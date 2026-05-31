# App Store Privacy Summary

Status: MVP1 App Store preparation notes. Final answers must be validated against the actual implementation before submission.

## Product Position

LumoRoll is a local-first photo creativity app. It lets users choose photos, generate personal color-inspired Film Rolls, apply them to photos, save outputs locally, optionally save processed images to Photos, share results, and export `.cube` LUT files.

## Expected App Privacy Answers for MVP1

MVP1 is expected to have no data collected by the developer if the implementation stays within current scope:

- No account system.
- No developer server.
- No remote analytics.
- No advertising.
- No tracking.
- No network-based AI.
- No cloud processing.
- No image upload.

Before App Store submission, confirm this against all linked SDKs, crash reporters, logging services, and build settings.

## Data Used Locally But Not Collected

The app uses the following data locally on the device:

- User-selected photos.
- User-entered Film Roll names.
- Generated LUTs.
- Thumbnails.
- Processed outputs.
- Local metadata.

This data remains in the app sandbox unless the user initiates Save to Photos, Share, or Export.

## Permission Strings

Photos write usage should be scoped to explicit Save to Photos behavior.

Suggested `NSPhotoLibraryAddUsageDescription`:

> LumoRoll needs permission to save edited photos you choose to your Photos library.

Current implementation string:

> LumoRoll saves your rendered photos to your Photos library only when you choose Save to Photos.

Avoid permission strings that imply broad scanning, automatic upload, or library-wide analysis.

If implementation later requires broad photo read access, add and justify `NSPhotoLibraryUsageDescription`; current MVP1 should avoid that where PhotosUI can provide selected assets.

Task 9 audit note: the app currently defines the add-only Photos string and no broad Photos read string.

## App Review Risk Notes

Review-sensitive areas:

- Explain local processing clearly in App Store copy and privacy policy.
- Avoid implying exact copying of another creator's protected style.
- Request Photos write permission only at the Save to Photos moment.
- Do not request unnecessary broad photo library read access.
- Make `.cube` export user-initiated.
- Ensure any future analytics or crash SDK changes update App Privacy answers before release.

## Export Compliance

MVP1 does not implement proprietary or standard encryption algorithms. It has no account system, developer server, network-based AI, cloud processing, analytics, or image upload path.

For App Store Connect encryption documentation, choose "None of the algorithms mentioned above" for the current implementation. The app Info.plist declares `ITSAppUsesNonExemptEncryption` as `false` so future uploads can skip repeated export compliance prompts unless encryption-related functionality is added.

## User-Facing Privacy Copy

Recommended concise copy:

- "Your photos are processed on this iPhone."
- "LumoRoll does not upload your images to create a Film Roll."
- "Save to Photos is optional and only happens when you choose it."
- "Export creates a `.cube` LUT file you can share or save."
