# Algorithm Documentation

This folder owns LumoRoll image-processing and LUT behavior. Most documents describe the implemented MVP1 local pipeline; future direction notes are explicitly marked when they are not implemented behavior.

## MVP1 Algorithm Baseline

- Public source builds use the deterministic traditional Algorithm V2 path for reference-image Film Roll creation.
- Production builds may add a private bundled local Core ML base-LUT predictor outside the public source tree and still fall back to Algorithm V2 when Core ML is unavailable or returns invalid output.
- Run all analysis, LUT generation, rendering, and export locally on device.
- Normalize inputs into SDR sRGB / Rec.709 for MVP1.
- Generate a 33x33x33 3D LUT by default.
- Build Algorithm V2 baseline LUTs from an identity cube, then apply a bounded style transform derived from the single reference image.
- Persist sample analysis, coverage/confidence, lighting, style profile, and render-profile seed metadata for reference-image rolls.
- Store generated LUT data as Float32 RGBA cube data suitable for `CIColorCube` or `CIColorCubeWithColorSpace`.
- Render through Core Image with a Metal-backed `CIContext`.
- Apply app-only adaptive post process after the base LUT and before intensity blending when saved sample metadata exists.
- Blend intensity between the original image and the LUT output; do not regenerate or mutate the LUT when intensity changes.
- Export `.cube` files with `TITLE`, `LUT_3D_SIZE 33`, `DOMAIN_MIN`, `DOMAIN_MAX`, documented ordering, and fixed precision.
- Keep video, HDR, Log, Display P3 advanced handling, network AI, cloud inference, and model downloads out of MVP1. `.cube` export serializes only the stored base LUT; sample analysis, confidence, model version, and adaptive render metadata stay app-only.

## Documents

- [MVP1 LUT Pipeline](mvp1-lut-pipeline.md): end-to-end flow from reference import to saved Film Roll, apply preview, save, and `.cube` export.
- [Reference Image Analysis](reference-image-analysis.md): downsampling, color normalization, statistics, edge cases, and output style descriptor.
- [LUT Generation](lut-generation.md): 33x33x33 identity cube construction and deterministic tone, channel, saturation, and split-tone transform.
- [Algorithm V2](algorithm-v2.md): robust percentile tone, tonal-zone color, hue-selective saturation, and neutral/skin soft protection.
- [Model-Assisted LUT And Render Profile](model-assisted-lut-render-profile.md): optional private local model direction plus target-aware in-app adaptive rendering split, including future quality controls.
- [Sample Analysis To Base LUT Workflow](sample-analysis-base-lut-workflow.md): first-stage workflow for sample quality, color/tone statistics, scene lighting analysis, coverage/confidence, base LUT generation, and render profile seed creation.
- [Adaptive Post Process](adaptive-post-process.md): app-only target-aware render layer that uses saved sample metadata after base LUT application and stays out of `.cube` export.
- [Private Model Boundary](model-assisted-coreml-artifact.md): public-source behavior, private production model boundary, fallback behavior, and release requirements.
- [Core Image Rendering](core-image-rendering.md): `CIContext`, color handling, LUT application, preview rendering, and save rendering.
- [Intensity Blending](intensity-blending.md): non-destructive original/LUT blend behavior and preview state expectations.
- [Cube Export](cube-export.md): `.cube` structure, ordering, precision, validation, and compatibility notes.
- [Performance and Memory](performance-memory.md): downsample strategy, full-resolution boundaries, memory constraints, and failure modes.
- [Test Fixtures](test-fixtures.md): deterministic fixture strategy for analysis, generation, rendering, export, and edge cases.

## Open Decisions For Implementation

- Exact persisted metadata schema for the style descriptor and LUT record belongs with architecture/storage docs.
- Final preview pixel dimensions should be chosen with the iOS architecture and design workers.
- Export filename rules and user-facing errors should be aligned with product/UX docs.
