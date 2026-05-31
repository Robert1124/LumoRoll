import Foundation

struct LUTExportRequest: Codable, Equatable, Sendable {
    let filmRollID: String
    let filmRollName: String
    let lut: LUT3D

    init(filmRollID: String, filmRollName: String, lut: LUT3D) {
        self.filmRollID = filmRollID
        self.filmRollName = filmRollName
        self.lut = lut
    }
}

protocol LUTExporting: Sendable {
    func exportLUT(for request: LUTExportRequest) async throws -> String
}
