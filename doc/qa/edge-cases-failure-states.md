# Edge Cases and Failure States

Status: updated after Task 9 implementation audit on 2026-05-24.

## Import Edge Cases

- User cancels reference import.
- User cancels apply-photo import.
- Selected asset cannot be loaded.
- Selected file is corrupt.
- Selected file type is unsupported.
- Selected image is extremely small.
- Selected image is extremely large.
- Selected image has unusual aspect ratio.
- Selected image has transparency.
- Selected image has mostly transparent colored pixels.
- Selected image has unsupported color profile.

Expected behavior: do not create broken saved content; show a clear error with retry or cancel.

## Film Roll Creation

- User leaves name empty.
- User enters duplicate name.
- User enters very long name.
- User enters punctuation or characters unsafe for filenames.
- LUT generation fails.
- Thumbnail generation fails.
- App backgrounds during generation.

Expected behavior: require a valid name before saving; keep filename sanitization separate from display name; avoid partial Film Rolls unless they can resume safely.

## Apply and Preview

- Target photo cannot load.
- Preview rendering fails.
- Split control is dragged to 0% or 100%.
- Intensity is set to 0% or 100%.
- User changes target photo repeatedly.
- User backgrounds app during processing.

Expected behavior: intensity should blend original and LUT-processed output without regenerating or mutating the LUT; failed previews should not damage saved Film Roll data.

## Save, Share, and Export

- Save to Film Roll fails.
- Save to Photos permission denied.
- Save to Photos fails after permission.
- Save to Photos is denied after the app has rendered a temporary output.
- Share sheet canceled.
- Share sheet fails.
- `.cube` export fails.
- Temporary export file cannot be written.
- Device storage is low.

Expected behavior: preserve existing app data, show recoverable error, and offer retry or alternatives where appropriate.

Current implementation note: Apply Save to Photos renders a temporary processed output, writes it to Photos, and discards the temporary render on both success and failure. Denial does not append the temporary output to the Film Roll; the user can still use Save to Film Roll as a separate action.

## Library and Storage

- Empty library.
- One Film Roll.
- Many Film Rolls.
- Film Roll with no processed outputs yet.
- Film Roll deletion.
- Storage growth after repeated saves and exports.
- Stale `tmp/imports` content after interrupted import.
- Unmanifested processed folder after crash during Save to Photos temporary render.
- App relaunch after deletion.

Expected behavior: empty states should feel intentional; deleting a Film Roll should remove its app-managed reference image, LUT, thumbnails, processed outputs, and metadata.

## Accessibility and Appearance

- VoiceOver enabled.
- Large Dynamic Type.
- Reduce Motion enabled.
- Light mode.
- Dark mode.
- Bright photo under overlay text.
- Dark photo under overlay text.

Expected behavior: controls remain readable and operable, with accessible labels and sufficient touch targets.

## Privacy-Sensitive Failure States

- User denies Photos write permission.
- User expects imported photo to be uploaded.
- User asks whether a Film Roll exactly copies another creator's style.
- User expects Algorithm V2 skin/neutral soft protection to perfectly preserve every portrait or neutral object.
- Exported processed photo metadata behavior is unclear.

Expected behavior: copy should reinforce local processing, optional Photos saving, color-inspired rather than exact-copy positioning, and preview-based user control rather than perfect semantic preservation.
