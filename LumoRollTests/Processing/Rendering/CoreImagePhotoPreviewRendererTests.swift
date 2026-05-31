import CoreGraphics
import ImageIO
import XCTest
@testable import LumoRoll

final class CoreImagePhotoPreviewRendererTests: XCTestCase {
    func testRendersTemporaryPreviewJPEGUnderApplyPreviewsWithoutSavingFilmRollAssets() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let sourceFolder = assetStore.rootURL.appendingPathComponent("tmp/imports", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceFolder, withIntermediateDirectories: true)
        let sourceURL = sourceFolder.appendingPathComponent("target.png")
        try previewPNGData(width: 4, height: 2, red: 255, green: 0, blue: 0).write(to: sourceURL)
        let renderer = CoreImagePhotoPreviewRenderer(assetStore: assetStore, previewJPEGQuality: 0.9)

        let result = try await renderer.renderPreview(
            for: PhotoPreviewRenderRequest(
                filmRollID: "roll-1",
                previewID: "preview-123",
                originalPath: "tmp/imports/target.png",
                lut: try previewConstantBlueLUT(),
                intensity: 100,
                maxPixelDimension: 2
            )
        )

        XCTAssertEqual(result.previewID, "preview-123")
        XCTAssertEqual(result.originalPath, "tmp/imports/target.png")
        XCTAssertEqual(result.previewPath, "tmp/apply-previews/preview-123/preview.jpg")
        XCTAssertEqual(result.intensity, 100)
        let previewURL = assetStore.rootURL.appendingPathComponent(result.previewPath)
        XCTAssertEqual(previewImageType(at: previewURL), "public.jpeg")
        XCTAssertLessThanOrEqual(max(try previewImageSize(at: previewURL).width, try previewImageSize(at: previewURL).height), 2)
        XCTAssertFalse(FileManager.default.fileExists(atPath: assetStore.filmRollFolderURL(for: "roll-1").path))

        let renderedPixel = try previewFirstPixel(at: previewURL)
        XCTAssertLessThanOrEqual(renderedPixel.red, 8)
        XCTAssertLessThanOrEqual(renderedPixel.green, 8)
        XCTAssertGreaterThanOrEqual(renderedPixel.blue, 245)
    }

    func testRenderPreviewSkipsAdaptiveMetadataWhenDiagnosticToggleIsDisabled() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let sourceFolder = assetStore.rootURL.appendingPathComponent("tmp/imports", isDirectory: true)
        try FileManager.default.createDirectory(at: sourceFolder, withIntermediateDirectories: true)
        let sourceURL = sourceFolder.appendingPathComponent("target.png")
        try previewPNGData(width: 4, height: 2, red: 240, green: 210, blue: 160).write(to: sourceURL)
        let renderer = CoreImagePhotoPreviewRenderer(assetStore: assetStore, previewJPEGQuality: 0.9)

        let result = try await renderer.renderPreview(
            for: PhotoPreviewRenderRequest(
                filmRollID: "roll-1",
                previewID: "preview-no-adaptive",
                originalPath: "tmp/imports/target.png",
                lut: try previewConstantBlueLUT(),
                intensity: 80,
                maxPixelDimension: 2,
                sampleAnalysisPackage: modelAssistedTestSampleAnalysisPackage(),
                isAdaptivePostProcessEnabled: false
            )
        )

        XCTAssertNil(result.adaptiveRenderMetadata)
    }

    func testDiscardRenderedPreviewRemovesOnlyMatchingTemporaryPreviewFolder() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let previewFolder = assetStore.rootURL
            .appendingPathComponent("tmp/apply-previews/preview-cleanup", isDirectory: true)
        try FileManager.default.createDirectory(at: previewFolder, withIntermediateDirectories: true)
        try Data([1]).write(to: previewFolder.appendingPathComponent("preview.jpg"))
        let sentinelFolder = assetStore.baseURL.appendingPathComponent("sentinel", isDirectory: true)
        try FileManager.default.createDirectory(at: sentinelFolder, withIntermediateDirectories: true)
        let sentinelFile = sentinelFolder.appendingPathComponent("keep.txt")
        try Data([2]).write(to: sentinelFile)
        let renderer = CoreImagePhotoPreviewRenderer(assetStore: assetStore)

        await renderer.discardRenderedPreview(at: "tmp/apply-previews/preview-cleanup/preview.jpg")
        await renderer.discardRenderedPreview(at: "../sentinel/keep.txt")

        XCTAssertFalse(FileManager.default.fileExists(atPath: previewFolder.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: sentinelFile.path))
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LumoRollCoreImagePhotoPreviewRendererTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private struct PreviewPixelSample {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}

private func previewPNGData(width: Int, height: Int, red: UInt8, green: UInt8, blue: UInt8) throws -> Data {
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    var bytes = [UInt8]()
    bytes.reserveCapacity(width * height * 4)
    for _ in 0..<(width * height) {
        bytes.append(red)
        bytes.append(green)
        bytes.append(blue)
        bytes.append(255)
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
    let data = NSMutableData()
    let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, image, nil)
    XCTAssertTrue(CGImageDestinationFinalize(destination))
    return data as Data
}

private func previewImageType(at url: URL) -> String? {
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        return nil
    }
    return CGImageSourceGetType(imageSource) as String?
}

private func previewImageSize(at url: URL) throws -> CGSize {
    let imageSource = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
    let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any])
    let width = try XCTUnwrap(properties[kCGImagePropertyPixelWidth] as? Int)
    let height = try XCTUnwrap(properties[kCGImagePropertyPixelHeight] as? Int)
    return CGSize(width: width, height: height)
}

private func previewFirstPixel(at url: URL) throws -> PreviewPixelSample {
    let imageSource = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
    let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(imageSource, 0, nil))
    var bytes = [UInt8](repeating: 0, count: 4)
    let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    let context = CGContext(
        data: &bytes,
        width: 1,
        height: 1,
        bitsPerComponent: 8,
        bytesPerRow: 4,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    )!
    context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
    return PreviewPixelSample(red: bytes[0], green: bytes[1], blue: bytes[2], alpha: bytes[3])
}

private func previewConstantBlueLUT() throws -> LUT3D {
    try LUT3D(
        size: 2,
        values: Array(repeating: [Float(0), Float(0), Float(1)], count: LUT3D.expectedSampleCount(for: 2)).flatMap { $0 }
    )
}
