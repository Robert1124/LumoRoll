import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import LumoRoll

final class ReferenceImageAnalyzerTests: XCTestCase {
    func testAnalyzeDataReturnsWarmerRedBiasedDescriptorForRedImageThanBlueImage() throws {
        let analyzer = ReferenceImageAnalyzer()

        let redDescriptor = try analyzer.analyze(data: try encodedPNG(width: 4, height: 4) { _, _ in
            PixelFixture(red: 235, green: 48, blue: 38, alpha: 255)
        })
        let blueDescriptor = try analyzer.analyze(data: try encodedPNG(width: 4, height: 4) { _, _ in
            PixelFixture(red: 35, green: 78, blue: 230, alpha: 255)
        })

        XCTAssertGreaterThan(redDescriptor.redBias, blueDescriptor.redBias)
        XCTAssertGreaterThan(redDescriptor.shadowWarmth, blueDescriptor.shadowWarmth)
        XCTAssertLessThan(redDescriptor.blueBias, blueDescriptor.blueBias)
    }

    func testAnalyzeDataRecordsWarningsForLowContrastLowSaturationImage() throws {
        let analyzer = ReferenceImageAnalyzer()

        let descriptor = try analyzer.analyze(data: try encodedPNG(width: 4, height: 4) { _, _ in
            PixelFixture(red: 122, green: 122, blue: 122, alpha: 255)
        })

        XCTAssertTrue(descriptor.warnings.contains(.lowContrast))
        XCTAssertTrue(descriptor.warnings.contains(.lowSaturation))
    }

    func testAnalyzeDataIgnoresTransparentPixelsFromPNG() throws {
        let analyzer = ReferenceImageAnalyzer()

        let descriptor = try analyzer.analyze(data: try encodedPNG(width: 4, height: 4) { x, y in
            if x == 0, y == 0 {
                return PixelFixture(red: 20, green: 70, blue: 230, alpha: 255)
            }
            return PixelFixture(red: 255, green: 40, blue: 20, alpha: 0)
        })

        XCTAssertLessThan(descriptor.redBias, descriptor.blueBias)
        XCTAssertLessThan(descriptor.shadowWarmth, 0)
        XCTAssertTrue(descriptor.warnings.contains(.lowConfidence))
    }

    func testAnalyzeDataIgnoresMostlyTransparentPixelsFromPNG() throws {
        let analyzer = ReferenceImageAnalyzer()

        let descriptor = try analyzer.analyze(data: try encodedPNG(width: 4, height: 4) { x, y in
            if x == 0, y == 0 {
                return PixelFixture(red: 20, green: 70, blue: 230, alpha: 255)
            }
            return PixelFixture(red: 255, green: 20, blue: 10, alpha: 16)
        })

        XCTAssertLessThan(descriptor.redBias, descriptor.blueBias)
        XCTAssertLessThan(descriptor.shadowWarmth, 0)
        XCTAssertTrue(descriptor.warnings.contains(.lowConfidence))
    }

    func testAnalyzePixelsReportsRobustLuminancePercentilesIgnoringOutliers() throws {
        let analyzer = ReferenceImageAnalyzer()
        var pixels = Array(repeating: ReferenceImageAnalyzer.Pixel(red: 0.5, green: 0.5, blue: 0.5), count: 100)
        pixels.append(ReferenceImageAnalyzer.Pixel(red: 0, green: 0, blue: 0))
        pixels.append(ReferenceImageAnalyzer.Pixel(red: 1, green: 1, blue: 1))

        let descriptor = try analyzer.analyze(pixels: pixels)

        XCTAssertEqual(descriptor.luminanceP50, 0.5, accuracy: 0.02)
        XCTAssertGreaterThan(descriptor.luminanceP5, 0.45)
        XCTAssertLessThan(descriptor.luminanceP95, 0.55)
    }

    func testAnalyzePixelsSeparatesShadowAndHighlightWarmth() throws {
        let analyzer = ReferenceImageAnalyzer()
        let warmShadows = Array(
            repeating: ReferenceImageAnalyzer.Pixel(red: 0.22, green: 0.10, blue: 0.04),
            count: 64
        )
        let neutralMidtones = Array(
            repeating: ReferenceImageAnalyzer.Pixel(red: 0.48, green: 0.48, blue: 0.48),
            count: 64
        )
        let coolHighlights = Array(
            repeating: ReferenceImageAnalyzer.Pixel(red: 0.55, green: 0.70, blue: 0.95),
            count: 64
        )

        let descriptor = try analyzer.analyze(pixels: warmShadows + neutralMidtones + coolHighlights)

        XCTAssertGreaterThan(descriptor.shadowWarmth, 0.02)
        XCTAssertEqual(descriptor.midtoneWarmth, 0, accuracy: 0.04)
        XCTAssertLessThan(descriptor.highlightWarmth, -0.02)
    }

    func testAnalyzePixelsReportsHueSaturationAndProtectionSignals() throws {
        let analyzer = ReferenceImageAnalyzer()
        let saturatedGreens = Array(
            repeating: ReferenceImageAnalyzer.Pixel(red: 0.08, green: 0.78, blue: 0.16),
            count: 48
        )
        let neutralGrays = Array(
            repeating: ReferenceImageAnalyzer.Pixel(red: 0.48, green: 0.48, blue: 0.48),
            count: 48
        )
        let skinLikeMidtones = Array(
            repeating: ReferenceImageAnalyzer.Pixel(red: 0.82, green: 0.56, blue: 0.42),
            count: 48
        )

        let descriptor = try analyzer.analyze(pixels: saturatedGreens + neutralGrays + skinLikeMidtones)

        XCTAssertGreaterThan(descriptor.greenSaturationBias, descriptor.blueSaturationBias)
        XCTAssertGreaterThan(descriptor.neutralProtection, 0.15)
        XCTAssertGreaterThan(descriptor.skinProtection, 0.15)
    }

    func testAnalyzePixelsReportsChromaPercentiles() throws {
        let analyzer = ReferenceImageAnalyzer()
        let neutral = Array(
            repeating: ReferenceImageAnalyzer.Pixel(red: 0.50, green: 0.50, blue: 0.50),
            count: 40
        )
        let moderateChroma = Array(
            repeating: ReferenceImageAnalyzer.Pixel(red: 0.70, green: 0.45, blue: 0.36),
            count: 40
        )
        let highChroma = Array(
            repeating: ReferenceImageAnalyzer.Pixel(red: 0.05, green: 0.82, blue: 0.18),
            count: 40
        )

        let descriptor = try analyzer.analyze(pixels: neutral + moderateChroma + highChroma)

        XCTAssertLessThan(descriptor.chromaP5, descriptor.chromaP50)
        XCTAssertLessThan(descriptor.chromaP50, descriptor.chromaP95)
        XCTAssertGreaterThan(descriptor.chromaP95, 0.35)
    }
}

final class LUTGeneratorTests: XCTestCase {
    func testGenerateNeutralDescriptorCreatesDefault33LUTWithExpectedCounts() throws {
        let generator = LUTGenerator()

        let lut = try generator.generateLUT(from: .neutral)

        XCTAssertEqual(lut.size, 33)
        XCTAssertEqual(lut.sampleCount, 35_937)
        XCTAssertEqual(lut.values.count, 107_811)
        XCTAssertEqual(lut.algorithmVersion, "mvp1.traditional.v2")
    }

    func testGeneratedLUTValuesAreFiniteAndClamped() throws {
        let descriptor = ReferenceImageAnalyzer.Descriptor(
            luminanceMean: 0.72,
            contrast: 1.8,
            saturationMean: 2.0,
            redBias: 1.5,
            greenBias: -1.5,
            blueBias: 1.2,
            shadowWarmth: -1.0,
            highlightWarmth: 1.0,
            warnings: []
        )
        let lut = try LUTGenerator().generateLUT(from: descriptor)

        XCTAssertFalse(lut.values.isEmpty)
        XCTAssertTrue(lut.values.allSatisfy { $0.isFinite && $0 >= 0 && $0 <= 1 })
    }

    func testNeutralDescriptorPreservesBlackAndWhiteCornersReasonably() throws {
        let lut = try LUTGenerator().generateLUT(from: .neutral)

        XCTAssertEqual(lut.values[0], 0, accuracy: 0.0001)
        XCTAssertEqual(lut.values[1], 0, accuracy: 0.0001)
        XCTAssertEqual(lut.values[2], 0, accuracy: 0.0001)

        let last = lut.values.count - 3
        XCTAssertEqual(lut.values[last], 1, accuracy: 0.0001)
        XCTAssertEqual(lut.values[last + 1], 1, accuracy: 0.0001)
        XCTAssertEqual(lut.values[last + 2], 1, accuracy: 0.0001)
    }

    func testGenerateLUTForProtocolRequestUsesReferenceImageData() async throws {
        let generator = LUTGenerator()
        let redData = try encodedPNG(width: 4, height: 4) { _, _ in
            PixelFixture(red: 235, green: 48, blue: 38, alpha: 255)
        }
        let blueData = try encodedPNG(width: 4, height: 4) { _, _ in
            PixelFixture(red: 35, green: 78, blue: 230, alpha: 255)
        }

        let redLUT = try await generator.generateLUT(
            for: LUTGenerationRequest(referenceImageData: redData, size: 2, algorithmVersion: "test")
        )
        let blueLUT = try await generator.generateLUT(
            for: LUTGenerationRequest(referenceImageData: blueData, size: 2, algorithmVersion: "test")
        )

        XCTAssertNotEqual(redLUT.values, blueLUT.values)
        XCTAssertNotEqual(redLUT.values, LUT3D.identity(size: 2, algorithmVersion: "test").values)
        XCTAssertEqual(redLUT.algorithmVersion, "test")
        XCTAssertEqual(blueLUT.algorithmVersion, "test")
    }

    func testGenerateFilmRollPackageReturnsBaseLUTAndSampleMetadata() async throws {
        let generator = LUTGenerator()
        let referenceData = try encodedPNG(width: 4, height: 4) { x, _ in
            if x < 2 {
                return PixelFixture(red: 230, green: 70, blue: 42, alpha: 255)
            }
            return PixelFixture(red: 42, green: 120, blue: 225, alpha: 255)
        }

        let result = try await generator.generateFilmRollPackage(
            for: LUTGenerationRequest(referenceImageData: referenceData, size: 2, algorithmVersion: "test.package")
        )

        XCTAssertEqual(result.lut.size, 2)
        XCTAssertEqual(result.lut.algorithmVersion, "test.package")
        let package = try XCTUnwrap(result.sampleAnalysisPackage)
        XCTAssertEqual(package.algorithmVersion, "test.package")
        XCTAssertGreaterThan(package.sampleQuality.confidence, 0)
        XCTAssertGreaterThan(package.coverageConfidence.overall, 0)
        XCTAssertTrue([.balanced, .conservative].contains(package.renderProfileSeed.lowConfidenceColorPolicy))
    }

    func testSampleAnalysisPackageBuilderMarksLowCoverageGraySampleConservative() throws {
        let descriptor = ReferenceImageAnalyzer.Descriptor(
            luminanceMean: 0.52,
            contrast: 0.35,
            saturationMean: 0.02,
            redBias: 0,
            greenBias: 0,
            blueBias: 0,
            shadowWarmth: 0,
            midtoneWarmth: 0,
            highlightWarmth: 0,
            chromaP50: 0.01,
            chromaP95: 0.02,
            neutralProtection: 0.92,
            skinProtection: 0,
            warnings: [.lowContrast, .lowSaturation]
        )

        let package = SampleAnalysisPackageBuilder().buildPackage(
            from: descriptor,
            algorithmVersion: "test.builder"
        )

        XCTAssertEqual(package.algorithmVersion, "test.builder")
        XCTAssertTrue(package.sampleQuality.warnings.contains(.lowColorCoverage))
        XCTAssertEqual(package.coverageConfidence.saturatedRed, .missing)
        XCTAssertEqual(package.coverageConfidence.saturatedGreen, .missing)
        XCTAssertEqual(package.coverageConfidence.saturatedBlue, .missing)
        XCTAssertEqual(package.semanticColor.neutral.observed, true)
        XCTAssertEqual(package.renderProfileSeed.lowConfidenceColorPolicy, .conservative)
    }

    func testSampleAnalysisPackageBuilderKeepsLightingAndCoverageSignals() throws {
        let descriptor = ReferenceImageAnalyzer.Descriptor(
            luminanceMean: 0.24,
            contrast: 1.25,
            saturationMean: 0.42,
            redBias: 0.04,
            greenBias: -0.02,
            blueBias: -0.03,
            shadowWarmth: 0.10,
            midtoneWarmth: 0.04,
            highlightWarmth: 0.12,
            chromaP50: 0.18,
            chromaP95: 0.44,
            luminanceP5: 0.03,
            luminanceP50: 0.24,
            luminanceP95: 0.82,
            redSaturationBias: 0.28,
            orangeSaturationBias: 0.35,
            blueSaturationBias: 0.24,
            neutralProtection: 0.32,
            skinProtection: 0.22,
            warnings: []
        )

        let package = SampleAnalysisPackageBuilder().buildPackage(
            from: descriptor,
            algorithmVersion: "test.builder"
        )

        XCTAssertEqual(package.sceneLighting.exposureKey, .lowKey)
        XCTAssertGreaterThan(package.sceneLighting.highlightWarmth, 0)
        XCTAssertEqual(package.coverageConfidence.deepShadow, .high)
        XCTAssertNotEqual(package.coverageConfidence.skin, .missing)
        XCTAssertTrue(package.semanticColor.warmLight.observed)
        XCTAssertGreaterThan(package.renderProfileSeed.highlightRolloffIntent, 0)
    }

    func testNeutralProtectionKeepsGrayAxisNearlyNeutralUnderStrongReferenceCast() throws {
        let descriptor = ReferenceImageAnalyzer.Descriptor(
            luminanceMean: 0.5,
            contrast: 1.0,
            saturationMean: 0.7,
            redBias: 0.18,
            greenBias: -0.16,
            blueBias: 0.04,
            shadowWarmth: 0.0,
            midtoneWarmth: 0.0,
            highlightWarmth: 0.0,
            neutralProtection: 1.0,
            skinProtection: 0.0,
            warnings: []
        )

        let lut = try LUTGenerator().generateLUT(from: descriptor, size: 17)
        let gray = lut.rgb(redIndex: 8, greenIndex: 8, blueIndex: 8)
        let saturatedGreen = lut.rgb(redIndex: 2, greenIndex: 14, blueIndex: 3)

        XCTAssertLessThan(gray.channelSpread, 0.035)
        XCTAssertGreaterThan(saturatedGreen.channelSpread, gray.channelSpread + 0.15)
    }

    func testHueSelectiveSaturationCanReduceGreenWithoutFlatteningSkinHue() throws {
        let descriptor = ReferenceImageAnalyzer.Descriptor(
            luminanceMean: 0.5,
            contrast: 1.0,
            saturationMean: 0.5,
            redBias: 0.0,
            greenBias: 0.0,
            blueBias: 0.0,
            shadowWarmth: 0.0,
            midtoneWarmth: 0.0,
            highlightWarmth: 0.0,
            orangeSaturationBias: 0.05,
            greenSaturationBias: -0.35,
            neutralProtection: 0.0,
            skinProtection: 1.0,
            warnings: []
        )

        let lut = try LUTGenerator().generateLUT(from: descriptor, size: 17)
        let originalGreen = RGBFixture(red: 2.0 / 16.0, green: 14.0 / 16.0, blue: 3.0 / 16.0)
        let originalSkin = RGBFixture(red: 13.0 / 16.0, green: 9.0 / 16.0, blue: 7.0 / 16.0)
        let transformedGreen = lut.rgb(redIndex: 2, greenIndex: 14, blueIndex: 3)
        let transformedSkin = lut.rgb(redIndex: 13, greenIndex: 9, blueIndex: 7)

        XCTAssertLessThan(transformedGreen.chroma, originalGreen.chroma - 0.05)
        XCTAssertEqual(transformedSkin.chroma, originalSkin.chroma, accuracy: 0.08)
    }

    func testRobustBlackAndWhitePercentilesAffectToneCurve() throws {
        let compressedRangeDescriptor = ReferenceImageAnalyzer.Descriptor(
            luminanceMean: 0.5,
            contrast: 1.0,
            saturationMean: 0.5,
            redBias: 0,
            greenBias: 0,
            blueBias: 0,
            shadowWarmth: 0,
            midtoneWarmth: 0,
            highlightWarmth: 0,
            luminanceP1: 0.28,
            luminanceP5: 0.32,
            luminanceP50: 0.50,
            luminanceP95: 0.68,
            luminanceP99: 0.72,
            warnings: []
        )
        let fullRangeDescriptor = ReferenceImageAnalyzer.Descriptor(
            luminanceMean: 0.5,
            contrast: 1.0,
            saturationMean: 0.5,
            redBias: 0,
            greenBias: 0,
            blueBias: 0,
            shadowWarmth: 0,
            midtoneWarmth: 0,
            highlightWarmth: 0,
            luminanceP1: 0.02,
            luminanceP5: 0.08,
            luminanceP50: 0.50,
            luminanceP95: 0.92,
            luminanceP99: 0.98,
            warnings: []
        )

        let compressedLUT = try LUTGenerator().generateLUT(from: compressedRangeDescriptor, size: 17)
        let fullRangeLUT = try LUTGenerator().generateLUT(from: fullRangeDescriptor, size: 17)

        XCTAssertGreaterThan(
            compressedLUT.rgb(redIndex: 4, greenIndex: 4, blueIndex: 4).red,
            fullRangeLUT.rgb(redIndex: 4, greenIndex: 4, blueIndex: 4).red + 0.02
        )
        XCTAssertLessThan(
            compressedLUT.rgb(redIndex: 12, greenIndex: 12, blueIndex: 12).red,
            fullRangeLUT.rgb(redIndex: 12, greenIndex: 12, blueIndex: 12).red - 0.02
        )
    }

    func testGeneratedV2LUTExportsAsStandardCubeRows() throws {
        let descriptor = try ReferenceImageAnalyzer().analyze(pixels: [
            ReferenceImageAnalyzer.Pixel(red: 0.22, green: 0.10, blue: 0.04),
            ReferenceImageAnalyzer.Pixel(red: 0.48, green: 0.48, blue: 0.48),
            ReferenceImageAnalyzer.Pixel(red: 0.55, green: 0.70, blue: 0.95),
            ReferenceImageAnalyzer.Pixel(red: 0.08, green: 0.78, blue: 0.16)
        ])
        let lut = try LUTGenerator().generateLUT(from: descriptor)

        let exported = try CubeExporter().export(lut: lut, title: "V2 Roll")
        let dataRows = exported
            .split(separator: "\n")
            .filter { $0.first?.isNumber == true || $0.first == "-" }

        XCTAssertEqual(lut.algorithmVersion, "mvp1.traditional.v2")
        XCTAssertEqual(dataRows.count, 35_937)
        XCTAssertTrue(exported.contains("LUT_3D_SIZE 33"))
    }
}

private struct RGBFixture {
    let red: Double
    let green: Double
    let blue: Double

    var channelSpread: Double {
        max(red, green, blue) - min(red, green, blue)
    }

    var chroma: Double {
        let luminance = (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
        return sqrt(pow(red - luminance, 2) + pow(green - luminance, 2) + pow(blue - luminance, 2))
    }
}

private extension LUT3D {
    func rgb(redIndex: Int, greenIndex: Int, blueIndex: Int) -> RGBFixture {
        let valueIndex = (((blueIndex * size) + greenIndex) * size + redIndex) * 3
        return RGBFixture(
            red: Double(values[valueIndex]),
            green: Double(values[valueIndex + 1]),
            blue: Double(values[valueIndex + 2])
        )
    }
}

private struct PixelFixture {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}

private func encodedPNG(
    width: Int,
    height: Int,
    pixelAt: (Int, Int) -> PixelFixture
) throws -> Data {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    var bytes: [UInt8] = []
    bytes.reserveCapacity(width * height * 4)

    for y in 0..<height {
        for x in 0..<width {
            let pixel = pixelAt(x, y)
            bytes.append(pixel.red)
            bytes.append(pixel.green)
            bytes.append(pixel.blue)
            bytes.append(pixel.alpha)
        }
    }

    let provider = CGDataProvider(data: Data(bytes) as CFData)!
    guard let image = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: width * 4,
        space: colorSpace,
        bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
        provider: provider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    ) else {
        XCTFail("Failed to create test image")
        return Data()
    }

    let output = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil) else {
        XCTFail("Failed to create PNG destination")
        return Data()
    }

    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        XCTFail("Failed to encode PNG")
        return Data()
    }

    return output as Data
}

final class CubeExporterTests: XCTestCase {
    func testCubeExportIncludesRequiredHeaderFields() throws {
        let exported = try CubeExporter().export(lut: .identity(), title: "Portra Morning")

        XCTAssertTrue(exported.contains("TITLE \"Portra Morning\""))
        XCTAssertTrue(exported.contains("LUT_3D_SIZE 33"))
        XCTAssertTrue(exported.contains("DOMAIN_MIN 0.000000 0.000000 0.000000"))
        XCTAssertTrue(exported.contains("DOMAIN_MAX 1.000000 1.000000 1.000000"))
    }

    func testCubeExportWritesExactlyDefaultLUTDataRows() throws {
        let exported = try CubeExporter().export(lut: .identity(), title: "Portra Morning")
        let dataRows = exported
            .split(separator: "\n")
            .filter { $0.first?.isNumber == true || $0.first == "-" }

        XCTAssertEqual(dataRows.count, 35_937)
    }

    func testCubeExportUsesRedFastestOrderingWithSixDecimalFormatting() throws {
        let exported = try CubeExporter().export(lut: .identity(size: 2), title: "Identity")
        let dataRows = exported
            .split(separator: "\n")
            .filter { $0.first?.isNumber == true || $0.first == "-" }
            .map(String.init)

        XCTAssertEqual(
            Array(dataRows.prefix(8)),
            [
                "0.000000 0.000000 0.000000",
                "1.000000 0.000000 0.000000",
                "0.000000 1.000000 0.000000",
                "1.000000 1.000000 0.000000",
                "0.000000 0.000000 1.000000",
                "1.000000 0.000000 1.000000",
                "0.000000 1.000000 1.000000",
                "1.000000 1.000000 1.000000"
            ]
        )
    }

    func testCubeExportEscapesQuotesInTitle() throws {
        let exported = try CubeExporter().export(lut: .identity(), title: #"Yiwen's "Warm" Roll"#)

        XCTAssertTrue(exported.contains(#"TITLE "Yiwen's \"Warm\" Roll""#))
    }
}

final class CubeLUTImporterTests: XCTestCase {
    func testCubeImportParsesSizeHeadersAndRedFastestRows() throws {
        let cubeText = """
        # LumoRoll import fixture
        TITLE "Tiny Warm Roll"
        LUT_3D_SIZE 2
        DOMAIN_MIN 0.000000 0.000000 0.000000
        DOMAIN_MAX 1.000000 1.000000 1.000000
        0.000000 0.000000 0.000000
        1.000000 0.000000 0.000000
        0.000000 1.000000 0.000000
        1.000000 1.000000 0.000000
        0.000000 0.000000 1.000000
        1.000000 0.000000 1.000000
        0.000000 1.000000 1.000000
        1.000000 1.000000 1.000000
        """

        let lut = try CubeLUTImporter().importLUT(fromCubeTextData: Data(cubeText.utf8))

        XCTAssertEqual(lut.size, 2)
        XCTAssertEqual(lut.values.count, 24)
        XCTAssertEqual(Array(lut.values.prefix(6)), [0, 0, 0, 1, 0, 0])
        XCTAssertEqual(lut.algorithmVersion, CubeLUTImporter.algorithmVersion)
    }

    func testCubeImportRejectsMalformedLUT() {
        let cubeText = """
        TITLE "Broken"
        LUT_3D_SIZE 2
        0.000000 0.000000 0.000000
        """

        XCTAssertThrowsError(try CubeLUTImporter().importLUT(fromCubeTextData: Data(cubeText.utf8))) { error in
            XCTAssertEqual(error as? LumoError, .invalidCubeLUT(message: "Expected 8 RGB rows, got 1."))
        }
    }
}
