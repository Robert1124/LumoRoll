import CoreGraphics
import CoreImage
import XCTest
@testable import LumoRoll

final class CoreImageRendererTests: XCTestCase {
    func testColorCubeDataExpandsRGBLUTToRGBAFloat32WithAlphaOne() throws {
        let lut = LUT3D.identity(size: 2)

        let data = CoreImageRenderer.colorCubeData(from: lut)
        let floats = data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }

        XCTAssertEqual(data.count, LUT3D.expectedSampleCount(for: 2) * 4 * MemoryLayout<Float>.size)
        XCTAssertEqual(floats.count, LUT3D.expectedSampleCount(for: 2) * 4)
        XCTAssertEqual(floats[0], 0, accuracy: 0.0001)
        XCTAssertEqual(floats[1], 0, accuracy: 0.0001)
        XCTAssertEqual(floats[2], 0, accuracy: 0.0001)
        XCTAssertEqual(floats[3], 1, accuracy: 0.0001)
        XCTAssertEqual(Array(floats[0..<32]), [
            0, 0, 0, 1,
            1, 0, 0, 1,
            0, 1, 0, 1,
            1, 1, 0, 1,
            0, 0, 1, 1,
            1, 0, 1, 1,
            0, 1, 1, 1,
            1, 1, 1, 1
        ])
        XCTAssertTrue(stride(from: 3, to: floats.count, by: 4).allSatisfy { floats[$0] == 1 })
    }

    func testRenderAtZeroIntensityReturnsOriginalImageColors() throws {
        let renderer = CoreImageRenderer()
        let original = singlePixelImage(red: 255, green: 0, blue: 0)

        let rendered = try renderer.render(
            original,
            applying: constantBlueLUT(),
            intensity: 0,
            size: .fullResolution
        )

        XCTAssertEqual(samplePixel(rendered).red, 255, accuracy: 2)
        XCTAssertEqual(samplePixel(rendered).green, 0, accuracy: 2)
        XCTAssertEqual(samplePixel(rendered).blue, 0, accuracy: 2)
    }

    func testRenderAtOneHundredIntensityAppliesLUTOutput() throws {
        let renderer = CoreImageRenderer()
        let original = singlePixelImage(red: 255, green: 0, blue: 0)

        let rendered = try renderer.render(
            original,
            applying: constantBlueLUT(),
            intensity: 100,
            size: .fullResolution
        )

        XCTAssertEqual(samplePixel(rendered).red, 0, accuracy: 2)
        XCTAssertEqual(samplePixel(rendered).green, 0, accuracy: 2)
        XCTAssertEqual(samplePixel(rendered).blue, 255, accuracy: 2)
    }

    func testRenderAtMidpointIntensityBlendsOriginalAndProcessedOutput() throws {
        let renderer = CoreImageRenderer()
        let original = singlePixelImage(red: 255, green: 0, blue: 0)

        let rendered = try renderer.render(
            original,
            applying: constantBlueLUT(),
            intensity: 50,
            size: .fullResolution
        )

        XCTAssertEqual(samplePixel(rendered).red, 128, accuracy: 3)
        XCTAssertEqual(samplePixel(rendered).green, 0, accuracy: 2)
        XCTAssertEqual(samplePixel(rendered).blue, 128, accuracy: 3)
    }

    func testAdaptiveAdjustmentCanReduceEffectiveLUTStrength() throws {
        let renderer = CoreImageRenderer()
        let original = singlePixelImage(red: 255, green: 0, blue: 0)
        let adjustment = AdaptiveRenderAdjustment(
            effectiveIntensityScale: 0.25,
            brightness: 0,
            contrast: 1,
            saturation: 1,
            shadowLift: 0,
            highlightRolloff: 0,
            confidence: 1
        )

        let rendered = try renderer.render(
            original,
            applying: constantBlueLUT(),
            intensity: 100,
            size: .fullResolution,
            adaptiveAdjustment: adjustment
        )

        XCTAssertEqual(samplePixel(rendered).red, 191, accuracy: 4)
        XCTAssertEqual(samplePixel(rendered).green, 0, accuracy: 2)
        XCTAssertEqual(samplePixel(rendered).blue, 64, accuracy: 4)
    }

    func testRenderAtMidpointIntensityPreservesSemiTransparentAlpha() throws {
        let renderer = CoreImageRenderer()
        let original = singlePixelImage(red: 255, green: 0, blue: 0, alpha: 128)

        let rendered = try renderer.render(
            original,
            applying: constantBlueLUT(),
            intensity: 50,
            size: .fullResolution
        )

        XCTAssertEqual(samplePixel(rendered).alpha, 128, accuracy: 3)
    }

    func testRenderingDoesNotMutateLUTValues() throws {
        let renderer = CoreImageRenderer()
        let lut = try constantBlueLUT()
        let valuesBeforeRendering = lut.values

        _ = try renderer.render(
            singlePixelImage(red: 255, green: 0, blue: 0),
            applying: lut,
            intensity: 50,
            size: .fullResolution
        )

        XCTAssertEqual(lut.values, valuesBeforeRendering)
    }

    func testPreviewAndThumbnailSizeControlsProduceBoundedDimensions() throws {
        let renderer = CoreImageRenderer()
        let original = checkerImage(width: 4, height: 2)

        let preview = try renderer.render(
            original,
            applying: LUT3D.identity(size: 2),
            intensity: 100,
            size: .preview(maxPixelDimension: 2)
        )
        let thumbnail = try renderer.render(
            original,
            applying: LUT3D.identity(size: 2),
            intensity: 100,
            size: .thumbnail(maxPixelDimension: 1)
        )

        XCTAssertLessThanOrEqual(max(preview.width, preview.height), 2)
        XCTAssertGreaterThan(preview.width, 0)
        XCTAssertGreaterThan(preview.height, 0)
        XCTAssertLessThanOrEqual(max(thumbnail.width, thumbnail.height), 1)
        XCTAssertGreaterThan(thumbnail.width, 0)
        XCTAssertGreaterThan(thumbnail.height, 0)
    }

    func testPreviewScalingPreservesOpaqueEdgePixelsForFractionalAspectRatio() throws {
        let renderer = CoreImageRenderer()
        let original = horizontalEdgeImage(width: 5, height: 3)

        let preview = try renderer.render(
            original,
            applying: LUT3D.identity(size: 2),
            intensity: 100,
            size: .preview(maxPixelDimension: 4)
        )
        let samples = pixelSamples(preview)

        XCTAssertEqual(preview.width, 4)
        XCTAssertEqual(preview.height, 2)
        XCTAssertTrue(samples.allSatisfy { $0.alpha >= 250 })
        XCTAssertTrue(samples.contains { $0.green > $0.red && $0.green > 150 })
    }
}

private struct PixelSample {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}

private func singlePixelImage(red: UInt8, green: UInt8, blue: UInt8, alpha: UInt8 = 255) -> CIImage {
    image(width: 1, height: 1) { _, _ in
        PixelSample(red: red, green: green, blue: blue, alpha: alpha)
    }
}

private func checkerImage(width: Int, height: Int) -> CIImage {
    image(width: width, height: height) { x, y in
        if (x + y).isMultiple(of: 2) {
            return PixelSample(red: 255, green: 0, blue: 0, alpha: 255)
        }
        return PixelSample(red: 0, green: 0, blue: 255, alpha: 255)
    }
}

private func horizontalEdgeImage(width: Int, height: Int) -> CIImage {
    image(width: width, height: height) { _, y in
        if y == 0 || y == height - 1 {
            return PixelSample(red: 0, green: 255, blue: 0, alpha: 255)
        }
        return PixelSample(red: 255, green: 0, blue: 0, alpha: 255)
    }
}

private func image(width: Int, height: Int, pixelAt: (Int, Int) -> PixelSample) -> CIImage {
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
    let image = CGImage(
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
    )!

    return CIImage(cgImage: image)
}

private func samplePixel(_ image: CGImage) -> PixelSample {
    pixelSamples(image)[0]
}

private func pixelSamples(_ image: CGImage) -> [PixelSample] {
    var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
        data: &bytes,
        width: image.width,
        height: image.height,
        bitsPerComponent: 8,
        bytesPerRow: image.width * 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    )!

    context.interpolationQuality = .none
    context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

    return stride(from: 0, to: bytes.count, by: 4).map { offset in
        PixelSample(
            red: bytes[offset],
            green: bytes[offset + 1],
            blue: bytes[offset + 2],
            alpha: bytes[offset + 3]
        )
    }
}

private func constantBlueLUT() throws -> LUT3D {
    try LUT3D(
        size: 2,
        values: Array(repeating: [Float(0), Float(0), Float(1)], count: LUT3D.expectedSampleCount(for: 2)).flatMap { $0 }
    )
}
