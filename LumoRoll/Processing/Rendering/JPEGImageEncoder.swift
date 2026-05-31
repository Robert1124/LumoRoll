import CoreGraphics
import Foundation
import ImageIO

enum JPEGImageEncoder {
    static func encode(_ image: CGImage, quality: CGFloat) throws -> Data {
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil) else {
            throw LumoError.renderFailed
        }

        let options = [
            kCGImageDestinationLossyCompressionQuality: max(0, min(1, quality))
        ] as CFDictionary
        CGImageDestinationAddImage(destination, image, options)
        guard CGImageDestinationFinalize(destination) else {
            throw LumoError.renderFailed
        }

        return data as Data
    }
}
