import CoreGraphics
import CoreImage
import Foundation
import Metal

struct CoreImageRenderer {
    enum RenderSize: Equatable {
        case fullResolution
        case preview(maxPixelDimension: Int)
        case thumbnail(maxPixelDimension: Int)
    }

    private static let sharedContext = CoreImageRenderer.makeContext()
    private static let srgbColorSpace = CGColorSpace(name: CGColorSpace.sRGB)!

    private let context: CIContext

    init(context: CIContext = CoreImageRenderer.sharedContext) {
        self.context = context
    }

    static func colorCubeData(from lut: LUT3D) -> Data {
        var rgbaValues: [Float] = []
        rgbaValues.reserveCapacity(lut.sampleCount * 4)

        for valueIndex in stride(from: 0, to: lut.values.count, by: 3) {
            rgbaValues.append(lut.values[valueIndex])
            rgbaValues.append(lut.values[valueIndex + 1])
            rgbaValues.append(lut.values[valueIndex + 2])
            rgbaValues.append(1)
        }

        return rgbaValues.withUnsafeBytes { Data($0) }
    }

    func render(
        _ image: CIImage,
        applying lut: LUT3D,
        intensity: Double,
        size: RenderSize,
        adaptiveAdjustment: AdaptiveRenderAdjustment? = nil
    ) throws -> CGImage {
        let preparedImage = image.preparedForRendering(size: size)
        let renderExtent = preparedImage.extent.integral
        let intensityScale = adaptiveAdjustment?.effectiveIntensityScale ?? 1
        let clampedIntensity = (intensity.clampedToLumoPercentage / 100) * intensityScale

        let outputImage: CIImage
        if clampedIntensity == 0 {
            outputImage = preparedImage
        } else {
            let lutImage = try apply(lut: lut, to: preparedImage).cropped(to: preparedImage.extent)
            let processedImage = applyAdaptivePostProcess(
                to: lutImage,
                adjustment: adaptiveAdjustment
            )
            .cropped(to: preparedImage.extent)
            outputImage = blend(
                original: preparedImage,
                processed: processedImage,
                intensity: clampedIntensity
            )
            .cropped(to: preparedImage.extent)
        }

        guard let renderedImage = context.createCGImage(
            outputImage,
            from: renderExtent,
            format: .RGBA8,
            colorSpace: Self.srgbColorSpace
        ) else {
            throw LumoError.renderFailed
        }

        return renderedImage
    }

    private func applyAdaptivePostProcess(
        to image: CIImage,
        adjustment: AdaptiveRenderAdjustment?
    ) -> CIImage {
        guard let adjustment else {
            return image
        }

        let brightness = adjustment.brightness + (adjustment.shadowLift * 0.04) - (adjustment.highlightRolloff * 0.03)
        return image.applyingFilter(
            "CIColorControls",
            parameters: [
                kCIInputBrightnessKey: brightness.clamped(to: -0.20...0.20),
                kCIInputContrastKey: adjustment.contrast,
                kCIInputSaturationKey: adjustment.saturation
            ]
        )
    }

    private func apply(lut: LUT3D, to image: CIImage) throws -> CIImage {
        let cubeData = Self.colorCubeData(from: lut)
        let parameters: [String: Any] = [
            kCIInputImageKey: image,
            "inputCubeDimension": lut.size,
            "inputCubeData": cubeData,
            "inputColorSpace": Self.srgbColorSpace
        ]

        if let filter = CIFilter(name: "CIColorCubeWithColorSpace", parameters: parameters),
           let outputImage = filter.outputImage {
            return outputImage
        }

        var fallbackParameters = parameters
        fallbackParameters.removeValue(forKey: "inputColorSpace")
        guard let fallbackFilter = CIFilter(name: "CIColorCube", parameters: fallbackParameters),
              let outputImage = fallbackFilter.outputImage else {
            throw LumoError.renderFailed
        }

        return outputImage
    }

    private func blend(original: CIImage, processed: CIImage, intensity: Double) -> CIImage {
        let mask = CIImage(
            color: CIColor(red: intensity, green: intensity, blue: intensity, alpha: 1)
        )
        .cropped(to: original.extent)

        return processed.applyingFilter(
            "CIBlendWithMask",
            parameters: [
                kCIInputBackgroundImageKey: original,
                kCIInputMaskImageKey: mask
            ]
        )
    }

    private static func makeContext() -> CIContext {
        let options: [CIContextOption: Any] = [
            .workingColorSpace: srgbColorSpace,
            .outputColorSpace: srgbColorSpace
        ]

        if let metalDevice = MTLCreateSystemDefaultDevice() {
            return CIContext(mtlDevice: metalDevice, options: options)
        }

        return CIContext(options: options)
    }
}

private extension CIImage {
    func preparedForRendering(size: CoreImageRenderer.RenderSize) -> CIImage {
        let normalizedImage = transformed(
            by: CGAffineTransform(translationX: -extent.origin.x, y: -extent.origin.y)
        )
        let normalizedExtent = CGRect(origin: .zero, size: extent.size)

        guard let maxPixelDimension = size.maxPixelDimension else {
            return normalizedImage.cropped(to: normalizedExtent)
        }

        let longestSide = max(normalizedExtent.width, normalizedExtent.height)
        guard longestSide > 0 else {
            return normalizedImage.cropped(to: normalizedExtent)
        }

        let boundedMaxPixelDimension = max(1, maxPixelDimension)
        let scale = min(1, CGFloat(boundedMaxPixelDimension) / longestSide)
        let targetWidth = max(1, min(boundedMaxPixelDimension, Int((normalizedExtent.width * scale).rounded())))
        let targetHeight = max(1, min(boundedMaxPixelDimension, Int((normalizedExtent.height * scale).rounded())))
        let exactScaleX = CGFloat(targetWidth) / normalizedExtent.width
        let exactScaleY = CGFloat(targetHeight) / normalizedExtent.height
        let targetExtent = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)

        return normalizedImage
            .transformed(by: CGAffineTransform(scaleX: exactScaleX, y: exactScaleY))
            .cropped(to: targetExtent)
    }
}

private extension CoreImageRenderer.RenderSize {
    var maxPixelDimension: Int? {
        switch self {
        case .fullResolution:
            nil
        case .preview(let maxPixelDimension), .thumbnail(let maxPixelDimension):
            maxPixelDimension
        }
    }
}

struct AdaptivePostProcessor: Sendable {
    static let algorithmVersion = "app.adaptive.global.v1"

    private let analyzer = ReferenceImageAnalyzer()

    func metadata(
        forTargetImageData imageData: Data,
        samplePackage: SampleAnalysisPackage,
        requestedIntensity: Double
    ) throws -> AdaptiveRenderMetadata {
        let descriptor = try analyzer.analyze(data: imageData)
        return metadata(
            forTargetDescriptor: descriptor,
            samplePackage: samplePackage,
            requestedIntensity: requestedIntensity
        )
    }

    func metadata(
        forTargetDescriptor descriptor: ReferenceImageAnalyzer.Descriptor,
        samplePackage: SampleAnalysisPackage,
        requestedIntensity: Double
    ) -> AdaptiveRenderMetadata {
        let targetAnalysis = targetAnalysis(from: descriptor)
        let adjustment = adjustment(
            for: targetAnalysis,
            targetDescriptor: descriptor,
            samplePackage: samplePackage,
            requestedIntensity: requestedIntensity
        )
        return AdaptiveRenderMetadata(
            algorithmVersion: Self.algorithmVersion,
            targetAnalysis: targetAnalysis,
            adjustment: adjustment
        )
    }

    private func targetAnalysis(from descriptor: ReferenceImageAnalyzer.Descriptor) -> TargetRenderAnalysis {
        let neutralConfidence = descriptor.neutralProtection.clampedToUnit
        let skinConfidence = min(1, descriptor.skinProtection * 2.2)
        let colorCoverage = (descriptor.chromaP95 * 1.5).clampedToUnit
        let coverage = ((colorCoverage * 0.45) + (neutralConfidence * 0.30) + (skinConfidence * 0.25)).clampedToUnit
        return TargetRenderAnalysis(
            exposureKey: exposureKey(for: descriptor),
            luminanceP50: descriptor.luminanceP50,
            luminanceP95: descriptor.luminanceP95,
            saturationMean: descriptor.saturationMean,
            neutralConfidence: neutralConfidence,
            skinConfidence: skinConfidence,
            coverageConfidenceOverall: coverage
        )
    }

    private func adjustment(
        for targetAnalysis: TargetRenderAnalysis,
        targetDescriptor: ReferenceImageAnalyzer.Descriptor,
        samplePackage: SampleAnalysisPackage,
        requestedIntensity: Double
    ) -> AdaptiveRenderAdjustment {
        let sampleConfidence = samplePackage.coverageConfidence.overall.clampedToUnit
        let exposureMismatch = targetAnalysis.exposureKey == samplePackage.sceneLighting.exposureKey ? 0.0 : 1.0
        let luminanceMismatch = abs(targetAnalysis.luminanceP50 - samplePackage.colorStatistics.luminanceP50)
        let targetCoveragePenalty = 1 - targetAnalysis.coverageConfidenceOverall
        let conservativePenalty = samplePackage.renderProfileSeed.lowConfidenceColorPolicy == .conservative ? 0.08 : 0
        let requestedStrength = requestedIntensity.clampedToLumoPercentage / 100

        let effectiveIntensityScale = (
            1
            - ((1 - sampleConfidence) * 0.35)
            - (luminanceMismatch * 0.38)
            - (exposureMismatch * 0.10)
            - (targetCoveragePenalty * 0.08)
            - conservativePenalty
            + (requestedStrength < 0.35 ? 0.04 : 0)
        ).clamped(to: 0.45...1.0)

        let brightness = (
            (samplePackage.colorStatistics.luminanceP50 - targetAnalysis.luminanceP50) * 0.05
            * (1 - sampleConfidence * 0.35)
        ).clamped(to: -0.06...0.06)

        let targetRange = (targetDescriptor.luminanceP95 - targetDescriptor.luminanceP5).clampedToUnit
        let sampleRange = (samplePackage.colorStatistics.luminanceP95 - samplePackage.colorStatistics.luminanceP5).clampedToUnit
        let contrast = (
            1 + ((sampleRange - targetRange) * 0.12 * sampleConfidence)
        ).clamped(to: 0.88...1.12)

        let saturation = (
            1 + ((samplePackage.colorStatistics.saturationMean - targetAnalysis.saturationMean) * 0.18 * sampleConfidence)
        ).clamped(to: 0.82...1.18)

        let shadowLift = (
            samplePackage.renderProfileSeed.shadowLiftIntent
            * (targetAnalysis.exposureKey == .lowKey ? 1.0 : 0.45)
            * effectiveIntensityScale
        ).clamped(to: 0...0.18)

        let highlightRolloff = (
            samplePackage.renderProfileSeed.highlightRolloffIntent
            * (targetAnalysis.luminanceP95 > 0.88 ? 1.0 : 0.55)
            * effectiveIntensityScale
        ).clamped(to: 0...0.22)

        let confidence = (
            sampleConfidence
            * (1 - luminanceMismatch * 0.25)
            * (1 - exposureMismatch * 0.10)
            * (0.75 + (targetAnalysis.coverageConfidenceOverall * 0.25))
        ).clampedToUnit

        return AdaptiveRenderAdjustment(
            effectiveIntensityScale: effectiveIntensityScale,
            brightness: brightness,
            contrast: contrast,
            saturation: saturation,
            shadowLift: shadowLift,
            highlightRolloff: highlightRolloff,
            confidence: confidence
        )
    }

    private func exposureKey(for descriptor: ReferenceImageAnalyzer.Descriptor) -> ExposureKey {
        if descriptor.luminanceP50 < 0.34 {
            return .lowKey
        }
        if descriptor.luminanceP50 > 0.68 {
            return .highKey
        }
        return .balanced
    }
}
