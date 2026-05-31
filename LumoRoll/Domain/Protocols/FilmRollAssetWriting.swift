import Foundation

protocol FilmRollAssetWriting: Sendable {
    func reserveFilmRollID() async throws -> String

    func storeReferenceImage(
        filmRollID: String,
        imageData: Data,
        thumbnailData: Data,
        preferredFileExtension: String?
    ) async throws -> FilmRollReferenceAsset

    func discardFilmRollAssets(filmRollID: String) async

    func writeCubeExport(filmRollID: String, cubeText: String, suggestedFilename: String) async throws -> URL
}
