# MVP1 Test Strategy

Status: updated for the public Algorithm V2 source tree on 2026-05-31.

## Purpose

Define the MVP1 test coverage expected before release: core Film Roll behavior, privacy-sensitive flows, image-processing reliability, `.cube` compatibility, performance, storage, accessibility, and visual quality.

## Device Matrix

Minimum matrix should include:

- One current or near-current iPhone.
- One older supported iPhone with less memory.
- One compact screen size.
- One large screen size.
- Latest supported iOS release.
- Oldest iOS version the app chooses to support.

Simulator testing is useful for UI and flow checks, but real-device testing is required for memory, performance, Photos permission behavior, and export/share flows.

## Core Flow Coverage

Create Film Roll:

- Import one reference image.
- Cancel image picker.
- Import unsupported image.
- Import corrupt image.
- Generate an Algorithm V2 base LUT locally in the public source build.
- For private production builds, verify the local Core ML predictor path separately and confirm it falls back to Algorithm V2 when the model is unavailable or produces invalid output.
- Verify reference-image Film Rolls persist sample analysis, coverage/confidence, lighting, style profile, and render-profile seed metadata.
- Require user-entered Film Roll name before save.
- Save Film Roll into app library.
- Verify reference sample appears first in the Film Roll Detail projector transport.

Apply Film Roll:

- Import target photo.
- Preview before, split, and after modes.
- Adjust intensity without regenerating or mutating the LUT.
- Verify adaptive post process uses saved sample metadata when present and falls back to base-LUT-only rendering for imported `.cube` rolls.
- Save output into Film Roll.
- Save output to Photos only after explicit user action.
- Share processed output.

Export:

- Export `.cube` from a saved Film Roll.
- Cancel export/share sheet.
- Retry failed export.
- Verify temporary file cleanup.

## Privacy and Permission Tests

- Import through PhotosUI without broad read prompt where possible.
- Confirm no Photos write prompt appears during onboarding, create, import, preview, or save-to-roll.
- Confirm Photos write prompt appears only after Save to Photos.
- Deny Photos write permission and verify recovery copy.
- Confirm no network dependency is required for MVP1 flows.
- Confirm the public source build has no bundled model artifact, model metadata, model download, or network dependency.
- For private production builds, confirm local Core ML inference does not download a model, call a network endpoint, or write prediction tensors outside the app sandbox.
- Confirm no account prompt exists.
- Confirm exported/shared files are user-initiated only.
- Confirm the app bundle has add-only Photos usage copy and no broad Photos read usage string for MVP1.
- Confirm Save to Photos uses add-only authorization on a clean install and after denial.

## Reliability and Edge Tests

- Large image import and processing.
- Very small image import.
- Wide panorama and tall portrait images.
- Images with transparency.
- HEIC, JPEG, PNG, and unsupported file types.
- Corrupt image file.
- Low storage conditions where possible.
- Interrupted export/share.
- App backgrounding during processing.
- App relaunch after partially completed work.
- Duplicate Film Roll names if allowed by product.
- Stale staged imports and unmanifested temporary processed folders after interruption.
- Metadata behavior for rendered JPEGs saved to Photos and exported/shared outputs.
- Algorithm V2 visual QA with references that contain people, neutral interiors, green foliage, sunsets, food, wood, sand, low-contrast photos, and clipped highlights.
- Private model visual QA with real photos, screenshots/documents, black borders, high-contrast graphics, low-light silhouettes, and strong green/cyan style references before model-enabled release.
- Private build Core ML model contract tests for bundled resource presence, input/output names, shapes, residual count, and metadata `candidate_name`.
- Private build preprocessing parity tests for NCHW tensor order, color stats order, EXIF orientation, non-square direct resize, and private golden fixtures.

## Visual and Accessibility Tests

- Light mode and dark mode for all MVP1 screens.
- Dynamic Type for supported text areas.
- VoiceOver labels for buttons, Film Roll cards, sliders, segmented controls, split preview, save/share/export.
- Reduced Motion behavior if animations are added.
- Touch target sizes for film strip items, icon buttons, and sliders.
- Photo overlays remain readable on bright and dark images.

## Pass Criteria

MVP1 is not release-ready until:

- Core create/apply/save/export flows pass on the device matrix.
- Privacy permission timing matches the privacy docs.
- Public Algorithm V2 creation works without network access, and private model-enabled release builds verify local inference plus Algorithm V2 fallback separately.
- `.cube` files import successfully in selected compatibility apps.
- Large-image memory tests do not crash on the oldest supported target device.
- Known failure states show recoverable user-facing errors.
- Accessibility smoke tests pass for primary flows.
- Metadata behavior and App Store privacy answers match the implemented SDKs and permissions.
