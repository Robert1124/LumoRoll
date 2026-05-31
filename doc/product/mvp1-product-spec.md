# MVP1 Product Spec

## Purpose

LumoRoll lets users create personal "Film Rolls" from reference photos, apply those rolls to other photos, save results in the app, and export the generated LUT as a `.cube` file. The experience should feel simple, light, friendly, slightly playful, film-inspired, and useful without becoming a full color-grading suite.

## Scope

MVP1 includes:

- Create one Film Roll from one reference photo.
- Analyze the reference image locally on device.
- Generate one reusable 33x33x33 LUT per Film Roll.
- Require a non-empty user-entered Film Roll name before save.
- Store the reference image, generated LUT, thumbnails, processed results, and metadata inside the app.
- Apply a Film Roll to photos.
- Preview before, split, and after states.
- Adjust intensity by blending original and LUT-processed output without regenerating the LUT.
- Save processed results into the current Film Roll.
- Save processed photos to the system Photos library only through an explicit Save to Photos action.
- Share, edit, or remove processed photos from Fullscreen Viewer.
- Export `.cube` files from Film Roll detail through the system share/export sheet.

Out of MVP1:

- Video import, export, and processing.
- HDR, Log, and advanced Display P3 workflows.
- iCloud sync, accounts, networking, cloud processing, and network-based AI.
- Duplicate Film Roll, library search, and fullscreen Save to Photos actions.
- Multi-reference Film Rolls and advanced LUT controls.

## Primary Users

- Everyday iPhone users who want better-looking photos without technical controls.
- Photography enthusiasts and creators who collect reusable color looks.
- Lightweight professional users who want `.cube` export without opening a grading suite.

## Core Objects

- Film Roll: user-named saved LUT package containing one reference image, one generated 33x33x33 LUT, palette/metadata, thumbnails, and processed photos.
- Reference image: the single user-chosen source image used to generate the Film Roll.
- Processed photo: a target photo rendered with a Film Roll at a chosen intensity.
- `.cube` export: file representation of the Film Roll LUT for use outside LumoRoll.

## Inputs

- Reference photo from Photos or Files.
- Film Roll name typed or selected by the user.
- Target photo from Photos or Files for applying a roll.
- Intensity value from 0 to 100.
- Explicit user actions for saving to Film Roll, saving to Photos where surfaced, editing/removing processed frames, or exporting `.cube`.

## Outputs

- Saved Film Roll in the local library.
- Saved processed photo in the current Film Roll.
- Optional processed photo written to Photos.
- Optional exported `.cube` file.

## Dependencies

- Product depends on design direction in `design/Lutroll/`.
- Architecture must provide local persistence, navigation, and state management.
- Image processing must provide local reference analysis, LUT generation, LUT application, intensity blending, and `.cube` export.
- QA/privacy must validate permission timing, local-only guarantees, memory risk, export compatibility, and App Store review concerns.

## Empty and Error States

Core states are documented in [Empty and Error States](empty-error-states.md). MVP1 must cover empty library, empty Film Roll, import cancellation, unsupported image, analysis failure, save failure, Photos permission denial, share/export cancellation, and file export failure.

## Future Extension Points

- iCloud sync.
- Video support.
- HDR/Log/Display P3 workflows.
- Advanced skin-tone and neutral-gray protection controls beyond Algorithm V2's lightweight LUT-time soft protection.
- Local AI-assisted enhancements.
- Duplicate, search, roll folders/tags, and richer organization.
- Richer per-photo actions such as duplicate, favorite, metadata, and cover selection.

## Open Risks

- Large image memory usage can make import, preview, or export fail if not constrained.
- Users may expect exact style copying from a reference photo; copy should frame the feature as creating a personal color roll, not cloning another creator's work.
- `.cube` compatibility varies by external app and should be verified with common tools before release.
