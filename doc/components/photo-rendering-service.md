# Photo Rendering Service

## Purpose

Apply a Film Roll LUT to photos, blend with the original by intensity, and render preview/final/thumbnail outputs locally.

## Inputs

- Source image file.
- Processed photo ID generated before rendering by `ApplyFilmRollUseCase`.
- LUT descriptor or LUT data.
- Intensity value.
- Target render size or quality.
- Output destination or requested in-memory preview type.

## Outputs

- Final rendered JPEG at `film-rolls/<roll-id>/processed/<photo-id>/rendered.jpg`.
- Thumbnail JPEG at `film-rolls/<roll-id>/processed/<photo-id>/thumbnail.jpg`.
- App-owned original copy at `film-rolls/<roll-id>/processed/<photo-id>/original.<ext>`.
- Typed processing errors.

## Data Dependencies

- Source image asset.
- LUT asset.
- Metal-backed `CIContext`.
- Render settings from Domain/Processing.

## Relationship To Other Modules

- Concrete implementation in Processing.
- Implements Domain `PhotoRendering` protocol.
- Called by apply/save use cases.
- Storage supplies file layout through `AssetStore`.
- Rendering writes the processed original, rendered image, and thumbnail into `processed/<photo-id>/`, but it does not update the Film Roll manifest. The Domain use case owns manifest mutation after rendering succeeds.
- `PhotoRenderRequest.processedPhotoID` is the storage folder name and must match the resulting `ProcessedPhoto.id`.
- `PhotoRenderRequest.sampleAnalysisPackage` carries saved roll metadata for app-only adaptive post process. When absent, rendering falls back to base-LUT-only behavior.

## State Management

Rendering is stateless except for shared processing resources such as `CIContext`. Feature models own task cancellation and progress display.

## Error States

- Source image decode failed.
- LUT data invalid.
- Render target too large.
- Output encode failed.
- Processed folder creation or original copy failed.
- Memory pressure/cancellation.

## Task 8A Implementation Notes

`CoreImagePhotoRenderer` reads an absolute file path or an `AssetStore.rootURL`-relative path, copies the source image into the app container, applies the LUT with intensity blending through `CoreImageRenderer`, and encodes rendered/thumbnail outputs as sRGB JPEGs. Returned manifest paths are relative to `AssetStore.rootURL` and never include the user-visible source filename.

`discardRenderedPhoto(_:)` removes only the processed output folder derived from a safe manifest path shaped like `film-rolls/<safe-roll-id>/processed/<safe-photo-id>/...`. Malformed paths or traversal attempts are ignored so cleanup cannot delete outside the intended processed-photo folder. This supports the Domain cleanup contract when manifest save fails after rendering.

## Empty States

No source image means no render request should be made.

## Future Extension Points

- Progressive preview then final render.
- Tiled rendering for very large images.
- Alternate LUT sizes.
- HDR/video pipeline in MVP2.
