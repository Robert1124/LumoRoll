import SwiftUI

struct FilmStripItem: Identifiable {
    enum Kind: Equatable {
        case reference
        case processed
        case addPhoto
    }

    let id: String
    let kind: Kind
    let photo: LumoPhotoDisplayData?
    let accessibilityLabel: String

    static func orderedItems(
        reference: LumoPhotoDisplayData,
        processed: [LumoPhotoDisplayData],
        includesAddPhoto: Bool
    ) -> [FilmStripItem] {
        var items = [
            FilmStripItem(
                id: reference.id,
                kind: .reference,
                photo: reference,
                accessibilityLabel: accessibilityLabel(for: reference)
            )
        ]

        items.append(contentsOf: processed.enumerated().map { index, photo in
            FilmStripItem(
                id: photo.id,
                kind: .processed,
                photo: photo,
                accessibilityLabel: accessibilityLabel(for: photo, fallback: "Processed photo \(index + 1)")
            )
        })

        if includesAddPhoto {
            items.append(FilmStripItem(id: "add-photo", kind: .addPhoto, photo: nil, accessibilityLabel: "Add photo"))
        }

        return items
    }

    private static func accessibilityLabel(for photo: LumoPhotoDisplayData, fallback: String? = nil) -> String {
        let baseLabel = photo.accessibilityLabel.isEmpty ? (fallback ?? photo.label) : photo.accessibilityLabel
        guard photo.image == nil,
              photo.thumbnailRelativePath == nil,
              photo.fullSizeRelativePath == nil else {
            return baseLabel
        }
        return "\(baseLabel), Photo unavailable"
    }
}

struct FilmStripSizing: Equatable {
    let frameWidth: CGFloat
    let frameHeight: CGFloat
    let stripHeight: CGFloat
    let frameSpacing: CGFloat
    let horizontalPadding: CGFloat
    let verticalPadding: CGFloat
    let sprocketCount: Int
    let sprocketHeight: CGFloat
    let sprocketWidth: CGFloat
    let sprocketSlotHeight: CGFloat
    let sprocketSpacing: CGFloat
    let imageMaxPixelDimension: Int
    let prefersFullSizeImages: Bool

    static let standard = FilmStripSizing(
        frameWidth: LumoTheme.Metrics.filmFrameWidth,
        frameHeight: LumoTheme.Metrics.filmFrameHeight,
        stripHeight: LumoTheme.Metrics.filmStripHeight,
        frameSpacing: 8,
        horizontalPadding: 14,
        verticalPadding: 8,
        sprocketCount: 18,
        sprocketHeight: 18,
        sprocketWidth: 7,
        sprocketSlotHeight: 5,
        sprocketSpacing: 10,
        imageMaxPixelDimension: 320,
        prefersFullSizeImages: false
    )

    static let detail = FilmStripSizing(
        frameWidth: 236,
        frameHeight: 312,
        stripHeight: 382,
        frameSpacing: 12,
        horizontalPadding: 18,
        verticalPadding: 12,
        sprocketCount: 18,
        sprocketHeight: 22,
        sprocketWidth: 8,
        sprocketSlotHeight: 6,
        sprocketSpacing: 12,
        imageMaxPixelDimension: 960,
        prefersFullSizeImages: true
    )
}

enum FilmStripSprocketScrollBehavior: Equatable {
    case movesWithHorizontalContent
}

enum FilmStripLayout {
    static let sprocketScrollBehavior: FilmStripSprocketScrollBehavior = .movesWithHorizontalContent
}

enum FilmStripSprocketLayout {
    static func slotCount(forWidth width: CGFloat, sizing: FilmStripSizing) -> Int {
        guard width.isFinite, width > 0 else {
            return max(1, sizing.sprocketCount)
        }

        let slotStep = sizing.sprocketWidth + sizing.sprocketSpacing
        guard slotStep > 0 else {
            return max(1, sizing.sprocketCount)
        }

        let generatedCount = Int(ceil((width + sizing.sprocketSpacing) / slotStep))
        return max(1, sizing.sprocketCount, generatedCount)
    }
}

enum FilmStripFrameLayout {
    static let photoContentMode: ContentMode = .fit

    static func frameSize(
        kind: FilmStripItem.Kind,
        aspectRatio: CGFloat?,
        sizing: FilmStripSizing
    ) -> CGSize {
        guard kind != .addPhoto,
              let aspectRatio,
              aspectRatio.isFinite,
              aspectRatio > 0 else {
            return CGSize(width: sizing.frameWidth, height: sizing.frameHeight)
        }

        return CGSize(width: sizing.frameHeight * aspectRatio, height: sizing.frameHeight)
    }

    static func displayRelativePath(
        for photo: LumoPhotoDisplayData?,
        sizing: FilmStripSizing
    ) -> String? {
        guard let photo else {
            return nil
        }

        if sizing.prefersFullSizeImages {
            return photo.fullSizeRelativePath ?? photo.thumbnailRelativePath
        }

        return photo.thumbnailRelativePath ?? photo.fullSizeRelativePath
    }
}

struct FilmStrip: View {
    let items: [FilmStripItem]
    var selectedID: String?
    var sizing: FilmStripSizing = .standard
    var photoDisplayImageStore: PhotoDisplayImageStore?
    var onSelect: (FilmStripItem) -> Void = { _ in }
    var onAddPhoto: () -> Void = {}

    var body: some View {
        GeometryReader { proxy in
            let innerContentWidth = innerContentWidth(forViewportWidth: proxy.size.width)

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(LumoTheme.Colors.filmStripBackground)
                    .shadow(color: Color.black.opacity(0.22), radius: 20, x: 0, y: 10)

                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(spacing: 0) {
                        sprocketRow(width: innerContentWidth)
                        HStack(spacing: sizing.frameSpacing) {
                            ForEach(items) { item in
                                FilmFrame(
                                    item: item,
                                    isSelected: selectedID == item.id,
                                    sizing: sizing,
                                    photoDisplayImageStore: photoDisplayImageStore,
                                    action: {
                                        switch item.kind {
                                        case .addPhoto:
                                            onAddPhoto()
                                        case .reference, .processed:
                                            onSelect(item)
                                        }
                                    }
                                )
                            }
                        }
                        .frame(width: innerContentWidth, alignment: .leading)
                        .frame(height: sizing.frameHeight)
                        sprocketRow(width: innerContentWidth)
                    }
                    .padding(.horizontal, sizing.horizontalPadding)
                    .frame(width: innerContentWidth + (sizing.horizontalPadding * 2))
                }
                .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                .padding(.vertical, sizing.verticalPadding)
            }
        }
        .frame(height: sizing.stripHeight)
    }

    private func sprocketRow(width: CGFloat) -> some View {
        let slotCount = FilmStripSprocketLayout.slotCount(forWidth: width, sizing: sizing)

        return HStack(spacing: sizing.sprocketSpacing) {
            ForEach(0..<slotCount, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.black.opacity(0.55))
                    .frame(width: sizing.sprocketWidth, height: sizing.sprocketSlotHeight)
            }
        }
        .frame(width: width, alignment: .leading)
        .frame(height: sizing.sprocketHeight)
        .clipped()
    }

    private func innerContentWidth(forViewportWidth viewportWidth: CGFloat) -> CGFloat {
        let frameWidths = items.map { item in
            FilmStripFrameLayout.frameSize(
                kind: item.kind,
                aspectRatio: loadedAspectRatio(for: item),
                sizing: sizing
            ).width
        }
        let totalFrameWidth = frameWidths.reduce(0, +)
        let totalSpacing = CGFloat(max(items.count - 1, 0)) * sizing.frameSpacing
        let frameContentWidth = totalFrameWidth + totalSpacing
        let viewportInnerWidth = max(0, viewportWidth - (sizing.horizontalPadding * 2))
        return max(viewportInnerWidth, frameContentWidth)
    }

    private func loadedAspectRatio(for item: FilmStripItem) -> CGFloat? {
        guard let photoDisplayImageStore,
              let displayRelativePath = FilmStripFrameLayout.displayRelativePath(for: item.photo, sizing: sizing) else {
            return nil
        }

        return photoDisplayImageStore.aspectRatio(
            relativePath: displayRelativePath,
            maxPixelDimension: sizing.imageMaxPixelDimension
        )
    }
}

struct FilmFrame: View {
    let item: FilmStripItem
    var isSelected = false
    var sizing: FilmStripSizing = .standard
    var photoDisplayImageStore: PhotoDisplayImageStore?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                frameContent
                    .frame(width: frameSize.width, height: frameSize.height)
                    .clipShape(RoundedRectangle(cornerRadius: LumoTheme.Radius.filmFrame, style: .continuous))

                RoundedRectangle(cornerRadius: LumoTheme.Radius.filmFrame, style: .continuous)
                    .stroke(isSelected ? LumoTheme.Colors.accent : .white.opacity(0.08), lineWidth: isSelected ? 2 : 1)

                if let badgeText {
                    Text(badgeText)
                        .font(LumoTheme.Typography.technicalLabel)
                        .tracking(0.7)
                        .foregroundStyle(badgeForeground)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(badgeBackground, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
                        .padding(7)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(item.accessibilityLabel)
    }

    @ViewBuilder
    private var frameContent: some View {
        switch item.kind {
        case .reference, .processed:
            if let image = item.photo?.image {
                ZStack {
                    LumoTheme.Colors.noirSurface
                    image
                        .resizable()
                        .aspectRatio(contentMode: FilmStripFrameLayout.photoContentMode)
                }
            } else if let photoDisplayImageStore,
                      let relativePath = displayRelativePath {
                ZStack {
                    LumoTheme.Colors.noirSurface
                    PhotoDisplayImageView(
                        store: photoDisplayImageStore,
                        relativePath: relativePath,
                        maxPixelDimension: sizing.imageMaxPixelDimension,
                        contentMode: FilmStripFrameLayout.photoContentMode
                    ) {
                        LumoPhotoPlaceholder(style: .unavailable, title: "Photo unavailable")
                    }
                }
            } else {
                LumoPhotoPlaceholder(style: .unavailable, title: "Photo unavailable")
            }
        case .addPhoto:
            LumoPhotoPlaceholder(style: .addPhoto, title: "Add photo")
        }
    }

    private var badgeText: String? {
        switch item.kind {
        case .reference:
            "Sample"
        case .processed:
            item.photo?.label
        case .addPhoto:
            nil
        }
    }

    private var badgeForeground: Color {
        item.kind == .reference ? LumoTheme.Colors.textPrimary : .white
    }

    private var badgeBackground: Color {
        item.kind == .reference ? LumoTheme.Colors.surfacePrimary.opacity(0.92) : .black.opacity(0.42)
    }

    private var frameSize: CGSize {
        FilmStripFrameLayout.frameSize(
            kind: item.kind,
            aspectRatio: loadedAspectRatio,
            sizing: sizing
        )
    }

    private var loadedAspectRatio: CGFloat? {
        guard let photoDisplayImageStore,
              let displayRelativePath else {
            return nil
        }

        return photoDisplayImageStore.aspectRatio(
            relativePath: displayRelativePath,
            maxPixelDimension: sizing.imageMaxPixelDimension
        )
    }

    private var displayRelativePath: String? {
        FilmStripFrameLayout.displayRelativePath(for: item.photo, sizing: sizing)
    }
}

#Preview("Film Strip") {
    FilmStrip(items: LumoPreviewFixtures.filmStripItems, selectedID: "reference")
        .padding()
        .background(LumoTheme.Colors.appBackground)
}
