import XCTest
@testable import LumoRoll

final class ApplyFilmRollUseCaseTests: XCTestCase {
    func testApplyLoadsRollRendersPhotoAppendsProcessedPhotoAndSavesRoll() async throws {
        let repository = SpyFilmRollRepository()
        let samplePackage = modelAssistedTestSampleAnalysisPackage()
        let adaptiveMetadata = modelAssistedTestAdaptiveRenderMetadata()
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Portra Morning",
            createdAt: Date(timeIntervalSince1970: 10),
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: try testLUT(size: 2, redOffset: 0.05),
            sampleAnalysisPackage: samplePackage
        )
        repository.filmRollsByID[roll.id] = roll
        let renderer = SpyPhotoRenderer(
            result: PhotoRenderResult(
                originalPath: "film-rolls/roll-1/processed/generated-photo-id/original.jpg",
                processedPath: "film-rolls/roll-1/processed/generated-photo-id/rendered.jpg",
                thumbnailPath: "film-rolls/roll-1/processed/generated-photo-id/thumbnail.jpg",
                intensity: 42,
                adaptiveRenderMetadata: adaptiveMetadata
            )
        )
        let useCase = ApplyFilmRollUseCase(
            repository: repository,
            photoRenderer: renderer,
            now: { Date(timeIntervalSince1970: 200) },
            processedPhotoIDGenerator: { "generated-photo-id" }
        )

        let savedRoll = try await useCase.applyPhoto(
            input: ApplyFilmRollInput(
                filmRollID: "roll-1",
                originalPhotoPath: "imports/photo-1.jpg",
                intensity: 42
            )
        )

        XCTAssertEqual(repository.loadedIDs, ["roll-1"])
        XCTAssertEqual(renderer.requests, [
            PhotoRenderRequest(
                filmRollID: "roll-1",
                processedPhotoID: "generated-photo-id",
                originalPath: "imports/photo-1.jpg",
                lut: roll.lut,
                intensity: 42,
                sampleAnalysisPackage: samplePackage
            )
        ])
        XCTAssertEqual(savedRoll.processedPhotos.count, 1)
        XCTAssertEqual(savedRoll.processedPhotos.first?.id, "generated-photo-id")
        XCTAssertEqual(savedRoll.processedPhotos.first?.originalPath, "film-rolls/roll-1/processed/generated-photo-id/original.jpg")
        XCTAssertEqual(savedRoll.processedPhotos.first?.processedPath, "film-rolls/roll-1/processed/generated-photo-id/rendered.jpg")
        XCTAssertEqual(savedRoll.processedPhotos.first?.thumbnailPath, "film-rolls/roll-1/processed/generated-photo-id/thumbnail.jpg")
        XCTAssertEqual(savedRoll.processedPhotos.first?.createdAt, Date(timeIntervalSince1970: 200))
        XCTAssertEqual(savedRoll.processedPhotos.first?.intensity, 42)
        XCTAssertEqual(savedRoll.processedPhotos.first?.adaptiveRenderMetadata, adaptiveMetadata)
        XCTAssertEqual(savedRoll.updatedAt, Date(timeIntervalSince1970: 200))
        XCTAssertEqual(repository.savedFilmRolls, [savedRoll])
    }

    func testApplyCanDisableAdaptivePostProcessForDiagnosticRender() async throws {
        let repository = SpyFilmRollRepository()
        let samplePackage = modelAssistedTestSampleAnalysisPackage()
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Diagnostic Roll",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: try testLUT(size: 2, redOffset: 0.05),
            sampleAnalysisPackage: samplePackage
        )
        repository.filmRollsByID[roll.id] = roll
        let renderer = SpyPhotoRenderer()
        let useCase = ApplyFilmRollUseCase(
            repository: repository,
            photoRenderer: renderer,
            processedPhotoIDGenerator: { "generated-photo-id" }
        )

        _ = try await useCase.applyPhoto(
            input: ApplyFilmRollInput(
                filmRollID: "roll-1",
                originalPhotoPath: "imports/photo-1.jpg",
                intensity: 42,
                isAdaptivePostProcessEnabled: false
            )
        )

        XCTAssertEqual(renderer.requests.first?.sampleAnalysisPackage, samplePackage)
        XCTAssertEqual(renderer.requests.first?.isAdaptivePostProcessEnabled, false)
    }

    func testApplyCanUseTransientAlgorithmV2LUTWithoutReplacingSavedRollLUT() async throws {
        let repository = SpyFilmRollRepository()
        let savedLUT = LUT3D.identity(size: 2, algorithmVersion: "private.model.v1")
        let transientV2LUT = LUT3D.identity(size: 2, algorithmVersion: LUT3D.defaultAlgorithmVersion)
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Diagnostic V2 Roll",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: savedLUT
        )
        repository.filmRollsByID[roll.id] = roll
        let referenceData = Data([0x01, 0x02, 0x03])
        let referenceLoader = StubReferenceImageDataLoader(data: referenceData)
        let lutGenerator = StubDiagnosticLUTGenerator(lut: transientV2LUT)
        let renderer = SpyPhotoRenderer()
        let useCase = ApplyFilmRollUseCase(
            repository: repository,
            photoRenderer: renderer,
            referenceImageDataLoader: referenceLoader,
            diagnosticLUTGenerator: lutGenerator,
            processedPhotoIDGenerator: { "generated-photo-id" }
        )

        let savedRoll = try await useCase.applyPhoto(
            input: ApplyFilmRollInput(
                filmRollID: "roll-1",
                originalPhotoPath: "imports/photo-1.jpg",
                intensity: 42,
                lutSourceMode: .algorithmV2
            )
        )

        XCTAssertEqual(referenceLoader.paths, [roll.referenceAsset.originalPath])
        XCTAssertEqual(lutGenerator.requests.map(\.referenceImageData), [referenceData])
        XCTAssertEqual(lutGenerator.requests.map(\.size), [savedLUT.size])
        XCTAssertEqual(lutGenerator.requests.map(\.algorithmVersion), [LUT3D.defaultAlgorithmVersion])
        XCTAssertEqual(renderer.requests.first?.lut, transientV2LUT)
        XCTAssertEqual(savedRoll.lut, savedLUT)
        XCTAssertEqual(repository.savedFilmRolls.last?.lut, savedLUT)
    }

    func testApplyCanReplaceExistingProcessedPhotoWithoutAppending() async throws {
        let existingPhoto = ProcessedPhoto(
            id: "processed-1",
            originalPath: "film-rolls/roll-1/processed/processed-1/original.jpg",
            processedPath: "film-rolls/roll-1/processed/processed-1/rendered.jpg",
            thumbnailPath: "film-rolls/roll-1/processed/processed-1/thumbnail.jpg",
            createdAt: Date(timeIntervalSince1970: 50),
            intensity: 35
        )
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Editable Roll",
            createdAt: Date(timeIntervalSince1970: 10),
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: LUT3D.identity(),
            processedPhotos: [existingPhoto]
        )
        let repository = SpyFilmRollRepository()
        repository.filmRollsByID[roll.id] = roll
        let renderResult = PhotoRenderResult(
            originalPath: "film-rolls/roll-1/processed/edited-render/original.jpg",
            processedPath: "film-rolls/roll-1/processed/edited-render/rendered.jpg",
            thumbnailPath: "film-rolls/roll-1/processed/edited-render/thumbnail.jpg",
            intensity: 62
        )
        let renderer = SpyPhotoRenderer(result: renderResult)
        let useCase = ApplyFilmRollUseCase(
            repository: repository,
            photoRenderer: renderer,
            now: { Date(timeIntervalSince1970: 200) },
            processedPhotoIDGenerator: { "edited-render" }
        )

        let savedRoll = try await useCase.applyPhoto(
            input: ApplyFilmRollInput(
                filmRollID: "roll-1",
                originalPhotoPath: existingPhoto.originalPath,
                intensity: 62,
                replacingProcessedPhotoID: "processed-1"
            )
        )

        XCTAssertEqual(renderer.requests.map(\.processedPhotoID), ["edited-render"])
        XCTAssertEqual(savedRoll.processedPhotos.count, 1)
        XCTAssertEqual(savedRoll.processedPhotos[0].id, "processed-1")
        XCTAssertEqual(savedRoll.processedPhotos[0].originalPath, renderResult.originalPath)
        XCTAssertEqual(savedRoll.processedPhotos[0].processedPath, renderResult.processedPath)
        XCTAssertEqual(savedRoll.processedPhotos[0].thumbnailPath, renderResult.thumbnailPath)
        XCTAssertEqual(savedRoll.processedPhotos[0].createdAt, existingPhoto.createdAt)
        XCTAssertEqual(savedRoll.processedPhotos[0].intensity, 62)
        XCTAssertEqual(savedRoll.updatedAt, Date(timeIntervalSince1970: 200))
        XCTAssertEqual(
            renderer.discardedResults,
            [
                PhotoRenderResult(
                    originalPath: existingPhoto.originalPath,
                    processedPath: existingPhoto.processedPath,
                    thumbnailPath: existingPhoto.thumbnailPath,
                    intensity: existingPhoto.intensity
                )
            ]
        )
    }

    func testApplyUseCaseHasNoPhotosLibraryWriterDependency() {
        let useCase = ApplyFilmRollUseCase(
            repository: SpyFilmRollRepository(),
            photoRenderer: SpyPhotoRenderer(),
            now: Date.init
        )

        XCTAssertNotNil(useCase)
    }

    func testApplyRenderFailureDoesNotSave() async throws {
        let repository = SpyFilmRollRepository()
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Portra Morning",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: LUT3D.identity()
        )
        repository.filmRollsByID[roll.id] = roll
        let renderer = SpyPhotoRenderer(error: LumoError.renderFailed)
        let useCase = ApplyFilmRollUseCase(repository: repository, photoRenderer: renderer)

        await XCTAssertThrowsAsyncError(
            try await useCase.applyPhoto(
                input: ApplyFilmRollInput(filmRollID: "roll-1", originalPhotoPath: "imports/photo-1.jpg", intensity: 80)
            )
        ) { error in
            XCTAssertEqual(error as? LumoError, .renderFailed)
        }

        XCTAssertEqual(repository.savedFilmRolls, [])
        XCTAssertEqual(renderer.discardedResults, [])
    }

    func testApplyRepositorySaveFailureAfterRenderCleansRenderedOutputAndRethrowsSaveError() async throws {
        let saveError = LumoError.storageFailed(message: "manifest save failed")
        let repository = SpyFilmRollRepository(saveError: saveError)
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Portra Morning",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: LUT3D.identity()
        )
        repository.filmRollsByID[roll.id] = roll
        let renderResult = PhotoRenderResult(
            originalPath: "film-rolls/roll-1/processed/photo-1/original.jpg",
            processedPath: "film-rolls/roll-1/processed/photo-1/rendered.jpg",
            thumbnailPath: "film-rolls/roll-1/processed/photo-1/thumbnail.jpg",
            intensity: 65
        )
        let renderer = SpyPhotoRenderer(result: renderResult)
        let useCase = ApplyFilmRollUseCase(repository: repository, photoRenderer: renderer)

        await XCTAssertThrowsAsyncError(
            try await useCase.applyPhoto(
                input: ApplyFilmRollInput(filmRollID: "roll-1", originalPhotoPath: "imports/photo-1.jpg", intensity: 65)
            )
        ) { error in
            XCTAssertEqual(error as? LumoError, saveError)
        }

        XCTAssertEqual(repository.savedFilmRolls, [])
        XCTAssertEqual(renderer.discardedResults, [renderResult])
    }

    func testConcurrentApplyOperationsForSameRollPreserveBothProcessedPhotos() async throws {
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Concurrent Roll",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: LUT3D.identity(size: 2)
        )
        let repository = ConcurrentApplyFilmRollRepository(filmRolls: [roll])
        let renderer = ConcurrentSuspendingPhotoRenderer()
        let useCase = ApplyFilmRollUseCase(
            repository: repository,
            photoRenderer: renderer,
            now: { Date(timeIntervalSince1970: 300) }
        )

        async let firstRoll = useCase.applyPhoto(
            input: ApplyFilmRollInput(filmRollID: roll.id, originalPhotoPath: "imports/first.jpg", intensity: 40)
        )
        async let secondRoll = useCase.applyPhoto(
            input: ApplyFilmRollInput(filmRollID: roll.id, originalPhotoPath: "imports/second.jpg", intensity: 70)
        )

        await renderer.waitForRequestCount(1)
        try await Task.sleep(nanoseconds: 50_000_000)
        await renderer.resumeOldest()
        await renderer.waitForRequestCount(2)
        await renderer.resumeOldest()

        _ = try await firstRoll
        _ = try await secondRoll
        let finalRoll = try await repository.loadFilmRoll(id: roll.id)

        XCTAssertEqual(finalRoll.processedPhotos.count, 2)
        XCTAssertEqual(Set(finalRoll.processedPhotos.map(\.intensity)), Set([40, 70]))
    }

    func testRemoveProcessedPhotoUpdatesManifestAndDiscardsAssets() async throws {
        let removedPhoto = ProcessedPhoto(
            id: "processed-remove",
            originalPath: "film-rolls/roll-1/processed/processed-remove/original.jpg",
            processedPath: "film-rolls/roll-1/processed/processed-remove/rendered.jpg",
            thumbnailPath: "film-rolls/roll-1/processed/processed-remove/thumbnail.jpg",
            createdAt: Date(timeIntervalSince1970: 20),
            intensity: 70
        )
        let keptPhoto = ProcessedPhoto(
            id: "processed-keep",
            originalPath: "film-rolls/roll-1/processed/processed-keep/original.jpg",
            processedPath: "film-rolls/roll-1/processed/processed-keep/rendered.jpg",
            thumbnailPath: "film-rolls/roll-1/processed/processed-keep/thumbnail.jpg",
            createdAt: Date(timeIntervalSince1970: 30),
            intensity: 55
        )
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Remove Roll",
            createdAt: Date(timeIntervalSince1970: 10),
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: LUT3D.identity(),
            processedPhotos: [removedPhoto, keptPhoto]
        )
        let repository = SpyFilmRollRepository()
        repository.filmRollsByID[roll.id] = roll
        let renderer = SpyPhotoRenderer()
        let useCase = RemoveProcessedPhotoUseCase(
            repository: repository,
            photoRenderer: renderer,
            now: { Date(timeIntervalSince1970: 200) }
        )

        let updatedRoll = try await useCase.removeProcessedPhoto(
            input: RemoveProcessedPhotoInput(filmRollID: "roll-1", processedPhotoID: "processed-remove")
        )

        XCTAssertEqual(updatedRoll.processedPhotos, [keptPhoto])
        XCTAssertEqual(updatedRoll.updatedAt, Date(timeIntervalSince1970: 200))
        XCTAssertEqual(repository.savedFilmRolls, [updatedRoll])
        XCTAssertEqual(
            renderer.discardedResults,
            [
                PhotoRenderResult(
                    originalPath: removedPhoto.originalPath,
                    processedPath: removedPhoto.processedPath,
                    thumbnailPath: removedPhoto.thumbnailPath,
                    intensity: removedPhoto.intensity
                )
            ]
        )
    }

    func testRemoveProcessedPhotoMissingIDDoesNotSaveOrDiscard() async throws {
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Remove Roll",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: LUT3D.identity()
        )
        let repository = SpyFilmRollRepository()
        repository.filmRollsByID[roll.id] = roll
        let renderer = SpyPhotoRenderer()
        let useCase = RemoveProcessedPhotoUseCase(repository: repository, photoRenderer: renderer)

        await XCTAssertThrowsAsyncError(
            try await useCase.removeProcessedPhoto(
                input: RemoveProcessedPhotoInput(filmRollID: "roll-1", processedPhotoID: "missing-photo")
            )
        ) { error in
            XCTAssertEqual(error as? LumoError, .processedPhotoNotFound(id: "missing-photo"))
        }

        XCTAssertEqual(repository.savedFilmRolls, [])
        XCTAssertEqual(renderer.discardedResults, [])
    }
}

private final class SpyPhotoRenderer: PhotoRendering, @unchecked Sendable {
    let result: PhotoRenderResult
    let error: Error?
    private(set) var requests: [PhotoRenderRequest] = []
    private(set) var discardedResults: [PhotoRenderResult] = []

    init(
        result: PhotoRenderResult = PhotoRenderResult(originalPath: "original.jpg", processedPath: "processed.jpg", thumbnailPath: "thumb.jpg", intensity: 100),
        error: Error? = nil
    ) {
        self.result = result
        self.error = error
    }

    func renderPhoto(for request: PhotoRenderRequest) async throws -> PhotoRenderResult {
        requests.append(request)
        if let error {
            throw error
        }
        return result
    }

    func discardRenderedPhoto(_ result: PhotoRenderResult) async {
        discardedResults.append(result)
    }
}

private final class SpyFilmRollRepository: FilmRollRepository, @unchecked Sendable {
    var filmRollsByID: [String: FilmRoll] = [:]
    let saveError: Error?
    private(set) var loadedIDs: [String] = []
    private(set) var savedFilmRolls: [FilmRoll] = []

    init(saveError: Error? = nil) {
        self.saveError = saveError
    }

    func loadFilmRolls() async throws -> [FilmRoll] {
        Array(filmRollsByID.values)
    }

    func loadFilmRoll(id: String) async throws -> FilmRoll {
        loadedIDs.append(id)
        guard let roll = filmRollsByID[id] else {
            throw LumoError.filmRollNotFound(id: id)
        }
        return roll
    }

    func saveFilmRoll(_ filmRoll: FilmRoll) async throws {
        if let saveError {
            throw saveError
        }
        savedFilmRolls.append(filmRoll)
        filmRollsByID[filmRoll.id] = filmRoll
    }

    func deleteFilmRoll(id: String) async throws {
        filmRollsByID[id] = nil
    }
}

private final class StubReferenceImageDataLoader: FilmRollReferenceImageDataLoading, @unchecked Sendable {
    let data: Data
    private(set) var paths: [String] = []

    init(data: Data) {
        self.data = data
    }

    func loadReferenceImageData(at path: String) async throws -> Data {
        paths.append(path)
        return data
    }
}

private final class StubDiagnosticLUTGenerator: LUTGenerating, @unchecked Sendable {
    let lut: LUT3D
    private(set) var requests: [LUTGenerationRequest] = []

    init(lut: LUT3D) {
        self.lut = lut
    }

    func generateLUT(for request: LUTGenerationRequest) async throws -> LUT3D {
        requests.append(request)
        return lut
    }
}

private actor ConcurrentApplyFilmRollRepository: FilmRollRepository {
    private var filmRollsByID: [String: FilmRoll]
    private(set) var savedFilmRolls: [FilmRoll] = []

    init(filmRolls: [FilmRoll]) {
        filmRollsByID = Dictionary(uniqueKeysWithValues: filmRolls.map { ($0.id, $0) })
    }

    func loadFilmRolls() async throws -> [FilmRoll] {
        Array(filmRollsByID.values)
    }

    func loadFilmRoll(id: String) async throws -> FilmRoll {
        guard let roll = filmRollsByID[id] else {
            throw LumoError.filmRollNotFound(id: id)
        }
        return roll
    }

    func saveFilmRoll(_ filmRoll: FilmRoll) async throws {
        savedFilmRolls.append(filmRoll)
        filmRollsByID[filmRoll.id] = filmRoll
    }

    func deleteFilmRoll(id: String) async throws {
        filmRollsByID[id] = nil
    }
}

private actor ConcurrentSuspendingPhotoRenderer: PhotoRendering {
    private var requests: [PhotoRenderRequest] = []
    private var pendingRenders: [(request: PhotoRenderRequest, continuation: CheckedContinuation<PhotoRenderResult, Error>)] = []
    private var requestWaiters: [CheckedContinuation<Void, Never>] = []

    func renderPhoto(for request: PhotoRenderRequest) async throws -> PhotoRenderResult {
        try await withCheckedThrowingContinuation { continuation in
            requests.append(request)
            pendingRenders.append((request, continuation))
            requestWaiters.forEach { $0.resume() }
            requestWaiters.removeAll()
        }
    }

    func waitForRequestCount(_ expectedCount: Int) async {
        if requests.count >= expectedCount {
            return
        }
        await withCheckedContinuation { continuation in
            requestWaiters.append(continuation)
        }
    }

    func resumeOldest() {
        guard !pendingRenders.isEmpty else {
            return
        }
        let pending = pendingRenders.removeFirst()
        pending.continuation.resume(
            returning: PhotoRenderResult(
                originalPath: "film-rolls/\(pending.request.filmRollID)/processed/\(pending.request.processedPhotoID)/original.jpg",
                processedPath: "film-rolls/\(pending.request.filmRollID)/processed/\(pending.request.processedPhotoID)/rendered.jpg",
                thumbnailPath: "film-rolls/\(pending.request.filmRollID)/processed/\(pending.request.processedPhotoID)/thumbnail.jpg",
                intensity: pending.request.intensity
            )
        )
    }

    func discardRenderedPhoto(_ result: PhotoRenderResult) async {}
}

private func testLUT(size: Int = 2, redOffset: Float = 0) throws -> LUT3D {
    let identity = LUT3D.identity(size: size)
    let values = identity.values.enumerated().map { index, value in
        index.isMultiple(of: 3) ? min(1, value + redOffset) : value
    }
    return try LUT3D(size: size, values: values, algorithmVersion: "test")
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
