import XCTest
@testable import LumoRoll

final class PhotoKitPhotoLibraryWriterTests: XCTestCase {
    func testRejectsInvalidOrMissingPathsWithoutRequestingAuthorization() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let client = SpyPhotoLibraryClient(status: .notDetermined, requestedStatus: .authorized)
        let writer = PhotoKitPhotoLibraryWriter(
            resolver: AppAssetURLResolver(assetStore: AssetStore(baseURL: tempDirectory)),
            client: client
        )

        await XCTAssertThrowsAsyncError(try await writer.savePhotoToLibrary(processedPath: "../outside.jpg")) { error in
            XCTAssertNotNil(error as? LumoError)
        }
        await XCTAssertThrowsAsyncError(try await writer.savePhotoToLibrary(processedPath: "tmp/missing.jpg")) { error in
            XCTAssertNotNil(error as? LumoError)
        }

        XCTAssertEqual(client.authorizationRequestCount, 0)
        XCTAssertEqual(client.createdAssetURLs, [])
    }

    func testRequestsAddOnlyAuthorizationWhenStatusIsNotDeterminedThenCreatesAsset() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let processedURL = assetStore.rootURL.appendingPathComponent("tmp/rendered/photo.jpg")
        try FileManager.default.createDirectory(at: processedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data([1, 2, 3]).write(to: processedURL)
        let client = SpyPhotoLibraryClient(
            status: .notDetermined,
            requestedStatus: .authorized,
            createdIdentifier: "photos-created-id"
        )
        let writer = PhotoKitPhotoLibraryWriter(
            resolver: AppAssetURLResolver(assetStore: assetStore),
            client: client
        )

        let identifier = try await writer.savePhotoToLibrary(processedPath: "tmp/rendered/photo.jpg")

        XCTAssertEqual(identifier, "photos-created-id")
        XCTAssertEqual(client.authorizationRequestCount, 1)
        XCTAssertEqual(client.createdAssetURLs, [processedURL])
    }

    func testAuthorizedStatusCreatesWithoutRequestingAuthorization() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let processedURL = assetStore.rootURL.appendingPathComponent("tmp/rendered/photo.jpg")
        try FileManager.default.createDirectory(at: processedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data([1, 2, 3]).write(to: processedURL)
        let client = SpyPhotoLibraryClient(status: .authorized, requestedStatus: .denied)
        let writer = PhotoKitPhotoLibraryWriter(
            resolver: AppAssetURLResolver(assetStore: assetStore),
            client: client
        )

        _ = try await writer.savePhotoToLibrary(processedPath: "tmp/rendered/photo.jpg")

        XCTAssertEqual(client.authorizationRequestCount, 0)
        XCTAssertEqual(client.createdAssetURLs, [processedURL])
    }

    func testDeniedAndRestrictedStatusesFailWithPermissionError() async throws {
        for status in [PhotoLibraryAuthorizationStatus.denied, .restricted] {
            let tempDirectory = try Self.makeTempDirectory()
            defer { try? FileManager.default.removeItem(at: tempDirectory) }
            let assetStore = AssetStore(baseURL: tempDirectory)
            let processedURL = assetStore.rootURL.appendingPathComponent("tmp/rendered/photo.jpg")
            try FileManager.default.createDirectory(at: processedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data([1, 2, 3]).write(to: processedURL)
            let client = SpyPhotoLibraryClient(status: status, requestedStatus: status)
            let writer = PhotoKitPhotoLibraryWriter(
                resolver: AppAssetURLResolver(assetStore: assetStore),
                client: client
            )

            await XCTAssertThrowsAsyncError(try await writer.savePhotoToLibrary(processedPath: "tmp/rendered/photo.jpg")) { error in
                XCTAssertEqual((error as? LocalizedError)?.errorDescription, "Photos access is needed to save images to your library.")
            }
            XCTAssertEqual(client.authorizationRequestCount, 0)
            XCTAssertEqual(client.createdAssetURLs, [])
        }
    }

    func testCreateAssetPreservesDomainErrors() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let processedURL = try Self.writeProcessedPhoto(in: assetStore)
        let client = SpyPhotoLibraryClient(
            status: .authorized,
            requestedStatus: .authorized,
            createAssetError: LumoError.photosPermissionDenied
        )
        let writer = PhotoKitPhotoLibraryWriter(
            resolver: AppAssetURLResolver(assetStore: assetStore),
            client: client
        )

        await XCTAssertThrowsAsyncError(try await writer.savePhotoToLibrary(processedPath: "tmp/rendered/photo.jpg")) { error in
            XCTAssertEqual((error as? LocalizedError)?.errorDescription, "Photos access is needed to save images to your library.")
        }
        XCTAssertEqual(client.createdAssetURLs, [processedURL])
    }

    func testCreateAssetPreservesCancellationError() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let processedURL = try Self.writeProcessedPhoto(in: assetStore)
        let client = SpyPhotoLibraryClient(
            status: .authorized,
            requestedStatus: .authorized,
            createAssetError: CancellationError()
        )
        let writer = PhotoKitPhotoLibraryWriter(
            resolver: AppAssetURLResolver(assetStore: assetStore),
            client: client
        )

        await XCTAssertThrowsAsyncError(try await writer.savePhotoToLibrary(processedPath: "tmp/rendered/photo.jpg")) { error in
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertEqual(client.createdAssetURLs, [processedURL])
    }

    func testCreateAssetMapsUnknownErrorsToSaveFailed() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let processedURL = try Self.writeProcessedPhoto(in: assetStore)
        let client = SpyPhotoLibraryClient(
            status: .authorized,
            requestedStatus: .authorized,
            createAssetError: NSError(domain: "TestUnknown", code: 42)
        )
        let writer = PhotoKitPhotoLibraryWriter(
            resolver: AppAssetURLResolver(assetStore: assetStore),
            client: client
        )

        await XCTAssertThrowsAsyncError(try await writer.savePhotoToLibrary(processedPath: "tmp/rendered/photo.jpg")) { error in
            XCTAssertEqual((error as? LocalizedError)?.errorDescription, "Save failed.")
        }
        XCTAssertEqual(client.createdAssetURLs, [processedURL])
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LumoRollPhotoKitWriterTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private static func writeProcessedPhoto(in assetStore: AssetStore) throws -> URL {
        let processedURL = assetStore.rootURL.appendingPathComponent("tmp/rendered/photo.jpg")
        try FileManager.default.createDirectory(at: processedURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data([1, 2, 3]).write(to: processedURL)
        return processedURL
    }
}

private final class SpyPhotoLibraryClient: PhotoLibraryClient, @unchecked Sendable {
    var status: PhotoLibraryAuthorizationStatus
    let requestedStatus: PhotoLibraryAuthorizationStatus
    let createdIdentifier: String
    let createAssetError: Error?
    private(set) var authorizationRequestCount = 0
    private(set) var createdAssetURLs: [URL] = []

    init(
        status: PhotoLibraryAuthorizationStatus,
        requestedStatus: PhotoLibraryAuthorizationStatus,
        createdIdentifier: String = "created-id",
        createAssetError: Error? = nil
    ) {
        self.status = status
        self.requestedStatus = requestedStatus
        self.createdIdentifier = createdIdentifier
        self.createAssetError = createAssetError
    }

    func authorizationStatus() async -> PhotoLibraryAuthorizationStatus {
        status
    }

    func requestAddOnlyAuthorization() async -> PhotoLibraryAuthorizationStatus {
        authorizationRequestCount += 1
        status = requestedStatus
        return requestedStatus
    }

    func createAsset(from fileURL: URL) async throws -> String {
        createdAssetURLs.append(fileURL)
        if let createAssetError {
            throw createAssetError
        }
        return createdIdentifier
    }
}

private func XCTAssertThrowsAsyncError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (Error) -> Void
) async {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
