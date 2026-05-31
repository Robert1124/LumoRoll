import Foundation

struct PhotoPreviewRenderRequest: Codable, Equatable, Sendable {
    let filmRollID: String
    let previewID: String
    let originalPath: String
    let lut: LUT3D
    let intensity: Double
    let maxPixelDimension: Int
    let sampleAnalysisPackage: SampleAnalysisPackage?
    let isAdaptivePostProcessEnabled: Bool

    init(
        filmRollID: String,
        previewID: String,
        originalPath: String,
        lut: LUT3D,
        intensity: Double,
        maxPixelDimension: Int,
        sampleAnalysisPackage: SampleAnalysisPackage? = nil,
        isAdaptivePostProcessEnabled: Bool = true
    ) {
        self.filmRollID = filmRollID
        self.previewID = previewID
        self.originalPath = originalPath
        self.lut = lut
        self.intensity = intensity.clampedToLumoPercentage
        self.maxPixelDimension = max(1, maxPixelDimension)
        self.sampleAnalysisPackage = sampleAnalysisPackage
        self.isAdaptivePostProcessEnabled = isAdaptivePostProcessEnabled
    }
}

struct PhotoPreviewRenderResult: Codable, Equatable, Sendable {
    let previewID: String
    let originalPath: String
    let previewPath: String
    let intensity: Double
    let adaptiveRenderMetadata: AdaptiveRenderMetadata?

    init(
        previewID: String,
        originalPath: String,
        previewPath: String,
        intensity: Double,
        adaptiveRenderMetadata: AdaptiveRenderMetadata? = nil
    ) {
        self.previewID = previewID
        self.originalPath = originalPath
        self.previewPath = previewPath
        self.intensity = intensity.clampedToLumoPercentage
        self.adaptiveRenderMetadata = adaptiveRenderMetadata
    }
}

protocol PhotoPreviewRendering: Sendable {
    func renderPreview(for request: PhotoPreviewRenderRequest) async throws -> PhotoPreviewRenderResult
    func discardRenderedPreview(at relativePath: String) async
}
