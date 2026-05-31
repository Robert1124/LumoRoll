# Before / Split / After Preview

## Purpose

Show the source photo, rendered LUT result, or an interactive split comparison during Apply Photo.

## Inputs

- Original preview image.
- Processed preview image or render handle.
- Preview aspect ratio derived from the loaded image when available.
- Mode: before, split, after.
- Split position.
- Intensity display value.
- Roll name for labeling.

## Outputs

- Visual preview.
- Split drag changes.
- Mode changes if segmented control is included nearby.

## Data Dependencies

- Preview-sized original image.
- Preview-sized processed image.
- Current render status.

## Relationship To Other Modules

- UI component in Features or DesignSystem.
- Gets images from Apply Photo feature model.
- Processing creates rendered assets.
- Does not run Core Image work.

## State Management

View-local:

- Split position.
- Gesture state.

Feature model:

- Rendered preview availability.
- Failed/loading state.

## Error States

- Missing original.
- Processed preview still rendering.
- Render failure with retry action.

## Empty States

If no photo is selected, the Apply Photo Flow owns the empty import state. If rendering is pending, show the original with a processing indicator rather than a blank area.

## Task 10 UI Fix Note

The preview container uses the loaded target/processed preview image aspect ratio instead of a permanently fixed `3:4` frame. The Apply screen may cap preview height to keep the title toolbar, preview control, preview, intensity slider, and save actions visible without scrolling, but it should preserve the image aspect ratio by narrowing tall previews rather than changing their ratio. If no image dimensions are available yet, it falls back to the standard `3:4` placeholder ratio.

## Future Extension Points

- Pinch zoom/pan.
- Histogram or clipping warnings if later needed.
- Higher-quality deferred final render after fast preview.
