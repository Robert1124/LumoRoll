import Foundation
import os
import Photos

enum PhotoLibraryAuthorizationStatus: Sendable {
    case notDetermined
    case authorized
    case limited
    case denied
    case restricted
}

protocol PhotoLibraryClient: Sendable {
    func authorizationStatus() async -> PhotoLibraryAuthorizationStatus
    func requestAddOnlyAuthorization() async -> PhotoLibraryAuthorizationStatus
    func createAsset(from fileURL: URL) async throws -> String
}

struct PhotoKitPhotoLibraryWriter: PhotoLibraryWriting {
    private let resolver: AppAssetURLResolver
    private let client: PhotoLibraryClient
    private let fileExists: @Sendable (String) -> Bool

    init(
        resolver: AppAssetURLResolver,
        client: PhotoLibraryClient = PhotoKitPhotoLibraryClient(),
        fileExists: @escaping @Sendable (String) -> Bool = { FileManager.default.fileExists(atPath: $0) }
    ) {
        self.resolver = resolver
        self.client = client
        self.fileExists = fileExists
    }

    func savePhotoToLibrary(processedPath: String) async throws -> String {
        let fileURL = try resolver.resolve(processedPath)
        guard fileExists(fileURL.path) else {
            throw LumoError.storageFailed(message: "Rendered photo is missing.")
        }

        let status = await effectiveAuthorizationStatus()
        guard status == .authorized || status == .limited else {
            throw LumoError.photosPermissionDenied
        }

        do {
            return try await client.createAsset(from: fileURL)
        } catch let error as CancellationError {
            throw error
        } catch let error as LumoError {
            throw error
        } catch {
            throw LumoError.saveFailed
        }
    }

    private func effectiveAuthorizationStatus() async -> PhotoLibraryAuthorizationStatus {
        let status = await client.authorizationStatus()
        guard status == .notDetermined else {
            return status
        }
        return await client.requestAddOnlyAuthorization()
    }
}

private struct PhotoKitPhotoLibraryClient: PhotoLibraryClient {
    func authorizationStatus() async -> PhotoLibraryAuthorizationStatus {
        PhotoLibraryAuthorizationStatus(PHPhotoLibrary.authorizationStatus(for: .addOnly))
    }

    func requestAddOnlyAuthorization() async -> PhotoLibraryAuthorizationStatus {
        await withCheckedContinuation { continuation in
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                continuation.resume(returning: PhotoLibraryAuthorizationStatus(status))
            }
        }
    }

    func createAsset(from fileURL: URL) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let placeholderIdentifier = OSAllocatedUnfairLock<String?>(initialState: nil)
            PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
                let localIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
                placeholderIdentifier.withLock {
                    $0 = localIdentifier
                }
            } completionHandler: { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if success, let createdAssetIdentifier = placeholderIdentifier.withLock({ $0 }) {
                    continuation.resume(returning: createdAssetIdentifier)
                } else {
                    continuation.resume(throwing: LumoError.saveFailed)
                }
            }
        }
    }
}

private extension PhotoLibraryAuthorizationStatus {
    init(_ status: PHAuthorizationStatus) {
        switch status {
        case .notDetermined:
            self = .notDetermined
        case .authorized:
            self = .authorized
        case .limited:
            self = .limited
        case .denied:
            self = .denied
        case .restricted:
            self = .restricted
        @unknown default:
            self = .denied
        }
    }
}
