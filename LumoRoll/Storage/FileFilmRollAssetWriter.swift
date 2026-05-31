import Foundation

actor FileFilmRollAssetWriter: FilmRollAssetWriting {
    private let assetStore: AssetStore
    private let fileManager: FileManager

    init(assetStore: AssetStore, fileManager: FileManager = .default) {
        self.assetStore = assetStore
        self.fileManager = fileManager
    }

    func reserveFilmRollID() async throws -> String {
        assetStore.generateRollID(forDisplayName: "")
    }

    func storeReferenceImage(
        filmRollID: String,
        imageData: Data,
        thumbnailData: Data,
        preferredFileExtension: String?
    ) async throws -> FilmRollReferenceAsset {
        guard Self.isPathSafeComponent(filmRollID) else {
            throw LumoError.storageFailed(message: "Invalid Film Roll asset ID.")
        }

        let originalExtension = Self.safeFileExtension(preferredFileExtension) ?? "img"
        let referenceFolderURL = assetStore.filmRollFolderURL(for: filmRollID)
            .appendingPathComponent("reference", isDirectory: true)
        let originalURL = referenceFolderURL.appendingPathComponent("original.\(originalExtension)")
        let thumbnailURL = referenceFolderURL.appendingPathComponent("thumbnail.jpg")

        do {
            try assetStore.prepareRoot(fileManager: fileManager)
            try fileManager.createDirectory(at: referenceFolderURL, withIntermediateDirectories: true)
            try imageData.write(to: originalURL, options: [.atomic])
            try thumbnailData.write(to: thumbnailURL, options: [.atomic])
        } catch let error as LumoError {
            throw error
        } catch {
            throw LumoError.storageFailed(message: error.localizedDescription)
        }

        return FilmRollReferenceAsset(
            originalPath: "film-rolls/\(filmRollID)/reference/original.\(originalExtension)",
            thumbnailPath: "film-rolls/\(filmRollID)/reference/thumbnail.jpg"
        )
    }

    func discardFilmRollAssets(filmRollID: String) async {
        guard Self.isPathSafeComponent(filmRollID) else {
            return
        }
        let rollFolderURL = assetStore.filmRollFolderURL(for: filmRollID)
        guard fileManager.fileExists(atPath: rollFolderURL.path) else {
            return
        }
        try? fileManager.removeItem(at: rollFolderURL)
    }

    func writeCubeExport(filmRollID: String, cubeText: String, suggestedFilename: String) async throws -> URL {
        guard Self.isPathSafeComponent(filmRollID) else {
            throw LumoError.storageFailed(message: "Invalid Film Roll asset ID.")
        }

        let lutFolderURL = assetStore.filmRollFolderURL(for: filmRollID)
            .appendingPathComponent("lut", isDirectory: true)
        let exportURL = lutFolderURL.appendingPathComponent("export.cube")

        do {
            try assetStore.prepareRoot(fileManager: fileManager)
            try fileManager.createDirectory(at: lutFolderURL, withIntermediateDirectories: true)
            try cubeText.write(to: exportURL, atomically: true, encoding: .utf8)
        } catch let error as LumoError {
            throw error
        } catch {
            throw LumoError.storageFailed(message: error.localizedDescription)
        }

        return exportURL
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
