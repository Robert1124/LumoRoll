import Foundation
import Observation

@MainActor
@Observable
final class CreateFilmRollFeatureModel {
    enum Phase: Equatable {
        case idle
        case importing
        case processing
        case naming
        case saving
        case complete(FilmRoll)
        case failed(String)
    }

    @ObservationIgnored
    private let createFilmRollUseCase: CreateFilmRollUseCase
    @ObservationIgnored
    private var draftVersion = 0

    var draftName = ""
    private(set) var selectedReferenceImageData: Data?
    private(set) var preferredFileExtension: String?
    private(set) var selectedCubeLUTData: Data?
    private(set) var selectedCubeOriginalFilename: String?
    private(set) var phase: Phase = .idle
    private(set) var savedFilmRoll: FilmRoll?

    var canSave: Bool {
        !draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (selectedReferenceImageData != nil || selectedCubeLUTData != nil)
    }

    init(createFilmRollUseCase: CreateFilmRollUseCase) {
        self.createFilmRollUseCase = createFilmRollUseCase
    }

    func beginImport() {
        draftVersion += 1
        selectedReferenceImageData = nil
        preferredFileExtension = nil
        selectedCubeLUTData = nil
        selectedCubeOriginalFilename = nil
        savedFilmRoll = nil
        phase = .importing
    }

    func selectReferenceImage(data: Data, preferredFileExtension: String?) {
        draftVersion += 1
        savedFilmRoll = nil
        selectedReferenceImageData = data
        self.preferredFileExtension = preferredFileExtension
        selectedCubeLUTData = nil
        selectedCubeOriginalFilename = nil
        phase = .naming
    }

    func selectCubeLUT(data: Data, originalFilename: String?) {
        draftVersion += 1
        savedFilmRoll = nil
        selectedReferenceImageData = nil
        preferredFileExtension = nil
        selectedCubeLUTData = data
        selectedCubeOriginalFilename = originalFilename
        phase = .naming
    }

    func save() async {
        guard phase != .processing && phase != .saving else {
            return
        }

        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            phase = .failed(featureErrorMessage(LumoError.invalidFilmRollName))
            return
        }
        let input: CreateFilmRollInput
        if let selectedReferenceImageData {
            input = CreateFilmRollInput(
                name: trimmedName,
                referenceImageData: selectedReferenceImageData,
                preferredFileExtension: preferredFileExtension
            )
        } else if let selectedCubeLUTData {
            input = CreateFilmRollInput(
                name: trimmedName,
                cubeLUTData: selectedCubeLUTData,
                originalFilename: selectedCubeOriginalFilename
            )
        } else {
            phase = .failed(featureErrorMessage(LumoError.missingReferenceAsset))
            return
        }

        let operationDraftVersion = draftVersion
        phase = .processing
        phase = .saving
        do {
            let roll = try await createFilmRollUseCase.createFilmRoll(input: input)
            guard operationDraftVersion == draftVersion else {
                return
            }
            savedFilmRoll = roll
            phase = .complete(roll)
        } catch {
            guard operationDraftVersion == draftVersion else {
                return
            }
            phase = .failed(featureErrorMessage(error))
        }
    }
}

private func featureErrorMessage(_ error: Error) -> String {
    if let message = (error as? LocalizedError)?.errorDescription {
        return message
    }
    return error.localizedDescription
}
