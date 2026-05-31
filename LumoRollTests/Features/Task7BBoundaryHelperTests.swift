import XCTest
import UniformTypeIdentifiers
@testable import LumoRoll

final class Task7BBoundaryHelperTests: XCTestCase {
    func testFullscreenSaveStateRejectsDuplicateStartWhileRequestIsActive() {
        var state = FullscreenSaveStatusState()

        let firstRequest = state.start(
            frameID: "processed-1",
            selectedIndex: 1,
            processedPath: "rolls/roll-1/processed-1.jpg"
        )
        let duplicateRequest = state.start(
            frameID: "processed-1",
            selectedIndex: 1,
            processedPath: "rolls/roll-1/processed-1.jpg"
        )

        XCTAssertEqual(
            firstRequest,
            FullscreenSaveRequest(
                frameID: "processed-1",
                selectedIndex: 1,
                processedPath: "rolls/roll-1/processed-1.jpg"
            )
        )
        XCTAssertNil(duplicateRequest)
        XCTAssertEqual(state.activeRequest, firstRequest)
    }

    func testFullscreenSaveCompletionAfterFrameChangeDoesNotSurfaceStatusAndClearsRequest() {
        var state = FullscreenSaveStatusState()
        let request = state.start(
            frameID: "processed-1",
            selectedIndex: 1,
            processedPath: "rolls/roll-1/processed-1.jpg"
        )

        let status = state.complete(
            request,
            currentFrameID: "processed-2",
            currentSelectedIndex: 2,
            completion: .success
        )

        XCTAssertNil(status)
        XCTAssertNil(state.activeRequest)
    }

    func testFullscreenSaveMatchingCompletionSurfacesStatusAndClearsRequest() {
        var state = FullscreenSaveStatusState()
        let request = state.start(
            frameID: "processed-1",
            selectedIndex: 1,
            processedPath: "rolls/roll-1/processed-1.jpg"
        )

        let status = state.complete(
            request,
            currentFrameID: "processed-1",
            currentSelectedIndex: 1,
            completion: .failure("Photos access is needed.")
        )

        XCTAssertEqual(status, "Could not save to Photos: Photos access is needed.")
        XCTAssertNil(state.activeRequest)
    }

    func testFullscreenPendingActionsAreUnavailableInsteadOfSilentNoOps() {
        let availability = FullscreenActionAvailability.task8Pending

        for action in FullscreenViewerAction.allCases {
            XCTAssertFalse(availability.isAvailable(action))
            XCTAssertFalse(availability.unavailableMessage(for: action).isEmpty)
        }
    }

    func testFullscreenProcessedFrameActionsAreShareEditAndRemoveOnly() {
        XCTAssertEqual(FullscreenViewerAction.allCases, [.share, .edit, .remove])
        XCTAssertEqual(FullscreenViewerAction.allCases.map(\.title), ["Share", "Edit", "Remove"])
    }

    func testFullscreenReferenceFrameReservesProcessedActionBarSpace() {
        XCTAssertTrue(FullscreenActionBarLayout.reservesProcessedFrameActionSpace)
        XCTAssertEqual(FullscreenActionBarLayout.reservedActions, FullscreenViewerAction.allCases)
    }

    func testFullscreenPhotoPreviewDoesNotExposeZoomOrPanGestures() {
        XCTAssertFalse(FullscreenPhotoPreviewInteraction.supportsPinchZoom)
        XCTAssertFalse(FullscreenPhotoPreviewInteraction.supportsTwoFingerPan)
    }

    func testApplyTargetTilesExposeImportBoundaryWithoutSelectingFakeTarget() {
        let emptyTiles = ApplyTargetPhotoTile.tiles(selectedTargetPhotoPath: nil)

        XCTAssertEqual(emptyTiles.map(\.kind), [.importTarget, .addTarget])
        XCTAssertTrue(emptyTiles.allSatisfy(\.triggersImportBoundary))

        let selectedTiles = ApplyTargetPhotoTile.tiles(selectedTargetPhotoPath: "real-task-8-target.jpg")
        XCTAssertEqual(selectedTiles.map(\.kind), [.selectedTarget, .addTarget])
        XCTAssertTrue(selectedTiles.allSatisfy(\.triggersImportBoundary))
    }

    func testApplyPreviewChromeShowsAfterTargetPhotoImport() {
        XCTAssertFalse(ApplyPreviewChromeVisibility.shouldShowPreviewChrome(selectedTargetPhotoPath: nil))
        XCTAssertFalse(ApplyPreviewChromeVisibility.shouldShowPreviewChrome(selectedTargetPhotoPath: ""))
        XCTAssertTrue(ApplyPreviewChromeVisibility.shouldShowPreviewChrome(selectedTargetPhotoPath: "tmp/imports/target/original.jpg"))
    }

    func testApplyImportControlsAreHiddenAfterTargetPhotoIsSelected() {
        XCTAssertTrue(ApplyImportControlsVisibility.shouldShowImportControls(selectedTargetPhotoPath: nil))
        XCTAssertTrue(ApplyImportControlsVisibility.shouldShowImportControls(selectedTargetPhotoPath: ""))
        XCTAssertFalse(ApplyImportControlsVisibility.shouldShowImportControls(selectedTargetPhotoPath: "tmp/imports/target/original.jpg"))
    }

    func testApplyPreviewLayoutPreservesImageAspectRatioAndBoundsHeightForSingleScreenLayout() {
        XCTAssertEqual(ApplyPreviewLayout.frameAspectRatio(forLoadedImageAspectRatio: 4.0 / 3.0), 4.0 / 3.0)
        XCTAssertEqual(
            ApplyPreviewLayout.frameAspectRatio(forLoadedImageAspectRatio: 9.0 / 16.0),
            9.0 / 16.0
        )
        XCTAssertEqual(
            ApplyPreviewLayout.frameAspectRatio(forLoadedImageAspectRatio: nil),
            LumoPreviewAspectRatio.fallback
        )
        XCTAssertEqual(ApplyPreviewLayout.previewMaxHeight(forContainerHeight: 852), 426)
        XCTAssertEqual(ApplyPreviewLayout.previewMaxHeight(forContainerHeight: 1_200), ApplyPreviewLayout.maximumPreviewHeight)
        XCTAssertEqual(ApplyPreviewLayout.previewMaxHeight(forContainerHeight: 400), ApplyPreviewLayout.minimumPreviewHeight)
    }

    func testLibraryCarouselCardKeepsEqualSlideSizesAndVisibleSideCards() {
        let contentWidth: CGFloat = 361
        let cardWidth = PerspectiveFilmCarouselLayout.cardWidth(forContentWidth: contentWidth)
        let sideInset = PerspectiveFilmCarouselLayout.sideInset(
            forContentWidth: contentWidth,
            cardWidth: cardWidth
        )

        XCTAssertEqual(PerspectiveFilmCarouselLayout.slideCardAspectRatio, 1)
        XCTAssertLessThan(cardWidth, contentWidth)
        XCTAssertLessThan(cardWidth, 250)
        XCTAssertGreaterThanOrEqual(cardWidth, 220)
        XCTAssertEqual(sideInset, (contentWidth - cardWidth) / 2, accuracy: 0.001)
        XCTAssertGreaterThan(PerspectiveFilmCarouselLayout.centerScale, PerspectiveFilmCarouselLayout.sideScale)
        XCTAssertGreaterThan(PerspectiveFilmCarouselLayout.bottomSummaryTopSpacing, 60)
        XCTAssertGreaterThan(PerspectiveFilmCarouselLayout.carouselTopInset(forAvailableHeight: 700), 40)
        XCTAssertLessThan(PerspectiveFilmCarouselLayout.cardSpacing, -50)
        XCTAssertLessThan(PerspectiveFilmCarouselLayout.sideOpacity, 1)
        XCTAssertGreaterThan(LibraryCarouselHaptics.impactIntensity, 0.8)
    }

    func testLibraryCarouselTitleSitsAboveCardAndCardKeepsLowerBias() {
        XCTAssertEqual(LibraryCarouselTitleLayout.selectedSummaryPlacement, .aboveCarousel)
        XCTAssertEqual(LibraryCarouselTitleLayout.cardVerticalBias, .slightlyBelowCenter)
        XCTAssertGreaterThan(
            PerspectiveFilmCarouselLayout.carouselTopInset(forAvailableHeight: 700),
            90
        )
        XCTAssertTrue(LibraryCarouselAddCardPresentation.reservesRollSummaryRows)
    }

    func testLibraryHomeTitleAndCardAreLiftedTogether() {
        let rawInset = PerspectiveFilmCarouselLayout.carouselTopInset(forAvailableHeight: 700)
        let liftedInset = LibraryCarouselTitleLayout.titleTopInset(forAvailableHeight: 700)

        XCTAssertEqual(LibraryCarouselTitleLayout.titleAndCardLift, 20)
        XCTAssertLessThan(liftedInset, rawInset)
        XCTAssertEqual(rawInset - liftedInset, LibraryCarouselTitleLayout.titleAndCardLift, accuracy: 0.001)
    }

    func testLibraryHomeCardCenterSitsTwentyPointsBelowViewportCenter() {
        let availableHeight: CGFloat = 700
        let titleTopInset = LibraryCarouselTitleLayout.titleTopInset(forAvailableHeight: availableHeight)
        let summarySpacing = LibraryCarouselTitleLayout.summaryToCarouselSpacing(forAvailableHeight: availableHeight)
        let cardCenterY = titleTopInset
            + LibraryCarouselTitleLayout.selectedSummaryReservedHeight
            + summarySpacing
            + (LibraryCarouselLayout.carouselHeight / 2)
            + LibraryCarouselTitleLayout.carouselVisualOffsetY

        XCTAssertEqual(LibraryCarouselTitleLayout.titleAndCardLift, 20)
        XCTAssertEqual(LibraryCarouselTitleLayout.cardCenterOffsetFromViewportCenter, 20)
        XCTAssertEqual(LibraryCarouselTitleLayout.carouselVisualOffsetY, 0, accuracy: 0.001)
        XCTAssertEqual(cardCenterY - (availableHeight / 2), LibraryCarouselTitleLayout.cardCenterOffsetFromViewportCenter, accuracy: 0.001)
        XCTAssertGreaterThanOrEqual(summarySpacing, 0)
    }

    func testLibraryCarouselInteractionKeepsHorizontalDragAvailableOverCards() {
        XCTAssertEqual(LibraryCarouselInteraction.cardActivation, .tapGesture)
        XCTAssertEqual(LibraryCarouselInteraction.dragGesturePriority, .highPriority)
        XCTAssertLessThanOrEqual(LibraryCarouselInteraction.dragMinimumDistance, 8)
        XCTAssertEqual(LibraryCarouselInteraction.dragStateLifetime, .persistentThroughSnapAnimation)
    }

    func testLibraryCarouselSnapPreservesReleaseVisualOffsetAfterChangingCenterIndex() {
        let itemStep: CGFloat = 180
        let releaseTranslation: CGFloat = -70
        let indexDelta = 1
        let continuityTranslation = PerspectiveFilmCarouselLayout.continuityDragTranslation(
            releaseTranslation: releaseTranslation,
            indexDelta: indexDelta,
            itemStep: itemStep
        )

        let targetOffsetBeforeCenterSwitch = CGFloat(indexDelta) + (releaseTranslation / itemStep)
        let targetOffsetAfterCenterSwitch = continuityTranslation / itemStep

        XCTAssertEqual(targetOffsetAfterCenterSwitch, targetOffsetBeforeCenterSwitch, accuracy: 0.001)
        XCTAssertGreaterThan(continuityTranslation, 0)
    }

    func testPerspectiveCarouselTransformFacesSideCardsTowardCenterContinuously() {
        let center = PerspectiveFilmCarouselLayout.coverFlowTransform(normalizedOffset: 0)
        let halfRight = PerspectiveFilmCarouselLayout.coverFlowTransform(normalizedOffset: 0.5)
        let right = PerspectiveFilmCarouselLayout.coverFlowTransform(normalizedOffset: 1)
        let left = PerspectiveFilmCarouselLayout.coverFlowTransform(normalizedOffset: -1)

        XCTAssertEqual(center.rotationYDegrees, 0, accuracy: 0.001)
        XCTAssertGreaterThan(left.rotationYDegrees, 0)
        XCTAssertLessThan(right.rotationYDegrees, 0)
        XCTAssertLessThan(abs(halfRight.rotationYDegrees), abs(right.rotationYDegrees))
        XCTAssertGreaterThan(center.scale, halfRight.scale)
        XCTAssertGreaterThan(halfRight.scale, right.scale)
        XCTAssertGreaterThan(center.opacity, right.opacity)
        XCTAssertGreaterThan(center.zIndex, right.zIndex)
        XCTAssertGreaterThan(center.photoLightAmount, right.photoLightAmount)
        XCTAssertLessThan(right.photoLightAmount, 0.35)
    }

    func testSlideMountPhotoWindowKeepsFixedHeightAndWidthFollowsImageAspectRatio() {
        let cardSize: CGFloat = 280
        let portrait = PerspectiveFilmCarouselLayout.photoWindowSize(cardSize: cardSize, imageAspectRatio: 0.75)
        let landscape = PerspectiveFilmCarouselLayout.photoWindowSize(cardSize: cardSize, imageAspectRatio: 1.5)
        let panoramic = PerspectiveFilmCarouselLayout.photoWindowSize(cardSize: cardSize, imageAspectRatio: 4)

        XCTAssertEqual(portrait.height, landscape.height, accuracy: 0.001)
        XCTAssertEqual(landscape.height, panoramic.height, accuracy: 0.001)
        XCTAssertLessThan(portrait.width, landscape.width)
        XCTAssertLessThan(landscape.width, panoramic.width)
        XCTAssertLessThanOrEqual(panoramic.width, cardSize * PerspectiveFilmCarouselLayout.photoWindowMaxWidthFraction)
    }

    func testLibraryHomeDisablesVerticalScrolling() {
        XCTAssertFalse(LibraryHomeLayout.allowsVerticalScroll)
    }

    func testLibraryHomeUsesCarouselAddCardInsteadOfTopChrome() {
        XCTAssertFalse(LibraryHomeChrome.showsTopBrandAndCreateControls)
        XCTAssertTrue(LibraryCarouselAddCardPresentation.showsCenteredAddButton)
        XCTAssertEqual(LibraryCarouselAddCardPresentation.summaryTitle, "Create a new roll")
        XCTAssertEqual(LibraryCarouselAddCardPresentation.accessibilityLabel, "Create Film Roll")
    }

    func testLibraryEmptyStateUsesBlankReversalSlideCardPrompt() {
        XCTAssertEqual(LibraryEmptyStatePresentation.heroKind, .blankReversalSlideCard)
        XCTAssertEqual(LibraryEmptyStatePresentation.title, "Create your first Film Roll")
        XCTAssertNil(LibraryEmptyStatePresentation.actionTitle)
        XCTAssertNil(LibraryEmptyStatePresentation.photoPlaceholderTitle)
        XCTAssertEqual(LibraryEmptyStatePresentation.backgroundTreatment, .none)
        XCTAssertEqual(LibraryEmptyStatePresentation.contentPlacement, .matchesSingleRollCarouselSlot)
        XCTAssertFalse(LibraryEmptyStateLayout.showsPrimaryActionButton)
        XCTAssertEqual(LibraryEmptyStateLayout.titlePlacement, .aboveCarousel)

        let contentWidth: CGFloat = 393
        let availableHeight: CGFloat = 720
        XCTAssertEqual(
            LibraryEmptyStateLayout.cardWidth(forContentWidth: contentWidth),
            PerspectiveFilmCarouselLayout.cardWidth(forContentWidth: contentWidth),
            accuracy: 0.001
        )
        XCTAssertEqual(
            LibraryEmptyStateLayout.titleTopInset(forAvailableHeight: availableHeight),
            LibraryCarouselTitleLayout.titleTopInset(forAvailableHeight: availableHeight),
            accuracy: 0.001
        )
        XCTAssertEqual(
            LibraryEmptyStateLayout.summaryReservedHeight,
            LibraryCarouselTitleLayout.selectedSummaryReservedHeight,
            accuracy: 0.001
        )
        XCTAssertEqual(
            LibraryEmptyStateLayout.summaryToCarouselSpacing(forAvailableHeight: availableHeight),
            LibraryCarouselTitleLayout.summaryToCarouselSpacing(forAvailableHeight: availableHeight),
            accuracy: 0.001
        )
        let emptyCardCenterY = LibraryEmptyStateLayout.titleTopInset(forAvailableHeight: availableHeight)
            + LibraryEmptyStateLayout.summaryReservedHeight
            + LibraryEmptyStateLayout.summaryToCarouselSpacing(forAvailableHeight: availableHeight)
            + (PerspectiveFilmCarouselLayout.carouselHeight / 2)
        XCTAssertEqual(
            emptyCardCenterY - (availableHeight / 2),
            LibraryCarouselTitleLayout.cardCenterOffsetFromViewportCenter,
            accuracy: 0.001
        )
        XCTAssertFalse(LibraryEmptyStateLayout.showsBottomSummary)
        XCTAssertFalse(LibraryEmptyStateLayout.showsPageIndicator)
        XCTAssertEqual(
            LibraryEmptyStateLayout.centerCardTransform,
            PerspectiveFilmCarouselLayout.coverFlowTransform(normalizedOffset: 0)
        )
    }

    func testLibraryCarouselAppendsBlankAddCardAfterSavedRolls() throws {
        let roll = try FilmRoll(
            id: "fuji-blue",
            name: "Fuji Blue",
            createdAt: Date(timeIntervalSince1970: 100),
            referenceAsset: FilmRollReferenceAsset(
                originalPath: "rolls/fuji/reference.jpg",
                thumbnailPath: "rolls/fuji/reference-thumb.jpg"
            ),
            lut: LUT3D.identity(),
            processedPhotos: []
        )

        let items = LibraryCarouselItem.items(for: [FilmRollDisplayData(filmRoll: roll)])

        XCTAssertEqual(items.map(\.kind), [.roll, .addRoll])
        XCTAssertEqual(items.first?.rollID, "fuji-blue")
        XCTAssertEqual(items.first?.summaryTitle, "Fuji Blue")
        XCTAssertEqual(items.last?.id, LibraryCarouselAddCardPresentation.id)
        XCTAssertEqual(items.last?.rollID, nil)
        XCTAssertEqual(items.last?.summaryTitle, "Create a new roll")
        XCTAssertTrue(items.last?.requestsCreate == true)
    }

    func testCreateFilmRollFlowRemovesAnalysisStepAndFitsOnePage() {
        XCTAssertEqual(CreateFilmRollLayout.steps, [.reference, .naming])
        XCTAssertEqual(CreateFilmRollLayout.stepLabel(for: .reference), "Step 1 of 2")
        XCTAssertEqual(CreateFilmRollLayout.stepLabel(for: .naming), "Step 2 of 2")
        XCTAssertLessThanOrEqual(
            CreateFilmRollLayout.estimatedContentHeight(forViewportHeight: 852),
            CreateFilmRollLayout.availableContentHeight(forViewportHeight: 852)
        )
    }

    func testCreateFilmRollSaveRequiresReferenceNameAndIdleState() {
        XCTAssertFalse(CreateFilmRollSaveAvailability.isEnabled(canSave: false, isWorking: false))
        XCTAssertFalse(CreateFilmRollSaveAvailability.isEnabled(canSave: true, isWorking: true))
        XCTAssertTrue(CreateFilmRollSaveAvailability.isEnabled(canSave: true, isWorking: false))
    }

    func testCreateFilmRollReferenceStepUsesSingleAddReferenceChoice() {
        XCTAssertEqual(CreateFilmRollReferenceStepCopy.title, "Pick a photo sample or a cube LUT")
        XCTAssertEqual(CreateFilmRollReferenceStepCopy.placeholderTitle, "Add a reference")
        XCTAssertEqual(CreateFilmRollReferenceSourceChoice.title, "Add a reference")
        XCTAssertFalse(CreateFilmRollReferenceSourceChoice.showsInlineSourceButtons)
        XCTAssertEqual(CreateFilmRollReferenceImportSource.allCases.map(\.label), ["Photos", "Files"])
        XCTAssertEqual(CreateFilmRollReferenceImportSource.photos.presentation, .photosPicker)
        XCTAssertEqual(CreateFilmRollReferenceImportSource.files.presentation, .fileImporter)
    }

    func testSlideMountLightingBrightensWindowWithoutRetoningThumbnail() {
        let centered = SlideMountPhotoWindowLightingStyle.values(centerProgress: 1)
        let side = SlideMountPhotoWindowLightingStyle.values(centerProgress: 0.28)

        XCTAssertEqual(centered.imageSaturation, 1, accuracy: 0.001)
        XCTAssertEqual(side.imageSaturation, 1, accuracy: 0.001)
        XCTAssertEqual(centered.imageContrast, 1, accuracy: 0.001)
        XCTAssertEqual(side.imageContrast, 1, accuracy: 0.001)
        XCTAssertEqual(centered.imageBrightness, 0, accuracy: 0.001)
        XCTAssertEqual(side.imageBrightness, 0, accuracy: 0.001)
        XCTAssertGreaterThan(centered.windowLightOpacity, side.windowLightOpacity)
        XCTAssertGreaterThan(side.dimOverlayOpacity, 0.75)
    }

    func testCreateFilmRollFilesImportAcceptsCubeLUTFiles() {
        XCTAssertTrue(CreateFilmRollAllowedImportTypes.values.contains(.lumoCube))
        XCTAssertEqual(CreateFilmRollFileImportKind.kind(forFilename: "Portra 160NC.cube"), .cubeLUT)
        XCTAssertEqual(CreateFilmRollFileImportKind.kind(forFilename: "reference.JPG"), .image)
    }

    func testAppDeclaresCubeDocumentTypeSoFilesPickerCanSelectCubeFiles() {
        let infoPlist: [String: Any]
        do {
            infoPlist = try Self.sourceInfoPlist()
        } catch {
            XCTFail("Could not read source Info.plist: \(error)")
            return
        }
        guard let importedTypes = infoPlist["UTImportedTypeDeclarations"] as? [[String: Any]] else {
            XCTFail("Missing UTImportedTypeDeclarations")
            return
        }
        guard let cubeType = importedTypes.first(where: { declaration in
            declaration["UTTypeIdentifier"] as? String == "com.lumoroll.cube"
        }) else {
            XCTFail("Missing com.lumoroll.cube imported type declaration")
            return
        }
        guard let conformsTo = cubeType["UTTypeConformsTo"] as? [String],
              let tagSpec = cubeType["UTTypeTagSpecification"] as? [String: Any],
              let filenameExtensions = tagSpec["public.filename-extension"] as? [String] else {
            XCTFail("Malformed com.lumoroll.cube imported type declaration")
            return
        }

        XCTAssertTrue(conformsTo.contains(UTType.plainText.identifier))
        XCTAssertTrue(filenameExtensions.contains("cube"))

        guard let documentTypes = infoPlist["CFBundleDocumentTypes"] as? [[String: Any]] else {
            XCTFail("Missing CFBundleDocumentTypes")
            return
        }
        guard let cubeDocumentType = documentTypes.first(where: { documentType in
            guard let contentTypes = documentType["LSItemContentTypes"] as? [String] else {
                return false
            }
            return contentTypes.contains("com.lumoroll.cube")
        }) else {
            XCTFail("Missing Cube LUT document type")
            return
        }

        XCTAssertEqual(cubeDocumentType["CFBundleTypeName"] as? String, "Cube LUT")
    }

    func testLibraryCarouselUsesLinearBoundariesWithoutLooping() {
        XCTAssertEqual(LibraryCarouselLayout.indexByAdding(-1, to: 0, count: 3), 0)
        XCTAssertEqual(LibraryCarouselLayout.indexByAdding(1, to: 2, count: 3), 2)
        XCTAssertEqual(LibraryCarouselLayout.indexByAdding(2, to: 1, count: 3), 2)
        XCTAssertEqual(LibraryCarouselLayout.indexByAdding(-2, to: 1, count: 3), 0)
        XCTAssertEqual(
            LibraryCarouselLayout.normalizedOffset(
                itemIndex: 2,
                centeredIndex: 0,
                itemCount: 3,
                dragTranslation: 0,
                itemStep: 100
            ),
            2
        )
        XCTAssertEqual(
            LibraryCarouselLayout.normalizedOffset(
                itemIndex: 0,
                centeredIndex: 2,
                itemCount: 3,
                dragTranslation: 0,
                itemStep: 100
            ),
            -2
        )
        XCTAssertEqual(
            LibraryCarouselLayout.boundedDragTranslation(
                90,
                centeredIndex: 0,
                itemCount: 3,
                itemStep: 100
            ),
            0
        )
        XCTAssertEqual(
            LibraryCarouselLayout.boundedDragTranslation(
                -90,
                centeredIndex: 2,
                itemCount: 3,
                itemStep: 100
            ),
            0
        )
    }

    func testLibraryCarouselSelectionChoosesClosestCardToViewportCenter() {
        let selectedID = LibraryCarouselSelection.centeredRollID(
            frames: [
                LibraryCarouselCardFrameInfo(id: "left", midX: 42),
                LibraryCarouselCardFrameInfo(id: "center", midX: 181),
                LibraryCarouselCardFrameInfo(id: "right", midX: 320)
            ],
            viewportMidX: 196
        )

        XCTAssertEqual(selectedID, "center")
    }

    func testLibrarySlideMountCopyAvoidsProtectedFilmBranding() {
        let combinedCopy = [
            LibrarySlideMountCopy.brandLine,
            LibrarySlideMountCopy.categoryLine,
            LibrarySlideMountCopy.lowerLeftLabel,
            LibrarySlideMountCopy.lowerRightLabel
        ].joined(separator: " ")

        XCTAssertEqual(LibrarySlideMountCopy.brandLine, "LUMOROLL")
        XCTAssertEqual(LibrarySlideMountCopy.categoryLine, "COLOR ROLL")
        XCTAssertFalse(combinedCopy.localizedCaseInsensitiveContains("kodak"))
    }

    func testFilmRollDetailMenuKeepsManagementSeparateFromBottomActions() {
        XCTAssertEqual(FilmRollDetailActions.menuActionTitles, ["Rename", "Remove"])
        XCTAssertEqual(FilmRollDetailActions.independentActionTitles, ["Export .cube", "Add photo"])
        XCTAssertEqual(FilmRollDetailActions.topToolbarIconActionTitles, ["Export .cube", "Add photo"])
        XCTAssertEqual(FilmRollDetailActions.titleIconActionTitles, [])
        XCTAssertFalse(FilmRollDetailLayout.showsBottomActionBar)
    }

    func testMVP1AvailabilityAllowsShareEditAndRemoveForProcessedFrame() {
        let frame = FilmRollViewerFrame(
            id: "processed-1",
            kind: .processed,
            displayLabel: "Frame 01",
            photo: LumoPhotoDisplayData(
                id: "processed-1",
                label: "01",
                image: nil,
                fullSizeRelativePath: "rolls/roll-1/processed-1.jpg"
            )
        )

        let availability = FullscreenActionAvailability.mvp1(for: frame)
        let shareAction = FullscreenViewerAction.allCases.first { $0.title == "Share" }

        XCTAssertEqual(FullscreenViewerAction.allCases.map(\.title), ["Share", "Edit", "Remove"])
        XCTAssertEqual(shareAction?.systemImage, "square.and.arrow.up")
        XCTAssertNotNil(shareAction)
        if let shareAction {
            XCTAssertTrue(availability.isAvailable(shareAction))
        }
        XCTAssertTrue(availability.isAvailable(.edit))
        XCTAssertTrue(availability.isAvailable(.remove))
    }

    func testMVP1AvailabilityRejectsReferenceFrameManagement() {
        let frame = FilmRollViewerFrame(
            id: "reference",
            kind: .reference,
            displayLabel: "Sample",
            photo: LumoPhotoDisplayData(
                id: "reference",
                label: "Sample",
                image: nil,
                fullSizeRelativePath: "rolls/roll-1/reference.jpg"
            )
        )

        let availability = FullscreenActionAvailability.mvp1(for: frame)
        let shareAction = FullscreenViewerAction.allCases.first { $0.title == "Share" }

        XCTAssertNotNil(shareAction)
        if let shareAction {
            XCTAssertFalse(availability.isAvailable(shareAction))
            XCTAssertTrue(availability.unavailableMessage(for: shareAction).contains("reference"))
        }
        XCTAssertFalse(availability.isAvailable(.edit))
        XCTAssertFalse(availability.isAvailable(.remove))
        XCTAssertTrue(availability.unavailableMessage(for: .edit).contains("reference"))
        XCTAssertTrue(availability.unavailableMessage(for: .remove).contains("reference"))
    }

    func testMVP1AvailabilityAllowsRemovingProcessedFrameEvenWhenDisplayPathIsMissing() {
        let frame = FilmRollViewerFrame(
            id: "processed-missing",
            kind: .processed,
            displayLabel: "Frame 02",
            photo: LumoPhotoDisplayData(
                id: "processed-missing",
                label: "02",
                image: nil
            )
        )

        let availability = FullscreenActionAvailability.mvp1(for: frame)
        let shareAction = FullscreenViewerAction.allCases.first { $0.title == "Share" }

        XCTAssertNotNil(shareAction)
        if let shareAction {
            XCTAssertFalse(availability.isAvailable(shareAction))
            XCTAssertTrue(availability.unavailableMessage(for: shareAction).contains("rendered file"))
        }
        XCTAssertTrue(availability.isAvailable(.edit))
        XCTAssertTrue(availability.isAvailable(.remove))
    }

    func testProcessedOutputPathUsesOnlyProcessedFramesWithFullSizePaths() {
        let processedFrame = FilmRollViewerFrame(
            id: "processed-1",
            kind: .processed,
            displayLabel: "Frame 01",
            photo: LumoPhotoDisplayData(
                id: "processed-1",
                label: "01",
                image: nil,
                fullSizeRelativePath: "rolls/roll-1/processed-1.jpg"
            )
        )
        let referenceFrame = FilmRollViewerFrame(
            id: "reference",
            kind: .reference,
            displayLabel: "Sample",
            photo: LumoPhotoDisplayData(
                id: "reference",
                label: "Sample",
                image: nil,
                fullSizeRelativePath: "rolls/roll-1/reference.jpg"
            )
        )
        let missingPathFrame = FilmRollViewerFrame(
            id: "processed-missing",
            kind: .processed,
            displayLabel: "Frame 02",
            photo: LumoPhotoDisplayData(id: "processed-missing", label: "02", image: nil)
        )

        XCTAssertEqual(processedFrame.fullscreenProcessedOutputPath, "rolls/roll-1/processed-1.jpg")
        XCTAssertNil(referenceFrame.fullscreenProcessedOutputPath)
        XCTAssertNil(missingPathFrame.fullscreenProcessedOutputPath)
    }

    private static func sourceInfoPlist() throws -> [String: Any] {
        let testFileURL = URL(fileURLWithPath: #filePath)
        let projectRoot = testFileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let infoPlistURL = projectRoot.appendingPathComponent("LumoRoll/Resources/Info.plist")
        let data = try Data(contentsOf: infoPlistURL)
        return try XCTUnwrap(
            PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        )
    }
}
