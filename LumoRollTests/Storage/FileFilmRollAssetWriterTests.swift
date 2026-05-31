import Foundation
import XCTest
@testable import LumoRoll

final class FileFilmRollAssetWriterTests: XCTestCase {
    func testWritesReferenceAssetsCubeExportAndDiscardsRollFolderUsingAssetStoreRelativePaths() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let writer = FileFilmRollAssetWriter(assetStore: assetStore)

        let filmRollID = try await writer.reserveFilmRollID()
        XCTAssertNotNil(UUID(uuidString: filmRollID))
        XCTAssertFalse(filmRollID.contains("/"))
        XCTAssertFalse(filmRollID.contains(".."))

        let reference = try await writer.storeReferenceImage(
            filmRollID: filmRollID,
            imageData: Data([1, 2, 3]),
            thumbnailData: Data([9, 8, 7]),
            preferredFileExtension: "JPG"
        )

        XCTAssertEqual(reference.originalPath, "film-rolls/\(filmRollID)/reference/original.jpg")
        XCTAssertEqual(reference.thumbnailPath, "film-rolls/\(filmRollID)/reference/thumbnail.jpg")
        XCTAssertEqual(try Data(contentsOf: assetStore.rootURL.appendingPathComponent(reference.originalPath)), Data([1, 2, 3]))
        XCTAssertEqual(try Data(contentsOf: assetStore.rootURL.appendingPathComponent(reference.thumbnailPath)), Data([9, 8, 7]))

        let exportURL = try await writer.writeCubeExport(
            filmRollID: filmRollID,
            cubeText: "TITLE \"Warm Roll\"\nLUT_3D_SIZE 33\n",
            suggestedFilename: "Warm-Roll.cube"
        )

        XCTAssertEqual(exportURL, assetStore.rootURL.appendingPathComponent("film-rolls/\(filmRollID)/lut/export.cube"))
        XCTAssertEqual(try String(contentsOf: exportURL, encoding: .utf8), "TITLE \"Warm Roll\"\nLUT_3D_SIZE 33\n")

        await writer.discardFilmRollAssets(filmRollID: filmRollID)

        XCTAssertFalse(FileManager.default.fileExists(atPath: assetStore.filmRollFolderURL(for: filmRollID).path))
    }

    func testDiscardFilmRollAssetsIgnoresUnsafeTraversalIDAndLeavesOutsideSentinelUntouched() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let writer = FileFilmRollAssetWriter(assetStore: assetStore)
        try assetStore.prepareRoot()
        let sentinelFolder = assetStore.rootURL.appendingPathComponent("sentinel", isDirectory: true)
        try FileManager.default.createDirectory(at: sentinelFolder, withIntermediateDirectories: true)
        let sentinelFile = sentinelFolder.appendingPathComponent("keep.txt")
        try Data([7]).write(to: sentinelFile)

        await writer.discardFilmRollAssets(filmRollID: "../sentinel")

        XCTAssertTrue(FileManager.default.fileExists(atPath: sentinelFile.path))
    }

    func testWriteCubeExportMapsDiskWriteFailureToStorageFailed() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let writer = FileFilmRollAssetWriter(assetStore: assetStore)
        let filmRollID = "roll-blocked"
        try assetStore.prepareRoot()
        try Data([1]).write(to: assetStore.filmRollsURL.appendingPathComponent(filmRollID))

        await XCTAssertThrowsAsyncError(
            try await writer.writeCubeExport(
                filmRollID: filmRollID,
                cubeText: "TITLE \"Blocked\"\n",
                suggestedFilename: "Blocked.cube"
            )
        ) { error in
            guard case .storageFailed(let message) = error as? LumoError else {
                XCTFail("Expected storageFailed, got \(error)")
                return
            }
            XCTAssertFalse(message.isEmpty)
        }
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LumoRollFileFilmRollAssetWriterTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private func XCTAssertThrowsAsyncError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ errorHandler: (Error) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
