import Foundation

enum AppRoute: Hashable {
    case createFilmRoll
    case filmRollDetail(id: String)
    case applyPhoto(
        filmRollID: String,
        initialImportSource: ApplyTargetImportSource?,
        initialTargetPhotoPath: String? = nil,
        editContext: ApplyPhotoEditContext? = nil
    )
}

struct ApplyPhotoEditContext: Hashable, Sendable {
    let processedPhotoID: String
    let originalPhotoPath: String
    let intensity: Double
}

struct FullscreenViewerRoute: Identifiable, Equatable {
    let filmRoll: FilmRoll
    let startIndex: Int

    var id: String {
        "\(filmRoll.id)-\(startIndex)"
    }
}
