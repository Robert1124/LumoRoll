import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct ApplyTargetPhotoTile: Identifiable, Equatable {
    enum Kind: Equatable {
        case importTarget
        case selectedTarget
        case addTarget
    }

    let kind: Kind

    var id: String {
        switch kind {
        case .importTarget:
            "import-target"
        case .selectedTarget:
            "selected-target"
        case .addTarget:
            "add-target"
        }
    }

    var label: String {
        switch kind {
        case .importTarget:
            "Import target"
        case .selectedTarget:
            "Selected target"
        case .addTarget:
            "Add"
        }
    }

    var accessibilityLabel: String {
        switch kind {
        case .importTarget:
            "Import target photo"
        case .selectedTarget:
            "Change target photo"
        case .addTarget:
            "Add target photo"
        }
    }

    var isSelected: Bool {
        kind == .selectedTarget || kind == .importTarget
    }

    var style: LumoPhotoPlaceholder.Style {
        isSelected ? .thumbnail : .addPhoto
    }

    var triggersImportBoundary: Bool {
        true
    }

    static func tiles(selectedTargetPhotoPath: String?) -> [ApplyTargetPhotoTile] {
        [
            ApplyTargetPhotoTile(kind: selectedTargetPhotoPath == nil ? .importTarget : .selectedTarget),
            ApplyTargetPhotoTile(kind: .addTarget)
        ]
    }
}

enum ApplyTargetImportCleanupDecision {
    static func pathToDiscardAfterSelection(
        previousPath: String?,
        stagedPath: String,
        selectedPathAfterSelection: String?
    ) -> String? {
        guard selectedPathAfterSelection != stagedPath else {
            if previousPath != stagedPath,
               selectedPathAfterSelection != previousPath {
                return previousPath
            }
            return nil
        }

        return stagedPath
    }
}

enum ApplyCloseDecision {
    static func shouldCloseAndDiscard(isSaving: Bool) -> Bool {
        !isSaving
    }
}

enum ApplyPreviewChromeVisibility {
    static func shouldShowPreviewChrome(selectedTargetPhotoPath: String?) -> Bool {
        guard let selectedTargetPhotoPath else {
            return false
        }

        return !selectedTargetPhotoPath.isEmpty
    }
}

enum ApplyImportControlsVisibility {
    static func shouldShowImportControls(selectedTargetPhotoPath: String?) -> Bool {
        guard let selectedTargetPhotoPath else {
            return true
        }

        return selectedTargetPhotoPath.isEmpty
    }
}

enum ApplyBottomActionsVisibility {
    static func shouldShowActions(selectedTargetPhotoPath: String?) -> Bool {
        ApplyPreviewChromeVisibility.shouldShowPreviewChrome(selectedTargetPhotoPath: selectedTargetPhotoPath)
    }
}

enum ApplyBottomActionCopy {
    static let saveTitle = "Save"
    static let cancelTitle = "Cancel"
}

enum ApplyDiagnosticControlsVisibility {
    static let showsTemporaryPostAndLUTButtons = false
}

enum ApplyTargetImportPresentation: Equatable {
    case photosPicker
    case fileImporter
}

enum ApplyTargetImportSource: CaseIterable, Equatable, Hashable, Identifiable {
    case photoLibrary
    case files

    var id: String {
        switch self {
        case .photoLibrary:
            "photo-library"
        case .files:
            "files"
        }
    }

    var label: String {
        switch self {
        case .photoLibrary:
            "Photo Library"
        case .files:
            "Files"
        }
    }

    var presentation: ApplyTargetImportPresentation {
        switch self {
        case .photoLibrary:
            .photosPicker
        case .files:
            .fileImporter
        }
    }
}

enum ApplyInitialImportPresentationDecision {
    static func presentation(initialImportSource: ApplyTargetImportSource?) -> ApplyTargetImportPresentation? {
        initialImportSource?.presentation
    }
}

struct ApplyTargetImportSaveActions: Equatable {
    let saveToFilmRoll: Bool
    let saveToPhotos: Bool
}

enum ApplyTargetImportSaveDecision {
    static func actionsAfterSelectingTarget(
        selectedTargetPhotoPath: String?,
        isSaving: Bool
    ) -> ApplyTargetImportSaveActions {
        guard !isSaving,
              let selectedTargetPhotoPath,
              !selectedTargetPhotoPath.isEmpty else {
            return ApplyTargetImportSaveActions(saveToFilmRoll: false, saveToPhotos: false)
        }

        return ApplyTargetImportSaveActions(saveToFilmRoll: false, saveToPhotos: false)
    }
}

enum ApplyPreviewLayout {
    static let previewHeightFraction: CGFloat = 0.50
    static let minimumPreviewHeight: CGFloat = 260
    static let maximumPreviewHeight: CGFloat = 430

    static func frameAspectRatio(forLoadedImageAspectRatio aspectRatio: CGFloat?) -> CGFloat {
        LumoPreviewAspectRatio.sanitized(aspectRatio)
    }

    static func previewMaxHeight(forContainerHeight containerHeight: CGFloat) -> CGFloat {
        let preferredHeight = max(containerHeight, 0) * previewHeightFraction
        return min(max(preferredHeight, minimumPreviewHeight), maximumPreviewHeight)
    }
}

private struct ApplyPreviewRenderTrigger: Equatable {
    let targetPath: String?
    let intensity: Double
    let isAdaptivePostProcessEnabled: Bool
    let isUsingAlgorithmV2DiagnosticLUT: Bool
}

struct ApplyPhotoModelHost: View {
    let model: ApplyPhotoFeatureModel
    let rollLoader: () async throws -> FilmRoll
    let photoImportStagingService: PhotoImportStagingService
    let photoDisplayImageStore: PhotoDisplayImageStore
    let initialImportSource: ApplyTargetImportSource?
    let onBack: () -> Void
    let onSavedToRoll: () -> Void

    @State private var roll: FilmRoll?
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if let roll {
                ApplyPhotoScreen(
                    model: model,
                    filmRoll: roll,
                    photoImportStagingService: photoImportStagingService,
                    photoDisplayImageStore: photoDisplayImageStore,
                    initialImportSource: initialImportSource,
                    onBack: onBack,
                    onSavedToRoll: onSavedToRoll
                )
            } else if let errorMessage {
                VStack(spacing: LumoTheme.Spacing.medium) {
                    Text("Film Roll unavailable")
                        .font(LumoTheme.Typography.headline)
                    Text(errorMessage)
                        .font(LumoTheme.Typography.callout)
                        .foregroundStyle(LumoTheme.Colors.textSecondary)
                    LumoPillButton(title: "Back", systemImage: "chevron.left", action: onBack)
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(LumoTheme.Colors.appBackground.ignoresSafeArea())
            } else {
                ProgressView("Loading Film Roll...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(LumoTheme.Colors.appBackground.ignoresSafeArea())
            }
        }
        .task {
            do {
                roll = try await rollLoader()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

struct ApplyPhotoScreen: View {
    let model: ApplyPhotoFeatureModel
    let filmRoll: FilmRoll
    let photoImportStagingService: PhotoImportStagingService
    let photoDisplayImageStore: PhotoDisplayImageStore
    var initialImportSource: ApplyTargetImportSource?
    var onBack: () -> Void
    var onSavedToRoll: () -> Void

    @State private var splitFraction = LumoSplitPosition.defaultFraction
    @State private var targetImportMessage: String?
    @State private var selectedTargetPhotosItem: PhotosPickerItem?
    @State private var isPhotosPickerPresented = false
    @State private var isImportSourceDialogPresented = false
    @State private var isFileImporterPresented = false
    @State private var didPresentInitialImportSource = false
    @State private var targetImportGeneration = 0

    private static let previewMaxPixelDimension = 1_200

    var body: some View {
        @Bindable var model = model

        GeometryReader { proxy in
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: LumoTheme.Spacing.small) {
                    header
                    if shouldShowPreviewChrome {
                        selectedPreviewContent(
                            intensity: $model.intensity,
                            maxPreviewHeight: ApplyPreviewLayout.previewMaxHeight(
                                forContainerHeight: proxy.size.height
                            )
                        )
                    } else if shouldShowImportControls {
                        VStack(spacing: LumoTheme.Spacing.small) {
                            importTargetPanel
                            targetImportStatus
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    }
                    saveStateMessage
                    Spacer(minLength: 0)
                }
                .padding(.horizontal, LumoTheme.Spacing.medium)
                .padding(.top, LumoTheme.Spacing.small)
                .padding(.bottom, LumoTheme.Spacing.small)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                if shouldShowBottomActions {
                    bottomActions
                }
            }
        }
        .background(LumoTheme.Colors.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .confirmationDialog(
            "Import target",
            isPresented: $isImportSourceDialogPresented,
            titleVisibility: .visible
        ) {
            ForEach(ApplyTargetImportSource.allCases) { source in
                Button(source.label) {
                    presentImportSource(source)
                }
            }
        }
        .photosPicker(
            isPresented: $isPhotosPickerPresented,
            selection: $selectedTargetPhotosItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: Self.allowedImportContentTypes,
            allowsMultipleSelection: false
        ) { result in
            Task { await importTargetFile(result) }
        }
        .onChange(of: selectedTargetPhotosItem, initial: false) { _, item in
            Task { await importTargetPhotosItem(item) }
        }
        .onChange(of: model.saveState, initial: false) { _, saveState in
            if case .saved = saveState {
                Task { @MainActor in
                    await model.discardPreview()
                    discardCurrentTargetImport()
                    onSavedToRoll()
                }
            }
        }
        .task(id: previewRenderTrigger) {
            guard shouldShowPreviewChrome else {
                return
            }

            await model.renderPreview(maxPixelDimension: Self.previewMaxPixelDimension)
        }
        .task(id: initialImportTaskID) {
            await presentInitialImportSourceIfNeeded()
        }
    }

    @ViewBuilder
    private func selectedPreviewContent(intensity: Binding<Double>, maxPreviewHeight: CGFloat) -> some View {
        PreviewModeSegmentedControl(selection: previewModeBinding)
        preview
            .frame(maxHeight: maxPreviewHeight)
            .frame(maxWidth: .infinity)
        LumoIntensitySlider(intensity: intensity)
            .frame(maxWidth: .infinity)
    }

    private var header: some View {
        HStack {
            LumoIconButton(systemImage: "chevron.left", accessibilityLabel: "Back", action: closeAndDiscard)
                .disabled(model.isSaving)
            Spacer()
            VStack(spacing: LumoTheme.Spacing.xxSmall) {
                Text(model.isEditingExistingProcessedPhoto ? "Editing" : "Applying")
                    .font(LumoTheme.Typography.technicalLabel)
                    .tracking(1)
                    .foregroundStyle(LumoTheme.Colors.textTertiary)
                Text(filmRoll.name)
                    .font(LumoTheme.Typography.headline)
                    .foregroundStyle(LumoTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Color.clear.frame(width: LumoTheme.Metrics.minimumHitTarget, height: LumoTheme.Metrics.minimumHitTarget)
        }
    }

    private var preview: some View {
        SplitPreview(
            mode: previewModeBinding.wrappedValue,
            aspectRatio: previewAspectRatio,
            splitFraction: $splitFraction
        ) {
            originalTargetPreviewImage(title: "Before")
        } after: {
            renderedTargetPreviewImage(title: filmRoll.name)
        }
    }

    private var importTargetPanel: some View {
        Button {
            isImportSourceDialogPresented = true
        } label: {
            LumoPhotoPlaceholder(style: .addPhoto, title: "Import target")
                .frame(maxWidth: .infinity)
                .aspectRatio(1.12, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: LumoTheme.Radius.preview, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: LumoTheme.Radius.preview, style: .continuous)
                        .stroke(LumoTheme.Colors.hairline, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Import target photo")
        .accessibilityHint("Choose Photo Library or Files")
        .disabled(model.isSaving)
        .frame(maxWidth: 300)
    }

    private var bottomActions: some View {
        HStack(spacing: LumoTheme.Spacing.small) {
            LumoPillButton(
                title: ApplyBottomActionCopy.cancelTitle,
                systemImage: "xmark",
                variant: .secondary,
                isFullWidth: true,
                action: closeAndDiscard
            )
            .disabled(model.isSaving)

            LumoPillButton(
                title: ApplyBottomActionCopy.saveTitle,
                systemImage: "checkmark",
                variant: .primary,
                isLoading: model.saveState == .saving,
                isFullWidth: true
            ) {
                Task { await model.saveToFilmRoll() }
            }
            .disabled(!model.canSaveToFilmRoll || model.isSaving)
        }
        .padding(.horizontal, LumoTheme.Spacing.medium)
        .padding(.top, LumoTheme.Spacing.small)
        .padding(.bottom, LumoTheme.Spacing.medium)
        .background(.ultraThinMaterial)
    }

    private func targetTile(_ tile: ApplyTargetPhotoTile) -> some View {
        Button {
            isFileImporterPresented = true
        } label: {
            targetTileContent(tile)
                .frame(width: 68, height: 86)
                .clipShape(RoundedRectangle(cornerRadius: LumoTheme.Radius.thumbnail, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: LumoTheme.Radius.thumbnail, style: .continuous)
                        .stroke(tile.isSelected ? LumoTheme.Colors.textPrimary : LumoTheme.Colors.hairlineStrong, lineWidth: tile.isSelected ? 2 : 1)
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tile.accessibilityLabel)
        .disabled(model.isSaving)
    }

    @ViewBuilder
    private func targetTileContent(_ tile: ApplyTargetPhotoTile) -> some View {
        if tile.kind == .selectedTarget {
            PhotoDisplayImageView(
                store: photoDisplayImageStore,
                relativePath: model.selectedTargetPhotoPath,
                maxPixelDimension: 240,
                contentMode: .fill
            ) {
                LumoPhotoPlaceholder(style: tile.style, title: tile.label)
            }
        } else {
            LumoPhotoPlaceholder(style: tile.style, title: tile.label)
        }
    }

    private func originalTargetPreviewImage(title: String) -> some View {
        PhotoDisplayImageView(
            store: photoDisplayImageStore,
            relativePath: model.selectedTargetPhotoPath,
            maxPixelDimension: Self.previewMaxPixelDimension,
            contentMode: .fill
        ) {
            LumoPhotoPlaceholder(
                style: model.selectedTargetPhotoPath == nil ? .addPhoto : .thumbnail,
                title: model.selectedTargetPhotoPath == nil ? "Import target" : title
            )
        }
    }

    private func renderedTargetPreviewImage(title: String) -> some View {
        PhotoDisplayImageView(
            store: photoDisplayImageStore,
            relativePath: model.renderedPreviewPhotoPath,
            maxPixelDimension: Self.previewMaxPixelDimension,
            contentMode: .fill
        ) {
            renderedPreviewPlaceholder(title: title)
        }
        .overlay(alignment: .bottom) {
            if case .rendering = model.previewState,
               model.renderedPreviewPhotoPath != nil {
                ProgressView()
                    .controlSize(.small)
                    .padding(LumoTheme.Spacing.small)
                    .background(.ultraThinMaterial, in: Capsule())
                    .padding(LumoTheme.Spacing.small)
            }
        }
    }

    @ViewBuilder
    private func renderedPreviewPlaceholder(title: String) -> some View {
        switch model.previewState {
        case .idle:
            LumoPhotoPlaceholder(
                style: model.selectedTargetPhotoPath == nil ? .addPhoto : .thumbnail,
                title: model.selectedTargetPhotoPath == nil ? "Import target" : title
            )
        case .rendering:
            ZStack {
                LumoPhotoPlaceholder(style: .thumbnail, title: "Rendering")
                ProgressView()
                    .controlSize(.regular)
                    .padding(.top, 64)
            }
        case .ready:
            LumoPhotoPlaceholder(style: .thumbnail, title: title)
        case .failed(let message, _):
            ZStack {
                LumoPhotoPlaceholder(style: .unavailable, title: "Preview failed")
                Text(message)
                    .font(LumoTheme.Typography.label)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LumoTheme.Colors.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.76)
                    .padding(LumoTheme.Spacing.medium)
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
        }
    }

    @ViewBuilder
    private var targetImportStatus: some View {
        if let targetImportMessage {
            Text(targetImportMessage)
                .font(LumoTheme.Typography.label)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var saveStateMessage: some View {
        switch model.saveState {
        case .idle:
            EmptyView()
        case .saving:
            Text("Saving to \(filmRoll.name)...")
                .font(LumoTheme.Typography.label)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
        case .saved:
            EmptyView()
        case .failed(let message):
            Text(message)
                .font(LumoTheme.Typography.label)
                .foregroundStyle(.red)
        }
        switch model.saveToPhotosState {
        case .idle:
            EmptyView()
        case .saving:
            Text("Saving to Photos...")
                .font(LumoTheme.Typography.label)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
        case .saved:
            Text("Saved to Photos.")
                .font(LumoTheme.Typography.label)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
        case .failed(let message):
            Text(message)
                .font(LumoTheme.Typography.label)
                .foregroundStyle(.red)
        }
    }

    private var previewModeBinding: Binding<LumoPreviewMode> {
        Binding(
            get: {
                switch model.previewMode {
                case .before:
                    return .before
                case .split:
                    return .split
                case .after:
                    return .after
                }
            },
            set: { mode in
                switch mode {
                case .before:
                    model.previewMode = .before
                case .split:
                    model.previewMode = .split
                case .after:
                    model.previewMode = .after
                }
            }
        )
    }

    private var previewRenderTrigger: ApplyPreviewRenderTrigger {
        ApplyPreviewRenderTrigger(
            targetPath: model.selectedTargetPhotoPath,
            intensity: model.intensity,
            isAdaptivePostProcessEnabled: model.isAdaptivePostProcessEnabled,
            isUsingAlgorithmV2DiagnosticLUT: model.isUsingAlgorithmV2DiagnosticLUT
        )
    }

    private var shouldShowPreviewChrome: Bool {
        ApplyPreviewChromeVisibility.shouldShowPreviewChrome(selectedTargetPhotoPath: model.selectedTargetPhotoPath)
    }

    private var shouldShowImportControls: Bool {
        ApplyImportControlsVisibility.shouldShowImportControls(selectedTargetPhotoPath: model.selectedTargetPhotoPath)
    }

    private var shouldShowBottomActions: Bool {
        ApplyBottomActionsVisibility.shouldShowActions(selectedTargetPhotoPath: model.selectedTargetPhotoPath)
    }

    private var initialImportTaskID: String {
        initialImportSource?.id ?? "none"
    }

    private var previewAspectRatio: CGFloat {
        ApplyPreviewLayout.frameAspectRatio(
            forLoadedImageAspectRatio:
            photoDisplayImageStore.aspectRatio(
                relativePath: model.renderedPreviewPhotoPath,
                maxPixelDimension: Self.previewMaxPixelDimension
            )
            ?? photoDisplayImageStore.aspectRatio(
                relativePath: model.selectedTargetPhotoPath,
                maxPixelDimension: Self.previewMaxPixelDimension
            )
        )
    }

    private func presentImportSource(_ source: ApplyTargetImportSource) {
        presentImportPresentation(source.presentation)
    }

    private func presentImportPresentation(_ presentation: ApplyTargetImportPresentation) {
        switch presentation {
        case .photosPicker:
            isPhotosPickerPresented = true
        case .fileImporter:
            isFileImporterPresented = true
        }
    }

    private func presentInitialImportSourceIfNeeded() async {
        guard !didPresentInitialImportSource,
              let presentation = ApplyInitialImportPresentationDecision.presentation(
                initialImportSource: initialImportSource
              ) else {
            return
        }

        didPresentInitialImportSource = true
        await Task.yield()
        presentImportPresentation(presentation)
    }

    private func importTargetPhotosItem(_ item: PhotosPickerItem?) async {
        guard let item else {
            return
        }
        let importGeneration = beginTargetImport()
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw LumoError.importFailed
            }
            let staged = try await photoImportStagingService.stageImageData(
                data,
                preferredFileExtension: nil
            )
            guard await acceptTargetImport(staged, importGeneration: importGeneration) else {
                return
            }
            selectStagedTarget(staged)
        } catch is CancellationError {
        } catch {
            if StagedImportGenerationDecision.shouldAccept(
                completedGeneration: importGeneration,
                activeGeneration: targetImportGeneration
            ) {
                targetImportMessage = applyScreenErrorMessage(error)
            }
        }
        if StagedImportGenerationDecision.shouldAccept(
            completedGeneration: importGeneration,
            activeGeneration: targetImportGeneration
        ) {
            selectedTargetPhotosItem = nil
        }
    }

    private func importTargetFile(_ result: Result<[URL], Error>) async {
        guard case .success(let urls) = result,
              let url = urls.first else {
            return
        }
        let importGeneration = beginTargetImport()
        do {
            let staged = try await photoImportStagingService.stageImageFile(at: url)
            guard await acceptTargetImport(staged, importGeneration: importGeneration) else {
                return
            }
            selectStagedTarget(staged)
        } catch is CancellationError {
        } catch {
            if StagedImportGenerationDecision.shouldAccept(
                completedGeneration: importGeneration,
                activeGeneration: targetImportGeneration
            ) {
                targetImportMessage = applyScreenErrorMessage(error)
            }
        }
    }

    private func beginTargetImport() -> Int {
        targetImportGeneration += 1
        targetImportMessage = nil
        return targetImportGeneration
    }

    private func acceptTargetImport(_ staged: StagedPhotoImport, importGeneration: Int) async -> Bool {
        if let stalePath = StagedImportGenerationDecision.stalePathToDiscard(
            stagedPath: staged.relativePath,
            completedGeneration: importGeneration,
            activeGeneration: targetImportGeneration
        ) {
            await photoImportStagingService.discardStagedImport(relativePath: stalePath)
            return false
        }
        return true
    }

    private func selectStagedTarget(_ staged: StagedPhotoImport) {
        let previousPath = model.selectedTargetPhotoPath
        model.selectTargetPhoto(path: staged.relativePath)
        let selectedPathAfterSelection = model.selectedTargetPhotoPath
        targetImportMessage = nil
        if let pathToDiscard = ApplyTargetImportCleanupDecision.pathToDiscardAfterSelection(
            previousPath: previousPath,
            stagedPath: staged.relativePath,
            selectedPathAfterSelection: selectedPathAfterSelection
        ) {
            Task {
                await photoImportStagingService.discardStagedImport(relativePath: pathToDiscard)
            }
        }
        let actions = ApplyTargetImportSaveDecision.actionsAfterSelectingTarget(
            selectedTargetPhotoPath: selectedPathAfterSelection,
            isSaving: model.isSaving
        )
        if actions.saveToFilmRoll {
            Task {
                await model.saveToFilmRoll()
            }
        }
    }

    private func closeAndDiscard() {
        guard ApplyCloseDecision.shouldCloseAndDiscard(isSaving: model.isSaving) else {
            return
        }
        targetImportGeneration += 1
        Task {
            await model.discardPreview()
        }
        discardCurrentTargetImport()
        onBack()
    }

    private func discardCurrentTargetImport() {
        guard let selectedPath = model.selectedTargetPhotoPath else {
            return
        }
        Task {
            await photoImportStagingService.discardStagedImport(relativePath: selectedPath)
        }
    }

    private static var allowedImportContentTypes: [UTType] {
        [
            .jpeg,
            .png,
            UTType("public.heic"),
            UTType("public.heif")
        ].compactMap { $0 }
    }
}

#Preview {
    ApplyPhotoModelHost(
        model: AppContainer.preview.makeApplyPhotoModel(filmRollID: "warm-picnic"),
        rollLoader: { try await AppContainer.preview.repository.loadFilmRoll(id: "warm-picnic") },
        photoImportStagingService: AppContainer.preview.photoImportStagingService,
        photoDisplayImageStore: AppContainer.preview.makePhotoDisplayImageStore(),
        initialImportSource: nil,
        onBack: {},
        onSavedToRoll: {}
    )
}

private func applyScreenErrorMessage(_ error: Error) -> String {
    if let message = (error as? LocalizedError)?.errorDescription {
        return message
    }
    return error.localizedDescription
}
