# Photos Library Writer

## Purpose

Persist an explicitly rendered still image to the user's system Photos library after the user taps Save to Photos.

## Inputs

- App-owned relative processed photo path.

## Outputs

- Photos local identifier string for the created asset.
- Localized permission or save failure error.

## Data Dependencies

- `AppAssetURLResolver` for resolving only app-owned relative paths.
- PhotoKit add-only authorization.
- Existing rendered image file in app storage.

## Relationship To Other Modules

- Domain owns the `PhotoLibraryWriting` protocol.
- `PhotoKitPhotoLibraryWriter` lives in `SystemIntegrations` and implements `PhotoLibraryWriting`.
- Explicit Photos save use cases call this writer only after rendering or locating an app-owned processed output.
- The Apply feature model can observe success/failure state for lower-level reuse, but the current import-first Apply screen does not surface Save to Photos.

## State Management Logic

The writer performs no long-lived state management. For each explicit save call it:

- Resolves the relative path inside app storage.
- Verifies the rendered file exists before any Photos authorization request.
- Reads current add-only authorization status.
- Requests `PHPhotoLibrary.requestAuthorization(for: .addOnly)` only when status is not determined.
- Creates one Photos asset from the rendered file when authorized.

## Error States

- Invalid or missing app asset path: storage failure before authorization.
- Denied or restricted Photos access: clear permission error.
- PhotoKit creation failure preserves `CancellationError` and existing `LumoError` values from the client; unknown non-domain errors map to save failure.

## Empty States

No empty UI is owned by the writer. The current Apply flow hides Save to Photos entirely; UI that exposes Photos saving must do so only behind an explicit user action.

## Future Extension Points

- A future explicit Save to Photos surface can reuse the same `PhotoLibraryWriting` adapter for existing processed frames.
- Batch export can call the adapter once per explicit selected output if MVP2 adds batch actions.
- If broader Photos browsing is ever required, the permission model must be revisited before adding read authorization.
