# Data Handling and Local Processing

Status: MVP1 decision document.

## Purpose

Document what data LumoRoll stores, where it is stored, and how processing remains local.

## Local Data Types

Film Roll records include:

- User-provided Film Roll name.
- One reference image in MVP1.
- Generated LUT data, defaulting to 33x33x33.
- Reference thumbnail.
- Processed photo outputs saved into the roll.
- Processed thumbnails.
- Metadata needed for sorting, display, export, and cleanup.

Temporary processing data may include:

- Decoded image buffers.
- Downscaled analysis images.
- Core Image intermediate images.
- Rendered preview images.
- Temporary export files for share sheets or file exporters.

## Storage Location

Persistent Film Roll content must live in the app sandbox. MVP1 should not store app-created assets in the system Photos library unless the user explicitly chooses Save to Photos for a processed output.

Temporary files should be deleted after import, processing, sharing, or export completes when they are no longer needed.

## Processing Boundary

The following operations must run on device:

- Reference image analysis.
- Deterministic Algorithm V2 LUT generation in public source builds.
- Optional private bundled local Core ML base-LUT prediction for production reference-image Film Roll creation outside the public source tree.
- Algorithm V2 LUT generation fallback, including robust local statistics and LUT-time neutral/skin-hue soft protection.
- Sample analysis package, coverage/confidence, and render-profile seed computation.
- App-only adaptive post-process target analysis and adjustment.
- LUT application.
- Intensity blending.
- Preview rendering.
- Thumbnail generation.
- `.cube` export generation.

MVP1 must not depend on network calls, remote inference, cloud jobs, account services, or server-side storage.

## Inputs and Outputs

Inputs:

- User-selected reference image.
- User-selected `.cube` LUT file for Files-based Film Roll creation.
- User-selected photo to process.
- User-entered Film Roll name.
- User-selected intensity value.
- User-initiated save, share, or export action.

Outputs:

- Saved Film Roll.
- Generated LUT.
- In-app thumbnails.
- Processed image previews.
- Processed outputs saved inside the Film Roll.
- Processed output written to Photos only on explicit user action.
- `.cube` file exported only on explicit user action.
- Imported `.cube` LUTs saved inside the app only after the user names and saves the Film Roll.

Public source builds do not include the bundled Core ML model or model runtime implementation and use Algorithm V2. A private production build may include a local Core ML predictor, but it must not add any network, cloud, model download, account, or analytics path. Algorithm V2 also remains local; its skin-hue and neutral protection signals are computed from the local reference image only and are baked into the generated LUT.

Sample analysis, optional private model inference, target analysis, coverage/confidence computation, and adaptive render adjustment run on device from images the user selected. These metadata records stay in the app-private Film Roll manifest unless the user explicitly exports app data through a future feature. `.cube` export contains only the base LUT values and does not include the sample analysis package, model version, coverage/confidence metadata, or adaptive render metadata.

## Metadata Handling

MVP1 should store only metadata needed for app functionality. If image metadata such as EXIF or GPS is not needed for rendering or export, implementation should avoid preserving it in app-generated processed outputs by default.

Current implementation decision:

- Rendered processed outputs are encoded as new JPEG files from rendered `CGImage` data with only JPEG quality options. Source EXIF/GPS metadata is not intentionally copied into processed outputs.
- Saved Film Roll reference images and saved target originals are byte copies of user-selected source files inside the app sandbox. These originals may retain source metadata, including location metadata if present in the selected file.
- `.cube` exports contain LUT text and the Film Roll title only; they do not contain image metadata.
- `.cube` imports are read as local text data. The app stores parsed LUT values and a generated preview image; it does not upload or cloud-process the LUT file.

QA must verify the rendered-output metadata behavior before release by inspecting files saved to Photos and files shared/exported through system UI. Future features must not share app-stored original images externally without a separate metadata review.

## Deletion and Storage Growth

Deleting a Film Roll should remove:

- The reference image copy.
- Generated LUT data.
- Processed outputs inside the roll.
- Thumbnails.
- Metadata record.

QA must test storage growth from repeated imports, repeated exports, large images, and temporary-file cleanup.

## Failure Handling

LumoRoll should fail locally and recoverably:

- Import failure should not create a broken Film Roll.
- LUT generation failure should keep the user on the create flow with retry or cancel.
- Processing failure should not overwrite the original image or existing Film Roll.
- Export failure should leave the in-app LUT intact.
- Save to Photos failure should leave the in-app processed output intact when already saved to the roll.
- Apply Save to Photos creates a temporary rendered output and discards it after the Photos write succeeds or fails. If the user has not separately saved to the Film Roll, denial does not create a local processed frame.

## Future Extensions

Any future cloud sync, account system, analytics, remote model, or network feature requires a new data-flow review and an updated privacy policy.
