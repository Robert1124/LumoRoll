# Privacy Policy Draft

Status: MVP1 draft for product and App Store preparation. This is not final legal text.

## Summary

LumoRoll is a local-first iOS app for creating personal Film Rolls from reference images, applying those Film Rolls to photos, and exporting `.cube` LUT files. MVP1 does not require an account, does not upload images, and does not use cloud or network-based AI processing.

## Data LumoRoll Handles

LumoRoll handles user-selected content only after the user chooses it through the iOS photo picker, file importer, share sheet, or related system UI.

Handled data may include:

- Reference images selected to create a Film Roll.
- Photos selected for applying a Film Roll.
- Generated 33x33x33 LUT data.
- Processed photo outputs.
- Thumbnails used in the in-app Film Roll library.
- User-entered Film Roll names.
- Local metadata such as creation date, image dimensions, processing status, and file references.

## Data Collection

MVP1 should collect no personal data for tracking, advertising, analytics, accounts, or remote services.

The app should not collect:

- User account identifiers.
- Contact information.
- Location data.
- Browsing history.
- Device advertising identifiers.
- Remote analytics events.
- Photos or LUT files outside user-selected actions.

If future builds add diagnostics, analytics, crash reporting, cloud sync, or accounts, this privacy policy must be revised before implementation and before release.

## Local Processing Commitment

All MVP1 image analysis, LUT generation, LUT application, intensity blending, thumbnail generation, and export preparation must run locally on the user's device.

MVP1 must not:

- Upload images for analysis.
- Upload LUTs.
- Use network AI services.
- Create cloud processing jobs.
- Require a user account.
- Sync Film Rolls through iCloud.
- Send generated palettes, thumbnails, or processed outputs to a server.

## Local Storage

LumoRoll stores app-created content inside the app sandbox. Stored content may include:

- Reference image copy for each saved Film Roll.
- Generated `.cube` or internal LUT representation.
- Processed outputs saved into a Film Roll.
- Thumbnails for library and detail screens.
- Film Roll names and metadata.

Deleting a Film Roll should remove its reference image, generated LUT, thumbnails, processed outputs, and metadata from app-managed storage, subject to normal iOS file-system behavior and any system backups that apply to the app container.

## Photos Access

LumoRoll should use PhotosUI for photo import where possible so users can select individual assets without granting broad read access to the photo library.

Photos write permission should be requested only when the user explicitly chooses a Save to Photos action. The app should not ask for Photos write access during onboarding, Film Roll creation, library browsing, LUT application, or `.cube` export.

If Photos access is denied or unavailable, the app should explain the failed action and offer non-Photos alternatives where available, such as saving inside the Film Roll or sharing/exporting through the system share sheet.

## Sharing and Export

LumoRoll exports data only through user-initiated actions:

- Share processed photo.
- Save processed photo to Photos.
- Export `.cube` LUT.
- Share `.cube` LUT through the system share sheet or file exporter.

The app should not automatically export or transmit any image or LUT.

## Copyright and Style Language

LumoRoll should describe Film Rolls as color-inspired looks created from a user's selected reference image. User-facing copy should not promise exact copying, cloning, or recreation of another creator's protected style, preset, film stock, brand, or copyrighted work.

Recommended framing:

- "Create a Film Roll inspired by this photo's colors."
- "Build a reusable color look from your reference image."
- "Results vary by photo and lighting."

Avoid framing:

- "Copy this photographer's style exactly."
- "Clone any preset."
- "Recreate a copyrighted look."

## Children's Privacy

MVP1 has no account system, no social features, no user profiles, and no remote data collection. If future versions add accounts, sharing communities, analytics, or cloud sync, children's privacy requirements must be reviewed before design or implementation.

## Future Changes Requiring Privacy Review

Privacy documentation must be updated before adding:

- Cloud sync or iCloud document storage.
- Account login.
- Remote analytics or crash reporting.
- Network-based AI.
- Local model downloads.
- Video processing.
- Metadata extraction beyond what MVP1 requires.
- Location-aware organization.
- Social sharing features beyond system share sheets.
