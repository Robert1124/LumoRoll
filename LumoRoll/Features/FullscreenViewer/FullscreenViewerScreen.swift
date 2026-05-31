import SwiftUI

enum FullscreenViewerAction: CaseIterable, Hashable {
    case share
    case edit
    case remove

    var title: String {
        switch self {
        case .share:
            "Share"
        case .edit:
            "Edit"
        case .remove:
            "Remove"
        }
    }

    var systemImage: String {
        switch self {
        case .share:
            "square.and.arrow.up"
        case .edit:
            "slider.horizontal.3"
        case .remove:
            "trash"
        }
    }
}

enum FullscreenPhotoPreviewInteraction {
    static let supportsPinchZoom = false
    static let supportsTwoFingerPan = false
}

enum FullscreenActionBarLayout {
    static let reservesProcessedFrameActionSpace = true
    static let reservedActions = FullscreenViewerAction.allCases
}

struct FullscreenActionAvailability: Equatable {
    private let unavailableMessages: [FullscreenViewerAction: String]

    static let task8Pending = FullscreenActionAvailability(
        unavailableMessages: Dictionary(
            uniqueKeysWithValues: FullscreenViewerAction.allCases.map {
                ($0, "\($0.title) is not available in this build.")
            }
        )
    )

    static let allAvailable = FullscreenActionAvailability(unavailableMessages: [:])

    static func mvp1(for frame: FilmRollViewerFrame) -> FullscreenActionAvailability {
        var unavailableMessages: [FullscreenViewerAction: String] = [:]

        switch frame.kind {
        case .reference:
            unavailableMessages[.share] = "The reference sample is view-only in fullscreen."
            unavailableMessages[.edit] = "The reference sample is view-only in fullscreen."
            unavailableMessages[.remove] = "The reference sample is view-only in fullscreen."
        case .processed:
            if frame.photo.fullSizeRelativePath == nil {
                unavailableMessages[.share] = "This processed photo cannot be shared because its rendered file is missing."
            }
            break
        }

        return FullscreenActionAvailability(unavailableMessages: unavailableMessages)
    }

    func isAvailable(_ action: FullscreenViewerAction) -> Bool {
        unavailableMessages[action] == nil
    }

    func unavailableMessage(for action: FullscreenViewerAction) -> String {
        unavailableMessages[action] ?? ""
    }
}

struct FullscreenSaveRequest: Equatable {
    let frameID: String
    let selectedIndex: Int
    let processedPath: String
}

enum FullscreenSaveCompletion: Equatable {
    case success
    case failure(String)
}

struct FullscreenSaveStatusState: Equatable {
    private(set) var activeRequest: FullscreenSaveRequest?

    mutating func start(
        frameID: String,
        selectedIndex: Int,
        processedPath: String
    ) -> FullscreenSaveRequest? {
        guard activeRequest == nil else {
            return nil
        }

        let request = FullscreenSaveRequest(
            frameID: frameID,
            selectedIndex: selectedIndex,
            processedPath: processedPath
        )
        activeRequest = request
        return request
    }

    mutating func complete(
        _ request: FullscreenSaveRequest?,
        currentFrameID: String,
        currentSelectedIndex: Int,
        completion: FullscreenSaveCompletion
    ) -> String? {
        guard let request, activeRequest == request else {
            return nil
        }

        activeRequest = nil

        guard request.frameID == currentFrameID,
              request.selectedIndex == currentSelectedIndex else {
            return nil
        }

        switch completion {
        case .success:
            return "Saved to Photos."
        case .failure(let message):
            return "Could not save to Photos: \(message)"
        }
    }
}

struct FullscreenViewerScreen: View {
    let startIndex: Int
    let photoDisplayImageStore: PhotoDisplayImageStore
    var onClose: () -> Void
    var actionAvailability: (FilmRollViewerFrame) -> FullscreenActionAvailability
    var shareURLResolver: (String) throws -> URL
    var onEditProcessedPhoto: (FilmRoll, ProcessedPhoto) -> Void
    var onRemoveProcessedPhoto: (FilmRoll, ProcessedPhoto) async throws -> FilmRoll

    @State private var filmRoll: FilmRoll
    @State private var selectedIndex: Int
    @State private var unavailableMessage: String?
    @State private var outputStatusMessage: String?
    @State private var saveStatusState = FullscreenSaveStatusState()
    @State private var isRemoveConfirmationPresented = false
    @State private var isRemoving = false

    private var frames: [FilmRollViewerFrame] {
        FilmRollViewerFrame.frames(for: filmRoll)
    }

    init(
        filmRoll: FilmRoll,
        startIndex: Int,
        photoDisplayImageStore: PhotoDisplayImageStore,
        onClose: @escaping () -> Void,
        actionAvailability: @escaping (FilmRollViewerFrame) -> FullscreenActionAvailability = FullscreenActionAvailability.mvp1,
        shareURLResolver: @escaping (String) throws -> URL = { URL(fileURLWithPath: $0) },
        onEditProcessedPhoto: @escaping (FilmRoll, ProcessedPhoto) -> Void = { _, _ in },
        onRemoveProcessedPhoto: @escaping (FilmRoll, ProcessedPhoto) async throws -> FilmRoll = { filmRoll, _ in filmRoll }
    ) {
        self.startIndex = startIndex
        self.photoDisplayImageStore = photoDisplayImageStore
        self.onClose = onClose
        self.actionAvailability = actionAvailability
        self.shareURLResolver = shareURLResolver
        self.onEditProcessedPhoto = onEditProcessedPhoto
        self.onRemoveProcessedPhoto = onRemoveProcessedPhoto
        _filmRoll = State(initialValue: filmRoll)
        _selectedIndex = State(initialValue: startIndex)
    }

    var body: some View {
        ZStack {
            LumoTheme.Colors.noirBackground.ignoresSafeArea()

            VStack(spacing: LumoTheme.Spacing.large) {
                header

                TabView(selection: $selectedIndex) {
                    ForEach(Array(frames.enumerated()), id: \.element.id) { index, frame in
                        frameView(frame)
                            .tag(index)
                            .padding(.horizontal, LumoTheme.Spacing.medium)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                pageDots
                actionBar
            }
            .padding(.top, LumoTheme.Spacing.medium)
            .padding(.bottom, LumoTheme.Spacing.medium)
        }
        .preferredColorScheme(.dark)
        .onChange(of: selectedIndex, initial: false) { _, _ in
            unavailableMessage = nil
            outputStatusMessage = nil
        }
        .confirmationDialog(
            "Remove photo?",
            isPresented: $isRemoveConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                removeCurrentProcessedFrame()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the processed photo from this Film Roll.")
        }
    }

    private var header: some View {
        HStack {
            LumoIconButton(systemImage: "xmark", accessibilityLabel: "Close viewer", variant: .ghost, action: onClose)
            Spacer()
            VStack(spacing: LumoTheme.Spacing.xxSmall) {
                Text(filmRoll.name)
                    .font(LumoTheme.Typography.technicalLabel)
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.56))
                    .lineLimit(1)
                Text(currentFrame.displayLabel)
                    .font(LumoTheme.Typography.callout.weight(.semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Color.clear
                .frame(width: LumoTheme.Metrics.minimumHitTarget, height: LumoTheme.Metrics.minimumHitTarget)
        }
        .padding(.horizontal, LumoTheme.Spacing.medium)
    }

    private func frameView(_ frame: FilmRollViewerFrame) -> some View {
        GeometryReader { proxy in
            ZStack {
                frameImage(frame)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipShape(RoundedRectangle(cornerRadius: LumoTheme.Radius.thumbnail, style: .continuous))
            .contentShape(Rectangle())
            .accessibilityLabel(frame.photo.accessibilityLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func frameImage(_ frame: FilmRollViewerFrame) -> some View {
        if let image = frame.photo.image {
            image
                .resizable()
                .scaledToFit()
        } else if let relativePath = frame.photo.fullSizeRelativePath {
            PhotoDisplayImageView(
                store: photoDisplayImageStore,
                relativePath: relativePath,
                maxPixelDimension: 2_048,
                contentMode: .fit
            ) {
                LumoPhotoPlaceholder(style: .unavailable, title: frame.displayLabel)
            }
        } else {
            LumoPhotoPlaceholder(style: .unavailable, title: frame.displayLabel)
        }
    }

    private var pageDots: some View {
        HStack(spacing: 6) {
            ForEach(frames.indices, id: \.self) { index in
                Capsule()
                    .fill(index == selectedIndex ? .white : .white.opacity(0.35))
                    .frame(width: index == selectedIndex ? 18 : 6, height: 6)
            }
        }
        .accessibilityLabel("Frame \(selectedIndex + 1) of \(max(frames.count, 1))")
    }

    private var actionBar: some View {
        VStack(spacing: LumoTheme.Spacing.small) {
            if currentFrame.kind == .processed {
                processedActionRow
            } else if FullscreenActionBarLayout.reservesProcessedFrameActionSpace {
                processedActionPlaceholderRow
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(LumoTheme.Typography.label)
                    .foregroundStyle(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, LumoTheme.Spacing.medium)
        .padding(.top, LumoTheme.Spacing.small)
    }

    private var processedActionRow: some View {
        HStack(spacing: LumoTheme.Spacing.small) {
            ForEach(FullscreenActionBarLayout.reservedActions, id: \.self) { action in
                actionControl(for: action)
            }
        }
    }

    private var processedActionPlaceholderRow: some View {
        HStack(spacing: LumoTheme.Spacing.small) {
            ForEach(FullscreenActionBarLayout.reservedActions, id: \.self) { action in
                FullscreenActionLabel(title: action.title, systemImage: action.systemImage)
                    .hidden()
                    .accessibilityHidden(true)
            }
        }
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private func actionControl(for action: FullscreenViewerAction) -> some View {
        switch action {
        case .share:
            shareActionControl
        case .edit, .remove:
            FullscreenActionButton(title: action.title, systemImage: action.systemImage) {
                handleAction(action)
            }
            .opacity(currentAvailability.isAvailable(action) && !isBusy ? 1 : 0.42)
            .disabled(isBusy)
        }
    }

    @ViewBuilder
    private var shareActionControl: some View {
        if let shareURL = currentShareURL, currentAvailability.isAvailable(.share) {
            ShareLink(item: shareURL) {
                FullscreenActionLabel(title: FullscreenViewerAction.share.title, systemImage: FullscreenViewerAction.share.systemImage)
            }
            .buttonStyle(.plain)
            .opacity(!isBusy ? 1 : 0.42)
            .disabled(isBusy)
        } else {
            FullscreenActionButton(
                title: FullscreenViewerAction.share.title,
                systemImage: FullscreenViewerAction.share.systemImage
            ) {
                handleAction(.share)
            }
            .opacity(0.42)
            .disabled(isBusy)
        }
    }

    private func handleAction(_ action: FullscreenViewerAction) {
        guard currentAvailability.isAvailable(action) else {
            outputStatusMessage = nil
            unavailableMessage = currentAvailability.unavailableMessage(for: action)
            return
        }
        unavailableMessage = nil
        switch action {
        case .share:
            guard currentShareURL != nil else {
                outputStatusMessage = "This processed photo could not be shared."
                return
            }
        case .edit:
            guard let currentProcessedPhoto else {
                outputStatusMessage = "This processed photo could not be edited."
                return
            }
            onEditProcessedPhoto(filmRoll, currentProcessedPhoto)
        case .remove:
            guard currentProcessedPhoto != nil else {
                outputStatusMessage = "This processed photo could not be removed."
                return
            }
            isRemoveConfirmationPresented = true
        }
    }

    private var currentFrame: FilmRollViewerFrame {
        let clampedIndex = min(max(selectedIndex, 0), max(frames.count - 1, 0))
        return frames.isEmpty
            ? FilmRollViewerFrame(
                id: "empty",
                kind: .reference,
                displayLabel: "Sample",
                photo: LumoPhotoDisplayData(id: "empty", label: "Sample", image: nil)
            )
            : frames[clampedIndex]
    }

    private var currentAvailability: FullscreenActionAvailability {
        actionAvailability(currentFrame)
    }

    private var currentProcessedPhoto: ProcessedPhoto? {
        guard currentFrame.kind == .processed else {
            return nil
        }
        return filmRoll.processedPhotos.first { $0.id == currentFrame.id }
    }

    private var currentShareURL: URL? {
        guard let processedPath = currentFrame.fullscreenProcessedOutputPath else {
            return nil
        }

        return try? shareURLResolver(processedPath)
    }

    private var isBusy: Bool {
        saveStatusState.activeRequest != nil || isRemoving
    }

    private var statusMessage: String? {
        unavailableMessage ?? outputStatusMessage
    }

    private func removeCurrentProcessedFrame() {
        guard !isRemoving, let photo = currentProcessedPhoto else {
            return
        }

        isRemoving = true
        outputStatusMessage = "Removing photo..."
        Task {
            do {
                let updatedRoll = try await onRemoveProcessedPhoto(filmRoll, photo)
                filmRoll = updatedRoll
                let maxIndex = max(frames.count - 1, 0)
                selectedIndex = min(selectedIndex, maxIndex)
                outputStatusMessage = "Photo removed."
            } catch {
                outputStatusMessage = "Could not remove photo: \(fullscreenErrorMessage(error))"
            }
            isRemoving = false
        }
    }
}

#Preview {
    FullscreenViewerScreen(
        filmRoll: PreviewFilmRollRepository.previewRolls[0],
        startIndex: 0,
        photoDisplayImageStore: AppContainer.preview.makePhotoDisplayImageStore(),
        onClose: {}
    )
}

private func fullscreenErrorMessage(_ error: Error) -> String {
    if let message = (error as? LocalizedError)?.errorDescription {
        return message
    }
    return error.localizedDescription
}

extension FilmRollViewerFrame {
    var fullscreenProcessedOutputPath: String? {
        guard kind == .processed else {
            return nil
        }
        return photo.fullSizeRelativePath
    }
}
