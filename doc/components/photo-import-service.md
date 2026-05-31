# Photo Import Service

## Purpose

Adapt PhotosUI and file import into app-owned image inputs that Domain use cases can process.

## Inputs

- User selection from PhotosUI.
- User selection from file importer.
- Allowed image types: standard still images that iOS can decode for SDR processing, with HEIC, JPEG, and PNG as the MVP1 baseline.

## Outputs

- Temporary app-local image file under `tmp/imports/<import-id>/original.<ext>`.
- App-owned relative path rooted at `Application Support/LumoRoll/`.
- Normalized preferred extension and original filename where available.
- Import cancellation or typed import error.

## Data Dependencies

- System picker result.
- Temporary storage location.
- Security-scoped file access for files if needed.

## Relationship To Other Modules

- Concrete implementation in SystemIntegrations.
- Used by SwiftUI picker hosts after PhotosUI or file importer returns a user selection.
- Feeds Create Film Roll with image data and preferred extension for `CreateFilmRollUseCase`.
- Feeds Apply Photo with an app-owned relative target path for `ApplyPhotoFeatureModel.selectTargetPhoto(path:)`.
- Does not persist final Film Roll records.
- Does not write to Photos, present share sheets, generate LUTs, render processed outputs, or update manifests.

## State Management

SwiftUI hosts own picker presentation and import status. The service performs one import operation, copies data into app-owned staging, and returns a lightweight staged-photo value.

Create flow can read the staged file data once and pass it into the existing create feature model. Apply flow should keep only the staged relative path in feature state.

## Error States

- User cancelled.
- Unsupported type.
- File unreadable.
- Copy failed.
- Security-scoped access denied.
- Path traversal attempt in generated or supplied paths.

## Empty States

No selected image returns cancellation, not an empty successful result.

## Future Extension Points

- Multiple selection for batch apply.
- Camera capture if product adds it.
- Import metadata extraction if privacy-reviewed.

## Task 8B Implementation Note

Task 8B adds system-integration helpers before UI wiring:

- `AppAssetURLResolver`: resolves app-owned relative paths and rejects absolute/traversal paths.
- `PhotoImportStagingService`: copies PhotosPicker/file importer data or file URLs into `tmp/imports`.
- `LocalPhotoImageLoader`: asynchronously decodes/downsamples app-owned images for display cache use.

SwiftUI views may present pickers, but they must not synchronously read image files or decode large images inside `body`.

## Task 8B1 Implementation Result

Task 8B1 added support services only:

- `PhotoImportStagingService.stageImageData(_:preferredFileExtension:originalFilename:)` validates ImageIO-decodable single still images and stages bytes to `tmp/imports/<import-id>/original.<ext>`.
- `PhotoImportStagingService.stageImageFile(at:)` reads a file URL, uses security-scoped access when available, validates the image, and copies bytes into app-owned staging.
- Generated import IDs must be path-safe and are injectable for tests.
- The staged app path never includes the user-visible filename; `originalFilename` may be returned as metadata for future UI use.
- MVP1 accepted extensions are `heic`, `heif`, `jpg`, and `png`; `jpeg` is normalized to `jpg`.
- Unsupported extensions, mismatched extension/type, and undecodable data throw `LumoError.importFailed`.
- Validation uses ImageIO metadata and a bounded 128 px thumbnail preflight instead of full-size decode.
- File URLs with no extension are allowed when ImageIO can infer an accepted still-image type.
- If staging folder creation succeeds but the final data write fails, the service removes that staged import folder best-effort.

Task 8B1 still does not present PhotosUI, `.fileImporter`, broad Photos access, Save to Photos, share/export UI, video, HDR, cloud, network, or accounts.

Successful staged import cleanup after a user cancels or after a staged photo is committed remains an 8B2 integration responsibility.

## Task 8B2 UI Wiring Decision

Task 8B2 wires PhotosUI and `.fileImporter` only in SwiftUI feature screens/root hosts. Domain remains free of PhotosUI, SwiftUI picker types, UIKit picker controllers, and Photos-library write APIs.

- Create Film Roll stages PhotosPicker data or still-image file-imported URLs first, then reads the staged app-owned file bytes and passes `Data` plus the normalized preferred extension to `CreateFilmRollFeatureModel.selectReferenceImage(data:preferredFileExtension:)`. `.cube` file imports are intentionally excluded from `PhotoImportStagingService`; the Create screen reads them as text data and passes them to `selectCubeLUT(data:originalFilename:)`.
- PhotosPicker data imports do not trust the first `PhotosPickerItem.supportedContentTypes` extension as the selected encoded representation; they pass no preferred extension so staging validates and names the file from ImageIO-detected data type. File importer URLs still use `stageImageFile(at:)` so their file extension can participate in validation.
- Apply Photo stages PhotosPicker data or file-imported URLs first, then passes the staged app-owned `relativePath` to `ApplyPhotoFeatureModel.selectTargetPhoto(path:)`.
- A staged import may be discarded through the staging service only when the UI knows the model no longer needs it: create cancel/save/new selection after the model has copied bytes, or apply cancel/save/new selection after the selected path has been replaced or copied into permanent processed-photo storage.
- Discard is constrained to `tmp/imports/<id>/...` folders and must not delete saved `film-rolls/...` paths.
- Task 8B2 left Save to Photos as an explicit future action stub with no `PHPhotoLibrary` integration. Task 8C2 adds the separate Photos writer path without changing import staging behavior.
