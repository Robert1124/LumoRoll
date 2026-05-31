import SwiftUI
import UniformTypeIdentifiers
import XCTest
@testable import LumoRoll

@MainActor
final class FilmRollDetailExportPresentationTests: XCTestCase {
    func testClearPreparedExportReturnsReadyExportToIdle() async throws {
        let roll = try exportPresentationRoll(id: "roll-ready", name: "Ready Roll")
        let dependencies = ExportPresentationDependencies(filmRolls: [roll])
        let model = FilmRollDetailFeatureModel(
            filmRollID: "roll-ready",
            repository: dependencies.repository,
            exportLUTUseCase: dependencies.useCase
        )

        await model.exportLUT()
        XCTAssertEqual(model.exportState, .ready(dependencies.expectedResult(filename: "Ready-Roll.cube")))

        model.clearPreparedExport()

        XCTAssertEqual(model.exportState, .idle)
    }

    func testClearPreparedExportDoesNotMutateInFlightExport() async throws {
        let roll = try exportPresentationRoll(id: "roll-exporting", name: "Exporting Roll")
        let repository = ExportPresentationRepository(filmRolls: [roll])
        let exporter = SuspendingExportPresentationLUTExporter(cubeText: "slow cube")
        let assetWriter = ExportPresentationAssetWriter()
        let useCase = ExportLUTUseCase(repository: repository, lutExporter: exporter, assetWriter: assetWriter)
        let model = FilmRollDetailFeatureModel(
            filmRollID: "roll-exporting",
            repository: repository,
            exportLUTUseCase: useCase
        )

        async let export: Void = model.exportLUT()
        await exporter.waitForRequestCount(1)

        model.clearPreparedExport()

        XCTAssertEqual(model.exportState, .exporting)

        await exporter.resumeExport()
        await export

        XCTAssertEqual(
            model.exportState,
            .ready(ExportLUTResult(
                suggestedFilename: "Exporting-Roll.cube",
                cubeText: "slow cube",
                fileURL: URL(fileURLWithPath: "/tmp/Exporting-Roll.cube")
            ))
        )
    }

    func testCubeLUTExportDocumentPreservesSuggestedFilenameContentAndCubeType() throws {
        let result = ExportLUTResult(
            suggestedFilename: "Warm-Roll.cube",
            cubeText: "TITLE \"Warm Roll\"\nLUT_3D_SIZE 33\n",
            fileURL: URL(fileURLWithPath: "/tmp/Warm-Roll.cube")
        )

        let document = CubeLUTExportDocument(exportResult: result)
        let fileWrapper = document.makeFileWrapper()

        XCTAssertEqual(document.suggestedFilename, "Warm-Roll.cube")
        XCTAssertTrue(document.suggestedFilename.hasSuffix(".cube"))
        XCTAssertEqual(String(data: fileWrapper.regularFileContents ?? Data(), encoding: .utf8), result.cubeText)
        XCTAssertTrue(CubeLUTExportDocument.writableContentTypes.contains(.lumoCube))
    }
}

private struct ExportPresentationDependencies {
    let repository: ExportPresentationRepository
    let assetWriter: ExportPresentationAssetWriter
    let useCase: ExportLUTUseCase

    init(filmRolls: [FilmRoll]) {
        repository = ExportPresentationRepository(filmRolls: filmRolls)
        assetWriter = ExportPresentationAssetWriter()
        useCase = ExportLUTUseCase(
            repository: repository,
            lutExporter: ExportPresentationLUTExporter(cubeText: "cube text"),
            assetWriter: assetWriter
        )
    }

    func expectedResult(filename: String) -> ExportLUTResult {
        ExportLUTResult(
            suggestedFilename: filename,
            cubeText: "cube text",
            fileURL: URL(fileURLWithPath: "/tmp/\(filename)")
        )
    }
}

private final class ExportPresentationRepository: FilmRollRepository, @unchecked Sendable {
    private let filmRollsByID: [String: FilmRoll]

    init(filmRolls: [FilmRoll]) {
        filmRollsByID = Dictionary(uniqueKeysWithValues: filmRolls.map { ($0.id, $0) })
    }

    func loadFilmRolls() async throws -> [FilmRoll] {
        Array(filmRollsByID.values)
    }

    func loadFilmRoll(id: String) async throws -> FilmRoll {
        guard let filmRoll = filmRollsByID[id] else {
            throw LumoError.filmRollNotFound(id: id)
        }
        return filmRoll
    }

    func saveFilmRoll(_ filmRoll: FilmRoll) async throws {}

    func deleteFilmRoll(id: String) async throws {}
}

private struct ExportPresentationLUTExporter: LUTExporting {
    let cubeText: String

    func exportLUT(for request: LUTExportRequest) async throws -> String {
        cubeText
    }
}

private final class ExportPresentationAssetWriter: FilmRollAssetWriting, @unchecked Sendable {
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

    func discardFilmRollAssets(filmRollID: String) async {}

    func writeCubeExport(filmRollID: String, cubeText: String, suggestedFilename: String) async throws -> URL {
        URL(fileURLWithPath: "/tmp/\(suggestedFilename)")
    }
}

private actor SuspendingExportPresentationLUTExporter: LUTExporting {
    private let cubeText: String
    private var exportContinuation: CheckedContinuation<String, Error>?
    private var requestWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var requestCount = 0

    init(cubeText: String) {
        self.cubeText = cubeText
    }

    func exportLUT(for request: LUTExportRequest) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            requestCount += 1
            exportContinuation = continuation
            requestWaiters.forEach { $0.resume() }
            requestWaiters.removeAll()
        }
    }

    func waitForRequestCount(_ expectedCount: Int) async {
        if requestCount >= expectedCount {
            return
        }
        await withCheckedContinuation { continuation in
            requestWaiters.append(continuation)
        }
    }

    func resumeExport() {
        exportContinuation?.resume(returning: cubeText)
        exportContinuation = nil
    }
}

private func exportPresentationRoll(id: String, name: String) throws -> FilmRoll {
    try FilmRoll(
        id: id,
        name: name,
        createdAt: Date(timeIntervalSince1970: 100),
        referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
        lut: LUT3D.identity()
    )
}
