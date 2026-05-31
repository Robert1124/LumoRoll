import XCTest
@testable import LumoRoll

final class ApplyPhotoImportFlowTests: XCTestCase {
    func testBottomActionsOnlyShowSaveAndCancelAfterTargetImport() {
        XCTAssertFalse(ApplyBottomActionsVisibility.shouldShowActions(selectedTargetPhotoPath: nil))
        XCTAssertFalse(ApplyBottomActionsVisibility.shouldShowActions(selectedTargetPhotoPath: ""))
        XCTAssertTrue(
            ApplyBottomActionsVisibility.shouldShowActions(
                selectedTargetPhotoPath: "tmp/imports/target/original.jpg"
            )
        )
        XCTAssertEqual(ApplyBottomActionCopy.saveTitle, "Save")
        XCTAssertEqual(ApplyBottomActionCopy.cancelTitle, "Cancel")
    }

    func testTemporaryPostAndLUTDiagnosticButtonsAreHidden() {
        XCTAssertFalse(ApplyDiagnosticControlsVisibility.showsTemporaryPostAndLUTButtons)
    }

    func testImportFirstApplyFlowShowsPreviewChromeOnlyAfterTargetImport() {
        XCTAssertFalse(ApplyPreviewChromeVisibility.shouldShowPreviewChrome(selectedTargetPhotoPath: nil))
        XCTAssertFalse(ApplyPreviewChromeVisibility.shouldShowPreviewChrome(selectedTargetPhotoPath: ""))
        XCTAssertTrue(
            ApplyPreviewChromeVisibility.shouldShowPreviewChrome(
                selectedTargetPhotoPath: "tmp/imports/target/original.jpg"
            )
        )

        XCTAssertTrue(ApplyImportControlsVisibility.shouldShowImportControls(selectedTargetPhotoPath: nil))
        XCTAssertTrue(ApplyImportControlsVisibility.shouldShowImportControls(selectedTargetPhotoPath: ""))
        XCTAssertFalse(
            ApplyImportControlsVisibility.shouldShowImportControls(
                selectedTargetPhotoPath: "tmp/imports/target/original.jpg"
            )
        )
    }

    func testImportSourceChoiceOffersPhotoLibraryAndFiles() {
        XCTAssertEqual(ApplyTargetImportSource.allCases, [.photoLibrary, .files])
        XCTAssertEqual(ApplyTargetImportSource.allCases.map(\.label), ["Photo Library", "Files"])
        XCTAssertEqual(ApplyTargetImportSource.photoLibrary.presentation, .photosPicker)
        XCTAssertEqual(ApplyTargetImportSource.files.presentation, .fileImporter)
    }

    func testInitialImportSourceCanOpenExistingApplyImportPresentationDirectly() {
        XCTAssertNil(ApplyInitialImportPresentationDecision.presentation(initialImportSource: nil))
        XCTAssertEqual(
            ApplyInitialImportPresentationDecision.presentation(initialImportSource: .photoLibrary),
            .photosPicker
        )
        XCTAssertEqual(
            ApplyInitialImportPresentationDecision.presentation(initialImportSource: .files),
            .fileImporter
        )
    }

    func testTargetSelectionDoesNotAutosaveBeforeUserConfirms() {
        XCTAssertEqual(
            ApplyTargetImportSaveDecision.actionsAfterSelectingTarget(
                selectedTargetPhotoPath: "tmp/imports/target/original.jpg",
                isSaving: false
            ),
            ApplyTargetImportSaveActions(saveToFilmRoll: false, saveToPhotos: false)
        )

        XCTAssertEqual(
            ApplyTargetImportSaveDecision.actionsAfterSelectingTarget(
                selectedTargetPhotoPath: nil,
                isSaving: false
            ),
            ApplyTargetImportSaveActions(saveToFilmRoll: false, saveToPhotos: false)
        )

        XCTAssertEqual(
            ApplyTargetImportSaveDecision.actionsAfterSelectingTarget(
                selectedTargetPhotoPath: "",
                isSaving: false
            ),
            ApplyTargetImportSaveActions(saveToFilmRoll: false, saveToPhotos: false)
        )

        XCTAssertEqual(
            ApplyTargetImportSaveDecision.actionsAfterSelectingTarget(
                selectedTargetPhotoPath: "tmp/imports/target/original.jpg",
                isSaving: true
            ),
            ApplyTargetImportSaveActions(saveToFilmRoll: false, saveToPhotos: false)
        )
    }
}
