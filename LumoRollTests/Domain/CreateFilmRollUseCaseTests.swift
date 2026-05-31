import XCTest
@testable import LumoRoll

final class CreateFilmRollUseCaseTests: XCTestCase {
    func testCreateSuccessSavesNamedRollWithOneReferenceAssetAndGeneratedLUT() async throws {
        let repository = SpyFilmRollRepository()
        let samplePackage = modelAssistedTestSampleAnalysisPackage()
        let generator = SpyLUTGenerator(
            lut: try testLUT(size: 2, redOffset: 0.1, algorithmVersion: LUT3D.defaultAlgorithmVersion),
            sampleAnalysisPackage: samplePackage
        )
        let thumbnailRenderer = SpyThumbnailRenderer(thumbnailData: Data([9, 8, 7]))
        let assetWriter = SpyFilmRollAssetWriter(
            reservedID: "roll-generated-id",
            referenceAsset: FilmRollReferenceAsset(
                originalPath: "film-rolls/roll-generated-id/reference/original.jpg",
                thumbnailPath: "film-rolls/roll-generated-id/reference/thumb.jpg"
            )
        )
        let useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: generator,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter,
            now: { Date(timeIntervalSince1970: 100) }
        )
        let referenceData = Data([1, 2, 3, 4])

        let roll = try await useCase.createFilmRoll(
            input: CreateFilmRollInput(
                name: "  Portra Morning  ",
                referenceImageData: referenceData,
                preferredFileExtension: "jpg"
            )
        )

        XCTAssertEqual(roll.id, "roll-generated-id")
        XCTAssertEqual(roll.name, "Portra Morning")
        XCTAssertEqual(roll.referenceAsset.originalPath, "film-rolls/roll-generated-id/reference/original.jpg")
        XCTAssertEqual(roll.referenceAsset.thumbnailPath, "film-rolls/roll-generated-id/reference/thumb.jpg")
        XCTAssertEqual(roll.lut, generator.lut)
        XCTAssertEqual(roll.lut.algorithmVersion, LUT3D.defaultAlgorithmVersion)
        XCTAssertEqual(roll.sampleAnalysisPackage, samplePackage)
        XCTAssertEqual(roll.processedPhotos, [])
        XCTAssertEqual(repository.savedFilmRolls, [roll])
        XCTAssertEqual(generator.requests, [
            LUTGenerationRequest(referenceImageData: referenceData, size: 33, algorithmVersion: LUT3D.defaultAlgorithmVersion)
        ])
        XCTAssertEqual(thumbnailRenderer.receivedImageData, [referenceData])
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.count, 1)
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.first?.filmRollID, "roll-generated-id")
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.first?.imageData, referenceData)
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.first?.thumbnailData, Data([9, 8, 7]))
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.first?.preferredFileExtension, "jpg")
    }

    func testCreateFromCubeLUTImportsLUTAndStoresGeneratedReferencePreview() async throws {
        let repository = SpyFilmRollRepository()
        let generator = SpyLUTGenerator(lut: LUT3D.identity())
        let importedLUT = try testLUT(size: 2, redOffset: 0.2)
        let lutImporter = SpyLUTImporter(lut: importedLUT)
        let previewRenderer = SpyLUTPreviewRenderer(previewData: Data([7, 7, 7]))
        let thumbnailRenderer = SpyThumbnailRenderer(thumbnailData: Data([4, 4, 4]))
        let assetWriter = SpyFilmRollAssetWriter(
            reservedID: "imported-cube-roll",
            referenceAsset: FilmRollReferenceAsset(
                originalPath: "film-rolls/imported-cube-roll/reference/original.png",
                thumbnailPath: "film-rolls/imported-cube-roll/reference/thumb.jpg"
            )
        )
        let useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: generator,
            lutImporter: lutImporter,
            lutPreviewRenderer: previewRenderer,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter,
            now: { Date(timeIntervalSince1970: 200) }
        )
        let cubeData = Data("LUT_3D_SIZE 2".utf8)

        let roll = try await useCase.createFilmRoll(
            input: CreateFilmRollInput(
                name: " Imported Cube ",
                cubeLUTData: cubeData,
                originalFilename: "warm.cube"
            )
        )

        XCTAssertEqual(roll.id, "imported-cube-roll")
        XCTAssertEqual(roll.name, "Imported Cube")
        XCTAssertEqual(roll.lut, importedLUT)
        XCTAssertNil(roll.sampleAnalysisPackage)
        XCTAssertEqual(generator.requests, [])
        XCTAssertEqual(lutImporter.receivedCubeTextData, [cubeData])
        XCTAssertEqual(previewRenderer.receivedLUTs, [importedLUT])
        XCTAssertEqual(thumbnailRenderer.receivedImageData, [Data([7, 7, 7])])
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.first?.imageData, Data([7, 7, 7]))
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.first?.thumbnailData, Data([4, 4, 4]))
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.first?.preferredFileExtension, "png")
        XCTAssertEqual(repository.savedFilmRolls, [roll])
    }

    func testCreateRejectsWhitespaceNameBeforeGeneratingWritingOrSaving() async {
        let repository = SpyFilmRollRepository()
        let generator = SpyLUTGenerator(lut: LUT3D.identity())
        let thumbnailRenderer = SpyThumbnailRenderer(thumbnailData: Data([1]))
        let assetWriter = SpyFilmRollAssetWriter(
            reservedID: "roll-id",
            referenceAsset: FilmRollReferenceAsset(originalPath: "original.jpg", thumbnailPath: "thumb.jpg")
        )
        let useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: generator,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter
        )

        await XCTAssertThrowsAsyncError(
            try await useCase.createFilmRoll(
                input: CreateFilmRollInput(name: " \n\t ", referenceImageData: Data([1]), preferredFileExtension: "jpg")
            )
        ) { error in
            XCTAssertEqual(error as? LumoError, .invalidFilmRollName)
        }

        XCTAssertEqual(generator.requests, [])
        XCTAssertEqual(thumbnailRenderer.receivedImageData, [])
        XCTAssertEqual(assetWriter.reservedIDCallCount, 0)
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.count, 0)
        XCTAssertEqual(repository.savedFilmRolls, [])
    }

    func testCreatePropagatesGenerationFailureAndDoesNotWriteOrSave() async {
        let repository = SpyFilmRollRepository()
        let generator = SpyLUTGenerator(error: LumoError.importFailed)
        let thumbnailRenderer = SpyThumbnailRenderer(thumbnailData: Data([1]))
        let assetWriter = SpyFilmRollAssetWriter(
            reservedID: "roll-id",
            referenceAsset: FilmRollReferenceAsset(originalPath: "original.jpg", thumbnailPath: "thumb.jpg")
        )
        let useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: generator,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter
        )
        let referenceData = Data([4, 3, 2, 1])

        await XCTAssertThrowsAsyncError(
            try await useCase.createFilmRoll(
                input: CreateFilmRollInput(name: "Failed Roll", referenceImageData: referenceData, preferredFileExtension: "png")
            )
        ) { error in
            XCTAssertEqual(error as? LumoError, .importFailed)
        }

        XCTAssertEqual(generator.requests, [
            LUTGenerationRequest(referenceImageData: referenceData, size: 33, algorithmVersion: LUT3D.defaultAlgorithmVersion)
        ])
        XCTAssertEqual(thumbnailRenderer.receivedImageData, [])
        XCTAssertEqual(assetWriter.reservedIDCallCount, 0)
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.count, 0)
        XCTAssertEqual(repository.savedFilmRolls, [])
    }

    func testCreatePropagatesThumbnailFailureAndDoesNotReserveWriteOrSave() async {
        let repository = SpyFilmRollRepository()
        let generator = SpyLUTGenerator(lut: LUT3D.identity())
        let thumbnailRenderer = SpyThumbnailRenderer(error: LumoError.renderFailed)
        let assetWriter = SpyFilmRollAssetWriter(
            reservedID: "roll-id",
            referenceAsset: FilmRollReferenceAsset(originalPath: "original.jpg", thumbnailPath: "thumb.jpg")
        )
        let useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: generator,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter
        )

        await XCTAssertThrowsAsyncError(
            try await useCase.createFilmRoll(
                input: CreateFilmRollInput(name: "No Thumb", referenceImageData: Data([1]), preferredFileExtension: "jpg")
            )
        ) { error in
            XCTAssertEqual(error as? LumoError, .renderFailed)
        }

        XCTAssertEqual(thumbnailRenderer.receivedImageData, [Data([1])])
        XCTAssertEqual(assetWriter.reservedIDCallCount, 0)
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.count, 0)
        XCTAssertEqual(assetWriter.discardedFilmRollIDs, [])
        XCTAssertEqual(repository.savedFilmRolls, [])
    }

    func testCreateReferenceWriteFailureCleansReservedRollAssetsAndDoesNotSave() async {
        let repository = SpyFilmRollRepository()
        let generator = SpyLUTGenerator(lut: LUT3D.identity())
        let thumbnailRenderer = SpyThumbnailRenderer(thumbnailData: Data([1]))
        let assetWriter = SpyFilmRollAssetWriter(
            reservedID: "roll-id",
            referenceAsset: FilmRollReferenceAsset(originalPath: "original.jpg", thumbnailPath: "thumb.jpg"),
            storeReferenceImageError: LumoError.storageFailed(message: "reference write failed")
        )
        let useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: generator,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter
        )

        await XCTAssertThrowsAsyncError(
            try await useCase.createFilmRoll(
                input: CreateFilmRollInput(name: "Write Fails", referenceImageData: Data([2]), preferredFileExtension: "jpg")
            )
        ) { error in
            XCTAssertEqual(error as? LumoError, .storageFailed(message: "reference write failed"))
        }

        XCTAssertEqual(assetWriter.reservedIDCallCount, 1)
        XCTAssertEqual(assetWriter.storeReferenceImageCalls.count, 1)
        XCTAssertEqual(assetWriter.discardedFilmRollIDs, ["roll-id"])
        XCTAssertEqual(repository.savedFilmRolls, [])
    }

    func testCreateRepositorySaveFailureAfterReferenceWriteCleansAssetsAndRethrowsSaveError() async {
        let saveError = LumoError.storageFailed(message: "manifest save failed")
        let repository = SpyFilmRollRepository(saveError: saveError)
        let generator = SpyLUTGenerator(lut: LUT3D.identity())
        let thumbnailRenderer = SpyThumbnailRenderer(thumbnailData: Data([1]))
        let assetWriter = SpyFilmRollAssetWriter(
            reservedID: "roll-id",
            referenceAsset: FilmRollReferenceAsset(originalPath: "original.jpg", thumbnailPath: "thumb.jpg")
        )
        let useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: generator,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter
        )

        await XCTAssertThrowsAsyncError(
            try await useCase.createFilmRoll(
                input: CreateFilmRollInput(name: "Save Fails", referenceImageData: Data([3]), preferredFileExtension: "jpg")
            )
        ) { error in
            XCTAssertEqual(error as? LumoError, saveError)
        }

        XCTAssertEqual(assetWriter.storeReferenceImageCalls.count, 1)
        XCTAssertEqual(assetWriter.discardedFilmRollIDs, ["roll-id"])
        XCTAssertEqual(repository.savedFilmRolls, [])
    }
}

private final class SpyLUTGenerator: LUTGenerating, @unchecked Sendable {
    let lut: LUT3D
    let sampleAnalysisPackage: SampleAnalysisPackage?
    let error: Error?
    private(set) var requests: [LUTGenerationRequest] = []

    init(lut: LUT3D = LUT3D.identity(), sampleAnalysisPackage: SampleAnalysisPackage? = nil, error: Error? = nil) {
        self.lut = lut
        self.sampleAnalysisPackage = sampleAnalysisPackage
        self.error = error
    }

    func generateLUT(for request: LUTGenerationRequest) async throws -> LUT3D {
        requests.append(request)
        if let error {
            throw error
        }
        return lut
    }

    func generateFilmRollPackage(for request: LUTGenerationRequest) async throws -> LUTGenerationResult {
        requests.append(request)
        if let error {
            throw error
        }
        return LUTGenerationResult(lut: lut, sampleAnalysisPackage: sampleAnalysisPackage)
    }
}

private final class SpyLUTImporter: LUTImporting, @unchecked Sendable {
    let lut: LUT3D
    private(set) var receivedCubeTextData: [Data] = []

    init(lut: LUT3D) {
        self.lut = lut
    }

    func importLUT(fromCubeTextData data: Data) throws -> LUT3D {
        receivedCubeTextData.append(data)
        return lut
    }
}

private final class SpyLUTPreviewRenderer: LUTPreviewRendering, @unchecked Sendable {
    let previewData: Data
    private(set) var receivedLUTs: [LUT3D] = []

    init(previewData: Data) {
        self.previewData = previewData
    }

    func renderPreviewImage(for lut: LUT3D) throws -> Data {
        receivedLUTs.append(lut)
        return previewData
    }
}

private final class SpyThumbnailRenderer: ThumbnailRendering, @unchecked Sendable {
    let thumbnailData: Data
    let error: Error?
    private(set) var receivedImageData: [Data] = []

    init(thumbnailData: Data = Data(), error: Error? = nil) {
        self.thumbnailData = thumbnailData
        self.error = error
    }

    func renderThumbnail(from imageData: Data) async throws -> Data {
        receivedImageData.append(imageData)
        if let error {
            throw error
        }
        return thumbnailData
    }
}

private final class SpyFilmRollAssetWriter: FilmRollAssetWriting, @unchecked Sendable {
    struct StoreReferenceImageCall: Equatable {
        let filmRollID: String
        let imageData: Data
        let thumbnailData: Data
        let preferredFileExtension: String?
    }

    let reservedID: String
    let referenceAsset: FilmRollReferenceAsset
    let storeReferenceImageError: Error?
    private(set) var reservedIDCallCount = 0
    private(set) var storeReferenceImageCalls: [StoreReferenceImageCall] = []
    private(set) var writeCubeExportCalls: [(filmRollID: String, cubeText: String, suggestedFilename: String)] = []
    private(set) var discardedFilmRollIDs: [String] = []

    init(reservedID: String, referenceAsset: FilmRollReferenceAsset, storeReferenceImageError: Error? = nil) {
        self.reservedID = reservedID
        self.referenceAsset = referenceAsset
        self.storeReferenceImageError = storeReferenceImageError
    }

    func reserveFilmRollID() async throws -> String {
        reservedIDCallCount += 1
        return reservedID
    }

    func storeReferenceImage(
        filmRollID: String,
        imageData: Data,
        thumbnailData: Data,
        preferredFileExtension: String?
    ) async throws -> FilmRollReferenceAsset {
        storeReferenceImageCalls.append(
            StoreReferenceImageCall(
                filmRollID: filmRollID,
                imageData: imageData,
                thumbnailData: thumbnailData,
                preferredFileExtension: preferredFileExtension
            )
        )
        if let storeReferenceImageError {
            throw storeReferenceImageError
        }
        return referenceAsset
    }

    func discardFilmRollAssets(filmRollID: String) async {
        discardedFilmRollIDs.append(filmRollID)
    }

    func writeCubeExport(filmRollID: String, cubeText: String, suggestedFilename: String) async throws -> URL {
        writeCubeExportCalls.append((filmRollID: filmRollID, cubeText: cubeText, suggestedFilename: suggestedFilename))
        return URL(fileURLWithPath: "/tmp/\(suggestedFilename)")
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

private func testLUT(size: Int = 2, redOffset: Float = 0, algorithmVersion: String = "test") throws -> LUT3D {
    let identity = LUT3D.identity(size: size)
    let values = identity.values.enumerated().map { index, value in
        index.isMultiple(of: 3) ? min(1, value + redOffset) : value
    }
    return try LUT3D(size: size, values: values, algorithmVersion: algorithmVersion)
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
