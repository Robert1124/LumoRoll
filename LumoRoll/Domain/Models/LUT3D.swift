import Foundation

struct LUT3D: Codable, Equatable, Identifiable, Sendable {
    static let defaultSize = 33
    static let defaultAlgorithmVersion = "mvp1.traditional.v2"

    let id: String
    let size: Int
    let values: [Float]
    let algorithmVersion: String

    var sampleCount: Int {
        values.count / Self.channelsPerSample
    }

    init(
        id: String = UUID().uuidString,
        size: Int = Self.defaultSize,
        values: [Float],
        algorithmVersion: String = Self.defaultAlgorithmVersion
    ) throws {
        guard size > 0 else {
            throw LumoError.invalidLUTSize(size)
        }

        let expectedValueCount = Self.expectedValueCount(for: size)
        guard values.count == expectedValueCount else {
            throw LumoError.invalidLUTSampleCount(expected: expectedValueCount, actual: values.count)
        }

        if let invalidIndex = values.firstIndex(where: { !$0.isFinite || $0 < 0 || $0 > 1 }) {
            throw LumoError.invalidLUTValue(index: invalidIndex)
        }

        self.id = id
        self.size = size
        self.values = values
        self.algorithmVersion = algorithmVersion
    }

    static func identity(size: Int = defaultSize, algorithmVersion: String = defaultAlgorithmVersion) -> LUT3D {
        var values: [Float] = []
        values.reserveCapacity(expectedValueCount(for: size))

        let maxIndex = Float(size - 1)
        for blue in 0..<size {
            for green in 0..<size {
                for red in 0..<size {
                    values.append(Float(red) / maxIndex)
                    values.append(Float(green) / maxIndex)
                    values.append(Float(blue) / maxIndex)
                }
            }
        }

        return try! LUT3D(size: size, values: values, algorithmVersion: algorithmVersion)
    }

    static func expectedSampleCount(for size: Int = defaultSize) -> Int {
        size * size * size
    }

    static func expectedValueCount(for size: Int = defaultSize) -> Int {
        expectedSampleCount(for: size) * channelsPerSample
    }

    private static let channelsPerSample = 3
}
