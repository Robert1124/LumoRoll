import Foundation

enum CreateFilmRollSource: Equatable, Sendable {
    case referenceImage(data: Data, preferredFileExtension: String?)
    case cubeLUT(data: Data, originalFilename: String?)
}

struct CreateFilmRollInput: Equatable, Sendable {
    let name: String
    let source: CreateFilmRollSource

    init(name: String, referenceImageData: Data, preferredFileExtension: String? = nil) {
        self.name = name
        source = .referenceImage(data: referenceImageData, preferredFileExtension: preferredFileExtension)
    }

    init(name: String, cubeLUTData: Data, originalFilename: String? = nil) {
        self.name = name
        source = .cubeLUT(data: cubeLUTData, originalFilename: originalFilename)
    }
}

struct CreateFilmRollUseCase: Sendable {
    private let repository: FilmRollRepository
    private let lutGenerator: LUTGenerating
    private let lutImporter: LUTImporting
    private let lutPreviewRenderer: LUTPreviewRendering
    private let thumbnailRenderer: ThumbnailRendering
    private let assetWriter: FilmRollAssetWriting
    private let now: @Sendable () -> Date

    init(
        repository: FilmRollRepository,
        lutGenerator: LUTGenerating,
        lutImporter: LUTImporting = UnavailableLUTImporter(),
        lutPreviewRenderer: LUTPreviewRendering = UnavailableLUTPreviewRenderer(),
        thumbnailRenderer: ThumbnailRendering,
        assetWriter: FilmRollAssetWriting,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.repository = repository
        self.lutGenerator = lutGenerator
        self.lutImporter = lutImporter
        self.lutPreviewRenderer = lutPreviewRenderer
        self.thumbnailRenderer = thumbnailRenderer
        self.assetWriter = assetWriter
        self.now = now
    }

    func createFilmRoll(input: CreateFilmRollInput) async throws -> FilmRoll {
        let trimmedName = input.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw LumoError.invalidFilmRollName
        }

        let preparedInput = try await prepareInputAssets(from: input.source)
        let thumbnailData = try await thumbnailRenderer.renderThumbnail(from: preparedInput.referenceImageData)
        let filmRollID = try await assetWriter.reserveFilmRollID()
        let referenceAsset: FilmRollReferenceAsset
        do {
            referenceAsset = try await assetWriter.storeReferenceImage(
                filmRollID: filmRollID,
                imageData: preparedInput.referenceImageData,
                thumbnailData: thumbnailData,
                preferredFileExtension: preparedInput.preferredFileExtension
            )
        } catch {
            await assetWriter.discardFilmRollAssets(filmRollID: filmRollID)
            throw error
        }

        let createdAt = now()
        let roll = try FilmRoll(
            id: filmRollID,
            name: trimmedName,
            createdAt: createdAt,
            referenceAsset: referenceAsset,
            lut: preparedInput.lut,
            sampleAnalysisPackage: preparedInput.sampleAnalysisPackage
        )

        do {
            try await repository.saveFilmRoll(roll)
        } catch {
            await assetWriter.discardFilmRollAssets(filmRollID: filmRollID)
            throw error
        }
        return roll
    }

    private func prepareInputAssets(from source: CreateFilmRollSource) async throws -> PreparedFilmRollInput {
        switch source {
        case .referenceImage(let data, let preferredFileExtension):
            let result = try await lutGenerator.generateFilmRollPackage(
                for: LUTGenerationRequest(
                    referenceImageData: data,
                    size: LUT3D.defaultSize,
                    algorithmVersion: LUT3D.defaultAlgorithmVersion
                )
            )
            return PreparedFilmRollInput(
                lut: result.lut,
                sampleAnalysisPackage: result.sampleAnalysisPackage,
                referenceImageData: data,
                preferredFileExtension: preferredFileExtension
            )
        case .cubeLUT(let data, _):
            let lut = try lutImporter.importLUT(fromCubeTextData: data)
            let previewImageData = try lutPreviewRenderer.renderPreviewImage(for: lut)
            return PreparedFilmRollInput(
                lut: lut,
                sampleAnalysisPackage: nil,
                referenceImageData: previewImageData,
                preferredFileExtension: "png"
            )
        }
    }
}

private struct PreparedFilmRollInput: Sendable {
    let lut: LUT3D
    let sampleAnalysisPackage: SampleAnalysisPackage?
    let referenceImageData: Data
    let preferredFileExtension: String?
}

private struct UnavailableLUTImporter: LUTImporting {
    func importLUT(fromCubeTextData data: Data) throws -> LUT3D {
        throw LumoError.importFailed
    }
}

private struct UnavailableLUTPreviewRenderer: LUTPreviewRendering {
    func renderPreviewImage(for lut: LUT3D) throws -> Data {
        throw LumoError.renderFailed
    }
}
