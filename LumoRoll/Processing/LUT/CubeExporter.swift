import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct CubeExporter: LUTExporting {
    func export(lut: LUT3D, title: String) throws -> String {
        var lines: [String] = []
        lines.reserveCapacity(lut.sampleCount + 4)
        lines.append(#"TITLE "\#(sanitizeTitle(title))""#)
        lines.append("LUT_3D_SIZE \(lut.size)")
        lines.append("DOMAIN_MIN 0.000000 0.000000 0.000000")
        lines.append("DOMAIN_MAX 1.000000 1.000000 1.000000")

        for index in stride(from: 0, to: lut.values.count, by: 3) {
            let red = clamp(lut.values[index])
            let green = clamp(lut.values[index + 1])
            let blue = clamp(lut.values[index + 2])
            lines.append("\(format(red)) \(format(green)) \(format(blue))")
        }

        return lines.joined(separator: "\n") + "\n"
    }

    func exportLUT(for request: LUTExportRequest) async throws -> String {
        try export(lut: request.lut, title: request.filmRollName)
    }

    private func sanitizeTitle(_ title: String) -> String {
        title.replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\r", with: " ")
    }

    private func format(_ value: Float) -> String {
        String(format: "%.6f", locale: Locale(identifier: "en_US_POSIX"), value)
    }

    private func clamp(_ value: Float) -> Float {
        guard value.isFinite else {
            return 0
        }
        return Swift.max(0, Swift.min(1, value))
    }
}

struct CubeLUTImporter: LUTImporting {
    static let algorithmVersion = "mvp1.imported-cube.v1"

    func importLUT(fromCubeTextData data: Data) throws -> LUT3D {
        guard let text = String(data: data, encoding: .utf8) else {
            throw LumoError.invalidCubeLUT(message: "File is not UTF-8 text.")
        }

        var lutSize: Int?
        var values: [Float] = []
        for rawLine in text.components(separatedBy: .newlines) {
            let line = stripComment(from: rawLine).trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else {
                continue
            }

            let tokens = line.split(whereSeparator: \.isWhitespace).map(String.init)
            guard let firstToken = tokens.first else {
                continue
            }
            let keyword = firstToken.uppercased()

            switch keyword {
            case "TITLE", "DOMAIN_MIN", "DOMAIN_MAX":
                continue
            case "LUT_3D_SIZE":
                guard tokens.count == 2, let size = Int(tokens[1]), size >= 2 else {
                    throw LumoError.invalidCubeLUT(message: "Invalid LUT_3D_SIZE.")
                }
                lutSize = size
            case "LUT_1D_SIZE":
                throw LumoError.invalidCubeLUT(message: "1D LUT files are not supported.")
            default:
                guard isNumericToken(firstToken), tokens.count == 3 else {
                    throw LumoError.invalidCubeLUT(message: "Unsupported .cube line: \(firstToken).")
                }
                guard let red = Float(tokens[0]), let green = Float(tokens[1]), let blue = Float(tokens[2]) else {
                    throw LumoError.invalidCubeLUT(message: "Invalid RGB row.")
                }
                values.append(contentsOf: [red, green, blue])
            }
        }

        guard let lutSize else {
            throw LumoError.invalidCubeLUT(message: "Missing LUT_3D_SIZE.")
        }

        let expectedRows = lutSize * lutSize * lutSize
        let actualRows = values.count / 3
        guard actualRows == expectedRows else {
            throw LumoError.invalidCubeLUT(message: "Expected \(expectedRows) RGB rows, got \(actualRows).")
        }

        do {
            return try LUT3D(size: lutSize, values: values, algorithmVersion: Self.algorithmVersion)
        } catch LumoError.invalidLUTValue(let index) {
            throw LumoError.invalidCubeLUT(message: "RGB value at row \(index / 3 + 1) is outside 0...1.")
        } catch LumoError.invalidLUTSize(let size) {
            throw LumoError.invalidCubeLUT(message: "Unsupported LUT size: \(size).")
        } catch LumoError.invalidLUTSampleCount(let expected, let actual) {
            throw LumoError.invalidCubeLUT(message: "Expected \(expected / 3) RGB rows, got \(actual / 3).")
        } catch {
            throw error
        }
    }

    private func stripComment(from line: String) -> String {
        guard let commentStart = line.firstIndex(of: "#") else {
            return line
        }
        return String(line[..<commentStart])
    }

    private func isNumericToken(_ token: String) -> Bool {
        Float(token) != nil
    }
}

struct CubeLUTPreviewRenderer: LUTPreviewRendering {
    private static let width = 320
    private static let height = 220

    func renderPreviewImage(for lut: LUT3D) throws -> Data {
        var bytes: [UInt8] = []
        bytes.reserveCapacity(Self.width * Self.height * 4)

        for y in 0..<Self.height {
            for x in 0..<Self.width {
                let red = Float(x) / Float(Self.width - 1)
                let green = Float(Self.height - 1 - y) / Float(Self.height - 1)
                let blue = 0.35 + (0.35 * red)
                let sample = sampleNearest(lut: lut, red: red, green: green, blue: min(1, blue))

                bytes.append(Self.byte(sample.red))
                bytes.append(Self.byte(sample.green))
                bytes.append(Self.byte(sample.blue))
                bytes.append(255)
            }
        }

        guard let provider = CGDataProvider(data: Data(bytes) as CFData),
              let image = CGImage(
                width: Self.width,
                height: Self.height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: Self.width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
                provider: provider,
                decode: nil,
                shouldInterpolate: true,
                intent: .defaultIntent
              ) else {
            throw LumoError.renderFailed
        }

        let output = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(output, UTType.png.identifier as CFString, 1, nil) else {
            throw LumoError.renderFailed
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            throw LumoError.renderFailed
        }
        return output as Data
    }

    private func sampleNearest(lut: LUT3D, red: Float, green: Float, blue: Float) -> (red: Float, green: Float, blue: Float) {
        let maxIndex = lut.size - 1
        let redIndex = Self.nearestIndex(for: red, maxIndex: maxIndex)
        let greenIndex = Self.nearestIndex(for: green, maxIndex: maxIndex)
        let blueIndex = Self.nearestIndex(for: blue, maxIndex: maxIndex)
        let valueIndex = ((blueIndex * lut.size * lut.size) + (greenIndex * lut.size) + redIndex) * 3
        return (
            lut.values[valueIndex],
            lut.values[valueIndex + 1],
            lut.values[valueIndex + 2]
        )
    }

    private static func nearestIndex(for value: Float, maxIndex: Int) -> Int {
        let clamped = max(0, min(1, value))
        return min(maxIndex, max(0, Int((clamped * Float(maxIndex)).rounded())))
    }

    private static func byte(_ value: Float) -> UInt8 {
        UInt8((max(0, min(1, value)) * 255).rounded())
    }
}
