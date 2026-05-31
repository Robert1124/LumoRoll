import XCTest
@testable import LumoRoll

final class DesignSystemHelperTests: XCTestCase {
    func testPaletteColorConvertsClampedRGBComponentsToHex() {
        let color = FilmRollPaletteColor(red: 1.2, green: 0.5, blue: -0.1)

        XCTAssertEqual(LumoTheme.paletteHex(for: color), "#FF8000")
    }

    func testFilmStripItemsOrderReferenceProcessedAndAddPhoto() {
        let processed = [
            LumoPhotoDisplayData(id: "processed-1", label: "01", image: nil, accessibilityLabel: "Warm portrait"),
            LumoPhotoDisplayData(id: "processed-2", label: "02", image: nil, accessibilityLabel: "Soft street frame")
        ]

        let items = FilmStripItem.orderedItems(
            reference: LumoPhotoDisplayData(id: "reference", label: "Sample", image: nil, accessibilityLabel: "Golden reference"),
            processed: processed,
            includesAddPhoto: true
        )

        XCTAssertEqual(items.map(\.kind), [.reference, .processed, .processed, .addPhoto])
        XCTAssertEqual(items.map(\.id), ["reference", "processed-1", "processed-2", "add-photo"])
        XCTAssertEqual(items.first?.accessibilityLabel, "Golden reference, Photo unavailable")
        XCTAssertEqual(items[1].accessibilityLabel, "Warm portrait, Photo unavailable")
        XCTAssertEqual(items.last?.accessibilityLabel, "Add photo")
    }

    func testLumoIntensityClampBoundsValuesToPercentRange() {
        XCTAssertEqual(LumoIntensity.clamped(-10), 0)
        XCTAssertEqual(LumoIntensity.clamped(42.5), 42.5)
        XCTAssertEqual(LumoIntensity.clamped(140), 100)
    }

    func testSplitPreviewPositionClampsFractionsAndConvertsDragLocations() {
        XCTAssertEqual(LumoSplitPosition.clampedFraction(-0.4), 0.08)
        XCTAssertEqual(LumoSplitPosition.clampedFraction(0.5), 0.5)
        XCTAssertEqual(LumoSplitPosition.clampedFraction(1.4), 0.92)
        XCTAssertEqual(LumoSplitPosition.fraction(forLocationX: 30, width: 120), 0.25)
        XCTAssertEqual(LumoSplitPosition.fraction(forLocationX: -20, width: 120), 0.08)
        XCTAssertEqual(LumoSplitPosition.fraction(forLocationX: 200, width: 120), 0.92)
        XCTAssertEqual(LumoSplitPosition.fraction(forLocationX: 20, width: 0), 0.5)
    }

    func testSplitPreviewPositionAccessibilityTextUsesPercent() {
        XCTAssertEqual(LumoSplitPosition.accessibilityValue(for: 0.254), "25 percent before")
        XCTAssertEqual(LumoSplitPosition.accessibilityHint, "Swipe up or down to move the comparison line.")
    }

    func testIntensityAccessibilityTextDescribesBlendBehavior() {
        XCTAssertEqual(LumoIntensity.accessibilityValue(for: 72.4), "72 percent Film Roll")
        XCTAssertEqual(LumoIntensity.accessibilityHint, "Adjusts the blend between the original photo and the Film Roll result.")
    }

    func testPreviewAspectRatioUsesLoadedImageRatioAndFallsBackForInvalidValues() {
        XCTAssertEqual(LumoPreviewAspectRatio.sanitized(4.0 / 3.0), 4.0 / 3.0)
        XCTAssertEqual(LumoPreviewAspectRatio.sanitized(nil), LumoPreviewAspectRatio.fallback)
        XCTAssertEqual(LumoPreviewAspectRatio.sanitized(0), LumoPreviewAspectRatio.fallback)
        XCTAssertEqual(LumoPreviewAspectRatio.sanitized(.infinity), LumoPreviewAspectRatio.fallback)
    }
}
