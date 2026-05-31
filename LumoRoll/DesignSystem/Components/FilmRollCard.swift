import SwiftUI

struct FilmRollCard<Thumbnail: View>: View {
    let name: String
    let processedPhotoCount: Int
    let createdDateText: String
    let palette: [FilmRollPaletteColor]
    let thumbnail: Thumbnail

    init(
        name: String,
        processedPhotoCount: Int,
        createdDateText: String,
        palette: [FilmRollPaletteColor],
        @ViewBuilder thumbnail: () -> Thumbnail
    ) {
        self.name = name
        self.processedPhotoCount = processedPhotoCount
        self.createdDateText = createdDateText
        self.palette = palette
        self.thumbnail = thumbnail()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LumoTheme.Spacing.small) {
            thumbnail
                .frame(maxWidth: .infinity)
                .aspectRatio(LumoTheme.Metrics.cardImageAspectRatio, contentMode: .fill)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: LumoTheme.Radius.thumbnail, style: .continuous))
                .overlay(alignment: .topLeading) {
                    Text("33x33x33")
                        .font(LumoTheme.Typography.technicalLabel)
                        .tracking(0.8)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .foregroundStyle(.white)
                        .background(.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .padding(8)
                }

            VStack(alignment: .leading, spacing: 7) {
                Text(name)
                    .font(LumoTheme.Typography.rollTitle)
                    .foregroundStyle(LumoTheme.Colors.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)

                HStack(spacing: LumoTheme.Spacing.xSmall) {
                    Text(processedPhotoCountText)
                    Text("•")
                    Text(createdDateText)
                }
                .font(LumoTheme.Typography.label)
                .foregroundStyle(LumoTheme.Colors.textSecondary)

                PaletteRow(colors: palette, size: 12, gap: 5)
            }
        }
        .padding(12)
        .background(LumoTheme.Colors.surfacePrimary)
        .clipShape(RoundedRectangle(cornerRadius: LumoTheme.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LumoTheme.Radius.card, style: .continuous)
                .stroke(LumoTheme.Colors.hairline, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name), \(processedPhotoCountText), created \(createdDateText)")
    }

    private var processedPhotoCountText: String {
        processedPhotoCount == 1 ? "1 photo" : "\(processedPhotoCount) photos"
    }
}

#Preview("Film Roll Card") {
    HStack(alignment: .top) {
        FilmRollCard(
            name: "Portra Morning",
            processedPhotoCount: 6,
            createdDateText: "May 23",
            palette: LumoPreviewFixtures.palette
        ) {
            LumoPreviewFixtures.referenceImage
                .resizable()
                .scaledToFill()
        }

        FilmRollCard(
            name: "Missing Thumbnail",
            processedPhotoCount: 0,
            createdDateText: "Today",
            palette: []
        ) {
            LumoPhotoPlaceholder(style: .thumbnail, title: "Missing Thumbnail")
        }
    }
    .padding()
    .background(LumoTheme.Colors.appBackground)
}
