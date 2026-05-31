import CoreGraphics
import Foundation
import ImageIO

struct ReferenceImageAnalyzer: Sendable {
    private static let maxAnalysisLongEdge = 128

    struct Descriptor: Codable, Equatable, Sendable {
        let luminanceMean: Double
        let contrast: Double
        let saturationMean: Double
        let redBias: Double
        let greenBias: Double
        let blueBias: Double
        let shadowWarmth: Double
        let midtoneWarmth: Double
        let highlightWarmth: Double
        let chromaP5: Double
        let chromaP50: Double
        let chromaP95: Double
        let luminanceP1: Double
        let luminanceP5: Double
        let luminanceP25: Double
        let luminanceP50: Double
        let luminanceP75: Double
        let luminanceP95: Double
        let luminanceP99: Double
        let shadowRedBias: Double
        let shadowGreenBias: Double
        let shadowBlueBias: Double
        let midtoneRedBias: Double
        let midtoneGreenBias: Double
        let midtoneBlueBias: Double
        let highlightRedBias: Double
        let highlightGreenBias: Double
        let highlightBlueBias: Double
        let redSaturationBias: Double
        let orangeSaturationBias: Double
        let yellowSaturationBias: Double
        let greenSaturationBias: Double
        let cyanSaturationBias: Double
        let blueSaturationBias: Double
        let magentaSaturationBias: Double
        let neutralProtection: Double
        let skinProtection: Double
        let warnings: [Warning]

        init(
            luminanceMean: Double,
            contrast: Double,
            saturationMean: Double,
            redBias: Double,
            greenBias: Double,
            blueBias: Double,
            shadowWarmth: Double,
            midtoneWarmth: Double = 0,
            highlightWarmth: Double,
            chromaP5: Double = 0,
            chromaP50: Double = 0,
            chromaP95: Double = 0,
            luminanceP1: Double = 0.01,
            luminanceP5: Double = 0.05,
            luminanceP25: Double = 0.25,
            luminanceP50: Double = 0.5,
            luminanceP75: Double = 0.75,
            luminanceP95: Double = 0.95,
            luminanceP99: Double = 0.99,
            shadowRedBias: Double = 0,
            shadowGreenBias: Double = 0,
            shadowBlueBias: Double = 0,
            midtoneRedBias: Double = 0,
            midtoneGreenBias: Double = 0,
            midtoneBlueBias: Double = 0,
            highlightRedBias: Double = 0,
            highlightGreenBias: Double = 0,
            highlightBlueBias: Double = 0,
            redSaturationBias: Double = 0,
            orangeSaturationBias: Double = 0,
            yellowSaturationBias: Double = 0,
            greenSaturationBias: Double = 0,
            cyanSaturationBias: Double = 0,
            blueSaturationBias: Double = 0,
            magentaSaturationBias: Double = 0,
            neutralProtection: Double = 0,
            skinProtection: Double = 0,
            warnings: [Warning]
        ) {
            self.luminanceMean = luminanceMean
            self.contrast = contrast
            self.saturationMean = saturationMean
            self.redBias = redBias
            self.greenBias = greenBias
            self.blueBias = blueBias
            self.shadowWarmth = shadowWarmth
            self.midtoneWarmth = midtoneWarmth
            self.highlightWarmth = highlightWarmth
            self.chromaP5 = chromaP5
            self.chromaP50 = chromaP50
            self.chromaP95 = chromaP95
            self.luminanceP1 = luminanceP1
            self.luminanceP5 = luminanceP5
            self.luminanceP25 = luminanceP25
            self.luminanceP50 = luminanceP50
            self.luminanceP75 = luminanceP75
            self.luminanceP95 = luminanceP95
            self.luminanceP99 = luminanceP99
            self.shadowRedBias = shadowRedBias
            self.shadowGreenBias = shadowGreenBias
            self.shadowBlueBias = shadowBlueBias
            self.midtoneRedBias = midtoneRedBias
            self.midtoneGreenBias = midtoneGreenBias
            self.midtoneBlueBias = midtoneBlueBias
            self.highlightRedBias = highlightRedBias
            self.highlightGreenBias = highlightGreenBias
            self.highlightBlueBias = highlightBlueBias
            self.redSaturationBias = redSaturationBias
            self.orangeSaturationBias = orangeSaturationBias
            self.yellowSaturationBias = yellowSaturationBias
            self.greenSaturationBias = greenSaturationBias
            self.cyanSaturationBias = cyanSaturationBias
            self.blueSaturationBias = blueSaturationBias
            self.magentaSaturationBias = magentaSaturationBias
            self.neutralProtection = neutralProtection
            self.skinProtection = skinProtection
            self.warnings = warnings
        }

        static let neutral = Descriptor(
            luminanceMean: 0.5,
            contrast: 1.0,
            saturationMean: 0.5,
            redBias: 0,
            greenBias: 0,
            blueBias: 0,
            shadowWarmth: 0,
            midtoneWarmth: 0,
            highlightWarmth: 0,
            warnings: []
        )
    }

    enum Warning: String, Codable, Equatable, Sendable {
        case assumedSRGB
        case lowContrast
        case lowSaturation
        case lowConfidence
    }

    struct Pixel: Equatable, Sendable {
        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        init(red: Double, green: Double, blue: Double, alpha: Double = 1) {
            self.red = red
            self.green = green
            self.blue = blue
            self.alpha = alpha
        }
    }

    func neutralDescriptor() -> Descriptor {
        .neutral
    }

    func analyze(pixels: [Pixel]) throws -> Descriptor {
        let usablePixels = pixels.filter { $0.alpha >= 0.5 }
        guard !usablePixels.isEmpty else {
            throw LumoError.importFailed
        }

        let luminanceValues = usablePixels.map { Self.luminance(red: $0.red, green: $0.green, blue: $0.blue) }
        let sortedLuminanceValues = luminanceValues.sorted()
        let meanLuminance = luminanceValues.reduce(0, +) / Double(luminanceValues.count)
        let luminanceP1 = Self.percentile(0.01, sortedValues: sortedLuminanceValues)
        let luminanceP5 = Self.percentile(0.05, sortedValues: sortedLuminanceValues)
        let luminanceP25 = Self.percentile(0.25, sortedValues: sortedLuminanceValues)
        let luminanceP50 = Self.percentile(0.50, sortedValues: sortedLuminanceValues)
        let luminanceP75 = Self.percentile(0.75, sortedValues: sortedLuminanceValues)
        let luminanceP95 = Self.percentile(0.95, sortedValues: sortedLuminanceValues)
        let luminanceP99 = Self.percentile(0.99, sortedValues: sortedLuminanceValues)
        let robustRange = luminanceP95 - luminanceP5
        let contrast = max(0.25, min(1.75, 1 + (robustRange - 0.5)))

        let meanRed = usablePixels.map(\.red).reduce(0, +) / Double(usablePixels.count)
        let meanGreen = usablePixels.map(\.green).reduce(0, +) / Double(usablePixels.count)
        let meanBlue = usablePixels.map(\.blue).reduce(0, +) / Double(usablePixels.count)
        let saturationValues = usablePixels.map { Self.saturation(red: $0.red, green: $0.green, blue: $0.blue) }
        let meanSaturation = saturationValues.reduce(0, +) / Double(usablePixels.count)
        let sortedChromaValues = usablePixels
            .map { Self.chroma(red: $0.red, green: $0.green, blue: $0.blue) }
            .sorted()
        let chromaP5 = Self.percentile(0.05, sortedValues: sortedChromaValues)
        let chromaP50 = Self.percentile(0.50, sortedValues: sortedChromaValues)
        let chromaP95 = Self.percentile(0.95, sortedValues: sortedChromaValues)

        var warnings: [Warning] = [.assumedSRGB]
        if robustRange < 0.08 {
            warnings.append(.lowContrast)
        }
        if meanSaturation < 0.08 {
            warnings.append(.lowSaturation)
        }
        if usablePixels.count < 16 {
            warnings.append(.lowConfidence)
        }

        let shadow = Self.zoneStats(for: usablePixels, range: 0..<0.33)
        let midtone = Self.zoneStats(for: usablePixels, range: 0.33..<0.67)
        let highlight = Self.zoneStats(for: usablePixels, range: 0.67..<1.01)
        let hueSaturation = Self.hueSaturationBiases(for: usablePixels, meanSaturation: meanSaturation)
        let neutralProtection = Double(saturationValues.filter { $0 < 0.08 }.count) / Double(usablePixels.count)
        let skinProtection = Double(usablePixels.filter(Self.isSkinLike).count) / Double(usablePixels.count)

        return Descriptor(
            luminanceMean: max(0, min(1, meanLuminance)),
            contrast: contrast,
            saturationMean: max(0, min(1, meanSaturation)),
            redBias: max(-0.2, min(0.2, meanRed - meanLuminance)),
            greenBias: max(-0.2, min(0.2, meanGreen - meanLuminance)),
            blueBias: max(-0.2, min(0.2, meanBlue - meanLuminance)),
            shadowWarmth: shadow.warmth,
            midtoneWarmth: midtone.warmth,
            highlightWarmth: highlight.warmth,
            chromaP5: chromaP5,
            chromaP50: chromaP50,
            chromaP95: chromaP95,
            luminanceP1: luminanceP1,
            luminanceP5: luminanceP5,
            luminanceP25: luminanceP25,
            luminanceP50: luminanceP50,
            luminanceP75: luminanceP75,
            luminanceP95: luminanceP95,
            luminanceP99: luminanceP99,
            shadowRedBias: shadow.redBias,
            shadowGreenBias: shadow.greenBias,
            shadowBlueBias: shadow.blueBias,
            midtoneRedBias: midtone.redBias,
            midtoneGreenBias: midtone.greenBias,
            midtoneBlueBias: midtone.blueBias,
            highlightRedBias: highlight.redBias,
            highlightGreenBias: highlight.greenBias,
            highlightBlueBias: highlight.blueBias,
            redSaturationBias: hueSaturation.red,
            orangeSaturationBias: hueSaturation.orange,
            yellowSaturationBias: hueSaturation.yellow,
            greenSaturationBias: hueSaturation.green,
            cyanSaturationBias: hueSaturation.cyan,
            blueSaturationBias: hueSaturation.blue,
            magentaSaturationBias: hueSaturation.magenta,
            neutralProtection: max(0, min(1, neutralProtection)),
            skinProtection: max(0, min(1, skinProtection)),
            warnings: warnings
        )
    }

    func analyze(data: Data) throws -> Descriptor {
        let sourceOptions = [
            kCGImageSourceShouldCache: false
        ] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions),
              CGImageSourceGetCount(source) > 0,
              let image = CGImageSourceCreateImageAtIndex(source, 0, sourceOptions)
        else {
            throw LumoError.importFailed
        }

        let pixels = try Self.extractPixels(from: image)
        return try analyze(pixels: pixels)
    }

    private static func luminance(red: Double, green: Double, blue: Double) -> Double {
        (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    }

    private static func saturation(red: Double, green: Double, blue: Double) -> Double {
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        guard maximum > 0 else {
            return 0
        }
        return (maximum - minimum) / maximum
    }

    private static func chroma(red: Double, green: Double, blue: Double) -> Double {
        let luminanceValue = luminance(red: red, green: green, blue: blue)
        return sqrt(
            pow(red - luminanceValue, 2)
                + pow(green - luminanceValue, 2)
                + pow(blue - luminanceValue, 2)
        )
    }

    private static func percentile(_ percentile: Double, sortedValues: [Double]) -> Double {
        guard !sortedValues.isEmpty else {
            return 0
        }
        guard sortedValues.count > 1 else {
            return sortedValues[0]
        }

        let clampedPercentile = max(0, min(1, percentile))
        let position = clampedPercentile * Double(sortedValues.count - 1)
        let lowerIndex = Int(position.rounded(.down))
        let upperIndex = Int(position.rounded(.up))
        let fraction = position - Double(lowerIndex)
        return sortedValues[lowerIndex] + ((sortedValues[upperIndex] - sortedValues[lowerIndex]) * fraction)
    }

    private struct ZoneStats {
        let redBias: Double
        let greenBias: Double
        let blueBias: Double
        let warmth: Double

        static let neutral = ZoneStats(redBias: 0, greenBias: 0, blueBias: 0, warmth: 0)
    }

    private static func zoneStats(for pixels: [Pixel], range: Range<Double>) -> ZoneStats {
        let zonePixels = pixels.filter { pixel in
            let luma = luminance(red: pixel.red, green: pixel.green, blue: pixel.blue)
            return range.contains(luma)
        }
        guard !zonePixels.isEmpty else {
            return .neutral
        }

        let count = Double(zonePixels.count)
        let meanRed = zonePixels.map(\.red).reduce(0, +) / count
        let meanGreen = zonePixels.map(\.green).reduce(0, +) / count
        let meanBlue = zonePixels.map(\.blue).reduce(0, +) / count
        let meanLuminance = zonePixels
            .map { luminance(red: $0.red, green: $0.green, blue: $0.blue) }
            .reduce(0, +) / count

        return ZoneStats(
            redBias: max(-0.2, min(0.2, meanRed - meanLuminance)),
            greenBias: max(-0.2, min(0.2, meanGreen - meanLuminance)),
            blueBias: max(-0.2, min(0.2, meanBlue - meanLuminance)),
            warmth: max(-0.2, min(0.2, (meanRed - meanBlue) * 0.5))
        )
    }

    private struct HueSaturationBiases {
        let red: Double
        let orange: Double
        let yellow: Double
        let green: Double
        let cyan: Double
        let blue: Double
        let magenta: Double
    }

    private static func hueSaturationBiases(for pixels: [Pixel], meanSaturation: Double) -> HueSaturationBiases {
        func bias(center: Double, width: Double) -> Double {
            var weightedSaturation = 0.0
            var weightTotal = 0.0
            for pixel in pixels {
                let saturationValue = saturation(red: pixel.red, green: pixel.green, blue: pixel.blue)
                guard saturationValue > 0.04 else {
                    continue
                }
                let hue = hueDegrees(red: pixel.red, green: pixel.green, blue: pixel.blue)
                let distance = circularHueDistance(hue, center)
                let weight = max(0, 1 - (distance / width))
                weightedSaturation += saturationValue * weight
                weightTotal += weight
            }
            guard weightTotal > 0 else {
                return 0
            }
            return max(-0.5, min(0.5, (weightedSaturation / weightTotal) - meanSaturation))
        }

        return HueSaturationBiases(
            red: bias(center: 0, width: 34),
            orange: bias(center: 30, width: 30),
            yellow: bias(center: 60, width: 34),
            green: bias(center: 125, width: 55),
            cyan: bias(center: 185, width: 45),
            blue: bias(center: 235, width: 48),
            magenta: bias(center: 300, width: 58)
        )
    }

    private static func hueDegrees(red: Double, green: Double, blue: Double) -> Double {
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let delta = maximum - minimum
        guard delta > 0 else {
            return 0
        }

        let rawHue: Double
        if maximum == red {
            rawHue = 60 * (((green - blue) / delta).truncatingRemainder(dividingBy: 6))
        } else if maximum == green {
            rawHue = 60 * (((blue - red) / delta) + 2)
        } else {
            rawHue = 60 * (((red - green) / delta) + 4)
        }
        return rawHue < 0 ? rawHue + 360 : rawHue
    }

    private static func circularHueDistance(_ lhs: Double, _ rhs: Double) -> Double {
        let direct = abs(lhs - rhs).truncatingRemainder(dividingBy: 360)
        return min(direct, 360 - direct)
    }

    private static func isSkinLike(_ pixel: Pixel) -> Bool {
        let saturationValue = saturation(red: pixel.red, green: pixel.green, blue: pixel.blue)
        guard saturationValue >= 0.12, saturationValue <= 0.78 else {
            return false
        }
        let luminanceValue = luminance(red: pixel.red, green: pixel.green, blue: pixel.blue)
        guard luminanceValue >= 0.30, luminanceValue <= 0.88 else {
            return false
        }
        let hue = hueDegrees(red: pixel.red, green: pixel.green, blue: pixel.blue)
        return hue >= 12 && hue <= 55
    }

    private static func extractPixels(from image: CGImage) throws -> [Pixel] {
        let sourceWidth = image.width
        let sourceHeight = image.height
        guard sourceWidth > 0, sourceHeight > 0 else {
            throw LumoError.importFailed
        }

        let longEdge = max(sourceWidth, sourceHeight)
        let scale = min(1, Double(maxAnalysisLongEdge) / Double(longEdge))
        let targetWidth = max(1, Int((Double(sourceWidth) * scale).rounded()))
        let targetHeight = max(1, Int((Double(sourceHeight) * scale).rounded()))
        let bytesPerPixel = 4
        let bytesPerRow = targetWidth * bytesPerPixel
        var bytes = [UInt8](repeating: 0, count: targetHeight * bytesPerRow)

        let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
            CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        )
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB()
        let didDraw = bytes.withUnsafeMutableBytes { rawBuffer in
            guard let context = CGContext(
                data: rawBuffer.baseAddress,
                width: targetWidth,
                height: targetHeight,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: bitmapInfo.rawValue
            ) else {
                return false
            }

            context.interpolationQuality = .high
            context.draw(image, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
            return true
        }

        guard didDraw else {
            throw LumoError.importFailed
        }

        var pixels: [Pixel] = []
        pixels.reserveCapacity(targetWidth * targetHeight)
        for index in stride(from: 0, to: bytes.count, by: bytesPerPixel) {
            pixels.append(
                Pixel(
                    red: Double(bytes[index]) / 255,
                    green: Double(bytes[index + 1]) / 255,
                    blue: Double(bytes[index + 2]) / 255,
                    alpha: Double(bytes[index + 3]) / 255
                )
            )
        }

        return pixels
    }
}
