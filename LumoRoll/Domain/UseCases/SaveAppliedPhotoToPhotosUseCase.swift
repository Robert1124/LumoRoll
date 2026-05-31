import Foundation

struct SaveAppliedPhotoToPhotosInput: Equatable, Sendable {
    let filmRollID: String
    let originalPhotoPath: String
    let intensity: Double
    let isAdaptivePostProcessEnabled: Bool
    let lutSourceMode: ApplyLUTSourceMode

    init(
        filmRollID: String,
        originalPhotoPath: String,
        intensity: Double,
        isAdaptivePostProcessEnabled: Bool = true,
        lutSourceMode: ApplyLUTSourceMode = .saved
    ) {
        self.filmRollID = filmRollID
        self.originalPhotoPath = originalPhotoPath
        self.intensity = intensity
        self.isAdaptivePostProcessEnabled = isAdaptivePostProcessEnabled
        self.lutSourceMode = lutSourceMode
    }
}

struct SaveAppliedPhotoToPhotosResult: Equatable, Sendable {
    let localIdentifier: String
}

struct SaveAppliedPhotoToPhotosUseCase: Sendable {
    private let repository: FilmRollRepository
    private let photoRenderer: PhotoRendering
    private let photoLibraryWriter: PhotoLibraryWriting
    private let lutResolver: ApplyLUTResolver
    private let processedPhotoIDGenerator: @Sendable () -> String

    init(
        repository: FilmRollRepository,
        photoRenderer: PhotoRendering,
        photoLibraryWriter: PhotoLibraryWriting,
        referenceImageDataLoader: FilmRollReferenceImageDataLoading? = nil,
        diagnosticLUTGenerator: LUTGenerating? = nil,
        processedPhotoIDGenerator: @escaping @Sendable () -> String = { UUID().uuidString }
    ) {
        self.repository = repository
        self.photoRenderer = photoRenderer
        self.photoLibraryWriter = photoLibraryWriter
        lutResolver = ApplyLUTResolver(
            referenceImageDataLoader: referenceImageDataLoader,
            diagnosticLUTGenerator: diagnosticLUTGenerator
        )
        self.processedPhotoIDGenerator = processedPhotoIDGenerator
    }

    func saveToPhotos(input: SaveAppliedPhotoToPhotosInput) async throws -> SaveAppliedPhotoToPhotosResult {
        let roll = try await repository.loadFilmRoll(id: input.filmRollID)
        let renderLUT = try await lutResolver.lut(for: roll, sourceMode: input.lutSourceMode)
        let renderResult = try await photoRenderer.renderPhoto(
            for: PhotoRenderRequest(
                filmRollID: roll.id,
                processedPhotoID: processedPhotoIDGenerator(),
                originalPath: input.originalPhotoPath,
                lut: renderLUT,
                intensity: input.intensity,
                sampleAnalysisPackage: roll.sampleAnalysisPackage,
                isAdaptivePostProcessEnabled: input.isAdaptivePostProcessEnabled
            )
        )

        do {
            let localIdentifier = try await photoLibraryWriter.savePhotoToLibrary(processedPath: renderResult.processedPath)
            await photoRenderer.discardRenderedPhoto(renderResult)
            return SaveAppliedPhotoToPhotosResult(localIdentifier: localIdentifier)
        } catch {
            await photoRenderer.discardRenderedPhoto(renderResult)
            throw error
        }
    }
}
