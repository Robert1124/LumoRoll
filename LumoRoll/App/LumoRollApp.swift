import SwiftUI

@main
struct LumoRollApp: App {
    private let container = AppContainer.live

    var body: some Scene {
        WindowGroup {
            LumoRollRootView(container: container)
        }
    }
}

struct LumoRollRootView: View {
    let container: AppContainer

    @State private var path: [AppRoute] = []
    @State private var fullscreenRoute: FullscreenViewerRoute?
    @State private var libraryModel: LibraryFeatureModel
    @State private var photoDisplayImageStore: PhotoDisplayImageStore
    @State private var detailReloadTokens: [String: Int] = [:]

    init(container: AppContainer) {
        self.container = container
        _libraryModel = State(initialValue: container.makeLibraryModel())
        _photoDisplayImageStore = State(initialValue: container.makePhotoDisplayImageStore())
    }

    var body: some View {
        NavigationStack(path: $path) {
            LibraryScreen(
                model: libraryModel,
                photoDisplayImageStore: photoDisplayImageStore
            )
                .navigationDestination(for: AppRoute.self) { route in
                    destination(for: route)
                }
        }
        .tint(LumoTheme.Colors.textPrimary)
        .fullScreenCover(item: $fullscreenRoute) { route in
            FullscreenViewerScreen(
                filmRoll: route.filmRoll,
                startIndex: route.startIndex,
                photoDisplayImageStore: photoDisplayImageStore,
                onClose: { fullscreenRoute = nil },
                shareURLResolver: container.assetURLResolver.resolve,
                onEditProcessedPhoto: { filmRoll, photo in
                    fullscreenRoute = nil
                    path.append(
                        .applyPhoto(
                            filmRollID: filmRoll.id,
                            initialImportSource: nil,
                            initialTargetPhotoPath: nil,
                            editContext: ApplyPhotoEditContext(
                                processedPhotoID: photo.id,
                                originalPhotoPath: photo.originalPath,
                                intensity: photo.intensity
                            )
                        )
                    )
                },
                onRemoveProcessedPhoto: { filmRoll, photo in
                    let updatedRoll = try await container.removeProcessedPhoto(
                        filmRollID: filmRoll.id,
                        processedPhotoID: photo.id
                    )
                    bumpDetailReloadToken(for: filmRoll.id)
                    Task { await libraryModel.reload() }
                    return updatedRoll
                }
            )
        }
        .onChange(of: libraryModel.pendingIntent, initial: false) { _, intent in
            guard let intent else {
                return
            }
            switch intent {
            case .createFilmRoll:
                path.append(.createFilmRoll)
            case .openFilmRoll(let id):
                path.append(.filmRollDetail(id: id))
            }
            libraryModel.clearPendingIntent()
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .createFilmRoll:
            CreateFilmRollModelHost(
                model: container.makeCreateFilmRollModel(),
                photoImportStagingService: container.photoImportStagingService,
                assetURLResolver: container.assetURLResolver,
                photoDisplayImageStore: photoDisplayImageStore,
                onClose: { path.removeLastIfPossible() },
                onSaved: { _ in
                    path.removeLastIfPossible()
                    Task { await libraryModel.reload() }
                }
            )
        case .filmRollDetail(let id):
            FilmRollDetailModelHost(
                model: container.makeFilmRollDetailModel(filmRollID: id),
                photoDisplayImageStore: photoDisplayImageStore,
                photoImportStagingService: container.photoImportStagingService,
                reloadToken: detailReloadTokens[id, default: 0],
                onBack: {
                    path.removeLastIfPossible()
                    Task { await libraryModel.reload() }
                },
                onApply: { filmRollID, source, initialTargetPhotoPath in
                    path.append(
                        .applyPhoto(
                            filmRollID: filmRollID,
                            initialImportSource: source,
                            initialTargetPhotoPath: initialTargetPhotoPath
                        )
                    )
                },
                onRemoved: {
                    path.removeLastIfPossible()
                    Task { await libraryModel.reload() }
                },
                onOpenFrame: { filmRoll, index in fullscreenRoute = FullscreenViewerRoute(filmRoll: filmRoll, startIndex: index) }
            )
        case .applyPhoto(let filmRollID, let initialImportSource, let initialTargetPhotoPath, let editContext):
            ApplyPhotoModelHost(
                model: container.makeApplyPhotoModel(
                    filmRollID: filmRollID,
                    initialTargetPhotoPath: initialTargetPhotoPath,
                    editContext: editContext
                ),
                rollLoader: { try await container.repository.loadFilmRoll(id: filmRollID) },
                photoImportStagingService: container.photoImportStagingService,
                photoDisplayImageStore: photoDisplayImageStore,
                initialImportSource: initialImportSource,
                onBack: { path.removeLastIfPossible() },
                onSavedToRoll: {
                    path.removeLastIfPossible()
                    bumpDetailReloadToken(for: filmRollID)
                    Task { await libraryModel.reload() }
                }
            )
        }
    }

    private func bumpDetailReloadToken(for filmRollID: String) {
        detailReloadTokens[filmRollID, default: 0] += 1
    }
}

#Preview {
    LumoRollRootView(container: .preview)
}

private extension Array {
    mutating func removeLastIfPossible() {
        guard !isEmpty else {
            return
        }
        removeLast()
    }
}
