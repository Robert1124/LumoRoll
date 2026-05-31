import XCTest
@testable import LumoRoll

final class ExportLUTUseCaseTests: XCTestCase {
    func testExportLoadsRollSerializesCubeWritesSafeCubeFilenameAndReturnsURL() async throws {
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Portra: Morning / 01",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: try testLUT(size: 2, redOffset: 0.05)
        )
        let repository = SpyFilmRollRepository()
        repository.filmRollsByID[roll.id] = roll
        let exporter = SpyLUTExporter(cubeText: "TITLE \"Portra\"\nLUT_3D_SIZE 2\n")
        let assetWriter = SpyFilmRollAssetWriter()
        let useCase = ExportLUTUseCase(
            repository: repository,
            lutExporter: exporter,
            assetWriter: assetWriter
        )

        let result = try await useCase.exportLUT(input: ExportLUTInput(filmRollID: "roll-1"))

        XCTAssertEqual(repository.loadedIDs, ["roll-1"])
        XCTAssertEqual(exporter.requests, [
            LUTExportRequest(filmRollID: "roll-1", filmRollName: "Portra: Morning / 01", lut: roll.lut)
        ])
        XCTAssertEqual(result.suggestedFilename, "Portra-Morning-01.cube")
        XCTAssertEqual(result.cubeText, "TITLE \"Portra\"\nLUT_3D_SIZE 2\n")
        XCTAssertEqual(result.fileURL, URL(fileURLWithPath: "/tmp/Portra-Morning-01.cube"))
        XCTAssertEqual(assetWriter.writeCubeExportCalls.count, 1)
        XCTAssertEqual(assetWriter.writeCubeExportCalls.first?.filmRollID, "roll-1")
        XCTAssertEqual(assetWriter.writeCubeExportCalls.first?.cubeText, "TITLE \"Portra\"\nLUT_3D_SIZE 2\n")
        XCTAssertEqual(assetWriter.writeCubeExportCalls.first?.suggestedFilename, "Portra-Morning-01.cube")
    }

    func testExportUsesUntitledFallbackWhenRollNameHasNoFilenameCharacters() async throws {
        let roll = try FilmRoll(
            id: "roll-2",
            name: "...",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: LUT3D.identity()
        )
        let repository = SpyFilmRollRepository()
        repository.filmRollsByID[roll.id] = roll
        let exporter = SpyLUTExporter(cubeText: "cube")
        let assetWriter = SpyFilmRollAssetWriter()
        let useCase = ExportLUTUseCase(repository: repository, lutExporter: exporter, assetWriter: assetWriter)

        let result = try await useCase.exportLUT(input: ExportLUTInput(filmRollID: "roll-2"))

        XCTAssertEqual(result.suggestedFilename, "Film-Roll.cube")
    }

    func testExportCapsVeryLongSuggestedFilename() async throws {
        let longName = String(repeating: "Warm Portra Morning ", count: 20)
        let roll = try FilmRoll(
            id: "roll-3",
            name: longName,
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: LUT3D.identity()
        )
        let repository = SpyFilmRollRepository()
        repository.filmRollsByID[roll.id] = roll
        let assetWriter = SpyFilmRollAssetWriter()
        let useCase = ExportLUTUseCase(
            repository: repository,
            lutExporter: SpyLUTExporter(cubeText: "cube"),
            assetWriter: assetWriter
        )

        let result = try await useCase.exportLUT(input: ExportLUTInput(filmRollID: "roll-3"))

        XCTAssertTrue(result.suggestedFilename.hasSuffix(".cube"))
        XCTAssertLessThanOrEqual(result.suggestedFilename.count, 85)
        XCTAssertEqual(result.suggestedFilename, assetWriter.writeCubeExportCalls.first?.suggestedFilename)
    }

    func testExportUsesAsciiOnlyFilenameAndFallbackForNonAsciiName() async throws {
        let roll = try FilmRoll(
            id: "roll-4",
            name: "暖色胶片",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: LUT3D.identity()
        )
        let repository = SpyFilmRollRepository()
        repository.filmRollsByID[roll.id] = roll
        let assetWriter = SpyFilmRollAssetWriter()
        let useCase = ExportLUTUseCase(
            repository: repository,
            lutExporter: SpyLUTExporter(cubeText: "cube"),
            assetWriter: assetWriter
        )

        let result = try await useCase.exportLUT(input: ExportLUTInput(filmRollID: "roll-4"))

        XCTAssertEqual(result.suggestedFilename, "Film-Roll.cube")
        XCTAssertTrue(result.suggestedFilename.unicodeScalars.allSatisfy { scalar in
            scalar.value < 128
        })
        XCTAssertTrue(result.suggestedFilename.allSatisfy { character in
            character.isASCIIAlphanumeric || character == "-" || character == "."
        })
    }
}

private final class SpyLUTExporter: LUTExporting, @unchecked Sendable {
    let cubeText: String
    private(set) var requests: [LUTExportRequest] = []

    init(cubeText: String) {
        self.cubeText = cubeText
    }

    func exportLUT(for request: LUTExportRequest) async throws -> String {
        requests.append(request)
        return cubeText
    }
}

private final class SpyFilmRollAssetWriter: FilmRollAssetWriting, @unchecked Sendable {
    private(set) var writeCubeExportCalls: [(filmRollID: String, cubeText: String, suggestedFilename: String)] = []

    func reserveFilmRollID() async throws -> String {
        "unused"
    }

    func storeReferenceImage(
        filmRollID: String,
        imageData: Data,
        thumbnailData: Data,
        preferredFileExtension: String?
    ) async throws -> FilmRollReferenceAsset {
        FilmRollReferenceAsset(originalPath: "unused", thumbnailPath: "unused")
    }

    func writeCubeExport(filmRollID: String, cubeText: String, suggestedFilename: String) async throws -> URL {
        writeCubeExportCalls.append((filmRollID: filmRollID, cubeText: cubeText, suggestedFilename: suggestedFilename))
        return URL(fileURLWithPath: "/tmp/\(suggestedFilename)")
    }

    func discardFilmRollAssets(filmRollID: String) async {}
}

private final class SpyFilmRollRepository: FilmRollRepository, @unchecked Sendable {
    var filmRollsByID: [String: FilmRoll] = [:]
    private(set) var loadedIDs: [String] = []
    private(set) var savedFilmRolls: [FilmRoll] = []

    func loadFilmRolls() async throws -> [FilmRoll] {
        Array(filmRollsByID.values)
    }

    func loadFilmRoll(id: String) async throws -> FilmRoll {
        loadedIDs.append(id)
        guard let roll = filmRollsByID[id] else {
            throw LumoError.filmRollNotFound(id: id)
        }
        return roll
    }

    func saveFilmRoll(_ filmRoll: FilmRoll) async throws {
        savedFilmRolls.append(filmRoll)
        filmRollsByID[filmRoll.id] = filmRoll
    }

    func deleteFilmRoll(id: String) async throws {
        filmRollsByID[id] = nil
    }
}

private func testLUT(size: Int = 2, redOffset: Float = 0) throws -> LUT3D {
    let identity = LUT3D.identity(size: size)
    let values = identity.values.enumerated().map { index, value in
        index.isMultiple(of: 3) ? min(1, value + redOffset) : value
    }
    return try LUT3D(size: size, values: values, algorithmVersion: "test")
}

private extension Character {
    var isASCIIAlphanumeric: Bool {
        guard let scalar = unicodeScalars.first, unicodeScalars.count == 1 else {
            return false
        }
        return (65...90).contains(scalar.value)
            || (97...122).contains(scalar.value)
            || (48...57).contains(scalar.value)
    }
}
