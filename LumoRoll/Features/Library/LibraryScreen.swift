import SwiftUI
import UIKit

struct LibraryCarouselCardFrameInfo: Equatable {
    let id: String
    let rollID: String
    let midX: CGFloat

    init(
        id: String,
        rollID: String? = nil,
        midX: CGFloat
    ) {
        self.id = id
        self.rollID = rollID ?? id
        self.midX = midX
    }
}

enum LibrarySlideMountCopy {
    static let brandLine = "LUMOROLL"
    static let categoryLine = "COLOR ROLL"
    static let lowerLeftLabel = "LUT"
    static let lowerRightLabel = "33x33x33"
}

struct PerspectiveFilmCarouselTransform: Equatable {
    let normalizedOffset: CGFloat
    let xOffset: CGFloat
    let scale: CGFloat
    let rotationYDegrees: CGFloat
    let opacity: CGFloat
    let zIndex: Double
    let shadowRadius: CGFloat
    let shadowYOffset: CGFloat
    let blurRadius: CGFloat
    let photoLightAmount: CGFloat
}

enum LibraryHomeLayout {
    static let allowsVerticalScroll = false
}

enum LibraryHomeChrome {
    static let showsTopBrandAndCreateControls = false
}

enum LibraryCarouselSelectedSummaryPlacement: Equatable {
    case aboveCarousel
}

enum LibraryCarouselCardVerticalBias: Equatable {
    case slightlyBelowCenter
}

enum LibraryCarouselTitleLayout {
    static let selectedSummaryPlacement: LibraryCarouselSelectedSummaryPlacement = .aboveCarousel
    static let cardVerticalBias: LibraryCarouselCardVerticalBias = .slightlyBelowCenter
    static let selectedSummaryReservedHeight: CGFloat = 124
    static let cardCenterOffsetFromViewportCenter: CGFloat = 20
    static let carouselVisualOffsetY: CGFloat = 0
    static let pageIndicatorTopSpacing: CGFloat = 54
    static let titleAndCardLift: CGFloat = 20
    static let minimumTitleTopInset: CGFloat = 56

    static func titleTopInset(forAvailableHeight availableHeight: CGFloat) -> CGFloat {
        max(
            minimumTitleTopInset,
            PerspectiveFilmCarouselLayout.carouselTopInset(forAvailableHeight: availableHeight) - titleAndCardLift
        )
    }

    static func cardCenterY(forAvailableHeight availableHeight: CGFloat) -> CGFloat {
        max(0, (availableHeight / 2) + cardCenterOffsetFromViewportCenter)
    }

    static func summaryToCarouselSpacing(forAvailableHeight availableHeight: CGFloat) -> CGFloat {
        max(
            0,
            cardCenterY(forAvailableHeight: availableHeight)
                - titleTopInset(forAvailableHeight: availableHeight)
                - selectedSummaryReservedHeight
                - (PerspectiveFilmCarouselLayout.carouselHeight / 2)
                - carouselVisualOffsetY
        )
    }
}

enum LibraryEmptyStateHeroKind: Equatable {
    case blankReversalSlideCard
}

enum LibraryEmptyStateBackgroundTreatment: Equatable {
    case none
}

enum LibraryEmptyStateContentPlacement: Equatable {
    case centeredHeroAndAction
    case matchesSingleRollCarouselSlot
}

enum LibraryEmptyStateTitlePlacement: Equatable {
    case aboveCarousel
}

enum LibraryEmptyStatePresentation {
    static let heroKind: LibraryEmptyStateHeroKind = .blankReversalSlideCard
    static let title = "Create your first Film Roll"
    static let actionTitle: String? = nil
    static let cardAccessibilityLabel = LibraryCarouselAddCardPresentation.accessibilityLabel
    static let photoPlaceholderTitle: String? = nil
    static let backgroundTreatment: LibraryEmptyStateBackgroundTreatment = .none
    static let contentPlacement: LibraryEmptyStateContentPlacement = .matchesSingleRollCarouselSlot
}

enum LibraryEmptyStateLayout {
    static let titlePlacement: LibraryEmptyStateTitlePlacement = .aboveCarousel
    static let summaryReservedHeight = LibraryCarouselTitleLayout.selectedSummaryReservedHeight
    static let centerCardTransform = PerspectiveFilmCarouselLayout.coverFlowTransform(normalizedOffset: 0)
    static let showsPageIndicator = false
    static let showsPrimaryActionButton = false
    static let showsBottomSummary = false

    static func cardWidth(forContentWidth contentWidth: CGFloat) -> CGFloat {
        PerspectiveFilmCarouselLayout.cardWidth(forContentWidth: contentWidth)
    }

    static func titleTopInset(forAvailableHeight availableHeight: CGFloat) -> CGFloat {
        LibraryCarouselTitleLayout.titleTopInset(forAvailableHeight: availableHeight)
    }

    static func summaryToCarouselSpacing(forAvailableHeight availableHeight: CGFloat) -> CGFloat {
        LibraryCarouselTitleLayout.summaryToCarouselSpacing(forAvailableHeight: availableHeight)
    }
}

enum LibraryCarouselCardActivation: Equatable {
    case tapGesture
}

enum LibraryCarouselDragGesturePriority: Equatable {
    case highPriority
}

enum LibraryCarouselDragStateLifetime: Equatable {
    case persistentThroughSnapAnimation
}

enum LibraryCarouselItemKind: Equatable {
    case roll
    case addRoll
}

enum LibraryCarouselAddCardPresentation {
    static let id = "library-add-roll"
    static let summaryTitle = "Create a new roll"
    static let accessibilityLabel = "Create Film Roll"
    static let showsCenteredAddButton = true
    static let reservesRollSummaryRows = true
}

struct LibraryCarouselItem: Identifiable {
    let id: String
    let kind: LibraryCarouselItemKind
    let roll: FilmRollDisplayData?
    let serialNumber: Int

    static func items(for rolls: [FilmRollDisplayData]) -> [LibraryCarouselItem] {
        var items = rolls.enumerated().map { index, roll in
            LibraryCarouselItem(
                id: roll.id,
                kind: .roll,
                roll: roll,
                serialNumber: index + 1
            )
        }
        items.append(
            LibraryCarouselItem(
                id: LibraryCarouselAddCardPresentation.id,
                kind: .addRoll,
                roll: nil,
                serialNumber: rolls.count + 1
            )
        )
        return items
    }

    var rollID: String? {
        roll?.id
    }

    var requestsCreate: Bool {
        kind == .addRoll
    }

    var summaryTitle: String {
        roll?.name ?? LibraryCarouselAddCardPresentation.summaryTitle
    }

    var accessibilityLabel: String {
        switch kind {
        case .roll:
            if let roll {
                return "Open Film Roll \(roll.name)"
            }
            return "Open Film Roll"
        case .addRoll:
            return LibraryCarouselAddCardPresentation.accessibilityLabel
        }
    }
}

enum LibraryCarouselInteraction {
    static let cardActivation: LibraryCarouselCardActivation = .tapGesture
    static let dragGesturePriority: LibraryCarouselDragGesturePriority = .highPriority
    static let dragMinimumDistance: CGFloat = 6
    static let dragStateLifetime: LibraryCarouselDragStateLifetime = .persistentThroughSnapAnimation
}

enum PerspectiveFilmCarouselLayout {
    static let slideCardAspectRatio: CGFloat = 1
    static let centerScale: CGFloat = 1.05
    static let sideScale: CGFloat = 0.9
    static let farScale: CGFloat = 0.78
    static let sideOpacity: CGFloat = 0.82
    static let farOpacity: CGFloat = 0.48
    static let cardSpacing: CGFloat = -72
    static let carouselHeight: CGFloat = 326
    static let photoWindowHeightFraction: CGFloat = 0.44
    static let photoWindowMinWidthFraction: CGFloat = 0.34
    static let photoWindowMaxWidthFraction: CGFloat = 0.76
    static let fallbackPhotoAspectRatio: CGFloat = 3.0 / 2.0
    static let bottomSummaryTopSpacing: CGFloat = 72
    static let minimumCarouselTopInset: CGFloat = 60
    static let maximumCarouselTopInset: CGFloat = 124
    static let carouselTopInsetHeightRatio: CGFloat = 0.14
    static let maximumRotationYDegrees: CGFloat = 36
    static let sideInwardOffset: CGFloat = 20
    static let coordinateSpaceName = "library-carousel"

    static func cardWidth(forContentWidth contentWidth: CGFloat) -> CGFloat {
        min(268, max(224, contentWidth * 0.66))
    }

    static func sideInset(forContentWidth contentWidth: CGFloat, cardWidth: CGFloat) -> CGFloat {
        max(0, (contentWidth - cardWidth) / 2)
    }

    static func itemStep(cardWidth: CGFloat) -> CGFloat {
        max(1, cardWidth + cardSpacing)
    }

    static func carouselTopInset(forAvailableHeight availableHeight: CGFloat) -> CGFloat {
        min(
            maximumCarouselTopInset,
            max(minimumCarouselTopInset, max(0, availableHeight) * carouselTopInsetHeightRatio)
        )
    }

    static func coverFlowTransform(normalizedOffset: CGFloat) -> PerspectiveFilmCarouselTransform {
        let clampedOffset = max(-1.6, min(1.6, normalizedOffset))
        let distance = min(1, abs(clampedOffset))
        let farDistance = min(1, max(0, abs(clampedOffset) - 1))
        let sideScaleValue = centerScale - ((centerScale - sideScale) * distance)
        let scale = sideScaleValue - ((sideScale - farScale) * farDistance)
        let opacity = sideOpacity + ((1 - sideOpacity) * (1 - distance)) - (0.34 * farDistance)
        let centerProgress = max(0, 1 - distance)

        return PerspectiveFilmCarouselTransform(
            normalizedOffset: normalizedOffset,
            xOffset: -sign(clampedOffset) * sideInwardOffset * distance,
            scale: scale,
            rotationYDegrees: -clampedOffset * maximumRotationYDegrees,
            opacity: max(farOpacity, min(1, opacity)),
            zIndex: Double(10 - (abs(clampedOffset) * 4)),
            shadowRadius: 8 + (18 * centerProgress),
            shadowYOffset: 5 + (8 * centerProgress),
            blurRadius: 0.7 * farDistance,
            photoLightAmount: max(0.12, 1 - (distance * 0.72) - (farDistance * 0.22))
        )
    }

    static func photoWindowSize(cardSize: CGFloat, imageAspectRatio: CGFloat?) -> CGSize {
        let height = cardSize * photoWindowHeightFraction
        let aspectRatio = sanitizedPhotoAspectRatio(imageAspectRatio)
        let rawWidth = height * aspectRatio
        let minWidth = cardSize * photoWindowMinWidthFraction
        let maxWidth = cardSize * photoWindowMaxWidthFraction
        let width = min(max(rawWidth, minWidth), maxWidth)
        return CGSize(width: width, height: height)
    }

    static func normalizedOffset(
        itemIndex: Int,
        centeredIndex: Int,
        itemCount: Int,
        dragTranslation: CGFloat,
        itemStep: CGFloat
    ) -> CGFloat {
        guard itemCount > 0 else {
            return 0
        }

        guard itemStep > 0 else {
            return CGFloat(itemIndex - centeredIndex)
        }

        return CGFloat(itemIndex - centeredIndex) + (dragTranslation / itemStep)
    }

    static func snapDelta(predictedTranslation: CGFloat, itemStep: CGFloat) -> Int {
        guard itemStep > 0 else {
            return 0
        }

        let rawDelta = -predictedTranslation / itemStep
        return Int(rawDelta.rounded())
    }

    static func continuityDragTranslation(
        releaseTranslation: CGFloat,
        indexDelta: Int,
        itemStep: CGFloat
    ) -> CGFloat {
        releaseTranslation + (CGFloat(indexDelta) * itemStep)
    }

    static func indexByAdding(_ delta: Int, to index: Int, count: Int) -> Int {
        guard count > 0 else {
            return 0
        }

        return min(max(index + delta, 0), count - 1)
    }

    static func boundedDragTranslation(
        _ translation: CGFloat,
        centeredIndex: Int,
        itemCount: Int,
        itemStep: CGFloat
    ) -> CGFloat {
        guard itemCount > 1, itemStep > 0 else {
            return 0
        }

        let rightBoundary = CGFloat(max(centeredIndex, 0)) * itemStep
        let leftBoundary = -CGFloat(max(itemCount - 1 - centeredIndex, 0)) * itemStep
        return min(max(translation, leftBoundary), rightBoundary)
    }

    private static func sanitizedPhotoAspectRatio(_ imageAspectRatio: CGFloat?) -> CGFloat {
        guard let imageAspectRatio,
              imageAspectRatio.isFinite,
              imageAspectRatio > 0 else {
            return fallbackPhotoAspectRatio
        }

        return imageAspectRatio
    }

    private static func sign(_ value: CGFloat) -> CGFloat {
        if value > 0 {
            return 1
        }

        if value < 0 {
            return -1
        }

        return 0
    }
}

typealias LibraryCarouselLayout = PerspectiveFilmCarouselLayout

enum LibraryCarouselHaptics {
    static let impactIntensity: CGFloat = 0.92

    @MainActor
    static func triggerSelectionChanged() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred(intensity: impactIntensity)
    }
}

enum LibraryCarouselSelection {
    static func centeredFrame(
        frames: [LibraryCarouselCardFrameInfo],
        viewportMidX: CGFloat
    ) -> LibraryCarouselCardFrameInfo? {
        frames.min { lhs, rhs in
            abs(lhs.midX - viewportMidX) < abs(rhs.midX - viewportMidX)
        }
    }

    static func centeredRollID(frames: [LibraryCarouselCardFrameInfo], viewportMidX: CGFloat) -> String? {
        centeredFrame(frames: frames, viewportMidX: viewportMidX)?.rollID
    }
}

private struct LibraryCarouselCardFramePreferenceKey: PreferenceKey {
    static let defaultValue: [LibraryCarouselCardFrameInfo] = []

    static func reduce(
        value: inout [LibraryCarouselCardFrameInfo],
        nextValue: () -> [LibraryCarouselCardFrameInfo]
    ) {
        value.append(contentsOf: nextValue())
    }
}

struct LibraryScreen: View {
    let model: LibraryFeatureModel
    let photoDisplayImageStore: PhotoDisplayImageStore

    @State private var selectedCarouselItemID: String?
    @State private var centeredSlideIndex = 0
    @State private var carouselDragTranslation: CGFloat = 0

    var body: some View {
        GeometryReader { proxy in
            VStack(alignment: .leading, spacing: 0) {
                content
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .top)
            .clipped()
        }
        .background(LumoTheme.Colors.appBackground.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .task {
            await model.load()
        }
    }

    @ViewBuilder
    private var content: some View {
        switch model.state {
        case .idle, .loading:
            loadingState
        case .loaded(let rolls):
            if rolls.isEmpty {
                emptyState
            } else {
                rollCarousel(rolls: rolls)
            }
        case .failed(let message):
            errorState(message: message)
        }
    }

    private var loadingState: some View {
        VStack(spacing: LumoTheme.Spacing.medium) {
            ProgressView()
            Text("Loading Film Rolls...")
                .font(LumoTheme.Typography.callout)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .padding(.horizontal, LumoTheme.Spacing.medium)
    }

    private var emptyState: some View {
        GeometryReader { outerProxy in
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: LibraryEmptyStateLayout.titleTopInset(forAvailableHeight: outerProxy.size.height))

                emptyCreateSummary
                    .frame(height: LibraryEmptyStateLayout.summaryReservedHeight)

                Color.clear
                    .frame(height: LibraryEmptyStateLayout.summaryToCarouselSpacing(forAvailableHeight: outerProxy.size.height))

                GeometryReader { proxy in
                    let cardWidth = LibraryEmptyStateLayout.cardWidth(forContentWidth: proxy.size.width)
                    let transform = LibraryEmptyStateLayout.centerCardTransform

                    Button(action: model.requestCreate) {
                        EmptyReversalSlideCard()
                            .frame(width: cardWidth, height: cardWidth)
                            .scaleEffect(transform.scale)
                            .shadow(
                                color: Color.black.opacity(0.10 + (0.10 * transform.photoLightAmount)),
                                radius: transform.shadowRadius,
                                x: 0,
                                y: transform.shadowYOffset
                            )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(LibraryEmptyStatePresentation.cardAccessibilityLabel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: LibraryCarouselLayout.carouselHeight)

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyCreateSummary: some View {
        Text(LibraryEmptyStatePresentation.title)
            .font(.system(.largeTitle, design: .serif, weight: .semibold))
            .foregroundStyle(LumoTheme.Colors.textPrimary)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.78)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, LumoTheme.Spacing.xLarge)
    }

    private func errorState(message: String) -> some View {
        VStack(spacing: LumoTheme.Spacing.medium) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 34, weight: .medium))
                .foregroundStyle(LumoTheme.Colors.accent)
            Text("Film Rolls are unavailable")
                .font(LumoTheme.Typography.headline)
                .foregroundStyle(LumoTheme.Colors.textPrimary)
            Text(message)
                .font(LumoTheme.Typography.callout)
                .foregroundStyle(LumoTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            LumoPillButton(title: "Retry", systemImage: "arrow.clockwise", variant: .secondary) {
                Task { await model.reload() }
            }
        }
        .padding(LumoTheme.Spacing.xLarge)
        .frame(maxWidth: .infinity, minHeight: 320)
        .padding(.horizontal, LumoTheme.Spacing.medium)
        .background(LumoTheme.Colors.surfacePrimary, in: RoundedRectangle(cornerRadius: LumoTheme.Radius.panel, style: .continuous))
    }

    private func rollCarousel(rolls: [FilmRoll]) -> some View {
        let displayData = rolls.map(FilmRollDisplayData.init)
        let items = LibraryCarouselItem.items(for: displayData)
        let itemIDs = items.map(\.id)

        return GeometryReader { outerProxy in
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: LibraryCarouselTitleLayout.titleTopInset(forAvailableHeight: outerProxy.size.height))

                selectedRollSummary(items: items)
                    .frame(height: LibraryCarouselTitleLayout.selectedSummaryReservedHeight)

                Color.clear
                    .frame(height: LibraryCarouselTitleLayout.summaryToCarouselSpacing(forAvailableHeight: outerProxy.size.height))

                GeometryReader { proxy in
                    let cardWidth = LibraryCarouselLayout.cardWidth(forContentWidth: proxy.size.width)
                    let itemStep = LibraryCarouselLayout.itemStep(cardWidth: cardWidth)

                    ZStack {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            let normalizedOffset = LibraryCarouselLayout.normalizedOffset(
                                itemIndex: index,
                                centeredIndex: centeredSlideIndex,
                                itemCount: items.count,
                                dragTranslation: carouselDragTranslation,
                                itemStep: itemStep
                            )
                            let transform = LibraryCarouselLayout.coverFlowTransform(normalizedOffset: normalizedOffset)
                            let isCenteredSlide = index == centeredSlideIndex && abs(carouselDragTranslation) < 0.5

                            carouselCard(
                                for: item,
                                isCentered: isCenteredSlide,
                                centerProgress: transform.photoLightAmount
                            )
                            .frame(width: cardWidth, height: cardWidth)
                            .scaleEffect(transform.scale)
                            .rotation3DEffect(
                                .degrees(Double(transform.rotationYDegrees)),
                                axis: (x: 0, y: 1, z: 0),
                                perspective: 0.76
                            )
                            .opacity(transform.opacity)
                            .blur(radius: transform.blurRadius)
                            .shadow(
                                color: Color.black.opacity(0.10 + (0.10 * transform.photoLightAmount)),
                                radius: transform.shadowRadius,
                                x: 0,
                                y: transform.shadowYOffset
                            )
                            .offset(x: (normalizedOffset * itemStep) + transform.xOffset)
                            .zIndex(transform.zIndex)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if index == centeredSlideIndex {
                                    if item.requestsCreate {
                                        model.requestCreate()
                                    } else if let rollID = item.rollID {
                                        model.requestOpenFilmRoll(id: rollID)
                                    }
                                } else {
                                    centerSlide(at: index, in: items)
                                }
                            }
                            .accessibilityLabel(item.accessibilityLabel)
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .highPriorityGesture(carouselDragGesture(itemStep: itemStep, items: items))
                    .onAppear {
                        synchronizeCenteredSlide(with: items)
                    }
                    .onChange(of: itemIDs, initial: false) { _, _ in
                        synchronizeCenteredSlide(with: items)
                    }
                }
                .frame(height: LibraryCarouselLayout.carouselHeight)
                .offset(y: LibraryCarouselTitleLayout.carouselVisualOffsetY)

                Color.clear
                    .frame(height: LibraryCarouselTitleLayout.pageIndicatorTopSpacing)

                carouselPageIndicator(items: items)
                    .offset(y: LibraryCarouselTitleLayout.carouselVisualOffsetY)

                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func carouselCard(
        for item: LibraryCarouselItem,
        isCentered: Bool,
        centerProgress: CGFloat
    ) -> some View {
        switch item.kind {
        case .roll:
            if let data = item.roll {
                let thumbnailPath = data.referencePhoto.thumbnailRelativePath
                let imageAspectRatio = photoDisplayImageStore.aspectRatio(
                    relativePath: thumbnailPath,
                    maxPixelDimension: 700
                )

                SlideMountCard(
                    serialNumber: item.serialNumber,
                    name: data.name,
                    processedPhotoCount: data.processedPhotoCount,
                    createdDateText: data.createdDateText,
                    palette: data.palette,
                    isCentered: isCentered,
                    centerProgress: centerProgress,
                    imageAspectRatio: imageAspectRatio
                ) {
                    PhotoDisplayImageView(
                        store: photoDisplayImageStore,
                        relativePath: thumbnailPath,
                        maxPixelDimension: 700,
                        contentMode: .fill
                    ) {
                        LumoPhotoPlaceholder(style: .thumbnail, title: data.name)
                    }
                }
            }
        case .addRoll:
            EmptyReversalSlideCard(serialNumber: item.serialNumber)
        }
    }

    private func carouselDragGesture(
        itemStep: CGFloat,
        items: [LibraryCarouselItem]
    ) -> some Gesture {
        DragGesture(minimumDistance: LibraryCarouselInteraction.dragMinimumDistance, coordinateSpace: .local)
            .onChanged { value in
                carouselDragTranslation = LibraryCarouselLayout.boundedDragTranslation(
                    value.translation.width,
                    centeredIndex: centeredSlideIndex,
                    itemCount: items.count,
                    itemStep: itemStep
                )
            }
            .onEnded { value in
                guard items.count > 1 else {
                    withAnimation(.snappy(duration: 0.24)) {
                        carouselDragTranslation = 0
                    }
                    return
                }

                let releaseTranslation = LibraryCarouselLayout.boundedDragTranslation(
                    value.translation.width,
                    centeredIndex: centeredSlideIndex,
                    itemCount: items.count,
                    itemStep: itemStep
                )
                let predictedTranslation = LibraryCarouselLayout.boundedDragTranslation(
                    value.predictedEndTranslation.width,
                    centeredIndex: centeredSlideIndex,
                    itemCount: items.count,
                    itemStep: itemStep
                )
                var delta = LibraryCarouselLayout.snapDelta(
                    predictedTranslation: predictedTranslation,
                    itemStep: itemStep
                )

                if delta == 0, abs(releaseTranslation) > itemStep * 0.28 {
                    delta = releaseTranslation < 0 ? 1 : -1
                }

                let boundedDelta = max(-2, min(2, delta))
                let nextIndex = LibraryCarouselLayout.indexByAdding(
                    boundedDelta,
                    to: centeredSlideIndex,
                    count: items.count
                )
                let actualDelta = nextIndex - centeredSlideIndex
                let continuityTranslation = LibraryCarouselLayout.continuityDragTranslation(
                    releaseTranslation: releaseTranslation,
                    indexDelta: actualDelta,
                    itemStep: itemStep
                )
                snapToSlide(at: nextIndex, in: items, continuityTranslation: continuityTranslation)
            }
    }

    private func centerSlide(at index: Int, in items: [LibraryCarouselItem]) {
        guard items.indices.contains(index) else {
            return
        }

        let previousIndex = centeredSlideIndex
        withAnimation(.snappy(duration: 0.34)) {
            centeredSlideIndex = index
            selectedCarouselItemID = items[index].id
        }

        if previousIndex != index {
            LibraryCarouselHaptics.triggerSelectionChanged()
        }
    }

    private func snapToSlide(
        at index: Int,
        in items: [LibraryCarouselItem],
        continuityTranslation: CGFloat
    ) {
        guard items.indices.contains(index) else {
            return
        }

        let previousIndex = centeredSlideIndex
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            centeredSlideIndex = index
            selectedCarouselItemID = items[index].id
            carouselDragTranslation = continuityTranslation
        }

        withAnimation(.snappy(duration: 0.34)) {
            carouselDragTranslation = 0
        }

        if previousIndex != index {
            LibraryCarouselHaptics.triggerSelectionChanged()
        }
    }

    private func synchronizeCenteredSlide(with items: [LibraryCarouselItem]) {
        guard !items.isEmpty else {
            centeredSlideIndex = 0
            selectedCarouselItemID = nil
            return
        }

        if let selectedCarouselItemID,
           let selectedIndex = items.firstIndex(where: { $0.id == selectedCarouselItemID }) {
            centeredSlideIndex = selectedIndex
            return
        }

        centeredSlideIndex = min(centeredSlideIndex, items.count - 1)
        selectedCarouselItemID = items[centeredSlideIndex].id
    }

    private func carouselPageIndicator(items: [LibraryCarouselItem]) -> some View {
        HStack(spacing: 10) {
            ForEach(items) { item in
                Circle()
                    .fill(item.id == selectedCarouselItemID ? LumoTheme.Colors.textPrimary : LumoTheme.Colors.textPrimary.opacity(0.18))
                    .frame(width: item.id == selectedCarouselItemID ? 10 : 7, height: item.id == selectedCarouselItemID ? 10 : 7)
                    .animation(.snappy(duration: 0.18), value: selectedCarouselItemID)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private func selectedRollSummary(items: [LibraryCarouselItem]) -> some View {
        let selected = items.first { $0.id == selectedCarouselItemID } ?? items.first

        return VStack(spacing: LumoTheme.Spacing.small) {
            if let selected {
                Text(selected.summaryTitle)
                    .font(.system(.largeTitle, design: .serif, weight: .semibold))
                    .foregroundStyle(LumoTheme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)

                if let roll = selected.roll {
                    Text("\(roll.processedPhotoCount == 1 ? "1 photo" : "\(roll.processedPhotoCount) photos"), created \(roll.createdDateText)")
                        .font(LumoTheme.Typography.callout)
                        .foregroundStyle(LumoTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)

                    PaletteRow(colors: roll.palette.prefix(5).map { $0 }, size: 12, gap: 6)
                        .accessibilityLabel("Selected roll palette")
                } else if LibraryCarouselAddCardPresentation.reservesRollSummaryRows {
                    Text("0 photos, created May 27")
                        .font(LumoTheme.Typography.callout)
                        .hidden()
                        .accessibilityHidden(true)

                    Color.clear
                        .frame(width: 12, height: 12)
                        .accessibilityHidden(true)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, LumoTheme.Spacing.xLarge)
    }
}

private struct EmptyReversalSlideCard: View {
    var serialNumber = 1

    var body: some View {
        SlideMountCard(
            serialNumber: serialNumber,
            name: "",
            processedPhotoCount: 0,
            createdDateText: "",
            palette: [],
            isCentered: true,
            centerProgress: 1,
            imageAspectRatio: LibraryCarouselLayout.fallbackPhotoAspectRatio
        ) {
            EmptySlideWindow()
        }
        .accessibilityHidden(true)
    }
}

private struct EmptySlideWindow: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    LumoTheme.Colors.surfaceSecondary,
                    LumoTheme.Colors.surfacePrimary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
                .padding(6)

            if LibraryCarouselAddCardPresentation.showsCenteredAddButton {
                ZStack {
                    Circle()
                        .fill(LumoTheme.Colors.textPrimary)
                        .frame(width: 46, height: 46)
                        .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 4)

                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundStyle(LumoTheme.Colors.surfacePrimary)
                }
            }
        }
    }
}

#Preview("Library loaded") {
    LibraryScreen(
        model: LibraryFeatureModel(repository: PreviewFilmRollRepository(filmRolls: PreviewFilmRollRepository.previewRolls)),
        photoDisplayImageStore: .preview
    )
}
