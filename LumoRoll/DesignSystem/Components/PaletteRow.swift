import SwiftUI

struct PaletteRow: View {
    let colors: [FilmRollPaletteColor]
    var size: CGFloat = 14
    var gap: CGFloat = 6

    var body: some View {
        HStack(spacing: gap) {
            ForEach(Array(colors.prefix(5))) { color in
                Circle()
                    .fill(LumoTheme.paletteColor(for: color))
                    .frame(width: size, height: size)
                    .overlay {
                        Circle()
                            .stroke(Color.black.opacity(0.08), lineWidth: 0.5)
                    }
                    .shadow(color: Color.white.opacity(0.25), radius: 0, x: 0, y: 1)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Roll palette")
    }
}

#Preview("Palette row") {
    PaletteRow(colors: LumoPreviewFixtures.palette)
        .padding()
        .background(LumoTheme.Colors.appBackground)
}
