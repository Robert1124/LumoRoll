# Task 9 Final QA and Privacy Audit

Status: current implementation audit refreshed on 2026-05-30.

## Scope

This audit reviews the MVP1 implementation for:

- Local-only image processing.
- Photos-only media scope.
- Photos permission timing.
- Add-only Photos write behavior.
- `.cube` export compatibility.
- Large-image, memory, and performance risk.
- Failure states and cleanup.
- Copyright and user-expectation risk around reference style.

## Decisions Confirmed

- MVP1 remains local-only. No `URLSession`, app networking layer, analytics SDK, account flow, cloud processing, or network AI path was found in the app source.
- MVP1 remains photos-only. Import UI uses `PhotosPicker` with `.images`, file import allows JPEG, PNG, HEIC, and HEIF, and staging validates still images before copying them into app-owned storage.
- Broad Photos read permission is not part of normal MVP1 flows. The app has `NSPhotoLibraryAddUsageDescription` and no broad `NSPhotoLibraryUsageDescription` key.
- Photos write access is requested only from the explicit Save to Photos path. `PhotoKitPhotoLibraryWriter` checks the app-owned rendered file first, then requests `PHPhotoLibrary` authorization for `.addOnly` only when needed.
- Save to Photos writes a rendered output to Photos with `PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL:)`; it does not request broad read/write library access.
- The current Apply import flow does not surface Save to Photos; it shows `Cancel` and `Save`, where `Save` writes to the current Film Roll. The lower-level Save to Photos use case remains available for explicit output surfaces.
- The current Fullscreen Viewer surfaces processed-frame `Share`, `Edit`, and `Remove`; it does not surface Save to Photos.
- `.cube` export is user-initiated from Film Roll detail and uses a SwiftUI `fileExporter` document with a `.cube` filename suggestion.
- The current `.cube` writer emits `TITLE`, `LUT_3D_SIZE`, `DOMAIN_MIN`, `DOMAIN_MAX`, and normalized RGB rows with six-decimal POSIX formatting.
- Current processed JPEG outputs are generated from rendered `CGImage` data with only JPEG quality options, so source EXIF/GPS metadata is not intentionally copied into rendered outputs.

## Implementation Evidence Reviewed

- `LumoRoll/Resources/Info.plist`: contains only `NSPhotoLibraryAddUsageDescription` for Photos access.
- `LumoRoll/Features/CreateFilmRoll/CreateFilmRollScreen.swift`: PhotosPicker is image-scoped and file import is limited to JPEG, PNG, HEIC, and HEIF.
- `LumoRoll/Features/ApplyPhoto/ApplyPhotoScreen.swift`: target import is image-scoped; the current bottom actions are `Cancel` and `Save` to Film Roll.
- `LumoRoll/Features/FullscreenViewer/FullscreenViewerScreen.swift`: processed frames expose `Share`, `Edit`, and `Remove`; reference frames are view-only.
- `LumoRoll/SystemIntegrations/PhotoImportStagingService.swift`: validates still image data, rejects unsupported types, copies imports into `tmp/imports`, and supports scoped file URLs.
- `LumoRoll/SystemIntegrations/PhotoKitPhotoLibraryWriter.swift`: uses add-only PhotoKit authorization and rejects invalid or missing app-owned paths before authorization.
- `LumoRoll/Domain/UseCases/SaveAppliedPhotoToPhotosUseCase.swift`: renders a temporary output, writes it to Photos, and discards the temporary render on success or failure.
- `LumoRoll/Processing/Rendering/CoreImageRenderer.swift`: uses an sRGB Core Image pipeline and creates a Metal-backed `CIContext` when a Metal device is available.
- `LumoRoll/Processing/LUT/CubeExporter.swift`: serializes standard `.cube` text with normalized values.
- `LumoRoll/Features/FilmRollDetail/CubeLUTExportDocument.swift`: exports `.cube` as plain text through user-initiated file export.

## Remaining Risks and Blockers

- Real-device memory and performance remain unverified. The implementation has bounded analysis and preview paths, but full-resolution apply and Save to Photos render through full-size `CGImage` and JPEG encoding.
- There is no explicit import pixel-count or file-size ceiling. Very large images may still stress memory before the app can fail recoverably.
- `ReferenceImageAnalyzer.analyze(data:)` creates a full `CGImage` before downsampling for analysis. This keeps the algorithm simple but leaves a large-image memory risk.
- Save to Photos renders a temporary output before requesting add-only authorization. This still follows explicit user action, but denial after rendering costs time and memory and then discards the temporary result.
- A crash between temporary render creation and cleanup could leave an unmanifested processed folder under the Film Roll. Normal success and failure paths do discard the temporary render.
- `.cube` automated format tests exist, but cross-app import compatibility is still manual and not completed.
- Processed JPEG outputs appear to strip source metadata, but this needs device-level verification using exported files saved to Photos and shared through the file exporter.
- Original selected reference and target image bytes are stored in app sandbox for saved Film Rolls. Those originals may retain source EXIF/GPS metadata inside app-managed storage and must not be exposed by future sharing features without a metadata review.
- User-facing copy avoids exact-copy claims in the reviewed screens, but App Store copy and onboarding copy still need final review before release.

## Follow-Up Tasks

- Run real-device memory profiling for create, apply, Save to Photos, and export using 12 MP, 24 MP or larger, panorama, and HEIC inputs.
- Decide whether MVP1 needs an explicit maximum import dimension or file-size guard before release.
- Add an automated or scripted `.cube` validator to count rows, parse headers, validate numeric ranges, and check red-fastest ordering.
- Complete manual `.cube` import checks in the selected compatibility apps and record app versions.
- Verify Photos permission timing on a clean-install device: no prompt during import/create/apply/export, prompt only after Save to Photos.
- Verify metadata behavior for rendered JPEGs saved to Photos and exported/shared outputs.
- Add a cleanup review for stale `tmp/imports` folders and any unmanifested processed folders after app relaunch or crash.
- Complete final App Store privacy answer review against linked SDKs, build settings, and release copy.
