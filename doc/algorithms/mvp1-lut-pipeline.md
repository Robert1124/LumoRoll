# MVP1 LUT Pipeline

## Purpose

Define the end-to-end image-processing pipeline for LumoRoll MVP1. The pipeline turns one user-selected reference image into a reusable Film Roll LUT, applies it to photos, previews the result, saves processed outputs, and exports the LUT as a `.cube` file.

## Scope

MVP1 supports photos only. The pipeline is local, deterministic, traditional image processing. It does not use networking, cloud processing, video, HDR, Log workflows, Display P3 advanced handling, or network AI.

## Inputs

- One reference image selected by the user for Film Roll creation.
- User-provided Film Roll name, required before saving.
- Target photos selected later for applying the Film Roll.
- User-selected intensity value for preview and output blending.

## Outputs

- Reference image copy stored inside the app.
- Generated 33x33x33 LUT stored as Float32 RGBA cube data.
- Film Roll metadata, including name, creation date, algorithm version, source color assumption, and preview thumbnail references.
- Processed preview images for UI.
- Full-resolution processed photos when the user saves or shares.
- `.cube` export file when the user chooses export.

## Pipeline Stages

1. Import the reference image with PhotosUI or file import.
2. Decode and normalize the image into the MVP1 working assumption: SDR sRGB / Rec.709.
3. Downsample the reference image for analysis.
4. Analyze the downsampled image into a compact deterministic style descriptor.
5. Generate a 33x33x33 identity RGB cube.
6. Apply Algorithm V2's bounded percentile tone, tonal-zone color balance, hue-selective saturation, and neutral/skin-hue soft protection to each cube sample.
7. Clamp transformed cube values to `[0, 1]`.
8. Store Float32 RGBA cube data for Core Image.
9. Save the reference image, LUT data, metadata, and thumbnails inside app storage.
10. Apply the LUT to target photos through Core Image.
11. Blend original and LUT output for intensity preview and save.
12. Export `.cube` text from the stored LUT when requested.

## Data Dependencies

- Product/UX defines when images are selected, named, saved, shared, or exported.
- Architecture/storage defines the persisted Film Roll record and file layout.
- Core Image rendering consumes the stored LUT and target image.
- `.cube` export consumes the same generated LUT values used for rendering.

## State Management Logic

The generated LUT is immutable after the Film Roll is saved. Intensity is preview/output state, not LUT state. Changing intensity recomputes only the blend between original and processed image.

## Error States

- Reference image cannot be decoded.
- Image has unsupported or missing color metadata; MVP1 should fall back to sRGB assumptions and record the fallback.
- Reference image is too small, transparent-only, nearly blank, or otherwise not useful for style analysis.
- LUT generation fails validation.
- Target photo cannot be decoded or rendered.
- Full-resolution render exceeds memory budget.
- `.cube` export cannot be written to the requested destination.

## Empty States

- No Film Rolls: product UI owns the empty library state.
- Film Roll with no processed outputs: detail should show the reference sample first and allow apply/export actions.
- No target photo selected: apply preview should remain unavailable until the user imports a photo.

## Future Extension Points

- HDR, Log, and Display P3 color workflows.
- Video LUT application.
- Advanced skin-tone and neutral-gray protection controls beyond the lightweight Algorithm V2 LUT-time soft protection.
- Local AI-assisted style extraction.
- Additional LUT sizes or user-facing style controls.

## Documentation Updates Completed

This document records the MVP1 processing sequence and links the algorithm modules that must be implemented later.
