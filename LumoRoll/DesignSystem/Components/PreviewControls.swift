import SwiftUI

enum LumoPreviewMode: String, CaseIterable, Identifiable {
    case before = "Before"
    case split = "Split"
    case after = "After"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .before:
            "photo"
        case .split:
            "arrow.left.arrow.right"
        case .after:
            "sparkles"
        }
    }
}

struct PreviewModeSegmentedControl: View {
    @Binding var selection: LumoPreviewMode
    var disabledModes: Set<LumoPreviewMode> = []

    var body: some View {
        HStack(spacing: 4) {
            ForEach(LumoPreviewMode.allCases) { mode in
                Button {
                    selection = mode
                } label: {
                    Label(mode.rawValue, systemImage: mode.systemImage)
                        .labelStyle(.titleAndIcon)
                        .font(LumoTheme.Typography.label)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .foregroundStyle(selection == mode ? LumoTheme.Colors.textPrimary : LumoTheme.Colors.textSecondary)
                        .background(selection == mode ? LumoTheme.Colors.surfacePrimary : .clear)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .disabled(disabledModes.contains(mode))
                .opacity(disabledModes.contains(mode) ? 0.42 : 1)
            }
        }
        .padding(4)
        .background(LumoTheme.Colors.surfaceSecondary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityElement(children: .contain)
    }
}

struct LumoIntensitySlider: View {
    @Binding var intensity: Double
    var isEnabled = true

    var body: some View {
        VStack(alignment: .leading, spacing: LumoTheme.Spacing.xSmall) {
            HStack {
                Label("Intensity", systemImage: "slider.horizontal.3")
                    .font(LumoTheme.Typography.label)
                    .foregroundStyle(LumoTheme.Colors.textSecondary)
                Spacer()
                Text("\(Int(LumoIntensity.clamped(intensity).rounded()))%")
                    .font(LumoTheme.Typography.technicalLabel)
                    .foregroundStyle(LumoTheme.Colors.textPrimary)
                    .monospacedDigit()
            }

            Slider(
                value: Binding(
                    get: { LumoIntensity.clamped(intensity) },
                    set: { intensity = LumoIntensity.clamped($0) }
                ),
                in: 0...100,
                step: 1
            )
            .tint(LumoTheme.Colors.accent)
            .disabled(!isEnabled)
            .accessibilityLabel("Film Roll intensity")
            .accessibilityValue(LumoIntensity.accessibilityValue(for: intensity))
            .accessibilityHint(LumoIntensity.accessibilityHint)
        }
        .padding(LumoTheme.Spacing.medium)
        .background(LumoTheme.Colors.surfacePrimary, in: RoundedRectangle(cornerRadius: LumoTheme.Radius.card, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LumoTheme.Radius.card, style: .continuous)
                .stroke(LumoTheme.Colors.hairline, lineWidth: 1)
        }
    }
}

struct SplitPreview<Before: View, After: View>: View {
    let mode: LumoPreviewMode
    let aspectRatio: CGFloat
    @Binding var splitFraction: CGFloat
    let before: Before
    let after: After

    init(
        mode: LumoPreviewMode,
        aspectRatio: CGFloat = LumoPreviewAspectRatio.fallback,
        splitFraction: Binding<CGFloat>,
        @ViewBuilder before: () -> Before,
        @ViewBuilder after: () -> After
    ) {
        self.mode = mode
        self.aspectRatio = LumoPreviewAspectRatio.sanitized(aspectRatio)
        self._splitFraction = splitFraction
        self.before = before()
        self.after = after()
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                baseLayer

                if mode == .split {
                    before
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .clipShape(SplitClip(fraction: boundedSplitFraction))
                    handle
                        .position(x: proxy.size.width * boundedSplitFraction, y: proxy.size.height / 2)
                }
            }
            .contentShape(Rectangle())
            .gesture(splitGesture(width: proxy.size.width))
        }
        .aspectRatio(aspectRatio, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: LumoTheme.Radius.preview, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: LumoTheme.Radius.preview, style: .continuous)
                .stroke(LumoTheme.Colors.hairlineStrong, lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.16), radius: 24, x: 0, y: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(accessibilityValue)
        .accessibilityHint(accessibilityHint)
        .accessibilityAdjustableAction { direction in
            guard mode == .split else {
                return
            }
            splitFraction = LumoSplitPosition.adjustedFraction(splitFraction, direction: direction)
        }
    }

    @ViewBuilder
    private var baseLayer: some View {
        switch mode {
        case .before:
            before
        case .split, .after:
            after
        }
    }

    private var boundedSplitFraction: CGFloat {
        LumoSplitPosition.clampedFraction(splitFraction)
    }

    private var handle: some View {
        Capsule()
            .fill(.white)
            .frame(width: 3, height: 58)
            .shadow(color: .black.opacity(0.28), radius: 6, x: 0, y: 2)
            .overlay {
                Circle()
                    .fill(.white)
                    .frame(width: 26, height: 26)
                    .overlay {
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(LumoTheme.Colors.inkOnAccent)
                    }
            }
    }

    private func splitGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard mode == .split else {
                    return
                }
                splitFraction = LumoSplitPosition.fraction(forLocationX: value.location.x, width: width)
            }
    }

    private var accessibilityLabel: String {
        switch mode {
        case .before:
            "Before preview"
        case .split:
            "Split comparison position"
        case .after:
            "After preview"
        }
    }

    private var accessibilityValue: String {
        switch mode {
        case .before:
            "Original photo"
        case .split:
            LumoSplitPosition.accessibilityValue(for: splitFraction)
        case .after:
            "Film Roll result"
        }
    }

    private var accessibilityHint: String {
        mode == .split ? LumoSplitPosition.accessibilityHint : ""
    }
}

private struct SplitClip: Shape {
    let fraction: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(CGRect(x: rect.minX, y: rect.minY, width: rect.width * fraction, height: rect.height))
    }
}

#Preview("Preview controls") {
    @Previewable @State var mode: LumoPreviewMode = .split
    @Previewable @State var intensity = 72.0

    VStack(spacing: 16) {
        PreviewModeSegmentedControl(selection: $mode)
        SplitPreview(mode: mode, splitFraction: .constant(0.5)) {
            LumoPreviewFixtures.referenceImage.resizable().scaledToFill()
        } after: {
            LumoPreviewFixtures.processedImage.resizable().scaledToFill()
        }
        LumoIntensitySlider(intensity: $intensity)
    }
    .padding()
    .background(LumoTheme.Colors.appBackground)
}
