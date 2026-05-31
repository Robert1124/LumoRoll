# LumoRoll MVP1 Screens

## Purpose

Defines MVP1 screen structure and visual behavior for the native iOS app.

## Home Library

Reference: prefer `design/Lutroll/_check/09-final.png` if source and screenshots differ.

Purpose:

- Shows saved Film Rolls in a Cover Flow-style 3D reversal-slide carousel.
- Provides entry into Create Film Roll.

Content:

- No top-left brand/title cluster and no top-right create button on the Home surface.
- Search/filter chips are deferred with search behavior. Do not show inactive visual-only chips in MVP1.
- Square reversal-slide Film Roll cards in a 3D perspective carousel, not a flat horizontal card list.
- A blank reversal-slide add card is always present at the end of the carousel. Selecting it shows `Create a new roll`; tapping it while centered opens Create Film Roll.
- The add-card selected summary reserves the same lower-row height as a normal roll summary so the page does not jump when swiping between a saved roll and the add card.
- Home is a fixed first-viewport screen; do not use vertical scrolling on the Library home.
- The carousel uses linear first/last boundaries and snaps to center after a horizontal drag. At the first or last card, dragging outward must not wrap to the other end.
- All slide cards keep the same outer physical size. The centered card is the only one facing the user and is visually largest through Cover Flow scale.
- Left and right cards stay visible, overlap inward, and rotate toward the centered card. Left cards rotate right/toward center; right cards rotate left/toward center.
- Each card's central photo window has fixed height. Its width follows the loaded reference photo aspect ratio, clamped to stay inside the slide mount.
- The selected photo window is lit like a slide on a lightbox by brightening the window display/backlight only. Do not alter the thumbnail image's color, tone, saturation, contrast, or generated pixel data for the centered state. Side photo windows are dimmer through reduced window/backlight presentation, and the matte paper mount should not glow.
- The selected-roll title/metadata sits above the carousel in a reserved-height area. The title top inset is lifted slightly from the raw carousel inset, while the card position is computed so the centered slide card sits 20 pt below the available viewport center. Page dots sit below the card.
- The slide card may use `LUMOROLL`, `COLOR ROLL`, `LUT`, and `33x33x33` copy, but must not use third-party film-brand names.
- Do not show a Home bottom tab bar, Rolls/Favorites/Settings bar, or Preview LUT button.

Empty state:

- Show one primary action to create the first Film Roll.
- Show one blank reversal-slide Film Roll card on the Home background using the same size and center-plus-20 position as the carousel card when exactly one Film Roll exists. The blank card contains a centered add affordance. Do not show the carousel page dot, bottom create pill, header plus, or brand/title cluster in the empty state. Place the `Create your first Film Roll` prompt in the same reserved title area above the card, not below it. Creation remains available by tapping the blank card. Do not use a generic photo placeholder or a separate white/surface panel.

Error state:

- If local library cannot load, explain that rolls are unavailable and offer retry.

Deferred:

- Search.
- Duplicate.
- Long-press actions.

## Create Film Roll

Purpose:

- Imports one reference image and requires a user-entered name on the same page before save-time local analysis/generation.

One-page content:

- One `Add a reference` picker surface. Tapping it opens a source choice for Photos or Files.
- Selected-reference preview after import.
- Film Roll name field.
- Save action gated by selected reference plus valid name.
- Save-time progress for local analysis, 33x33x33 LUT generation, thumbnail creation, and storage.

Rules:

- Step 1 title is `Pick a photo sample or a cube LUT`.
- Copy must say `33x33x33`, not `32x32x32`.
- Do not show a separate Step 2 analysis panel in MVP1.
- No `Untitled Roll` save path. Disable Save until name is valid.
- Name suggestions are allowed, but selecting one counts as user naming.
- The reference image becomes the first frame in the Film Roll.

Error states:

- Import canceled.
- Unsupported file.
- Image cannot be decoded.
- Analysis failed.
- Storage failed.

## Film Roll Detail

Purpose:

- Shows the identity and contents of one Film Roll.
- Provides apply and `.cube` export actions.

Content:

- Back button.
- Roll metadata label.
- Large roll title.
- Created date, used-on count, palette row.
- Center projected frame viewer with the current sample/reference or processed photo, shown directly without a white card/backdrop and without a top `Sample` / `Frame xx` caption.
- The center projected frame sits inside a large adaptive display container, but the container does not draw a visible background block or stroke. Its width stays tied to the existing horizontal inset, while its layout height is taller than the available image width so portrait and landscape photos have more vertical room. The image uses aspect-fit behavior so either its width or its height fills the available container without cropping.
- Bottom film transport with the roll's existing photos: first sample/reference, then processed frames, plus a short leader before the first frame and trailer after the last frame.
- A fixed square light-box view finder sits at bottom center in a warm light hybrid style matching the reference image. It is built from two transparent light/dark asset layers, not flat SwiftUI rectangles: a larger labeled square back frame with `LUMOROLL` and `LIGHT BOX`, and a smaller unlabeled square front viewer block with realistic corner screws, the current live aperture proportion, and colors matched to the back frame. The back frame is large enough that its bottom labels remain visible below the front viewer. The moving film strip passes between those layers, so the back frame sits behind the film and the front viewer masks/covers the film.
- Viewer asset cutouts must be clean: outside the plate shape and inside the window are fully transparent, with no translucent gray bounding border. The plate material itself covers the film instead of letting selected-frame outlines show through.
- The view finder does not render a separate enlarged photo. The selected film cell remains the same fixed height as the film-strip cells, passes under a front viewer aperture that is slightly taller than the film photo cell, and stays bright; inactive film cells remain dimmed.
- The selected frame snap target applies a light `-12 pt` left optical correction under the layered viewer so the selected film cell reads centered beneath the fixed front aperture without a left drift.
- If the selected frame does not fill the visible aperture, the remaining visible area is the same black tone as the film body.
- Do not render a decorative top rail, `FILM VIEWER` title, or center horizontal bar on the projector body.
- Dragging the film left/right moves the film under the projector, snaps by photo frame, updates the center projected frame, and produces a subtle haptic. On release, the snap animation must continue from the release position without jumping back to the previous frame center. Film frames are not tap targets.
- Film sprocket holes, photo frames, black film body, and finite film edges move together as one film object. Do not extend the black film body or sprocket holes outside the actual moving film content.
- The center projected frame and the bottom film transport share a full-screen-width visual viewport. This viewport cancels the Detail page's horizontal content padding with an equal leading offset, so the projected image, fixed view finder, and moving film all center on the physical screen center while title/metadata remain padded.
- The film transport's visible and draggable viewport bleeds through the Detail page's horizontal content padding so the moving film can reach the physical screen edges before it is clipped.
- The film transport is visually larger than the earlier compact version. Photos in the film use fixed heights and aspect-derived widths, and inactive thumbnails are strongly dimmed with a 0.65 black overlay so the center projection and selected view-finder cell remain the active visual focus. The moving film content is laid out in an explicit full-screen-width leading-edge coordinate space, so the selected film frame snaps directly beneath the fixed centered viewer even when the finite film content is wider than the viewport.
- Do not render a light beam or projection cone.
- Do not show the Add Photo plus button on the view finder body in this iteration.
- `Export .cube` and Add Photo are circular icon buttons in the top-right header row beside the three-dot menu. Tapping Add Photo presents the existing Photos / Files source choice for adding a new processed photo to the Film Roll. Do not show these actions in the title row or as a bottom-pinned export/add action row.
- The Detail page itself does not vertically scroll.
- No roll-level intensity panel in MVP1. Intensity belongs to the Apply flow and saved processed outputs.

Empty state:

- For a new roll with no processed photos, show the sample frame as the center projection and the only bottom film frame; do not add explanatory copy under the transport.

Error states:

- Missing reference image.
- Missing processed frame.
- Export failure.

## Apply Photo

Purpose:

- Lets the user add one target photo to a Film Roll and save the processed result into that roll.

Content:

- Roll context in header.
- Centered Import target panel before selection.
- Source choice dialog with Photo Library and Files after tapping the panel.
- If opened from Detail after a photo is picked, skip the empty import state and open the preview/intensity editor with that staged target.
- Before/Split/After preview after import.
- Intensity slider after import.
- Do not show temporary diagnostic `Post` or `LUT` buttons in the Apply editor.
- Bottom `Save` and `Cancel` actions after import.

Rules:

- Imported targets do not auto-save.
- `Save` stores the processed result in the current Film Roll inside the app.
- `Cancel` discards the staged target and temporary preview without saving.
- This flow does not write to Photos.
- Long-press preview-to-original can be considered but is not required for MVP1.

Error states:

- Processing failed.
- Save to roll failed.

## Full-Screen Viewer

Purpose:

- Dark immersive viewer for browsing frames inside one Film Roll.

Content:

- Close button.
- Roll name and current frame label.
- Centered image.
- Page indicator.
- Bottom actions on processed frames: Share, Edit, Remove.
- Reference/sample frames reserve the same bottom action-row space invisibly so paging between sample and processed frames does not shift the preview or page dots.
- Pinch zoom and two-finger pan are not available in the current photo preview.

Rules:

- The sample/reference image is part of the sequence and must be clearly labeled.
- Swipe navigation stays within the current Film Roll.
- Reference/sample frames are view-only in fullscreen.
- Remove asks for confirmation before deleting a processed frame.

Error states:

- Image unavailable.
- Share/edit/remove unavailable for reference frames.

## Permission Timing

- Photo import uses PhotosUI or file import and should not request broad library write permission.
- Photos write permission is requested only from explicit Save to Photos.
- No network permission is needed for MVP1.

## Documentation Update Note

Created to define MVP1 screen behavior from the design source.

## Task 7B SwiftUI Screen Note

Task 7B adds the MVP1 SwiftUI screens and root `NavigationStack` shell.

- Library renders the reversal-slide carousel, empty state with one Create action, and retry state. Create/open actions are emitted as feature-model intents and routed by `LumoRollRootView`.
- Create Film Roll renders one page with reference import, preview, required name, and Save. Import buttons call injected closures for later Task 8 integration; in the Task 7B live root those closures are inert and cannot select placeholder data. Save is disabled until a real reference is selected and the trimmed name is non-empty, and copy uses `33x33x33`.
- Detail renders header/back/export/add/more, title, metadata, palette, center projected frame, bottom film transport, and fixed light-box view finder body. It does not include a standalone Import Photo panel, projector plus button, title-row action cluster, bottom export/add row, or the deferred roll-level intensity panel.
- Apply renders roll context and a centered Import target panel. Tapping the panel asks for Photo Library or Files, then the selected target enters the preview/intensity editor with bottom `Save` and `Cancel`.
- Fullscreen renders a dark paged viewer with sample first, processed frames after, close, and processed-frame Share/Edit/Remove actions. The top-right ellipsis and bottom More action are not shown.

## Task 8B2 Screen Note

Task 8B2 turns import and local display into real SwiftUI behavior while preserving MVP1 scope.

- Create `Add a reference` presents a Photos/Files source choice, stages the result locally, shows the selected reference preview or `.cube` selection, and keeps Save gated by user name plus selected source.
- Apply target import presents native import surfaces for still images from a source choice dialog, stages the target locally, and waits for explicit `Save` before appending the processed result to the Film Roll. Save to Photos remains out of this flow.
- Library cards load reference thumbnails when available.
- Detail film transport loads reference/processed thumbnails, keeps the sample frame first, sizes frames by fixed height plus image aspect ratio, and includes finite leader/trailer ends.
- Fullscreen loads display-sized original/reference and processed render images.
- No Photos write permission, Save-to-Photos implementation, video, HDR, cloud, network, or account behavior is introduced. Fullscreen processed-frame Share uses the system share sheet for the existing app-owned processed render file only.
