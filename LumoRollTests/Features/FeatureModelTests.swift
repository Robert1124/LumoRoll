import XCTest
@testable import LumoRoll

@MainActor
final class FeatureModelTests: XCTestCase {
    func testLibraryLoadSuccessTreatsEmptyArrayAsLoadedState() async {
        let repository = FeatureSpyFilmRollRepository(filmRolls: [])
        let model = LibraryFeatureModel(repository: repository)

        await model.load()

        XCTAssertEqual(model.state, .loaded([]))
        XCTAssertEqual(repository.loadFilmRollsCallCount, 1)
    }

    func testLibraryLoadFailurePublishesFailedState() async {
        let repository = FeatureSpyFilmRollRepository(loadFilmRollsError: LumoError.storageFailed(message: "manifest missing"))
        let model = LibraryFeatureModel(repository: repository)

        await model.load()

        XCTAssertEqual(model.state, .failed("Storage failed: manifest missing"))
    }

    func testLibraryCreateAndOpenIntentsCarryNoImageData() {
        let model = LibraryFeatureModel(repository: FeatureSpyFilmRollRepository())

        model.requestCreate()
        XCTAssertEqual(model.pendingIntent, .createFilmRoll)

        model.requestOpenFilmRoll(id: "roll-1")
        XCTAssertEqual(model.pendingIntent, .openFilmRoll(id: "roll-1"))
    }

    func testLibraryDuplicateLoadWhileLoadingDoesNotLaunchSecondRepositoryCall() async throws {
        let roll = try featureRoll(id: "roll-slow", name: "Slow Roll")
        let repository = FeatureSuspendingFilmRollRepository(filmRolls: [roll])
        let model = LibraryFeatureModel(repository: repository)

        async let firstLoad: Void = model.load()
        await repository.waitForLoadFilmRollsCallCount(1)
        await model.load()
        await repository.resumeLoadFilmRolls()
        await firstLoad

        let loadFilmRollsCallCount = await repository.loadFilmRollsCallCount
        XCTAssertEqual(loadFilmRollsCallCount, 1)
        XCTAssertEqual(model.state, .loaded([roll]))
    }

    func testLibraryReloadFailureAfterLoadedContentPreservesLoadedStateAndPublishesLastError() async throws {
        let roll = try featureRoll(id: "roll-loaded", name: "Loaded Roll")
        let repository = FeatureQueuedFilmRollRepository(
            loadFilmRollsResults: [
                .success([roll]),
                .failure(LumoError.storageFailed(message: "refresh failed"))
            ]
        )
        let model = LibraryFeatureModel(repository: repository)

        await model.load()
        await model.reload()

        XCTAssertEqual(model.state, .loaded([roll]))
        XCTAssertEqual(model.lastErrorMessage, "Storage failed: refresh failed")
        let loadFilmRollsCallCount = await repository.loadFilmRollsCallCount
        XCTAssertEqual(loadFilmRollsCallCount, 2)
    }

    func testCreateBlocksBlankNameWithoutCallingUseCase() async {
        let dependencies = FeatureCreateDependencies()
        let model = CreateFilmRollFeatureModel(createFilmRollUseCase: dependencies.useCase)
        model.selectReferenceImage(data: Data([1, 2, 3]), preferredFileExtension: "jpg")
        model.draftName = " \n\t "

        await model.save()

        XCTAssertEqual(model.phase, .failed("Film Roll name cannot be empty."))
        XCTAssertEqual(dependencies.lutGenerator.requests, [])
        XCTAssertEqual(dependencies.repository.savedFilmRolls, [])
        XCTAssertEqual(model.selectedReferenceImageData, Data([1, 2, 3]))
    }

    func testCreateSuccessReachesCompleteWithSavedRoll() async throws {
        let dependencies = FeatureCreateDependencies()
        let model = CreateFilmRollFeatureModel(createFilmRollUseCase: dependencies.useCase)
        model.selectReferenceImage(data: Data([4, 5, 6]), preferredFileExtension: "png")
        model.draftName = "  Warm Walk  "

        await model.save()

        let savedRoll = try XCTUnwrap(dependencies.repository.savedFilmRolls.first)
        XCTAssertEqual(savedRoll.name, "Warm Walk")
        XCTAssertEqual(model.phase, .complete(savedRoll))
        XCTAssertEqual(model.savedFilmRoll, savedRoll)
        XCTAssertEqual(dependencies.lutGenerator.requests.map(\.referenceImageData), [Data([4, 5, 6])])
    }

    func testCreateCubeSelectionEnablesSaveAndSkipsReferenceLUTGeneration() async throws {
        let dependencies = FeatureCreateDependencies()
        let model = CreateFilmRollFeatureModel(createFilmRollUseCase: dependencies.useCase)
        let cubeData = Data("LUT_3D_SIZE 2".utf8)

        model.selectCubeLUT(data: cubeData, originalFilename: "Warm Roll.cube")
        model.draftName = " Imported Warm "

        XCTAssertTrue(model.canSave)
        XCTAssertNil(model.selectedReferenceImageData)
        XCTAssertEqual(model.selectedCubeLUTData, cubeData)
        XCTAssertEqual(model.selectedCubeOriginalFilename, "Warm Roll.cube")

        await model.save()

        let savedRoll = try XCTUnwrap(dependencies.repository.savedFilmRolls.first)
        XCTAssertEqual(savedRoll.name, "Imported Warm")
        XCTAssertEqual(dependencies.lutGenerator.requests, [])
        XCTAssertEqual(dependencies.lutImporter.receivedCubeTextData, [cubeData])
        XCTAssertEqual(dependencies.lutPreviewRenderer.receivedLUTs, [dependencies.lutImporter.lut])
        XCTAssertEqual(model.phase, .complete(savedRoll))
    }

    func testCreateFailureKeepsDraftAndReferenceDataForRetry() async {
        let dependencies = FeatureCreateDependencies(saveError: LumoError.storageFailed(message: "disk full"))
        let model = CreateFilmRollFeatureModel(createFilmRollUseCase: dependencies.useCase)
        model.selectReferenceImage(data: Data([7, 8, 9]), preferredFileExtension: "heic")
        model.draftName = "Retry Roll"

        await model.save()

        XCTAssertEqual(model.phase, .failed("Storage failed: disk full"))
        XCTAssertEqual(model.draftName, "Retry Roll")
        XCTAssertEqual(model.selectedReferenceImageData, Data([7, 8, 9]))
        XCTAssertEqual(model.preferredFileExtension, "heic")
    }

    func testCreateDuplicateSaveWhileProcessingDoesNotLaunchSecondCreateCall() async {
        let repository = FeatureActorFilmRollRepository()
        let lutGenerator = FeatureSuspendingLUTGenerator(lut: LUT3D.identity())
        let thumbnailRenderer = FeatureSpyThumbnailRenderer(thumbnailData: Data([10]))
        let assetWriter = FeatureSpyFilmRollAssetWriter(
            reservedID: "slow-created-roll",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg")
        )
        let useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: lutGenerator,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter
        )
        let model = CreateFilmRollFeatureModel(createFilmRollUseCase: useCase)
        model.selectReferenceImage(data: Data([1, 2, 3]), preferredFileExtension: "jpg")
        model.draftName = "Slow Create"

        async let firstSave: Void = model.save()
        await lutGenerator.waitForRequestCount(1)
        async let secondSave: Void = model.save()
        try? await Task.sleep(nanoseconds: 50_000_000)
        await lutGenerator.resumeGeneration()
        await firstSave
        await secondSave

        let requestCount = await lutGenerator.requestCount
        XCTAssertEqual(requestCount, 1)
        let savedFilmRolls = await repository.savedFilmRolls
        XCTAssertEqual(savedFilmRolls.count, 1)
        XCTAssertEqual(model.savedFilmRoll?.id, "slow-created-roll")
    }

    func testCreateStartingNewImportOrSelectingNewReferenceClearsCompletedRollState() async {
        let dependencies = FeatureCreateDependencies()
        let model = CreateFilmRollFeatureModel(createFilmRollUseCase: dependencies.useCase)
        model.selectReferenceImage(data: Data([4, 5, 6]), preferredFileExtension: "png")
        model.draftName = "Old Roll"
        await model.save()
        XCTAssertNotNil(model.savedFilmRoll)

        model.beginImport()

        XCTAssertNil(model.savedFilmRoll)
        XCTAssertEqual(model.phase, .importing)

        model.selectReferenceImage(data: Data([9, 8, 7]), preferredFileExtension: "heic")

        XCTAssertNil(model.savedFilmRoll)
        XCTAssertEqual(model.phase, .naming)
        XCTAssertEqual(model.selectedReferenceImageData, Data([9, 8, 7]))
        XCTAssertEqual(model.preferredFileExtension, "heic")
    }

    func testCreateStaleSaveResultAfterNewReferenceDoesNotOverwriteCurrentDraft() async {
        let repository = FeatureActorFilmRollRepository()
        let lutGenerator = FeatureSuspendingLUTGenerator(lut: LUT3D.identity())
        let thumbnailRenderer = FeatureSpyThumbnailRenderer(thumbnailData: Data([10]))
        let assetWriter = FeatureSpyFilmRollAssetWriter(
            reservedID: "old-created-roll",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/old.jpg", thumbnailPath: "reference/old-thumb.jpg")
        )
        let useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: lutGenerator,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter
        )
        let model = CreateFilmRollFeatureModel(createFilmRollUseCase: useCase)
        model.selectReferenceImage(data: Data([1, 2, 3]), preferredFileExtension: "jpg")
        model.draftName = "Old Create"

        async let save: Void = model.save()
        await lutGenerator.waitForRequestCount(1)
        model.selectReferenceImage(data: Data([9, 8, 7]), preferredFileExtension: "heic")
        await lutGenerator.resumeGeneration()
        await save

        XCTAssertEqual(model.phase, .naming)
        XCTAssertNil(model.savedFilmRoll)
        XCTAssertEqual(model.selectedReferenceImageData, Data([9, 8, 7]))
        XCTAssertEqual(model.preferredFileExtension, "heic")
    }

    func testCreateStaleSaveResultAfterBeginImportDoesNotOverwriteImportingState() async {
        let repository = FeatureActorFilmRollRepository()
        let lutGenerator = FeatureSuspendingLUTGenerator(lut: LUT3D.identity())
        let thumbnailRenderer = FeatureSpyThumbnailRenderer(thumbnailData: Data([10]))
        let assetWriter = FeatureSpyFilmRollAssetWriter(
            reservedID: "old-import-roll",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/old.jpg", thumbnailPath: "reference/old-thumb.jpg")
        )
        let useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: lutGenerator,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter
        )
        let model = CreateFilmRollFeatureModel(createFilmRollUseCase: useCase)
        model.selectReferenceImage(data: Data([3, 2, 1]), preferredFileExtension: "png")
        model.draftName = "Old Import"

        async let save: Void = model.save()
        await lutGenerator.waitForRequestCount(1)
        model.beginImport()
        await lutGenerator.resumeGeneration()
        await save

        XCTAssertEqual(model.phase, .importing)
        XCTAssertNil(model.savedFilmRoll)
        XCTAssertNil(model.selectedReferenceImageData)
        XCTAssertNil(model.preferredFileExtension)
    }

    func testDetailLoadSuccessAndFailure() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Detail Roll")
        let successRepository = FeatureSpyFilmRollRepository(filmRolls: [roll])
        let successModel = FilmRollDetailFeatureModel(
            filmRollID: "roll-1",
            repository: successRepository,
            exportLUTUseCase: FeatureExportDependencies(repository: successRepository).useCase
        )

        await successModel.load()

        XCTAssertEqual(successModel.state, .loaded(roll))

        let failureModel = FilmRollDetailFeatureModel(
            filmRollID: "missing",
            repository: FeatureSpyFilmRollRepository(),
            exportLUTUseCase: FeatureExportDependencies(repository: FeatureSpyFilmRollRepository()).useCase
        )

        await failureModel.load()

        XCTAssertEqual(failureModel.state, .failed("Film Roll not found: missing."))
    }

    func testDetailExportSuccessAndFailure() async throws {
        let roll = try featureRoll(id: "roll-export", name: "Export Roll")
        let successRepository = FeatureSpyFilmRollRepository(filmRolls: [roll])
        let successDependencies = FeatureExportDependencies(repository: successRepository)
        let successModel = FilmRollDetailFeatureModel(
            filmRollID: "roll-export",
            repository: successRepository,
            exportLUTUseCase: successDependencies.useCase
        )

        await successModel.exportLUT()

        let expectedResult = ExportLUTResult(
            suggestedFilename: "Export-Roll.cube",
            cubeText: "cube text",
            fileURL: URL(fileURLWithPath: "/tmp/Export-Roll.cube")
        )
        XCTAssertEqual(successModel.exportState, .ready(expectedResult))
        XCTAssertEqual(successDependencies.exporter.requests.map(\.filmRollID), ["roll-export"])

        let failureRepository = FeatureSpyFilmRollRepository(filmRolls: [roll])
        let failureDependencies = FeatureExportDependencies(
            repository: failureRepository,
            exportError: LumoError.exportFailed
        )
        let failureModel = FilmRollDetailFeatureModel(
            filmRollID: "roll-export",
            repository: failureRepository,
            exportLUTUseCase: failureDependencies.useCase
        )

        await failureModel.exportLUT()

        XCTAssertEqual(failureModel.exportState, .failed("Export failed."))
    }

    func testDetailApplyIntentCarriesRollIDOnly() {
        let model = FilmRollDetailFeatureModel(
            filmRollID: "roll-apply",
            repository: FeatureSpyFilmRollRepository(),
            exportLUTUseCase: FeatureExportDependencies(repository: FeatureSpyFilmRollRepository()).useCase
        )

        model.requestApplyPhoto()

        XCTAssertEqual(model.pendingIntent, .applyPhoto(filmRollID: "roll-apply"))
    }

    func testDetailImportIntentCarriesRollIDAndSource() {
        let model = FilmRollDetailFeatureModel(
            filmRollID: "roll-import",
            repository: FeatureSpyFilmRollRepository(),
            exportLUTUseCase: FeatureExportDependencies(repository: FeatureSpyFilmRollRepository()).useCase
        )

        model.requestImportPhoto(source: .photoLibrary)

        XCTAssertEqual(model.pendingIntent, .importPhoto(filmRollID: "roll-import", source: .photoLibrary))
    }

    func testDetailDuplicateExportWhileExportingDoesNotLaunchSecondUseCaseCall() async throws {
        let roll = try featureRoll(id: "roll-export-slow", name: "Export Slow")
        let repository = FeatureSpyFilmRollRepository(filmRolls: [roll])
        let exporter = FeatureSuspendingLUTExporter(cubeText: "slow cube")
        let assetWriter = FeatureSpyFilmRollAssetWriter()
        let useCase = ExportLUTUseCase(repository: repository, lutExporter: exporter, assetWriter: assetWriter)
        let model = FilmRollDetailFeatureModel(
            filmRollID: "roll-export-slow",
            repository: repository,
            exportLUTUseCase: useCase
        )

        async let firstExport: Void = model.exportLUT()
        await exporter.waitForRequestCount(1)
        await model.exportLUT()
        await exporter.resumeExport()
        await firstExport

        let requestCount = await exporter.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(assetWriter.writeCubeExportCalls.count, 1)
    }

    func testDetailReloadFailureAfterLoadedContentPreservesLoadedStateAndPublishesLastError() async throws {
        let roll = try featureRoll(id: "roll-detail", name: "Detail Roll")
        let repository = FeatureQueuedFilmRollRepository(
            loadFilmRollResults: [
                .success(roll),
                .failure(LumoError.storageFailed(message: "detail refresh failed"))
            ]
        )
        let model = FilmRollDetailFeatureModel(
            filmRollID: "roll-detail",
            repository: repository,
            exportLUTUseCase: FeatureExportDependencies(repository: repository).useCase
        )

        await model.load()
        await model.reload()

        XCTAssertEqual(model.state, .loaded(roll))
        XCTAssertEqual(model.lastErrorMessage, "Storage failed: detail refresh failed")
        let loadedIDs = await repository.loadedIDs
        XCTAssertEqual(loadedIDs, ["roll-detail", "roll-detail"])
    }

    func testDetailRenameTrimsNameSavesRollAndUpdatesLoadedState() async throws {
        let roll = try featureRoll(id: "roll-rename", name: "Old Name")
        let repository = FeatureSpyFilmRollRepository(filmRolls: [roll])
        let model = FilmRollDetailFeatureModel(
            filmRollID: "roll-rename",
            repository: repository,
            exportLUTUseCase: FeatureExportDependencies(repository: repository).useCase,
            now: { Date(timeIntervalSince1970: 500) }
        )
        await model.load()

        await model.renameFilmRoll(to: "  New Name  ")

        let savedRoll = try XCTUnwrap(repository.savedFilmRolls.first)
        XCTAssertEqual(savedRoll.name, "New Name")
        XCTAssertEqual(savedRoll.updatedAt, Date(timeIntervalSince1970: 500))
        XCTAssertEqual(model.state, .loaded(savedRoll))
        XCTAssertEqual(model.managementState, .idle)
    }

    func testDetailRemoveRollDeletesAndPublishesRemovedIntent() async throws {
        let roll = try featureRoll(id: "roll-remove", name: "Remove Me")
        let repository = FeatureSpyFilmRollRepository(filmRolls: [roll])
        let model = FilmRollDetailFeatureModel(
            filmRollID: "roll-remove",
            repository: repository,
            exportLUTUseCase: FeatureExportDependencies(repository: repository).useCase
        )

        await model.removeFilmRoll()

        XCTAssertEqual(repository.deletedIDs, ["roll-remove"])
        XCTAssertEqual(model.pendingIntent, .removedFilmRoll(filmRollID: "roll-remove"))
        XCTAssertEqual(model.managementState, .idle)
    }

    func testApplyClampsIntensity() {
        let dependencies = FeatureApplyDependencies()
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: dependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: dependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: dependencies.previewUseCase
        )

        model.intensity = -10
        XCTAssertEqual(model.intensity, 0)

        model.intensity = 150
        XCTAssertEqual(model.intensity, 100)
    }

    func testApplyPreviewModeCanChangeBetweenBeforeSplitAndAfter() {
        let dependencies = FeatureApplyDependencies()
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: dependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: dependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: dependencies.previewUseCase
        )

        model.previewMode = .before
        XCTAssertEqual(model.previewMode, .before)

        model.previewMode = .after
        XCTAssertEqual(model.previewMode, .after)

        model.previewMode = .split
        XCTAssertEqual(model.previewMode, .split)
    }

    func testApplyEditContextPreselectsOriginalPhotoAndReusesProcessedPhotoIDOnSave() async throws {
        let existingPhoto = ProcessedPhoto(
            id: "processed-existing",
            originalPath: "film-rolls/roll-1/processed/processed-existing/original.jpg",
            processedPath: "film-rolls/roll-1/processed/processed-existing/rendered.jpg",
            thumbnailPath: "film-rolls/roll-1/processed/processed-existing/thumbnail.jpg",
            createdAt: Date(timeIntervalSince1970: 300),
            intensity: 38
        )
        let roll = try FilmRoll(
            id: "roll-1",
            name: "Apply Roll",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
            lut: LUT3D.identity(),
            processedPhotos: [existingPhoto]
        )
        let dependencies = FeatureApplyDependencies(initialRoll: roll)
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            editContext: ApplyPhotoEditContext(
                processedPhotoID: "processed-existing",
                originalPhotoPath: "film-rolls/roll-1/processed/processed-existing/original.jpg",
                intensity: 38
            ),
            applyFilmRollUseCase: dependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: dependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: dependencies.previewUseCase
        )

        XCTAssertEqual(model.selectedTargetPhotoPath, "film-rolls/roll-1/processed/processed-existing/original.jpg")
        XCTAssertEqual(model.intensity, 38)
        XCTAssertTrue(model.isEditingExistingProcessedPhoto)

        await model.saveToFilmRoll()

        XCTAssertEqual(dependencies.renderer.requests.map(\.originalPath), ["film-rolls/roll-1/processed/processed-existing/original.jpg"])
        XCTAssertEqual(dependencies.renderer.requests.map(\.intensity), [38])
        XCTAssertEqual(dependencies.repository.savedFilmRolls.first?.processedPhotos.first?.id, "processed-existing")
    }

    func testApplySaveToRollSuccessAndFailureRetainsInputsForRetry() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let successDependencies = FeatureApplyDependencies(initialRoll: roll)
        let successModel = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: successDependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: successDependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: successDependencies.previewUseCase
        )
        successModel.selectTargetPhoto(path: "imports/photo.jpg")
        successModel.intensity = 48

        await successModel.saveToFilmRoll()

        let savedRoll = try XCTUnwrap(successDependencies.repository.savedFilmRolls.first)
        XCTAssertEqual(successModel.saveState, .saved(savedRoll))
        XCTAssertEqual(successDependencies.renderer.requests.map(\.originalPath), ["imports/photo.jpg"])
        XCTAssertEqual(successDependencies.renderer.requests.map(\.intensity), [48])

        let failureDependencies = FeatureApplyDependencies(initialRoll: roll, saveError: LumoError.saveFailed)
        let failureModel = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: failureDependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: failureDependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: failureDependencies.previewUseCase
        )
        failureModel.selectTargetPhoto(path: "imports/retry.jpg")
        failureModel.intensity = 72

        await failureModel.saveToFilmRoll()

        XCTAssertEqual(failureModel.saveState, .failed("Save failed."))
        XCTAssertEqual(failureModel.selectedTargetPhotoPath, "imports/retry.jpg")
        XCTAssertEqual(failureModel.intensity, 72)
    }

    func testApplySelectingNewTargetResetsStaleSaveStates() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let dependencies = FeatureApplyDependencies(initialRoll: roll)
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: dependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: dependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: dependencies.previewUseCase
        )
        model.selectTargetPhoto(path: "imports/old.jpg")
        await model.saveToFilmRoll()
        await model.saveToPhotos()

        model.selectTargetPhoto(path: "imports/new.jpg")

        XCTAssertEqual(model.selectedTargetPhotoPath, "imports/new.jpg")
        XCTAssertEqual(model.saveState, .idle)
        XCTAssertEqual(model.saveToPhotosState, .idle)
    }

    func testApplyPreviewRenderPublishesReadyPreviewWithoutUsingFinalSavePath() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let dependencies = FeatureApplyDependencies(initialRoll: roll)
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: dependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: dependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: dependencies.previewUseCase
        )
        model.selectTargetPhoto(path: "imports/photo.jpg")
        model.intensity = 43

        await model.renderPreview()

        XCTAssertEqual(model.previewState, .ready(path: "tmp/apply-previews/feature-preview-id/preview.jpg"))
        XCTAssertEqual(dependencies.previewRenderer.requests.map(\.originalPath), ["imports/photo.jpg"])
        XCTAssertEqual(dependencies.previewRenderer.requests.map(\.intensity), [43])
        XCTAssertEqual(dependencies.repository.savedFilmRolls, [])
        XCTAssertEqual(dependencies.renderer.requests, [])
    }

    func testApplyDiagnosticAdaptiveToggleControlsPreviewAndFinalRenderRequests() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let dependencies = FeatureApplyDependencies(initialRoll: roll)
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: dependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: dependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: dependencies.previewUseCase
        )
        XCTAssertTrue(model.isAdaptivePostProcessEnabled)
        model.selectTargetPhoto(path: "imports/photo.jpg")
        model.intensity = 43
        model.isAdaptivePostProcessEnabled = false

        await model.renderPreview()
        await model.saveToFilmRoll()
        await model.saveToPhotos()

        XCTAssertEqual(dependencies.previewRenderer.requests.first?.isAdaptivePostProcessEnabled, false)
        XCTAssertEqual(dependencies.renderer.requests.map(\.isAdaptivePostProcessEnabled), [false, false])
    }

    func testApplyDiagnosticV2ToggleControlsPreviewAndFinalRenderLUTSource() async throws {
        let savedLUT = LUT3D.identity(size: 2, algorithmVersion: "private.model.v1")
        let transientV2LUT = LUT3D.identity(size: 2, algorithmVersion: LUT3D.defaultAlgorithmVersion)
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll", lut: savedLUT)
        let dependencies = FeatureApplyDependencies(initialRoll: roll, diagnosticLUT: transientV2LUT)
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: dependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: dependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: dependencies.previewUseCase
        )
        XCTAssertFalse(model.isUsingAlgorithmV2DiagnosticLUT)
        model.selectTargetPhoto(path: "imports/photo.jpg")
        model.intensity = 43
        model.isUsingAlgorithmV2DiagnosticLUT = true

        await model.renderPreview()
        await model.saveToFilmRoll()
        await model.saveToPhotos()

        XCTAssertEqual(dependencies.previewRenderer.requests.first?.lut, transientV2LUT)
        XCTAssertEqual(dependencies.renderer.requests.map(\.lut), [transientV2LUT, transientV2LUT])
        XCTAssertEqual(dependencies.repository.savedFilmRolls.last?.lut, savedLUT)
    }

    func testApplyPreviewStaleCompletionDoesNotReplaceCurrentPreviewAndDiscardsStaleOutput() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let repository = FeatureActorFilmRollRepository(filmRolls: [roll])
        let finalRenderer = FeatureSpyPhotoRenderer(
            result: PhotoRenderResult(
                originalPath: "processed/original.jpg",
                processedPath: "processed/photo.jpg",
                thumbnailPath: "processed/thumb.jpg",
                intensity: 80
            )
        )
        let previewRenderer = FeatureSuspendingPhotoPreviewRenderer()
        let previewIDs = FeaturePreviewIDGenerator(ids: ["old-preview", "new-preview"])
        let useCase = ApplyFilmRollUseCase(repository: repository, photoRenderer: finalRenderer)
        let saveToPhotosUseCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: finalRenderer,
            photoLibraryWriter: FeatureSpyPhotoLibraryWriter()
        )
        let previewUseCase = RenderApplyPreviewUseCase(
            repository: repository,
            photoPreviewRenderer: previewRenderer,
            previewIDGenerator: previewIDs.next
        )
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: useCase,
            saveAppliedPhotoToPhotosUseCase: saveToPhotosUseCase,
            renderApplyPreviewUseCase: previewUseCase
        )
        model.selectTargetPhoto(path: "imports/photo.jpg")
        model.intensity = 25

        async let oldRender: Void = model.renderPreview()
        await previewRenderer.waitForRequestCount(1)
        XCTAssertEqual(model.previewState, .rendering(previousPath: nil))

        model.intensity = 80
        async let newRender: Void = model.renderPreview()
        await previewRenderer.waitForRequestCount(2)
        await previewRenderer.resumeLatest()
        await newRender

        XCTAssertEqual(model.previewState, .ready(path: "tmp/apply-previews/new-preview/preview.jpg"))

        await previewRenderer.resumeOldest()
        await oldRender

        XCTAssertEqual(model.previewState, .ready(path: "tmp/apply-previews/new-preview/preview.jpg"))
        let discardedPaths = await previewRenderer.discardedPaths
        XCTAssertEqual(discardedPaths, ["tmp/apply-previews/old-preview/preview.jpg"])
    }

    func testApplyPreviewFailureKeepsTargetAndSaveRetryAvailable() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let dependencies = FeatureApplyDependencies(initialRoll: roll, previewError: LumoError.renderFailed)
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: dependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: dependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: dependencies.previewUseCase
        )
        model.selectTargetPhoto(path: "imports/retry.jpg")

        await model.renderPreview()

        XCTAssertEqual(model.previewState, .failed(message: "Photo rendering failed.", previousPath: nil))
        XCTAssertEqual(model.selectedTargetPhotoPath, "imports/retry.jpg")
        XCTAssertTrue(model.canSaveToFilmRoll)
        XCTAssertEqual(model.saveState, .idle)
        XCTAssertEqual(model.saveToPhotosState, .idle)
    }

    func testApplyDiscardPreviewClearsReadyPreviewAndRemovesTemporaryOutput() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let dependencies = FeatureApplyDependencies(initialRoll: roll)
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: dependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: dependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: dependencies.previewUseCase
        )
        model.selectTargetPhoto(path: "imports/photo.jpg")
        await model.renderPreview()

        await model.discardPreview()

        XCTAssertEqual(model.previewState, .idle)
        XCTAssertEqual(dependencies.previewRenderer.discardedPaths, ["tmp/apply-previews/feature-preview-id/preview.jpg"])
    }

    func testApplySelectingNewTargetWhileSavingDoesNotMutateSelectionUntilSaveFinishes() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let repository = FeatureActorFilmRollRepository(filmRolls: [roll])
        let renderer = FeatureSuspendingPhotoRenderer(
            result: PhotoRenderResult(
                originalPath: "processed/old-original.jpg",
                processedPath: "processed/old.jpg",
                thumbnailPath: "processed/old-thumb.jpg",
                intensity: 64
            )
        )
        let useCase = ApplyFilmRollUseCase(repository: repository, photoRenderer: renderer)
        let saveToPhotosUseCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: renderer,
            photoLibraryWriter: FeatureSpyPhotoLibraryWriter()
        )
        let previewUseCase = RenderApplyPreviewUseCase(
            repository: repository,
            photoPreviewRenderer: FeatureSpyPhotoPreviewRenderer()
        )
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: useCase,
            saveAppliedPhotoToPhotosUseCase: saveToPhotosUseCase,
            renderApplyPreviewUseCase: previewUseCase
        )
        model.selectTargetPhoto(path: "imports/old.jpg")
        model.intensity = 64

        async let save: Void = model.saveToFilmRoll()
        await renderer.waitForRequestCount(1)
        model.selectTargetPhoto(path: "imports/new.jpg")

        XCTAssertEqual(model.selectedTargetPhotoPath, "imports/old.jpg")
        XCTAssertEqual(model.saveState, .saving)

        await renderer.resumeRender()
        await save

        XCTAssertEqual(model.selectedTargetPhotoPath, "imports/old.jpg")
        guard case .saved(let savedRoll) = model.saveState else {
            XCTFail("Expected save to finish for the original selected target.")
            return
        }
        XCTAssertEqual(savedRoll.processedPhotos.count, 1)
        XCTAssertEqual(model.intensity, 64)
    }

    func testApplyTargetImportCleanupNeverDiscardsModelSelectedPath() {
        XCTAssertEqual(
            ApplyTargetImportCleanupDecision.pathToDiscardAfterSelection(
                previousPath: "tmp/imports/old/original.jpg",
                stagedPath: "tmp/imports/new/original.jpg",
                selectedPathAfterSelection: "tmp/imports/old/original.jpg"
            ),
            "tmp/imports/new/original.jpg"
        )

        XCTAssertEqual(
            ApplyTargetImportCleanupDecision.pathToDiscardAfterSelection(
                previousPath: "tmp/imports/old/original.jpg",
                stagedPath: "tmp/imports/new/original.jpg",
                selectedPathAfterSelection: "tmp/imports/new/original.jpg"
            ),
            "tmp/imports/old/original.jpg"
        )

        XCTAssertNil(
            ApplyTargetImportCleanupDecision.pathToDiscardAfterSelection(
                previousPath: "tmp/imports/new/original.jpg",
                stagedPath: "tmp/imports/new/original.jpg",
                selectedPathAfterSelection: "tmp/imports/new/original.jpg"
            )
        )
    }

    func testApplyCloseDecisionKeepsStagedTargetWhileSaving() {
        XCTAssertFalse(ApplyCloseDecision.shouldCloseAndDiscard(isSaving: true))
        XCTAssertTrue(ApplyCloseDecision.shouldCloseAndDiscard(isSaving: false))
    }

    func testStagedImportGenerationRejectsStaleCompletions() {
        XCTAssertTrue(StagedImportGenerationDecision.shouldAccept(completedGeneration: 3, activeGeneration: 3))
        XCTAssertFalse(StagedImportGenerationDecision.shouldAccept(completedGeneration: 2, activeGeneration: 3))
        XCTAssertEqual(
            StagedImportGenerationDecision.stalePathToDiscard(
                stagedPath: "tmp/imports/stale/original.jpg",
                completedGeneration: 2,
                activeGeneration: 3
            ),
            "tmp/imports/stale/original.jpg"
        )
        XCTAssertNil(
            StagedImportGenerationDecision.stalePathToDiscard(
                stagedPath: "tmp/imports/current/original.jpg",
                completedGeneration: 3,
                activeGeneration: 3
            )
        )
    }

    func testApplyDuplicateSaveWhileSavingDoesNotLaunchSecondUseCaseCall() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let repository = FeatureSpyFilmRollRepository(filmRolls: [roll])
        let renderer = FeatureSuspendingPhotoRenderer(
            result: PhotoRenderResult(
                originalPath: "processed/original.jpg",
                processedPath: "processed/photo.jpg",
                thumbnailPath: "processed/thumb.jpg",
                intensity: 64
            )
        )
        let useCase = ApplyFilmRollUseCase(repository: repository, photoRenderer: renderer)
        let saveToPhotosUseCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: renderer,
            photoLibraryWriter: FeatureSpyPhotoLibraryWriter()
        )
        let previewUseCase = RenderApplyPreviewUseCase(
            repository: repository,
            photoPreviewRenderer: FeatureSpyPhotoPreviewRenderer()
        )
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: useCase,
            saveAppliedPhotoToPhotosUseCase: saveToPhotosUseCase,
            renderApplyPreviewUseCase: previewUseCase
        )
        model.selectTargetPhoto(path: "imports/slow.jpg")
        model.intensity = 64

        async let firstSave: Void = model.saveToFilmRoll()
        await renderer.waitForRequestCount(1)
        await model.saveToFilmRoll()
        await renderer.resumeRender()
        await firstSave

        let requestCount = await renderer.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(repository.savedFilmRolls.count, 1)
    }

    func testApplySaveToPhotosSuccessAndFailureRetainsInputsForRetry() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let successDependencies = FeatureApplyDependencies(initialRoll: roll)
        let successModel = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: successDependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: successDependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: successDependencies.previewUseCase
        )
        successModel.selectTargetPhoto(path: "imports/photo.jpg")
        successModel.intensity = 48

        await successModel.saveToPhotos()

        XCTAssertEqual(successModel.saveToPhotosState, .saved("photos-id"))
        XCTAssertEqual(successDependencies.photosWriter.processedPaths, ["processed/photo.jpg"])
        XCTAssertEqual(successDependencies.repository.savedFilmRolls, [])

        let failureDependencies = FeatureApplyDependencies(initialRoll: roll, photoLibraryError: LumoError.photosPermissionDenied)
        let failureModel = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: failureDependencies.useCase,
            saveAppliedPhotoToPhotosUseCase: failureDependencies.saveToPhotosUseCase,
            renderApplyPreviewUseCase: failureDependencies.previewUseCase
        )
        failureModel.selectTargetPhoto(path: "imports/retry.jpg")
        failureModel.intensity = 72

        await failureModel.saveToPhotos()

        XCTAssertEqual(failureModel.saveToPhotosState, .failed("Photos access is needed to save images to your library."))
        XCTAssertEqual(failureModel.selectedTargetPhotoPath, "imports/retry.jpg")
        XCTAssertEqual(failureModel.intensity, 72)
    }

    func testApplyDuplicateSaveToPhotosWhileSavingDoesNotLaunchSecondUseCaseCall() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let repository = FeatureSpyFilmRollRepository(filmRolls: [roll])
        let renderer = FeatureSuspendingPhotoRenderer(
            result: PhotoRenderResult(
                originalPath: "processed/original.jpg",
                processedPath: "processed/photo.jpg",
                thumbnailPath: "processed/thumb.jpg",
                intensity: 64
            )
        )
        let writer = FeatureSpyPhotoLibraryWriter()
        let useCase = ApplyFilmRollUseCase(repository: repository, photoRenderer: renderer)
        let saveToPhotosUseCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: renderer,
            photoLibraryWriter: writer
        )
        let previewUseCase = RenderApplyPreviewUseCase(
            repository: repository,
            photoPreviewRenderer: FeatureSpyPhotoPreviewRenderer()
        )
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: useCase,
            saveAppliedPhotoToPhotosUseCase: saveToPhotosUseCase,
            renderApplyPreviewUseCase: previewUseCase
        )
        model.selectTargetPhoto(path: "imports/slow.jpg")
        model.intensity = 64

        async let firstSave: Void = model.saveToPhotos()
        await renderer.waitForRequestCount(1)
        await model.saveToPhotos()
        await renderer.resumeRender()
        await firstSave

        let requestCount = await renderer.requestCount
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(writer.processedPaths, ["processed/photo.jpg"])
        XCTAssertEqual(repository.savedFilmRolls, [])
    }

    func testApplySelectingNewTargetWhileSaveToPhotosIsSavingDoesNotMutateSelectionUntilSaveFinishes() async throws {
        let roll = try featureRoll(id: "roll-1", name: "Apply Roll")
        let repository = FeatureActorFilmRollRepository(filmRolls: [roll])
        let renderer = FeatureSuspendingPhotoRenderer(
            result: PhotoRenderResult(
                originalPath: "processed/old-original.jpg",
                processedPath: "processed/old.jpg",
                thumbnailPath: "processed/old-thumb.jpg",
                intensity: 64
            )
        )
        let writer = FeatureSpyPhotoLibraryWriter()
        let useCase = ApplyFilmRollUseCase(repository: repository, photoRenderer: renderer)
        let saveToPhotosUseCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: renderer,
            photoLibraryWriter: writer
        )
        let previewUseCase = RenderApplyPreviewUseCase(
            repository: repository,
            photoPreviewRenderer: FeatureSpyPhotoPreviewRenderer()
        )
        let model = ApplyPhotoFeatureModel(
            filmRollID: "roll-1",
            applyFilmRollUseCase: useCase,
            saveAppliedPhotoToPhotosUseCase: saveToPhotosUseCase,
            renderApplyPreviewUseCase: previewUseCase
        )
        model.selectTargetPhoto(path: "imports/old.jpg")
        model.intensity = 64

        async let save: Void = model.saveToPhotos()
        await renderer.waitForRequestCount(1)
        model.selectTargetPhoto(path: "imports/new.jpg")

        XCTAssertEqual(model.selectedTargetPhotoPath, "imports/old.jpg")
        XCTAssertEqual(model.saveToPhotosState, .saving)

        await renderer.resumeRender()
        await save

        XCTAssertEqual(model.selectedTargetPhotoPath, "imports/old.jpg")
        XCTAssertEqual(model.saveToPhotosState, .saved("photos-id"))
        XCTAssertEqual(model.intensity, 64)
    }
}

private struct FeatureCreateDependencies {
    let repository: FeatureSpyFilmRollRepository
    let lutGenerator: FeatureSpyLUTGenerator
    let lutImporter: FeatureSpyLUTImporter
    let lutPreviewRenderer: FeatureSpyLUTPreviewRenderer
    let thumbnailRenderer: FeatureSpyThumbnailRenderer
    let assetWriter: FeatureSpyFilmRollAssetWriter
    let useCase: CreateFilmRollUseCase

    init(saveError: Error? = nil) {
        repository = FeatureSpyFilmRollRepository(saveError: saveError)
        lutGenerator = FeatureSpyLUTGenerator(lut: LUT3D.identity())
        lutImporter = FeatureSpyLUTImporter(lut: LUT3D.identity(size: 2))
        lutPreviewRenderer = FeatureSpyLUTPreviewRenderer(previewData: Data([12, 12]))
        thumbnailRenderer = FeatureSpyThumbnailRenderer(thumbnailData: Data([10]))
        assetWriter = FeatureSpyFilmRollAssetWriter(
            reservedID: "created-roll",
            referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg")
        )
        useCase = CreateFilmRollUseCase(
            repository: repository,
            lutGenerator: lutGenerator,
            lutImporter: lutImporter,
            lutPreviewRenderer: lutPreviewRenderer,
            thumbnailRenderer: thumbnailRenderer,
            assetWriter: assetWriter,
            now: { Date(timeIntervalSince1970: 1_000) }
        )
    }
}

private struct FeatureExportDependencies {
    let exporter: FeatureSpyLUTExporter
    let assetWriter: FeatureSpyFilmRollAssetWriter
    let useCase: ExportLUTUseCase

    init(repository: FilmRollRepository, exportError: Error? = nil) {
        exporter = FeatureSpyLUTExporter(cubeText: "cube text", error: exportError)
        assetWriter = FeatureSpyFilmRollAssetWriter()
        useCase = ExportLUTUseCase(repository: repository, lutExporter: exporter, assetWriter: assetWriter)
    }
}

private struct FeatureApplyDependencies {
    let repository: FeatureSpyFilmRollRepository
    let renderer: FeatureSpyPhotoRenderer
    let previewRenderer: FeatureSpyPhotoPreviewRenderer
    let photosWriter: FeatureSpyPhotoLibraryWriter
    let referenceLoader: FeatureStubReferenceImageDataLoader
    let diagnosticLUTGenerator: FeatureStubDiagnosticLUTGenerator
    let useCase: ApplyFilmRollUseCase
    let saveToPhotosUseCase: SaveAppliedPhotoToPhotosUseCase
    let previewUseCase: RenderApplyPreviewUseCase

    init(
        initialRoll: FilmRoll? = nil,
        saveError: Error? = nil,
        photoLibraryError: Error? = nil,
        previewError: Error? = nil,
        diagnosticLUT: LUT3D = LUT3D.identity(size: 2, algorithmVersion: LUT3D.defaultAlgorithmVersion)
    ) {
        repository = FeatureSpyFilmRollRepository(
            filmRolls: initialRoll.map { [$0] } ?? [],
            saveError: saveError
        )
        renderer = FeatureSpyPhotoRenderer(
            result: PhotoRenderResult(
                originalPath: "processed/original.jpg",
                processedPath: "processed/photo.jpg",
                thumbnailPath: "processed/thumb.jpg",
                intensity: 50
            )
        )
        previewRenderer = FeatureSpyPhotoPreviewRenderer(error: previewError)
        photosWriter = FeatureSpyPhotoLibraryWriter(error: photoLibraryError)
        referenceLoader = FeatureStubReferenceImageDataLoader(data: Data([0x42]))
        diagnosticLUTGenerator = FeatureStubDiagnosticLUTGenerator(lut: diagnosticLUT)
        useCase = ApplyFilmRollUseCase(
            repository: repository,
            photoRenderer: renderer,
            referenceImageDataLoader: referenceLoader,
            diagnosticLUTGenerator: diagnosticLUTGenerator,
            now: { Date(timeIntervalSince1970: 2_000) }
        )
        saveToPhotosUseCase = SaveAppliedPhotoToPhotosUseCase(
            repository: repository,
            photoRenderer: renderer,
            photoLibraryWriter: photosWriter,
            referenceImageDataLoader: referenceLoader,
            diagnosticLUTGenerator: diagnosticLUTGenerator,
            processedPhotoIDGenerator: { "photos-temp-id" }
        )
        previewUseCase = RenderApplyPreviewUseCase(
            repository: repository,
            photoPreviewRenderer: previewRenderer,
            referenceImageDataLoader: referenceLoader,
            diagnosticLUTGenerator: diagnosticLUTGenerator,
            previewIDGenerator: { "feature-preview-id" }
        )
    }
}

private final class FeatureSpyFilmRollRepository: FilmRollRepository, @unchecked Sendable {
    var filmRollsByID: [String: FilmRoll]
    let loadFilmRollsError: Error?
    let saveError: Error?
    private(set) var loadFilmRollsCallCount = 0
    private(set) var loadedIDs: [String] = []
    private(set) var savedFilmRolls: [FilmRoll] = []
    private(set) var deletedIDs: [String] = []

    init(filmRolls: [FilmRoll] = [], loadFilmRollsError: Error? = nil, saveError: Error? = nil) {
        filmRollsByID = Dictionary(uniqueKeysWithValues: filmRolls.map { ($0.id, $0) })
        self.loadFilmRollsError = loadFilmRollsError
        self.saveError = saveError
    }

    func loadFilmRolls() async throws -> [FilmRoll] {
        loadFilmRollsCallCount += 1
        if let loadFilmRollsError {
            throw loadFilmRollsError
        }
        return Array(filmRollsByID.values)
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
        deletedIDs.append(id)
        filmRollsByID[id] = nil
    }
}

private actor FeatureActorFilmRollRepository: FilmRollRepository {
    private var filmRollsByID: [String: FilmRoll]
    private(set) var savedFilmRolls: [FilmRoll] = []

    init(filmRolls: [FilmRoll] = []) {
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

private final class FeatureSpyLUTGenerator: LUTGenerating, @unchecked Sendable {
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

private final class FeatureSpyLUTImporter: LUTImporting, @unchecked Sendable {
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

private final class FeatureSpyLUTPreviewRenderer: LUTPreviewRendering, @unchecked Sendable {
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

private final class FeatureSpyThumbnailRenderer: ThumbnailRendering, @unchecked Sendable {
    let thumbnailData: Data

    init(thumbnailData: Data) {
        self.thumbnailData = thumbnailData
    }

    func renderThumbnail(from imageData: Data) async throws -> Data {
        thumbnailData
    }
}

private final class FeatureSpyLUTExporter: LUTExporting, @unchecked Sendable {
    let cubeText: String
    let error: Error?
    private(set) var requests: [LUTExportRequest] = []

    init(cubeText: String, error: Error? = nil) {
        self.cubeText = cubeText
        self.error = error
    }

    func exportLUT(for request: LUTExportRequest) async throws -> String {
        requests.append(request)
        if let error {
            throw error
        }
        return cubeText
    }
}

private final class FeatureSpyPhotoRenderer: PhotoRendering, @unchecked Sendable {
    let result: PhotoRenderResult
    private(set) var requests: [PhotoRenderRequest] = []
    private(set) var discardedResults: [PhotoRenderResult] = []

    init(result: PhotoRenderResult) {
        self.result = result
    }

    func renderPhoto(for request: PhotoRenderRequest) async throws -> PhotoRenderResult {
        requests.append(request)
        return result
    }

    func discardRenderedPhoto(_ result: PhotoRenderResult) async {
        discardedResults.append(result)
    }
}

private final class FeatureSpyPhotoPreviewRenderer: PhotoPreviewRendering, @unchecked Sendable {
    let error: Error?
    private(set) var requests: [PhotoPreviewRenderRequest] = []
    private(set) var discardedPaths: [String] = []

    init(error: Error? = nil) {
        self.error = error
    }

    func renderPreview(for request: PhotoPreviewRenderRequest) async throws -> PhotoPreviewRenderResult {
        requests.append(request)
        if let error {
            throw error
        }
        return PhotoPreviewRenderResult(
            previewID: request.previewID,
            originalPath: request.originalPath,
            previewPath: "tmp/apply-previews/\(request.previewID)/preview.jpg",
            intensity: request.intensity
        )
    }

    func discardRenderedPreview(at relativePath: String) async {
        discardedPaths.append(relativePath)
    }
}

private final class FeaturePreviewIDGenerator: @unchecked Sendable {
    private let lock = NSLock()
    private var ids: [String]

    init(ids: [String]) {
        self.ids = ids
    }

    func next() -> String {
        lock.lock()
        defer { lock.unlock() }
        guard !ids.isEmpty else {
            return UUID().uuidString
        }
        return ids.removeFirst()
    }
}

private final class FeatureSpyPhotoLibraryWriter: PhotoLibraryWriting, @unchecked Sendable {
    let localIdentifier: String
    let error: Error?
    private(set) var processedPaths: [String] = []

    init(localIdentifier: String = "photos-id", error: Error? = nil) {
        self.localIdentifier = localIdentifier
        self.error = error
    }

    func savePhotoToLibrary(processedPath: String) async throws -> String {
        processedPaths.append(processedPath)
        if let error {
            throw error
        }
        return localIdentifier
    }
}

private final class FeatureSpyFilmRollAssetWriter: FilmRollAssetWriting, @unchecked Sendable {
    let reservedID: String
    let referenceAsset: FilmRollReferenceAsset
    private(set) var writeCubeExportCalls: [(filmRollID: String, cubeText: String, suggestedFilename: String)] = []
    private(set) var discardedFilmRollIDs: [String] = []

    init(
        reservedID: String = "unused",
        referenceAsset: FilmRollReferenceAsset = FilmRollReferenceAsset(originalPath: "unused", thumbnailPath: "unused")
    ) {
        self.reservedID = reservedID
        self.referenceAsset = referenceAsset
    }

    func reserveFilmRollID() async throws -> String {
        reservedID
    }

    func storeReferenceImage(
        filmRollID: String,
        imageData: Data,
        thumbnailData: Data,
        preferredFileExtension: String?
    ) async throws -> FilmRollReferenceAsset {
        referenceAsset
    }

    func discardFilmRollAssets(filmRollID: String) async {
        discardedFilmRollIDs.append(filmRollID)
    }

    func writeCubeExport(filmRollID: String, cubeText: String, suggestedFilename: String) async throws -> URL {
        writeCubeExportCalls.append((filmRollID: filmRollID, cubeText: cubeText, suggestedFilename: suggestedFilename))
        return URL(fileURLWithPath: "/tmp/\(suggestedFilename)")
    }
}

private actor FeatureSuspendingFilmRollRepository: FilmRollRepository {
    private let filmRolls: [FilmRoll]
    private var loadFilmRollsContinuation: CheckedContinuation<[FilmRoll], Error>?
    private var loadFilmRollsWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var loadFilmRollsCallCount = 0

    init(filmRolls: [FilmRoll]) {
        self.filmRolls = filmRolls
    }

    func loadFilmRolls() async throws -> [FilmRoll] {
        try await withCheckedThrowingContinuation { continuation in
            loadFilmRollsCallCount += 1
            loadFilmRollsContinuation = continuation
            loadFilmRollsWaiters.forEach { $0.resume() }
            loadFilmRollsWaiters.removeAll()
        }
    }

    func waitForLoadFilmRollsCallCount(_ expectedCount: Int) async {
        if loadFilmRollsCallCount >= expectedCount {
            return
        }
        await withCheckedContinuation { continuation in
            loadFilmRollsWaiters.append(continuation)
        }
    }

    func resumeLoadFilmRolls() {
        loadFilmRollsContinuation?.resume(returning: filmRolls)
        loadFilmRollsContinuation = nil
    }

    func loadFilmRoll(id: String) async throws -> FilmRoll {
        guard let roll = filmRolls.first(where: { $0.id == id }) else {
            throw LumoError.filmRollNotFound(id: id)
        }
        return roll
    }

    func saveFilmRoll(_ filmRoll: FilmRoll) async throws {}

    func deleteFilmRoll(id: String) async throws {}
}

private actor FeatureQueuedFilmRollRepository: FilmRollRepository {
    private var loadFilmRollsResults: [Result<[FilmRoll], Error>]
    private var loadFilmRollResults: [Result<FilmRoll, Error>]
    private(set) var loadFilmRollsCallCount = 0
    private(set) var loadedIDs: [String] = []

    init(
        loadFilmRollsResults: [Result<[FilmRoll], Error>] = [],
        loadFilmRollResults: [Result<FilmRoll, Error>] = []
    ) {
        self.loadFilmRollsResults = loadFilmRollsResults
        self.loadFilmRollResults = loadFilmRollResults
    }

    func loadFilmRolls() async throws -> [FilmRoll] {
        loadFilmRollsCallCount += 1
        guard !loadFilmRollsResults.isEmpty else {
            return []
        }
        return try loadFilmRollsResults.removeFirst().get()
    }

    func loadFilmRoll(id: String) async throws -> FilmRoll {
        loadedIDs.append(id)
        guard !loadFilmRollResults.isEmpty else {
            throw LumoError.filmRollNotFound(id: id)
        }
        return try loadFilmRollResults.removeFirst().get()
    }

    func saveFilmRoll(_ filmRoll: FilmRoll) async throws {}

    func deleteFilmRoll(id: String) async throws {}
}

private actor FeatureSuspendingLUTGenerator: LUTGenerating {
    private let lut: LUT3D
    private var generationContinuations: [CheckedContinuation<LUT3D, Error>] = []
    private var requestWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var requestCount = 0

    init(lut: LUT3D) {
        self.lut = lut
    }

    func generateLUT(for request: LUTGenerationRequest) async throws -> LUT3D {
        try await withCheckedThrowingContinuation { continuation in
            requestCount += 1
            generationContinuations.append(continuation)
            requestWaiters.forEach { $0.resume() }
            requestWaiters.removeAll()
        }
    }

    func waitForRequestCount(_ expectedCount: Int) async {
        if requestCount >= expectedCount {
            return
        }
        await withCheckedContinuation { continuation in
            requestWaiters.append(continuation)
        }
    }

    func resumeGeneration() {
        generationContinuations.forEach { $0.resume(returning: lut) }
        generationContinuations.removeAll()
    }
}

private actor FeatureSuspendingLUTExporter: LUTExporting {
    private let cubeText: String
    private var exportContinuation: CheckedContinuation<String, Error>?
    private var requestWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var requestCount = 0

    init(cubeText: String) {
        self.cubeText = cubeText
    }

    func exportLUT(for request: LUTExportRequest) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            requestCount += 1
            exportContinuation = continuation
            requestWaiters.forEach { $0.resume() }
            requestWaiters.removeAll()
        }
    }

    func waitForRequestCount(_ expectedCount: Int) async {
        if requestCount >= expectedCount {
            return
        }
        await withCheckedContinuation { continuation in
            requestWaiters.append(continuation)
        }
    }

    func resumeExport() {
        exportContinuation?.resume(returning: cubeText)
        exportContinuation = nil
    }
}

private actor FeatureSuspendingPhotoRenderer: PhotoRendering {
    private let result: PhotoRenderResult
    private var renderContinuation: CheckedContinuation<PhotoRenderResult, Error>?
    private var requestWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var requestCount = 0

    init(result: PhotoRenderResult) {
        self.result = result
    }

    func renderPhoto(for request: PhotoRenderRequest) async throws -> PhotoRenderResult {
        try await withCheckedThrowingContinuation { continuation in
            requestCount += 1
            renderContinuation = continuation
            requestWaiters.forEach { $0.resume() }
            requestWaiters.removeAll()
        }
    }

    func waitForRequestCount(_ expectedCount: Int) async {
        if requestCount >= expectedCount {
            return
        }
        await withCheckedContinuation { continuation in
            requestWaiters.append(continuation)
        }
    }

    func resumeRender() {
        renderContinuation?.resume(returning: result)
        renderContinuation = nil
    }

    func discardRenderedPhoto(_ result: PhotoRenderResult) async {}
}

private actor FeatureSuspendingPhotoPreviewRenderer: PhotoPreviewRendering {
    private var requests: [PhotoPreviewRenderRequest] = []
    private var pendingRenders: [(request: PhotoPreviewRenderRequest, continuation: CheckedContinuation<PhotoPreviewRenderResult, Error>)] = []
    private var requestWaiters: [CheckedContinuation<Void, Never>] = []
    private(set) var discardedPaths: [String] = []

    func renderPreview(for request: PhotoPreviewRenderRequest) async throws -> PhotoPreviewRenderResult {
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

    func resumeLatest() {
        guard !pendingRenders.isEmpty else {
            return
        }
        let pending = pendingRenders.removeLast()
        pending.continuation.resume(returning: result(for: pending.request))
    }

    func resumeOldest() {
        guard !pendingRenders.isEmpty else {
            return
        }
        let pending = pendingRenders.removeFirst()
        pending.continuation.resume(returning: result(for: pending.request))
    }

    func discardRenderedPreview(at relativePath: String) async {
        discardedPaths.append(relativePath)
    }

    private func result(for request: PhotoPreviewRenderRequest) -> PhotoPreviewRenderResult {
        PhotoPreviewRenderResult(
            previewID: request.previewID,
            originalPath: request.originalPath,
            previewPath: "tmp/apply-previews/\(request.previewID)/preview.jpg",
            intensity: request.intensity
        )
    }
}

private final class FeatureStubReferenceImageDataLoader: FilmRollReferenceImageDataLoading, @unchecked Sendable {
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

private final class FeatureStubDiagnosticLUTGenerator: LUTGenerating, @unchecked Sendable {
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

private func featureRoll(
    id: String,
    name: String,
    lut: LUT3D = LUT3D.identity()
) throws -> FilmRoll {
    try FilmRoll(
        id: id,
        name: name,
        createdAt: Date(timeIntervalSince1970: 100),
        referenceAsset: FilmRollReferenceAsset(originalPath: "reference/original.jpg", thumbnailPath: "reference/thumb.jpg"),
        lut: lut
    )
}
