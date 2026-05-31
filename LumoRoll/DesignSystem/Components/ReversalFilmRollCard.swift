import SwiftUI
import UIKit

struct SlideMountPhotoWindowLighting: Equatable {
    let imageSaturation: CGFloat
    let imageContrast: CGFloat
    let imageBrightness: CGFloat
    let windowLightOpacity: CGFloat
    let dimOverlayOpacity: CGFloat
    let glowOpacity: CGFloat
}

enum SlideMountPhotoWindowLightingStyle {
    static func values(centerProgress: CGFloat) -> SlideMountPhotoWindowLighting {
        let progress = min(1, max(0, centerProgress))
        let litWindowProgress = CGFloat(pow(Double(progress), 1.8))

        return SlideMountPhotoWindowLighting(
            imageSaturation: 1,
            imageContrast: 1,
            imageBrightness: 0,
            windowLightOpacity: 0.04 + (0.22 * litWindowProgress),
            dimOverlayOpacity: 0.84 * (1 - litWindowProgress),
            glowOpacity: 0.56 * litWindowProgress
        )
    }
}

struct SlideMountCard<Thumbnail: View>: View {
    let serialNumber: Int
    let name: String
    let processedPhotoCount: Int
    let createdDateText: String
    let palette: [FilmRollPaletteColor]
    let isCentered: Bool
    let centerProgress: CGFloat
    let imageAspectRatio: CGFloat?
    let thumbnail: Thumbnail

    init(
        serialNumber: Int,
        name: String,
        processedPhotoCount: Int,
        createdDateText: String,
        palette: [FilmRollPaletteColor],
        isCentered: Bool,
        centerProgress: CGFloat,
        imageAspectRatio: CGFloat?,
        @ViewBuilder thumbnail: () -> Thumbnail
    ) {
        self.serialNumber = serialNumber
        self.name = name
        self.processedPhotoCount = processedPhotoCount
        self.createdDateText = createdDateText
        self.palette = palette
        self.isCentered = isCentered
        self.centerProgress = min(1, max(0, centerProgress))
        self.imageAspectRatio = imageAspectRatio
        self.thumbnail = thumbnail()
    }

    var body: some View {
        GeometryReader { proxy in
            let cardSize = min(proxy.size.width, proxy.size.height)
            let photoWindowSize = LibraryCarouselLayout.photoWindowSize(
                cardSize: cardSize,
                imageAspectRatio: imageAspectRatio
            )
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(slideMountBackground)
                    .overlay {
                        SlideMountGrain()
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(borderColor, lineWidth: isCentered ? 1.25 : 1)
                    }

                VStack(spacing: 0) {
                    header
                        .padding(.horizontal, cardSize * 0.10)
                        .padding(.top, cardSize * 0.095)

                    Spacer(minLength: cardSize * 0.07)

                    photoWindow
                        .frame(width: photoWindowSize.width, height: photoWindowSize.height)

                    Spacer(minLength: cardSize * 0.08)

                    footer
                        .padding(.horizontal, cardSize * 0.10)
                        .padding(.bottom, cardSize * 0.095)
                }
            }
        }
        .aspectRatio(LibraryCarouselLayout.slideCardAspectRatio, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var header: some View {
        VStack(spacing: 3) {
            HStack(alignment: .center, spacing: 10) {
                Text(String(format: "%03d", serialNumber))
                    .font(LumoTheme.Typography.technicalLabel)
                    .foregroundStyle(LumoTheme.Colors.textSecondary)
                    .monospacedDigit()

                Spacer(minLength: 8)

                Text(displayName)
                    .font(.system(.caption, design: .serif, weight: .semibold))
                    .tracking(1.1)
                    .foregroundStyle(slideRed)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)

                Spacer(minLength: 8)

                Circle()
                    .fill(slideRed)
                    .frame(width: 9, height: 9)
            }

            Text(LibrarySlideMountCopy.categoryLine)
                .font(LumoTheme.Typography.technicalLabel)
                .tracking(1.6)
                .foregroundStyle(slideRed.opacity(0.82))
                .lineLimit(1)
        }
    }

    private var photoWindow: some View {
        let lighting = SlideMountPhotoWindowLightingStyle.values(centerProgress: centerProgress)

        return thumbnail
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .saturation(lighting.imageSaturation)
            .contrast(lighting.imageContrast)
            .brightness(lighting.imageBrightness)
            .overlay {
                windowLight
                    .opacity(lighting.windowLightOpacity)

                Color.black.opacity(lighting.dimOverlayOpacity)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.black.opacity(0.46), lineWidth: 2)
            }
            .shadow(color: selectedWindowGlow.opacity(lighting.glowOpacity), radius: 18 * centerProgress, x: 0, y: 2 * centerProgress)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.84))
                    .padding(-4)
            )
    }

    private var windowLight: some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color.white.opacity(0.42),
                    Color.white.opacity(0.18),
                    Color.clear
                ],
                center: .center,
                startRadius: 8,
                endRadius: 160
            )
            .blendMode(.screen)

            LinearGradient(
                colors: [
                    Color.white.opacity(0.24),
                    Color.clear,
                    Color.black.opacity(0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blendMode(.screen)
        }
    }

    private var footer: some View {
        HStack(alignment: .bottom) {
            Text(LibrarySlideMountCopy.lowerLeftLabel)
                .font(LumoTheme.Typography.technicalLabel)
                .tracking(1.2)
                .foregroundStyle(slideRed)

            Spacer()

            VStack(alignment: .trailing, spacing: 6) {
                PaletteRow(colors: palette.prefix(4).map { $0 }, size: 8, gap: 4)
                Text(LibrarySlideMountCopy.lowerRightLabel)
                    .font(LumoTheme.Typography.technicalLabel)
                    .tracking(0.8)
                    .foregroundStyle(slideRed)
            }
        }
    }

    private var slideMountBackground: LinearGradient {
        LinearGradient(
            colors: [
                LumoTheme.Colors.surfacePrimary,
                Color(uiColor: UIColor(hex: 0xEFE3CB)),
                LumoTheme.Colors.surfacePrimary
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var displayName: String {
        name.uppercased()
    }

    private var processedPhotoCountText: String {
        processedPhotoCount == 1 ? "1 photo" : "\(processedPhotoCount) photos"
    }

    private var accessibilityLabel: String {
        let selectionPrefix = isCentered ? "Selected Film Roll, " : "Film Roll, "
        return "\(selectionPrefix)\(name), \(processedPhotoCountText), created \(createdDateText)"
    }

    private var borderColor: Color {
        isCentered ? Color.black.opacity(0.18) : LumoTheme.Colors.hairlineStrong
    }

    private var selectedWindowGlow: Color {
        Color(uiColor: UIColor(hex: 0xF0B65A))
    }

    private var slideRed: Color {
        Color(uiColor: UIColor(hex: 0xA33A2E))
    }
}

typealias ReversalFilmRollCard<Thumbnail: View> = SlideMountCard<Thumbnail>

private struct SlideMountGrain: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<54 {
                let x = size.width * pseudoRandom(index, multiplier: 37, offset: 11)
                let y = size.height * pseudoRandom(index, multiplier: 53, offset: 19)
                let radius = CGFloat(0.45 + pseudoRandom(index, multiplier: 17, offset: 7) * 0.8)
                let rect = CGRect(x: x, y: y, width: radius, height: radius)
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(Color.black.opacity(0.045))
                )
            }
        }
        .allowsHitTesting(false)
    }

    private func pseudoRandom(_ value: Int, multiplier: Int, offset: Int) -> CGFloat {
        CGFloat(((value * multiplier) + offset) % 97) / 97.0
    }
}

#Preview("Reversal Film Roll Card") {
    SlideMountCard(
        serialNumber: 1,
        name: "Warm Haze",
        processedPhotoCount: 24,
        createdDateText: "May 24",
        palette: LumoPreviewFixtures.palette,
        isCentered: true,
        centerProgress: 1,
        imageAspectRatio: 1.5
    ) {
        LumoPreviewFixtures.referenceImage
            .resizable()
            .scaledToFill()
    }
    .frame(width: 300, height: 300)
    .padding(40)
    .background(LumoTheme.Colors.appBackground)
}
