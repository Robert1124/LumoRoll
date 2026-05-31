import XCTest
@testable import LumoRoll

@MainActor
final class PhotoDisplayImageStoreTests: XCTestCase {
    func testLoadCachesSuccessfulDisplayImageByPathAndRequestedSize() async throws {
        let imageData = try SystemIntegrationImageFixtures.png(width: 4, height: 2) { _, _ in
            .init(red: 120, green: 80, blue: 40, alpha: 255)
        }
        let loader = PhotoDisplayImageStoreSpyLoader(displayImage: LocalPhotoDisplayImage(
            data: imageData,
            pixelWidth: 4,
            pixelHeight: 2,
            contentType: "public.png"
        ))
        let store = PhotoDisplayImageStore(loadDisplayImage: loader.loadDisplayImage(relativePath:maxPixelDimension:))

        await store.load(relativePath: "tmp/imports/one/original.png", maxPixelDimension: 512)
        await store.load(relativePath: "tmp/imports/one/original.png", maxPixelDimension: 512)

        XCTAssertNotNil(store.image(relativePath: "tmp/imports/one/original.png", maxPixelDimension: 512))
        XCTAssertEqual(store.aspectRatio(relativePath: "tmp/imports/one/original.png", maxPixelDimension: 512), 2)
        let requestsAfterCachedLoad = await loader.recordedRequests()
        XCTAssertEqual(requestsAfterCachedLoad, [
            .init(relativePath: "tmp/imports/one/original.png", maxPixelDimension: 512)
        ])

        await store.load(relativePath: "tmp/imports/one/original.png", maxPixelDimension: 1024)

        let requestsAfterSecondSize = await loader.recordedRequests()
        XCTAssertEqual(requestsAfterSecondSize, [
            .init(relativePath: "tmp/imports/one/original.png", maxPixelDimension: 512),
            .init(relativePath: "tmp/imports/one/original.png", maxPixelDimension: 1024)
        ])
    }

    func testConcurrentLoadsForSameKeyShareOneLoaderRequest() async throws {
        let imageData = try SystemIntegrationImageFixtures.png(width: 3, height: 3) { _, _ in
            .init(red: 30, green: 90, blue: 180, alpha: 255)
        }
        let loader = PhotoDisplayImageStoreSuspendingLoader(displayImage: LocalPhotoDisplayImage(
            data: imageData,
            pixelWidth: 3,
            pixelHeight: 3,
            contentType: "public.png"
        ))
        let store = PhotoDisplayImageStore(loadDisplayImage: loader.loadDisplayImage(relativePath:maxPixelDimension:))

        async let firstLoad: Void = store.load(relativePath: "tmp/imports/shared/original.png", maxPixelDimension: 512)
        await loader.waitForRequestCount(1)
        async let secondLoad: Void = store.load(relativePath: "tmp/imports/shared/original.png", maxPixelDimension: 512)
        try await Task.sleep(nanoseconds: 50_000_000)
        await loader.resume()
        await firstLoad
        await secondLoad

        XCTAssertNotNil(store.image(relativePath: "tmp/imports/shared/original.png", maxPixelDimension: 512))
        let requestCount = await loader.recordedRequestCount()
        XCTAssertEqual(requestCount, 1)
    }

    func testFailedLoadPublishesErrorWithoutCachingInvalidImage() async {
        let loader = PhotoDisplayImageStoreSpyLoader(error: LumoError.importFailed)
        let store = PhotoDisplayImageStore(loadDisplayImage: loader.loadDisplayImage(relativePath:maxPixelDimension:))

        await store.load(relativePath: "tmp/imports/missing/original.jpg", maxPixelDimension: 512)

        XCTAssertNil(store.image(relativePath: "tmp/imports/missing/original.jpg", maxPixelDimension: 512))
        XCTAssertEqual(store.errorMessage(relativePath: "tmp/imports/missing/original.jpg", maxPixelDimension: 512), "Photo import failed.")
    }

    func testCancelledCallerKeepsInFlightRequestShareableWithoutPublishingImage() async throws {
        let imageData = try SystemIntegrationImageFixtures.png(width: 3, height: 3) { _, _ in
            .init(red: 220, green: 160, blue: 90, alpha: 255)
        }
        let loader = PhotoDisplayImageStoreSuspendingLoader(displayImage: LocalPhotoDisplayImage(
            data: imageData,
            pixelWidth: 3,
            pixelHeight: 3,
            contentType: "public.png"
        ))
        let store = PhotoDisplayImageStore(loadDisplayImage: loader.loadDisplayImage(relativePath:maxPixelDimension:))

        let firstLoad = Task {
            await store.load(relativePath: "tmp/imports/cancelled/original.png", maxPixelDimension: 512)
        }
        await loader.waitForRequestCount(1)
        firstLoad.cancel()
        try await Task.sleep(nanoseconds: 50_000_000)

        let secondLoad = Task {
            await store.load(relativePath: "tmp/imports/cancelled/original.png", maxPixelDimension: 512)
        }
        try await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNil(store.image(relativePath: "tmp/imports/cancelled/original.png", maxPixelDimension: 512))
        let requestCountAfterCancellation = await loader.recordedRequestCount()
        XCTAssertEqual(requestCountAfterCancellation, 1)

        await loader.resume()
        await firstLoad.value
        await secondLoad.value

        XCTAssertNotNil(store.image(relativePath: "tmp/imports/cancelled/original.png", maxPixelDimension: 512))
    }
}

private struct PhotoDisplayImageStoreLoadRequest: Equatable {
    let relativePath: String
    let maxPixelDimension: Int
}

private actor PhotoDisplayImageStoreSpyLoader {
    private let displayImage: LocalPhotoDisplayImage?
    private let error: Error?
    private(set) var requests: [PhotoDisplayImageStoreLoadRequest] = []

    init(displayImage: LocalPhotoDisplayImage? = nil, error: Error? = nil) {
        self.displayImage = displayImage
        self.error = error
    }

    func loadDisplayImage(relativePath: String, maxPixelDimension: Int) async throws -> LocalPhotoDisplayImage {
        requests.append(.init(relativePath: relativePath, maxPixelDimension: maxPixelDimension))
        if let error {
            throw error
        }
        return displayImage!
    }

    func recordedRequests() -> [PhotoDisplayImageStoreLoadRequest] {
        requests
    }
}

private actor PhotoDisplayImageStoreSuspendingLoader {
    private let displayImage: LocalPhotoDisplayImage
    private var continuations: [CheckedContinuation<LocalPhotoDisplayImage, Error>] = []
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private(set) var requestCount = 0

    init(displayImage: LocalPhotoDisplayImage) {
        self.displayImage = displayImage
    }

    func loadDisplayImage(relativePath: String, maxPixelDimension: Int) async throws -> LocalPhotoDisplayImage {
        try await withCheckedThrowingContinuation { continuation in
            requestCount += 1
            continuations.append(continuation)
            waiters.forEach { $0.resume() }
            waiters.removeAll()
        }
    }

    func waitForRequestCount(_ expectedCount: Int) async {
        if requestCount >= expectedCount {
            return
        }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func resume() {
        continuations.forEach { $0.resume(returning: displayImage) }
        continuations.removeAll()
    }

    func recordedRequestCount() -> Int {
        requestCount
    }
}
