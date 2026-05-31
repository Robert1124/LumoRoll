# Create Film Roll Flow

## Purpose

Let the user create one named Film Roll from one reference photo or one local `.cube` LUT file. Creation is complete only after the user enters a non-empty name, taps Save, and local analysis/generation or `.cube` import succeeds.

## Flow

1. User taps the blank add card from Library.
2. Create screen opens as one page with reference import and Film Roll naming together.
3. User taps `Add a reference`, then chooses one photo from Photos/Files, or one `.cube` LUT from Files.
4. LumoRoll validates and previews the selected image locally, or marks the selected `.cube` file locally, on the same page.
5. User enters a Film Roll name on the same page.
6. Save action is enabled only when a source is selected and the trimmed name is non-empty.
7. User saves the Film Roll.
8. LumoRoll analyzes the image locally and generates a 33x33x33 LUT, or parses the imported `.cube` locally, then stores the reference/preview image, LUT, thumbnail, palette/metadata, and name locally.
9. App returns to Library and shows the new Film Roll.

## Inputs

- One reference photo in a supported image format, or one supported `.cube` LUT file.
- One non-empty Film Roll name.

## Outputs

- One saved Film Roll.
- One generated or imported LUT.
- One stored reference image or imported-LUT preview image and thumbnail.
- Metadata such as creation date, palette summary, and photo count.

## Validation Rules

- Name is required before save.
- Whitespace-only names are invalid.
- MVP1 must not silently save `Untitled Roll`.
- Suggested names may fill the name field, but the user must confirm save.
- Each Film Roll has exactly one reference image-equivalent asset. For imported `.cube` rolls, this asset is a generated local preview image of the LUT, not a user photo.

## Dependencies

- PhotosUI and file import for selecting the reference.
- Files import for selecting `.cube` LUTs.
- Image processing for local analysis and LUT generation.
- `.cube` parsing and preview generation for imported LUTs.
- Local persistence for saving Film Roll assets and metadata.
- Design system for the one-page create flow, film cartridge preview, palette swatches, naming field, and save/progress treatment.

## Empty and Error States

- No photo or `.cube` selected: keep the one-page import/naming form open with Save disabled.
- User cancels picker: return to the one-page form without error.
- Unsupported image: explain that the image could not be used and offer Photos/Files again.
- Unsupported `.cube`: explain that the LUT file could not be imported and offer Files again.
- Analysis or save-time generation fails: keep the selected image and name available if possible and offer retry or choose another photo.
- Name empty: keep Save disabled and show concise inline guidance only after the user attempts to save or leaves the field.
- Save fails: keep the generated state in memory when possible and offer retry.

## User-Facing Copy

- MVP1 uses two compact section labels on one page: `Step 1 of 2` for reference import/preview and `Step 2 of 2` for naming.
- Primary prompt: `Pick a photo sample or a cube LUT`
- Empty reference picker: `Add a reference`
- Save/generation status: `Building your Film Roll...`
- Name prompt: `Name your roll.`
- Name placeholder: `e.g. Roadtrip Sky`
- Save action: `Save as Film Roll`
- Name validation: `Enter a name to save this Film Roll.`

## Future Extension Points

- Multiple reference images.
- Advanced generation settings.
- Manual palette adjustment.
- Local AI-assisted naming suggestions.
- Draft recovery if creation is interrupted.

## MVP1 Implementation Decision

MVP1 keeps the create flow lightweight: source import, preview/source state, naming, and save live on one page. After image import, the selected reference is validated, staged, and previewed, but LUT analysis/generation happens when the user explicitly saves the named Film Roll. After `.cube` import, the selected file is held as local text data and parsed only when the user saves. There is no separate Step 2 analysis screen or panel. This preserves the requirement that every saved Film Roll is user-named before persistence and avoids creating generated LUT assets for abandoned drafts.
