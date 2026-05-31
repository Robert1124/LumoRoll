# Privacy Documentation

This folder records LumoRoll MVP1 privacy decisions, permission timing, local data handling, and App Store privacy preparation.

## MVP1 Commitments

- All image analysis, LUT generation, LUT application, preview rendering, and export preparation run locally on device.
- No image upload.
- No cloud processing.
- No account system.
- No network-based AI.
- No remote analytics or tracking in MVP1.
- App library storage remains inside the app sandbox.
- PhotosUI import should avoid broad photo library read permission where possible.
- Writing to the system Photos library happens only when the user explicitly chooses Save to Photos.
- `.cube` export happens only through user-initiated share/export.
- User-facing copy should frame Film Rolls as color-inspired looks, not exact copying of copyrighted styles.

## Documents

- [Privacy Policy Draft](privacy-policy-draft.md): draft policy language and data collection boundaries.
- [Photos Permission Model](photos-permission-model.md): import, write permission, and denial handling.
- [Data Handling and Local Processing](data-handling-and-local-processing.md): stored data, processing boundary, deletion, and failure behavior.
- [App Store Privacy Summary](app-store-privacy-summary.md): expected App Privacy answers, permission string notes, and review risks.
- [Model Artifact Provenance](model-artifact-provenance.md): private local Core ML model privacy boundary, provenance requirements, and release risks.

## Open Privacy Follow-Ups

- Confirm final App Store privacy answers against the actual SDK list before submission.
- Verify rendered JPEG metadata behavior on real saved/shared outputs. The current implementation intends not to copy source EXIF/GPS into processed JPEGs, while original selected image bytes remain in app sandbox.
- Re-review privacy docs before any future analytics, crash reporting, account, iCloud, cloud processing, or AI-model-download work.
