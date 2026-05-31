import Foundation

protocol PhotoLibraryWriting: Sendable {
    func savePhotoToLibrary(processedPath: String) async throws -> String
}
