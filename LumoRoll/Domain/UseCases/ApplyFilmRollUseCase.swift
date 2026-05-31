import Foundation

struct ApplyFilmRollInput: Equatable, Sendable {
    let filmRollID: String
    let originalPhotoPath: String
    let intensity: Double
    let replacingProcessedPhotoID: String?
    let isAdaptivePostProcessEnabled: Bool
    let lutSourceMode: ApplyLUTSourceMode

    init(
        filmRollID: String,
        originalPhotoPath: String,
        intensity: Double,
        replacingProcessedPhotoID: String? = nil,
        isAdaptivePostProcessEnabled: Bool = true,
        lutSourceMode: ApplyLUTSourceMode = .saved
    ) {
        self.filmRollID = filmRollID
        self.originalPhotoPath = originalPhotoPath
        self.intensity = intensity
        self.replacingProcessedPhotoID = replacingProcessedPhotoID
        self.isAdaptivePostProcessEnabled = isAdaptivePostProcessEnabled
        self.lutSourceMode = lutSourceMode
    }
}

struct ApplyLUTResolver: Sendable {
    private let referenceImageDataLoader: FilmRollReferenceImageDataLoading?
    private let diagnosticLUTGenerator: LUTGenerating?

    init(
        referenceImageDataLoader: FilmRollReferenceImageDataLoading? = nil,
        diagnosticLUTGenerator: LUTGenerating? = nil
    ) {
        self.referenceImageDataLoader = referenceImageDataLoader
        self.diagnosticLUTGenerator = diagnosticLUTGenerator
    }

    func lut(for roll: FilmRoll, sourceMode: ApplyLUTSourceMode) async throws -> LUT3D {
        switch sourceMode {
        case .saved:
            return roll.lut
        case .algorithmV2:
            guard let referenceImageDataLoader, let diagnosticLUTGenerator else {
                throw LumoError.storageFailed(message: "Algorithm V2 diagnostic LUT generation is unavailable.")
            }

            let referenceImageData = try await referenceImageDataLoader.loadReferenceImageData(
                at: roll.referenceAsset.originalPath
            )
            return try await diagnosticLUTGenerator.generateLUT(
                for: LUTGenerationRequest(
                    referenceImageData: referenceImageData,
                    size: roll.lut.size,
                    algorithmVersion: LUT3D.defaultAlgorithmVersion
                )
            )
        }
    }
}

struct ApplyFilmRollUseCase: Sendable {
    private let repository: FilmRollRepository
    private let photoRenderer: PhotoRendering
    private let lutResolver: ApplyLUTResolver
    private let now: @Sendable () -> Date
    private let processedPhotoIDGenerator: @Sendable () -> String
    private let serialGate = AsyncSerialGate()

    init(
        repository: FilmRollRepository,
        photoRenderer: PhotoRendering,
        referenceImageDataLoader: FilmRollReferenceImageDataLoading? = nil,
        diagnosticLUTGenerator: LUTGenerating? = nil,
        now: @escaping @Sendable () -> Date = Date.init,
        processedPhotoIDGenerator: @escaping @Sendable () -> String = { UUID().uuidString }
    ) {
        self.repository = repository
        self.photoRenderer = photoRenderer
        lutResolver = ApplyLUTResolver(
            referenceImageDataLoader: referenceImageDataLoader,
            diagnosticLUTGenerator: diagnosticLUTGenerator
        )
        self.now = now
        self.processedPhotoIDGenerator = processedPhotoIDGenerator
    }

    func applyPhoto(input: ApplyFilmRollInput) async throws -> FilmRoll {
        await serialGate.acquire()
        do {
            let roll = try await performApplyPhoto(input: input)
            await serialGate.release()
            return roll
        } catch {
            await serialGate.release()
            throw error
        }
    }

    private func performApplyPhoto(input: ApplyFilmRollInput) async throws -> FilmRoll {
        var roll = try await repository.loadFilmRoll(id: input.filmRollID)
        let replacedPhotoIndex: Int?
        let replacedPhoto: ProcessedPhoto?
        if let replacingProcessedPhotoID = input.replacingProcessedPhotoID {
            guard let index = roll.processedPhotos.firstIndex(where: { $0.id == replacingProcessedPhotoID }) else {
                throw LumoError.processedPhotoNotFound(id: replacingProcessedPhotoID)
            }
            replacedPhotoIndex = index
            replacedPhoto = roll.processedPhotos[index]
        } else {
            replacedPhotoIndex = nil
            replacedPhoto = nil
        }

        let processedPhotoID = processedPhotoIDGenerator()
        let renderLUT = try await lutResolver.lut(for: roll, sourceMode: input.lutSourceMode)
        let renderRequest = PhotoRenderRequest(
            filmRollID: roll.id,
            processedPhotoID: processedPhotoID,
            originalPath: input.originalPhotoPath,
            lut: renderLUT,
            intensity: input.intensity,
            sampleAnalysisPackage: roll.sampleAnalysisPackage,
            isAdaptivePostProcessEnabled: input.isAdaptivePostProcessEnabled
        )
        let renderResult = try await photoRenderer.renderPhoto(for: renderRequest)
        let timestamp = now()
        let processedPhoto = ProcessedPhoto(
            id: replacedPhoto?.id ?? processedPhotoID,
            originalPath: renderResult.originalPath,
            processedPath: renderResult.processedPath,
            thumbnailPath: renderResult.thumbnailPath,
            createdAt: replacedPhoto?.createdAt ?? timestamp,
            intensity: renderResult.intensity,
            adaptiveRenderMetadata: renderResult.adaptiveRenderMetadata
        )

        if let replacedPhotoIndex {
            roll.processedPhotos[replacedPhotoIndex] = processedPhoto
        } else {
            roll.processedPhotos.append(processedPhoto)
        }
        roll.updatedAt = timestamp
        do {
            try await repository.saveFilmRoll(roll)
        } catch {
            await photoRenderer.discardRenderedPhoto(renderResult)
            throw error
        }
        if let replacedPhoto {
            await photoRenderer.discardRenderedPhoto(PhotoRenderResult(processedPhoto: replacedPhoto))
        }
        return roll
    }
}

struct RemoveProcessedPhotoInput: Equatable, Sendable {
    let filmRollID: String
    let processedPhotoID: String
}

struct RemoveProcessedPhotoUseCase: Sendable {
    private let repository: FilmRollRepository
    private let photoRenderer: PhotoRendering
    private let now: @Sendable () -> Date
    private let serialGate = AsyncSerialGate()

    init(
        repository: FilmRollRepository,
        photoRenderer: PhotoRendering,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.repository = repository
        self.photoRenderer = photoRenderer
        self.now = now
    }

    func removeProcessedPhoto(input: RemoveProcessedPhotoInput) async throws -> FilmRoll {
        await serialGate.acquire()
        do {
            let roll = try await performRemoveProcessedPhoto(input: input)
            await serialGate.release()
            return roll
        } catch {
            await serialGate.release()
            throw error
        }
    }

    private func performRemoveProcessedPhoto(input: RemoveProcessedPhotoInput) async throws -> FilmRoll {
        var roll = try await repository.loadFilmRoll(id: input.filmRollID)
        guard let index = roll.processedPhotos.firstIndex(where: { $0.id == input.processedPhotoID }) else {
            throw LumoError.processedPhotoNotFound(id: input.processedPhotoID)
        }

        let removedPhoto = roll.processedPhotos.remove(at: index)
        roll.updatedAt = now()
        try await repository.saveFilmRoll(roll)
        await photoRenderer.discardRenderedPhoto(PhotoRenderResult(processedPhoto: removedPhoto))
        return roll
    }
}

private extension PhotoRenderResult {
    init(processedPhoto: ProcessedPhoto) {
        self.init(
            originalPath: processedPhoto.originalPath,
            processedPath: processedPhoto.processedPath,
            thumbnailPath: processedPhoto.thumbnailPath,
            intensity: processedPhoto.intensity,
            adaptiveRenderMetadata: processedPhoto.adaptiveRenderMetadata
        )
    }
}

private actor AsyncSerialGate {
    private var isLocked = false
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func acquire() async {
        if !isLocked {
            isLocked = true
            return
        }

        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }

    func release() {
        if waiters.isEmpty {
            isLocked = false
        } else {
            let nextWaiter = waiters.removeFirst()
            nextWaiter.resume()
        }
    }
}
