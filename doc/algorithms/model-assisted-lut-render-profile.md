# Model-Assisted LUT And Render Profile

## Purpose

This document records the optional private model-assisted base-LUT and render-profile direction after Algorithm V2. Public source builds use Algorithm V2. Production builds may add a private bundled Core ML base-LUT predictor, while Algorithm V2 remains the deterministic fallback and Apply rendering can use app-only adaptive post process. The first-stage sample import workflow is detailed in `sample-analysis-base-lut-workflow.md`.

The goal is to move LumoRoll beyond single-reference color statistics. The model-assisted pipeline generates a complete exportable base LUT from one sample image, then uses target-aware rendering inside the app to adapt that LUT to each imported photo.

The intended result is:

- Exported `.cube`: a portable base color LUT that represents the Film Roll's core color response.
- In-app render: the base LUT plus adaptive post process using target lighting, skin, neutral, and scene analysis.

The in-app render may be stronger and more stable than the exported `.cube`. This is acceptable as long as the product clearly treats `.cube` export as the portable color layer, not as a full recreation of every adaptive in-app effect.

## Product Decision

The final direction discussed by the main thread is:

1. Sample analysis must create a complete base LUT, not only a weak palette or global color bias.
2. Base LUT generation may use a bundled local model.
3. The model should not be a general LLM as the core color engine.
4. Target-aware post process should happen after the base LUT is applied in the app.
5. Post process may protect skin, protect neutrals, adjust lighting response, and modulate LUT strength per target photo.

Public source builds use `mvp1.traditional.v2`. Private model-enabled builds may use a private Core ML algorithm version when bundled inference succeeds and `mvp1.traditional.v2` when the model path is unavailable or invalid. Older private model-generated rolls may still record earlier private model algorithm identifiers.

Default model-assisted base LUT generation now applies a V2 signature boost after successful Core ML prediction:

- The saved base LUT starts from the Core ML predicted LUT.
- A traditional Algorithm V2 LUT is generated from the same reference-image descriptor.
- The V2-minus-model signature is blended into the model LUT at `60%` strength in Lab space.
- Lab `a/b` chroma channels receive the full `60%` boost; Lab `L` receives only `9%` (`60% * 15%`) to avoid pulling the model's tone curve too far toward V2.
- Because this happens before the Film Roll LUT is saved, `.cube` export includes the boosted base LUT for new Film Rolls.
- Algorithm V2 fallback remains unboosted and records `mvp1.traditional.v2`.

## Core Problem

A single sample image often has incomplete color coverage. For example, a night sample may contain mostly blue shadows, black values, and orange practical lights. It may not contain daylight skin, foliage, sky, saturated clothing, white walls, or neutral product surfaces.

A useful Film Roll still needs a full `33x33x33` color mapping. The system must infer how the sampled style should treat colors that were not present in the sample.

Algorithm V2 is the open-source baseline. A private local Core ML model can provide a stronger base LUT predictor in production builds, while future work should improve sample filtering, scene gating, and model quality controls for weak samples.

## Inputs

### Film Roll Creation

- One sample image.
- Optional private bundled local Core ML model output: a predicted residual base LUT.
- Traditional analysis statistics from the sample image.
- Target LUT size, default `33`.

### Photo Application

- One target photo.
- Saved base LUT.
- Saved style profile.
- Saved color coverage and confidence data.
- Target analysis outputs, such as exposure key, luminance distribution, skin confidence, neutral confidence, scene color coverage, and highlight/shadow structure.

## Outputs

### Saved Film Roll Outputs

- Reference image.
- Base `33x33x33` LUT suitable for Core Image application and `.cube` export.
- Style profile describing the intended look.
- Color coverage and confidence map describing which color families were observed versus inferred.
- Render profile describing how the style should adapt to target images inside the app.
- Metadata recording algorithm version and model version when a model is used.

### Render Outputs

- Preview image.
- Processed photo stored in the app after explicit save.
- Optional exported `.cube` file containing only the base LUT.

## Data Dependencies

- Sample image data stored inside the app.
- Target image data selected by the user.
- Optional private bundled local Core ML model.
- Traditional image statistics from existing processing modules.
- Core Image render path for applying LUT and post process filters.
- Storage metadata for algorithm version, model version, style profile, render profile, and confidence values.

No network or cloud dependency is implied by this document. If an API-backed experiment is introduced later, it must be documented as a separate mode because it changes the current local-processing product promise.

## Relationship To Other Modules

- Domain stores the Film Roll's base LUT and algorithm metadata.
- Processing owns sample analysis, base LUT generation, target analysis, and adaptive rendering.
- Storage persists model-assisted metadata alongside existing reference image, LUT, thumbnails, and processed photos.
- UI may show that exported `.cube` is the base LUT while in-app rendering can include additional adaptive processing.
- Privacy docs must be updated before any new model bundle, API experiment, or new analysis output ships.

## Pipeline Overview

```text
sample image
↓
SampleStyleAnalyzer
↓
style profile + coverage/confidence + render profile seed
↓
BaseLUTGenerator
↓
exportable base LUT

target image
↓
TargetAnalyzer
↓
target lighting + skin/neutral/scene analysis
↓
AdaptiveRenderer
↓
base LUT + target-aware post process
↓
final render
```

The sample image portion of this pipeline is expanded in `sample-analysis-base-lut-workflow.md`, including sample quality analysis, measured statistics, lighting descriptor, semantic color descriptor, style profile, coverage/confidence, base LUT generation, and render profile seed creation.

## Base LUT Responsibilities

The base LUT answers:

> What should this Film Roll's style look like across the full RGB color cube?

It should handle:

- Hue mapping for common color families, including colors missing from the sample.
- Saturation response for muted, vivid, faded, or selective-color looks.
- Shadow, midtone, and highlight color response.
- Black point, white point, contrast shape, toe, and shoulder.
- Memory color priors for skin, sky, foliage, neutrals, warm lights, and common daylight colors.
- Smooth interpolation across unobserved color regions.
- Conservative behavior when confidence is low.

The base LUT must remain:

- Finite and clamped.
- Smooth enough to avoid banding and discontinuities.
- Exportable as a standard `.cube`.
- Stable when applied without the in-app adaptive renderer.

## Style Profile Responsibilities

The style profile is a compact description of the sample's intended look. It should be saved because it helps the app explain, debug, and adapt the Film Roll.

Candidate fields:

```json
{
  "contrastShape": "soft",
  "blackPointLift": 0.08,
  "highlightRolloff": 0.22,
  "shadowTint": "cyan_blue",
  "shadowTintStrength": 0.16,
  "highlightWarmth": 0.18,
  "globalSaturation": -0.10,
  "greenHandling": "muted",
  "skinHandling": "protected_warm",
  "neutralHandling": "protected",
  "filmFade": 0.20
}
```

These fields are illustrative, not final schema.

## Coverage And Confidence Responsibilities

The system should know which parts of the color space are supported by the sample and which parts are inferred.

Examples:

```json
{
  "skin": "low_confidence",
  "sky": "missing",
  "foliage": "missing",
  "neutral": "medium_confidence",
  "warmLight": "high_confidence",
  "deepShadow": "high_confidence"
}
```

Coverage data helps the adaptive renderer avoid overconfident color changes on target content that the sample did not represent.

## Render Profile Responsibilities

The render profile is not exported as `.cube`. It exists so the app can apply the Film Roll intelligently to each target image.

It should encode:

- How strongly the style should adapt to different exposure keys.
- How much to protect skin and neutral regions.
- Whether highlights should roll off, warm up, desaturate, or stay clean.
- Whether shadows should lift, crush, cool, or fade.
- How to treat large lighting mismatches, such as night sample to daylight target.
- How conservative to be in low-confidence color families.

This is an illumination-aware render profile, not physical ray tracing. It may estimate lighting and scene structure, but it does not reconstruct a real 3D light path.

## Target Analysis Responsibilities

When applying a Film Roll, the app should analyze the target photo before or during rendering.

Target analysis may include:

- Exposure key: low-key, high-key, daylight, night, indoor, backlit, flash-like.
- Dynamic range and highlight distribution.
- Shadow density and black point.
- White, gray, and neutral confidence.
- Skin-tone confidence.
- Sky, foliage, warm light, and common scene-color confidence.
- Color coverage compared with the sample's coverage map.

This target analysis should not mutate the saved base LUT. It only informs the current render.

## Adaptive Renderer Responsibilities

The adaptive renderer answers:

> How should this target photo receive the saved Film Roll without breaking important content?

It may:

- Apply the base LUT.
- Blend or locally modulate LUT strength.
- Protect skin tones and neutral regions.
- Adjust exposure, contrast, highlight rolloff, and shadow response.
- Reduce aggressive color shifts for low-confidence target regions.
- Add non-LUT effects in future versions, such as grain or glow, if product scope allows.

The adaptive renderer must not change the exported `.cube`. Intensity should remain conceptually a blend between original and processed output, but the processed output may include base LUT plus adaptive post process.

Temporary diagnostic note:

- Task 10O adds a temporary Apply-screen toggle near intensity that can disable adaptive post process for Apply preview, Save to Film Roll, and Save to Photos.
- This is for comparing model-assisted base LUT output against base LUT plus adaptive post process on real device.
- The default remains enabled, and this diagnostic control should be removed or redesigned before release.
- Task 10P adds a separate temporary Apply-screen toggle that can replace the saved base LUT with a transient `mvp1.traditional.v2` LUT regenerated from the Film Roll reference sample for the current Apply render.
- The Task 10P V2 toggle is diagnostic-only: it must not persist the regenerated LUT, must not modify the Film Roll's saved LUT or metadata, and must not affect `.cube` export.
- The adaptive post-process toggle and V2 LUT-source toggle are independent so device testing can isolate saved-model LUT quality from adaptive post-process behavior.

## Model Role

The future model should be treated as a visual color/style model, not a general LLM.

Acceptable model roles:

- Sample image to style latent.
- Sample image to structured style profile.
- Sample image to base LUT, with validation and smoothing by local code.
- Sample image to coverage/confidence estimates.
- Target image to masks or target descriptors, if traditional analysis is not enough.

Avoid:

- Asking an LLM to directly write tens of thousands of LUT values.
- Letting a model output unchecked arbitrary filters.
- Treating text descriptions as the main color engine when the user only provided images.

Local model output must pass deterministic validation, clamping, smoothing, and fallback checks before it affects a saved Film Roll.

## Error States

Future implementation must define recoverable errors for:

- Model unavailable or unsupported on device.
- Model output missing required fields.
- Model output fails validation.
- Predicted LUT is non-finite, out of range, discontinuous, or too weak.
- Sample image has too little color or lighting information for confident generation.
- Target analysis fails during preview or save.

The fallback should be explicit:

- Use deterministic Algorithm V2/V3 fallback when model generation is unavailable.
- Keep the user from exporting a model-generated LUT until validation succeeds.
- Preserve the original sample and target images so the user can retry.

## Empty States

Creation empty state:

- A sample image is required before model-assisted generation can start.

Application empty state:

- A target photo is required before target-aware post process can run.

Export empty state:

- `.cube` export is available only after a valid base LUT exists.

## Privacy And Product Boundaries

For a fully local product:

- Model inference must run on device.
- Images must stay inside the app unless the user explicitly exports or saves.
- No model download, analytics upload, or cloud processing should occur without a separate product decision and privacy update.

If an API-based prototype is used for research, it must be documented separately from the local product flow because sample and target images would leave the device.

## Testing Requirements

Future implementation should prove:

- Base LUT remains valid and export-compatible.
- Base LUT has meaningful behavior for colors missing from the sample.
- Night-to-daylight and daylight-to-night cases do not collapse highlights, skin, or neutrals.
- Coverage/confidence data reduces aggressive shifts in unsupported color families.
- Target analysis does not mutate saved LUT data.
- In-app render can differ from exported `.cube` by design, and this difference is tested and documented.
- Model failures fall back cleanly.

## Open Questions

- Should the model output a compact style latent, a structured style profile, a base LUT, or all three?
- What minimum device class is acceptable for local model inference?
- How large can the model bundle be before it hurts the app experience?
- Should model-assisted Film Rolls be a separate creation mode or replace traditional creation after validation?
- How should the UI explain that exported `.cube` is the base LUT while in-app rendering includes adaptive post process?
- What benchmark image set defines "good enough" for night, daylight, indoor, portrait, landscape, food, and architecture samples?

## Future Extension Points

- Train or adopt a local style encoder.
- Add a target segmentation or skin-confidence model.
- Add visual diagnostics for coverage and target analysis.
- Add a benchmark harness comparing Algorithm V2, future V3, and model-assisted LUTs.
- Add user-facing controls for conservative, balanced, and strong adaptation.
