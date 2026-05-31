import SwiftUI

enum LumoPreviewFixtures {
    static let palette = [
        FilmRollPaletteColor(id: "peach", red: 0.91, green: 0.61, blue: 0.48),
        FilmRollPaletteColor(id: "butter", red: 0.91, green: 0.76, blue: 0.42),
        FilmRollPaletteColor(id: "sage", red: 0.66, green: 0.72, blue: 0.60),
        FilmRollPaletteColor(id: "dusk", red: 0.48, green: 0.52, blue: 0.63),
        FilmRollPaletteColor(id: "plum", red: 0.54, green: 0.44, blue: 0.53)
    ]

    static let referencePhoto = LumoPhotoDisplayData(
        id: "reference",
        label: "Sample",
        image: referenceImage,
        accessibilityLabel: "Reference sample"
    )

    static let processedPhotos = [
        LumoPhotoDisplayData(id: "processed-1", label: "01", image: processedImage, accessibilityLabel: "Processed photo 1"),
        LumoPhotoDisplayData(id: "processed-2", label: "02", image: alternateImage, accessibilityLabel: "Processed photo 2")
    ]

    static let filmStripItems = FilmStripItem.orderedItems(
        reference: referencePhoto,
        processed: processedPhotos,
        includesAddPhoto: true
    )

    static var referenceImage: Image {
        Image(systemName: "photo")
    }

    static var processedImage: Image {
        Image(systemName: "camera.filters")
    }

    static var alternateImage: Image {
        Image(systemName: "square.stack.3d.up")
    }
}
