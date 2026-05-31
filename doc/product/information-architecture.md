# Information Architecture

## Purpose

Define the MVP1 screen map and navigation relationships for LumoRoll. The app should open directly into the user's Film Roll library, not a marketing or account screen.

## Screen Map

- Library: home screen with a horizontal reversal-slide Film Roll carousel and a trailing blank add card as the create action.
- Create Film Roll: one-page flow for reference import, selected-reference preview, required naming, and explicit save-time local analysis/generation.
- Film Roll Detail: roll title, metadata, palette, title-row circular icon actions for `Export .cube` and adding a new photo, large adaptive center projected frame without a visible background block, bottom film transport with reference sample first and processed photos after it, and fixed square reference-style light-box viewer.
- Apply Photo: centered target import panel, Photo Library or Files source choice, preview/intensity editor, and explicit Save of the processed result into the current Film Roll.
- Fullscreen Viewer: dark immersive viewer for the reference sample and processed photos in one Film Roll.
- System Sheets: Photos picker, Files picker/importer, share sheet, export sheet, and Photos permission prompt when needed.

## Navigation Model

Primary navigation:

1. Library opens by default.
2. Tapping the Library blank add card opens Create Film Roll.
3. Successful Film Roll creation returns to Library with the new roll visible.
4. Tapping a Film Roll opens Film Roll Detail.
5. Detail currently hides the projector Add Photo plus affordance.
6. When an Apply entry is exposed again, selecting a target photo should open Apply Photo for that roll with the staged target already loaded into the preview/intensity editor.
7. Tapping Save in Apply saves the processed result into the Film Roll, then returns to Detail with the new frame appended to the bottom film transport.
8. Tapping a reference or processed frame opens Fullscreen Viewer.
9. Closing Fullscreen Viewer returns to Detail.
10. Export `.cube` from Detail opens the system share/export sheet.

## Screen Inputs and Outputs

Library:

- Inputs: local Film Roll metadata, thumbnails, photo counts, creation dates.
- Outputs: centered selected Film Roll, open-roll intent, create intent.

Create Film Roll:

- Inputs: one reference image and one non-empty Film Roll name.
- Outputs: saved Film Roll with reference image, generated LUT, palette, thumbnail, and metadata.

Film Roll Detail:

- Inputs: selected Film Roll and saved processed photos.
- Outputs: fullscreen viewer intent, roll rename/remove intents, `.cube` export intent.

Apply Photo:

- Inputs: selected Film Roll, one target photo, default intensity value.
- Outputs: rendered processed photo saved to Film Roll. This flow does not write to Photos.

Fullscreen Viewer:

- Inputs: selected Film Roll and start frame.
- Outputs: optional Share sheet, Edit route, or Remove action for the current processed frame.

## Dependencies

- Local persistence supplies Film Roll lists and detail data.
- Image processing supplies generated LUTs and rendered outputs. Preview rendering remains a lower-level capability but is not surfaced by the current Apply flow.
- System pickers/sheets provide import, export, share, and Photos write permission flows.

## Empty and Error States

- Empty Library shows a friendly create-first state.
- Empty Film Roll Detail still shows the reference sample as the projected frame and only film frame; the projector plus affordance is hidden in this iteration.
- Missing or deleted local assets show a recoverable placeholder and an option to remove the broken item when that feature is available.
- If a selected Film Roll cannot load, return to Library and show an error message.

## Future Extension Points

- Search and sorting in Library.
- Duplicate Film Roll.
- Roll folders, tags, or favorites.
- Per-frame detail metadata.
- Multi-reference roll creation.
