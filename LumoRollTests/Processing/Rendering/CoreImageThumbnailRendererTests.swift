import CoreGraphics
import ImageIO
import XCTest
@testable import LumoRoll

final class CoreImageThumbnailRendererTests: XCTestCase {
    func testRendersBoundedSRGBJPEGThumbnailFromImageData() async throws {
        let sourceData = try pngImageData(width: 120, height: 60, red: 230, green: 40, blue: 20)
        let renderer = CoreImageThumbnailRenderer(maxPixelDimension: 32)

        let thumbnailData = try await renderer.renderThumbnail(from: sourceData)

        let imageSource = try XCTUnwrap(CGImageSourceCreateWithData(thumbnailData as CFData, nil))
        XCTAssertEqual(CGImageSourceGetType(imageSource) as String?, "public.jpeg")
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any])
        let width = try XCTUnwrap(properties[kCGImagePropertyPixelWidth] as? Int)
        let height = try XCTUnwrap(properties[kCGImagePropertyPixelHeight] as? Int)
        XCTAssertLessThanOrEqual(max(width, height), 32)
        XCTAssertGreaterThan(width, 0)
        XCTAssertGreaterThan(height, 0)
    }

    func testInvalidImageDataThrowsImportFailed() async {
        let renderer = CoreImageThumbnailRenderer(maxPixelDimension: 32)

        await XCTAssertThrowsAsyncError(
            try await renderer.renderThumbnail(from: Data([0, 1, 2, 3]))
        ) { error in
            XCTAssertEqual(error as? LumoError, .importFailed)
        }
    }
}

private func pngImageData(width: Int, height: Int, red: UInt8, green: UInt8, blue: UInt8) throws -> Data {
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

private func XCTAssertThrowsAsyncError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ errorHandler: (Error) -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("Expected error to be thrown", file: file, line: line)
    } catch {
        errorHandler(error)
    }
}
