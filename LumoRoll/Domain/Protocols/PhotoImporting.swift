import Foundation

struct ImportedPhoto: Codable, Equatable, Identifiable, Sendable {
    let id: String
    let originalPath: String
    let thumbnailPath: String

    init(id: String = UUID().uuidString, originalPath: String, thumbnailPath: String) {
        self.id = id
        self.originalPath = originalPath
        self.thumbnailPath = thumbnailPath
    }
}

protocol PhotoImporting: Sendable {
    func importPhoto() async throws -> ImportedPhoto
}
