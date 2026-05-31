# Save, Share, Export Flow

## Purpose

Define explicit output actions so users understand where processed photos and LUT files go. MVP1 separates in-app saving, Photos saving, sharing, and `.cube` export.

## Save to Film Roll

Purpose: store the rendered processed photo inside the current Film Roll.

Inputs:

- Current Film Roll.
- Target photo.
- Current intensity value.
- Final rendered output.

Outputs:

- Processed photo saved in app storage.
- Thumbnail appended after the reference sample in the Film Roll film strip.
- Updated photo count.

Behavior:

- This is the primary apply-flow save action.
- It is triggered only after a target has been imported and the user taps `Save` on the Apply preview screen.
- It does not write to the system Photos library.
- It should return the user to Film Roll Detail after success.

## Save to Photos

Purpose: write a processed photo to the system Photos library only when explicitly requested.

Inputs:

- Final rendered processed photo.
- User tap on Save to Photos.
- Photos write permission if not already granted.

Outputs:

- New photo in the system Photos library.

Behavior:

- This is separate from Save to Film Roll.
- Photos write permission is requested only after the user taps Save to Photos.
- Apply import no longer surfaces Save to Photos. It offers only `Save` to the current Film Roll or `Cancel` without saving.
- Fullscreen Viewer surfaces Share, Edit, and Remove for processed frames. It does not surface Save to Photos.
- If permission is denied, the app should explain the issue and leave other output actions available.

## Share Processed Photo

Purpose: let the user share a rendered processed photo through the system share sheet.

Inputs:

- Current processed photo from the Fullscreen Viewer Share action.

Outputs:

- System share sheet with the rendered image.

Behavior:

- Sharing does not automatically save to Film Roll or Photos.
- Fullscreen Viewer presents the system share sheet for the app-owned processed render file.
- Share cancellation is not an error.

## Export `.cube`

Purpose: export the Film Roll LUT for use in other tools.

Inputs:

- Current Film Roll.
- Generated 33x33x33 LUT.
- Film Roll name for filename.

Outputs:

- `.cube` file presented through the system share/export sheet.

Behavior:

- Export starts from Film Roll Detail.
- Suggested filename should derive from the Film Roll name and end in `.cube`.
- After the `.cube` file is prepared, LumoRoll must present a system export/share UI instead of only showing an in-app ready message.
- Exporting does not save any processed photo.
- Export cancellation is not an error.

## Dependencies

- Local persistence for stored Film Roll assets and processed photos.
- Image processing for final rendered images and `.cube` serialization.
- System share/export sheets.
- Photos write API for Save to Photos only.

## Empty and Error States

- Save to Film Roll fails: show retry and keep the rendered output available.
- Save to Photos permission denied: show a recoverable permission message.
- Photos write fails: explain that the image was not saved to Photos.
- Share/export cancelled: dismiss silently or show no-error state.
- `.cube` serialization fails: show export failure and retry.
- Film Roll LUT missing: disable export and surface a data recovery issue.

## Future Extension Points

- Export presets for LUT size or compatibility.
- Batch export.
- Share card or visual roll preview.
- Save both to Film Roll and Photos with one explicitly labeled combined action.
