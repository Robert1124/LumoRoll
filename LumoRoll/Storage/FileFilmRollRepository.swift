import Foundation

actor FileFilmRollRepository: FilmRollRepository {
    private let assetStore: AssetStore
    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(assetStore: AssetStore, fileManager: FileManager = .default) {
        self.assetStore = assetStore
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    func loadFilmRolls() async throws -> [FilmRoll] {
        try assetStore.prepareRoot(fileManager: fileManager)

        let rollFolderURLs = try fileManager.contentsOfDirectory(
            at: assetStore.filmRollsURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles]
        )

        let filmRolls = try rollFolderURLs
            .filter { try isDirectory(at: $0) }
            .compactMap { folderURL -> FilmRoll? in
                let manifestURL = folderURL.appendingPathComponent("manifest.json")
                guard fileManager.fileExists(atPath: manifestURL.path) else {
                    return nil
                }
                return try loadManifest(at: manifestURL).filmRoll
            }

        return filmRolls.sorted { $0.createdAt > $1.createdAt }
    }

    func loadFilmRoll(id: String) async throws -> FilmRoll {
        let manifestURL = assetStore.manifestURL(for: id)
        guard fileManager.fileExists(atPath: manifestURL.path) else {
            throw LumoError.filmRollNotFound(id: id)
        }

        return try loadManifest(at: manifestURL).filmRoll
    }

    func saveFilmRoll(_ filmRoll: FilmRoll) async throws {
        do {
            try assetStore.prepareRoot(fileManager: fileManager)
            let rollFolderURL = assetStore.filmRollFolderURL(for: filmRoll.id)
            try fileManager.createDirectory(at: rollFolderURL, withIntermediateDirectories: true)

            let manifest = FilmRollManifest(filmRoll: filmRoll)
            let data = try encoder.encode(manifest)
            try data.write(to: assetStore.manifestURL(for: filmRoll.id), options: [.atomic])
        } catch let error as LumoError {
            throw error
        } catch {
            throw LumoError.storageFailed(message: error.localizedDescription)
        }
    }

    func deleteFilmRoll(id: String) async throws {
        let rollFolderURL = assetStore.filmRollFolderURL(for: id)
        guard fileManager.fileExists(atPath: rollFolderURL.path) else {
            throw LumoError.filmRollNotFound(id: id)
        }

        do {
            try fileManager.removeItem(at: rollFolderURL)
        } catch {
            throw LumoError.storageFailed(message: error.localizedDescription)
        }
    }

    private func loadManifest(at url: URL) throws -> FilmRollManifest {
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(FilmRollManifest.self, from: data)
        } catch {
            throw LumoError.storageFailed(message: error.localizedDescription)
        }
    }

    private func isDirectory(at url: URL) throws -> Bool {
        let values = try url.resourceValues(forKeys: [.isDirectoryKey])
        return values.isDirectory == true
    }
}
