import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct LocalPhotoDisplayImage: Equatable, Sendable {
    let data: Data
    let pixelWidth: Int
    let pixelHeight: Int
    let contentType: String
}

struct LocalPhotoImageLoader: Sendable {
    private static let maximumDisplayPixelDimension = 4_096

    private let resolver: AppAssetURLResolver

    init(resolver: AppAssetURLResolver) {
        self.resolver = resolver
    }

    func loadDisplayImage(relativePath: String, maxPixelDimension: Int) async throws -> LocalPhotoDisplayImage {
        guard maxPixelDimension > 0 else {
            throw LumoError.importFailed
        }
        let sourceURL = try resolver.resolve(relativePath)
        let maxPixelDimension = min(maxPixelDimension, Self.maximumDisplayPixelDimension)

        return try await Task.detached(priority: .userInitiated) {
            try Self.loadDisplayImage(at: sourceURL, maxPixelDimension: maxPixelDimension)
        }.value
    }

    private static func loadDisplayImage(at sourceURL: URL, maxPixelDimension: Int) throws -> LocalPhotoDisplayImage {
        guard maxPixelDimension > 0 else {
            throw LumoError.importFailed
        }
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw LumoError.importFailed
        }

        let sourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(sourceURL as CFURL, sourceOptions),
              CGImageSourceGetCount(imageSource) > 0,
              let sourceTypeIdentifier = CGImageSourceGetType(imageSource) as String? else {
            throw LumoError.importFailed
        }

        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelDimension
        ] as CFDictionary
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions) else {
            throw LumoError.importFailed
        }

        let outputTypeIdentifier = outputTypeIdentifier(for: sourceTypeIdentifier)
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            data,
            outputTypeIdentifier as CFString,
            1,
            nil
        ) else {
            throw LumoError.importFailed
        }

        if outputTypeIdentifier == UTType.jpeg.identifier {
            let options = [
                kCGImageDestinationLossyCompressionQuality: 0.86
            ] as CFDictionary
            CGImageDestinationAddImage(destination, thumbnail, options)
        } else {
            CGImageDestinationAddImage(destination, thumbnail, nil)
        }

        guard CGImageDestinationFinalize(destination) else {
            throw LumoError.importFailed
        }

        return LocalPhotoDisplayImage(
            data: data as Data,
            pixelWidth: thumbnail.width,
            pixelHeight: thumbnail.height,
            contentType: outputTypeIdentifier
        )
    }

    private static func outputTypeIdentifier(for sourceTypeIdentifier: String) -> String {
        guard let type = UTType(sourceTypeIdentifier),
              type.conforms(to: .png) else {
            return UTType.jpeg.identifier
        }

        return UTType.png.identifier
    }
}
