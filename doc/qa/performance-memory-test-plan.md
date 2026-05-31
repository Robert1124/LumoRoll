# Performance and Memory Test Plan

Status: updated after Task 9 implementation audit on 2026-05-24.

## Purpose

Verify that LumoRoll can import, analyze, preview, apply, save, and export photo-based Film Rolls without excessive memory use, crashes, or unacceptable latency on the supported iPhone matrix.

## Risk Areas

- Large source images.
- Multiple Core Image intermediates.
- 33x33x33 LUT generation and application.
- Full-resolution output rendering.
- Thumbnail generation.
- Repeated imports and exports.
- Temporary file cleanup.
- Older devices with lower memory ceilings.
- Save to Photos denial after a full temporary render has already been created.
- Crash or termination between temporary render creation and cleanup.

## Current Implementation Notes

- Reference analysis downsamples to a 128-pixel long edge for pixel sampling, but it currently creates a `CGImage` from the full input before downsampling.
- Display image loading uses ImageIO thumbnail creation and caps display output at 4,096 pixels on the long edge.
- Thumbnail rendering is capped at 512 pixels on the long edge.
- Apply and Save to Photos render the processed output at full source resolution before JPEG encoding.
- Core Image uses an sRGB working/output color space and creates a Metal-backed `CIContext` when Metal is available.
- Import staging loads selected image data into memory and copies the full selected file into app-owned storage. There is no explicit pixel-count or file-size rejection threshold yet.

## Image Set

Test with:

- Small image around 1 MP.
- Typical phone image around 12 MP.
- Large image above 24 MP where available.
- Very wide panorama.
- Tall portrait image.
- HEIC, JPEG, and PNG.
- Bright, dark, low-contrast, and high-saturation photos.

## Measurements

Record on real devices:

- Time to load selected reference image.
- Time to generate LUT.
- Time to render apply preview.
- Time to adjust intensity preview.
- Time to save processed output into Film Roll.
- Time to save processed output to Photos.
- Time to export `.cube`.
- Peak memory during create flow.
- Peak memory during apply flow.
- Storage growth after repeated saves.
- Temporary storage after canceled and completed exports.

## Pass Criteria

Final thresholds should be set once implementation exists. Initial qualitative criteria:

- No crash on the oldest supported device during typical 12 MP workflows.
- Large image workflows degrade gracefully with progress, downscaling, or recoverable failure.
- Intensity adjustment is interactive because it blends original and LUT-processed output rather than regenerating the LUT.
- App remains responsive enough to cancel or recover from long-running work.
- Repeated exports do not leave unbounded temporary files.

## Stress Scenarios

- Create 50 Film Rolls with thumbnails and generated LUTs.
- Save 20 processed outputs into one Film Roll.
- Export the same `.cube` repeatedly.
- Apply a Film Roll to multiple photos in sequence.
- Background the app during processing.
- Receive memory pressure during large-image processing where test tools allow.
- Delete Film Rolls after large storage growth and verify app-managed files are removed.

## Instrumentation Follow-Up

- Xcode memory graph or Instruments allocation profiling.
- Signposts or lightweight timing logs for processing stages.
- Manual storage inspection of app container before and after stress tests.
- A crash-recovery storage check for stale `tmp/imports` folders and unmanifested processed folders.
