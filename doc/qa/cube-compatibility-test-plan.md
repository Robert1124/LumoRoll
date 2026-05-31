# Cube Compatibility Test Plan

Status: updated after Task 9 implementation audit on 2026-05-24.

## Purpose

Verify that LumoRoll's generated 33x33x33 `.cube` LUT files are standard, portable, and usable in common photo and video editing tools even though MVP1 itself is photo-only.

## Export Expectations

The MVP1 `.cube` export should:

- Use a standard text `.cube` format.
- Default to `LUT_3D_SIZE 33`.
- Include `TITLE`, `DOMAIN_MIN 0.000000 0.000000 0.000000`, and `DOMAIN_MAX 1.000000 1.000000 1.000000`.
- Use normalized RGB triplets.
- Write RGB rows with red as the fastest-changing channel, then green, then blue.
- Use six decimal places with POSIX decimal formatting.
- Avoid malformed headers or app-specific syntax that breaks import.
- Preserve the generated Film Roll name in a sanitized ASCII `.cube` filename where possible, with `Film-Roll.cube` fallback.
- Be created only through explicit user export/share action.

## Compatibility Targets

Initial manual import targets should include a practical subset of common tools available to the team:

- DaVinci Resolve.
- Adobe Premiere Pro or Adobe Photoshop where available.
- Final Cut Pro through a LUT-loading workflow where available.
- Affinity Photo or another LUT-capable photo editor where available.
- A simple parser script or validator to check dimensions and numeric ranges.

Because tool availability can vary, the final compatibility matrix should record exact app names, versions, OS versions, and results.

## Test Cases

- Export a Film Roll with default 33x33x33 LUT.
- Create a Film Roll from a known-good `.cube` file through Files import.
- Confirm iOS Files enables selectable `.cube` files in the Create Film Roll picker.
- Confirm file extension is `.cube`.
- Confirm filename is valid with spaces, emoji-free fallback, punctuation, duplicate names, and long names.
- Parse file and verify the expected number of RGB rows: `33 * 33 * 33`.
- Verify all RGB values are finite and within expected normalized range.
- Import into each compatibility target.
- Apply LUT to at least one neutral photo and one saturated photo.
- Confirm no channel swapping, inversion, clipping-only output, or severe unexpected color cast from file-order errors.
- Share/export cancellation leaves the Film Roll intact.
- Failed export displays a recoverable error.
- Malformed `.cube` import displays a recoverable create-flow error and does not create a Film Roll.

## Regression Checks

Run the compatibility smoke test whenever:

- LUT generation changes.
- `.cube` parser or imported-LUT preview rendering changes.
- `.cube` writer changes.
- App document type or UTType declarations change.
- Color-space assumptions change.
- Export/share workflow changes.
- File naming or storage paths change.

## Open Questions

- None for the current writer format. Remaining work is compatibility validation in external apps.

## Implementation Notes

- `CubeExporter` currently emits `TITLE`, `LUT_3D_SIZE`, `DOMAIN_MIN`, and `DOMAIN_MAX`, followed by exactly `size * size * size` RGB rows.
- `CubeLUTImporter` reads simple UTF-8 3D `.cube` files, validates row count and normalized RGB values, and rejects unsupported 1D LUT files.
- Imported `.cube` Film Rolls store a generated local preview image as the reference asset so detail and library components can keep using the MVP1 one-reference model.
- `ExportLUTUseCase` sanitizes the suggested filename from the Film Roll name, limits the base name length, and falls back to `Film-Roll.cube` when needed.
- `CubeLUTExportDocument` exports the cube text as UTF-8 plain text through SwiftUI `fileExporter`.
- `Info.plist` declares `com.lumoroll.cube` as an imported plain-text document type with the `cube` filename extension so the system Files picker can select local LUT files.
