import XCTest
@testable import LumoRoll

final class FilmRollDetailLayoutTests: XCTestCase {
    func testDetailIndependentActionsLiveInTopToolbarIconCluster() {
        XCTAssertEqual(FilmRollDetailActions.independentActionTitles, ["Export .cube", "Add photo"])
        XCTAssertEqual(FilmRollDetailActions.topToolbarIconActionTitles, ["Export .cube", "Add photo"])
        XCTAssertEqual(FilmRollDetailActions.titleIconActionTitles, [])
        XCTAssertEqual(FilmRollDetailActions.menuActionTitles, ["Rename", "Remove"])
        XCTAssertFalse(FilmRollDetailActions.menuActionTitles.contains("Add photo"))
        XCTAssertFalse(FilmRollDetailActions.menuActionTitles.contains("Export .cube"))
        XCTAssertFalse(FilmRollDetailLayout.showsBottomActionBar)
        XCTAssertEqual(FilmRollDetailLayout.exportButtonPlacement, .topToolbarTrailingIcon)
        XCTAssertEqual(FilmRollDetailLayout.addPhotoButtonPlacement, .topToolbarTrailingIcon)
    }

    func testDesignSystemOffersLargerFilmStripSizing() {
        let detailSizing = FilmStripSizing.detail

        XCTAssertEqual(detailSizing, .detail)
        XCTAssertFalse(FilmRollDetailLayout.allowsVerticalScroll)
        XCTAssertGreaterThan(detailSizing.frameWidth, FilmStripSizing.standard.frameWidth)
        XCTAssertGreaterThan(detailSizing.frameHeight, FilmStripSizing.standard.frameHeight)
        XCTAssertGreaterThan(detailSizing.stripHeight, FilmStripSizing.standard.stripHeight)
        XCTAssertGreaterThanOrEqual(detailSizing.frameWidth, 236)
        XCTAssertGreaterThanOrEqual(detailSizing.frameHeight, 312)
        XCTAssertGreaterThanOrEqual(detailSizing.stripHeight, 372)
        XCTAssertTrue(detailSizing.prefersFullSizeImages)
        XCTAssertGreaterThan(detailSizing.imageMaxPixelDimension, FilmStripSizing.standard.imageMaxPixelDimension)
        XCTAssertEqual(FilmRollDetailLayout.exportButtonPlacement, .topToolbarTrailingIcon)
    }

    func testDetailUsesFilmProjectorViewerPresentation() {
        XCTAssertEqual(FilmRollDetailLayout.presentationStyle, .filmProjectorViewer)
        XCTAssertEqual(FilmRollDetailLayout.projectionPlacement, .centerViewport)
        XCTAssertEqual(FilmRollDetailLayout.filmTransportPlacement, .bottomPinnedProjector)
        XCTAssertEqual(FilmRollDetailLayout.projectionLighting, .none)
        XCTAssertTrue(FilmRollDetailLayout.filmTransportMovesProjectionSelection)
        XCTAssertFalse(FilmRollProjectionScreenLayout.usesBackdrop)
        XCTAssertTrue(FilmRollProjectionScreenLayout.usesLargeAdaptiveContainer)
        XCTAssertFalse(FilmRollProjectionScreenLayout.usesVisibleContainerBackground)
        XCTAssertEqual(FilmRollProjectionScreenLayout.imageContentMode, .fit)
        XCTAssertFalse(FilmRollProjectionScreenLayout.showsFrameLabel)
        XCTAssertGreaterThan(
            FilmRollProjectionScreenLayout.height(
                forViewportHeight: 932,
                transportHeight: FilmRollProjectorTransportLayout.totalHeight
            ),
            FilmRollProjectionScreenLayout.containerWidth(forViewportWidth: 430)
        )
    }

    func testDetailFilmTransportMovesFilmAndSnapsWithHaptics() {
        XCTAssertEqual(FilmRollDetailFilmTransportInteraction.hapticStyle, .mediumImpact)
        XCTAssertGreaterThan(FilmRollDetailFilmTransportInteraction.hapticIntensity, 0.75)

        let frameWidths: [CGFloat] = [72, 132, 84]

        XCTAssertEqual(
            FilmRollDetailFilmTransportInteraction.contentOffset(
                selectedIndex: 2,
                dragTranslation: 15,
                frameWidths: frameWidths,
                frameSpacing: 12,
                leadingInset: 60,
                viewportCenter: 200
            ),
            -115,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FilmRollDetailFilmTransportInteraction.targetIndex(
                selectedIndex: 0,
                dragTranslation: -92,
                frameWidths: frameWidths,
                frameSpacing: 12
            ),
            1
        )
        XCTAssertEqual(
            FilmRollDetailFilmTransportInteraction.targetIndex(
                selectedIndex: 2,
                dragTranslation: 92,
                frameWidths: frameWidths,
                frameSpacing: 12
            ),
            1
        )
        XCTAssertEqual(
            FilmRollDetailFilmTransportInteraction.targetIndex(
                selectedIndex: 2,
                dragTranslation: -140,
                frameWidths: frameWidths,
                frameSpacing: 12
            ),
            2
        )
    }

    func testDetailFilmTransportSnapStartsFromReleasePositionAfterIndexChange() {
        let frameWidths: [CGFloat] = [72, 132, 84]
        let frameSpacing: CGFloat = 12
        let leadingInset: CGFloat = 60
        let viewportCenter: CGFloat = 200
        let releaseTranslation: CGFloat = -92
        let selectedIndex = 0
        let targetIndex = 1

        let releaseOffset = FilmRollDetailFilmTransportInteraction.contentOffset(
            selectedIndex: selectedIndex,
            dragTranslation: releaseTranslation,
            frameWidths: frameWidths,
            frameSpacing: frameSpacing,
            leadingInset: leadingInset,
            viewportCenter: viewportCenter
        )
        let continuityTranslation = FilmRollDetailFilmTransportInteraction.continuityDragTranslation(
            releaseTranslation: releaseTranslation,
            selectedIndex: selectedIndex,
            targetIndex: targetIndex,
            frameWidths: frameWidths,
            frameSpacing: frameSpacing
        )
        let offsetAfterIndexChange = FilmRollDetailFilmTransportInteraction.contentOffset(
            selectedIndex: targetIndex,
            dragTranslation: continuityTranslation,
            frameWidths: frameWidths,
            frameSpacing: frameSpacing,
            leadingInset: leadingInset,
            viewportCenter: viewportCenter
        )

        XCTAssertNotEqual(continuityTranslation, 0)
        XCTAssertEqual(offsetAfterIndexChange, releaseOffset, accuracy: 0.001)
    }

    func testDetailProjectorViewerUsesLayeredLightBoxWithoutSeparateMagnifiedImage() {
        XCTAssertEqual(FilmRollProjectorTransportLayout.bodyForm, .lightBoxPlate)
        XCTAssertEqual(FilmRollProjectorTransportLayout.bodyRendering, .transparentReferenceLightBoxAsset)
        XCTAssertTrue(FilmRollProjectorTransportLayout.usesTransparentBodyAsset)
        XCTAssertEqual(FilmRollProjectorTransportLayout.layeringStyle, .backFrameFilmFrontViewer)
        XCTAssertEqual(FilmRollProjectorTransportLayout.filmLayerPosition, .betweenBackFrameAndFrontViewer)
        XCTAssertFalse(FilmRollProjectorTransportLayout.rendersSeparateViewerImage)
        XCTAssertTrue(FilmRollProjectorTransportLayout.viewerImageUsesFilmFrameSize)
        XCTAssertTrue(FilmRollProjectorTransportLayout.frontViewerCoversFilm)
        XCTAssertTrue(FilmRollProjectorTransportLayout.backFrameIsCoveredByFilm)
        XCTAssertEqual(FilmRollProjectorTransportLayout.backFrameLightAssetName, "FilmLightBoxViewerBackFrame")
        XCTAssertEqual(FilmRollProjectorTransportLayout.backFrameDarkAssetName, "FilmLightBoxViewerBackFrameDark")
        XCTAssertEqual(FilmRollProjectorTransportLayout.frontViewerLightAssetName, "FilmLightBoxViewerFrontBlock")
        XCTAssertEqual(FilmRollProjectorTransportLayout.frontViewerDarkAssetName, "FilmLightBoxViewerFrontBlockDark")
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.backFrameAssetName(isDarkMode: false),
            "FilmLightBoxViewerBackFrame"
        )
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.backFrameAssetName(isDarkMode: true),
            "FilmLightBoxViewerBackFrameDark"
        )
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.frontViewerAssetName(isDarkMode: false),
            "FilmLightBoxViewerFrontBlock"
        )
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.frontViewerAssetName(isDarkMode: true),
            "FilmLightBoxViewerFrontBlockDark"
        )
        XCTAssertFalse(FilmRollProjectorTransportLayout.usesFlatRectangleBody)
        XCTAssertEqual(FilmRollProjectorTransportLayout.backFrameWidth, FilmRollProjectorTransportLayout.backFrameHeight)
        XCTAssertEqual(FilmRollProjectorTransportLayout.frontViewerWidth, FilmRollProjectorTransportLayout.frontViewerHeight)
        XCTAssertEqual(FilmRollProjectorTransportLayout.projectorWidth, 224)
        XCTAssertEqual(FilmRollProjectorTransportLayout.projectorHeight, 224)
        XCTAssertGreaterThanOrEqual(
            FilmRollProjectorTransportLayout.backFrameWidth - FilmRollProjectorTransportLayout.frontViewerWidth,
            56
        )
        XCTAssertLessThan(FilmRollProjectorTransportLayout.frontViewerWidth, FilmRollProjectorTransportLayout.backFrameWidth)
        XCTAssertEqual(FilmRollProjectorTransportLayout.viewerAssetOuterTransparentMargin, 4)
        XCTAssertEqual(FilmRollProjectorTransportLayout.viewerAssetWindowTransparentMargin, 0)
        XCTAssertTrue(FilmRollProjectorTransportLayout.viewerAssetCutoutsAreFullyTransparent)
        XCTAssertTrue(FilmRollProjectorTransportLayout.viewerAssetMaterialIsOpaque)
        XCTAssertTrue(FilmRollProjectorTransportLayout.frontViewerUsesReferenceAssetStyle)
        XCTAssertTrue(FilmRollProjectorTransportLayout.frontViewerUsesRealisticReferenceScrews)
        XCTAssertTrue(FilmRollProjectorTransportLayout.frontViewerMatchesBackFramePalette)
        XCTAssertFalse(FilmRollProjectorTransportLayout.showsAddPhotoButton)
        XCTAssertEqual(FilmRollProjectorTransportLayout.bodyStyle, .warmLightHybrid)
        XCTAssertLessThanOrEqual(FilmRollProjectorTransportLayout.projectorBorderWidth, 0.75)
        XCTAssertEqual(FilmRollProjectorTransportLayout.projectorBodyOpacity, 1)
        XCTAssertFalse(FilmRollProjectorTransportLayout.showsTopRail)
        XCTAssertFalse(FilmRollProjectorTransportLayout.showsTopTitle)
        XCTAssertTrue(FilmRollProjectorTransportLayout.showsCornerScrews)
        XCTAssertEqual(FilmRollProjectorTransportLayout.cornerScrewCount, 4)
        XCTAssertEqual(FilmRollProjectorTransportLayout.bottomLeftLabel, "LUMOROLL")
        XCTAssertEqual(FilmRollProjectorTransportLayout.bottomRightLabel, "LIGHT BOX")
        XCTAssertEqual(FilmRollProjectorTransportLayout.filmHeight, 130)
        XCTAssertGreaterThanOrEqual(FilmRollProjectorTransportLayout.filmFrameHeight, 90)
        XCTAssertEqual(FilmRollProjectorTransportLayout.projectorWindowFrameHeight, FilmRollProjectorTransportLayout.filmFrameHeight + 8)
        XCTAssertGreaterThan(FilmRollProjectorTransportLayout.projectorWindowFrameHeight, FilmRollProjectorTransportLayout.filmFrameHeight)
        XCTAssertGreaterThan(FilmRollProjectorTransportLayout.projectorWindowWidth, FilmRollProjectorTransportLayout.projectorWindowFrameHeight)
        XCTAssertLessThan(FilmRollProjectorTransportLayout.projectorWindowWidth, FilmRollProjectorTransportLayout.frontViewerWidth)
        XCTAssertLessThanOrEqual(FilmRollProjectorTransportLayout.projectorWindowPadding, 4)
        XCTAssertTrue(FilmRollProjectorTransportLayout.projectorWindowUsesFilmBlackEmptyFill)
        XCTAssertTrue(FilmRollProjectorTransportLayout.dimsFilmFrameImages)
        XCTAssertEqual(FilmRollProjectorTransportLayout.filmFrameImageDimmingOpacity, 0.65)
        XCTAssertEqual(FilmRollProjectorTransportLayout.filmFrameImageDimmingOpacity(isSelected: true), 0)
        XCTAssertEqual(FilmRollProjectorTransportLayout.filmFrameImageDimmingOpacity(isSelected: false), 0.65)
        XCTAssertGreaterThanOrEqual(
            FilmRollProjectorTransportLayout.projectorWindowFrameHeight / FilmRollProjectorTransportLayout.frontViewerHeight,
            0.55
        )
    }

    func testDetailProjectorWindowImageUsesSelectedFilmFrameBounds() {
        XCTAssertEqual(FilmRollProjectorTransportLayout.filmCenterY, 106)
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.projectorWindowFrameHeight,
            FilmRollProjectorTransportLayout.filmFrameHeight + 8
        )
        XCTAssertEqual(FilmRollProjectorTransportLayout.projectorWindowCenterOffsetY, 0)
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.projectorWindowCenterY,
            FilmRollProjectorTransportLayout.filmCenterY
        )
        XCTAssertGreaterThan(FilmRollProjectorTransportLayout.projectorWindowTopY, FilmRollProjectorTransportLayout.filmTopY)
        XCTAssertLessThan(FilmRollProjectorTransportLayout.projectorWindowBottomY, FilmRollProjectorTransportLayout.filmBottomY)
    }

    func testDetailProjectorFilmSelectionUsesLeftOpticalCorrectionUnderLayeredViewer() {
        let viewportWidth: CGFloat = 430
        let frameWidths: [CGFloat] = [142, 96, 132, 118]
        let targetCenter = FilmRollProjectorTransportLayout.filmFrameTargetCenterX(
            forViewportWidth: viewportWidth
        )

        XCTAssertEqual(FilmRollProjectorTransportLayout.filmSelectionAlignmentOffsetX, -12)
        XCTAssertLessThan(targetCenter, viewportWidth / 2)
        XCTAssertEqual(targetCenter, (viewportWidth / 2) - 12, accuracy: 0.001)
        XCTAssertEqual(
            FilmRollDetailFilmTransportInteraction.selectedFrameViewportCenterX(
                selectedIndex: 0,
                dragTranslation: 0,
                frameWidths: frameWidths,
                frameSpacing: FilmRollProjectorTransportLayout.frameSpacing,
                leadingInset: FilmRollProjectorTransportLayout.leaderLength,
                viewportWidth: viewportWidth,
                contentWidth: 600
            ),
            targetCenter,
            accuracy: 0.001
        )
    }

    func testDetailProjectorFilmContentUsesLeadingCoordinateSpaceForFrameAlignment() {
        let viewportWidth: CGFloat = 430
        let frameWidths: [CGFloat] = [124, 96, 132, 118]
        let frameSpacing = FilmRollProjectorTransportLayout.frameSpacing
        let contentWidth = FilmRollProjectorTransportLayout.leaderLength
            + frameWidths.reduce(0, +)
            + (CGFloat(frameWidths.count - 1) * frameSpacing)
            + FilmRollProjectorTransportLayout.trailerLength

        XCTAssertGreaterThan(contentWidth, viewportWidth)
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.filmStripViewportWidth(
                forVisualViewportWidth: viewportWidth,
                contentWidth: contentWidth
            ),
            viewportWidth,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.filmStripViewportLeadingX(forVisualViewportWidth: viewportWidth),
            0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FilmRollDetailFilmTransportInteraction.contentLeadingX(
                viewportWidth: viewportWidth,
                contentWidth: contentWidth
            ),
            0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FilmRollDetailFilmTransportInteraction.selectedFrameViewportCenterX(
                selectedIndex: 2,
                dragTranslation: 0,
                frameWidths: frameWidths,
                frameSpacing: frameSpacing,
                leadingInset: FilmRollProjectorTransportLayout.leaderLength,
                viewportWidth: viewportWidth,
                contentWidth: contentWidth
            ),
            FilmRollProjectorTransportLayout.filmFrameTargetCenterX(forViewportWidth: viewportWidth),
            accuracy: 0.001
        )
    }

    func testDetailProjectorFilmFramesAreNotTapTargets() {
        XCTAssertFalse(FilmRollProjectorTransportLayout.filmFramesAreTapTargets)
    }

    func testDetailProjectorFilmBodyMovesWithActualFilmContent() {
        XCTAssertTrue(FilmRollProjectorTransportLayout.filmBodyMovesWithContent)
        XCTAssertFalse(FilmRollProjectorTransportLayout.extendsFilmBodyToViewport)
    }

    func testDetailProjectorTransportViewportBleedsToScreenEdges() {
        let paddedContentWidth: CGFloat = 361

        XCTAssertTrue(FilmRollProjectorTransportLayout.usesFullScreenWidthViewport)
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.viewportHorizontalBleed,
            LumoTheme.Spacing.medium,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.viewportWidth(forContentWidth: paddedContentWidth),
            paddedContentWidth + (LumoTheme.Spacing.medium * 2),
            accuracy: 0.001
        )
    }

    func testDetailProjectorVisualViewportCancelsContentPaddingAndCentersOnScreen() {
        let paddedContentWidth: CGFloat = 361
        let contentLeadingX = LumoTheme.Spacing.medium
        let screenWidth = paddedContentWidth + (LumoTheme.Spacing.medium * 2)

        XCTAssertEqual(
            FilmRollProjectorTransportLayout.viewportLeadingOffset,
            -LumoTheme.Spacing.medium,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.viewportCenterXInContent(forContentWidth: paddedContentWidth),
            paddedContentWidth / 2,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.viewportLeadingX(
                forContentLeadingX: contentLeadingX
            ),
            0,
            accuracy: 0.001
        )
        XCTAssertEqual(
            FilmRollProjectorTransportLayout.viewportTrailingX(
                forContentLeadingX: contentLeadingX,
                contentWidth: paddedContentWidth
            ),
            screenWidth,
            accuracy: 0.001
        )
    }

    func testDetailProjectorFramesUseFixedHeightAndAspectWidth() {
        let stripFrame = FilmRollProjectorFrameLayout.frameSize(
            aspectRatio: 1.5,
            fixedHeight: FilmRollProjectorTransportLayout.filmFrameHeight
        )
        let viewerFrame = FilmRollProjectorFrameLayout.frameSize(
            aspectRatio: 1.5,
            fixedHeight: FilmRollProjectorTransportLayout.projectorWindowFrameHeight
        )

        XCTAssertEqual(stripFrame.height, FilmRollProjectorTransportLayout.filmFrameHeight)
        XCTAssertEqual(stripFrame.width, FilmRollProjectorTransportLayout.filmFrameHeight * 1.5)
        XCTAssertEqual(viewerFrame.height, FilmRollProjectorTransportLayout.projectorWindowFrameHeight)
        XCTAssertEqual(viewerFrame.width, FilmRollProjectorTransportLayout.projectorWindowFrameHeight * 1.5)
        XCTAssertGreaterThan(viewerFrame.height, stripFrame.height)
        XCTAssertGreaterThan(viewerFrame.width, stripFrame.width)
    }

    func testDetailProjectorFilmHasLeaderAndTrailer() {
        XCTAssertGreaterThan(FilmRollProjectorTransportLayout.leaderLength, 0)
        XCTAssertEqual(FilmRollProjectorTransportLayout.leaderLength, FilmRollProjectorTransportLayout.trailerLength)
    }

    func testFilmStripSprocketHolesMoveWithHorizontalContent() {
        XCTAssertEqual(FilmStripLayout.sprocketScrollBehavior, .movesWithHorizontalContent)
    }

    func testFilmStripSprocketCountIsGeneratedFromAvailableWidth() {
        let compactCount = FilmStripSprocketLayout.slotCount(
            forWidth: 240,
            sizing: .detail
        )
        let wideCount = FilmStripSprocketLayout.slotCount(
            forWidth: 840,
            sizing: .detail
        )

        XCTAssertGreaterThan(wideCount, compactCount)
        XCTAssertGreaterThanOrEqual(wideCount, 40)
    }

    func testDesignSystemDetailFilmStripUsesCompleteAspectAdaptivePhotoFrames() {
        let detailSizing = FilmStripSizing.detail

        let portraitFrame = FilmStripFrameLayout.frameSize(
            kind: .reference,
            aspectRatio: 0.6,
            sizing: detailSizing
        )
        let landscapeFrame = FilmStripFrameLayout.frameSize(
            kind: .processed,
            aspectRatio: 1.5,
            sizing: detailSizing
        )
        let addFrame = FilmStripFrameLayout.frameSize(
            kind: .addPhoto,
            aspectRatio: 3,
            sizing: detailSizing
        )

        XCTAssertEqual(portraitFrame.height, detailSizing.frameHeight)
        XCTAssertEqual(landscapeFrame.height, detailSizing.frameHeight)
        XCTAssertEqual(portraitFrame.width, detailSizing.frameHeight * 0.6)
        XCTAssertEqual(landscapeFrame.width, detailSizing.frameHeight * 1.5)
        XCTAssertEqual(addFrame.width, detailSizing.frameWidth)
        XCTAssertEqual(FilmStripFrameLayout.photoContentMode, .fit)
    }

    func testDetailDoesNotShowEmptyProcessedPhotoHintBelowStrip() {
        XCTAssertFalse(FilmRollDetailLayout.showsEmptyProcessedPhotoHint(processedPhotoCount: 0))
        XCTAssertFalse(FilmRollDetailLayout.showsEmptyProcessedPhotoHint(processedPhotoCount: 3))
    }

    func testDetailAddPhotoSourceChoiceOffersPhotoLibraryAndFiles() {
        XCTAssertEqual(FilmRollDetailAddPhotoSourceChoice.title, "Add photo")
        XCTAssertEqual(FilmRollDetailAddPhotoSourceChoice.sources, [.photoLibrary, .files])
    }

    func testDetailProjectorTransportUsesExistingPhotosOnly() throws {
        let roll = try FilmRoll(
            id: "roll-detail-layout",
            name: "Detail Layout",
            createdAt: Date(timeIntervalSince1970: 100),
            referenceAsset: FilmRollReferenceAsset(
                originalPath: "reference/original.jpg",
                thumbnailPath: "reference/thumb.jpg"
            ),
            lut: LUT3D.identity(),
            processedPhotos: [
                ProcessedPhoto(
                    id: "processed-1",
                    originalPath: "processed/original.jpg",
                    processedPath: "processed/full.jpg",
                    thumbnailPath: "processed/thumb.jpg",
                    intensity: 75
                )
            ]
        )

        let frames = FilmRollViewerFrame.frames(for: roll)

        XCTAssertEqual(frames.map(\.kind), [.reference, .processed])
        XCTAssertEqual(frames.map(\.displayLabel), ["Sample", "Frame 01"])
        XCTAssertEqual(frames.map(\.photo.id), ["roll-detail-layout-reference", "processed-1"])
        XCTAssertFalse(frames.map(\.id).contains("add-photo"))
    }
}
