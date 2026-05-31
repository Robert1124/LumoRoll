import Foundation
import XCTest
@testable import LumoRoll

final class PhotoImportStagingServiceTests: XCTestCase {
    func testStagesPNGDataToTemporaryImportFolderWithCopiedBytes() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "import-fixed" })
        let pngData = try SystemIntegrationImageFixtures.png(width: 3, height: 2) { _, _ in
            .init(red: 20, green: 130, blue: 220, alpha: 255)
        }

        let staged = try await service.stageImageData(
            pngData,
            preferredFileExtension: "png",
            originalFilename: "Summer Vacation.png"
        )

        XCTAssertEqual(staged.id, "import-fixed")
        XCTAssertEqual(staged.relativePath, "tmp/imports/import-fixed/original.png")
        XCTAssertEqual(staged.preferredFileExtension, "png")
        XCTAssertEqual(staged.originalFilename, "Summer Vacation.png")
        XCTAssertFalse(staged.relativePath.contains("Summer Vacation"))
        XCTAssertEqual(try Data(contentsOf: assetStore.rootURL.appendingPathComponent(staged.relativePath)), pngData)
    }

    func testNormalizesJPEGExtensionAndKeepsFilenameOutOfAppPath() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let service = PhotoImportStagingService(assetStore: AssetStore(baseURL: tempDirectory), idGenerator: { "import-jpeg" })
        let jpegData = try SystemIntegrationImageFixtures.jpeg(width: 2, height: 2) { _, _ in
            .init(red: 240, green: 180, blue: 90, alpha: 255)
        }

        let staged = try await service.stageImageData(
            jpegData,
            preferredFileExtension: ".JPEG",
            originalFilename: "Yiwen's Roll.jpeg"
        )

        XCTAssertEqual(staged.relativePath, "tmp/imports/import-jpeg/original.jpg")
        XCTAssertEqual(staged.preferredFileExtension, "jpg")
        XCTAssertFalse(staged.relativePath.contains("Yiwen"))
    }

    func testRejectsUnsupportedExtensionAndInvalidImageData() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let service = PhotoImportStagingService(assetStore: AssetStore(baseURL: tempDirectory), idGenerator: { "import-bad" })
        let pngData = try SystemIntegrationImageFixtures.png(width: 1, height: 1) { _, _ in
            .init(red: 1, green: 2, blue: 3, alpha: 255)
        }

        await XCTAssertThrowsAsyncLumoError(try await service.stageImageData(pngData, preferredFileExtension: "gif")) { error in
            XCTAssertEqual(error, .importFailed)
        }
        await XCTAssertThrowsAsyncLumoError(try await service.stageImageData(Data([0, 1, 2]), preferredFileExtension: "png")) { error in
            XCTAssertEqual(error, .importFailed)
        }
    }

    func testRejectsMismatchedPreferredExtensionAndDetectedImageType() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let service = PhotoImportStagingService(assetStore: AssetStore(baseURL: tempDirectory), idGenerator: { "import-mismatch" })
        let jpegData = try SystemIntegrationImageFixtures.jpeg(width: 2, height: 2) { _, _ in
            .init(red: 80, green: 90, blue: 100, alpha: 255)
        }

        await XCTAssertThrowsAsyncLumoError(try await service.stageImageData(jpegData, preferredFileExtension: "png")) { error in
            XCTAssertEqual(error, .importFailed)
        }
    }

    func testStagesLargeDimensionPNGUsingBoundedDecodePreflight() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "import-large" })
        let pngData = try SystemIntegrationImageFixtures.png(width: 5_000, height: 1) { x, _ in
            .init(red: UInt8(x % 255), green: 120, blue: 160, alpha: 255)
        }

        let staged = try await service.stageImageData(pngData, preferredFileExtension: "png")

        XCTAssertEqual(staged.relativePath, "tmp/imports/import-large/original.png")
        XCTAssertEqual(try Data(contentsOf: assetStore.rootURL.appendingPathComponent(staged.relativePath)), pngData)
    }

    func testRemovesStagedImportFolderWhenWriteFailsAfterDirectoryCreation() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "import-blocked" })
        let pngData = try SystemIntegrationImageFixtures.png(width: 1, height: 1) { _, _ in
            .init(red: 1, green: 2, blue: 3, alpha: 255)
        }
        let importFolder = assetStore.rootURL.appendingPathComponent("tmp/imports/import-blocked", isDirectory: true)
        let blockingDestination = importFolder.appendingPathComponent("original.png", isDirectory: true)
        try FileManager.default.createDirectory(at: blockingDestination, withIntermediateDirectories: true)

        await XCTAssertThrowsAsyncLumoError(try await service.stageImageData(pngData, preferredFileExtension: "png")) { error in
            XCTAssertEqual(error, .importFailed)
        }
        XCTAssertFalse(FileManager.default.fileExists(atPath: importFolder.path))
    }

    func testStagesFileURLByCopyingIntoAppOwnedStorage() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "import-file" })
        let sourceURL = tempDirectory.appendingPathComponent("User Visible Name.jpeg")
        let jpegData = try SystemIntegrationImageFixtures.jpeg(width: 2, height: 3) { _, _ in
            .init(red: 32, green: 90, blue: 170, alpha: 255)
        }
        try jpegData.write(to: sourceURL)

        let staged = try await service.stageImageFile(at: sourceURL)

        XCTAssertEqual(staged.relativePath, "tmp/imports/import-file/original.jpg")
        XCTAssertEqual(staged.preferredFileExtension, "jpg")
        XCTAssertEqual(staged.originalFilename, "User Visible Name.jpeg")
        XCTAssertEqual(try Data(contentsOf: assetStore.rootURL.appendingPathComponent(staged.relativePath)), jpegData)
        XCTAssertFalse(staged.relativePath.contains("User Visible Name"))
    }

    func testStagesExtensionlessFileURLUsingDetectedImageTypeExtension() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "import-extensionless" })
        let sourceURL = tempDirectory.appendingPathComponent("selected-photo")
        let jpegData = try SystemIntegrationImageFixtures.jpeg(width: 2, height: 2) { _, _ in
            .init(red: 210, green: 90, blue: 60, alpha: 255)
        }
        try jpegData.write(to: sourceURL)

        let staged = try await service.stageImageFile(at: sourceURL)

        XCTAssertEqual(staged.relativePath, "tmp/imports/import-extensionless/original.jpg")
        XCTAssertEqual(staged.preferredFileExtension, "jpg")
        XCTAssertEqual(try Data(contentsOf: assetStore.rootURL.appendingPathComponent(staged.relativePath)), jpegData)
    }

    func testDiscardStagedImportRemovesTemporaryImportFolderOnly() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let resolver = AppAssetURLResolver(assetStore: assetStore)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "import-discard" })
        let pngData = try SystemIntegrationImageFixtures.png(width: 2, height: 2) { _, _ in
            .init(red: 90, green: 120, blue: 150, alpha: 255)
        }
        let staged = try await service.stageImageData(pngData, preferredFileExtension: "png")
        let stagedFolder = try resolver.resolve("tmp/imports/import-discard")
        let savedFolder = try resolver.resolve("film-rolls/roll-1/reference")
        try FileManager.default.createDirectory(at: savedFolder, withIntermediateDirectories: true)

        await service.discardStagedImport(relativePath: staged.relativePath)

        XCTAssertFalse(FileManager.default.fileExists(atPath: stagedFolder.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: savedFolder.path))
    }

    @MainActor
    func testCreateStagedReferenceSelectionDiscardsStagedImportWhenReadFails() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let resolver = AppAssetURLResolver(assetStore: assetStore)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "selection-failure" })
        let pngData = try SystemIntegrationImageFixtures.png(width: 2, height: 2) { _, _ in
            .init(red: 80, green: 100, blue: 120, alpha: 255)
        }
        let staged = try await service.stageImageData(pngData, preferredFileExtension: "png")
        let stagedFolder = try resolver.resolve("tmp/imports/selection-failure")
        let stagedURL = try resolver.resolve(staged.relativePath)
        try FileManager.default.removeItem(at: stagedURL)

        do {
            try await CreateStagedReferenceSelection.select(
                staged,
                resolver: resolver,
                completedGeneration: 1,
                activeGeneration: { 1 },
                discardStagedImport: service.discardStagedImport(relativePath:),
                onSelected: { _, _ in }
            )
            XCTFail("Expected staged reference selection to fail.")
        } catch {
        }

        XCTAssertFalse(FileManager.default.fileExists(atPath: stagedFolder.path))
    }

    @MainActor
    func testCreateStagedReferenceSelectionDiscardsStaleCompletionAfterReadWithoutSelecting() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let resolver = AppAssetURLResolver(assetStore: assetStore)
        let service = PhotoImportStagingService(assetStore: assetStore, idGenerator: { "stale-after-read" })
        let pngData = try SystemIntegrationImageFixtures.png(width: 2, height: 2) { _, _ in
            .init(red: 50, green: 70, blue: 90, alpha: 255)
        }
        let staged = try await service.stageImageData(pngData, preferredFileExtension: "png")
        let stagedFolder = try resolver.resolve("tmp/imports/stale-after-read")
        var didSelect = false

        let didAccept = try await CreateStagedReferenceSelection.select(
            staged,
            resolver: resolver,
            completedGeneration: 1,
            activeGeneration: { 2 },
            discardStagedImport: service.discardStagedImport(relativePath:)
        ) { _, _ in
            didSelect = true
        }

        XCTAssertFalse(didAccept)
        XCTAssertFalse(didSelect)
        XCTAssertFalse(FileManager.default.fileExists(atPath: stagedFolder.path))
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LumoRollPhotoImportStagingServiceTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private func XCTAssertThrowsAsyncLumoError<T>(
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
