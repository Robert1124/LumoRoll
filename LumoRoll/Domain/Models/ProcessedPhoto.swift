import Foundation

struct ProcessedPhoto: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let originalPath: String
    let processedPath: String
    let thumbnailPath: String
    let createdAt: Date
    let intensity: Double
    let adaptiveRenderMetadata: AdaptiveRenderMetadata?

    init(
        id: String = UUID().uuidString,
        originalPath: String,
        processedPath: String,
        thumbnailPath: String,
        createdAt: Date = Date(),
        intensity: Double,
        adaptiveRenderMetadata: AdaptiveRenderMetadata? = nil
    ) {
        self.id = id
        self.originalPath = originalPath
        self.processedPath = processedPath
        self.thumbnailPath = thumbnailPath
        self.createdAt = createdAt
        self.intensity = intensity.clampedToLumoPercentage
        self.adaptiveRenderMetadata = adaptiveRenderMetadata
    }
}

extension Double {
    var clampedToLumoPercentage: Double {
        min(max(self, 0), 100)
    }
}
