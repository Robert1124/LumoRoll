import Foundation

protocol FilmRollRepository: Sendable {
    func loadFilmRolls() async throws -> [FilmRoll]
    func loadFilmRoll(id: String) async throws -> FilmRoll
    func saveFilmRoll(_ filmRoll: FilmRoll) async throws
    func deleteFilmRoll(id: String) async throws
}
