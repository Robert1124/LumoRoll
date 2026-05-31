import Foundation
import SwiftUI

struct FilmRollDisplayData: Identifiable {
    let id: String
    let name: String
    let createdDateText: String
    let processedPhotoCount: Int
    let palette: [FilmRollPaletteColor]
    let referencePhoto: LumoPhotoDisplayData
    let processedPhotos: [LumoPhotoDisplayData]

    init(filmRoll: FilmRoll) {
        id = filmRoll.id
        name = filmRoll.name
        createdDateText = Self.createdDateFormatter.string(from: filmRoll.createdAt)
        processedPhotoCount = filmRoll.processedPhotos.count
        palette = filmRoll.palette
        referencePhoto = LumoPhotoDisplayData(
            id: "\(filmRoll.id)-reference",
            label: "Sample",
            image: nil,
            thumbnailRelativePath: filmRoll.referenceAsset.thumbnailPath,
            fullSizeRelativePath: filmRoll.referenceAsset.originalPath,
            accessibilityLabel: "\(filmRoll.name) reference sample"
        )
        processedPhotos = filmRoll.processedPhotos.enumerated().map { index, photo in
            LumoPhotoDisplayData(
                id: photo.id,
                label: String(format: "%02d", index + 1),
                image: nil,
                thumbnailRelativePath: photo.thumbnailPath,
                fullSizeRelativePath: photo.processedPath,
                accessibilityLabel: "\(filmRoll.name) processed photo \(index + 1)"
            )
        }
    }

    private static let createdDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "MMM d"
        return formatter
    }()
}

struct FilmRollViewerFrame: Identifiable, Equatable {
    enum Kind: Equatable {
        case reference
        case processed
    }

    let id: String
    let kind: Kind
    let displayLabel: String
    let photo: LumoPhotoDisplayData

    static func frames(for filmRoll: FilmRoll) -> [FilmRollViewerFrame] {
        let displayData = FilmRollDisplayData(filmRoll: filmRoll)
        var frames = [
            FilmRollViewerFrame(
                id: displayData.referencePhoto.id,
                kind: .reference,
                displayLabel: "Sample",
                photo: displayData.referencePhoto
            )
        ]

        frames.append(contentsOf: displayData.processedPhotos.enumerated().map { index, photo in
            FilmRollViewerFrame(
                id: photo.id,
                kind: .processed,
                displayLabel: "Frame \(String(format: "%02d", index + 1))",
                photo: photo
            )
        })

        return frames
    }
}

extension FilmRollViewerFrame {
    static func == (lhs: FilmRollViewerFrame, rhs: FilmRollViewerFrame) -> Bool {
        lhs.id == rhs.id
            && lhs.kind == rhs.kind
            && lhs.displayLabel == rhs.displayLabel
            && lhs.photo.id == rhs.photo.id
            && lhs.photo.label == rhs.photo.label
            && lhs.photo.accessibilityLabel == rhs.photo.accessibilityLabel
    }
}
