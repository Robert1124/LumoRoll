import Foundation

struct FilmRollManifest: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let filmRoll: FilmRoll

    init(schemaVersion: Int = Self.currentSchemaVersion, filmRoll: FilmRoll) {
        self.schemaVersion = schemaVersion
        self.filmRoll = filmRoll
    }
}
