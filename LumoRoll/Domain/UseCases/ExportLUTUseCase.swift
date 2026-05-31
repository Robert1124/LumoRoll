import Foundation

struct ExportLUTInput: Equatable, Sendable {
    let filmRollID: String

    init(filmRollID: String) {
        self.filmRollID = filmRollID
    }
}

struct ExportLUTResult: Equatable, Sendable {
    let suggestedFilename: String
    let cubeText: String
    let fileURL: URL
}

struct ExportLUTUseCase: Sendable {
    private static let maxSuggestedFilenameBaseLength = 80

    private let repository: FilmRollRepository
    private let lutExporter: LUTExporting
    private let assetWriter: FilmRollAssetWriting

    init(repository: FilmRollRepository, lutExporter: LUTExporting, assetWriter: FilmRollAssetWriting) {
        self.repository = repository
        self.lutExporter = lutExporter
        self.assetWriter = assetWriter
    }

    func exportLUT(input: ExportLUTInput) async throws -> ExportLUTResult {
        let roll = try await repository.loadFilmRoll(id: input.filmRollID)
        let cubeText = try await lutExporter.exportLUT(
            for: LUTExportRequest(filmRollID: roll.id, filmRollName: roll.name, lut: roll.lut)
        )
        let suggestedFilename = Self.safeCubeFilename(from: roll.name)
        let fileURL = try await assetWriter.writeCubeExport(
            filmRollID: roll.id,
            cubeText: cubeText,
            suggestedFilename: suggestedFilename
        )

        return ExportLUTResult(suggestedFilename: suggestedFilename, cubeText: cubeText, fileURL: fileURL)
    }

    private static func safeCubeFilename(from rollName: String) -> String {
        var filename = ""
        var previousWasSeparator = false

        for scalar in rollName.unicodeScalars {
            if Self.isASCIILetterOrDigit(scalar) {
                filename.unicodeScalars.append(scalar)
                previousWasSeparator = false
            } else if !previousWasSeparator, !filename.isEmpty {
                filename.append("-")
                previousWasSeparator = true
            }
        }

        filename = filename.trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        if filename.isEmpty {
            filename = "Film-Roll"
        }
        if filename.count > maxSuggestedFilenameBaseLength {
            filename = String(filename.prefix(maxSuggestedFilenameBaseLength))
                .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
        }
        if filename.isEmpty {
            filename = "Film-Roll"
        }
        return "\(filename).cube"
    }

    private static func isASCIILetterOrDigit(_ scalar: UnicodeScalar) -> Bool {
        (65...90).contains(scalar.value)
            || (97...122).contains(scalar.value)
            || (48...57).contains(scalar.value)
    }
}
