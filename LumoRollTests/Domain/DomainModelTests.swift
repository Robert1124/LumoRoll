import XCTest
@testable import LumoRoll

final class DomainModelTests: XCTestCase {
    func testFilmRollRejectsEmptyAndWhitespaceNames() {
        let referenceAsset = FilmRollReferenceAsset(
            originalPath: "film-rolls/roll-1/reference/original.heic",
            thumbnailPath: "film-rolls/roll-1/reference/thumb.jpg"
        )
        let lut = LUT3D.identity()

        XCTAssertThrowsError(try FilmRoll(name: "", referenceAsset: referenceAsset, lut: lut)) { error in
            XCTAssertEqual(error as? LumoError, .invalidFilmRollName)
        }

        XCTAssertThrowsError(try FilmRoll(name: "   \n\t", referenceAsset: referenceAsset, lut: lut)) { error in
            XCTAssertEqual(error as? LumoError, .invalidFilmRollName)
        }
    }

    func testFilmRollStoresExactlyOneReferenceAssetInMVP1() throws {
        let referenceAsset = FilmRollReferenceAsset(
            originalPath: "film-rolls/roll-1/reference/original.heic",
            thumbnailPath: "film-rolls/roll-1/reference/thumb.jpg"
        )

        let roll = try FilmRoll(name: "Portra Morning", referenceAsset: referenceAsset, lut: .identity())

        XCTAssertEqual(roll.referenceAsset, referenceAsset)
        XCTAssertEqual(roll.referenceAsset.originalPath, "film-rolls/roll-1/reference/original.heic")
        XCTAssertEqual(roll.referenceAsset.thumbnailPath, "film-rolls/roll-1/reference/thumb.jpg")
    }

    func testLUT3DDefaultSizeIs33AndSampleCountIs35937() {
        let lut = LUT3D.identity()

        XCTAssertEqual(lut.size, 33)
        XCTAssertEqual(lut.sampleCount, 35_937)
        XCTAssertEqual(lut.values.count, 35_937 * 3)
    }

    func testLUT3DRejectsInvalidSampleCounts() {
        XCTAssertThrowsError(try LUT3D(size: 33, values: [0, 0, 0, 1], algorithmVersion: "test")) { error in
            XCTAssertEqual(error as? LumoError, .invalidLUTSampleCount(expected: 35_937 * 3, actual: 4))
        }
    }

    func testProcessedPhotoClampsIntensityToZeroThroughOneHundred() {
        let low = ProcessedPhoto(
            originalPath: "imports/original.jpg",
            processedPath: "processed/low.jpg",
            thumbnailPath: "processed/low-thumb.jpg",
            intensity: -20
        )
        let high = ProcessedPhoto(
            originalPath: "imports/original.jpg",
            processedPath: "processed/high.jpg",
            thumbnailPath: "processed/high-thumb.jpg",
            intensity: 125
        )

        XCTAssertEqual(low.intensity, 0)
        XCTAssertEqual(high.intensity, 100)
    }

    func testFilmRollAndProcessedPhotoStoreModelAssistedMetadata() throws {
        let samplePackage = modelAssistedTestSampleAnalysisPackage()
        let adaptiveMetadata = modelAssistedTestAdaptiveRenderMetadata()
        let processedPhoto = ProcessedPhoto(
            originalPath: "imports/original.jpg",
            processedPath: "processed/rendered.jpg",
            thumbnailPath: "processed/thumb.jpg",
            intensity: 72,
            adaptiveRenderMetadata: adaptiveMetadata
        )

        let roll = try FilmRoll(
            name: "Metadata Roll",
            referenceAsset: FilmRollReferenceAsset(
                originalPath: "film-rolls/roll-1/reference/original.jpg",
                thumbnailPath: "film-rolls/roll-1/reference/thumb.jpg"
            ),
            lut: .identity(size: 2),
            sampleAnalysisPackage: samplePackage,
            processedPhotos: [processedPhoto]
        )

        XCTAssertEqual(roll.sampleAnalysisPackage, samplePackage)
        XCTAssertEqual(roll.processedPhotos.first?.adaptiveRenderMetadata, adaptiveMetadata)
    }

    func testPhotoRenderRequestClampsIntensityToZeroThroughOneHundred() {
        let low = PhotoRenderRequest(
            filmRollID: "roll-1",
            processedPhotoID: "photo-low",
            originalPath: "imports/original.jpg",
            lut: .identity(),
            intensity: -1
        )
        let high = PhotoRenderRequest(
            filmRollID: "roll-1",
            processedPhotoID: "photo-high",
            originalPath: "imports/original.jpg",
            lut: .identity(),
            intensity: 101
        )

        XCTAssertEqual(low.intensity, 0)
        XCTAssertEqual(high.intensity, 100)
    }

    func testRenderRequestsDefaultToAdaptivePostProcessEnabledAndCanDisableIt() {
        let defaultPhotoRequest = PhotoRenderRequest(
            filmRollID: "roll-1",
            processedPhotoID: "photo-default",
            originalPath: "imports/original.jpg",
            lut: .identity(),
            intensity: 80
        )
        let disabledPhotoRequest = PhotoRenderRequest(
            filmRollID: "roll-1",
            processedPhotoID: "photo-disabled",
            originalPath: "imports/original.jpg",
            lut: .identity(),
            intensity: 80,
            isAdaptivePostProcessEnabled: false
        )
        let disabledPreviewRequest = PhotoPreviewRenderRequest(
            filmRollID: "roll-1",
            previewID: "preview-disabled",
            originalPath: "imports/original.jpg",
            lut: .identity(),
            intensity: 80,
            maxPixelDimension: 720,
            isAdaptivePostProcessEnabled: false
        )

        XCTAssertTrue(defaultPhotoRequest.isAdaptivePostProcessEnabled)
        XCTAssertFalse(disabledPhotoRequest.isAdaptivePostProcessEnabled)
        XCTAssertFalse(disabledPreviewRequest.isAdaptivePostProcessEnabled)
    }
}

func modelAssistedTestSampleAnalysisPackage() -> SampleAnalysisPackage {
    SampleAnalysisPackage(
        algorithmVersion: "test.sample-analysis.v1",
        modelVersion: "test-model",
        sampleQuality: SampleQualityMetadata(
            usable: true,
            confidence: 0.82,
            warnings: [.assumedSRGB]
        ),
        colorStatistics: SampleColorStatistics(
            luminanceP5: 0.08,
            luminanceP50: 0.42,
            luminanceP95: 0.88,
            chromaP50: 0.21,
            saturationMean: 0.34,
            redBias: 0.03,
            greenBias: -0.01,
            blueBias: -0.02,
            shadowWarmth: -0.04,
            midtoneWarmth: 0.01,
            highlightWarmth: 0.08
        ),
        sceneLighting: SceneLightingDescriptor(
            exposureKey: .balanced,
            contrastIntent: 0.54,
            shadowTintStrength: 0.12,
            highlightWarmth: 0.08,
            blackLift: 0.05,
            highlightRolloff: 0.18,
            saturationIntent: 0.62
        ),
        semanticColor: SemanticColorDescriptor(
            neutral: ColorFamilyEvidence(observed: true, confidence: 0.72),
            skin: ColorFamilyEvidence(observed: true, confidence: 0.44),
            foliage: ColorFamilyEvidence(observed: false, confidence: 0.18),
            sky: ColorFamilyEvidence(observed: false, confidence: 0.12),
            warmLight: ColorFamilyEvidence(observed: true, confidence: 0.68),
            saturatedRed: ColorFamilyEvidence(observed: true, confidence: 0.52),
            saturatedGreen: ColorFamilyEvidence(observed: false, confidence: 0.16),
            saturatedBlue: ColorFamilyEvidence(observed: false, confidence: 0.14)
        ),
        styleProfile: StyleProfile(
            blackPointLift: 0.05,
            highlightRolloff: 0.18,
            globalSaturation: 0.62,
            greenHandling: -0.08,
            skinProtection: 0.44,
            neutralProtection: 0.72,
            styleStrength: 0.78
        ),
        coverageConfidence: CoverageConfidenceMetadata(
            overall: 0.82,
            deepShadow: .medium,
            midtone: .high,
            highlight: .high,
            saturatedRed: .medium,
            saturatedGreen: .low,
            saturatedBlue: .low,
            neutral: .high,
            skin: .medium,
            sky: .low,
            foliage: .low,
            warmLight: .medium
        ),
        renderProfileSeed: RenderProfileSeed(
            skinProtectionIntent: 0.44,
            neutralProtectionIntent: 0.72,
            highlightRolloffIntent: 0.18,
            shadowLiftIntent: 0.05,
            shadowTintAdaptation: 0.12,
            lowConfidenceColorPolicy: .conservative
        )
    )
}

func modelAssistedTestAdaptiveRenderMetadata() -> AdaptiveRenderMetadata {
    AdaptiveRenderMetadata(
        algorithmVersion: "test.adaptive.v1",
        targetAnalysis: TargetRenderAnalysis(
            exposureKey: .highKey,
            luminanceP50: 0.73,
            luminanceP95: 0.96,
            saturationMean: 0.22,
            neutralConfidence: 0.65,
            skinConfidence: 0.18,
            coverageConfidenceOverall: 0.58
        ),
        adjustment: AdaptiveRenderAdjustment(
            effectiveIntensityScale: 0.72,
            brightness: -0.02,
            contrast: 0.96,
            saturation: 0.92,
            shadowLift: 0.03,
            highlightRolloff: 0.08,
            confidence: 0.58
        )
    )
}
