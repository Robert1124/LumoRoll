import Foundation

struct AppAssetURLResolver: Sendable {
    private let assetStore: AssetStore

    init(assetStore: AssetStore) {
        self.assetStore = assetStore
    }

    func resolve(_ relativePath: String) throws -> URL {
        let components = try validatedComponents(from: relativePath)
        let rootURL = normalizedRootURL()
        let resolvedURL = components.reduce(rootURL) { partialURL, component in
            partialURL.appendingPathComponent(component)
        }
        let normalizedURL = resolvedURL.standardizedFileURL

        guard normalizedURL.isContained(in: rootURL) else {
            throw LumoError.storageFailed(message: "Asset path must stay inside app storage.")
        }

        return normalizedURL
    }

    func relativePath(for url: URL) throws -> String {
        guard url.isFileURL else {
            throw LumoError.storageFailed(message: "Asset URL must be a file URL.")
        }

        let rootURL = normalizedRootURL()
        let normalizedURL = url.standardizedFileURL
        guard normalizedURL.isContained(in: rootURL), normalizedURL.path != rootURL.path else {
            throw LumoError.storageFailed(message: "Asset URL must stay inside app storage.")
        }

        let rootPrefix = rootURL.path.hasSuffix("/") ? rootURL.path : "\(rootURL.path)/"
        let relativePath = String(normalizedURL.path.dropFirst(rootPrefix.count))
        _ = try validatedComponents(from: relativePath)
        return relativePath
    }

    private func normalizedRootURL() -> URL {
        assetStore.rootURL.standardizedFileURL
    }

    private func validatedComponents(from relativePath: String) throws -> [String] {
        guard !relativePath.isEmpty,
              !relativePath.hasPrefix("/"),
              !relativePath.lowercased().hasPrefix("file://"),
              !relativePath.contains("\\") else {
            throw LumoError.storageFailed(message: "Invalid app asset path.")
        }

        let components = relativePath.split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard !components.isEmpty,
              components.allSatisfy(Self.isSafePathComponent) else {
            throw LumoError.storageFailed(message: "Invalid app asset path component.")
        }
        return components
    }

    private static func isSafePathComponent(_ component: String) -> Bool {
        guard !component.isEmpty,
              component != ".",
              component != "..",
              !component.contains("..") else {
            return false
        }

        return component.range(of: #"^[A-Za-z0-9][A-Za-z0-9._-]*$"#, options: .regularExpression) != nil
    }
}

struct AssetStoreReferenceImageDataLoader: FilmRollReferenceImageDataLoading {
    private let resolver: AppAssetURLResolver

    init(assetStore: AssetStore) {
        resolver = AppAssetURLResolver(assetStore: assetStore)
    }

    func loadReferenceImageData(at path: String) async throws -> Data {
        let url = try resolver.resolve(path)
        return try Data(contentsOf: url)
    }
}

private extension URL {
    func isContained(in rootURL: URL) -> Bool {
        if path == rootURL.path {
            return true
        }
        let rootPrefix = rootURL.path.hasSuffix("/") ? rootURL.path : "\(rootURL.path)/"
        return path.hasPrefix(rootPrefix)
    }
}
