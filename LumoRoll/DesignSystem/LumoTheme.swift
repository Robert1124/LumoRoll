import SwiftUI
import UIKit

enum LumoTheme {
    enum Colors {
        static let appBackground = dynamic(light: 0xF4EFE6, dark: 0x1A1612)
        static let surfacePrimary = dynamic(light: 0xFBF7EF, dark: 0x221D17)
        static let surfaceSecondary = dynamic(light: 0xECE3D2, dark: 0x2C261F)
        static let textPrimary = dynamic(light: 0x1F1A14, dark: 0xFBF7EF)
        static let textSecondary = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 1, alpha: 0.60)
                    : UIColor(hex: 0x6E665B)
            }
        )
        static let textTertiary = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 1, alpha: 0.42)
                    : UIColor(hex: 0x918879)
            }
        )
        static let hairline = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 1, alpha: 0.10)
                    : UIColor(hex: 0x1F1A14, alpha: 0.08)
            }
        )
        static let hairlineStrong = Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(white: 1, alpha: 0.16)
                    : UIColor(hex: 0x1F1A14, alpha: 0.14)
            }
        )
        static let accent = Color(uiColor: UIColor(hex: 0xE89B7A))
        static let noirBackground = Color(uiColor: UIColor(hex: 0x1A1612))
        static let noirSurface = Color(uiColor: UIColor(hex: 0x221D17))
        static let filmStripBackground = Color(uiColor: UIColor(hex: 0x2A2520))
        static let inkOnAccent = Color(uiColor: UIColor(hex: 0x2A1810))

        private static func dynamic(light: UInt32, dark: UInt32) -> Color {
            Color(uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
            })
        }
    }

    enum Spacing {
        static let xxSmall: CGFloat = 4
        static let xSmall: CGFloat = 8
        static let small: CGFloat = 12
        static let medium: CGFloat = 16
        static let large: CGFloat = 20
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
    }

    enum Radius {
        static let small: CGFloat = 10
        static let thumbnail: CGFloat = 12
        static let card: CGFloat = 20
        static let panel: CGFloat = 22
        static let preview: CGFloat = 24
        static let filmFrame: CGFloat = 4
    }

    enum Metrics {
        static let minimumHitTarget: CGFloat = 44
        static let filmFrameWidth: CGFloat = 148
        static let filmFrameHeight: CGFloat = 188
        static let filmStripHeight: CGFloat = 228
        static let cardImageAspectRatio: CGFloat = 0.82
    }

    enum Typography {
        static let rollTitle = Font.system(.title3, design: .default, weight: .semibold)
        static let screenTitle = Font.system(.largeTitle, design: .default, weight: .semibold)
        static let headline = Font.system(.headline, design: .default, weight: .semibold)
        static let body = Font.system(.body, design: .default)
        static let callout = Font.system(.callout, design: .default)
        static let label = Font.system(.caption, design: .default, weight: .medium)
        static let technicalLabel = Font.system(.caption2, design: .monospaced, weight: .medium)
    }

    static func paletteColor(for paletteColor: FilmRollPaletteColor) -> Color {
        let red = Double(clampedComponent(paletteColor.red))
        let green = Double(clampedComponent(paletteColor.green))
        let blue = Double(clampedComponent(paletteColor.blue))
        return Color(red: red, green: green, blue: blue)
    }

    static func paletteHex(for paletteColor: FilmRollPaletteColor) -> String {
        let red = Int((clampedComponent(paletteColor.red) * 255).rounded())
        let green = Int((clampedComponent(paletteColor.green) * 255).rounded())
        let blue = Int((clampedComponent(paletteColor.blue) * 255).rounded())
        return String(format: "#%02X%02X%02X", red, green, blue)
    }

    private static func clampedComponent(_ value: Float) -> Float {
        min(max(value, 0), 1)
    }
}

extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

enum LumoIntensity {
    static func clamped(_ value: Double) -> Double {
        min(max(value, 0), 100)
    }

    static func accessibilityValue(for value: Double) -> String {
        "\(Int(clamped(value).rounded())) percent Film Roll"
    }

    static let accessibilityHint = "Adjusts the blend between the original photo and the Film Roll result."
}

enum LumoSplitPosition {
    static let minimumFraction: CGFloat = 0.08
    static let maximumFraction: CGFloat = 0.92
    static let defaultFraction: CGFloat = 0.5
    static let accessibilityHint = "Swipe up or down to move the comparison line."

    static func clampedFraction(_ fraction: CGFloat) -> CGFloat {
        min(max(fraction, minimumFraction), maximumFraction)
    }

    static func fraction(forLocationX locationX: CGFloat, width: CGFloat) -> CGFloat {
        guard width > 0 else {
            return defaultFraction
        }
        return clampedFraction(locationX / width)
    }

    static func accessibilityValue(for fraction: CGFloat) -> String {
        "\(Int((clampedFraction(fraction) * 100).rounded())) percent before"
    }

    static func adjustedFraction(_ fraction: CGFloat, direction: AccessibilityAdjustmentDirection) -> CGFloat {
        switch direction {
        case .increment:
            clampedFraction(fraction + 0.05)
        case .decrement:
            clampedFraction(fraction - 0.05)
        @unknown default:
            clampedFraction(fraction)
        }
    }
}

enum LumoPreviewAspectRatio {
    static let fallback: CGFloat = 3.0 / 4.0

    static func sanitized(_ aspectRatio: CGFloat?) -> CGFloat {
        guard let aspectRatio,
              aspectRatio.isFinite,
              aspectRatio > 0 else {
            return fallback
        }

        return aspectRatio
    }
}
