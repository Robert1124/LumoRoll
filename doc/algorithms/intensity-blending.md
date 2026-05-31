# Intensity Blending

## Purpose

Define the non-destructive intensity behavior for applying a Film Roll. Intensity controls how much of the LUT output is mixed with the original image.

## Inputs

- Original image.
- LUT-processed image.
- Intensity value from Domain rendering requests, expected range `0...100`.
- Rendering converts the Domain percentage to a render fraction in `0.0...1.0`.

## Output

- Blended image used for preview, save, and share.

## Formula

For each pixel channel:

```text
output = original * (1 - intensity) + processed * intensity
```

At `0.0`, output equals the original image. At `1.0`, output equals the full LUT-processed image.

Current implementation detail:

- `CoreImageRenderer` clamps the public intensity percentage to `0...100`.
- The clamped percentage is divided by `100` before blending.
- The renderer uses a constant grayscale Core Image mask with `CIBlendWithMask` to mix the original and LUT-processed images.
- Alpha is blended through the same mask so semi-transparent pixels stay semi-transparent instead of becoming opaque.
- The blended output is cropped back to the prepared original extent.

## Core Decision

Intensity must not regenerate, mutate, or save a new LUT. It is render state for a specific preview or processed output.

This keeps one Film Roll stable across multiple photos while still letting users choose a softer or stronger result per output.

## Rendering Behavior

- Preview changes should update quickly using downsampled images.
- Save/share should render with the selected intensity at the requested output size.
- The saved Film Roll LUT remains unchanged after a processed photo is saved.
- If the user returns to a saved processed photo, stored metadata may record the intensity used for that output.
- Rendering never mutates or regenerates the `LUT3D`; tests cover LUT value immutability during blending.

## State Management Logic

The apply screen owns temporary intensity state. A processed result may persist the chosen intensity as output metadata, but the Film Roll LUT data remains immutable.

## Edge Cases

- Clamp intensity below `0` to `0`.
- Clamp intensity above `100` to `100`.
- If original and processed images differ in extent, crop or align to the normalized render extent before blending.
- If alpha is present, preserve alpha consistently and avoid introducing opaque pixels where the original was transparent.

## Error States

- Original image missing.
- Processed image missing because LUT application failed.
- Image extents or pixel formats cannot be aligned.

## Future Extension Points

- Per-output default intensity.
- Film Roll suggested intensity.
- Separate blend modes, if product scope expands.
- Masked intensity for local adjustments outside MVP1.

## Documentation Updates Completed

This document records the intensity formula, Domain percentage conversion, Core Image blend implementation, immutability rule, render state boundaries, and edge cases.
