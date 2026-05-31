import SwiftUI

struct LumoPhotoDisplayData: Identifiable {
    let id: String
    let label: String
    let image: Image?
    let thumbnailRelativePath: String?
    let fullSizeRelativePath: String?
    let accessibilityLabel: String

    init(
        id: String,
        label: String,
        image: Image?,
        thumbnailRelativePath: String? = nil,
        fullSizeRelativePath: String? = nil,
        accessibilityLabel: String? = nil
    ) {
        self.id = id
        self.label = label
        self.image = image
        self.thumbnailRelativePath = thumbnailRelativePath
        self.fullSizeRelativePath = fullSizeRelativePath
        self.accessibilityLabel = accessibilityLabel ?? label
    }
}

struct LumoPhotoPlaceholder: View {
    enum Style {
        case thumbnail
        case unavailable
        case addPhoto
    }

    let style: Style
    var title: String?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: LumoTheme.Spacing.xSmall) {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .medium))
                    .symbolRenderingMode(.hierarchical)

                if let title {
                    Text(title)
                        .font(LumoTheme.Typography.label)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
            }
            .foregroundStyle(LumoTheme.Colors.textSecondary)
            .padding(LumoTheme.Spacing.small)
        }
        .accessibilityElement(children: .combine)
    }

    private var systemImage: String {
        switch style {
        case .thumbnail:
            "photo"
        case .unavailable:
            "exclamationmark.triangle"
        case .addPhoto:
            "plus"
        }
    }

    private var gradientColors: [Color] {
        switch style {
        case .thumbnail:
            [LumoTheme.Colors.surfaceSecondary, LumoTheme.Colors.surfacePrimary]
        case .unavailable:
            [LumoTheme.Colors.noirSurface, Color.black.opacity(0.78)]
        case .addPhoto:
            [LumoTheme.Colors.surfacePrimary, LumoTheme.Colors.surfaceSecondary]
        }
    }
}

#Preview("Photo placeholders") {
    HStack {
        LumoPhotoPlaceholder(style: .thumbnail, title: "Reference")
        LumoPhotoPlaceholder(style: .unavailable, title: "Unavailable")
        LumoPhotoPlaceholder(style: .addPhoto, title: "Add photo")
    }
    .frame(height: 120)
    .padding()
    .background(LumoTheme.Colors.appBackground)
}
