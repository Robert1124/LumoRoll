# Apply Photo Flow

## Purpose

Let the user apply an existing Film Roll to a photo, adjust intensity on a preview screen, and explicitly decide whether to save the processed result into that Film Roll.

## Flow

1. User opens a Film Roll Detail screen.
2. User opens Apply from an exposed entry point. The Detail projector plus affordance is currently hidden.
3. Apply screen opens with the selected Film Roll and a centered Import target panel.
4. User taps the panel and chooses Photo Library or Files.
5. User chooses one target photo.
6. LumoRoll shows Before/Split/After preview and an intensity slider. Temporary diagnostic Post/LUT buttons are not shown.
7. User taps `Save` to store the processed output in the current roll, or `Cancel` to discard the staged target without saving.
8. On successful Save, the user returns to Film Roll Detail. No system Photos write occurs.

## Inputs

- Selected Film Roll with generated LUT.
- One target photo.
- Import source choice: Photo Library or Files.
- Current intensity value.

## Outputs

- Rendered processed photo.
- Saved frame inside the current Film Roll.

Save to Photos is not surfaced in this flow. Only a later explicit Photos export/save action may write to the system library.

## Intensity Decision

Intensity changes must blend the original image and LUT-processed output. Intensity must not regenerate, mutate, or replace the Film Roll LUT.

Recommended behavior:

- 0 means original photo.
- 100 means full LUT output.
- Values between 0 and 100 linearly blend original and LUT output unless image-processing docs define a better local blend curve.

## Dependencies

- Film Roll Detail supplies the selected roll.
- Image processing supplies preview rendering, final rendering, LUT application, and intensity blending.
- Local persistence saves processed outputs into the Film Roll.
- Photos write API is not used by this Apply import flow.

## Empty and Error States

- Before target selection: show only the centered import panel; do not show preview modes, preview frame, intensity, Photos/Files buttons, or bottom save actions.
- Source choice: tapping the import panel asks the user to choose Photo Library or Files.
- After target selection: show preview modes, preview frame, intensity, and bottom `Save` / `Cancel` actions; keep Save to Photos hidden and do not write to Photos.
- User cancels photo selection: keep Apply screen idle without creating an output.
- User taps Cancel after import: discard the staged target and temporary preview without appending a processed frame.
- Target photo cannot load: show an import error and offer another selection.
- Final render fails: keep the user in Apply and offer retry.
- Save to Film Roll fails: do not imply the photo was saved; offer retry.

## User-Facing Copy

- Header label: `Applying`
- Import panel: `Import target`
- Source choices: `Photo Library`, `Files`
- Bottom actions after import: `Cancel`, `Save`

## Future Extension Points

- Batch photo application.
- Recent target photo strip if supported by architecture.
- Crop or orientation tools.
- Per-photo edit controls beyond intensity.
- Video support in a later MVP.
