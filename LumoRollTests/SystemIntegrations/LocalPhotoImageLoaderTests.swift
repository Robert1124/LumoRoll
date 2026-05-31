import Foundation
import XCTest
@testable import LumoRoll

final class LocalPhotoImageLoaderTests: XCTestCase {
    func testLoadsAndDownsamplesAppOwnedImageToMaxDimension() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "display-import" })
        let loader = LocalPhotoImageLoader(resolver: AppAssetURLResolver(assetStore: assetStore))
        let pngData = try SystemIntegrationImageFixtures.png(width: 20, height: 10) { x, _ in
            .init(red: UInt8(x * 10), green: 80, blue: 120, alpha: 255)
        }
        let staged = try await service.stageImageData(pngData, preferredFileExtension: "png")

        let displayImage = try await loader.loadDisplayImage(relativePath: staged.relativePath, maxPixelDimension: 6)

        XCTAssertLessThanOrEqual(max(displayImage.pixelWidth, displayImage.pixelHeight), 6)
        XCTAssertGreaterThan(displayImage.pixelWidth, 0)
        XCTAssertGreaterThan(displayImage.pixelHeight, 0)
        XCTAssertFalse(displayImage.data.isEmpty)
        XCTAssertFalse(displayImage.contentType.isEmpty)
    }

    func testRejectsUnsafeMissingAndCorruptImagePathsCleanly() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let resolver = AppAssetURLResolver(assetStore: assetStore)
        let loader = LocalPhotoImageLoader(resolver: resolver)

        await XCTAssertThrowsAsyncLocalError(try await loader.loadDisplayImage(relativePath: "../outside.jpg", maxPixelDimension: 128))
        await XCTAssertThrowsAsyncLocalError(try await loader.loadDisplayImage(relativePath: "tmp/imports/missing/original.jpg", maxPixelDimension: 128))

        let corruptURL = try resolver.resolve("tmp/imports/corrupt/original.jpg")
        try FileManager.default.createDirectory(at: corruptURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data([0, 1, 2, 3]).write(to: corruptURL)

        await XCTAssertThrowsAsyncLocalLumoError(try await loader.loadDisplayImage(relativePath: "tmp/imports/corrupt/original.jpg", maxPixelDimension: 128)) { error in
            XCTAssertEqual(error, .importFailed)
        }
    }

    func testRejectsNonPositiveMaxPixelDimension() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "display-invalid-size" })
        let loader = LocalPhotoImageLoader(resolver: AppAssetURLResolver(assetStore: assetStore))
        let pngData = try SystemIntegrationImageFixtures.png(width: 4, height: 2) { _, _ in
            .init(red: 30, green: 70, blue: 110, alpha: 255)
        }
        let staged = try await service.stageImageData(pngData, preferredFileExtension: "png")

        await XCTAssertThrowsAsyncLocalLumoError(try await loader.loadDisplayImage(relativePath: staged.relativePath, maxPixelDimension: 0)) { error in
            XCTAssertEqual(error, .importFailed)
        }
    }

    func testClampsExcessiveMaxPixelDimensionToDisplayCap() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "display-large" })
        let loader = LocalPhotoImageLoader(resolver: AppAssetURLResolver(assetStore: assetStore))
        let pngData = try SystemIntegrationImageFixtures.png(width: 5_000, height: 1) { x, _ in
            .init(red: UInt8(x % 255), green: 100, blue: 150, alpha: 255)
        }
        let staged = try await service.stageImageData(pngData, preferredFileExtension: "png")

        let displayImage = try await loader.loadDisplayImage(relativePath: staged.relativePath, maxPixelDimension: 50_000)

        XCTAssertLessThanOrEqual(max(displayImage.pixelWidth, displayImage.pixelHeight), 4_096)
        XCTAssertGreaterThan(displayImage.pixelWidth, 0)
        XCTAssertGreaterThan(displayImage.pixelHeight, 0)
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LumoRollLocalPhotoImageLoaderTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private func XCTAssertThrowsAsyncLocalError<T>(
    _ expression: @autoclosure () async throws -> T,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown", file: file, line: line)
    } catch {
    }
}

private func XCTAssertThrowsAsyncLocalLumoError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ errorHandler: (LumoError) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected LumoError to be thrown", file: file, line: line)
    } catch let error as LumoError {
        errorHandler(error)
    } catch {
        XCTFail("Expected LumoError, got \(error)", file: file, line: line)
    }
}
