import Foundation

struct PhotoRenderRequest: Codable, Equatable, Sendable {
    let filmRollID: String
    let processedPhotoID: String
    let originalPath: String
    let lut: LUT3D
    let intensity: Double
    let sampleAnalysisPackage: SampleAnalysisPackage?
    let isAdaptivePostProcessEnabled: Bool

    init(
        filmRollID: String,
        processedPhotoID: String,
        originalPath: String,
        lut: LUT3D,
        intensity: Double,
        sampleAnalysisPackage: SampleAnalysisPackage? = nil,
        isAdaptivePostProcessEnabled: Bool = true
    ) {
        self.filmRollID = filmRollID
        self.processedPhotoID = processedPhotoID
        self.originalPath = originalPath
        self.lut = lut
        self.intensity = intensity.clampedToLumoPercentage
        self.sampleAnalysisPackage = sampleAnalysisPackage
        self.isAdaptivePostProcessEnabled = isAdaptivePostProcessEnabled
    }
}

struct PhotoRenderResult: Codable, Equatable, Sendable {
    let originalPath: String
    let processedPath: String
    let thumbnailPath: String
    let intensity: Double
    let adaptiveRenderMetadata: AdaptiveRenderMetadata?

    init(
        originalPath: String,
        processedPath: String,
        thumbnailPath: String,
        intensity: Double,
        adaptiveRenderMetadata: AdaptiveRenderMetadata? = nil
    ) {
        self.originalPath = originalPath
        self.processedPath = processedPath
        self.thumbnailPath = thumbnailPath
        self.intensity = intensity.clampedToLumoPercentage
        self.adaptiveRenderMetadata = adaptiveRenderMetadata
    }
}

protocol PhotoRendering: Sendable {
    func renderPhoto(for request: PhotoRenderRequest) async throws -> PhotoRenderResult
    func discardRenderedPhoto(_ result: PhotoRenderResult) async
}
