import CoreGraphics
import CoreImage
import Foundation
import ImageIO

actor CoreImagePhotoRenderer: PhotoRendering {
    private let assetStore: AssetStore
    private let fileManager: FileManager
    private let renderer: CoreImageRenderer
    private let adaptivePostProcessor: AdaptivePostProcessor
    private let renderedJPEGQuality: CGFloat
    private let thumbnailJPEGQuality: CGFloat
    private let thumbnailMaxPixelDimension: Int

    init(
        assetStore: AssetStore,
        fileManager: FileManager = .default,
        renderer: CoreImageRenderer = CoreImageRenderer(),
        adaptivePostProcessor: AdaptivePostProcessor = AdaptivePostProcessor(),
        renderedJPEGQuality: CGFloat = 0.9,
        thumbnailJPEGQuality: CGFloat = 0.82,
        thumbnailMaxPixelDimension: Int = 512
    ) {
        self.assetStore = assetStore
        self.fileManager = fileManager
        self.renderer = renderer
        self.adaptivePostProcessor = adaptivePostProcessor
        self.renderedJPEGQuality = renderedJPEGQuality
        self.thumbnailJPEGQuality = thumbnailJPEGQuality
        self.thumbnailMaxPixelDimension = max(1, thumbnailMaxPixelDimension)
    }

    func renderPhoto(for request: PhotoRenderRequest) async throws -> PhotoRenderResult {
        guard Self.isPathSafeComponent(request.filmRollID),
              Self.isPathSafeComponent(request.processedPhotoID) else {
            throw LumoError.storageFailed(message: "Invalid processed photo asset ID.")
        }

        let sourceURL = sourceURL(for: request.originalPath)
        let sourceData: Data
        do {
            sourceData = try Data(contentsOf: sourceURL)
        } catch {
            throw LumoError.importFailed
        }

        guard Self.canDecodeImage(sourceData) else {
            throw LumoError.importFailed
        }
        guard let image = CIImage(
            data: sourceData,
            options: [
                .applyOrientationProperty: true,
                .colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
            ]
        ) else {
            throw LumoError.importFailed
        }

        let outputFolderURL = processedPhotoFolderURL(filmRollID: request.filmRollID, processedPhotoID: request.processedPhotoID)
        let originalExtension = Self.originalFileExtension(sourceURL: sourceURL, imageData: sourceData)
        let originalURL = outputFolderURL.appendingPathComponent("original.\(originalExtension)")
        let renderedURL = outputFolderURL.appendingPathComponent("rendered.jpg")
        let thumbnailURL = outputFolderURL.appendingPathComponent("thumbnail.jpg")
        let adaptiveMetadata: AdaptiveRenderMetadata?
        if request.isAdaptivePostProcessEnabled,
           let sampleAnalysisPackage = request.sampleAnalysisPackage {
            adaptiveMetadata = try adaptivePostProcessor.metadata(
                forTargetImageData: sourceData,
                samplePackage: sampleAnalysisPackage,
                requestedIntensity: request.intensity
            )
        } else {
            adaptiveMetadata = nil
        }

        do {
            if fileManager.fileExists(atPath: outputFolderURL.path) {
                try fileManager.removeItem(at: outputFolderURL)
            }
            try fileManager.createDirectory(at: outputFolderURL, withIntermediateDirectories: true)
            try sourceData.write(to: originalURL, options: [.atomic])

            let renderedImage = try renderer.render(
                image,
                applying: request.lut,
                intensity: request.intensity,
                size: .fullResolution,
                adaptiveAdjustment: adaptiveMetadata?.adjustment
            )
            try JPEGImageEncoder.encode(renderedImage, quality: renderedJPEGQuality).write(to: renderedURL, options: [.atomic])

            let thumbnailImage = try renderer.render(
                image,
                applying: request.lut,
                intensity: request.intensity,
                size: .thumbnail(maxPixelDimension: thumbnailMaxPixelDimension),
                adaptiveAdjustment: adaptiveMetadata?.adjustment
            )
            try JPEGImageEncoder.encode(thumbnailImage, quality: thumbnailJPEGQuality).write(to: thumbnailURL, options: [.atomic])
        } catch let error as LumoError {
            try? fileManager.removeItem(at: outputFolderURL)
            throw error
        } catch {
            try? fileManager.removeItem(at: outputFolderURL)
            throw LumoError.storageFailed(message: error.localizedDescription)
        }

        let relativeBasePath = "film-rolls/\(request.filmRollID)/processed/\(request.processedPhotoID)"
        return PhotoRenderResult(
            originalPath: "\(relativeBasePath)/original.\(originalExtension)",
            processedPath: "\(relativeBasePath)/rendered.jpg",
            thumbnailPath: "\(relativeBasePath)/thumbnail.jpg",
            intensity: request.intensity,
            adaptiveRenderMetadata: adaptiveMetadata
        )
    }

    func discardRenderedPhoto(_ result: PhotoRenderResult) async {
        guard let folderURL = processedPhotoFolderURL(from: result.processedPath) else {
            return
        }
        guard fileManager.fileExists(atPath: folderURL.path) else {
            return
        }
        try? fileManager.removeItem(at: folderURL)
    }

    private static func canDecodeImage(_ imageData: Data) -> Bool {
        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
            return false
        }
        return CGImageSourceGetCount(imageSource) > 0 && CGImageSourceGetType(imageSource) != nil
    }

    private func sourceURL(for path: String) -> URL {
        if path.hasPrefix("file://"), let fileURL = URL(string: path), fileURL.isFileURL {
            return fileURL
        }
        if path.hasPrefix("/") {
            return URL(fileURLWithPath: path)
        }
        return assetStore.rootURL.appendingPathComponent(path)
    }

    private func processedPhotoFolderURL(filmRollID: String, processedPhotoID: String) -> URL {
        assetStore.filmRollFolderURL(for: filmRollID)
            .appendingPathComponent("processed", isDirectory: true)
            .appendingPathComponent(processedPhotoID, isDirectory: true)
    }

    private func processedPhotoFolderURL(from processedPath: String) -> URL? {
        let components = processedPath.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard components.count == 5,
              components[0] == "film-rolls",
              Self.isPathSafeComponent(components[1]),
              components[2] == "processed",
              Self.isPathSafeComponent(components[3]),
              !components[4].isEmpty,
              components[4] != ".",
              components[4] != ".." else {
            return nil
        }

        return processedPhotoFolderURL(filmRollID: components[1], processedPhotoID: components[3])
    }

    private static func originalFileExtension(sourceURL: URL, imageData: Data) -> String {
        if let pathExtension = safeFileExtension(sourceURL.pathExtension) {
            return pathExtension
        }

        guard let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
              let type = CGImageSourceGetType(imageSource) as String? else {
            return "img"
        }

        switch type {
        case "public.jpeg":
            return "jpg"
        case "public.png":
            return "png"
        case "public.heic", "public.heif":
            return "heic"
        default:
            return "img"
        }
    }

    private static func safeFileExtension(_ fileExtension: String?) -> String? {
        guard let fileExtension else {
            return nil
        }
        let trimmed = fileExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
        guard (1...8).contains(trimmed.count),
              trimmed.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) else {
            return nil
        }
        return trimmed == "jpeg" ? "jpg" : trimmed
    }

    private static func isPathSafeComponent(_ value: String) -> Bool {
        !value.isEmpty
            && value.range(of: #"^[A-Za-z0-9-]+$"#, options: .regularExpression) != nil
    }
}
