import Foundation
import ImageIO
import UniformTypeIdentifiers

struct StagedPhotoImport: Equatable, Sendable {
    let id: String
    let relativePath: String
    let preferredFileExtension: String
    let originalFilename: String?
}

actor PhotoImportStagingService {
    private static let validationThumbnailMaxPixelDimension = 128

    private let resolver: AppAssetURLResolver
    private let fileManager: FileManager
    private let idGenerator: @Sendable () -> String

    init(
        assetStore: AssetStore,
        fileManager: FileManager = .default,
        idGenerator: @escaping @Sendable () -> String = { UUID().uuidString }
    ) {
        self.resolver = AppAssetURLResolver(assetStore: assetStore)
        self.fileManager = fileManager
        self.idGenerator = idGenerator
    }

    func stageImageData(
        _ data: Data,
        preferredFileExtension: String?,
        originalFilename: String? = nil
    ) async throws -> StagedPhotoImport {
        let imageInfo = try Self.validateStillImage(data: data, preferredFileExtension: preferredFileExtension)
        return try writeStagedImage(
            data,
            preferredFileExtension: imageInfo.fileExtension,
            originalFilename: originalFilename
        )
    }

    func stageImageFile(at fileURL: URL) async throws -> StagedPhotoImport {
        guard fileURL.isFileURL else {
            throw LumoError.importFailed
        }

        let didStartAccessing = fileURL.startAccessingSecurityScopedResource()
        defer {
            if didStartAccessing {
                fileURL.stopAccessingSecurityScopedResource()
            }
        }

        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw LumoError.importFailed
        }

        let imageInfo = try Self.validateStillImage(data: data, preferredFileExtension: fileURL.pathExtension)
        return try writeStagedImage(
            data,
            preferredFileExtension: imageInfo.fileExtension,
            originalFilename: fileURL.lastPathComponent
        )
    }

    func discardStagedImport(relativePath: String) async {
        let components = relativePath.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard components.count >= 4,
              components[0] == "tmp",
              components[1] == "imports",
              Self.isPathSafeID(components[2]) else {
            return
        }

        let importFolderPath = "tmp/imports/\(components[2])"
        guard let importFolderURL = try? resolver.resolve(importFolderPath),
              fileManager.fileExists(atPath: importFolderURL.path) else {
            return
        }
        try? fileManager.removeItem(at: importFolderURL)
    }

    private func writeStagedImage(
        _ data: Data,
        preferredFileExtension: String,
        originalFilename: String?
    ) throws -> StagedPhotoImport {
        let importID = idGenerator()
        guard Self.isPathSafeID(importID) else {
            throw LumoError.importFailed
        }

        let relativePath = "tmp/imports/\(importID)/original.\(preferredFileExtension)"
        let destinationURL = try resolver.resolve(relativePath)
        let importFolderURL = destinationURL.deletingLastPathComponent()

        do {
            try fileManager.createDirectory(
                at: importFolderURL,
                withIntermediateDirectories: true
            )
            try data.write(to: destinationURL, options: [.atomic])
        } catch {
            try? fileManager.removeItem(at: importFolderURL)
            throw LumoError.importFailed
        }

        return StagedPhotoImport(
            id: importID,
            relativePath: relativePath,
            preferredFileExtension: preferredFileExtension,
            originalFilename: Self.cleanedOriginalFilename(originalFilename)
        )
    }

    private static func validateStillImage(
        data: Data,
        preferredFileExtension: String?
    ) throws -> (fileExtension: String, typeIdentifier: String) {
        let sourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, sourceOptions),
              CGImageSourceGetCount(imageSource) == 1,
              let typeIdentifier = CGImageSourceGetType(imageSource) as String?,
              let detectedExtension = allowedFileExtension(forTypeIdentifier: typeIdentifier) else {
            throw LumoError.importFailed
        }
        try validateImageProperties(imageSource)
        try validateThumbnailDecode(imageSource)

        if let safeExtension = try safePreferredFileExtension(preferredFileExtension) {
            guard allowedFileExtensions.contains(safeExtension),
                  isFileExtension(safeExtension, compatibleWith: detectedExtension) else {
                throw LumoError.importFailed
            }
            return (safeExtension, typeIdentifier)
        }

        return (detectedExtension, typeIdentifier)
    }

    private static func validateImageProperties(_ imageSource: CGImageSource) throws {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any],
              let pixelWidth = properties[kCGImagePropertyPixelWidth] as? Int,
              let pixelHeight = properties[kCGImagePropertyPixelHeight] as? Int,
              pixelWidth > 0,
              pixelHeight > 0 else {
            throw LumoError.importFailed
        }
    }

    private static func validateThumbnailDecode(_ imageSource: CGImageSource) throws {
        let thumbnailOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceShouldCacheImmediately: false,
            kCGImageSourceThumbnailMaxPixelSize: validationThumbnailMaxPixelDimension
        ] as CFDictionary
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, thumbnailOptions),
              thumbnail.width > 0,
              thumbnail.height > 0,
              max(thumbnail.width, thumbnail.height) <= validationThumbnailMaxPixelDimension else {
            throw LumoError.importFailed
        }
    }

    private static func cleanedOriginalFilename(_ filename: String?) -> String? {
        guard let filename else {
            return nil
        }
        let trimmed = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private static func safePreferredFileExtension(_ fileExtension: String?) throws -> String? {
        guard let fileExtension else {
            return nil
        }

        let trimmed = fileExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "."))
            .lowercased()
        guard !trimmed.isEmpty else {
            return nil
        }

        guard (1...8).contains(trimmed.count),
              trimmed.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber) }) else {
            throw LumoError.importFailed
        }

        return trimmed == "jpeg" ? "jpg" : trimmed
    }

    private static func allowedFileExtension(forTypeIdentifier typeIdentifier: String) -> String? {
        guard let type = UTType(typeIdentifier) else {
            return nil
        }

        if type.conforms(to: .jpeg) {
            return "jpg"
        }
        if type.conforms(to: .png) {
            return "png"
        }
        if let heicType = UTType("public.heic"), type.conforms(to: heicType) {
            return "heic"
        }
        if let heifType = UTType("public.heif"), type.conforms(to: heifType) {
            return "heif"
        }
        return nil
    }

    private static func isFileExtension(_ fileExtension: String, compatibleWith detectedExtension: String) -> Bool {
        if detectedExtension == "heic" || detectedExtension == "heif" {
            return fileExtension == "heic" || fileExtension == "heif"
        }
        return fileExtension == detectedExtension
    }

    private static var allowedFileExtensions: Set<String> {
        ["heic", "heif", "jpg", "png"]
    }

    private static func isPathSafeID(_ value: String) -> Bool {
        !value.isEmpty
            && value.range(of: #"^[A-Za-z0-9-]+$"#, options: .regularExpression) != nil
    }
}
