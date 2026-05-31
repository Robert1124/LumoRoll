# Film Strip

## Purpose

Display a horizontal continuous film-inspired strip of frames, with the reference sample first and processed photos after it.

## Inputs

- Ordered frame view models.
- Frame selection action.
- Add-photo action.
- Visual mode for light/dark context.

## Outputs

- Scrollable strip.
- Sample frame badge.
- Processed frame labels if needed.
- Add-photo tile.
- Frame selection intents.

## Data Dependencies

- Thumbnail images.
- Frame IDs.
- Sample/processed flag.

## Relationship To Other Modules

- Reusable visual component in DesignSystem.
- Available for reusable preview strips and future secondary scrubbing contexts.
- Current Film Roll Detail uses a custom bottom projector transport instead of this generic `FilmStrip`.
- Receives prepared display data from Features.
- Does not load files directly.

## State Management

Mostly stateless. Optional view-local scroll position can remain inside the view unless feature restoration needs it.

The top and bottom sprocket rows are part of the same horizontal scroll content as the frames. When the user swipes the strip, frames and sprocket holes move together rather than leaving the holes fixed to the viewport.

Sprocket slots are generated from the actual available strip/content width instead of using only the preset count. The preset count remains a minimum, but wider detail strips and aspect-adaptive photo frames produce enough holes to span the visible film edge.

Sizing:

- `standard` is for compact repeated usage.
- `detail` is a larger reusable preset retained for high-quality strip contexts. It uses a taller strip, requests a higher display pixel dimension, and prefers the app-owned full-size display path over the thumbnail path.
- Detail-sized photo frames render complete images with fit content mode. Each frame keeps the same height while its width follows the loaded image aspect ratio. The add-photo tile keeps the preset fallback width when this component is used with add-photo enabled.
- Before an image aspect ratio is available, a frame uses the preset fallback width so loading can start from a stable placeholder. Width may adjust after the display store publishes the decoded aspect ratio.

## Error States

- Missing thumbnail: show placeholder frame.
- Very large frame count: lazy horizontal rendering should be used during implementation.

## Empty States

Minimum valid state depends on the caller. Generic creation flows may use one sample frame plus add-photo tile; Film Roll Detail's projector transport uses the existing frames only, and the projector plus affordance is currently hidden.

## Future Extension Points

- Scrubber index.
- Drag reorder if product adds organization.
- Lazy thumbnail prefetching.

## Detail Relationship Update

Film Roll Detail no longer renders this generic `FilmStrip` as its primary content. It uses a projector-specific bottom transport whose film contains the reference sample and processed photos only. This component's `detail` sizing remains available for future high-quality strips and avoids loading original-resolution images by routing display paths through the display store's `imageMaxPixelDimension`.
