import CoreGraphics
import CoreImage
import Foundation
import ImageIO

actor CoreImageThumbnailRenderer: ThumbnailRendering {
    private let maxPixelDimension: Int
    private let jpegQuality: CGFloat
    private let renderer: CoreImageRenderer

    init(
        maxPixelDimension: Int = 512,
        jpegQuality: CGFloat = 0.82,
        renderer: CoreImageRenderer = CoreImageRenderer()
    ) {
        self.maxPixelDimension = max(1, maxPixelDimension)
        self.jpegQuality = jpegQuality
        self.renderer = renderer
    }

    func renderThumbnail(from imageData: Data) async throws -> Data {
        guard Self.canDecodeImage(imageData) else {
            throw LumoError.importFailed
        }
        guard let image = CIImage(
            data: imageData,
            options: [
                .applyOrientationProperty: true,
                .colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
            ]
        ) else {
            throw LumoError.importFailed
        }

        let renderedImage = try renderer.render(
            image,
            applying: LUT3D.identity(size: 2),
            intensity: 0,
            size: .thumbnail(maxPixelDimension: maxPixelDimension)
        )
        return try JPEGImageEncoder.encode(renderedImage, quality: jpegQuality)
    }

    private static func canDecodeImage(_ imageData: Data) -> Bool {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return false
        }
        return CGImageSourceGetCount(imageSource) > 0 && CGImageSourceGetType(imageSource) != nil
    }
}
