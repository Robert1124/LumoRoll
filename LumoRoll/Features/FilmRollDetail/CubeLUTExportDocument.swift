import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let lumoCube = UTType(filenameExtension: "cube", conformingTo: .plainText)
        ?? UTType(importedAs: "com.lumoroll.cube", conformingTo: .plainText)
}

struct CubeLUTExportDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [.lumoCube, .plainText]
    }

    static var writableContentTypes: [UTType] {
        [.lumoCube]
    }

    let suggestedFilename: String
    private let cubeText: String

    init(exportResult: ExportLUTResult) {
        suggestedFilename = exportResult.suggestedFilename
        cubeText = exportResult.cubeText
    }

    init(configuration: ReadConfiguration) throws {
        let data = configuration.file.regularFileContents ?? Data()
        suggestedFilename = "Film-Roll.cube"
        cubeText = String(data: data, encoding: .utf8) ?? ""
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        makeFileWrapper()
    }

    func makeFileWrapper() -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(cubeText.utf8))
    }
}
