import XCTest
@testable import LumoRoll

final class SaveAppliedPhotoToPhotosUseCaseTests: XCTestCase {
    func testSaveToPhotosRendersWritesDiscardsAndDoesNotSaveRepository() async throws {
        let repository = SavePhotosSpyFilmRollRepository()
        let samplePackage = modelAssistedTestSampleAnalysisPackage()
        let roll = try savePhotosRoll(sampleAnalysisPackage: samplePackage)
        repository.filmRollsByID[roll.id] = roll
        let renderResult = PhotoRenderResult(
            originalPath: "tmp/render/generated/original.jpg",
            processedPath: "tmp/render/generated/processed.jpg",
            thumbnailPath: "tmp/render/generated/thumb.jpg",
            intensity: 42
        )
        let renderer = SavePhotosSpyPhotoRenderer(result: renderResult)
        let writer = SavePhotosSpyPhotoLibraryWriter(localIdentifier: "photos-local-id")
        let useCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: renderer,
            photoLibraryWriter: writer,
            processedPhotoIDGenerator: { "generated-temp-id" }
        )

        let result = try await useCase.saveToPhotos(
            input: SaveAppliedPhotoToPhotosInput(
                filmRollID: roll.id,
                originalPhotoPath: "tmp/imports/target/original.jpg",
                intensity: 42
            )
        )

        XCTAssertEqual(result.localIdentifier, "photos-local-id")
        XCTAssertEqual(repository.loadedIDs, [roll.id])
        XCTAssertEqual(repository.savedFilmRolls, [])
        XCTAssertEqual(renderer.requests, [
            PhotoRenderRequest(
                filmRollID: roll.id,
                processedPhotoID: "generated-temp-id",
                originalPath: "tmp/imports/target/original.jpg",
                lut: roll.lut,
                intensity: 42,
                sampleAnalysisPackage: samplePackage
            )
        ])
        XCTAssertEqual(writer.processedPaths, [renderResult.processedPath])
        XCTAssertEqual(renderer.discardedResults, [renderResult])
    }

    func testSaveToPhotosCanDisableAdaptivePostProcessForDiagnosticRender() async throws {
        let repository = SavePhotosSpyFilmRollRepository()
        let samplePackage = modelAssistedTestSampleAnalysisPackage()
        let roll = try savePhotosRoll(sampleAnalysisPackage: samplePackage)
        repository.filmRollsByID[roll.id] = roll
        let renderer = SavePhotosSpyPhotoRenderer()
        let writer = SavePhotosSpyPhotoLibraryWriter(localIdentifier: "photos-local-id")
        let useCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: renderer,
            photoLibraryWriter: writer,
            processedPhotoIDGenerator: { "generated-temp-id" }
        )

        _ = try await useCase.saveToPhotos(
            input: SaveAppliedPhotoToPhotosInput(
                filmRollID: roll.id,
                originalPhotoPath: "tmp/imports/target/original.jpg",
                intensity: 42,
                isAdaptivePostProcessEnabled: false
            )
        )

        XCTAssertEqual(renderer.requests.first?.sampleAnalysisPackage, samplePackage)
        XCTAssertEqual(renderer.requests.first?.isAdaptivePostProcessEnabled, false)
    }

    func testSaveToPhotosCanUseTransientAlgorithmV2LUTWithoutSavingRepository() async throws {
        let repository = SavePhotosSpyFilmRollRepository()
        let savedLUT = LUT3D.identity(size: 2, algorithmVersion: "private.model.v1")
        let transientV2LUT = LUT3D.identity(size: 2, algorithmVersion: LUT3D.defaultAlgorithmVersion)
        let roll = try savePhotosRoll(lut: savedLUT)
        repository.filmRollsByID[roll.id] = roll
        let referenceData = Data([0x10, 0x20])
        let referenceLoader = SavePhotosStubReferenceImageDataLoader(data: referenceData)
        let lutGenerator = SavePhotosStubDiagnosticLUTGenerator(lut: transientV2LUT)
        let renderer = SavePhotosSpyPhotoRenderer()
        let writer = SavePhotosSpyPhotoLibraryWriter(localIdentifier: "photos-local-id")
        let useCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: renderer,
            photoLibraryWriter: writer,
            referenceImageDataLoader: referenceLoader,
            diagnosticLUTGenerator: lutGenerator,
            processedPhotoIDGenerator: { "generated-temp-id" }
        )

        _ = try await useCase.saveToPhotos(
            input: SaveAppliedPhotoToPhotosInput(
                filmRollID: roll.id,
                originalPhotoPath: "tmp/imports/target/original.jpg",
                intensity: 42,
                lutSourceMode: .algorithmV2
            )
        )

        XCTAssertEqual(referenceLoader.paths, [roll.referenceAsset.originalPath])
        XCTAssertEqual(lutGenerator.requests.map(\.referenceImageData), [referenceData])
        XCTAssertEqual(lutGenerator.requests.map(\.size), [savedLUT.size])
        XCTAssertEqual(lutGenerator.requests.map(\.algorithmVersion), [LUT3D.defaultAlgorithmVersion])
        XCTAssertEqual(renderer.requests.first?.lut, transientV2LUT)
        XCTAssertEqual(repository.savedFilmRolls, [])
        XCTAssertEqual(repository.filmRollsByID[roll.id]?.lut, savedLUT)
    }

    func testSaveToPhotosWriterFailureDiscardsTemporaryRenderAndRethrows() async throws {
        let repository = SavePhotosSpyFilmRollRepository()
        let roll = try savePhotosRoll()
        repository.filmRollsByID[roll.id] = roll
        let renderResult = PhotoRenderResult(
            originalPath: "tmp/render/generated/original.jpg",
            processedPath: "tmp/render/generated/processed.jpg",
            thumbnailPath: "tmp/render/generated/thumb.jpg",
            intensity: 65
        )
        let renderer = SavePhotosSpyPhotoRenderer(result: renderResult)
        let writer = SavePhotosSpyPhotoLibraryWriter(error: LumoError.saveFailed)
        let useCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: renderer,
            photoLibraryWriter: writer,
            processedPhotoIDGenerator: { "generated-temp-id" }
        )

        await XCTAssertThrowsAsyncError(
            try await useCase.saveToPhotos(
                input: SaveAppliedPhotoToPhotosInput(
                    filmRollID: roll.id,
                    originalPhotoPath: "tmp/imports/target/original.jpg",
                    intensity: 65
                )
            )
        ) { error in
            XCTAssertEqual(error as? LumoError, .saveFailed)
        }

        XCTAssertEqual(repository.savedFilmRolls, [])
        XCTAssertEqual(writer.processedPaths, [renderResult.processedPath])
        XCTAssertEqual(renderer.discardedResults, [renderResult])
    }

    func testSaveToPhotosRenderFailureDoesNotWriteOrDiscard() async throws {
        let repository = SavePhotosSpyFilmRollRepository()
        let roll = try savePhotosRoll()
        repository.filmRollsByID[roll.id] = roll
        let renderer = SavePhotosSpyPhotoRenderer(error: LumoError.renderFailed)
        let writer = SavePhotosSpyPhotoLibraryWriter(localIdentifier: "unused")
        let useCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: renderer,
            photoLibraryWriter: writer
        )

        await XCTAssertThrowsAsyncError(
            try await useCase.saveToPhotos(
                input: SaveAppliedPhotoToPhotosInput(
                    filmRollID: roll.id,
                    originalPhotoPath: "tmp/imports/target/original.jpg",
                    intensity: 65
                )
            )
        ) { error in
            XCTAssertEqual(error as? LumoError, .renderFailed)
        }

        XCTAssertEqual(repository.savedFilmRolls, [])
        XCTAssertEqual(writer.processedPaths, [])
        XCTAssertEqual(renderer.discardedResults, [])
    }
}

private final class SavePhotosSpyFilmRollRepository: FilmRollRepository, @unchecked Sendable {
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
    }

    func deleteFilmRoll(id: String) async throws {
        filmRollsByID[id] = nil
    }
}

private final class SavePhotosSpyPhotoRenderer: PhotoRendering, @unchecked Sendable {
    let result: PhotoRenderResult
    let error: Error?
    private(set) var requests: [PhotoRenderRequest] = []
    private(set) var discardedResults: [PhotoRenderResult] = []

    init(
        result: PhotoRenderResult = PhotoRenderResult(originalPath: "original.jpg", processedPath: "processed.jpg", thumbnailPath: "thumb.jpg", intensity: 100),
        error: Error? = nil
    ) {
        self.result = result
        self.error = error
    }

    func renderPhoto(for request: PhotoRenderRequest) async throws -> PhotoRenderResult {
        requests.append(request)
        if let error {
            throw error
        }
        return result
    }

    func discardRenderedPhoto(_ result: PhotoRenderResult) async {
        discardedResults.append(result)
    }
}

private final class SavePhotosSpyPhotoLibraryWriter: PhotoLibraryWriting, @unchecked Sendable {
    let localIdentifier: String
    let error: Error?
    private(set) var processedPaths: [String] = []

    init(localIdentifier: String = "local-id", error: Error? = nil) {
        self.localIdentifier = localIdentifier
        self.error = error
    }

    func savePhotoToLibrary(processedPath: String) async throws -> String {
        processedPaths.append(processedPath)
        if let error {
            throw error
        }
        return localIdentifier
    }
}

private final class SavePhotosStubReferenceImageDataLoader: FilmRollReferenceImageDataLoading, @unchecked Sendable {
    let data: Data
    private(set) var paths: [String] = []

    init(data: Data) {
        self.data = data
    }

    func loadReferenceImageData(at path: String) async throws -> Data {
        paths.append(path)
        return data
    }
}

private final class SavePhotosStubDiagnosticLUTGenerator: LUTGenerating, @unchecked Sendable {
    let lut: LUT3D
    private(set) var requests: [LUTGenerationRequest] = []

    init(lut: LUT3D) {
        self.lut = lut
    }

    func generateLUT(for request: LUTGenerationRequest) async throws -> LUT3D {
        requests.append(request)
        return lut
    }
}

private func savePhotosRoll(
    lut: LUT3D = LUT3D.identity(size: 2),
    sampleAnalysisPackage: SampleAnalysisPackage? = nil
) throws -> FilmRoll {
    try FilmRoll(
        id: "roll-1",
        name: "Photos Roll",
        referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
        lut: lut,
        sampleAnalysisPackage: sampleAnalysisPackage
    )
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
