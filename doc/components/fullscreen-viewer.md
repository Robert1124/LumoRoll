# Fullscreen Viewer

## Purpose

Provide an immersive dark photo viewer for browsing the reference sample and processed photos inside one Film Roll.

## Inputs

- Film Roll ID.
- Starting frame ID.
- Ordered frames with image references.
- Close action.
- Frame-aware share/edit/remove action availability.

## Outputs

- Fullscreen image browsing.
- Swipe navigation.
- Share sheet presentation for the current processed frame.
- Edit intent for the current processed frame.
- Remove intent for the current processed frame with confirmation and local status copy.

## Data Dependencies

- Reference original or display-sized image.
- Processed output images.
- Frame labels.
- Current roll name.

## Relationship To Other Modules

- Owned by Features with visual primitives from DesignSystem.
- Presented through item-based fullscreen cover.
- Root wiring resolves app-owned processed image paths for Share, opens Apply with an edit context for Edit, and delegates processed-photo removal through `RemoveProcessedPhotoUseCase`.
- Does not write to Photos directly.
- Presents Share only through an explicit processed-frame Share action.

## State Management

View-local:

- Current visible frame index.
- Unavailable action message, if the user reaches a disabled/pending action state.
- Remove confirmation and remove status message.
- Processed-frame action bar layout reservation. Reference/sample frames do not expose Share/Edit/Remove controls, but reserve the same bottom action-row space with hidden, inaccessible placeholders so paging between sample and processed frames does not move the image, page dots, or bottom layout.
- No local zoom or pan state. The fullscreen photo preview is static inside the paging frame; horizontal swipes remain dedicated to frame navigation.

Feature model:

- Loaded frame list.
- Share/edit/remove availability for the current processed frame.
- Missing asset errors.

## Error States

- Starting frame not found.
- Image asset missing.
- Share unavailable when the processed frame has no rendered file path.
- Remove failure.
- Reference frame selected: management actions are unavailable because the sample is view-only in fullscreen.

## Empty States

Minimum valid data is the reference sample. If no processed photos exist, viewer can still show the sample.

## Future Extension Points

- Pinch zoom or pan if product later chooses freeform image inspection.
- Metadata overlay.

## Task 7B Implementation Note

`FullscreenViewerScreen` uses a dark `TabView` pager and `FilmRollViewerFrame.frames(for:)` so the reference sample is the first frame. The older Close, Save, Share, and More action set has been replaced by processed-frame management actions.

## Task 8B2 Implementation Note

Fullscreen frames now carry full-size display paths: the reference frame uses the reference original, and processed frames use the processed render path. The viewer asks the display image store for a bounded fullscreen-sized image and keeps the dark unavailable placeholder if loading fails.

## Task 8C Decision Note

Task 8C previously made fullscreen output actions frame-aware. The current management pass supersedes that action set for Fullscreen Viewer:

- Reference sample: Share, Edit, and Remove are unavailable.
- Processed frame: Share opens the system share sheet for the app-owned processed image file.
- Processed frame: Edit opens the Apply intensity editor for that stored photo.
- Processed frame: Remove shows a confirmation dialog, updates the Film Roll manifest, and discards the removed photo assets through the renderer cleanup path.

## Current Implementation Note

The top-right ellipsis is removed. The bottom action bar for processed frames contains `Share`, `Edit`, and `Remove`. Reference/sample frames reserve that action-row space invisibly but do not expose action controls. Share resolves the processed render path through app storage and presents SwiftUI `ShareLink`; it does not request Photos permission or create a Photos library write. Edit passes the stored `ProcessedPhoto` ID, original path, and intensity into Apply so saving replaces that frame instead of appending a duplicate. Remove confirms first, calls the root removal closure, updates the viewer's local Film Roll on success, and asks the root to refresh Detail and Library.

Current viewer interaction follow-up: fullscreen frames no longer support pinch zoom or two-finger pan. The image remains fitted inside the dark paging frame, so swipe navigation stays predictable and the close, page indicator, and processed-frame actions remain stable.
