import Foundation

protocol ThumbnailRendering: Sendable {
    func renderThumbnail(from imageData: Data) async throws -> Data
}

protocol LUTPreviewRendering: Sendable {
    func renderPreviewImage(for lut: LUT3D) throws -> Data
}
