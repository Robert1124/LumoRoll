import Foundation

struct LUTGenerationRequest: Codable, Equatable, Sendable {
    let referenceImageData: Data
    let size: Int
    let algorithmVersion: String

    init(
        referenceImageData: Data,
        size: Int = LUT3D.defaultSize,
        algorithmVersion: String = LUT3D.defaultAlgorithmVersion
    ) {
        self.referenceImageData = referenceImageData
        self.size = size
        self.algorithmVersion = algorithmVersion
    }
}

struct LUTGenerationResult: Equatable, Sendable {
    let lut: LUT3D
    let sampleAnalysisPackage: SampleAnalysisPackage?

    init(lut: LUT3D, sampleAnalysisPackage: SampleAnalysisPackage? = nil) {
        self.lut = lut
        self.sampleAnalysisPackage = sampleAnalysisPackage
    }
}

protocol LUTGenerating: Sendable {
    func generateLUT(for request: LUTGenerationRequest) async throws -> LUT3D
    func generateFilmRollPackage(for request: LUTGenerationRequest) async throws -> LUTGenerationResult
}

extension LUTGenerating {
    func generateFilmRollPackage(for request: LUTGenerationRequest) async throws -> LUTGenerationResult {
        let lut = try await generateLUT(for: request)
        return LUTGenerationResult(lut: lut)
    }
}

enum ApplyLUTSourceMode: String, Codable, Equatable, Sendable {
    case saved
    case algorithmV2
}

protocol FilmRollReferenceImageDataLoading: Sendable {
    func loadReferenceImageData(at path: String) async throws -> Data
}

protocol LUTImporting: Sendable {
    func importLUT(fromCubeTextData data: Data) throws -> LUT3D
}
