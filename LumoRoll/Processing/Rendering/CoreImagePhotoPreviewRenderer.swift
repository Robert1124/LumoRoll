import CoreGraphics
import CoreImage
import Foundation
import ImageIO

actor CoreImagePhotoPreviewRenderer: PhotoPreviewRendering {
    private let assetStore: AssetStore
    private let fileManager: FileManager
    private let renderer: CoreImageRenderer
    private let adaptivePostProcessor: AdaptivePostProcessor
    private let previewJPEGQuality: CGFloat

    init(
        assetStore: AssetStore,
        fileManager: FileManager = .default,
        renderer: CoreImageRenderer = CoreImageRenderer(),
        adaptivePostProcessor: AdaptivePostProcessor = AdaptivePostProcessor(),
        previewJPEGQuality: CGFloat = 0.86
    ) {
        self.assetStore = assetStore
        self.fileManager = fileManager
        self.renderer = renderer
        self.adaptivePostProcessor = adaptivePostProcessor
        self.previewJPEGQuality = previewJPEGQuality
    }

    func renderPreview(for request: PhotoPreviewRenderRequest) async throws -> PhotoPreviewRenderResult {
        guard Self.isPathSafeComponent(request.previewID) else {
            throw LumoError.storageFailed(message: "Invalid preview asset ID.")
        }

        let sourceURL = sourceURL(for: request.originalPath)
        let sourceData: Data
        do {
            sourceData = try Data(contentsOf: sourceURL)
        } catch {
            throw LumoError.importFailed
        }

        guard Self.canDecodeImage(sourceData),
              let image = CIImage(
                data: sourceData,
                options: [
                    .applyOrientationProperty: true,
                    .colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!
                ]
              ) else {
            throw LumoError.importFailed
        }

        let outputFolderURL = previewFolderURL(previewID: request.previewID)
        let previewURL = outputFolderURL.appendingPathComponent("preview.jpg")
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
            let previewImage = try renderer.render(
                image,
                applying: request.lut,
                intensity: request.intensity,
                size: .preview(maxPixelDimension: request.maxPixelDimension),
                adaptiveAdjustment: adaptiveMetadata?.adjustment
            )
            try JPEGImageEncoder.encode(previewImage, quality: previewJPEGQuality).write(to: previewURL, options: [.atomic])
        } catch let error as LumoError {
            try? fileManager.removeItem(at: outputFolderURL)
            throw error
        } catch {
            try? fileManager.removeItem(at: outputFolderURL)
            throw LumoError.storageFailed(message: error.localizedDescription)
        }

        return PhotoPreviewRenderResult(
            previewID: request.previewID,
            originalPath: request.originalPath,
            previewPath: "tmp/apply-previews/\(request.previewID)/preview.jpg",
            intensity: request.intensity,
            adaptiveRenderMetadata: adaptiveMetadata
        )
    }

    func discardRenderedPreview(at relativePath: String) async {
        guard let folderURL = previewFolderURL(from: relativePath),
              fileManager.fileExists(atPath: folderURL.path) else {
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

    private func previewFolderURL(previewID: String) -> URL {
        assetStore.rootURL
            .appendingPathComponent("tmp", isDirectory: true)
            .appendingPathComponent("apply-previews", isDirectory: true)
            .appendingPathComponent(previewID, isDirectory: true)
    }

    private func previewFolderURL(from relativePath: String) -> URL? {
        let components = relativePath.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard components.count == 4,
              components[0] == "tmp",
              components[1] == "apply-previews",
              Self.isPathSafeComponent(components[2]),
              components[3] == "preview.jpg" else {
            return nil
        }
        return previewFolderURL(previewID: components[2])
    }

    private static func isPathSafeComponent(_ value: String) -> Bool {
        !value.isEmpty
            && value.range(of: #"^[A-Za-z0-9-]+$"#, options: .regularExpression) != nil
    }
}
