# Film Roll Domain Model

## Purpose

Represent a user-named LUT collection built from exactly one reference image-equivalent asset in MVP1. A Film Roll is the core product object shown in the library, opened in detail, used for applying photos, and exported as a `.cube` LUT.

## Inputs

- User-provided Film Roll name.
- One imported reference image, or one generated preview image for `.cube`-imported rolls.
- Generated or imported LUT data.
- Reference thumbnail.
- Palette summary.
- Optional sample analysis package for reference-image-created rolls.
- Processed photo records appended over time.

## Outputs

- Library summaries.
- Detail data.
- LUT descriptor for rendering/export.
- Coverage/confidence and render profile seed for app-only adaptive rendering.
- Stable IDs for navigation and storage.

## Data Dependencies

- `manifest.json` metadata.
- Reference original and thumbnail files.
- LUT binary and optional `.cube` export files.
- Inline sample analysis package for sample quality, style profile, coverage/confidence, and render profile seed.
- Processed image records and thumbnails.

## Relationship To Other Modules

- Owned by Domain.
- Created and loaded by Domain use cases.
- Persisted by Storage through `FilmRollRepository`.
- Rendered by Processing through LUT descriptors and asset URLs.
- Displayed by Features and DesignSystem components.

## State Management

The model should be a value type or set of value types. Feature models observe loaded collections and selected roll detail state. Navigation uses `FilmRollID`, not full model payloads.

## Error States

- Missing reference image.
- Missing LUT file.
- Manifest version unsupported.
- Duplicate or invalid ID.
- Empty user name before save.

## Empty States

A Film Roll can have zero processed photos, but it must still have one reference image-equivalent asset. Detail displays the reference sample first; the projector add-photo affordance is currently hidden. For `.cube`-imported rolls, the sample frame is a locally generated preview of the LUT rather than an original user photo.

## Future Extension Points

- Multiple references per roll.
- Rename and notes.
- Favorite/pinned state.
- Higher LUT resolutions.
- Model-generated base LUT metadata and richer adaptive rendering diagnostics.
- iCloud sync metadata.
