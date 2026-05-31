import Foundation
import Observation

@MainActor
@Observable
final class FilmRollDetailFeatureModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(FilmRoll)
        case failed(String)
    }

    enum ExportState: Equatable {
        case idle
        case exporting
        case ready(ExportLUTResult)
        case failed(String)
    }

    enum ManagementState: Equatable {
        case idle
        case renaming
        case removing
    }

    enum Intent: Equatable {
        case applyPhoto(filmRollID: String)
        case importPhoto(filmRollID: String, source: ApplyTargetImportSource)
        case removedFilmRoll(filmRollID: String)
    }

    let filmRollID: String
    @ObservationIgnored
    private let repository: FilmRollRepository
    @ObservationIgnored
    private let exportLUTUseCase: ExportLUTUseCase
    @ObservationIgnored
    private let now: () -> Date

    private(set) var state: State = .idle
    private(set) var exportState: ExportState = .idle
    private(set) var managementState: ManagementState = .idle
    private(set) var lastErrorMessage: String?
    private(set) var pendingIntent: Intent?

    init(
        filmRollID: String,
        repository: FilmRollRepository,
        exportLUTUseCase: ExportLUTUseCase,
        now: @escaping () -> Date = Date.init
    ) {
        self.filmRollID = filmRollID
        self.repository = repository
        self.exportLUTUseCase = exportLUTUseCase
        self.now = now
    }

    func load() async {
        guard state != .loading else {
            return
        }
        let previousState = state
        state = .loading
        do {
            state = .loaded(try await repository.loadFilmRoll(id: filmRollID))
            lastErrorMessage = nil
        } catch {
            let message = featureErrorMessage(error)
            if case .loaded = previousState {
                state = previousState
                lastErrorMessage = message
            } else {
                state = .failed(message)
            }
        }
    }

    func reload() async {
        await load()
    }

    func exportLUT() async {
        guard exportState != .exporting else {
            return
        }
        exportState = .exporting
        do {
            exportState = .ready(try await exportLUTUseCase.exportLUT(input: ExportLUTInput(filmRollID: filmRollID)))
        } catch {
            exportState = .failed(featureErrorMessage(error))
        }
    }

    func clearPreparedExport() {
        guard case .ready = exportState else {
            return
        }
        exportState = .idle
    }

    func requestApplyPhoto() {
        pendingIntent = .applyPhoto(filmRollID: filmRollID)
    }

    func requestImportPhoto(source: ApplyTargetImportSource) {
        pendingIntent = .importPhoto(filmRollID: filmRollID, source: source)
    }

    func renameFilmRoll(to newName: String) async {
        guard managementState == .idle else {
            return
        }

        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            lastErrorMessage = featureErrorMessage(LumoError.invalidFilmRollName)
            return
        }

        managementState = .renaming
        do {
            var roll: FilmRoll
            if case .loaded(let loadedRoll) = state {
                roll = loadedRoll
            } else {
                roll = try await repository.loadFilmRoll(id: filmRollID)
            }
            roll.name = trimmedName
            roll.updatedAt = now()
            try await repository.saveFilmRoll(roll)
            state = .loaded(roll)
            lastErrorMessage = nil
            managementState = .idle
        } catch {
            lastErrorMessage = featureErrorMessage(error)
            managementState = .idle
        }
    }

    func removeFilmRoll() async {
        guard managementState == .idle else {
            return
        }

        managementState = .removing
        do {
            try await repository.deleteFilmRoll(id: filmRollID)
            pendingIntent = .removedFilmRoll(filmRollID: filmRollID)
            lastErrorMessage = nil
            managementState = .idle
        } catch {
            lastErrorMessage = featureErrorMessage(error)
            managementState = .idle
        }
    }

    func clearPendingIntent() {
        pendingIntent = nil
    }
}

private func featureErrorMessage(_ error: Error) -> String {
    if let message = (error as? LocalizedError)?.errorDescription {
        return message
    }
    return error.localizedDescription
}
