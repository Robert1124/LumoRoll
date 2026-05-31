import Foundation
import Observation

@MainActor
@Observable
final class ApplyPhotoFeatureModel {
    enum PreviewMode: Equatable {
        case before
        case split
        case after
    }

    enum SaveState: Equatable {
        case idle
        case saving
        case saved(FilmRoll)
        case failed(String)
    }

    enum SaveToPhotosState: Equatable {
        case idle
        case saving
        case saved(String)
        case failed(String)
    }

    enum PreviewState: Equatable {
        case idle
        case rendering(previousPath: String?)
        case ready(path: String)
        case failed(message: String, previousPath: String?)

        var displayPath: String? {
            switch self {
            case .idle:
                nil
            case .rendering(let previousPath):
                previousPath
            case .ready(let path):
                path
            case .failed(_, let previousPath):
                previousPath
            }
        }
    }

    let filmRollID: String
    @ObservationIgnored
    private let applyFilmRollUseCase: ApplyFilmRollUseCase
    @ObservationIgnored
    private let saveAppliedPhotoToPhotosUseCase: SaveAppliedPhotoToPhotosUseCase
    @ObservationIgnored
    private let renderApplyPreviewUseCase: RenderApplyPreviewUseCase
    @ObservationIgnored
    private let editContext: ApplyPhotoEditContext?
    @ObservationIgnored
    private var targetSelectionVersion = 0
    @ObservationIgnored
    private var previewRenderVersion = 0

    private(set) var selectedTargetPhotoPath: String?
    private var clampedIntensity: Double = 100
    var intensity: Double {
        get {
            clampedIntensity
        }
        set {
            clampedIntensity = newValue.clampedToLumoPercentage
        }
    }
    var isAdaptivePostProcessEnabled = true
    var isUsingAlgorithmV2DiagnosticLUT = false
    var previewMode: PreviewMode = .split
    private(set) var previewState: PreviewState = .idle
    private(set) var saveState: SaveState = .idle
    private(set) var saveToPhotosState: SaveToPhotosState = .idle

    var canSaveToFilmRoll: Bool {
        selectedTargetPhotoPath != nil
    }

    var isSaving: Bool {
        saveState == .saving || saveToPhotosState == .saving
    }

    var isEditingExistingProcessedPhoto: Bool {
        editContext != nil
    }

    var renderedPreviewPhotoPath: String? {
        previewState.displayPath
    }

    init(
        filmRollID: String,
        initialTargetPhotoPath: String? = nil,
        editContext: ApplyPhotoEditContext? = nil,
        applyFilmRollUseCase: ApplyFilmRollUseCase,
        saveAppliedPhotoToPhotosUseCase: SaveAppliedPhotoToPhotosUseCase,
        renderApplyPreviewUseCase: RenderApplyPreviewUseCase
    ) {
        self.filmRollID = filmRollID
        self.editContext = editContext
        self.applyFilmRollUseCase = applyFilmRollUseCase
        self.saveAppliedPhotoToPhotosUseCase = saveAppliedPhotoToPhotosUseCase
        self.renderApplyPreviewUseCase = renderApplyPreviewUseCase
        selectedTargetPhotoPath = editContext?.originalPhotoPath ?? initialTargetPhotoPath
        clampedIntensity = editContext?.intensity.clampedToLumoPercentage ?? 100
    }

    func selectTargetPhoto(path: String) {
        guard !isSaving else {
            return
        }
        if selectedTargetPhotoPath != path {
            targetSelectionVersion += 1
            previewRenderVersion += 1
            discardPreviewIfNeeded(previewState.displayPath)
            previewState = .idle
            saveState = .idle
            saveToPhotosState = .idle
        }
        selectedTargetPhotoPath = path
    }

    func renderPreview(maxPixelDimension: Int = 1_200) async {
        guard let operationTargetPath = selectedTargetPhotoPath else {
            previewRenderVersion += 1
            previewState = .idle
            return
        }

        previewRenderVersion += 1
        let operationPreviewVersion = previewRenderVersion
        let operationTargetVersion = targetSelectionVersion
        let operationIntensity = intensity
        let operationAdaptivePostProcessEnabled = isAdaptivePostProcessEnabled
        let operationLUTSourceMode = currentLUTSourceMode
        let previousPath = previewState.displayPath
        previewState = .rendering(previousPath: previousPath)

        do {
            let result = try await renderApplyPreviewUseCase.renderPreview(
                input: RenderApplyPreviewInput(
                    filmRollID: filmRollID,
                    originalPhotoPath: operationTargetPath,
                    intensity: operationIntensity,
                    maxPixelDimension: maxPixelDimension,
                    isAdaptivePostProcessEnabled: operationAdaptivePostProcessEnabled,
                    lutSourceMode: operationLUTSourceMode
                )
            )
            guard isCurrentPreviewResult(
                previewVersion: operationPreviewVersion,
                targetVersion: operationTargetVersion,
                targetPath: operationTargetPath,
                intensity: operationIntensity,
                isAdaptivePostProcessEnabled: operationAdaptivePostProcessEnabled,
                lutSourceMode: operationLUTSourceMode
            ) else {
                await renderApplyPreviewUseCase.discardPreview(path: result.previewPath)
                return
            }

            if let previousPath, previousPath != result.previewPath {
                await renderApplyPreviewUseCase.discardPreview(path: previousPath)
            }
            previewState = .ready(path: result.previewPath)
        } catch {
            guard isCurrentPreviewResult(
                previewVersion: operationPreviewVersion,
                targetVersion: operationTargetVersion,
                targetPath: operationTargetPath,
                intensity: operationIntensity,
                isAdaptivePostProcessEnabled: operationAdaptivePostProcessEnabled,
                lutSourceMode: operationLUTSourceMode
            ) else {
                return
            }
            previewState = .failed(message: featureErrorMessage(error), previousPath: previousPath)
        }
    }

    func discardPreview() async {
        previewRenderVersion += 1
        let path = previewState.displayPath
        previewState = .idle
        if let path {
            await renderApplyPreviewUseCase.discardPreview(path: path)
        }
    }

    func saveToFilmRoll() async {
        guard !isSaving else {
            return
        }
        guard let selectedTargetPhotoPath else {
            saveState = .failed(featureErrorMessage(LumoError.importFailed))
            return
        }

        let operationTargetVersion = targetSelectionVersion
        let operationTargetPath = selectedTargetPhotoPath
        let operationIntensity = intensity
        let operationAdaptivePostProcessEnabled = isAdaptivePostProcessEnabled
        let operationLUTSourceMode = currentLUTSourceMode
        saveState = .saving
        do {
            let roll = try await applyFilmRollUseCase.applyPhoto(
                input: ApplyFilmRollInput(
                    filmRollID: filmRollID,
                    originalPhotoPath: operationTargetPath,
                    intensity: operationIntensity,
                    replacingProcessedPhotoID: editContext?.processedPhotoID,
                    isAdaptivePostProcessEnabled: operationAdaptivePostProcessEnabled,
                    lutSourceMode: operationLUTSourceMode
                )
            )
            guard operationTargetVersion == targetSelectionVersion,
                  selectedTargetPhotoPath == operationTargetPath else {
                return
            }
            saveState = .saved(roll)
        } catch {
            guard operationTargetVersion == targetSelectionVersion,
                  selectedTargetPhotoPath == operationTargetPath else {
                return
            }
            saveState = .failed(featureErrorMessage(error))
        }
    }

    func saveToPhotos() async {
        guard !isSaving else {
            return
        }
        guard let selectedTargetPhotoPath else {
            saveToPhotosState = .failed(featureErrorMessage(LumoError.importFailed))
            return
        }

        let operationTargetVersion = targetSelectionVersion
        let operationTargetPath = selectedTargetPhotoPath
        let operationIntensity = intensity
        let operationAdaptivePostProcessEnabled = isAdaptivePostProcessEnabled
        let operationLUTSourceMode = currentLUTSourceMode
        saveToPhotosState = .saving
        do {
            let result = try await saveAppliedPhotoToPhotosUseCase.saveToPhotos(
                input: SaveAppliedPhotoToPhotosInput(
                    filmRollID: filmRollID,
                    originalPhotoPath: operationTargetPath,
                    intensity: operationIntensity,
                    isAdaptivePostProcessEnabled: operationAdaptivePostProcessEnabled,
                    lutSourceMode: operationLUTSourceMode
                )
            )
            guard operationTargetVersion == targetSelectionVersion,
                  self.selectedTargetPhotoPath == operationTargetPath else {
                return
            }
            saveToPhotosState = .saved(result.localIdentifier)
        } catch {
            guard operationTargetVersion == targetSelectionVersion,
                  self.selectedTargetPhotoPath == operationTargetPath else {
                return
            }
            saveToPhotosState = .failed(featureErrorMessage(error))
        }
    }

    private func isCurrentPreviewResult(
        previewVersion: Int,
        targetVersion: Int,
        targetPath: String,
        intensity: Double,
        isAdaptivePostProcessEnabled: Bool,
        lutSourceMode: ApplyLUTSourceMode
    ) -> Bool {
        previewVersion == previewRenderVersion
            && targetVersion == targetSelectionVersion
            && selectedTargetPhotoPath == targetPath
            && self.intensity == intensity
            && self.isAdaptivePostProcessEnabled == isAdaptivePostProcessEnabled
            && currentLUTSourceMode == lutSourceMode
    }

    private var currentLUTSourceMode: ApplyLUTSourceMode {
        isUsingAlgorithmV2DiagnosticLUT ? .algorithmV2 : .saved
    }

    private func discardPreviewIfNeeded(_ path: String?) {
        guard let path else {
            return
        }
        let renderApplyPreviewUseCase = renderApplyPreviewUseCase
        Task {
            await renderApplyPreviewUseCase.discardPreview(path: path)
        }
    }
}

private func featureErrorMessage(_ error: Error) -> String {
    if let message = (error as? LocalizedError)?.errorDescription {
        return message
    }
    return error.localizedDescription
}
