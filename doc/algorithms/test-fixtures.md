# Test Fixtures

## Purpose

Define a deterministic fixture strategy for validating MVP1 reference analysis, LUT generation, Core Image application, intensity blending, `.cube` export, and performance edge cases.

## Fixture Categories

Use generated fixtures where possible so tests do not depend on copyrighted photos or external network downloads.

Recommended fixtures:

- Identity gradient image.
- Neutral gray ramp.
- RGB channel ramps.
- Saturation wheel or synthetic color grid.
- Warm cast image.
- Cool cast image.
- Low-contrast image.
- High-contrast image.
- Mostly black image.
- Mostly white image.
- Near-monochrome image.
- Small image, such as `16x16`.
- Large synthetic image.
- Wide panorama-like synthetic image.
- Transparent image with valid non-transparent content.
- Fully transparent image for failure behavior.

## Analysis Tests

Validate that reference analysis:

- Produces deterministic descriptor values for the same input.
- Handles downsampled and native-size paths.
- Records warnings for low-confidence images.
- Ignores fully transparent pixels.
- Falls back to sRGB assumptions when metadata is missing.

Expected values should use tolerances because resize and color conversion implementations may differ slightly by platform.

## LUT Generation Tests

Validate that LUT generation:

- Produces exactly `33 * 33 * 33` samples.
- Stores Float32 RGBA values.
- Uses alpha `1.0`.
- Produces finite RGB values.
- Clamps RGB values to `[0, 1]`.
- Is deterministic for a fixed descriptor and algorithm version.
- Does not change when intensity changes.

## Rendering Tests

Validate that rendering:

- Applies identity-like LUTs without unexpected color shifts.
- Produces expected directional changes for warm/cool fixtures.
- Uses preview downsampling for preview paths.
- Uses full-resolution only for save/share paths.
- Handles decode/render failures without corrupting stored Film Rolls.

## Intensity Tests

Validate the blend formula:

- `0.0` equals original.
- `1.0` equals processed.
- `0.5` equals midpoint within tolerance.
- Values below `0.0` and above `1.0` are clamped.
- LUT data remains unchanged after intensity changes.

## Cube Export Tests

Validate that exported `.cube` files:

- Include `TITLE`.
- Include `LUT_3D_SIZE 33`.
- Include `DOMAIN_MIN 0.000000 0.000000 0.000000`.
- Include `DOMAIN_MAX 1.000000 1.000000 1.000000`.
- Write exactly `35937` data lines.
- Use the documented red-fastest ordering.
- Use fixed decimal precision.
- Can be parsed back into the same RGB values within formatting tolerance.

## Performance Tests

Once implementation exists, measure:

- Reference analysis time for typical and large photos.
- Preview render latency.
- Full-resolution render time.
- Peak memory during large image decode and render.
- `.cube` export time and file size.

## Fixture Storage

Fixture file location should be chosen once the Xcode project exists. Until then, this document defines the required fixture set and expected behaviors.

## Future Extension Points

- Golden image snapshots for UI preview.
- Compatibility imports into common LUT tools.
- Device matrix performance baselines.
- HDR/P3/Log fixtures for MVP2.

## Documentation Updates Completed

This document records the algorithm test fixture strategy and expected validation coverage for MVP1.
