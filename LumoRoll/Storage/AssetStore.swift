import Foundation

struct AssetStore: Sendable {
    let baseURL: URL

    var rootURL: URL {
        baseURL.appendingPathComponent("LumoRoll", isDirectory: true)
    }

    var filmRollsURL: URL {
        rootURL.appendingPathComponent("film-rolls", isDirectory: true)
    }

    init(baseURL: URL) {
        self.baseURL = baseURL
    }

    func prepareRoot(fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(at: filmRollsURL, withIntermediateDirectories: true)
    }

    func generateRollID(forDisplayName displayName: String) -> String {
        UUID().uuidString
    }

    func filmRollFolderURL(for id: String) -> URL {
        filmRollsURL.appendingPathComponent(id, isDirectory: true)
    }

    func manifestURL(for id: String) -> URL {
        filmRollFolderURL(for: id).appendingPathComponent("manifest.json")
    }
}
