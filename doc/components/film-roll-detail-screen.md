# Film Roll Detail Screen

## Purpose

Show one Film Roll, its reference sample, processed photos, the bottom film viewer/projector transport, roll management actions, and the `.cube` export action.

## Inputs

- Film Roll ID from navigation.
- Loaded Film Roll detail.
- Export `.cube` action.
- Rename action.
- Remove Film Roll action.
- Frame selection action for fullscreen viewer.

## Outputs

- Title and metadata.
- Top-right circular icon actions for `Export .cube`, Add Photo, and More.
- Large adaptive center projected frame with reference sample first and processed frames in saved order. The image uses aspect-fit behavior inside the large display container so either width or height fills without cropping, and the center projection does not show a top `Sample` / `Frame xx` caption.
- Larger bottom film transport whose film contains the roll's existing photos plus a short leader before the first photo and a matching trailer after the last photo.
- Fixed bottom-center light-box view finder in a warm light hybrid style matching the reference image. The view finder is split into two transparent asset layers: a larger square back frame with `LUMOROLL` / `LIGHT BOX` labels and a smaller square front viewer block with corner screws. The front viewer block keeps the current size and live aperture proportion, uses the provided true-transparent realistic molded-plate front-block source image in light mode, and uses a dark variant generated from that same source image. The back frame is intentionally larger than the front viewer so the bottom labels remain visible. The moving film strip renders between those layers, so the back frame is visually behind the film and the front viewer covers the film. The view finder no longer renders a separate enlarged image; the selected film cell itself passes under a slightly taller front aperture at the same size as the film-strip cell. The Add Photo button is temporarily hidden on the body.
- Top-right menu with Rename and Remove.
- Fullscreen viewer intent.

## Data Dependencies

- Roll metadata.
- Reference thumbnail/original.
- Processed photo thumbnails and processed full-size display paths.
- LUT export availability.

## Relationship To Other Modules

- Owned by Features.
- Uses buttons, palette row, display image loading, and film-inspired transport components.
- Calls Domain use cases through feature model.
- Does not render images or serialize LUTs directly.

## State Management

Feature model:

- `FilmRollDetailFeatureModel.State`: `idle`, `loading`, `loaded(FilmRoll)`, or `failed(String)`.
- `ExportState`: `idle`, `exporting`, `ready(ExportLUTResult)`, or `failed(String)`.
- `ManagementState`: `idle`, `renaming`, or `removing`.
- Duplicate load/reload calls are ignored while `loading`.
- If a reload fails after content is loaded, the previous `loaded(FilmRoll)` state is preserved and `lastErrorMessage` carries the refresh error.
- Duplicate export calls are ignored while `exporting`.
- Rename trims and validates the new name, saves the updated Film Roll, updates loaded state, and records failures in `lastErrorMessage`.
- Remove deletes the Film Roll through the repository and emits a removed intent so root navigation can pop back and refresh Library.
- Selected fullscreen frame route.

View-local:

- No vertical page scroll state; the Detail page is a fixed viewport with top-right export/add/menu icons, a center projection, and bottom film transport.
- The bottom safe-area export/add action bar is not rendered. Export and Add Photo are owned by the top-right header icon cluster beside the More menu.
- The center projected photo and bottom film transport share a full-screen-width visual viewport that is offset left by the Detail page's horizontal padding. This keeps the projection image and fixed light-box view finder centered on the physical screen instead of the padded content column.
- The bottom film transport viewport expands through the Detail page's horizontal padding, so the moving film can travel to the screen edges before clipping. The finite black film body still belongs to the moving film content and does not fill outside its actual leader/frame/trailer bounds. Inactive film-cell thumbnails use a 0.65 neutral dim overlay; the selected film cell skips that overlay so it remains bright under the front viewer.
- The fixed light-box view finder layers use a light `-12 pt` left optical correction for the selected film-frame target so the visible selected cell reads centered under the front aperture without drifting left. The back frame renders first, the moving film renders second, and the front viewer block renders last. Viewer assets have fully transparent outside/window cutouts with opaque plate material, so there is no translucent gray bounding border and the film does not show through the plate. The visible selected cell is the actual film-strip frame passing through the viewer, not a duplicated projected thumbnail.
- The fixed light-box aperture shows the moving film cell and the film-black background where the photo does not fill the aperture.
- Drag state is owned as view-local state so release snapping can preserve the final finger offset across selected-frame changes. The selected frame changes without animation first, then the remaining drag translation animates to zero; this avoids a visible rewind to the previous frame center.
- Lightweight menu presentation state.
- Top-right export/add/menu icon presentation.

## Error States

- Roll missing.
- Asset missing.
- Export failed.
- Rename validation or save failed.
- Remove failed.
- Apply flow unavailable.

## Empty States

If there are no processed photos, the projected frame and bottom film still show the reference sample. No explanatory small text is shown below the transport. The projector Add Photo button is temporarily hidden, and adding a new processed photo is available from the top-right Add Photo icon beside `Export .cube` and the More menu.

## Future Extension Points

- Notes editing.
- Per-roll settings.
- Usage history.

## Task 7B Implementation Note

`FilmRollDetailScreen` uses `FilmRollDisplayData` and `FilmRollViewerFrame.frames(for:)` so the reference sample always appears first and processed frames follow in saved order. The menu does not expose a separate Apply Photo action in MVP1. `.cube` export calls the existing export feature model state.

## Task 8B2 Implementation Note

Detail viewer frames carry thumbnail and full-size paths. The reference sample remains first and processed thumbnails follow in saved order. Loading is delegated to the shared display image store. Film and projector-window photos keep fixed heights and derive their widths from the loaded image aspect ratio.

## Task 10 Detail Layout Note

The detail screen treats the film viewer/projector as the primary object on the page. It removes the standalone `Import Photo` panel and labels the export action `Export .cube`. The projector Add Photo affordance is deferred and hidden; the top-right header exposes Add Photo as a neighboring circular icon beside export and the More menu.

Follow-up: the showcase strip was enlarged again for the LUT detail page. `Export .cube` / Add Photo moved from the bottom safe-area row to circular icon actions, now grouped in the top-right header beside the More menu. Export status and file-export errors stay in the Detail content status area. The center projected image uses a taller-than-wide layout container without drawing a visible background block.

## Detail Add Photo Source Update

The projector Add Photo affordance remains hidden. The top-right Add Photo plus button presents the same source choice for Photo Library or Files.

The projector transport renders reference and processed photos as complete images. Each film photo keeps a common height and derives its width from the loaded image aspect ratio. The film line and fixed view finder sit in the lower half of the page, lifted 40 pt from the previous shared placement. The view finder body uses transparent light and dark layered assets: a labeled back frame behind the moving film and an unlabeled front viewer block above it. The selected frame remains the same size as the film-strip cell and stays bright under the viewer.

## Current Management Note

The detail top-right header exposes `Export .cube`, Add Photo, and a menu in one trailing icon cluster. The menu itself contains only `Rename` and `Remove`. Rename uses a system alert with a text field seeded from the current loaded roll name. Remove uses a destructive confirmation dialog and only deletes after explicit confirmation. Successful removal returns to Library via the root pending-intent handler.

## Current Interaction Note

The Detail page no longer uses a vertical `ScrollView`; title, metadata, top-right export/add/menu icons, center projection, and bottom film transport stay in one fixed viewport. The loaded state now uses a film viewer/projector composition: the current reference or processed frame is shown inside a large adaptive display container without cropping, while the bottom film strip moves horizontally through a fixed two-layer light-box view finder. The center projection and bottom projector transport use the same full-screen-width visual viewport and cancel the page padding with a leading offset, keeping both centered on the physical screen. The view finder uses dark variants for both asset layers in dark mode. Dragging the film left or right snaps to the nearest photo frame, updates the center projection, and fires a medium selection haptic when the current frame changes. The release snap preserves the user's release offset through the selected-frame change, then animates to the new snapped position from there. Film frames are not tap targets; selection changes come from dragging the transport. The transport viewport reaches the screen edges, while the sprocket holes, photo frames, black film body, and finite film edges move together as one film object from an explicit full-screen-width leading frame, so no black strip or sprocket holes appear outside the actual film content and the selected frame remains centered below the fixed view finder. A short leader before the first frame and matching trailer after the last frame make the film feel finite. No projected light beam is rendered.
