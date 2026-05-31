import CoreGraphics
import ImageIO
import XCTest
@testable import LumoRoll

final class CoreImagePhotoRendererTests: XCTestCase {
    func testRendersPhotoCopiesOriginalAndReturnsAssetStoreRelativeManifestPaths() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let sourceData = try testPNGData(width: 4, height: 2, red: 255, green: 0, blue: 0)
        let sourceURL = tempDirectory.appendingPathComponent("Visible User Name.png")
        try sourceData.write(to: sourceURL)
        let renderer = CoreImagePhotoRenderer(assetStore: assetStore, thumbnailMaxPixelDimension: 2)

        let result = try await renderer.renderPhoto(
            for: PhotoRenderRequest(
                filmRollID: "roll-1",
                processedPhotoID: "photo-123",
                originalPath: sourceURL.path,
                lut: try constantBlueLUT(),
                intensity: 100
            )
        )

        XCTAssertEqual(result.originalPath, "film-rolls/roll-1/processed/photo-123/original.png")
        XCTAssertEqual(result.processedPath, "film-rolls/roll-1/processed/photo-123/rendered.jpg")
        XCTAssertEqual(result.thumbnailPath, "film-rolls/roll-1/processed/photo-123/thumbnail.jpg")
        XCTAssertFalse(result.originalPath.contains("Visible"))
        XCTAssertEqual(result.intensity, 100)

        XCTAssertEqual(try Data(contentsOf: assetStore.rootURL.appendingPathComponent(result.originalPath)), sourceData)
        let renderedURL = assetStore.rootURL.appendingPathComponent(result.processedPath)
        let thumbnailURL = assetStore.rootURL.appendingPathComponent(result.thumbnailPath)
        XCTAssertEqual(imageType(at: renderedURL), "public.jpeg")
        XCTAssertEqual(imageType(at: thumbnailURL), "public.jpeg")
        XCTAssertLessThanOrEqual(max(try imageSize(at: thumbnailURL).width, try imageSize(at: thumbnailURL).height), 2)

        let renderedPixel = try firstPixel(at: renderedURL)
        XCTAssertLessThanOrEqual(renderedPixel.red, 8)
        XCTAssertLessThanOrEqual(renderedPixel.green, 8)
        XCTAssertGreaterThanOrEqual(renderedPixel.blue, 245)
    }

    func testRenderPhotoReturnsAdaptiveMetadataWhenSamplePackageIsProvided() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let sourceData = try testPNGData(width: 4, height: 2, red: 240, green: 210, blue: 160)
        let sourceURL = tempDirectory.appendingPathComponent("target.png")
        try sourceData.write(to: sourceURL)
        let renderer = CoreImagePhotoRenderer(assetStore: assetStore, thumbnailMaxPixelDimension: 2)

        let result = try await renderer.renderPhoto(
            for: PhotoRenderRequest(
                filmRollID: "roll-1",
                processedPhotoID: "photo-adaptive",
                originalPath: sourceURL.path,
                lut: try constantBlueLUT(),
                intensity: 80,
                sampleAnalysisPackage: modelAssistedTestSampleAnalysisPackage()
            )
        )

        let metadata = try XCTUnwrap(result.adaptiveRenderMetadata)
        XCTAssertEqual(metadata.algorithmVersion, AdaptivePostProcessor.algorithmVersion)
        XCTAssertGreaterThan(metadata.adjustment.confidence, 0)
    }

    func testRenderPhotoSkipsAdaptiveMetadataWhenDiagnosticToggleIsDisabled() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let sourceData = try testPNGData(width: 4, height: 2, red: 240, green: 210, blue: 160)
        let sourceURL = tempDirectory.appendingPathComponent("target.png")
        try sourceData.write(to: sourceURL)
        let renderer = CoreImagePhotoRenderer(assetStore: assetStore, thumbnailMaxPixelDimension: 2)

        let result = try await renderer.renderPhoto(
            for: PhotoRenderRequest(
                filmRollID: "roll-1",
                processedPhotoID: "photo-no-adaptive",
                originalPath: sourceURL.path,
                lut: try constantBlueLUT(),
                intensity: 80,
                sampleAnalysisPackage: modelAssistedTestSampleAnalysisPackage(),
                isAdaptivePostProcessEnabled: false
            )
        )

        XCTAssertNil(result.adaptiveRenderMetadata)
    }

    func testDiscardRenderedPhotoRemovesProcessedOutputFolder() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let renderer = CoreImagePhotoRenderer(assetStore: assetStore, thumbnailMaxPixelDimension: 2)
        let sourceURL = tempDirectory.appendingPathComponent("source.png")
        try testPNGData(width: 2, height: 2, red: 255, green: 0, blue: 0).write(to: sourceURL)

        let result = try await renderer.renderPhoto(
            for: PhotoRenderRequest(
                filmRollID: "roll-1",
                processedPhotoID: "photo-cleanup",
                originalPath: sourceURL.path,
                lut: LUT3D.identity(size: 2),
                intensity: 50
            )
        )
        let outputFolder = assetStore.rootURL
            .appendingPathComponent("film-rolls/roll-1/processed/photo-cleanup", isDirectory: true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputFolder.path))

        await renderer.discardRenderedPhoto(result)

        XCTAssertFalse(FileManager.default.fileExists(atPath: outputFolder.path))
    }

    func testDiscardRenderedPhotoIgnoresTraversalPathAndLeavesOutsideSentinelUntouched() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let renderer = CoreImagePhotoRenderer(assetStore: assetStore)
        try assetStore.prepareRoot()
        let sentinelFolder = assetStore.baseURL.appendingPathComponent("sentinel", isDirectory: true)
        try FileManager.default.createDirectory(at: sentinelFolder, withIntermediateDirectories: true)
        let sentinelFile = sentinelFolder.appendingPathComponent("keep.txt")
        try Data([8]).write(to: sentinelFile)

        await renderer.discardRenderedPhoto(
            PhotoRenderResult(
                originalPath: "unused",
                processedPath: "../sentinel/rendered.jpg",
                thumbnailPath: "unused",
                intensity: 50
            )
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: sentinelFile.path))
    }

    func testDiscardRenderedPhotoIgnoresMalformedNonProcessedPathAndLeavesFolderUntouched() async throws {
        let tempDirectory = try Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: tempDirectory) }
        let assetStore = AssetStore(baseURL: tempDirectory)
        let renderer = CoreImagePhotoRenderer(assetStore: assetStore)
        let referenceFolder = assetStore.rootURL
            .appendingPathComponent("film-rolls/roll-1/reference", isDirectory: true)
        try FileManager.default.createDirectory(at: referenceFolder, withIntermediateDirectories: true)
        let sentinelFile = referenceFolder.appendingPathComponent("keep.txt")
        try Data([9]).write(to: sentinelFile)

        await renderer.discardRenderedPhoto(
            PhotoRenderResult(
                originalPath: "unused",
                processedPath: "film-rolls/roll-1/reference/rendered.jpg",
                thumbnailPath: "unused",
                intensity: 50
            )
        )

        XCTAssertTrue(FileManager.default.fileExists(atPath: sentinelFile.path))
    }

    private static func makeTempDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LumoRollCoreImagePhotoRendererTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
}

private struct PixelSample {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}

private func testPNGData(width: Int, height: Int, red: UInt8, green: UInt8, blue: UInt8) throws -> Data {
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

private func imageType(at url: URL) -> String? {
    guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        return nil
    }
    return CGImageSourceGetType(imageSource) as String?
}

private func imageSize(at url: URL) throws -> CGSize {
    let imageSource = try XCTUnwrap(CGImageSourceCreateWithURL(url as CFURL, nil))
    let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any])
    let width = try XCTUnwrap(properties[kCGImagePropertyPixelWidth] as? Int)
    let height = try XCTUnwrap(properties[kCGImagePropertyPixelHeight] as? Int)
    return CGSize(width: width, height: height)
}

private func firstPixel(at url: URL) throws -> PixelSample {
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
    return PixelSample(red: bytes[0], green: bytes[1], blue: bytes[2], alpha: bytes[3])
}

private func constantBlueLUT() throws -> LUT3D {
    try LUT3D(
        size: 2,
        values: Array(repeating: [Float(0), Float(0), Float(1)], count: LUT3D.expectedSampleCount(for: 2)).flatMap { $0 }
    )
}
