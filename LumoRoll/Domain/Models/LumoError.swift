import Foundation

enum LumoError: Error, Equatable, Sendable {
    case invalidFilmRollName
    case invalidLUTSize(Int)
    case invalidLUTSampleCount(expected: Int, actual: Int)
    case invalidLUTValue(index: Int)
    case invalidCubeLUT(message: String)
    case missingReferenceAsset
    case filmRollNotFound(id: String)
    case storageFailed(message: String)
    case importFailed
    case renderFailed
    case saveFailed
    case processedPhotoNotFound(id: String)
    case photosPermissionDenied
    case exportFailed
}

extension LumoError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidFilmRollName:
            "Film Roll name cannot be empty."
        case .invalidLUTSize(let size):
            "Unsupported LUT size: \(size)."
        case .invalidLUTSampleCount(let expected, let actual):
            "Invalid LUT value count. Expected \(expected), got \(actual)."
        case .invalidLUTValue(let index):
            "Invalid LUT value at index \(index)."
        case .invalidCubeLUT(let message):
            "Invalid .cube LUT: \(message)"
        case .missingReferenceAsset:
            "Reference image is missing."
        case .filmRollNotFound(let id):
            "Film Roll not found: \(id)."
        case .storageFailed(let message):
            "Storage failed: \(message)"
        case .importFailed:
            "Photo import failed."
        case .renderFailed:
            "Photo rendering failed."
        case .saveFailed:
            "Save failed."
        case .processedPhotoNotFound(let id):
            "Processed photo not found: \(id)."
        case .photosPermissionDenied:
            "Photos access is needed to save images to your library."
        case .exportFailed:
            "Export failed."
        }
    }
}
