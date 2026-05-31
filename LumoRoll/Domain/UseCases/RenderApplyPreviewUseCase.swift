import Foundation

struct RenderApplyPreviewInput: Equatable, Sendable {
    let filmRollID: String
    let originalPhotoPath: String
    let intensity: Double
    let maxPixelDimension: Int
    let isAdaptivePostProcessEnabled: Bool
    let lutSourceMode: ApplyLUTSourceMode

    init(
        filmRollID: String,
        originalPhotoPath: String,
        intensity: Double,
        maxPixelDimension: Int = 1_200,
        isAdaptivePostProcessEnabled: Bool = true,
        lutSourceMode: ApplyLUTSourceMode = .saved
    ) {
        self.filmRollID = filmRollID
        self.originalPhotoPath = originalPhotoPath
        self.intensity = intensity.clampedToLumoPercentage
        self.maxPixelDimension = max(1, maxPixelDimension)
        self.isAdaptivePostProcessEnabled = isAdaptivePostProcessEnabled
        self.lutSourceMode = lutSourceMode
    }
}

struct RenderApplyPreviewUseCase: Sendable {
    private let repository: FilmRollRepository
    private let photoPreviewRenderer: PhotoPreviewRendering
    private let lutResolver: ApplyLUTResolver
    private let previewIDGenerator: @Sendable () -> String

    init(
        repository: FilmRollRepository,
        photoPreviewRenderer: PhotoPreviewRendering,
        referenceImageDataLoader: FilmRollReferenceImageDataLoading? = nil,
        diagnosticLUTGenerator: LUTGenerating? = nil,
        previewIDGenerator: @escaping @Sendable () -> String = { UUID().uuidString }
    ) {
        self.repository = repository
        self.photoPreviewRenderer = photoPreviewRenderer
        lutResolver = ApplyLUTResolver(
            referenceImageDataLoader: referenceImageDataLoader,
            diagnosticLUTGenerator: diagnosticLUTGenerator
        )
        self.previewIDGenerator = previewIDGenerator
    }

    func renderPreview(input: RenderApplyPreviewInput) async throws -> PhotoPreviewRenderResult {
        let roll = try await repository.loadFilmRoll(id: input.filmRollID)
        let renderLUT = try await lutResolver.lut(for: roll, sourceMode: input.lutSourceMode)
        return try await photoPreviewRenderer.renderPreview(
            for: PhotoPreviewRenderRequest(
                filmRollID: roll.id,
                previewID: previewIDGenerator(),
                originalPath: input.originalPhotoPath,
                lut: renderLUT,
                intensity: input.intensity,
                maxPixelDimension: input.maxPixelDimension,
                sampleAnalysisPackage: roll.sampleAnalysisPackage,
                isAdaptivePostProcessEnabled: input.isAdaptivePostProcessEnabled
            )
        )
    }

    func discardPreview(path: String) async {
        await photoPreviewRenderer.discardRenderedPreview(at: path)
    }
}
