import Foundation
import Observation

@MainActor
@Observable
final class LibraryFeatureModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded([FilmRoll])
        case failed(String)
    }

    enum Intent: Equatable {
        case createFilmRoll
        case openFilmRoll(id: String)
    }

    @ObservationIgnored
    private let repository: FilmRollRepository

    private(set) var state: State = .idle
    private(set) var lastErrorMessage: String?
    private(set) var pendingIntent: Intent?

    init(repository: FilmRollRepository) {
        self.repository = repository
    }

    func load() async {
        guard state != .loading else {
            return
        }
        let previousState = state
        state = .loading
        do {
            state = .loaded(try await repository.loadFilmRolls())
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

    func requestCreate() {
        pendingIntent = .createFilmRoll
    }

    func requestOpenFilmRoll(id: String) {
        pendingIntent = .openFilmRoll(id: id)
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
