import XCTest
@testable import LumoRoll

final class FilmRollDisplayDataTests: XCTestCase {
    func testDisplayDataMapsRollMetadataWithoutLoadingImages() throws {
        let roll = try displayDataRoll()

        let displayData = FilmRollDisplayData(filmRoll: roll)

        XCTAssertEqual(displayData.id, "roll-display")
        XCTAssertEqual(displayData.name, "Display Roll")
        XCTAssertEqual(displayData.processedPhotoCount, 2)
        XCTAssertEqual(displayData.createdDateText, "May 23")
        XCTAssertNil(displayData.referencePhoto.image)
        XCTAssertEqual(displayData.referencePhoto.label, "Sample")
        XCTAssertEqual(displayData.referencePhoto.thumbnailRelativePath, "reference/thumb.jpg")
        XCTAssertEqual(displayData.referencePhoto.fullSizeRelativePath, "reference/original.jpg")
        XCTAssertEqual(displayData.processedPhotos.map(\.label), ["01", "02"])
        XCTAssertEqual(displayData.processedPhotos.map(\.thumbnailRelativePath), ["thumb/1.jpg", "thumb/2.jpg"])
        XCTAssertEqual(displayData.processedPhotos.map(\.fullSizeRelativePath), ["processed/1.jpg", "processed/2.jpg"])
    }

    func testViewerFramesKeepReferenceSampleFirst() throws {
        let roll = try displayDataRoll()

        let frames = FilmRollViewerFrame.frames(for: roll)

        XCTAssertEqual(frames.map(\.kind), [.reference, .processed, .processed])
        XCTAssertEqual(frames.map(\.displayLabel), ["Sample", "Frame 01", "Frame 02"])
        XCTAssertEqual(frames.map(\.photo.id), ["roll-display-reference", "processed-1", "processed-2"])
        XCTAssertEqual(frames.map(\.photo.thumbnailRelativePath), ["reference/thumb.jpg", "thumb/1.jpg", "thumb/2.jpg"])
        XCTAssertEqual(frames.map(\.photo.fullSizeRelativePath), ["reference/original.jpg", "processed/1.jpg", "processed/2.jpg"])
    }
}

private func displayDataRoll() throws -> FilmRoll {
    try FilmRoll(
        id: "roll-display",
        name: "Display Roll",
        createdAt: Date(timeIntervalSince1970: 1_716_460_000),
        referenceAsset: FilmRollReferenceAsset(
            originalPath: "reference/original.jpg",
            thumbnailPath: "reference/thumb.jpg"
        ),
        lut: LUT3D.identity(),
        palette: [
            FilmRollPaletteColor(id: "peach", red: 0.9, green: 0.6, blue: 0.4)
        ],
        processedPhotos: [
            ProcessedPhoto(
                id: "processed-1",
                originalPath: "original/1.jpg",
                processedPath: "processed/1.jpg",
                thumbnailPath: "thumb/1.jpg",
                createdAt: Date(timeIntervalSince1970: 1_716_470_000),
                intensity: 80
            ),
            ProcessedPhoto(
                id: "processed-2",
                originalPath: "original/2.jpg",
                processedPath: "processed/2.jpg",
                thumbnailPath: "thumb/2.jpg",
                createdAt: Date(timeIntervalSince1970: 1_716_480_000),
                intensity: 65
            )
        ]
    )
}
