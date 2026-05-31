import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest

enum SystemIntegrationImageFixtures {
    struct Pixel {
        let red: UInt8
        let green: UInt8
        let blue: UInt8
        let alpha: UInt8
    }

    static func png(
        width: Int,
        height: Int,
        pixelAt: (Int, Int) -> Pixel
    ) throws -> Data {
        try encodedImage(type: UTType.png.identifier, width: width, height: height, pixelAt: pixelAt)
    }

    static func jpeg(
        width: Int,
        height: Int,
        pixelAt: (Int, Int) -> Pixel
    ) throws -> Data {
        try encodedImage(type: UTType.jpeg.identifier, width: width, height: height, pixelAt: pixelAt)
    }

    private static func encodedImage(
        type: String,
        width: Int,
        height: Int,
        pixelAt: (Int, Int) -> Pixel
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
        guard let destination = CGImageDestinationCreateWithData(output, type as CFString, 1, nil) else {
            XCTFail("Failed to create image destination")
            return Data()
        }

        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            XCTFail("Failed to encode image")
            return Data()
        }

        return output as Data
    }
}
