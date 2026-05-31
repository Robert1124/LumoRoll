import XCTest
@testable import LumoRoll

final class RenderApplyPreviewUseCaseTests: XCTestCase {
    func testRenderPreviewLoadsRollRendersTemporaryPreviewAndDoesNotSaveRoll() async throws {
        let repository = PreviewUseCaseSpyFilmRollRepository()
        let samplePackage = modelAssistedTestSampleAnalysisPackage()
        let roll = try previewUseCaseRoll(sampleAnalysisPackage: samplePackage)
        repository.filmRollsByID[roll.id] = roll
        let renderResult = PhotoPreviewRenderResult(
            previewID: "preview-1",
            originalPath: "tmp/imports/target.jpg",
            previewPath: "tmp/apply-previews/preview-1/preview.jpg",
            intensity: 37
        )
        let renderer = PreviewUseCaseSpyPhotoPreviewRenderer(result: renderResult)
        let useCase = RenderApplyPreviewUseCase(
            repository: repository,
            photoPreviewRenderer: renderer,
            previewIDGenerator: { "preview-1" }
        )

        let result = try await useCase.renderPreview(
            input: RenderApplyPreviewInput(
                filmRollID: roll.id,
                originalPhotoPath: "tmp/imports/target.jpg",
                intensity: 37,
                maxPixelDimension: 720
            )
        )

        XCTAssertEqual(result, renderResult)
        XCTAssertEqual(repository.loadedIDs, [roll.id])
        XCTAssertEqual(repository.savedFilmRolls, [])
        XCTAssertEqual(renderer.requests, [
            PhotoPreviewRenderRequest(
                filmRollID: roll.id,
                previewID: "preview-1",
                originalPath: "tmp/imports/target.jpg",
                lut: roll.lut,
                intensity: 37,
                maxPixelDimension: 720,
                sampleAnalysisPackage: samplePackage
            )
        ])
    }

    func testDiscardPreviewDelegatesToRenderer() async {
        let renderer = PreviewUseCaseSpyPhotoPreviewRenderer()
        let useCase = RenderApplyPreviewUseCase(
            repository: PreviewUseCaseSpyFilmRollRepository(),
            photoPreviewRenderer: renderer
        )

        await useCase.discardPreview(path: "tmp/apply-previews/preview-1/preview.jpg")

        XCTAssertEqual(renderer.discardedPaths, ["tmp/apply-previews/preview-1/preview.jpg"])
    }

    func testRenderPreviewCanDisableAdaptivePostProcess() async throws {
        let repository = PreviewUseCaseSpyFilmRollRepository()
        let samplePackage = modelAssistedTestSampleAnalysisPackage()
        let roll = try previewUseCaseRoll(sampleAnalysisPackage: samplePackage)
        repository.filmRollsByID[roll.id] = roll
        let renderer = PreviewUseCaseSpyPhotoPreviewRenderer()
        let useCase = RenderApplyPreviewUseCase(
            repository: repository,
            photoPreviewRenderer: renderer,
            previewIDGenerator: { "preview-disabled" }
        )

        _ = try await useCase.renderPreview(
            input: RenderApplyPreviewInput(
                filmRollID: roll.id,
                originalPhotoPath: "tmp/imports/target.jpg",
                intensity: 64,
                maxPixelDimension: 720,
                isAdaptivePostProcessEnabled: false
            )
        )

        XCTAssertEqual(renderer.requests.first?.sampleAnalysisPackage, samplePackage)
        XCTAssertEqual(renderer.requests.first?.isAdaptivePostProcessEnabled, false)
    }

    func testRenderPreviewCanUseTransientAlgorithmV2LUTWithoutSavingRoll() async throws {
        let repository = PreviewUseCaseSpyFilmRollRepository()
        let savedLUT = LUT3D.identity(size: 2, algorithmVersion: "private.model.v1")
        let transientV2LUT = LUT3D.identity(size: 2, algorithmVersion: LUT3D.defaultAlgorithmVersion)
        let roll = try previewUseCaseRoll(lut: savedLUT)
        repository.filmRollsByID[roll.id] = roll
        let referenceData = Data([0xCA, 0xFE])
        let referenceLoader = PreviewUseCaseStubReferenceImageDataLoader(data: referenceData)
        let lutGenerator = PreviewUseCaseStubLUTGenerator(lut: transientV2LUT)
        let renderer = PreviewUseCaseSpyPhotoPreviewRenderer()
        let useCase = RenderApplyPreviewUseCase(
            repository: repository,
            photoPreviewRenderer: renderer,
            referenceImageDataLoader: referenceLoader,
            diagnosticLUTGenerator: lutGenerator,
            previewIDGenerator: { "preview-v2" }
        )

        _ = try await useCase.renderPreview(
            input: RenderApplyPreviewInput(
                filmRollID: roll.id,
                originalPhotoPath: "tmp/imports/target.jpg",
                intensity: 64,
                maxPixelDimension: 720,
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
}

private final class PreviewUseCaseSpyFilmRollRepository: FilmRollRepository, @unchecked Sendable {
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

private final class PreviewUseCaseSpyPhotoPreviewRenderer: PhotoPreviewRendering, @unchecked Sendable {
    let result: PhotoPreviewRenderResult
    private(set) var requests: [PhotoPreviewRenderRequest] = []
    private(set) var discardedPaths: [String] = []

    init(
        result: PhotoPreviewRenderResult = PhotoPreviewRenderResult(
            previewID: "preview",
            originalPath: "original.jpg",
            previewPath: "tmp/apply-previews/preview/preview.jpg",
            intensity: 100
        )
    ) {
        self.result = result
    }

    func renderPreview(for request: PhotoPreviewRenderRequest) async throws -> PhotoPreviewRenderResult {
        requests.append(request)
        return result
    }

    func discardRenderedPreview(at relativePath: String) async {
        discardedPaths.append(relativePath)
    }
}

private final class PreviewUseCaseStubReferenceImageDataLoader: FilmRollReferenceImageDataLoading, @unchecked Sendable {
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

private final class PreviewUseCaseStubLUTGenerator: LUTGenerating, @unchecked Sendable {
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

private func previewUseCaseRoll(
    lut: LUT3D = LUT3D.identity(size: 2),
    sampleAnalysisPackage: SampleAnalysisPackage? = nil
) throws -> FilmRoll {
    try FilmRoll(
        id: "roll-1",
        name: "Preview Roll",
        referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
        lut: lut,
        sampleAnalysisPackage: sampleAnalysisPackage
    )
}
