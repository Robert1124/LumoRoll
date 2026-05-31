import XCTest
@testable import LumoRoll

final class FileFilmRollRepositoryTests: XCTestCase {
    func testSaveFilmRollThenLoadListAndLoadByID() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let repository = FileFilmRollRepository(assetStore: AssetStore(baseURL: tempDirectory))
        let roll = try Self.makeFilmRoll(id: UUID().uuidString, name: "Golden Hour")

        try await repository.saveFilmRoll(roll)

        let loadedRolls = try await repository.loadFilmRolls()
        XCTAssertEqual(loadedRolls, [roll])

        let loadedRoll = try await repository.loadFilmRoll(id: roll.id)
        XCTAssertEqual(loadedRoll, roll)

        let manifestURL = tempDirectory
            .appendingPathComponent("LumoRoll", isDirectory: true)
            .appendingPathComponent("film-rolls", isDirectory: true)
            .appendingPathComponent(roll.id, isDirectory: true)
            .appendingPathComponent("manifest.json")
        XCTAssertTrue(FileManager.default.fileExists(atPath: manifestURL.path))
    }

    func testMissingFilmRollIDThrowsTypedNotFoundError() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let repository = FileFilmRollRepository(assetStore: AssetStore(baseURL: tempDirectory))

        do {
            _ = try await repository.loadFilmRoll(id: "missing-roll")
            XCTFail("Expected missing roll lookup to throw.")
        } catch let error as LumoError {
            XCTAssertEqual(error, .filmRollNotFound(id: "missing-roll"))
        }
    }

    func testDeleteFilmRollRemovesRollFolder() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let store = AssetStore(baseURL: tempDirectory)
        let repository = FileFilmRollRepository(assetStore: store)
        let roll = try Self.makeFilmRoll(id: UUID().uuidString, name: "Delete Me")

        try await repository.saveFilmRoll(roll)
        let rollFolder = store.filmRollFolderURL(for: roll.id)
        XCTAssertTrue(FileManager.default.fileExists(atPath: rollFolder.path))

        try await repository.deleteFilmRoll(id: roll.id)

        XCTAssertFalse(FileManager.default.fileExists(atPath: rollFolder.path))
    }

    private static func makeFilmRoll(id: String, name: String) throws -> FilmRoll {
        let reference = FilmRollReferenceAsset(
            originalPath: "film-rolls/\(id)/reference/original.jpg",
            thumbnailPath: "film-rolls/\(id)/reference/thumbnail.jpg"
        )
        let lut = try LUT3D(size: 2, values: [
            0, 0, 0,
            1, 0, 0,
            0, 1, 0,
            1, 1, 0,
            0, 0, 1,
            1, 0, 1,
            0, 1, 1,
            1, 1, 1
        ])
        let processed = ProcessedPhoto(
            id: "photo-1",
            originalPath: "film-rolls/\(id)/processed/photo-1/original.jpg",
            processedPath: "film-rolls/\(id)/processed/photo-1/rendered.jpg",
            thumbnailPath: "film-rolls/\(id)/processed/photo-1/thumbnail.jpg",
            createdAt: Date(timeIntervalSince1970: 3_000),
            intensity: 55
        )

        return try FilmRoll(
            id: id,
            name: name,
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000),
            referenceAsset: reference,
            lut: lut,
            palette: [FilmRollPaletteColor(id: "color-1", red: 0.1, green: 0.2, blue: 0.3)],
            processedPhotos: [processed]
        )
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LumoRollRepositoryTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}
