import XCTest
@testable import LumoRoll

final class FilmRollManifestTests: XCTestCase {
    func testManifestEncodesAndDecodesFilmRollMetadata() throws {
        let roll = try Self.makeFilmRoll()
        let manifest = FilmRollManifest(filmRoll: roll)

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(manifest)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(FilmRollManifest.self, from: data)

        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.filmRoll, roll)
        XCTAssertEqual(decoded.filmRoll.referenceAsset.originalPath, "film-rolls/roll-id/reference/original.jpg")
        XCTAssertEqual(decoded.filmRoll.lut.size, 2)
        XCTAssertEqual(decoded.filmRoll.palette.first?.red, 0.2)
        XCTAssertEqual(decoded.filmRoll.sampleAnalysisPackage, roll.sampleAnalysisPackage)
        XCTAssertEqual(decoded.filmRoll.processedPhotos.first?.processedPath, "film-rolls/roll-id/processed/photo-1/rendered.jpg")
        XCTAssertEqual(decoded.filmRoll.processedPhotos.first?.adaptiveRenderMetadata, roll.processedPhotos.first?.adaptiveRenderMetadata)
    }

    private static func makeFilmRoll() throws -> FilmRoll {
        let reference = FilmRollReferenceAsset(
            originalPath: "film-rolls/roll-id/reference/original.jpg",
            thumbnailPath: "film-rolls/roll-id/reference/thumbnail.jpg"
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
            originalPath: "film-rolls/roll-id/processed/photo-1/original.jpg",
            processedPath: "film-rolls/roll-id/processed/photo-1/rendered.jpg",
            thumbnailPath: "film-rolls/roll-id/processed/photo-1/thumbnail.jpg",
            createdAt: Date(timeIntervalSince1970: 1_800),
            intensity: 75,
            adaptiveRenderMetadata: modelAssistedTestAdaptiveRenderMetadata()
        )

        return try FilmRoll(
            id: "roll-id",
            name: "Portra Morning",
            createdAt: Date(timeIntervalSince1970: 1_000),
            updatedAt: Date(timeIntervalSince1970: 2_000),
            referenceAsset: reference,
            lut: lut,
            sampleAnalysisPackage: modelAssistedTestSampleAnalysisPackage(),
            palette: [
                FilmRollPaletteColor(id: "color-1", red: 0.2, green: 0.4, blue: 0.6)
            ],
            processedPhotos: [processed]
        )
    }
}
