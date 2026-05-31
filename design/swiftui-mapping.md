# SwiftUI Mapping Notes

## Purpose

Maps the `design/Lutroll/` visual reference to native SwiftUI conventions. This is design guidance, not app code.

## Platform Assumptions

- iPhone-first SwiftUI.
- Native navigation, sheets, menus, buttons, sliders, PhotosUI, and ShareLink/share sheet where appropriate.
- SF Pro and SF Mono defaults.
- Custom serif/display font is optional future work only after licensing is settled.

## Tokens

Create semantic SwiftUI tokens rather than CSS-variable replicas:

- `appBackground`
- `surfacePrimary`
- `surfaceSecondary`
- `textPrimary`
- `textSecondary`
- `textTertiary`
- `hairline`
- `hairlineStrong`
- `accent`
- `noirBackground`
- `noirSurface`

Use dynamic colors for light and dark mode.

## Typography

- Roll titles: system serif design may be explored through SwiftUI if it remains native and readable.
- UI labels: `.caption`, `.caption2`, `.footnote`, `.subheadline`.
- Technical labels: `.monospaced()` with uppercase tracking.
- Body copy: native `.body` / `.callout`.

Do not depend on Instrument Serif, Geist, or Geist Mono for MVP1.

## Layout

Home:

- Do not wrap Library home in a vertical `ScrollView`; it should be a fixed viewport layout.
- Use a custom Cover Flow-style horizontal carousel with drag gesture, snap-to-center behavior, and linear first/last boundaries.
- Do not render a top-left brand/title cluster or top-right create button; creation is available through the blank add card.
- Always append a blank reversal-slide add card to the carousel. Its selected summary reads `Create a new roll`.
- The add-card summary reserves the same metadata/palette row height as saved roll summaries so paging between cards does not shift page dots or surrounding layout.
- Keep square slide-mount card dimensions stable as images load.
- Keep every card's base size fixed. The carousel transform may scale the centered card to read forward.
- Compute card state from normalized center offset. Drive x position, scale, `rotation3DEffect`, opacity, z-index, shadow, optional blur, and photo-window display/backlight intensity from that offset.
- Carousel lighting must be a presentation-layer treatment of the slide/photo window only. Do not recolor, retone, resaturate, contrast-adjust, or mutate the thumbnail image pixels to make the centered card brighter.
- Non-centered card images should read dimmer through reduced photo-window display/backlight intensity or a neutral overlay, preserving the image's underlying color/tone.
- Rotation sign matters: left-side cards rotate right/toward center; right-side cards rotate left/toward center.
- Keep each central photo window at a fixed height; compute its width from the loaded reference photo aspect ratio with min/max clamps.
- Drive medium impact haptics from centered-card changes.
- Place the selected-roll title/metadata region above the slide carousel in a reserved-height block. Keep the title top inset slightly lifted from the raw carousel inset, then derive the title-to-carousel spacing from available height so the centered slide card's center lands 20 pt below the available viewport center. Do not use an extra carousel/page-dot vertical offset. Keep page dots below the card.
- For the no-roll empty state, reuse the same reserved title block and card-center math: `Create your first Film Roll` sits above the blank reversal-slide card, and the blank card occupies the same position as the centered card in the saved-roll carousel.
- Do not render a Home bottom tab bar or Preview LUT button.
- Respect safe areas and Dynamic Island.

Detail:

- Use a full-screen-feeling film viewer/projector composition.
- Keep the title/metadata at the top, render the current reference or processed photo directly as a center projected frame without a white backdrop, and place the film transport at the bottom.
- Put `Export .cube` and Add Photo as circular icon buttons in the top-right header row beside the three-dot menu. Do not render them in the roll-title row and do not render the old bottom safe-area action bar.
- The center projection should use a large adaptive container with aspect-fit image presentation, so portrait and landscape frames maximize either width or height without cropping. The container reserves a taller-than-wide layout region while keeping the same horizontal inset, but it must not draw a visible background block or stroke.
- Render the bottom film as the roll's existing photos only: reference frame first, then processed frames. Add a short leader before the first frame and a matching trailer after the last frame.
- Use transparent light and dark image assets for a two-layer square light-box viewer rather than drawing the body from SwiftUI rectangles. The back layer is a larger square labeled frame with `LUMOROLL` and `LIGHT BOX`; it must be large enough that the bottom labels stay visible below the front viewer. The front layer is a smaller square viewer block with corner screws and no text labels; keep its current size/aperture proportion and source its light-mode treatment from the provided true-transparent realistic molded-plate front-block image. The dark-mode front block is derived from that same source image with a warm charcoal remap so the screw relief and molded edge detail stay consistent. The moving film strip must render between those layers: back frame first, film second, front viewer last.
- The viewer assets must not include a translucent gray bounding box or shadow halo. Pixels outside the outer plate shape and inside the view window are fully transparent, while the plate material itself is opaque enough to cover the moving film.
- Do not render a separate enlarged photo inside the view finder. The selected film cell itself passes under the front viewer aperture at the same fixed height as the film strip, and only the selected cell avoids the inactive film-cell dim overlay so it stays bright under the viewer.
- Make the front viewer aperture slightly taller than the film photo cell, so the display opening has a little more vertical room while the film photo itself remains unchanged.
- Position the projector layers and film in the lower half of the page, lifted 40 pt from the previous shared film/viewer placement. The selected film-frame snap target uses a light `-12 pt` left optical correction under the layered asset so the selected cell reads centered below the fixed front viewer aperture without drifting left; the black film body/sprockets remain behind the front viewer and above the labeled back frame.
- Fill any unused area visible through the fixed view-finder aperture with the same black tone as the film body, from the film cell/background rather than a separate projected thumbnail.
- Dragging the bottom film moves the film content under a fixed center projector body. On drag end, preserve the release offset while changing the selected frame, then animate only the remaining translation to zero; do not let drag state reset to the old frame center before the snap. Snap by photo frame, update the center projection, and fire a medium haptic when selection changes. Individual film frames should not be tap targets.
- Move sprocket holes, photo frames, black film body, and finite film edges together as one film object; do not draw full-viewport black film outside the moving content. Align the moving film content from the viewport leading edge before applying snap offsets; do not let SwiftUI center the fixed-width film content, because that shifts the selected frame away from the fixed viewer when content width exceeds viewport width.
- Render the center projected photo and bottom projector transport inside the same full-screen-width visual viewport. Offset that viewport left by the Detail page's horizontal content padding so both photo and projector are centered on the physical screen, while the title block stays aligned to the padded content column. Do not show a `Sample` or `Frame xx` label above the center projected photo.
- Expand the film transport viewport horizontally through the Detail content padding so clipping happens at the screen edges rather than at the padded content column.
- Do not render a projected light beam or cone.
- Film-strip photos use fixed heights and widths derived from loaded image aspect ratios. Strongly dim inactive film-strip thumbnails with a 0.65 neutral black overlay so they read as physical film cells rather than the active preview; the selected film frame under the viewer keeps full brightness. The compact square projector view finder is a mask/frame over the same moving film content, not an independent image renderer.
- Do not wrap the Detail page in a vertical `ScrollView`.

Apply:

- Use a centered Import target panel as the primary control before target selection.
- Tapping the panel presents a source choice for Photo Library or Files.
- When Detail has already supplied the source choice, present that selected native importer once on Apply entry.
- After target selection, show Before/Split/After preview, intensity, and bottom `Save` / `Cancel`.
- Do not show temporary diagnostic Post/LUT buttons in the selected-target editor.
- Do not auto-save selected targets.
- Do not show Save to Photos in this Apply flow.

Fullscreen:

- Use a dark full-screen cover or navigation destination.
- Use paging/swipe behavior within the roll.
- Do not support pinch zoom or two-finger pan in the current photo preview; horizontal swipes should stay dedicated to frame paging.
- Reserve the processed-frame action row height for reference/sample frames with hidden, inaccessible placeholders to avoid vertical layout shifts during paging.
- Keep bottom actions inside the safe area.

## Components

Prototype CSS components map approximately to:

- `PillButton`: SwiftUI `Button` with capsule style.
- `IconButton`: circular SwiftUI `Button`.
- `PaletteRow`: horizontal stack of circles.
- `FilmStrip`: horizontal `ScrollView` whose frames and sprocket rows move together.
- `FilmFrame`: tappable thumbnail in a fixed-size frame.
- `Toast`: transient overlay plus VoiceOver announcement.

## Native Controls

Prefer native components for:

- Photos import.
- File import/export.
- Share.
- Menus.
- Alerts and confirmation dialogs.
- Sliders where possible.

Custom drawing is appropriate for:

- Film cartridge card treatment.
- Film strip sprocket pattern.
- Split comparison overlay.
- Palette swatches.

## Accessibility Hooks

- Every icon-only button needs an accessibility label.
- Palette rows should have a concise accessibility label, not raw color values.
- Film frames should announce sample/reference or processed frame number.
- The intensity slider should announce percent and effect.
- Split preview should provide alternatives for VoiceOver users, such as Before/After segmented mode.

## Prototype Mismatches To Correct

- Show `33x33x33`, not `32x32x32`.
- Prevent saving unnamed rolls.
- Use LumoRoll capitalization.
- Remove/defer prototype-only search, duplicate, fullscreen Save to Photos, and fullscreen More.
- CSS `filter()` recipes are visual stand-ins, not LUT implementation guidance.

## Documentation Update Note

Created to guide native SwiftUI design translation for MVP1.

## Task 7A Mapping Note

Task 7A implements the mapping as reusable components only, not feature screens or navigation.

- Domain palette data maps through `LumoTheme.paletteColor(for:)` and `paletteHex(for:)`.
- Photo display maps through injected `Image` values in `LumoPhotoDisplayData`; views do not read file paths.
- Film strip ordering is centralized in `FilmStripItem.orderedItems`, which returns reference/sample first, processed frames next, and add-photo last.
- Apply preview controls use `LumoPreviewMode` (`Before`, `Split`, `After`) so feature screens can map from their own state without coupling the design system to feature models.
- `SplitPreview` owns no feature state; feature screens pass a `Binding<CGFloat>` for the comparison line. Drag updates are clamped to the preview bounds, and VoiceOver users can adjust the same value with the adjustable action.

## Task 7B Mapping Note

Task 7B wires reusable components into feature screens without adding Task 8 system adapters.

- `FilmRollDisplayData` maps domain `FilmRoll` values to screen-ready text, palette, and `LumoPhotoDisplayData` placeholders. It never reads file paths or decodes local images.
- `FilmRollViewerFrame.frames(for:)` centralizes fullscreen ordering: reference sample first, processed frames after.
- The app shell owns route state as small IDs in `AppRoute`, with fullscreen presentation using an item route that carries the already loaded roll and start index.
- Screens keep image placeholders until Task 8 supplies decoded thumbnails/images through the display-data boundary.
- Pending Task 8 system-boundary adapters in the live app are inert/failing, not fake-success. Create import closures do not inject placeholder reference bytes, apply starts without a fake target, and create/apply/export adapters throw domain errors if accidentally reached before real importer, renderer, writer, and exporter wiring exists.
- `ApplyTargetPhotoTile` describes target-strip tiles that all route to the injected import-target boundary. Task 7B uses that boundary only to surface unavailable import state; it does not select a fake target.
- Fullscreen action availability keeps reference frames view-only and exposes processed-frame Share/Edit/Remove actions only.

## Task 8B2 Mapping Note

Task 8B2 extends display data with local image path metadata instead of embedding decoded images in Domain models.

- `LumoPhotoDisplayData` may carry a thumbnail path and a full-size display path.
- `FilmRollDisplayData` maps reference thumbnails for Library/Detail and reference originals for Fullscreen.
- Processed photos map thumbnail paths for Detail and processed render paths for Fullscreen.
- SwiftUI image rendering uses a shared app-layer display store backed by `LocalPhotoImageLoader`; views keep placeholders while `.task(id:)` loads.
- PhotosUI and `.fileImporter` stay in SwiftUI screens/hosts only.
