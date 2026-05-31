import Foundation

struct FilmRoll: Codable, Equatable, Identifiable, Sendable {
    let id: String
    var name: String
    let createdAt: Date
    var updatedAt: Date
    var referenceAsset: FilmRollReferenceAsset
    var lut: LUT3D
    var sampleAnalysisPackage: SampleAnalysisPackage?
    var palette: [FilmRollPaletteColor]
    var processedPhotos: [ProcessedPhoto]

    init(
        id: String = UUID().uuidString,
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date? = nil,
        referenceAsset: FilmRollReferenceAsset,
        lut: LUT3D,
        sampleAnalysisPackage: SampleAnalysisPackage? = nil,
        palette: [FilmRollPaletteColor] = [],
        processedPhotos: [ProcessedPhoto] = []
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw LumoError.invalidFilmRollName
        }

        self.id = id
        self.name = trimmedName
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.referenceAsset = referenceAsset
        self.lut = lut
        self.sampleAnalysisPackage = sampleAnalysisPackage
        self.palette = palette
        self.processedPhotos = processedPhotos
    }
}

struct FilmRollReferenceAsset: Codable, Equatable, Sendable {
    let originalPath: String
    let thumbnailPath: String

    init(originalPath: String, thumbnailPath: String) {
        self.originalPath = originalPath
        self.thumbnailPath = thumbnailPath
    }
}

struct FilmRollPaletteColor: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let red: Float
    let green: Float
    let blue: Float

    init(id: String = UUID().uuidString, red: Float, green: Float, blue: Float) {
        self.id = id
        self.red = red
        self.green = green
        self.blue = blue
    }
}

struct SampleAnalysisPackage: Codable, Equatable, Sendable {
    let algorithmVersion: String
    let modelVersion: String?
    let sampleQuality: SampleQualityMetadata
    let colorStatistics: SampleColorStatistics
    let sceneLighting: SceneLightingDescriptor
    let semanticColor: SemanticColorDescriptor
    let styleProfile: StyleProfile
    let coverageConfidence: CoverageConfidenceMetadata
    let renderProfileSeed: RenderProfileSeed
}

struct SampleQualityMetadata: Codable, Equatable, Sendable {
    let usable: Bool
    let confidence: Double
    let warnings: [SampleQualityWarning]

    init(usable: Bool, confidence: Double, warnings: [SampleQualityWarning]) {
        self.usable = usable
        self.confidence = confidence.clampedToUnit
        self.warnings = warnings
    }
}

enum SampleQualityWarning: String, Codable, Equatable, Sendable {
    case assumedSRGB
    case lowContrast
    case lowSaturation
    case lowConfidence
    case lowColorCoverage
    case highShadowFraction
    case highHighlightFraction
}

struct SampleColorStatistics: Codable, Equatable, Sendable {
    let luminanceP5: Double
    let luminanceP50: Double
    let luminanceP95: Double
    let chromaP50: Double
    let saturationMean: Double
    let redBias: Double
    let greenBias: Double
    let blueBias: Double
    let shadowWarmth: Double
    let midtoneWarmth: Double
    let highlightWarmth: Double

    init(
        luminanceP5: Double,
        luminanceP50: Double,
        luminanceP95: Double,
        chromaP50: Double,
        saturationMean: Double,
        redBias: Double,
        greenBias: Double,
        blueBias: Double,
        shadowWarmth: Double,
        midtoneWarmth: Double,
        highlightWarmth: Double
    ) {
        self.luminanceP5 = luminanceP5.clampedToUnit
        self.luminanceP50 = luminanceP50.clampedToUnit
        self.luminanceP95 = luminanceP95.clampedToUnit
        self.chromaP50 = chromaP50.clampedToUnit
        self.saturationMean = saturationMean.clampedToUnit
        self.redBias = redBias.clamped(to: -1...1)
        self.greenBias = greenBias.clamped(to: -1...1)
        self.blueBias = blueBias.clamped(to: -1...1)
        self.shadowWarmth = shadowWarmth.clamped(to: -1...1)
        self.midtoneWarmth = midtoneWarmth.clamped(to: -1...1)
        self.highlightWarmth = highlightWarmth.clamped(to: -1...1)
    }
}

enum ExposureKey: String, Codable, Equatable, Sendable {
    case lowKey
    case balanced
    case highKey
}

struct SceneLightingDescriptor: Codable, Equatable, Sendable {
    let exposureKey: ExposureKey
    let contrastIntent: Double
    let shadowTintStrength: Double
    let highlightWarmth: Double
    let blackLift: Double
    let highlightRolloff: Double
    let saturationIntent: Double

    init(
        exposureKey: ExposureKey,
        contrastIntent: Double,
        shadowTintStrength: Double,
        highlightWarmth: Double,
        blackLift: Double,
        highlightRolloff: Double,
        saturationIntent: Double
    ) {
        self.exposureKey = exposureKey
        self.contrastIntent = contrastIntent.clampedToUnit
        self.shadowTintStrength = shadowTintStrength.clampedToUnit
        self.highlightWarmth = highlightWarmth.clamped(to: -1...1)
        self.blackLift = blackLift.clampedToUnit
        self.highlightRolloff = highlightRolloff.clampedToUnit
        self.saturationIntent = saturationIntent.clampedToUnit
    }
}

struct ColorFamilyEvidence: Codable, Equatable, Sendable {
    let observed: Bool
    let confidence: Double

    init(observed: Bool, confidence: Double) {
        self.observed = observed
        self.confidence = confidence.clampedToUnit
    }
}

struct SemanticColorDescriptor: Codable, Equatable, Sendable {
    let neutral: ColorFamilyEvidence
    let skin: ColorFamilyEvidence
    let foliage: ColorFamilyEvidence
    let sky: ColorFamilyEvidence
    let warmLight: ColorFamilyEvidence
    let saturatedRed: ColorFamilyEvidence
    let saturatedGreen: ColorFamilyEvidence
    let saturatedBlue: ColorFamilyEvidence
}

struct StyleProfile: Codable, Equatable, Sendable {
    let blackPointLift: Double
    let highlightRolloff: Double
    let globalSaturation: Double
    let greenHandling: Double
    let skinProtection: Double
    let neutralProtection: Double
    let styleStrength: Double

    init(
        blackPointLift: Double,
        highlightRolloff: Double,
        globalSaturation: Double,
        greenHandling: Double,
        skinProtection: Double,
        neutralProtection: Double,
        styleStrength: Double
    ) {
        self.blackPointLift = blackPointLift.clampedToUnit
        self.highlightRolloff = highlightRolloff.clampedToUnit
        self.globalSaturation = globalSaturation.clampedToUnit
        self.greenHandling = greenHandling.clamped(to: -1...1)
        self.skinProtection = skinProtection.clampedToUnit
        self.neutralProtection = neutralProtection.clampedToUnit
        self.styleStrength = styleStrength.clampedToUnit
    }
}

enum CoverageConfidenceLevel: String, Codable, Equatable, Sendable {
    case missing
    case low
    case medium
    case high
}

struct CoverageConfidenceMetadata: Codable, Equatable, Sendable {
    let overall: Double
    let deepShadow: CoverageConfidenceLevel
    let midtone: CoverageConfidenceLevel
    let highlight: CoverageConfidenceLevel
    let saturatedRed: CoverageConfidenceLevel
    let saturatedGreen: CoverageConfidenceLevel
    let saturatedBlue: CoverageConfidenceLevel
    let neutral: CoverageConfidenceLevel
    let skin: CoverageConfidenceLevel
    let sky: CoverageConfidenceLevel
    let foliage: CoverageConfidenceLevel
    let warmLight: CoverageConfidenceLevel

    init(
        overall: Double,
        deepShadow: CoverageConfidenceLevel,
        midtone: CoverageConfidenceLevel,
        highlight: CoverageConfidenceLevel,
        saturatedRed: CoverageConfidenceLevel,
        saturatedGreen: CoverageConfidenceLevel,
        saturatedBlue: CoverageConfidenceLevel,
        neutral: CoverageConfidenceLevel,
        skin: CoverageConfidenceLevel,
        sky: CoverageConfidenceLevel,
        foliage: CoverageConfidenceLevel,
        warmLight: CoverageConfidenceLevel
    ) {
        self.overall = overall.clampedToUnit
        self.deepShadow = deepShadow
        self.midtone = midtone
        self.highlight = highlight
        self.saturatedRed = saturatedRed
        self.saturatedGreen = saturatedGreen
        self.saturatedBlue = saturatedBlue
        self.neutral = neutral
        self.skin = skin
        self.sky = sky
        self.foliage = foliage
        self.warmLight = warmLight
    }
}

struct RenderProfileSeed: Codable, Equatable, Sendable {
    let skinProtectionIntent: Double
    let neutralProtectionIntent: Double
    let highlightRolloffIntent: Double
    let shadowLiftIntent: Double
    let shadowTintAdaptation: Double
    let lowConfidenceColorPolicy: LowConfidenceColorPolicy

    init(
        skinProtectionIntent: Double,
        neutralProtectionIntent: Double,
        highlightRolloffIntent: Double,
        shadowLiftIntent: Double,
        shadowTintAdaptation: Double,
        lowConfidenceColorPolicy: LowConfidenceColorPolicy
    ) {
        self.skinProtectionIntent = skinProtectionIntent.clampedToUnit
        self.neutralProtectionIntent = neutralProtectionIntent.clampedToUnit
        self.highlightRolloffIntent = highlightRolloffIntent.clampedToUnit
        self.shadowLiftIntent = shadowLiftIntent.clampedToUnit
        self.shadowTintAdaptation = shadowTintAdaptation.clampedToUnit
        self.lowConfidenceColorPolicy = lowConfidenceColorPolicy
    }
}

enum LowConfidenceColorPolicy: String, Codable, Equatable, Sendable {
    case conservative
    case balanced
}

struct TargetRenderAnalysis: Codable, Equatable, Sendable {
    let exposureKey: ExposureKey
    let luminanceP50: Double
    let luminanceP95: Double
    let saturationMean: Double
    let neutralConfidence: Double
    let skinConfidence: Double
    let coverageConfidenceOverall: Double

    init(
        exposureKey: ExposureKey,
        luminanceP50: Double,
        luminanceP95: Double,
        saturationMean: Double,
        neutralConfidence: Double,
        skinConfidence: Double,
        coverageConfidenceOverall: Double
    ) {
        self.exposureKey = exposureKey
        self.luminanceP50 = luminanceP50.clampedToUnit
        self.luminanceP95 = luminanceP95.clampedToUnit
        self.saturationMean = saturationMean.clampedToUnit
        self.neutralConfidence = neutralConfidence.clampedToUnit
        self.skinConfidence = skinConfidence.clampedToUnit
        self.coverageConfidenceOverall = coverageConfidenceOverall.clampedToUnit
    }
}

struct AdaptiveRenderAdjustment: Codable, Equatable, Sendable {
    let effectiveIntensityScale: Double
    let brightness: Double
    let contrast: Double
    let saturation: Double
    let shadowLift: Double
    let highlightRolloff: Double
    let confidence: Double

    init(
        effectiveIntensityScale: Double,
        brightness: Double,
        contrast: Double,
        saturation: Double,
        shadowLift: Double,
        highlightRolloff: Double,
        confidence: Double
    ) {
        self.effectiveIntensityScale = effectiveIntensityScale.clampedToUnit
        self.brightness = brightness.clamped(to: -0.20...0.20)
        self.contrast = contrast.clamped(to: 0.60...1.40)
        self.saturation = saturation.clamped(to: 0.50...1.50)
        self.shadowLift = shadowLift.clampedToUnit
        self.highlightRolloff = highlightRolloff.clampedToUnit
        self.confidence = confidence.clampedToUnit
    }
}

struct AdaptiveRenderMetadata: Codable, Equatable, Sendable {
    let algorithmVersion: String
    let targetAnalysis: TargetRenderAnalysis
    let adjustment: AdaptiveRenderAdjustment
}

extension Double {
    var clampedToUnit: Double {
        guard isFinite else {
            return 0
        }
        return clamped(to: 0...1)
    }

    func clamped(to range: ClosedRange<Double>) -> Double {
        guard isFinite else {
            return range.lowerBound
        }
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
