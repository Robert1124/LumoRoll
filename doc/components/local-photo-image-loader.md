# Local Photo Image Loader

## Purpose

Load app-owned local images asynchronously for display cache use without decoding large files inside SwiftUI view bodies.

## Inputs

- A safe app-owned relative image path.
- Maximum display pixel dimension.

Requested display dimensions must be positive. Oversized requests are clamped to the service cap of `4096` px on the longest side.

## Outputs

- `LocalPhotoDisplayImage` with encoded display `Data`, pixel width, pixel height, and output content type.

## Data Dependencies

- `AppAssetURLResolver`.
- App-owned files under `AssetStore.rootURL`.
- ImageIO decoding and thumbnail generation.

## Relationship To Other Modules

- Lives in `LumoRoll/SystemIntegrations`.
- Intended for Task 8B2 UI wiring to map reference thumbnails, processed thumbnails, apply previews, and fullscreen images into display data.
- Does not choose images, present pickers, write files, save to Photos, share, export, or update manifests.

## State Management

The loader is a stateless `Sendable` service. Decode/downsample work runs asynchronously and returns a lightweight `Sendable` value rather than UIKit/AppKit image objects.

## Error States

- Unsafe relative path rejected by the resolver.
- Missing file.
- Corrupt or undecodable image.
- Non-positive max pixel dimension.

Image decode/load failures throw `LumoError.importFailed`.

Excessive max-dimension requests are clamped, not rejected, so a caller bug cannot trigger larger display decodes than MVP1 allows.

## Empty States

No image path means the caller should keep the existing empty UI state; the loader does not synthesize placeholder images.

## Future Extension Points

- Add in-memory display cache ownership in Task 8B2 if screen performance needs it.
- Add larger preview policies for fullscreen while preserving bounded decode memory.
- Task 8B2 owns cancellation strategy for scrolling grids and fullscreen navigation.

## Task 8B2 Display Store Decision

Task 8B2 adds a UI/app-layer display image store above `LocalPhotoImageLoader`.

- The loader remains stateless and returns encoded display data only.
- The store maps app-owned relative paths plus requested max pixel dimension to SwiftUI `Image` values outside SwiftUI `body`.
- Successful loads are cached by `(relativePath, maxPixelDimension)`.
- Concurrent requests for the same key share in-flight work where practical.
- In-flight bookkeeping is owned by a small actor registry and is cleared when the shared load actually succeeds or fails. A cancelled caller does not clear the shared entry, so a reappearing view can join the same ImageIO decode instead of starting duplicate work.
- Failures publish a non-crashing error state and do not cache invalid images.
- SwiftUI views use `.task(id:)` for view-scoped cancellation; if a cell disappears, the cancelled caller does not publish an image, but the underlying shared display load is allowed to finish for this MVP pass.
- Preview containers use a disabled/no-op display store so SwiftUI previews keep placeholders instead of trying to read nonexistent fixture paths from disk.
