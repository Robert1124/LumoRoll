# Photos Permission Model

Status: MVP1 decision document.

## Purpose

Define when LumoRoll interacts with the user's photo library and how permission prompts should be timed.

## Decisions

- Use PhotosUI for importing reference images and target photos where possible.
- Prefer picker-scoped user selection over broad Photos read permission.
- Do not request broad photo library read permission for MVP1 normal flows.
- Request Photos write permission only when the user explicitly taps Save to Photos.
- Keep Film Roll library storage inside the app sandbox, not the system Photos library.
- `.cube` export is handled through user-initiated file export or share sheet, not Photos permissions.
- Task 8B1 import/display support services do not request Photos permissions. They only validate already-provided Data or file URLs and copy selected still images into app-owned staging.
- Task 8C2 uses PhotoKit only from explicit output actions. It requests add-only Photos authorization, not broad read/write authorization.
- Task 9 audit confirms the current app bundle uses `NSPhotoLibraryAddUsageDescription` and does not define a broad `NSPhotoLibraryUsageDescription` key.

## Import Flows

Reference image import:

- User taps the create/import action.
- System picker or file importer opens.
- User selects exactly one reference image for the Film Roll.
- LumoRoll receives only the selected item.
- App analyzes the image locally and asks the user to name the Film Roll before saving.

Apply-photo import:

- User opens a Film Roll and chooses a photo to process.
- System picker or file importer opens.
- User selects the photo.
- LumoRoll receives only the selected item.
- App applies the existing LUT locally.

## Save to Photos Flow

Photos write permission can be requested only after:

1. The user has a processed output.
2. The user explicitly chooses Save to Photos.
3. The app is ready to write only that selected output.

If permission is granted, write the processed output to the system Photos library. Invalid or missing app-owned output paths are rejected before requesting authorization.

Apply Save to Photos remains a lower-level explicit output path: it renders a temporary processed output for the selected target and current intensity, verifies the app-owned rendered file exists, requests add-only Photos authorization only if needed, writes it to Photos, discards the temporary render, and does not append a frame to the Film Roll. Fullscreen Viewer exposes Share, Edit, and Remove for processed frames; Share uses the system share sheet for the app-owned processed render file and does not request Photos permission.

If permission is denied:

- Keep the processed output available inside the Film Roll when applicable.
- Offer Share or Export where applicable.
- Provide a plain-language failure message.
- Do not repeatedly prompt.

## Permission Copy

Suggested write-permission rationale:

> LumoRoll needs permission to save this edited photo to your Photos library.

Suggested denial message:

> LumoRoll could not save to Photos. You can keep editing here or share a saved Film Roll frame from fullscreen.

## Empty, Error, and Edge States

- User cancels picker: return to the previous screen without creating empty content.
- Selected item fails to load: show import failure and allow retry.
- Unsupported image type: explain that MVP1 supports standard SDR photos first.
- Save to Photos denied: keep local result and offer share/export alternatives.
- Save to Photos fails after permission: show failure and allow retry.

## Future Extensions

If MVP2 adds iCloud sync, video import, or broader media browsing, this model must be reviewed before implementation.
