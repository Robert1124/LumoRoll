import CoreGraphics
import CoreImage
import Foundation

struct LUTGenerator: LUTGenerating {
    func generateLUT(
        from descriptor: ReferenceImageAnalyzer.Descriptor,
        size: Int = LUT3D.defaultSize,
        algorithmVersion: String = LUT3D.defaultAlgorithmVersion
    ) throws -> LUT3D {
        guard size > 1 else {
            throw LumoError.invalidLUTSize(size)
        }

        var values: [Float] = []
        values.reserveCapacity(LUT3D.expectedValueCount(for: size))

        let maxIndex = Double(size - 1)
        for blueIndex in 0..<size {
            for greenIndex in 0..<size {
                for redIndex in 0..<size {
                    let red = Double(redIndex) / maxIndex
                    let green = Double(greenIndex) / maxIndex
                    let blue = Double(blueIndex) / maxIndex
                    let transformed = transform(red: red, green: green, blue: blue, descriptor: descriptor)

                    values.append(Float(transformed.red))
                    values.append(Float(transformed.green))
                    values.append(Float(transformed.blue))
                }
            }
        }

        return try LUT3D(size: size, values: values, algorithmVersion: algorithmVersion)
    }

    func generateLUT(for request: LUTGenerationRequest) async throws -> LUT3D {
        let descriptor = try ReferenceImageAnalyzer().analyze(data: request.referenceImageData)
        return try generateLUT(from: descriptor, size: request.size, algorithmVersion: request.algorithmVersion)
    }

    func generateFilmRollPackage(for request: LUTGenerationRequest) async throws -> LUTGenerationResult {
        let descriptor = try ReferenceImageAnalyzer().analyze(data: request.referenceImageData)
        let lut = try generateLUT(from: descriptor, size: request.size, algorithmVersion: request.algorithmVersion)
        let package = SampleAnalysisPackageBuilder().buildPackage(
            from: descriptor,
            algorithmVersion: request.algorithmVersion
        )
        return LUTGenerationResult(lut: lut, sampleAnalysisPackage: package)
    }

    private func transform(
        red: Double,
        green: Double,
        blue: Double,
        descriptor: ReferenceImageAnalyzer.Descriptor
    ) -> (red: Double, green: Double, blue: Double) {
        if descriptor == .neutral {
            return (red, green, blue)
        }

        let neutral = ReferenceImageAnalyzer.Descriptor.neutral
        let toneMapped = RGB(
            red: tone(red, descriptor: descriptor),
            green: tone(green, descriptor: descriptor),
            blue: tone(blue, descriptor: descriptor)
        )
        let tonedLuminance = luminance(toneMapped)
        let zoneWeights = tonalZoneWeights(for: tonedLuminance)
        let colorBalanced = applyZoneColor(
            to: toneMapped,
            descriptor: descriptor,
            weights: zoneWeights
        )
        let hueAdjusted = applyHueSelectiveSaturation(to: colorBalanced, descriptor: descriptor, neutral: neutral)
        let protected = applySoftProtection(
            original: RGB(red: red, green: green, blue: blue),
            adjusted: hueAdjusted,
            fallback: toneMapped,
            descriptor: descriptor
        )

        return (
            clamp(protected.red, min: 0, max: 1),
            clamp(protected.green, min: 0, max: 1),
            clamp(protected.blue, min: 0, max: 1)
        )
    }

    private struct RGB {
        let red: Double
        let green: Double
        let blue: Double
    }

    private struct ZoneWeights {
        let shadow: Double
        let midtone: Double
        let highlight: Double
    }

    private func tone(_ value: Double, descriptor: ReferenceImageAnalyzer.Descriptor) -> Double {
        let contrast = 1 + clamp(descriptor.contrast - 1, min: -0.25, max: 0.25)
        let midpointCorrection = clamp(0.5 - descriptor.luminanceP50, min: -0.10, max: 0.10)
        var adjusted = ((value - 0.5) * contrast) + 0.5 + midpointCorrection

        let robustRange = max(0.01, descriptor.luminanceP99 - descriptor.luminanceP1)
        let rangeCompression = clamp(0.80 - robustRange, min: 0, max: 0.45)
        adjusted = 0.5 + ((adjusted - 0.5) * (1 - (rangeCompression * 0.55)))

        let toeWeight = 1 - smoothstep(edge0: 0.08, edge1: 0.30, x: adjusted)
        adjusted = mix(adjusted, adjusted * 0.94, amount: toeWeight * 0.45)

        let shoulderWeight = smoothstep(edge0: 0.70, edge1: 0.96, x: adjusted)
        let shoulder = 1 - pow(max(0, 1 - adjusted), 1.10)
        adjusted = mix(adjusted, shoulder, amount: shoulderWeight * 0.55)

        return clamp(adjusted, min: 0, max: 1)
    }

    private func tonalZoneWeights(for luminance: Double) -> ZoneWeights {
        let shadow = 1 - smoothstep(edge0: 0.16, edge1: 0.48, x: luminance)
        let highlight = smoothstep(edge0: 0.52, edge1: 0.84, x: luminance)
        let midtone = max(0, 1 - shadow - highlight)
        let total = max(0.0001, shadow + midtone + highlight)
        return ZoneWeights(
            shadow: shadow / total,
            midtone: midtone / total,
            highlight: highlight / total
        )
    }

    private func applyZoneColor(
        to color: RGB,
        descriptor: ReferenceImageAnalyzer.Descriptor,
        weights: ZoneWeights
    ) -> RGB {
        let globalStrength = 0.35
        let redBias = weighted(
            shadow: descriptor.shadowRedBias,
            midtone: descriptor.midtoneRedBias,
            highlight: descriptor.highlightRedBias,
            weights: weights
        ) + (descriptor.redBias * globalStrength)
        let greenBias = weighted(
            shadow: descriptor.shadowGreenBias,
            midtone: descriptor.midtoneGreenBias,
            highlight: descriptor.highlightGreenBias,
            weights: weights
        ) + (descriptor.greenBias * globalStrength)
        let blueBias = weighted(
            shadow: descriptor.shadowBlueBias,
            midtone: descriptor.midtoneBlueBias,
            highlight: descriptor.highlightBlueBias,
            weights: weights
        ) + (descriptor.blueBias * globalStrength)
        let warmth = weighted(
            shadow: descriptor.shadowWarmth,
            midtone: descriptor.midtoneWarmth,
            highlight: descriptor.highlightWarmth,
            weights: weights
        )

        return RGB(
            red: color.red + clamp(redBias, min: -0.08, max: 0.08) + clamp(warmth, min: -0.05, max: 0.05),
            green: color.green + clamp(greenBias, min: -0.08, max: 0.08),
            blue: color.blue + clamp(blueBias, min: -0.08, max: 0.08) - clamp(warmth, min: -0.05, max: 0.05)
        )
    }

    private func applyHueSelectiveSaturation(
        to color: RGB,
        descriptor: ReferenceImageAnalyzer.Descriptor,
        neutral: ReferenceImageAnalyzer.Descriptor
    ) -> RGB {
        let colorLuminance = luminance(color)
        let hue = hueDegrees(color)
        let globalScale = 1 + clamp(descriptor.saturationMean - neutral.saturationMean, min: -0.20, max: 0.20) * 0.65
        let sectorBias = hueSaturationBias(for: hue, descriptor: descriptor)
        let sectorScale = 1 + clamp(sectorBias, min: -0.45, max: 0.45)
        let scale = clamp(globalScale * sectorScale, min: 0.55, max: 1.45)

        return RGB(
            red: colorLuminance + ((color.red - colorLuminance) * scale),
            green: colorLuminance + ((color.green - colorLuminance) * scale),
            blue: colorLuminance + ((color.blue - colorLuminance) * scale)
        )
    }

    private func applySoftProtection(
        original: RGB,
        adjusted: RGB,
        fallback: RGB,
        descriptor: ReferenceImageAnalyzer.Descriptor
    ) -> RGB {
        let originalSaturation = saturation(original)
        let neutralMask = smoothstep(edge0: 0.18, edge1: 0.02, x: originalSaturation)
            * clamp(descriptor.neutralProtection, min: 0, max: 1)
        let skinMask = skinHueWeight(original)
            * clamp(descriptor.skinProtection, min: 0, max: 1)
            * (1 - neutralMask)
        let protection = clamp(neutralMask + skinMask, min: 0, max: 0.95)

        return RGB(
            red: mix(adjusted.red, fallback.red, amount: protection),
            green: mix(adjusted.green, fallback.green, amount: protection),
            blue: mix(adjusted.blue, fallback.blue, amount: protection)
        )
    }

    private func weighted(shadow: Double, midtone: Double, highlight: Double, weights: ZoneWeights) -> Double {
        (shadow * weights.shadow) + (midtone * weights.midtone) + (highlight * weights.highlight)
    }

    private func hueSaturationBias(for hue: Double, descriptor: ReferenceImageAnalyzer.Descriptor) -> Double {
        let weightedBiases: [(center: Double, width: Double, bias: Double)] = [
            (0, 34, descriptor.redSaturationBias),
            (30, 30, descriptor.orangeSaturationBias),
            (60, 34, descriptor.yellowSaturationBias),
            (125, 55, descriptor.greenSaturationBias),
            (185, 45, descriptor.cyanSaturationBias),
            (235, 48, descriptor.blueSaturationBias),
            (300, 58, descriptor.magentaSaturationBias)
        ]
        var total = 0.0
        var weightedTotal = 0.0
        for entry in weightedBiases {
            let distance = circularHueDistance(hue, entry.center)
            let weight = max(0, 1 - (distance / entry.width))
            weightedTotal += entry.bias * weight
            total += weight
        }
        guard total > 0 else {
            return 0
        }
        return weightedTotal / total
    }

    private func skinHueWeight(_ color: RGB) -> Double {
        let hue = hueDegrees(color)
        let hueWeight = max(0, 1 - (abs(hue - 28) / 28))
        let saturationValue = saturation(color)
        let saturationWeight = smoothstep(edge0: 0.10, edge1: 0.24, x: saturationValue)
            * (1 - smoothstep(edge0: 0.72, edge1: 0.90, x: saturationValue))
        let luminanceValue = luminance(color)
        let luminanceWeight = smoothstep(edge0: 0.25, edge1: 0.40, x: luminanceValue)
            * (1 - smoothstep(edge0: 0.86, edge1: 0.98, x: luminanceValue))
        return clamp(hueWeight * saturationWeight * luminanceWeight, min: 0, max: 1)
    }

    private func luminance(_ color: RGB) -> Double {
        (0.2126 * color.red) + (0.7152 * color.green) + (0.0722 * color.blue)
    }

    private func saturation(_ color: RGB) -> Double {
        let maximum = max(color.red, color.green, color.blue)
        let minimum = min(color.red, color.green, color.blue)
        guard maximum > 0 else {
            return 0
        }
        return (maximum - minimum) / maximum
    }

    private func hueDegrees(_ color: RGB) -> Double {
        let maximum = max(color.red, color.green, color.blue)
        let minimum = min(color.red, color.green, color.blue)
        let delta = maximum - minimum
        guard delta > 0 else {
            return 0
        }

        let rawHue: Double
        if maximum == color.red {
            rawHue = 60 * (((color.green - color.blue) / delta).truncatingRemainder(dividingBy: 6))
        } else if maximum == color.green {
            rawHue = 60 * (((color.blue - color.red) / delta) + 2)
        } else {
            rawHue = 60 * (((color.red - color.green) / delta) + 4)
        }
        return rawHue < 0 ? rawHue + 360 : rawHue
    }

    private func circularHueDistance(_ lhs: Double, _ rhs: Double) -> Double {
        let direct = abs(lhs - rhs).truncatingRemainder(dividingBy: 360)
        return min(direct, 360 - direct)
    }

    private func smoothstep(edge0: Double, edge1: Double, x: Double) -> Double {
        guard edge0 != edge1 else {
            return x < edge0 ? 0 : 1
        }
        let t = clamp((x - edge0) / (edge1 - edge0), min: 0, max: 1)
        return t * t * (3 - (2 * t))
    }

    private func mix(_ first: Double, _ second: Double, amount: Double) -> Double {
        first + ((second - first) * clamp(amount, min: 0, max: 1))
    }

    private func clamp(_ value: Double, min minimum: Double, max maximum: Double) -> Double {
        Swift.max(minimum, Swift.min(maximum, value))
    }
}

struct SampleAnalysisPackageBuilder {
    func buildPackage(
        from descriptor: ReferenceImageAnalyzer.Descriptor,
        algorithmVersion: String,
        modelVersion: String? = nil
    ) -> SampleAnalysisPackage {
        let warnings = sampleWarnings(from: descriptor)
        let qualityConfidence = confidence(from: descriptor, warnings: warnings)
        let exposureKey = exposureKey(for: descriptor)
        let semanticColor = semanticColor(from: descriptor)
        let coverage = coverageConfidence(
            from: descriptor,
            semanticColor: semanticColor,
            overallConfidence: qualityConfidence
        )
        let blackLift = blackLift(from: descriptor)
        let highlightRolloff = highlightRolloff(from: descriptor)
        let shadowTintStrength = max(
            abs(descriptor.shadowRedBias),
            abs(descriptor.shadowGreenBias),
            abs(descriptor.shadowBlueBias),
            abs(descriptor.shadowWarmth)
        ).clampedToUnit
        let saturationIntent = (0.5 + ((descriptor.saturationMean - 0.25) * 0.9)).clampedToUnit

        return SampleAnalysisPackage(
            algorithmVersion: algorithmVersion,
            modelVersion: modelVersion,
            sampleQuality: SampleQualityMetadata(
                usable: qualityConfidence >= 0.15,
                confidence: qualityConfidence,
                warnings: warnings
            ),
            colorStatistics: SampleColorStatistics(
                luminanceP5: descriptor.luminanceP5,
                luminanceP50: descriptor.luminanceP50,
                luminanceP95: descriptor.luminanceP95,
                chromaP50: descriptor.chromaP50,
                saturationMean: descriptor.saturationMean,
                redBias: descriptor.redBias,
                greenBias: descriptor.greenBias,
                blueBias: descriptor.blueBias,
                shadowWarmth: descriptor.shadowWarmth,
                midtoneWarmth: descriptor.midtoneWarmth,
                highlightWarmth: descriptor.highlightWarmth
            ),
            sceneLighting: SceneLightingDescriptor(
                exposureKey: exposureKey,
                contrastIntent: contrastIntent(from: descriptor),
                shadowTintStrength: shadowTintStrength,
                highlightWarmth: descriptor.highlightWarmth,
                blackLift: blackLift,
                highlightRolloff: highlightRolloff,
                saturationIntent: saturationIntent
            ),
            semanticColor: semanticColor,
            styleProfile: StyleProfile(
                blackPointLift: blackLift,
                highlightRolloff: highlightRolloff,
                globalSaturation: saturationIntent,
                greenHandling: descriptor.greenSaturationBias.clamped(to: -1...1),
                skinProtection: semanticColor.skin.confidence,
                neutralProtection: semanticColor.neutral.confidence,
                styleStrength: styleStrength(from: descriptor, confidence: qualityConfidence)
            ),
            coverageConfidence: coverage,
            renderProfileSeed: RenderProfileSeed(
                skinProtectionIntent: semanticColor.skin.confidence,
                neutralProtectionIntent: semanticColor.neutral.confidence,
                highlightRolloffIntent: highlightRolloff,
                shadowLiftIntent: blackLift,
                shadowTintAdaptation: shadowTintStrength,
                lowConfidenceColorPolicy: qualityConfidence < 0.70 || coverage.overall < 0.70 ? .conservative : .balanced
            )
        )
    }

    private func sampleWarnings(from descriptor: ReferenceImageAnalyzer.Descriptor) -> [SampleQualityWarning] {
        var warnings: [SampleQualityWarning] = descriptor.warnings.map { warning in
            switch warning {
            case .assumedSRGB:
                return .assumedSRGB
            case .lowContrast:
                return .lowContrast
            case .lowSaturation:
                return .lowSaturation
            case .lowConfidence:
                return .lowConfidence
            }
        }

        if descriptor.chromaP95 < 0.10 || descriptor.saturationMean < 0.08 {
            warnings.append(.lowColorCoverage)
        }
        if descriptor.luminanceP50 < 0.28 {
            warnings.append(.highShadowFraction)
        }
        if descriptor.luminanceP50 > 0.75 {
            warnings.append(.highHighlightFraction)
        }

        return Array(Set(warnings)).sorted { $0.rawValue < $1.rawValue }
    }

    private func confidence(
        from descriptor: ReferenceImageAnalyzer.Descriptor,
        warnings: [SampleQualityWarning]
    ) -> Double {
        var confidence = 0.95
        confidence -= Double(warnings.filter { $0 != .assumedSRGB }.count) * 0.10
        confidence -= max(0, 0.12 - descriptor.chromaP95) * 1.2
        confidence -= max(0, 0.14 - (descriptor.luminanceP95 - descriptor.luminanceP5)) * 1.4
        confidence -= abs(descriptor.luminanceP50 - 0.5) * 0.18
        return confidence.clamped(to: 0.10...1)
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

    private func semanticColor(from descriptor: ReferenceImageAnalyzer.Descriptor) -> SemanticColorDescriptor {
        let neutral = descriptor.neutralProtection.clampedToUnit
        let skin = min(1, descriptor.skinProtection * 2.2)
        let foliage = hueConfidence(descriptor.greenSaturationBias, scale: 2.6)
        let sky = max(
            hueConfidence(descriptor.blueSaturationBias, scale: 2.4),
            hueConfidence(descriptor.cyanSaturationBias, scale: 2.2)
        )
        let warmLight = max(
            positiveConfidence(descriptor.highlightWarmth, scale: 3.5),
            hueConfidence(descriptor.orangeSaturationBias, scale: 2.5),
            positiveConfidence(descriptor.redBias, scale: 3.0)
        )
        let saturatedRed = max(
            hueConfidence(descriptor.redSaturationBias, scale: 2.5),
            hueConfidence(descriptor.orangeSaturationBias, scale: 2.0)
        )
        let saturatedGreen = hueConfidence(descriptor.greenSaturationBias, scale: 2.5)
        let saturatedBlue = max(
            hueConfidence(descriptor.blueSaturationBias, scale: 2.5),
            hueConfidence(descriptor.cyanSaturationBias, scale: 2.0)
        )

        return SemanticColorDescriptor(
            neutral: evidence(confidence: neutral, observedThreshold: 0.10),
            skin: evidence(confidence: skin, observedThreshold: 0.12),
            foliage: evidence(confidence: foliage, observedThreshold: 0.16),
            sky: evidence(confidence: sky, observedThreshold: 0.16),
            warmLight: evidence(confidence: warmLight, observedThreshold: 0.16),
            saturatedRed: evidence(confidence: saturatedRed, observedThreshold: 0.18),
            saturatedGreen: evidence(confidence: saturatedGreen, observedThreshold: 0.18),
            saturatedBlue: evidence(confidence: saturatedBlue, observedThreshold: 0.18)
        )
    }

    private func coverageConfidence(
        from descriptor: ReferenceImageAnalyzer.Descriptor,
        semanticColor: SemanticColorDescriptor,
        overallConfidence: Double
    ) -> CoverageConfidenceMetadata {
        let deepShadowConfidence = descriptor.luminanceP5 < 0.12 ? 0.80 : descriptor.luminanceP25 < 0.30 ? 0.52 : 0.20
        let midtoneConfidence = (1 - abs(descriptor.luminanceP50 - 0.5) * 1.5).clampedToUnit
        let highlightConfidence = descriptor.luminanceP95 > 0.76 ? 0.78 : descriptor.luminanceP75 > 0.64 ? 0.52 : 0.20
        let colorBreadth = (descriptor.chromaP95 * 1.6).clampedToUnit
        let overall = (overallConfidence * 0.60)
            + (colorBreadth * 0.22)
            + (max(semanticColor.neutral.confidence, semanticColor.skin.confidence) * 0.18)

        return CoverageConfidenceMetadata(
            overall: overall,
            deepShadow: coverageLevel(deepShadowConfidence),
            midtone: coverageLevel(midtoneConfidence),
            highlight: coverageLevel(highlightConfidence),
            saturatedRed: coverageLevel(semanticColor.saturatedRed.confidence),
            saturatedGreen: coverageLevel(semanticColor.saturatedGreen.confidence),
            saturatedBlue: coverageLevel(semanticColor.saturatedBlue.confidence),
            neutral: coverageLevel(semanticColor.neutral.confidence),
            skin: coverageLevel(semanticColor.skin.confidence),
            sky: coverageLevel(semanticColor.sky.confidence),
            foliage: coverageLevel(semanticColor.foliage.confidence),
            warmLight: coverageLevel(semanticColor.warmLight.confidence)
        )
    }

    private func contrastIntent(from descriptor: ReferenceImageAnalyzer.Descriptor) -> Double {
        ((descriptor.contrast - 0.25) / 1.50).clampedToUnit
    }

    private func blackLift(from descriptor: ReferenceImageAnalyzer.Descriptor) -> Double {
        let compressedShadows = max(0, 0.12 - descriptor.luminanceP5) * 1.2
        let lowKeyLift = descriptor.luminanceP50 < 0.34 ? (0.34 - descriptor.luminanceP50) * 0.55 : 0
        return (compressedShadows + lowKeyLift).clamped(to: 0...0.28)
    }

    private func highlightRolloff(from descriptor: ReferenceImageAnalyzer.Descriptor) -> Double {
        let brightHighlights = max(0, descriptor.luminanceP95 - 0.72) * 0.75
        let warmHighlights = max(0, descriptor.highlightWarmth) * 0.75
        return (brightHighlights + warmHighlights).clamped(to: 0...0.45)
    }

    private func styleStrength(
        from descriptor: ReferenceImageAnalyzer.Descriptor,
        confidence: Double
    ) -> Double {
        let colorCast = max(abs(descriptor.redBias), abs(descriptor.greenBias), abs(descriptor.blueBias)) * 3.0
        let zoneColor = max(abs(descriptor.shadowWarmth), abs(descriptor.highlightWarmth)) * 2.0
        let saturation = abs(descriptor.saturationMean - 0.35)
        return ((colorCast + zoneColor + saturation + 0.35) * confidence).clampedToUnit
    }

    private func evidence(confidence: Double, observedThreshold: Double) -> ColorFamilyEvidence {
        ColorFamilyEvidence(observed: confidence >= observedThreshold, confidence: confidence)
    }

    private func coverageLevel(_ confidence: Double) -> CoverageConfidenceLevel {
        switch confidence.clampedToUnit {
        case 0..<0.08:
            return .missing
        case 0..<0.30:
            return .low
        case 0..<0.62:
            return .medium
        default:
            return .high
        }
    }

    private func hueConfidence(_ value: Double, scale: Double) -> Double {
        max(0, value * scale).clampedToUnit
    }

    private func positiveConfidence(_ value: Double, scale: Double) -> Double {
        max(0, value * scale).clampedToUnit
    }
}
