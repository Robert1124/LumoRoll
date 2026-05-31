import Foundation

struct AppContainer {
    let appName: String
    let repository: FilmRollRepository
    let createFilmRollUseCase: CreateFilmRollUseCase
    let applyFilmRollUseCase: ApplyFilmRollUseCase
    let removeProcessedPhotoUseCase: RemoveProcessedPhotoUseCase
    let saveAppliedPhotoToPhotosUseCase: SaveAppliedPhotoToPhotosUseCase
    let renderApplyPreviewUseCase: RenderApplyPreviewUseCase
    let exportLUTUseCase: ExportLUTUseCase
    let photoImportStagingService: PhotoImportStagingService
    let assetURLResolver: AppAssetURLResolver
    let localPhotoImageLoader: LocalPhotoImageLoader
    private let photoLibraryWriter: PhotoLibraryWriting
    private let usesPreviewDisplayImageStore: Bool

    static let live: AppContainer = {
        let supportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return AppContainer.makeLive(assetStore: AssetStore(baseURL: supportURL))
    }()

    static let preview = AppContainer(repository: PreviewFilmRollRepository(filmRolls: PreviewFilmRollRepository.previewRolls))

    static func makeLive(assetStore: AssetStore) -> AppContainer {
        let repository = FileFilmRollRepository(assetStore: assetStore)
        let assetWriter = FileFilmRollAssetWriter(assetStore: assetStore)
        let photoRenderer = CoreImagePhotoRenderer(assetStore: assetStore)
        let referenceImageDataLoader = AssetStoreReferenceImageDataLoader(assetStore: assetStore)
        return AppContainer(
            repository: repository,
            assetStore: assetStore,
            lutGenerator: LUTGenerator(),
            lutImporter: CubeLUTImporter(),
            lutPreviewRenderer: CubeLUTPreviewRenderer(),
            thumbnailRenderer: CoreImageThumbnailRenderer(),
            assetWriter: assetWriter,
            photoRenderer: photoRenderer,
            photoPreviewRenderer: CoreImagePhotoPreviewRenderer(assetStore: assetStore),
            photoLibraryWriter: PhotoKitPhotoLibraryWriter(
                resolver: AppAssetURLResolver(assetStore: assetStore)
            ),
            lutExporter: CubeExporter(),
            referenceImageDataLoader: referenceImageDataLoader,
            diagnosticLUTGenerator: LUTGenerator(),
            usesPreviewDisplayImageStore: false
        )
    }

    init(
        appName: String = "LumoRoll",
        repository: FilmRollRepository,
        assetStore: AssetStore = AssetStore(baseURL: FileManager.default.temporaryDirectory),
        lutGenerator: LUTGenerating = PendingLUTGenerator(),
        lutImporter: LUTImporting = PendingLUTImporter(),
        lutPreviewRenderer: LUTPreviewRendering = PendingLUTPreviewRenderer(),
        thumbnailRenderer: ThumbnailRendering = PendingThumbnailRenderer(),
        assetWriter: FilmRollAssetWriting = PendingFilmRollAssetWriter(),
        photoRenderer: PhotoRendering = PendingPhotoRenderer(),
        photoPreviewRenderer: PhotoPreviewRendering = PendingPhotoPreviewRenderer(),
        photoLibraryWriter: PhotoLibraryWriting = PendingPhotoLibraryWriter(),
        lutExporter: LUTExporting = CubeExporter(),
        referenceImageDataLoader: FilmRollReferenceImageDataLoading? = nil,
        diagnosticLUTGenerator: LUTGenerating? = nil,
        usesPreviewDisplayImageStore: Bool = true
    ) {
        self.appName = appName
        self.repository = repository
        assetURLResolver = AppAssetURLResolver(assetStore: assetStore)
        photoImportStagingService = PhotoImportStagingService(assetStore: assetStore)
        localPhotoImageLoader = LocalPhotoImageLoader(resolver: assetURLResolver)
        self.photoLibraryWriter = photoLibraryWriter
        self.usesPreviewDisplayImageStore = usesPreviewDisplayImageStore
        createFilmRollUseCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: lutGenerator,
            lutImporter: lutImporter,
            lutPreviewRenderer: lutPreviewRenderer,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter
        )
        applyFilmRollUseCase = ApplyFilmRollUseCase(
            repository: repository,
            photoRenderer: photoRenderer,
            referenceImageDataLoader: referenceImageDataLoader,
            diagnosticLUTGenerator: diagnosticLUTGenerator
        )
        removeProcessedPhotoUseCase = RemoveProcessedPhotoUseCase(
            repository: repository,
            photoRenderer: photoRenderer
        )
        saveAppliedPhotoToPhotosUseCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: photoRenderer,
            photoLibraryWriter: photoLibraryWriter,
            referenceImageDataLoader: referenceImageDataLoader,
            diagnosticLUTGenerator: diagnosticLUTGenerator
        )
        renderApplyPreviewUseCase = RenderApplyPreviewUseCase(
            repository: repository,
            photoPreviewRenderer: photoPreviewRenderer,
            referenceImageDataLoader: referenceImageDataLoader,
            diagnosticLUTGenerator: diagnosticLUTGenerator
        )
        exportLUTUseCase = ExportLUTUseCase(
            repository: repository,
            lutExporter: lutExporter,
            assetWriter: assetWriter
        )
    }

    @MainActor
    func makeLibraryModel() -> LibraryFeatureModel {
        LibraryFeatureModel(repository: repository)
    }

    @MainActor
    func makeCreateFilmRollModel() -> CreateFilmRollFeatureModel {
        CreateFilmRollFeatureModel(createFilmRollUseCase: createFilmRollUseCase)
    }

    @MainActor
    func makeFilmRollDetailModel(filmRollID: String) -> FilmRollDetailFeatureModel {
        FilmRollDetailFeatureModel(
            filmRollID: filmRollID,
            repository: repository,
            exportLUTUseCase: exportLUTUseCase
        )
    }

    @MainActor
    func makeApplyPhotoModel(
        filmRollID: String,
        initialTargetPhotoPath: String? = nil,
        editContext: ApplyPhotoEditContext? = nil
    ) -> ApplyPhotoFeatureModel {
        ApplyPhotoFeatureModel(
            filmRollID: filmRollID,
            initialTargetPhotoPath: initialTargetPhotoPath,
            editContext: editContext,
            applyFilmRollUseCase: applyFilmRollUseCase,
            saveAppliedPhotoToPhotosUseCase: saveAppliedPhotoToPhotosUseCase,
            renderApplyPreviewUseCase: renderApplyPreviewUseCase
        )
    }

    @MainActor
    func makePhotoDisplayImageStore() -> PhotoDisplayImageStore {
        if usesPreviewDisplayImageStore {
            return .preview
        }
        return PhotoDisplayImageStore(loader: localPhotoImageLoader)
    }

    func saveExistingProcessedPhotoToPhotos(processedPath: String) async throws -> String {
        try await photoLibraryWriter.savePhotoToLibrary(processedPath: processedPath)
    }

    func removeProcessedPhoto(filmRollID: String, processedPhotoID: String) async throws -> FilmRoll {
        try await removeProcessedPhotoUseCase.removeProcessedPhoto(
            input: RemoveProcessedPhotoInput(filmRollID: filmRollID, processedPhotoID: processedPhotoID)
        )
    }
}

private struct PendingLUTGenerator: LUTGenerating {
    func generateLUT(for request: LUTGenerationRequest) async throws -> LUT3D {
        throw LumoError.importFailed
    }
}

private struct PendingThumbnailRenderer: ThumbnailRendering {
    func renderThumbnail(from imageData: Data) async throws -> Data {
        throw LumoError.importFailed
    }
}

private struct PendingLUTImporter: LUTImporting {
    func importLUT(fromCubeTextData data: Data) throws -> LUT3D {
        throw LumoError.importFailed
    }
}

private struct PendingLUTPreviewRenderer: LUTPreviewRendering {
    func renderPreviewImage(for lut: LUT3D) throws -> Data {
        throw LumoError.renderFailed
    }
}

private actor PendingFilmRollAssetWriter: FilmRollAssetWriting {
    func reserveFilmRollID() async throws -> String {
        throw LumoError.saveFailed
    }

    func storeReferenceImage(
        filmRollID: String,
        imageData: Data,
        thumbnailData: Data,
        preferredFileExtension: String?
    ) async throws -> FilmRollReferenceAsset {
        throw LumoError.saveFailed
    }

    func discardFilmRollAssets(filmRollID: String) async {}

    func writeCubeExport(filmRollID: String, cubeText: String, suggestedFilename: String) async throws -> URL {
        throw LumoError.exportFailed
    }
}

private actor PendingPhotoRenderer: PhotoRendering {
    func renderPhoto(for request: PhotoRenderRequest) async throws -> PhotoRenderResult {
        throw LumoError.renderFailed
    }

    func discardRenderedPhoto(_ result: PhotoRenderResult) async {}
}

private actor PendingPhotoPreviewRenderer: PhotoPreviewRendering {
    func renderPreview(for request: PhotoPreviewRenderRequest) async throws -> PhotoPreviewRenderResult {
        throw LumoError.renderFailed
    }

    func discardRenderedPreview(at relativePath: String) async {}
}

private struct PendingPhotoLibraryWriter: PhotoLibraryWriting {
    func savePhotoToLibrary(processedPath: String) async throws -> String {
        throw LumoError.saveFailed
    }
}

actor PreviewFilmRollRepository: FilmRollRepository {
    static let previewRolls: [FilmRoll] = [
        previewRoll(id: "warm-picnic", name: "Warm Picnic", daysAgo: 0, processedCount: 2),
        previewRoll(id: "tokyo-night", name: "Tokyo Night", daysAgo: 2, processedCount: 1),
        previewRoll(id: "soft-green", name: "Soft Green", daysAgo: 4, processedCount: 0),
        previewRoll(id: "creamy-street", name: "Creamy Street", daysAgo: 7, processedCount: 3)
    ].compactMap { $0 }

    private var filmRollsByID: [String: FilmRoll]

    init(filmRolls: [FilmRoll] = []) {
        filmRollsByID = Dictionary(uniqueKeysWithValues: filmRolls.map { ($0.id, $0) })
    }

    func loadFilmRolls() async throws -> [FilmRoll] {
        filmRollsByID.values.sorted { $0.createdAt > $1.createdAt }
    }

    func loadFilmRoll(id: String) async throws -> FilmRoll {
        guard let roll = filmRollsByID[id] else {
            throw LumoError.filmRollNotFound(id: id)
        }
        return roll
    }

    func saveFilmRoll(_ filmRoll: FilmRoll) async throws {
        filmRollsByID[filmRoll.id] = filmRoll
    }

    func deleteFilmRoll(id: String) async throws {
        filmRollsByID[id] = nil
    }

    private static func previewRoll(id: String, name: String, daysAgo: TimeInterval, processedCount: Int) -> FilmRoll? {
        let createdAt = Date(timeIntervalSince1970: 1_716_460_000 - (daysAgo * 86_400))
        let processedPhotos = (0..<processedCount).map { index in
            ProcessedPhoto(
                id: "\(id)-processed-\(index)",
                originalPath: "preview/original-\(index).jpg",
                processedPath: "preview/processed-\(index).jpg",
                thumbnailPath: "preview/thumb-\(index).jpg",
                createdAt: createdAt,
                intensity: Double(80 - index)
            )
        }
        return try? FilmRoll(
            id: id,
            name: name,
            createdAt: createdAt,
            referenceAsset: FilmRollReferenceAsset(
                originalPath: "preview/reference.jpg",
                thumbnailPath: "preview/reference-thumb.jpg"
            ),
            lut: LUT3D.identity(),
            palette: LumoPreviewFixtures.palette,
            processedPhotos: processedPhotos
        )
    }
}
