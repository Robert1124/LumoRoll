# Fullscreen Viewer Flow

## Purpose

Provide an immersive dark viewer for browsing the reference sample and processed photos inside one Film Roll.

## Flow

1. User opens Film Roll Detail.
2. User taps the reference sample or a processed frame.
3. Fullscreen Viewer opens at the tapped item.
4. User swipes horizontally to move between frames.
5. User closes the viewer to return to Film Roll Detail.
6. On a processed frame, user may share, edit intensity, or remove the frame.

## Inputs

- Selected Film Roll.
- Start frame: reference sample or processed photo index.
- Current frame for Share/Edit/Remove actions.

## Outputs

- No data change from browsing.
- Optional system share sheet for the current processed frame.
- Optional Edit route for the current processed frame.
- Optional removal of the current processed frame after confirmation.
- No Film Roll mutation from browsing alone.

## MVP1 Behavior

- The reference sample appears first.
- Processed photos appear after the sample in saved order.
- Viewer uses a dark immersive treatment.
- Swipe navigation is horizontal within the current Film Roll only.
- The photo preview does not support pinch zoom or two-finger pan in MVP1.
- Close returns to Film Roll Detail.
- Processed frames expose bottom `Share`, `Edit`, and `Remove` actions.
- The reference sample is view-only in Fullscreen Viewer for MVP1; Share, Edit, and Remove are unavailable on that frame.
- Share presents the system share sheet for the app-owned processed render file and does not request Photos permission.
- Edit closes the viewer and opens the Apply intensity flow using the stored original path and current intensity for that processed photo.
- Saving from that edit flow replaces the existing processed photo record instead of appending a duplicate.
- Remove shows a confirmation dialog before deleting the processed photo from the Film Roll.
- The top-right ellipsis and bottom `More` action are not shown.
- Reference/sample frames reserve the processed-frame action-row space without showing action buttons, so paging does not shift the image or page indicator.

## Dependencies

- Film Roll Detail provides the selected frame.
- Local persistence provides image assets.
- No Photos write permission is requested from the current Fullscreen Viewer.
- Future Photos actions must be added as explicit visible actions.

## Empty and Error States

- Empty Film Roll still has the reference sample available.
- Missing frame asset: show a recoverable error placeholder and allow closing.
- Processed frame missing its display asset: keep the image placeholder, make Share unavailable, and still allow Remove when the manifest record exists.
- Remove failure: keep the viewer open and show recoverable failure copy.
- Edit target missing at render time: Apply shows the existing render/import failure state and allows backing out.

## Future Extension Points

- Frame metadata.
- Favorite or cover selection.
- Pinch zoom or pan if product later chooses freeform image inspection.
