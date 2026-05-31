# Adaptive Post Process

## Purpose

Adaptive post process is the app-only rendering layer that runs after a Film Roll's base LUT has been applied to a target photo. It improves robustness when the target photo has a different exposure, lighting key, neutral/skin content, or color coverage than the original sample image.

The adaptive layer is not exported in `.cube` files. Export continues to serialize the stored base LUT only.

## Inputs

- Target photo decoded into the local SDR sRGB / Rec.709 working space.
- Saved base `LUT3D`.
- User intensity.
- Saved `SampleAnalysisPackage`, including coverage/confidence metadata and render profile seed.
- Target image analysis computed locally from the selected target photo.

## Outputs

- Preview JPEG for Apply preview.
- Rendered JPEG and thumbnail for saved processed photos.
- Per-render adaptive metadata stored on `ProcessedPhoto` for saved outputs.

The adaptive metadata records the target analysis and applied adjustment. It is diagnostic and re-render guidance; it is not required by `.cube` export.

## First Local Algorithm

The first implementation is deterministic and global rather than mask-based:

1. Analyze the target image with the same local reference analyzer used for sample analysis.
2. Compare target exposure, contrast, saturation, neutral evidence, skin evidence, and hue coverage to the saved sample package.
3. Derive a bounded `AdaptiveRenderAdjustment`.
4. Apply the base LUT.
5. Apply target-aware post-LUT tone/saturation controls.
6. Blend original and processed output with the user intensity.

The adjustment can:

- Reduce effective style strength when sample confidence is low or target/sample exposure keys are mismatched.
- Preserve target brightness for large lighting mismatches.
- Lift or hold shadows according to the render profile seed.
- Add highlight rolloff conservatively.
- Reduce saturation changes for low-confidence color families.
- Record neutral and skin protection intent for future mask-based work.

The first version deliberately keeps masks out of scope. Skin and neutral confidence influence global strength and saturation/contrast decisions, but they do not create per-pixel segmentation masks.

## Current Implementation

The first Swift implementation is `AdaptivePostProcessor` with algorithm version `app.adaptive.global.v1`.

- It computes target metadata from `ReferenceImageAnalyzer`.
- It derives a bounded `AdaptiveRenderAdjustment`.
- `CoreImageRenderer` applies the adjustment after the base LUT and before intensity blending.
- `CoreImagePhotoRenderer` stores the resulting `AdaptiveRenderMetadata` on saved `ProcessedPhoto` records.
- `CoreImagePhotoPreviewRenderer` uses the same adjustment transiently and returns transient preview metadata.

## State Management

Creation-time metadata lives on `FilmRoll.sampleAnalysisPackage`.

Apply-time metadata is computed per render:

- Preview renders use the metadata transiently.
- Saved processed photos persist the resulting `AdaptiveRenderMetadata`.
- Replacing an existing processed photo replaces the adaptive metadata with the new render's metadata.

## Error States

- If target analysis fails, rendering fails with the same local image import/render error used by the current renderer.
- If a Film Roll has no sample package, the renderer falls back to base-LUT-only rendering.
- If adaptive adjustment values are malformed or non-finite, they are clamped or ignored before rendering.

## Testing Requirements

- A Film Roll created from a sample image stores a sample analysis package with coverage/confidence and render profile seed.
- Apply and preview requests carry the saved sample package to rendering.
- Adaptive rendering changes output for a target mismatch while preserving base-LUT-only behavior for rolls without metadata.
- Saved `ProcessedPhoto` records adaptive render metadata.
- `.cube` export remains unchanged because it serializes only `FilmRoll.lut`.
