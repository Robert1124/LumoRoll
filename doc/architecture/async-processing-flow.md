# Async Processing Flow

## Purpose

Document the asynchronous boundaries for import, create, apply, save, export, share, and Photos write flows.

## Create Film Roll

1. User selects a reference image through PhotosUI or Files.
2. System integration copies/imports the image into a temporary app location.
3. Feature model reads the staged image bytes and enters the naming state.
4. User provides a required Film Roll name.
5. User explicitly saves the named Film Roll.
6. Domain create use case asks Processing to analyze the reference image.
7. Processing generates the default 33x33x33 LUT and palette summary.
8. Processing renders a reference thumbnail.
9. Storage commits assets and metadata atomically.
10. Library state refreshes and navigates/dismisses according to product decision.

Failure should leave the user in the create flow with a retry path. The roll is not saved until the user name and all required assets exist.

## Apply Photo

1. User chooses an Apply/Add Photo entry point when it is exposed. The Film Roll Detail projector plus affordance is currently hidden.
2. User imports/selects a target photo.
3. Feature model requests temporary preview rendering for the selected roll, photo, and intensity.
4. Processing applies the existing LUT and blends original with processed output according to intensity.
5. Preview state updates with an app-owned rendered preview path or a recoverable render failure.
6. User adjusts intensity; the app re-renders the temporary preview without regenerating the LUT.
7. User saves to Film Roll, Photos, shares, or cancels.

Temporary preview renders must be discarded when superseded or stale. They are not Film Roll frames and are not Photos outputs.

## Save To Film Roll

1. Feature model sends the current source image, selected roll ID, intensity, and render settings to a use case.
2. Processing creates final rendered output and thumbnail.
3. Storage appends a processed photo record and asset files.
4. Detail projector transport refreshes, keeping the reference sample first and adding the new processed photo to the bottom film.

## Save To Photos

1. User explicitly taps Save to Photos.
2. SystemIntegrations requests Photos write authorization only at this moment if needed.
3. Processing provides or creates final rendered output.
4. SystemIntegrations writes the image to Photos.
5. Feature reports success or permission/failure state.

## Export `.cube`

1. User taps `.cube` export from Film Roll detail.
2. Domain loads the LUT descriptor or binary.
3. Processing serializes compatible `.cube` text data if a cached export is missing or stale.
4. Storage may cache the export file.
5. SystemIntegrations presents file export/share UI.

SwiftUI views do not serialize `.cube` text directly.

## Share Processed Photo

1. User selects a saved processed photo or current rendered result.
2. Feature asks for a shareable file URL.
3. Storage/Processing ensures the file exists.
4. SystemIntegrations presents the share sheet.

## Cancellation

- Import cancellation returns to the prior state.
- Render cancellation should not corrupt storage.
- Save/export tasks should surface final success or failure; they should not leave partial manifest updates.

## Future Extension Points

- Background task support for large renders.
- Progress callbacks from processing.
- Batch apply flow.
