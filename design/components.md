# LumoRoll MVP1 Components

## Purpose

Documents core UI components before SwiftUI implementation. Each component description includes purpose, inputs, outputs, dependencies, states, errors, empty handling, and extension points.

## Reversal Slide Film Roll Card

Purpose: Represents one saved Film Roll in the Home carousel as a small mounted reversal-slide card.

Inputs:

- Roll id.
- User-entered roll name.
- Reference thumbnail.
- Reference thumbnail aspect ratio when available.
- Processed photo count.
- Created date.
- Palette colors.

Outputs:

- Centered tap opens Film Roll detail; side-card tap may center that card before opening.
- Future long-press actions are deferred.

Dependencies:

- Local thumbnail storage.
- Roll metadata.
- Generated palette metadata.

State:

- Center selected, side/unselected, pressed, loading thumbnail, unavailable thumbnail.
- Center selected state is clearer, visually brought forward, slightly scaled by the carousel transform, and lit through the photo-window display/backlight only. The slide mount's base size remains fixed.
- Side/unselected state makes the photo window dimmer through display/backlight attenuation, lowers card emphasis, rotates toward the center, and can overlap inward behind the selected card.
- Side/unselected photo windows should read clearly darker than before, while preserving the underlying thumbnail color. The dimming is an overlay/display treatment, not saturation, contrast, or brightness retouching of the image asset.
- The central image window must reserve the same height for every card. Its width follows the loaded image aspect ratio with min/max clamps inside the slide mount.
- The light effect is constrained to the photo window, not the entire card back. It must not change the image's color, tone, saturation, contrast, or underlying thumbnail data.
- Must truncate long roll names cleanly.
- Card copy must avoid third-party film-brand names.

Empty/error:

- If thumbnail cannot load, show a warm placeholder film frame and roll initials/name.

Future extension:

- Context menu for duplicate/share/search tags only after MVP1 approval.

## Film Strip

Purpose: Horizontal continuous strip in detail, with the reference sample first and processed frames after it.

Inputs:

- Reference image thumbnail.
- Processed output thumbnails.
- Selected/open callbacks.
- Add-photo callback.

Outputs:

- Opens full-screen viewer for tapped frame.
- Opens Apply flow from add tile.

Dependencies:

- Local thumbnail storage.
- Roll photo ordering.

State:

- Scroll position.
- Empty processed-photo state: Detail still shows the sample frame in the center projection and bottom film. The projector plus affordance is hidden in this iteration.
- Loading images start from a fallback frame width.
- Film Roll Detail uses a center projected frame and bottom film transport. The center projected frame keeps its horizontal inset but reserves a taller-than-wide invisible layout region so the visible photo can maximize within it without a background block or a top `Sample` / `Frame xx` caption. The transport film contains existing photos only, with a finite leader/trailer. The fixed view finder is split into two transparent light/dark asset layers: a larger square back frame with `LUMOROLL` / `LIGHT BOX` labels and a smaller square front viewer block with corner screws. The front viewer keeps the current 168 pt size and live aperture proportion, uses the provided true-transparent realistic molded-plate front-block source image for light mode, and uses a dark variant generated from that same source image. The back frame is larger than the front layer so its bottom labels stay visible. The moving film renders between those two layers, so the back frame is covered by the film and the front viewer covers the film. Viewer assets use fully transparent outside/window cutouts and opaque plate material instead of translucent gray bounds. It hides its Add Photo control in this iteration. Its film frames are drag-only; inactive frames are dimmed with a 0.65 black overlay, while the selected frame stays bright and is visible through a slightly taller front viewer aperture at the same size as its film-strip cell. The selected frame target has a light `-12 pt` left optical correction so it appears centered below the layered viewer without drifting left. The black film body/sprockets move with the actual finite film content rather than filling the viewport. The moving film strip is laid out in an explicit full-screen-width leading coordinate space.
- Detail should request higher-quality display images than compact strips, preferring app-owned full-size paths while still downsampling for display.

Error:

- Missing image shows a dark frame with an accessible "Photo unavailable" label.

Future extension:

- Reordering and deletion are not MVP1 unless separately approved.

## Palette Row

Purpose: Shows the extracted color identity of a Film Roll.

Inputs:

- 3-5 palette colors derived from the reference image.

Outputs:

- Decorative visual cue only in MVP1.

Dependencies:

- Algorithm-provided palette metadata.

State:

- Always noninteractive in MVP1.
- Provide accessibility text such as "Roll palette" instead of reading raw hex values.

Future extension:

- Palette inspection or naming can be added later.

## Pill Button

Purpose: Primary and secondary command style for import, save, export, and share actions.

Inputs:

- Label.
- Optional SF Symbol.
- Variant: primary ink, secondary cream, ghost, destructive if needed later.
- Enabled/loading state.

Outputs:

- Invokes the command.

Dependencies:

- Button role and permission timing.

State:

- Enabled, pressed, disabled, loading.
- Disabled state must have visible contrast and accessible explanation where needed.

Error:

- Command failures surface as toast/banner or inline error near the affected action.

## Icon Button

Purpose: Compact navigation and overflow controls.

Inputs:

- SF Symbol.
- Accessibility label.
- Optional menu/action.

Outputs:

- Invokes navigation, close, more, or add.

Dependencies:

- Native SwiftUI `Button`.

State:

- Minimum 44x44 pt hit target.
- Visible pressed state.

## Segmented Preview Control

Purpose: Switches Apply preview between Before, Split, and After.

Inputs:

- Selected mode.

Outputs:

- Updates preview presentation only.

Dependencies:

- Apply screen preview state.

State:

- Before, Split, After.
- Split mode exposes draggable compare handle.

Error:

- If processed preview fails, disable After/Split and show error state.

## Intensity Slider

Purpose: Adjusts display/output intensity by blending original and LUT-processed image.

Inputs:

- Intensity value 0-100.
- Original image.
- LUT-processed image.

Outputs:

- Updated blend preview and saved output intensity.

Dependencies:

- Image-processing output cache.
- Does not regenerate the LUT.

State:

- Dragging, settled, disabled while processed image is unavailable.
- Values: 0 is original, 100 is full LUT output.

Error:

- If processed image generation fails, slider is disabled and the preview explains the failure.

## Before/Split/After Preview

Purpose: Main Apply screen visual comparison.

Inputs:

- Original image.
- Processed image.
- Intensity value.
- Split position.
- Preview mode.
- Display frame aspect ratio, derived from the loaded image.

Outputs:

- Direct manipulation of split position.
- Visual confirmation before saving.

Dependencies:

- Local image processing.

State:

- Loading original.
- Processing.
- Before.
- Split.
- After.
- Failed processing.
- Single-screen Apply layout may cap preview height, preserving the image ratio by narrowing very tall previews rather than allowing the page to scroll.

Future extension:

- Zoom/pan in Apply preview is not required for MVP1.

## Full-Screen Viewer

Purpose: Immersive dark viewer for browsing one Film Roll's sample and processed photos.

Inputs:

- Roll name.
- Ordered photo list with sample first.
- Start index.

Outputs:

- Swipe navigation.
- Save to Photos.
- Share.
- More menu if needed.

Dependencies:

- Local image storage.
- Photos write permission only when Save is tapped.
- Share sheet.

State:

- Current index.
- Sample badge for reference image.
- Loading image.
- Image unavailable.

MVP1 actions:

- Processed frames expose Share, Edit, and Remove.
- Reference/sample frames remain view-only.

## Toast / Confirmation

Purpose: Lightweight confirmation for save/export/share completion.

Inputs:

- Message.
- Optional icon.

Outputs:

- Nonblocking feedback.

Dependencies:

- Action result.

State:

- Appears briefly and dismisses automatically.
- Must be accessible via VoiceOver announcement.

## Task 7A SwiftUI Component API Notes

Implemented reusable components under `LumoRoll/DesignSystem/Components/`:

- `PaletteRow`
- `LumoPillButton`, `LumoPillButtonStyle`, and `LumoIconButton`
- `FilmRollCard`
- `FilmStrip`, `FilmFrame`, and `FilmStripItem.orderedItems(reference:processed:includesAddPhoto:)`
- `PreviewModeSegmentedControl`
- `LumoIntensitySlider`
- `SplitPreview`
- `FullscreenActionButton`
- `LumoPhotoDisplayData` and `LumoPhotoPlaceholder`

Photo display is intentionally pure: components receive injected `Image` values or render placeholders. They do not use file paths, PhotosUI, file import, sharing, Photos writes, or real navigation.

Review-fix notes:

- `SplitPreview` now takes a `Binding<CGFloat>` for split position, supports direct drag movement constrained to preview bounds, and exposes an adjustable VoiceOver control with percent-before value text.
- `LumoIntensitySlider` exposes an explicit accessibility label, descriptive percent value, and hint describing blend behavior.
- Film frame accessibility derives from `LumoPhotoDisplayData.accessibilityLabel`; unavailable images append `Photo unavailable`.

## Documentation Update Note

Created as MVP1 component specification for Design System worker scope.
