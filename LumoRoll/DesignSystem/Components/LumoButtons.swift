import SwiftUI

enum LumoPillButtonVariant {
    case primary
    case secondary
    case ghost
    case accent
    case destructive
}

struct LumoPillButtonStyle: ButtonStyle {
    let variant: LumoPillButtonVariant
    var isLoading = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LumoTheme.Typography.callout.weight(.semibold))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .padding(.horizontal, LumoTheme.Spacing.large)
            .frame(minHeight: LumoTheme.Metrics.minimumHitTarget)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(border, lineWidth: 1)
            }
            .opacity(opacity)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.snappy(duration: 0.14), value: configuration.isPressed)
    }

    private var opacity: Double {
        guard isEnabled else {
            return 0.42
        }

        return isLoading ? 0.72 : 1
    }

    private var foreground: Color {
        switch variant {
        case .primary:
            LumoTheme.Colors.surfacePrimary
        case .secondary, .ghost:
            LumoTheme.Colors.textPrimary
        case .accent:
            LumoTheme.Colors.inkOnAccent
        case .destructive:
            .red
        }
    }

    private var background: Color {
        switch variant {
        case .primary:
            LumoTheme.Colors.textPrimary
        case .secondary:
            LumoTheme.Colors.surfacePrimary
        case .ghost, .destructive:
            .clear
        case .accent:
            LumoTheme.Colors.accent
        }
    }

    private var border: Color {
        switch variant {
        case .primary, .accent:
            .clear
        case .secondary, .ghost:
            LumoTheme.Colors.hairlineStrong
        case .destructive:
            .red.opacity(0.30)
        }
    }
}

struct LumoPillButton: View {
    let title: String
    var systemImage: String?
    var variant: LumoPillButtonVariant = .primary
    var isLoading = false
    var isFullWidth = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LumoTheme.Spacing.xSmall) {
                if isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 15, weight: .semibold))
                }

                Text(title)
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
        }
        .buttonStyle(LumoPillButtonStyle(variant: variant, isLoading: isLoading))
        .disabled(isLoading)
    }
}

struct LumoPillPickerLabel: View {
    let title: String
    var systemImage: String?
    var variant: LumoPillButtonVariant = .primary
    var isFullWidth = false

    var body: some View {
        HStack(spacing: LumoTheme.Spacing.xSmall) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
            }
            Text(title)
        }
        .font(LumoTheme.Typography.callout.weight(.semibold))
        .lineLimit(1)
        .minimumScaleFactor(0.82)
        .padding(.horizontal, LumoTheme.Spacing.large)
        .frame(maxWidth: isFullWidth ? .infinity : nil)
        .frame(minHeight: LumoTheme.Metrics.minimumHitTarget)
        .foregroundStyle(foreground)
        .background(background)
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .stroke(border, lineWidth: 1)
        }
    }

    private var foreground: Color {
        switch variant {
        case .primary:
            LumoTheme.Colors.surfacePrimary
        case .secondary, .ghost:
            LumoTheme.Colors.textPrimary
        case .accent:
            LumoTheme.Colors.inkOnAccent
        case .destructive:
            .red
        }
    }

    private var background: Color {
        switch variant {
        case .primary:
            LumoTheme.Colors.textPrimary
        case .secondary:
            LumoTheme.Colors.surfacePrimary
        case .ghost, .destructive:
            .clear
        case .accent:
            LumoTheme.Colors.accent
        }
    }

    private var border: Color {
        switch variant {
        case .primary, .accent:
            .clear
        case .secondary, .ghost:
            LumoTheme.Colors.hairlineStrong
        case .destructive:
            .red.opacity(0.30)
        }
    }
}

struct LumoIconButton: View {
    let systemImage: String
    let accessibilityLabel: String
    var variant: LumoPillButtonVariant = .secondary
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: LumoTheme.Metrics.minimumHitTarget, height: LumoTheme.Metrics.minimumHitTarget)
                .contentShape(Circle())
        }
        .buttonStyle(LumoIconButtonStyle(variant: variant))
        .accessibilityLabel(accessibilityLabel)
    }
}

private struct LumoIconButtonStyle: ButtonStyle {
    let variant: LumoPillButtonVariant

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(border, lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.snappy(duration: 0.14), value: configuration.isPressed)
    }

    private var foreground: Color {
        switch variant {
        case .primary:
            LumoTheme.Colors.surfacePrimary
        case .accent:
            LumoTheme.Colors.inkOnAccent
        case .destructive:
            .red
        case .secondary, .ghost:
            LumoTheme.Colors.textPrimary
        }
    }

    private var background: Color {
        switch variant {
        case .primary:
            LumoTheme.Colors.textPrimary
        case .accent:
            LumoTheme.Colors.accent
        case .secondary:
            LumoTheme.Colors.surfacePrimary
        case .ghost, .destructive:
            LumoTheme.Colors.surfaceSecondary.opacity(0.54)
        }
    }

    private var border: Color {
        switch variant {
        case .primary, .accent:
            .clear
        default:
            LumoTheme.Colors.hairline
        }
    }
}

struct FullscreenActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            FullscreenActionLabel(title: title, systemImage: systemImage)
        }
        .buttonStyle(.plain)
    }
}

struct FullscreenActionLabel: View {
    let title: String
    let systemImage: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .frame(width: LumoTheme.Metrics.minimumHitTarget, height: LumoTheme.Metrics.minimumHitTarget)
                .background(.white.opacity(0.12), in: Circle())
                .overlay {
                    Circle().stroke(.white.opacity(0.14), lineWidth: 1)
                }
            Text(title)
                .font(LumoTheme.Typography.technicalLabel)
                .textCase(.uppercase)
        }
        .foregroundStyle(.white)
        .frame(minWidth: 64)
    }
}

#Preview("Buttons") {
    VStack(spacing: 16) {
        LumoPillButton(title: "Import & apply", systemImage: "photo", action: {})
        LumoPillButton(title: "Export .cube", systemImage: "cube", variant: .secondary, action: {})
        HStack {
            LumoIconButton(systemImage: "chevron.left", accessibilityLabel: "Back", action: {})
            LumoIconButton(systemImage: "plus", accessibilityLabel: "Add", variant: .accent, action: {})
        }
        FullscreenActionButton(title: "Save", systemImage: "arrow.down.to.line", action: {})
            .padding()
            .background(.black)
    }
    .padding()
    .background(LumoTheme.Colors.appBackground)
}
