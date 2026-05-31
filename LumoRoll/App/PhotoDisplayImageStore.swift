import Foundation
import Observation
import SwiftUI
import UIKit

@MainActor
@Observable
final class PhotoDisplayImageStore {
    typealias Loader = @Sendable (_ relativePath: String, _ maxPixelDimension: Int) async throws -> LocalPhotoDisplayImage

    struct DisplayImage {
        let image: Image
        let pixelWidth: Int
        let pixelHeight: Int

        var aspectRatio: CGFloat? {
            guard pixelWidth > 0,
                  pixelHeight > 0 else {
                return nil
            }

            return CGFloat(pixelWidth) / CGFloat(pixelHeight)
        }
    }

    struct Key: Hashable, Sendable {
        let relativePath: String
        let maxPixelDimension: Int
    }

    @ObservationIgnored
    private let loadDisplayImage: Loader
    @ObservationIgnored
    private let loadRegistry = PhotoDisplayImageLoadRegistry()
    @ObservationIgnored
    private var cache: [Key: DisplayImage] = [:]
    private var loadedKeys: Set<Key> = []
    private var failures: [Key: String] = [:]

    init(loadDisplayImage: @escaping Loader) {
        self.loadDisplayImage = loadDisplayImage
    }

    static let preview = PhotoDisplayImageStore { _, _ in
        throw LumoError.importFailed
    }

    convenience init(loader: LocalPhotoImageLoader) {
        self.init(loadDisplayImage: loader.loadDisplayImage(relativePath:maxPixelDimension:))
    }

    func image(relativePath: String?, maxPixelDimension: Int) -> Image? {
        guard let key = key(relativePath: relativePath, maxPixelDimension: maxPixelDimension) else {
            return nil
        }
        guard loadedKeys.contains(key) else {
            return nil
        }
        return cache[key]?.image
    }

    func aspectRatio(relativePath: String?, maxPixelDimension: Int) -> CGFloat? {
        guard let key = key(relativePath: relativePath, maxPixelDimension: maxPixelDimension),
              loadedKeys.contains(key) else {
            return nil
        }

        return cache[key]?.aspectRatio
    }

    func errorMessage(relativePath: String?, maxPixelDimension: Int) -> String? {
        guard let key = key(relativePath: relativePath, maxPixelDimension: maxPixelDimension) else {
            return nil
        }
        return failures[key]
    }

    func load(relativePath: String?, maxPixelDimension: Int) async {
        guard let key = key(relativePath: relativePath, maxPixelDimension: maxPixelDimension),
              cache[key] == nil else {
            return
        }

        let loadDisplayImage = loadDisplayImage
        let inFlightLoad = await loadRegistry.load(for: key) {
            Task {
                try await loadDisplayImage(key.relativePath, key.maxPixelDimension)
            }
        }

        await finishLoad(key: key, inFlightLoad: inFlightLoad)
    }

    private func finishLoad(key: Key, inFlightLoad: PhotoDisplayImageLoadRegistry.InFlightLoad) async {
        do {
            let displayImage = try await inFlightLoad.task.value
            guard !Task.isCancelled else {
                await loadRegistry.clear(key: key, loadID: inFlightLoad.id)
                return
            }
            if let uiImage = UIImage(data: displayImage.data) {
                cache[key] = DisplayImage(
                    image: Image(uiImage: uiImage),
                    pixelWidth: displayImage.pixelWidth,
                    pixelHeight: displayImage.pixelHeight
                )
                loadedKeys.insert(key)
                failures[key] = nil
            } else {
                loadedKeys.remove(key)
                failures[key] = featureErrorMessage(LumoError.importFailed)
            }
        } catch is CancellationError {
            await loadRegistry.clear(key: key, loadID: inFlightLoad.id)
            return
        } catch {
            loadedKeys.remove(key)
            failures[key] = featureErrorMessage(error)
        }
        await loadRegistry.clear(key: key, loadID: inFlightLoad.id)
    }

    private func key(relativePath: String?, maxPixelDimension: Int) -> Key? {
        guard let relativePath,
              !relativePath.isEmpty,
              maxPixelDimension > 0 else {
            return nil
        }
        return Key(relativePath: relativePath, maxPixelDimension: maxPixelDimension)
    }
}

private actor PhotoDisplayImageLoadRegistry {
    struct InFlightLoad: Sendable {
        let id: UUID
        let task: Task<LocalPhotoDisplayImage, Error>
    }

    private var inFlightLoads: [PhotoDisplayImageStore.Key: InFlightLoad] = [:]

    func load(
        for key: PhotoDisplayImageStore.Key,
        createTask: @Sendable () -> Task<LocalPhotoDisplayImage, Error>
    ) -> InFlightLoad {
        if let inFlightLoad = inFlightLoads[key] {
            return inFlightLoad
        }

        let inFlightLoad = InFlightLoad(id: UUID(), task: createTask())
        inFlightLoads[key] = inFlightLoad
        return inFlightLoad
    }

    func clear(key: PhotoDisplayImageStore.Key, loadID: UUID) {
        guard inFlightLoads[key]?.id == loadID else {
            return
        }
        inFlightLoads[key] = nil
    }
}

struct PhotoDisplayImageView<Placeholder: View>: View {
    let store: PhotoDisplayImageStore
    let relativePath: String?
    let maxPixelDimension: Int
    var contentMode: ContentMode = .fill
    let placeholder: Placeholder

    init(
        store: PhotoDisplayImageStore,
        relativePath: String?,
        maxPixelDimension: Int,
        contentMode: ContentMode = .fill,
        @ViewBuilder placeholder: () -> Placeholder
    ) {
        self.store = store
        self.relativePath = relativePath
        self.maxPixelDimension = maxPixelDimension
        self.contentMode = contentMode
        self.placeholder = placeholder()
    }

    var body: some View {
        Group {
            if let image = store.image(relativePath: relativePath, maxPixelDimension: maxPixelDimension) {
                image
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else {
                placeholder
            }
        }
        .task(id: loadID) {
            await store.load(relativePath: relativePath, maxPixelDimension: maxPixelDimension)
        }
    }

    private var loadID: String {
        "\(relativePath ?? "nil")|\(maxPixelDimension)"
    }
}

private func featureErrorMessage(_ error: Error) -> String {
    if let message = (error as? LocalizedError)?.errorDescription {
        return message
    }
    return error.localizedDescription
}
