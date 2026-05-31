import PhotosUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct FilmRollDetailModelHost: View {
    let model: FilmRollDetailFeatureModel
    let photoDisplayImageStore: PhotoDisplayImageStore
    let photoImportStagingService: PhotoImportStagingService
    let reloadToken: Int
    let onBack: () -> Void
    let onApply: (String, ApplyTargetImportSource?, String?) -> Void
    let onRemoved: () -> Void
    let onOpenFrame: (FilmRoll, Int) -> Void

    var body: some View {
        FilmRollDetailScreen(
            model: model,
            photoDisplayImageStore: photoDisplayImageStore,
            photoImportStagingService: photoImportStagingService,
            reloadToken: reloadToken,
            onBack: onBack,
            onImportedTarget: { path in
                onApply(model.filmRollID, nil, path)
            },
            onOpenFrame: onOpenFrame
        )
            .onChange(of: model.pendingIntent, initial: false) { _, intent in
                guard let intent else {
                    return
                }
                switch intent {
                case .applyPhoto(let filmRollID):
                    onApply(filmRollID, nil, nil)
                case .importPhoto(let filmRollID, let source):
                    onApply(filmRollID, source, nil)
                case .removedFilmRoll:
                    onRemoved()
                }
                model.clearPendingIntent()
            }
    }
}

enum FilmRollDetailActions {
    static let renameTitle = "Rename"
    static let removeTitle = "Remove"
    static let addPhotoTitle = "Add photo"
    static let exportCubeTitle = "Export .cube"
    static let independentActionTitles = [exportCubeTitle, addPhotoTitle]
    static let topToolbarIconActionTitles = independentActionTitles
    static let titleIconActionTitles: [String] = []
    static let menuActionTitles = [renameTitle, removeTitle]
}

enum FilmRollDetailExportButtonPlacement: Equatable {
    case topToolbarTrailingIcon
}

enum FilmRollDetailAddPhotoButtonPlacement: Equatable {
    case topToolbarTrailingIcon
}

enum FilmRollDetailPresentationStyle: Equatable {
    case filmProjectorViewer
}

enum FilmRollDetailProjectionPlacement: Equatable {
    case centerViewport
}

enum FilmRollDetailFilmTransportPlacement: Equatable {
    case bottomPinnedProjector
}

enum FilmRollDetailProjectionLighting: Equatable {
    case none
}

enum FilmRollDetailLayout {
    static let allowsVerticalScroll = false
    static let showsBottomActionBar = false
    static let exportButtonPlacement: FilmRollDetailExportButtonPlacement = .topToolbarTrailingIcon
    static let addPhotoButtonPlacement: FilmRollDetailAddPhotoButtonPlacement = .topToolbarTrailingIcon
    static let presentationStyle: FilmRollDetailPresentationStyle = .filmProjectorViewer
    static let projectionPlacement: FilmRollDetailProjectionPlacement = .centerViewport
    static let filmTransportPlacement: FilmRollDetailFilmTransportPlacement = .bottomPinnedProjector
    static let projectionLighting: FilmRollDetailProjectionLighting = .none
    static let filmTransportMovesProjectionSelection = true

    static func screenContentMinimumHeight(for viewportHeight: CGFloat) -> CGFloat {
        max(0, viewportHeight - LumoTheme.Spacing.medium * 2)
    }

    static func showsEmptyProcessedPhotoHint(processedPhotoCount: Int) -> Bool {
        false
    }
}

enum FilmRollDetailFilmTransportHapticStyle: Equatable {
    case mediumImpact
}

enum FilmRollDetailFilmTransportInteraction {
    static let hapticStyle: FilmRollDetailFilmTransportHapticStyle = .mediumImpact
    static let hapticIntensity: CGFloat = 0.88

    static func contentOffset(
        selectedIndex: Int,
        dragTranslation: CGFloat,
        frameWidths: [CGFloat],
        frameSpacing: CGFloat,
        leadingInset: CGFloat,
        viewportCenter: CGFloat
    ) -> CGFloat {
        let centers = frameCenters(
            frameWidths: frameWidths,
            frameSpacing: frameSpacing,
            leadingInset: leadingInset
        )
        guard let selectedCenter = centers[safe: selectedIndex] else {
            return dragTranslation
        }
        return viewportCenter - selectedCenter + dragTranslation
    }

    static func targetIndex(
        selectedIndex: Int,
        dragTranslation: CGFloat,
        frameWidths: [CGFloat],
        frameSpacing: CGFloat
    ) -> Int {
        let centers = frameCenters(frameWidths: frameWidths, frameSpacing: frameSpacing)
        guard let selectedCenter = centers[safe: selectedIndex] else {
            return 0
        }

        let targetCenter = selectedCenter - dragTranslation
        return nearestFrameIndex(to: targetCenter, centers: centers)
    }

    static func continuityDragTranslation(
        releaseTranslation: CGFloat,
        selectedIndex: Int,
        targetIndex: Int,
        frameWidths: [CGFloat],
        frameSpacing: CGFloat
    ) -> CGFloat {
        let centers = frameCenters(frameWidths: frameWidths, frameSpacing: frameSpacing)
        guard let selectedCenter = centers[safe: selectedIndex],
              let targetCenter = centers[safe: targetIndex] else {
            return releaseTranslation
        }
        return releaseTranslation + (targetCenter - selectedCenter)
    }

    static func contentLeadingX(viewportWidth: CGFloat, contentWidth: CGFloat) -> CGFloat {
        0
    }

    static func selectedFrameViewportCenterX(
        selectedIndex: Int,
        dragTranslation: CGFloat,
        frameWidths: [CGFloat],
        frameSpacing: CGFloat,
        leadingInset: CGFloat,
        viewportWidth: CGFloat,
        contentWidth: CGFloat
    ) -> CGFloat {
        let centers = frameCenters(
            frameWidths: frameWidths,
            frameSpacing: frameSpacing,
            leadingInset: leadingInset
        )
        guard let selectedCenter = centers[safe: selectedIndex] else {
            return contentLeadingX(viewportWidth: viewportWidth, contentWidth: contentWidth)
        }
        let offset = contentOffset(
            selectedIndex: selectedIndex,
            dragTranslation: dragTranslation,
            frameWidths: frameWidths,
            frameSpacing: frameSpacing,
            leadingInset: leadingInset,
            viewportCenter: FilmRollProjectorTransportLayout.filmFrameTargetCenterX(
                forViewportWidth: viewportWidth
            )
        )
        return contentLeadingX(viewportWidth: viewportWidth, contentWidth: contentWidth)
            + offset
            + selectedCenter
    }

    static func frameCenters(
        frameWidths: [CGFloat],
        frameSpacing: CGFloat,
        leadingInset: CGFloat = 0
    ) -> [CGFloat] {
        var leadingEdge = max(0, leadingInset)
        return frameWidths.map { width in
            let sanitizedWidth = max(0, width)
            let center = leadingEdge + (sanitizedWidth / 2)
            leadingEdge += sanitizedWidth + max(0, frameSpacing)
            return center
        }
    }

    static func boundedDragTranslation(
        _ translation: CGFloat,
        selectedIndex: Int,
        frameCount: Int,
        leaderLength: CGFloat,
        trailerLength: CGFloat
    ) -> CGFloat {
        guard frameCount > 1 else {
            return 0
        }
        if selectedIndex == 0, translation > 0 {
            return boundedOverdrag(translation, limit: max(0, leaderLength))
        }
        if selectedIndex == frameCount - 1, translation < 0 {
            return -boundedOverdrag(abs(translation), limit: max(0, trailerLength))
        }
        return translation
    }

    private static func nearestFrameIndex(to targetCenter: CGFloat, centers: [CGFloat]) -> Int {
        guard !centers.isEmpty else {
            return 0
        }

        return centers.enumerated().min { lhs, rhs in
            abs(lhs.element - targetCenter) < abs(rhs.element - targetCenter)
        }?.offset ?? 0
    }

    private static func boundedOverdrag(_ translation: CGFloat, limit: CGFloat) -> CGFloat {
        guard translation > limit else {
            return translation
        }
        return limit + ((translation - limit) * 0.22)
    }

    @MainActor
    static func triggerSelectionChanged() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred(intensity: hapticIntensity)
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}

enum FilmRollDetailAddPhotoSourceChoice {
    static let title = "Add photo"
    static let sources = ApplyTargetImportSource.allCases
}

struct FilmRollDetailScreen: View {
    let model: FilmRollDetailFeatureModel
    let photoDisplayImageStore: PhotoDisplayImageStore
    let photoImportStagingService: PhotoImportStagingService
    let reloadToken: Int
    var onBack: () -> Void
    var onImportedTarget: (String) -> Void
    var onOpenFrame: (FilmRoll, Int) -> Void
    @State private var preparedExportDocument: CubeLUTExportDocument?
    @State private var isExportPresented = false
    @State private var fileExportErrorMessage: String?
    @State private var isAddPhotoSourceDialogPresented = false
    @State private var selectedAddPhotoPhotosItem: PhotosPickerItem?
    @State private var isAddPhotoPhotosPickerPresented = false
    @State private var isAddPhotoFileImporterPresented = false
    @State private var addPhotoImportMessage: String?
    @State private var addPhotoImportGeneration = 0
    @State private var isRenamePresented = false
    @State private var renameDraftName = ""
    @State private var isRemoveConfirmationPresented = false
    @State private var selectedProjectorFrameIndex = 0

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: LumoTheme.Spacing.xLarge) {
                header
                content
            }
            .frame(
                maxWidth: .infinity,
                minHeight: FilmRollDetailLayout.screenContentMinimumHeight(for: proxy.size.height),
                maxHeight: .infinity,
                alignment: .top
            )
            .padding(LumoTheme.Spacing.medium)
            .clipped()
        }
        .background(LumoTheme.Colors.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .task(id: reloadToken) {
            await model.load()
        }
        .onChange(of: model.exportState, initial: false) { _, exportState in
            guard case .ready(let result) = exportState else {
                return
            }
            preparedExportDocument = CubeLUTExportDocument(exportResult: result)
            fileExportErrorMessage = nil
            isExportPresented = true
        }
        .fileExporter(
            isPresented: $isExportPresented,
            document: preparedExportDocument,
            contentType: .lumoCube,
            defaultFilename: preparedExportDocument?.suggestedFilename ?? "Film-Roll.cube"
        ) { result in
            handleFileExportCompletion(result)
        }
        .photosPicker(
            isPresented: $isAddPhotoPhotosPickerPresented,
            selection: $selectedAddPhotoPhotosItem,
            matching: .images,
            photoLibrary: .shared()
        )
        .fileImporter(
            isPresented: $isAddPhotoFileImporterPresented,
            allowedContentTypes: Self.allowedImportContentTypes,
            allowsMultipleSelection: false
        ) { result in
            Task { await importAddPhotoFile(result) }
        }
        .onChange(of: selectedAddPhotoPhotosItem, initial: false) { _, item in
            Task { await importAddPhotoPhotosItem(item) }
        }
        .onChange(of: isExportPresented, initial: false) { _, isPresented in
            guard !isPresented else {
                return
            }
            clearExportPresentation()
        }
        .confirmationDialog(
            FilmRollDetailAddPhotoSourceChoice.title,
            isPresented: $isAddPhotoSourceDialogPresented,
            titleVisibility: .visible
        ) {
            ForEach(FilmRollDetailAddPhotoSourceChoice.sources) { source in
                Button(source.label) {
                    presentAddPhotoSource(source)
                }
            }
        }
        .alert("Rename Film Roll", isPresented: $isRenamePresented) {
            TextField("Name", text: $renameDraftName)
            Button("Save") {
                Task { await model.renameFilmRoll(to: renameDraftName) }
            }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog(
            "Remove Film Roll?",
            isPresented: $isRemoveConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button(FilmRollDetailActions.removeTitle, role: .destructive) {
                Task { await model.removeFilmRoll() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the Film Roll and its saved photos from LumoRoll.")
        }
    }

    private var header: some View {
        HStack {
            LumoIconButton(systemImage: "chevron.left", accessibilityLabel: "Back", action: onBack)
            Spacer()
            topToolbarActionButtons
            Menu {
                Button(FilmRollDetailActions.renameTitle, systemImage: "pencil") {
                    renameDraftName = currentRollName
                    isRenamePresented = true
                }
                Button(FilmRollDetailActions.removeTitle, systemImage: "trash", role: .destructive) {
                    isRemoveConfirmationPresented = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 17, weight: .semibold))
                    .frame(width: LumoTheme.Metrics.minimumHitTarget, height: LumoTheme.Metrics.minimumHitTarget)
                    .foregroundStyle(LumoTheme.Colors.textPrimary)
                    .background(LumoTheme.Colors.surfacePrimary, in: Circle())
                    .overlay {
                        Circle().stroke(LumoTheme.Colors.hairline, lineWidth: 1)
                    }
            }
            .accessibilityLabel("More actions")
            .disabled(model.managementState != .idle)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            loadingState
        case .loaded(let roll):
            loadedContent(roll)
        case .failed(let message):
            errorState(message)
        }
    }

    private var loadingState: some View {
        VStack(spacing: LumoTheme.Spacing.medium) {
            ProgressView()
            Text("Loading Film Roll...")
                .font(LumoTheme.Typography.callout)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 360)
    }

    private func loadedContent(_ roll: FilmRoll) -> some View {
        let displayData = FilmRollDisplayData(filmRoll: roll)
        let frames = FilmRollViewerFrame.frames(for: roll)

        return FilmRollProjectorDetailView(
            roll: roll,
            displayData: displayData,
            frames: frames,
            selectedIndex: $selectedProjectorFrameIndex,
            photoDisplayImageStore: photoDisplayImageStore,
            onOpenFrame: { index in
                onOpenFrame(roll, index)
            },
            titleActions: {
                EmptyView()
            },
            statusContent: {
                VStack(alignment: .leading, spacing: LumoTheme.Spacing.xSmall) {
                    exportStatus
                    fileExportStatus
                    addPhotoImportStatus
                    staleLoadError
                }
            }
        )
    }

    @ViewBuilder
    private var exportStatus: some View {
        switch model.exportState {
        case .idle:
            EmptyView()
        case .exporting:
            Text("Preparing .cube export...")
                .font(LumoTheme.Typography.label)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
        case .ready(let result):
            Text("\(result.suggestedFilename) is ready to export.")
                .font(LumoTheme.Typography.label)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
        case .failed(let message):
            Text(message)
                .font(LumoTheme.Typography.label)
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var fileExportStatus: some View {
        if let fileExportErrorMessage {
            Text(fileExportErrorMessage)
                .font(LumoTheme.Typography.label)
                .foregroundStyle(.red)
        }
    }

    @ViewBuilder
    private var addPhotoImportStatus: some View {
        if let addPhotoImportMessage {
            Text(addPhotoImportMessage)
                .font(LumoTheme.Typography.label)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var staleLoadError: some View {
        if let message = model.lastErrorMessage {
            Text(message)
                .font(LumoTheme.Typography.label)
                .foregroundStyle(.red)
        }
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: LumoTheme.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(LumoTheme.Colors.accent)
            Text("Film Roll unavailable")
                .font(LumoTheme.Typography.headline)
            Text(message)
                .font(LumoTheme.Typography.callout)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            LumoPillButton(title: "Retry", systemImage: "arrow.clockwise", variant: .secondary) {
                Task { await model.reload() }
            }
        }
        .padding(LumoTheme.Spacing.xLarge)
        .frame(maxWidth: .infinity, minHeight: 360)
        .background(LumoTheme.Colors.surfacePrimary, in: RoundedRectangle(cornerRadius: LumoTheme.Radius.panel, style: .continuous))
    }

    private func handleFileExportCompletion(_ result: Result<URL, Error>) {
        if case .failure(let error) = result, !isUserCancelledFileExport(error) {
            fileExportErrorMessage = "Could not export .cube: \(error.localizedDescription)"
        }
    }

    private func clearExportPresentation() {
        preparedExportDocument = nil
        model.clearPreparedExport()
    }

    private var currentRollName: String {
        if case .loaded(let roll) = model.state {
            return roll.name
        }
        return ""
    }

    private func isUserCancelledFileExport(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == NSCocoaErrorDomain && nsError.code == NSUserCancelledError
    }

    private func presentAddPhotoSource(_ source: ApplyTargetImportSource) {
        switch source {
        case .photoLibrary:
            isAddPhotoPhotosPickerPresented = true
        case .files:
            isAddPhotoFileImporterPresented = true
        }
    }

    private func importAddPhotoPhotosItem(_ item: PhotosPickerItem?) async {
        guard let item else {
            return
        }
        let importGeneration = beginAddPhotoImport()
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw LumoError.importFailed
            }
            let staged = try await photoImportStagingService.stageImageData(
                data,
                preferredFileExtension: nil
            )
            guard await acceptAddPhotoImport(staged, importGeneration: importGeneration) else {
                return
            }
            completeAddPhotoImport(staged)
        } catch is CancellationError {
        } catch {
            if StagedImportGenerationDecision.shouldAccept(
                completedGeneration: importGeneration,
                activeGeneration: addPhotoImportGeneration
            ) {
                addPhotoImportMessage = detailScreenErrorMessage(error)
            }
        }
        if StagedImportGenerationDecision.shouldAccept(
            completedGeneration: importGeneration,
            activeGeneration: addPhotoImportGeneration
        ) {
            selectedAddPhotoPhotosItem = nil
        }
    }

    private func importAddPhotoFile(_ result: Result<[URL], Error>) async {
        guard case .success(let urls) = result,
              let url = urls.first else {
            return
        }
        let importGeneration = beginAddPhotoImport()
        do {
            let staged = try await photoImportStagingService.stageImageFile(at: url)
            guard await acceptAddPhotoImport(staged, importGeneration: importGeneration) else {
                return
            }
            completeAddPhotoImport(staged)
        } catch is CancellationError {
        } catch {
            if StagedImportGenerationDecision.shouldAccept(
                completedGeneration: importGeneration,
                activeGeneration: addPhotoImportGeneration
            ) {
                addPhotoImportMessage = detailScreenErrorMessage(error)
            }
        }
    }

    private func beginAddPhotoImport() -> Int {
        addPhotoImportGeneration += 1
        addPhotoImportMessage = nil
        return addPhotoImportGeneration
    }

    private func acceptAddPhotoImport(_ staged: StagedPhotoImport, importGeneration: Int) async -> Bool {
        if let stalePath = StagedImportGenerationDecision.stalePathToDiscard(
            stagedPath: staged.relativePath,
            completedGeneration: importGeneration,
            activeGeneration: addPhotoImportGeneration
        ) {
            await photoImportStagingService.discardStagedImport(relativePath: stalePath)
            return false
        }
        return true
    }

    private func completeAddPhotoImport(_ staged: StagedPhotoImport) {
        addPhotoImportMessage = nil
        onImportedTarget(staged.relativePath)
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

private struct FilmRollDetailTitleBlock<ActionContent: View>: View {
    let displayData: FilmRollDisplayData
    @ViewBuilder let actionContent: () -> ActionContent

    var body: some View {
        HStack(alignment: .top, spacing: LumoTheme.Spacing.small) {
            VStack(alignment: .leading, spacing: LumoTheme.Spacing.small) {
                Text("Film Roll")
                    .font(LumoTheme.Typography.technicalLabel)
                    .tracking(1)
                    .foregroundStyle(LumoTheme.Colors.textTertiary)
                Text(displayData.name)
                    .font(LumoTheme.Typography.screenTitle)
                    .foregroundStyle(LumoTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.72)

                HStack(spacing: LumoTheme.Spacing.small) {
                    Text("Created \(displayData.createdDateText)")
                    Text("•")
                    Text(displayData.processedPhotoCount == 1 ? "Used on 1 photo" : "Used on \(displayData.processedPhotoCount) photos")
                    Text("•")
                    PaletteRow(colors: displayData.palette)
                }
                .font(LumoTheme.Typography.label)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            actionContent()
                .padding(.top, 38)
        }
    }
}

private struct FilmRollProjectorDetailView<TitleActions: View, StatusContent: View>: View {
    let roll: FilmRoll
    let displayData: FilmRollDisplayData
    let frames: [FilmRollViewerFrame]
    @Binding var selectedIndex: Int
    let photoDisplayImageStore: PhotoDisplayImageStore
    let onOpenFrame: (Int) -> Void
    @ViewBuilder let titleActions: () -> TitleActions
    @ViewBuilder let statusContent: () -> StatusContent

    var body: some View {
        GeometryReader { proxy in
            let currentIndex = clampedSelectedIndex
            let currentFrame = frames[currentIndex]
            let visualViewportWidth = FilmRollProjectorTransportLayout.viewportWidth(
                forContentWidth: proxy.size.width
            )
            let visualViewportLeadingOffset = FilmRollProjectorTransportLayout.viewportLeadingOffset

            VStack(alignment: .leading, spacing: 0) {
                FilmRollDetailTitleBlock(displayData: displayData, actionContent: titleActions)

                Spacer(minLength: LumoTheme.Spacing.small)

                ZStack(alignment: .leading) {
                    Button {
                        onOpenFrame(currentIndex)
                    } label: {
                        FilmRollProjectionScreen(
                            frame: currentFrame,
                            photoDisplayImageStore: photoDisplayImageStore
                        )
                    }
                    .buttonStyle(.plain)
                    .frame(width: visualViewportWidth)
                    .offset(x: visualViewportLeadingOffset)
                    .accessibilityLabel("Open \(currentFrame.displayLabel)")
                }
                .frame(width: proxy.size.width, alignment: .leading)
                .frame(
                    height: FilmRollProjectionScreenLayout.height(
                        forViewportHeight: proxy.size.height,
                        transportHeight: FilmRollProjectorTransportLayout.totalHeight
                    )
                )

                Spacer(minLength: LumoTheme.Spacing.medium)

                ZStack(alignment: .leading) {
                    FilmProjectorTransport(
                        frames: frames,
                        selectedIndex: $selectedIndex,
                        photoDisplayImageStore: photoDisplayImageStore
                    )
                    .frame(width: visualViewportWidth)
                    .offset(x: visualViewportLeadingOffset)
                }
                .frame(width: proxy.size.width, height: FilmRollProjectorTransportLayout.totalHeight, alignment: .leading)

                statusContent()
                    .padding(.top, LumoTheme.Spacing.xSmall)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .onAppear {
                clampSelection()
            }
            .onChange(of: frames.map(\.id), initial: false) { _, _ in
                clampSelection()
            }
        }
    }

    private var clampedSelectedIndex: Int {
        min(max(selectedIndex, 0), max(frames.count - 1, 0))
    }

    private func clampSelection() {
        let clamped = clampedSelectedIndex
        if selectedIndex != clamped {
            selectedIndex = clamped
        }
    }
}

private extension FilmRollDetailScreen {
    var topToolbarActionButtons: some View {
        HStack(spacing: LumoTheme.Spacing.xSmall) {
            LumoIconButton(
                systemImage: "cube",
                accessibilityLabel: FilmRollDetailActions.exportCubeTitle,
                variant: .secondary
            ) {
                Task { await model.exportLUT() }
            }
            .disabled(model.exportState == .exporting)

            LumoIconButton(
                systemImage: "plus",
                accessibilityLabel: FilmRollDetailActions.addPhotoTitle,
                variant: .primary
            ) {
                isAddPhotoSourceDialogPresented = true
            }
            .disabled(model.managementState != .idle)
        }
    }
}

enum FilmRollProjectionImageContentMode: Equatable {
    case fit
}

enum FilmRollProjectionScreenLayout {
    static let usesBackdrop = false
    static let usesLargeAdaptiveContainer = true
    static let usesVisibleContainerBackground = false
    static let showsFrameLabel = false
    static let imageContentMode: FilmRollProjectionImageContentMode = .fit
    static let minimumHeight: CGFloat = 360
    static let maximumHeight: CGFloat = 420
    static let containerCornerRadius: CGFloat = 26
    static let containerHorizontalInset: CGFloat = LumoTheme.Spacing.large

    static func height(forViewportHeight viewportHeight: CGFloat, transportHeight: CGFloat) -> CGFloat {
        let available = viewportHeight - transportHeight - 250
        return min(maximumHeight, max(minimumHeight, available))
    }

    static func containerWidth(forViewportWidth viewportWidth: CGFloat) -> CGFloat {
        max(0, viewportWidth - containerHorizontalInset * 2)
    }
}

private struct FilmRollProjectionScreen: View {
    let frame: FilmRollViewerFrame
    let photoDisplayImageStore: PhotoDisplayImageStore

    var body: some View {
        VStack(spacing: LumoTheme.Spacing.small) {
            if FilmRollProjectionScreenLayout.showsFrameLabel {
                Text(frame.displayLabel)
                    .font(LumoTheme.Typography.technicalLabel)
                    .tracking(1.2)
                    .foregroundStyle(LumoTheme.Colors.textTertiary)
            }

            frameImage(frame)
                .padding(LumoTheme.Spacing.xSmall)
                .padding(.horizontal, FilmRollProjectionScreenLayout.containerHorizontalInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func frameImage(_ frame: FilmRollViewerFrame) -> some View {
        if let image = frame.photo.image {
            image
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else if let relativePath = frame.photo.fullSizeRelativePath ?? frame.photo.thumbnailRelativePath {
            PhotoDisplayImageView(
                store: photoDisplayImageStore,
                relativePath: relativePath,
                maxPixelDimension: 1_600,
                contentMode: .fit
            ) {
                LumoPhotoPlaceholder(style: .unavailable, title: frame.displayLabel)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            LumoPhotoPlaceholder(style: .unavailable, title: frame.displayLabel)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

enum FilmRollProjectorBodyStyle: Equatable {
    case warmLightHybrid
}

enum FilmRollProjectorBodyForm: Equatable {
    case lightBoxPlate
}

enum FilmRollProjectorBodyRendering: Equatable {
    case transparentReferenceLightBoxAsset
}

enum FilmRollProjectorLayeringStyle: Equatable {
    case backFrameFilmFrontViewer
}

enum FilmRollProjectorFilmLayerPosition: Equatable {
    case betweenBackFrameAndFrontViewer
}

enum FilmRollProjectorFrameLayout {
    static let fallbackAspectRatio: CGFloat = 1.45

    static func frameSize(aspectRatio: CGFloat?, fixedHeight: CGFloat) -> CGSize {
        let sanitizedAspectRatio = sanitized(aspectRatio)
        let sanitizedHeight = max(1, fixedHeight)
        return CGSize(width: sanitizedHeight * sanitizedAspectRatio, height: sanitizedHeight)
    }

    static func sanitized(_ aspectRatio: CGFloat?) -> CGFloat {
        guard let aspectRatio,
              aspectRatio.isFinite,
              aspectRatio > 0 else {
            return fallbackAspectRatio
        }
        return aspectRatio
    }
}

enum FilmRollProjectorTransportLayout {
    static let bodyForm: FilmRollProjectorBodyForm = .lightBoxPlate
    static let bodyStyle: FilmRollProjectorBodyStyle = .warmLightHybrid
    static let bodyRendering: FilmRollProjectorBodyRendering = .transparentReferenceLightBoxAsset
    static let usesTransparentBodyAsset = true
    static let layeringStyle: FilmRollProjectorLayeringStyle = .backFrameFilmFrontViewer
    static let filmLayerPosition: FilmRollProjectorFilmLayerPosition = .betweenBackFrameAndFrontViewer
    static let rendersSeparateViewerImage = false
    static let viewerImageUsesFilmFrameSize = true
    static let frontViewerCoversFilm = true
    static let backFrameIsCoveredByFilm = true
    static let backFrameLightAssetName = "FilmLightBoxViewerBackFrame"
    static let backFrameDarkAssetName = "FilmLightBoxViewerBackFrameDark"
    static let frontViewerLightAssetName = "FilmLightBoxViewerFrontBlock"
    static let frontViewerDarkAssetName = "FilmLightBoxViewerFrontBlockDark"
    static let usesFlatRectangleBody = false
    static let filmHeight: CGFloat = 130
    static let totalHeight: CGFloat = 286
    static let filmFrameHeight: CGFloat = 94
    static let frameSpacing: CGFloat = 12
    static let sprocketHeight: CGFloat = 8
    static let leaderLength: CGFloat = 88
    static let trailerLength: CGFloat = 88
    static let backFrameWidth: CGFloat = 224
    static let backFrameHeight: CGFloat = 224
    static let frontViewerWidth: CGFloat = 168
    static let frontViewerHeight: CGFloat = 168
    static let projectorWidth: CGFloat = backFrameWidth
    static let projectorHeight: CGFloat = backFrameHeight
    static let projectorBorderWidth: CGFloat = 0.75
    static let projectorBodyOpacity: CGFloat = 1
    static let projectorWindowFrameHeight: CGFloat = filmFrameHeight + 8
    static let projectorWindowWidth: CGFloat = 142
    static let projectorWindowPadding: CGFloat = 4
    static let projectorWindowUsesFilmBlackEmptyFill = true
    static let viewerAssetOuterTransparentMargin: CGFloat = 4
    static let viewerAssetWindowTransparentMargin: CGFloat = 0
    static let viewerAssetCutoutsAreFullyTransparent = true
    static let viewerAssetMaterialIsOpaque = true
    static let frontViewerUsesReferenceAssetStyle = true
    static let frontViewerUsesRealisticReferenceScrews = true
    static let frontViewerMatchesBackFramePalette = true
    static let showsAddPhotoButton = false
    static let showsTopRail = false
    static let showsTopTitle = false
    static let showsCornerScrews = true
    static let cornerScrewCount = 4
    static let bottomLeftLabel = "LUMOROLL"
    static let bottomRightLabel = "LIGHT BOX"
    static let filmFramesAreTapTargets = false
    static let dimsFilmFrameImages = true
    static let filmFrameImageDimmingOpacity: CGFloat = 0.65
    static let filmBodyMovesWithContent = true
    static let extendsFilmBodyToViewport = false
    static let usesFullScreenWidthViewport = true
    static let viewportHorizontalBleed = LumoTheme.Spacing.medium
    static let filmCenterY: CGFloat = 106
    static let projectorWindowCenterOffsetY: CGFloat = 0
    static let filmSelectionAlignmentOffsetX: CGFloat = -12

    static func backFrameAssetName(isDarkMode: Bool) -> String {
        isDarkMode ? backFrameDarkAssetName : backFrameLightAssetName
    }

    static func frontViewerAssetName(isDarkMode: Bool) -> String {
        isDarkMode ? frontViewerDarkAssetName : frontViewerLightAssetName
    }

    static func filmFrameImageDimmingOpacity(isSelected: Bool) -> CGFloat {
        isSelected ? 0 : filmFrameImageDimmingOpacity
    }

    static var projectorCenterY: CGFloat {
        filmCenterY - projectorWindowCenterOffsetY
    }

    static func filmFrameTargetCenterX(forViewportWidth viewportWidth: CGFloat) -> CGFloat {
        (max(0, viewportWidth) / 2) + filmSelectionAlignmentOffsetX
    }

    static var filmTopY: CGFloat {
        filmCenterY - (filmHeight / 2)
    }

    static var filmBottomY: CGFloat {
        filmCenterY + (filmHeight / 2)
    }

    static var projectorWindowCenterY: CGFloat {
        projectorCenterY + projectorWindowCenterOffsetY
    }

    static var projectorWindowTopY: CGFloat {
        projectorWindowCenterY - (projectorWindowFrameHeight / 2)
    }

    static var projectorWindowBottomY: CGFloat {
        projectorWindowCenterY + (projectorWindowFrameHeight / 2)
    }

    static var viewportLeadingOffset: CGFloat {
        -viewportHorizontalBleed
    }

    static func viewportWidth(forContentWidth contentWidth: CGFloat) -> CGFloat {
        max(0, contentWidth + (viewportHorizontalBleed * 2))
    }

    static func viewportCenterXInContent(forContentWidth contentWidth: CGFloat) -> CGFloat {
        viewportLeadingOffset + (viewportWidth(forContentWidth: contentWidth) / 2)
    }

    static func viewportLeadingX(forContentLeadingX contentLeadingX: CGFloat) -> CGFloat {
        contentLeadingX + viewportLeadingOffset
    }

    static func viewportTrailingX(
        forContentLeadingX contentLeadingX: CGFloat,
        contentWidth: CGFloat
    ) -> CGFloat {
        viewportLeadingX(forContentLeadingX: contentLeadingX)
            + viewportWidth(forContentWidth: contentWidth)
    }

    static func filmStripViewportWidth(forVisualViewportWidth visualViewportWidth: CGFloat, contentWidth _: CGFloat) -> CGFloat {
        max(0, visualViewportWidth)
    }

    static func filmStripViewportLeadingX(forVisualViewportWidth _: CGFloat) -> CGFloat {
        0
    }
}

private struct FilmProjectorTransport: View {
    let frames: [FilmRollViewerFrame]
    @Binding var selectedIndex: Int
    let photoDisplayImageStore: PhotoDisplayImageStore
    @State private var dragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            let frameWidths = transportFrameWidths
            let boundedDrag = FilmRollDetailFilmTransportInteraction.boundedDragTranslation(
                dragTranslation,
                selectedIndex: selectedIndex,
                frameCount: frames.count,
                leaderLength: FilmRollProjectorTransportLayout.leaderLength,
                trailerLength: FilmRollProjectorTransportLayout.trailerLength
            )
            let offset = FilmRollDetailFilmTransportInteraction.contentOffset(
                selectedIndex: selectedIndex,
                dragTranslation: boundedDrag,
                frameWidths: frameWidths,
                frameSpacing: FilmRollProjectorTransportLayout.frameSpacing,
                leadingInset: FilmRollProjectorTransportLayout.leaderLength,
                viewportCenter: FilmRollProjectorTransportLayout.filmFrameTargetCenterX(
                    forViewportWidth: proxy.size.width
                )
            )
            let filmContentWidth = contentWidth(frameWidths: frameWidths)
            let filmViewportWidth = FilmRollProjectorTransportLayout.filmStripViewportWidth(
                forVisualViewportWidth: proxy.size.width,
                contentWidth: filmContentWidth
            )

            ZStack(alignment: .bottom) {
                FilmProjectorBackFrame()
                    .frame(
                        width: FilmRollProjectorTransportLayout.backFrameWidth,
                        height: FilmRollProjectorTransportLayout.backFrameHeight
                    )
                    .position(x: proxy.size.width / 2, y: FilmRollProjectorTransportLayout.projectorCenterY)

                projectorFilmStrip(
                    contentWidth: filmContentWidth,
                    offset: offset,
                    viewportWidth: filmViewportWidth
                )
                    .position(x: proxy.size.width / 2, y: FilmRollProjectorTransportLayout.filmCenterY)

                FilmProjectorFrontViewer()
                    .frame(
                        width: FilmRollProjectorTransportLayout.frontViewerWidth,
                        height: FilmRollProjectorTransportLayout.frontViewerHeight
                    )
                    .position(x: proxy.size.width / 2, y: FilmRollProjectorTransportLayout.projectorCenterY)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(dragGesture)
        }
        .frame(height: FilmRollProjectorTransportLayout.totalHeight)
        .onAppear(perform: clampSelection)
        .onChange(of: frames.count, initial: false) { _, _ in
            clampSelection()
        }
    }

    private func projectorFilmStrip(contentWidth: CGFloat, offset: CGFloat, viewportWidth: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.92))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }

                VStack(spacing: 6) {
                    transportSprockets(width: contentWidth)
                    HStack(spacing: FilmRollProjectorTransportLayout.frameSpacing) {
                        filmEnd(length: FilmRollProjectorTransportLayout.leaderLength)
                        ForEach(Array(frames.enumerated()), id: \.element.id) { index, frame in
                            FilmProjectorTransportFrame(
                                frame: frame,
                                isSelected: index == selectedIndex,
                                frameSize: frameSize(
                                    for: frame,
                                    fixedHeight: FilmRollProjectorTransportLayout.filmFrameHeight,
                                    maxPixelDimension: 360
                                ),
                                photoDisplayImageStore: photoDisplayImageStore
                            )
                        }
                        filmEnd(length: FilmRollProjectorTransportLayout.trailerLength)
                    }
                    .frame(width: contentWidth, alignment: .leading)
                    .frame(height: FilmRollProjectorTransportLayout.filmFrameHeight)
                    transportSprockets(width: contentWidth)
                }
                .frame(width: contentWidth)
            }
            .frame(width: contentWidth)
            .offset(x: offset)
        }
        .frame(
            width: viewportWidth,
            height: FilmRollProjectorTransportLayout.filmHeight,
            alignment: .leading
        )
        .clipped()
    }

    private func transportSprockets(width: CGFloat) -> some View {
        let slotStep: CGFloat = 11
        let slotCount = max(1, Int(ceil(width / slotStep)))

        return HStack(spacing: 7) {
            ForEach(0..<slotCount, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Color.white.opacity(0.36))
                    .frame(width: 4, height: FilmRollProjectorTransportLayout.sprocketHeight)
            }
        }
        .frame(width: width, alignment: .leading)
        .clipped()
    }

    private func filmEnd(length: CGFloat) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: length, height: FilmRollProjectorTransportLayout.filmFrameHeight)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4, coordinateSpace: .local)
            .onChanged { value in
                dragTranslation = FilmRollDetailFilmTransportInteraction.boundedDragTranslation(
                    value.translation.width,
                    selectedIndex: selectedIndex,
                    frameCount: frames.count,
                    leaderLength: FilmRollProjectorTransportLayout.leaderLength,
                    trailerLength: FilmRollProjectorTransportLayout.trailerLength
                )
            }
            .onEnded { value in
                let frameWidths = transportFrameWidths
                let releaseTranslation = FilmRollDetailFilmTransportInteraction.boundedDragTranslation(
                    value.translation.width,
                    selectedIndex: selectedIndex,
                    frameCount: frames.count,
                    leaderLength: FilmRollProjectorTransportLayout.leaderLength,
                    trailerLength: FilmRollProjectorTransportLayout.trailerLength
                )
                let target = FilmRollDetailFilmTransportInteraction.targetIndex(
                    selectedIndex: selectedIndex,
                    dragTranslation: releaseTranslation,
                    frameWidths: frameWidths,
                    frameSpacing: FilmRollProjectorTransportLayout.frameSpacing
                )
                snapToFrame(at: target, releaseTranslation: releaseTranslation, frameWidths: frameWidths)
            }
    }

    private var transportFrameWidths: [CGFloat] {
        frames.map {
            frameSize(
                for: $0,
                fixedHeight: FilmRollProjectorTransportLayout.filmFrameHeight,
                maxPixelDimension: 360
            ).width
        }
    }

    private func contentWidth(frameWidths: [CGFloat]) -> CGFloat {
        FilmRollProjectorTransportLayout.leaderLength
            + frameWidths.reduce(0, +)
            + (CGFloat(max(frames.count - 1, 0)) * FilmRollProjectorTransportLayout.frameSpacing)
            + FilmRollProjectorTransportLayout.trailerLength
    }

    private func frameSize(
        for frame: FilmRollViewerFrame,
        fixedHeight: CGFloat,
        maxPixelDimension: Int
    ) -> CGSize {
        FilmRollProjectorFrameLayout.frameSize(
            aspectRatio: aspectRatio(for: frame, maxPixelDimension: maxPixelDimension),
            fixedHeight: fixedHeight
        )
    }

    private func aspectRatio(for frame: FilmRollViewerFrame, maxPixelDimension: Int) -> CGFloat? {
        photoDisplayImageStore.aspectRatio(
            relativePath: frame.photo.thumbnailRelativePath ?? frame.photo.fullSizeRelativePath,
            maxPixelDimension: maxPixelDimension
        ) ?? photoDisplayImageStore.aspectRatio(
            relativePath: frame.photo.fullSizeRelativePath ?? frame.photo.thumbnailRelativePath,
            maxPixelDimension: maxPixelDimension
        )
    }

    private var safeSelectedIndex: Int {
        min(max(selectedIndex, 0), max(frames.count - 1, 0))
    }

    private func clampSelection() {
        let clamped = safeSelectedIndex
        if selectedIndex != clamped {
            selectedIndex = clamped
        }
        dragTranslation = 0
    }

    private func snapToFrame(at index: Int, releaseTranslation: CGFloat, frameWidths: [CGFloat]) {
        let clamped = min(max(index, 0), max(frames.count - 1, 0))
        let previousIndex = selectedIndex

        guard clamped != previousIndex else {
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                dragTranslation = 0
            }
            return
        }

        let continuityTranslation = FilmRollDetailFilmTransportInteraction.continuityDragTranslation(
            releaseTranslation: releaseTranslation,
            selectedIndex: previousIndex,
            targetIndex: clamped,
            frameWidths: frameWidths,
            frameSpacing: FilmRollProjectorTransportLayout.frameSpacing
        )
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            selectedIndex = clamped
            dragTranslation = continuityTranslation
        }

        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            dragTranslation = 0
        }
        FilmRollDetailFilmTransportInteraction.triggerSelectionChanged()
    }
}

private struct FilmProjectorTransportFrame: View {
    let frame: FilmRollViewerFrame
    let isSelected: Bool
    let frameSize: CGSize
    let photoDisplayImageStore: PhotoDisplayImageStore

    var body: some View {
        ZStack(alignment: .topLeading) {
            FilmProjectorFrameImage(
                frame: frame,
                photoDisplayImageStore: photoDisplayImageStore,
                maxPixelDimension: 360,
                cornerRadius: 5
            )
            .frame(
                width: frameSize.width,
                height: frameSize.height
            )
            .overlay {
                let dimmingOpacity = FilmRollProjectorTransportLayout.filmFrameImageDimmingOpacity(isSelected: isSelected)
                if FilmRollProjectorTransportLayout.dimsFilmFrameImages, dimmingOpacity > 0 {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.black.opacity(dimmingOpacity))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(isSelected ? LumoTheme.Colors.accent : Color.white.opacity(0.15), lineWidth: isSelected ? 2 : 1)
            }

            Text(frame.kind == .reference ? "S" : frame.photo.label)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(.white)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(.black.opacity(0.46), in: RoundedRectangle(cornerRadius: 3, style: .continuous))
                .padding(4)
        }
        .frame(
            width: frameSize.width,
            height: frameSize.height
        )
        .accessibilityLabel(frame.photo.accessibilityLabel)
    }
}

private struct FilmProjectorBackFrame: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image(FilmRollProjectorTransportLayout.backFrameAssetName(isDarkMode: colorScheme == .dark))
            .resizable()
            .interpolation(.high)
            .frame(
                width: FilmRollProjectorTransportLayout.backFrameWidth,
                height: FilmRollProjectorTransportLayout.backFrameHeight
            )
            .allowsHitTesting(false)
    }
}

private struct FilmProjectorFrontViewer: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image(FilmRollProjectorTransportLayout.frontViewerAssetName(isDarkMode: colorScheme == .dark))
            .resizable()
            .interpolation(.high)
            .frame(
                width: FilmRollProjectorTransportLayout.frontViewerWidth,
                height: FilmRollProjectorTransportLayout.frontViewerHeight
            )
            .allowsHitTesting(false)
    }
}

private struct FilmProjectorFrameImage: View {
    let frame: FilmRollViewerFrame
    let photoDisplayImageStore: PhotoDisplayImageStore
    let maxPixelDimension: Int
    let cornerRadius: CGFloat
    var background: Color = Color.black.opacity(0.08)

    var body: some View {
        ZStack {
            background
            frameImage
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private var frameImage: some View {
        if let image = frame.photo.image {
            image
                .resizable()
                .scaledToFit()
        } else if let relativePath = frame.photo.thumbnailRelativePath ?? frame.photo.fullSizeRelativePath {
            PhotoDisplayImageView(
                store: photoDisplayImageStore,
                relativePath: relativePath,
                maxPixelDimension: maxPixelDimension,
                contentMode: .fit
            ) {
                LumoPhotoPlaceholder(style: .unavailable, title: frame.displayLabel)
            }
        } else {
            LumoPhotoPlaceholder(style: .unavailable, title: frame.displayLabel)
        }
    }
}

#Preview {
    FilmRollDetailModelHost(
        model: AppContainer.preview.makeFilmRollDetailModel(filmRollID: "warm-picnic"),
        photoDisplayImageStore: AppContainer.preview.makePhotoDisplayImageStore(),
        photoImportStagingService: AppContainer.preview.photoImportStagingService,
        reloadToken: 0,
        onBack: {},
        onApply: { _, _, _ in },
        onRemoved: {},
        onOpenFrame: { _, _ in }
    )
}

private func detailScreenErrorMessage(_ error: Error) -> String {
    if let message = (error as? LocalizedError)?.errorDescription {
        return message
    }
    return error.localizedDescription
}
