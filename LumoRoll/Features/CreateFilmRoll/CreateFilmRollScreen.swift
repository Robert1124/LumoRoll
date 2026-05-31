import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct CreateFilmRollModelHost: View {
    let model: CreateFilmRollFeatureModel
    let photoImportStagingService: PhotoImportStagingService
    let assetURLResolver: AppAssetURLResolver
    let photoDisplayImageStore: PhotoDisplayImageStore
    let onClose: () -> Void
    let onSaved: (FilmRoll) -> Void

    var body: some View {
        CreateFilmRollScreen(
            model: model,
            photoImportStagingService: photoImportStagingService,
            assetURLResolver: assetURLResolver,
            photoDisplayImageStore: photoDisplayImageStore,
            onClose: onClose,
            onSaved: onSaved
        )
    }
}

enum StagedImportGenerationDecision {
    static func shouldAccept(completedGeneration: Int, activeGeneration: Int) -> Bool {
        completedGeneration == activeGeneration
    }

    static func stalePathToDiscard(
        stagedPath: String,
        completedGeneration: Int,
        activeGeneration: Int
    ) -> String? {
        shouldAccept(completedGeneration: completedGeneration, activeGeneration: activeGeneration) ? nil : stagedPath
    }
}

enum CreateFilmRollStep: Equatable {
    case reference
    case naming
}

enum CreateFilmRollLayout {
    static let steps: [CreateFilmRollStep] = [.reference, .naming]
    static let sectionSpacing: CGFloat = 16
    static let panelPadding: CGFloat = 16
    static let panelContentSpacing: CGFloat = 14
    static let outerPadding: CGFloat = 16
    static let additionalBottomPadding: CGFloat = 24
    static let bottomBarEstimatedHeight: CGFloat = 96
    static let headerEstimatedHeight: CGFloat = 56
    static let referencePanelChromeHeight: CGFloat = 110
    static let namingPanelEstimatedHeight: CGFloat = 166
    static let minimumReferencePreviewHeight: CGFloat = 184
    static let maximumReferencePreviewHeight: CGFloat = 326

    static func stepLabel(for step: CreateFilmRollStep) -> String {
        guard let index = steps.firstIndex(of: step) else {
            return ""
        }

        return "Step \(index + 1) of \(steps.count)"
    }

    static func referencePreviewHeight(forViewportHeight viewportHeight: CGFloat) -> CGFloat {
        let remainingHeight = availableContentHeight(forViewportHeight: viewportHeight)
            - contentVerticalPadding
            - headerEstimatedHeight
            - namingPanelEstimatedHeight
            - referencePanelChromeHeight
            - (sectionSpacing * 2)

        return min(
            maximumReferencePreviewHeight,
            max(minimumReferencePreviewHeight, remainingHeight)
        )
    }

    static func estimatedContentHeight(forViewportHeight viewportHeight: CGFloat) -> CGFloat {
        headerEstimatedHeight
            + contentVerticalPadding
            + referencePanelChromeHeight
            + referencePreviewHeight(forViewportHeight: viewportHeight)
            + namingPanelEstimatedHeight
            + (sectionSpacing * 2)
    }

    static func availableContentHeight(forViewportHeight viewportHeight: CGFloat) -> CGFloat {
        max(0, viewportHeight - bottomBarEstimatedHeight)
    }

    private static var contentVerticalPadding: CGFloat {
        (outerPadding * 2) + additionalBottomPadding
    }
}

enum CreateFilmRollSaveAvailability {
    static func isEnabled(canSave: Bool, isWorking: Bool) -> Bool {
        canSave && !isWorking
    }
}

enum CreateFilmRollReferenceStepCopy {
    static let title = "Pick a photo sample or a cube LUT"
    static let placeholderTitle = "Add a reference"
}

enum CreateFilmRollReferenceImportPresentation: Equatable {
    case photosPicker
    case fileImporter
}

enum CreateFilmRollReferenceImportSource: CaseIterable, Equatable, Identifiable {
    case photos
    case files

    var id: String {
        switch self {
        case .photos:
            "photos"
        case .files:
            "files"
        }
    }

    var label: String {
        switch self {
        case .photos:
            "Photos"
        case .files:
            "Files"
        }
    }

    var presentation: CreateFilmRollReferenceImportPresentation {
        switch self {
        case .photos:
            .photosPicker
        case .files:
            .fileImporter
        }
    }
}

enum CreateFilmRollReferenceSourceChoice {
    static let title = CreateFilmRollReferenceStepCopy.placeholderTitle
    static let showsInlineSourceButtons = false
}

enum CreateFilmRollFileImportKind: Equatable {
    case image
    case cubeLUT

    static func kind(forFilename filename: String) -> CreateFilmRollFileImportKind {
        filename.lowercased().hasSuffix(".cube") ? .cubeLUT : .image
    }
}

enum CreateFilmRollAllowedImportTypes {
    static let values: [UTType] = [
        .jpeg,
        .png,
        UTType("public.heic"),
        UTType("public.heif"),
        .lumoCube
    ].compactMap { $0 }
}

@MainActor
enum CreateStagedReferenceSelection {
    static func select(
        _ staged: StagedPhotoImport,
        resolver: AppAssetURLResolver,
        completedGeneration: Int,
        activeGeneration: () -> Int,
        discardStagedImport: (String) async -> Void,
        onSelected: (Data, String) -> Void
    ) async throws -> Bool {
        do {
            let url = try resolver.resolve(staged.relativePath)
            let data = try await Task.detached(priority: .userInitiated) {
                try Data(contentsOf: url)
            }.value
            if let stalePath = StagedImportGenerationDecision.stalePathToDiscard(
                stagedPath: staged.relativePath,
                completedGeneration: completedGeneration,
                activeGeneration: activeGeneration()
            ) {
                await discardStagedImport(stalePath)
                return false
            }
            onSelected(data, staged.preferredFileExtension)
            return true
        } catch {
            await discardStagedImport(staged.relativePath)
            throw error
        }
    }
}

struct CreateFilmRollScreen: View {
    let model: CreateFilmRollFeatureModel
    let photoImportStagingService: PhotoImportStagingService
    let assetURLResolver: AppAssetURLResolver
    let photoDisplayImageStore: PhotoDisplayImageStore
    var onClose: () -> Void
    var onSaved: (FilmRoll) -> Void

    @State private var selectedReferencePhotosItem: PhotosPickerItem?
    @State private var isReferenceSourceDialogPresented = false
    @State private var isReferencePhotosPickerPresented = false
    @State private var isFileImporterPresented = false
    @State private var selectedReferenceRelativePath: String?
    @State private var selectedCubeFilename: String?
    @State private var referenceImportMessage: String?
    @State private var referenceImportGeneration = 0

    var body: some View {
        @Bindable var model = model

        GeometryReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: CreateFilmRollLayout.sectionSpacing) {
                    header
                    referenceStep(previewHeight: CreateFilmRollLayout.referencePreviewHeight(forViewportHeight: proxy.size.height))
                    namingStep(draftName: $model.draftName)
                }
                .padding(CreateFilmRollLayout.outerPadding)
                .padding(.bottom, CreateFilmRollLayout.additionalBottomPadding)
                .frame(
                    maxWidth: .infinity,
                    minHeight: CreateFilmRollLayout.availableContentHeight(forViewportHeight: proxy.size.height),
                    alignment: .top
                )
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(LumoTheme.Colors.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
        .confirmationDialog(
            CreateFilmRollReferenceSourceChoice.title,
            isPresented: $isReferenceSourceDialogPresented,
            titleVisibility: .visible
        ) {
            ForEach(CreateFilmRollReferenceImportSource.allCases) { source in
                Button(source.label) {
                    presentReferenceImportSource(source)
                }
            }
        }
        .photosPicker(
            isPresented: $isReferencePhotosPickerPresented,
            selection: $selectedReferencePhotosItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: CreateFilmRollAllowedImportTypes.values,
            allowsMultipleSelection: false
        ) { result in
            Task { await importReferenceFile(result) }
        }
        .onChange(of: selectedReferencePhotosItem, initial: false) { _, item in
            Task { await importReferencePhotosItem(item) }
        }
        .onChange(of: model.savedFilmRoll, initial: false) { _, roll in
            if let roll {
                discardSelectedReferenceImport()
                onSaved(roll)
            }
        }
    }

    private var header: some View {
        HStack {
            LumoIconButton(systemImage: "chevron.left", accessibilityLabel: "Back", action: closeAndDiscard)
            Spacer()
            Text("Create Film Roll")
                .font(LumoTheme.Typography.headline)
                .foregroundStyle(LumoTheme.Colors.textPrimary)
            Spacer()
            Color.clear.frame(width: LumoTheme.Metrics.minimumHitTarget, height: LumoTheme.Metrics.minimumHitTarget)
        }
    }

    private func referenceStep(previewHeight: CGFloat) -> some View {
        stepPanel(
            step: CreateFilmRollLayout.stepLabel(for: .reference),
            title: CreateFilmRollReferenceStepCopy.title
        ) {
            VStack(alignment: .leading, spacing: CreateFilmRollLayout.panelContentSpacing) {
                Button {
                    isReferenceSourceDialogPresented = true
                } label: {
                    LumoPhotoPlaceholder(
                        style: .thumbnail,
                        title: referencePlaceholderTitle
                    )
                    .overlay {
                        PhotoDisplayImageView(
                            store: photoDisplayImageStore,
                            relativePath: selectedReferenceRelativePath,
                            maxPixelDimension: 900,
                            contentMode: .fill
                        ) {
                            Color.clear
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: previewHeight)
                    .clipShape(RoundedRectangle(cornerRadius: LumoTheme.Radius.preview, style: .continuous))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(CreateFilmRollReferenceStepCopy.placeholderTitle)
                .accessibilityHint("Choose Photos or Files")

                if let referenceImportMessage {
                    Text(referenceImportMessage)
                        .font(LumoTheme.Typography.label)
                        .foregroundStyle(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func presentReferenceImportSource(_ source: CreateFilmRollReferenceImportSource) {
        switch source.presentation {
        case .photosPicker:
            isReferencePhotosPickerPresented = true
        case .fileImporter:
            isFileImporterPresented = true
        }
    }

    private func namingStep(draftName: Binding<String>) -> some View {
        stepPanel(step: CreateFilmRollLayout.stepLabel(for: .naming), title: "Name your roll.") {
            VStack(alignment: .leading, spacing: LumoTheme.Spacing.small) {
                TextField("e.g. Roadtrip Sky", text: draftName)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .padding(LumoTheme.Spacing.medium)
                    .background(LumoTheme.Colors.surfaceSecondary, in: RoundedRectangle(cornerRadius: LumoTheme.Radius.small, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: LumoTheme.Radius.small, style: .continuous)
                            .stroke(LumoTheme.Colors.hairlineStrong, lineWidth: 1)
                    }

                if case .failed(let message) = model.phase {
                    Text(message)
                        .font(LumoTheme.Typography.label)
                        .foregroundStyle(.red)
                } else {
                    Text("Save is available after a reference is selected and the name is not empty.")
                        .font(LumoTheme.Typography.label)
                        .foregroundStyle(LumoTheme.Colors.textSecondary)
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: LumoTheme.Spacing.small) {
            LumoPillButton(title: "Cancel", variant: .secondary, isFullWidth: true, action: closeAndDiscard)
            LumoPillButton(
                title: "Save as Film Roll",
                systemImage: "film",
                variant: .primary,
                isLoading: isWorking,
                isFullWidth: true
            ) {
                Task { await model.save() }
            }
            .disabled(!CreateFilmRollSaveAvailability.isEnabled(canSave: model.canSave, isWorking: isWorking))
        }
        .padding(LumoTheme.Spacing.medium)
        .background(.ultraThinMaterial)
    }

    private var isWorking: Bool {
        switch model.phase {
        case .processing, .saving:
            true
        default:
            false
        }
    }

    private func stepPanel<Content: View>(
        step: String,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: CreateFilmRollLayout.panelContentSpacing) {
            VStack(alignment: .leading, spacing: LumoTheme.Spacing.xxSmall) {
                Text(step)
                    .font(LumoTheme.Typography.technicalLabel)
                    .tracking(0.8)
                    .textCase(.uppercase)
                    .foregroundStyle(LumoTheme.Colors.textTertiary)
                Text(title)
                    .font(LumoTheme.Typography.headline)
                    .foregroundStyle(LumoTheme.Colors.textPrimary)
            }
            content()
        }
        .padding(CreateFilmRollLayout.panelPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LumoTheme.Colors.surfacePrimary, in: RoundedRectangle(cornerRadius: LumoTheme.Radius.panel, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LumoTheme.Radius.panel, style: .continuous)
                .stroke(LumoTheme.Colors.hairline, lineWidth: 1)
        }
    }

    private func importReferencePhotosItem(_ item: PhotosPickerItem?) async {
        guard let item else {
            return
        }
        let importGeneration = beginReferenceImport()
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw LumoError.importFailed
            }
            let staged = try await photoImportStagingService.stageImageData(
                data,
                preferredFileExtension: nil
            )
            guard await acceptReferenceImport(staged, importGeneration: importGeneration) else {
                return
            }
            guard try await selectStagedReference(staged, importGeneration: importGeneration) else {
                return
            }
        } catch is CancellationError {
        } catch {
            if StagedImportGenerationDecision.shouldAccept(
                completedGeneration: importGeneration,
                activeGeneration: referenceImportGeneration
            ) {
                referenceImportMessage = createScreenErrorMessage(error)
            }
        }
        if StagedImportGenerationDecision.shouldAccept(
            completedGeneration: importGeneration,
            activeGeneration: referenceImportGeneration
        ) {
            selectedReferencePhotosItem = nil
        }
    }

    private func importReferenceFile(_ result: Result<[URL], Error>) async {
        guard case .success(let urls) = result,
              let url = urls.first else {
            return
        }
        let importGeneration = beginReferenceImport()
        do {
            switch CreateFilmRollFileImportKind.kind(forFilename: url.lastPathComponent) {
            case .image:
                let staged = try await photoImportStagingService.stageImageFile(at: url)
                guard await acceptReferenceImport(staged, importGeneration: importGeneration) else {
                    return
                }
                guard try await selectStagedReference(staged, importGeneration: importGeneration) else {
                    return
                }
            case .cubeLUT:
                guard try await selectCubeLUTFile(at: url, importGeneration: importGeneration) else {
                    return
                }
            }
        } catch is CancellationError {
        } catch {
            if StagedImportGenerationDecision.shouldAccept(
                completedGeneration: importGeneration,
                activeGeneration: referenceImportGeneration
            ) {
                referenceImportMessage = createScreenErrorMessage(error)
            }
        }
    }

    private func selectCubeLUTFile(at url: URL, importGeneration: Int) async throws -> Bool {
        let didStartAccessing = url.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                url.stopAccessingSecurityScopedResource()
            }
        }

        let cubeData = try await Task.detached(priority: .userInitiated) {
            try Data(contentsOf: url)
        }.value
        guard StagedImportGenerationDecision.shouldAccept(
            completedGeneration: importGeneration,
            activeGeneration: referenceImportGeneration
        ) else {
            return false
        }

        let previousPath = selectedReferenceRelativePath
        model.selectCubeLUT(data: cubeData, originalFilename: url.lastPathComponent)
        selectedReferenceRelativePath = nil
        selectedCubeFilename = url.deletingPathExtension().lastPathComponent
        referenceImportMessage = nil
        if let previousPath {
            await photoImportStagingService.discardStagedImport(relativePath: previousPath)
        }
        return true
    }

    private func selectStagedReference(_ staged: StagedPhotoImport, importGeneration: Int) async throws -> Bool {
        let previousPath = selectedReferenceRelativePath
        let didSelect = try await CreateStagedReferenceSelection.select(
            staged,
            resolver: assetURLResolver,
            completedGeneration: importGeneration,
            activeGeneration: { referenceImportGeneration },
            discardStagedImport: { await photoImportStagingService.discardStagedImport(relativePath: $0) }
        ) { data, preferredFileExtension in
            model.selectReferenceImage(data: data, preferredFileExtension: preferredFileExtension)
            selectedReferenceRelativePath = staged.relativePath
            selectedCubeFilename = nil
            referenceImportMessage = nil
        }
        guard didSelect else {
            return false
        }
        if let previousPath, previousPath != staged.relativePath {
            await photoImportStagingService.discardStagedImport(relativePath: previousPath)
        }
        return true
    }

    private var referencePlaceholderTitle: String {
        if let selectedCubeFilename {
            return "LUT file\n\(selectedCubeFilename)"
        }
        return CreateFilmRollReferenceStepCopy.placeholderTitle
    }

    private func beginReferenceImport() -> Int {
        referenceImportGeneration += 1
        model.beginImport()
        selectedCubeFilename = nil
        referenceImportMessage = nil
        return referenceImportGeneration
    }

    private func acceptReferenceImport(_ staged: StagedPhotoImport, importGeneration: Int) async -> Bool {
        if let stalePath = StagedImportGenerationDecision.stalePathToDiscard(
            stagedPath: staged.relativePath,
            completedGeneration: importGeneration,
            activeGeneration: referenceImportGeneration
        ) {
            await photoImportStagingService.discardStagedImport(relativePath: stalePath)
            return false
        }
        return true
    }

    private func closeAndDiscard() {
        referenceImportGeneration += 1
        discardSelectedReferenceImport()
        onClose()
    }

    private func discardSelectedReferenceImport() {
        guard let selectedReferenceRelativePath else {
            selectedCubeFilename = nil
            return
        }
        Task {
            await photoImportStagingService.discardStagedImport(relativePath: selectedReferenceRelativePath)
        }
        self.selectedReferenceRelativePath = nil
        selectedCubeFilename = nil
    }
}

#Preview {
    CreateFilmRollModelHost(
        model: AppContainer.preview.makeCreateFilmRollModel(),
        photoImportStagingService: AppContainer.preview.photoImportStagingService,
        assetURLResolver: AppContainer.preview.assetURLResolver,
        photoDisplayImageStore: AppContainer.preview.makePhotoDisplayImageStore(),
        onClose: {},
        onSaved: { _ in }
    )
}

private func createScreenErrorMessage(_ error: Error) -> String {
    if let message = (error as? LocalizedError)?.errorDescription {
        return message
    }
    return error.localizedDescription
}
