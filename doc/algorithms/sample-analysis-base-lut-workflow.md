# Sample Analysis To Base LUT Workflow

## Purpose

This document defines the first stage of the local model-assisted LumoRoll workflow:

```text
import sample image
->
sample analysis package
->
base LUT
->
render profile seed
->
coverage/confidence metadata
```

It expands the model-assisted direction documented in `model-assisted-lut-render-profile.md`. The public local implementation stores deterministic analysis metadata alongside the base LUT and uses Algorithm V2. Private production builds may add a bundled Core ML base-LUT predictor outside the public source tree and fall back to Algorithm V2 when the model path is unavailable or invalid.

The key decision is that sample import should not only generate a weak color descriptor. It should produce a complete package that lets LumoRoll create a strong exportable base LUT and later adapt that LUT to target photos through in-app post process.

## Product Goal

After a user imports one sample image, LumoRoll should understand enough about the sample to answer:

- What is the sample's color style?
- What is the sample's lighting style?
- What scene and image-quality conditions shaped the sample?
- Which color families are represented in the sample?
- Which important color families are missing and must be inferred?
- How confident is the system in the generated Film Roll?
- What base LUT should be exported as `.cube`?
- What render profile should guide target-aware post process?

The base LUT should be a complete `33x33x33` color mapping, not a direct lookup table only for colors that appeared in the sample.

## Inputs

- One sample image selected by the user.
- Decoded SDR / sRGB / Rec.709 working image data.
- Optional image metadata, such as orientation, color profile, dimensions, and EXIF exposure information when available.
- Traditional image statistics computed locally.
- Optional private bundled local visual model output when Core ML inference succeeds.
- Target LUT size, default `33`.

## Outputs

The sample stage saves a `SampleAnalysisPackage` containing:

- `sampleQuality`: suitability and warnings for the imported sample.
- `colorStatistics`: measured color and tone statistics.
- `sceneLighting`: inferred lighting and scene characteristics.
- `semanticColor`: detected or inferred skin, sky, foliage, neutral, warm-light, and other memory-color cues.
- `styleProfile`: compact description of the intended look.
- `coverageConfidence`: observed and inferred color-space coverage.
- `renderProfileSeed`: target-aware adaptation instructions.
- `baseLUT`: complete exportable `33x33x33` LUT.
- `algorithmVersion` and, if applicable, `modelVersion`.

The first Swift schema uses these conceptual names so future model outputs and richer gating decisions can be added without changing the meaning of existing metadata.

## Relationship To Other Modules

- Create Film Roll flow imports the sample image and waits for valid analysis before the Film Roll can be saved.
- Domain stores the base LUT and metadata with the Film Roll.
- Processing owns analysis, model inference, base LUT generation, validation, and render profile creation.
- Storage persists the sample image, base LUT, style profile, render profile seed, coverage/confidence metadata, and algorithm/model version.
- `.cube` export uses only the validated base LUT.
- Apply flow uses the saved base LUT plus render profile seed and coverage/confidence metadata for target-aware rendering.

## Stage 1: Sample Quality Analysis

Purpose:

- Decide whether the sample can produce a reliable Film Roll.
- Warn or fail early when the image is too limited.

Analyze:

- Resolution and usable pixel count.
- Blur or focus weakness.
- Noise level.
- Overexposed and underexposed pixel fraction.
- Low contrast.
- Low saturation.
- Extreme monochrome or near-duotone samples.
- Transparency or invalid decode.
- Color profile fallback to sRGB.

Output examples:

```json
{
  "usable": true,
  "warnings": ["low_color_coverage", "high_shadow_fraction"],
  "confidence": 0.62
}
```

Behavior:

- Severe decode, empty image, or unusable pixel failures should block generation.
- Weak but usable samples should generate a Film Roll with lower confidence and more conservative color-space inference.

## Stage 2: Measured Color And Tone Statistics

Purpose:

- Capture what is actually present in the sample without interpreting it as full style yet.

Analyze:

- Luminance percentiles: p1, p5, p25, p50, p75, p95, p99.
- Black point, white point, midpoint, and dynamic range.
- Shadow, midtone, and highlight color bias.
- Hue histogram.
- Saturation and chroma distribution.
- Dominant and secondary color clusters.
- Neutral-axis behavior.
- Warm/cool balance by tonal zone.
- Hue-sector saturation tendencies.

Output examples:

```json
{
  "tone": {
    "luminanceP5": 0.08,
    "luminanceP50": 0.32,
    "luminanceP95": 0.78
  },
  "zones": {
    "shadows": { "tint": "cyan_blue", "strength": 0.18 },
    "midtones": { "warmth": -0.04 },
    "highlights": { "warmth": 0.12 }
  },
  "dominantHues": ["blue", "orange"]
}
```

Behavior:

- This stage should stay mostly deterministic and explainable.
- It should not decide how missing colors behave by itself.
- It should feed both the model-assisted interpretation and deterministic fallback path.

## Stage 3: Scene And Lighting Descriptor

Purpose:

- Estimate the lighting situation that produced the sample so future target application can adapt intelligently.

Analyze:

- Exposure key: low-key, high-key, daylight, night, indoor, cloudy, backlit, flash-like, neon, warm practical light.
- Contrast ratio between shadows and highlights.
- Highlight behavior: clean, warm, clipped, rolled off, desaturated.
- Shadow behavior: lifted, crushed, cool, warm, green-biased, faded.
- Black behavior: true black, lifted black, colored black.
- White/neutral behavior: preserved, warm, cool, dirty, tinted.
- Light-source impression: natural daylight, tungsten/warm indoor, mixed light, neon/signage, overcast, night ambient.

Output examples:

```json
{
  "exposureKey": "night_low_key",
  "lightSource": "mixed_cool_ambient_warm_practicals",
  "shadowTint": "cyan_blue",
  "shadowTintStrength": 0.18,
  "highlightWarmth": 0.14,
  "blackLift": 0.10,
  "highlightRolloff": 0.22,
  "contrastIntent": 0.35
}
```

Behavior:

- This is illumination-aware analysis, not physical ray tracing.
- It should describe useful render behavior rather than pretending to reconstruct real 3D light paths.
- The output seeds the future render profile used during target-aware post process.

## Stage 4: Semantic Color Descriptor

Purpose:

- Identify or infer how important real-world color families appear in the sample.

Analyze:

- Skin-tone evidence.
- Sky evidence.
- Foliage/green evidence.
- Neutral and white-surface evidence.
- Warm light evidence.
- Water/blue ambient evidence.
- Food/wood/sand/warm-object evidence.
- Saturated red, yellow, cyan, blue, magenta, and green coverage.

Output examples:

```json
{
  "skin": { "observed": false, "confidence": 0.12 },
  "sky": { "observed": false, "confidence": 0.08 },
  "foliage": { "observed": false, "confidence": 0.04 },
  "warmLight": { "observed": true, "confidence": 0.88 },
  "neutral": { "observed": true, "confidence": 0.44 }
}
```

Behavior:

- This stage should separate observed evidence from inferred behavior.
- It should not assume a color family was represented just because a similar hue exists.
- Missing memory-color families should be marked as missing so base LUT generation and target rendering can be conservative.

## Stage 5: Style Profile

Purpose:

- Convert measured statistics and visual interpretation into a compact statement of the intended look.

The style profile should describe the Film Roll's color identity:

- Contrast shape.
- Black point behavior.
- Highlight rolloff.
- Shadow tint.
- Highlight warmth.
- Global saturation response.
- Hue-specific saturation response.
- Green handling.
- Skin handling tendency.
- Neutral handling tendency.
- Film fade or clean digital response.
- Strength of stylization.

Example:

```json
{
  "contrastShape": "soft_filmic",
  "blackPointLift": 0.10,
  "highlightRolloff": 0.22,
  "shadowTint": "cyan_blue",
  "highlightWarmth": 0.14,
  "globalSaturation": -0.12,
  "greenHandling": "muted",
  "skinHandling": "protected_warm",
  "neutralHandling": "protected",
  "styleStrength": 0.72
}
```

Behavior:

- A future model may help infer this profile.
- A general LLM should not be the core color engine.
- The profile must be bounded, schema-validated, and clamped before it generates a LUT.

## Stage 6: Coverage And Confidence

Purpose:

- Record where the sample supports strong decisions and where the system is guessing.

Coverage should describe:

- Observed tonal zones.
- Observed hue families.
- Observed semantic color families.
- Missing or low-confidence regions.
- Overall sample suitability.
- Per-region confidence used by base LUT generation and future target-aware rendering.

Example:

```json
{
  "overall": 0.66,
  "deepShadow": "high",
  "warmLight": "high",
  "neutral": "medium",
  "skin": "missing",
  "sky": "missing",
  "foliage": "missing",
  "saturatedRed": "low",
  "saturatedGreen": "low"
}
```

Behavior:

- Low-confidence colors should not receive extreme mappings.
- Missing colors should be completed using model priors or deterministic memory-color priors.
- The final base LUT must still be complete, but low-confidence regions should be smoother and more conservative.

## Stage 7: Base LUT Generation

Purpose:

- Generate the Film Roll's complete exportable color response.

The base LUT must answer:

> If this style saw any RGB color, how should it map that color?

Generation should combine:

- Measured color/tone statistics.
- Style profile.
- Memory-color priors.
- Coverage/confidence constraints.
- Optional local model output.
- Deterministic smoothing and validation.

The base LUT should support:

- Full RGB cube mapping.
- Shadow, midtone, and highlight differentiation.
- Hue-specific saturation and hue shifts.
- Neutral-axis safety.
- Skin and memory-color conservative priors.
- Smooth behavior for unobserved colors.
- Strong enough style identity to feel meaningfully different from neutral.

Validation must check:

- Exact sample count for `33x33x33`.
- Finite values.
- `[0, 1]` channel bounds.
- Smoothness and continuity.
- No severe banding or discontinuity.
- Export compatibility.
- Minimum style strength where confidence allows.

The base LUT is the `.cube` export artifact. It should be useful in other tools even though it will not include LumoRoll's adaptive post process.

## Stage 8: Render Profile Seed

Purpose:

- Save instructions for how this style should adapt to target photos inside LumoRoll.

Render profile seed fields may include:

```json
{
  "exposureAdaptation": "preserve_target_key",
  "nightToDaylightBehavior": "style_color_without_crushing_daylight",
  "skinProtectionIntent": 0.46,
  "neutralProtectionIntent": 0.42,
  "highlightRolloffIntent": 0.24,
  "shadowLiftIntent": 0.10,
  "shadowTintAdaptation": 0.62,
  "lowConfidenceColorPolicy": "conservative"
}
```

Behavior:

- This profile is not exported as `.cube`.
- It does not replace the base LUT.
- It guides target-aware post process after the base LUT is applied.
- It helps solve large mismatches, such as night sample applied to daylight target.

## Implemented First Local Schema

The first app schema is intentionally compact and deterministic:

- `sampleQuality`: `usable`, `confidence`, and warning codes.
- `colorStatistics`: luminance, chroma, saturation, RGB bias, and tonal-zone warmth/bias values copied from local reference analysis.
- `sceneLighting`: exposure key, contrast intent, shadow tint strength, highlight warmth, black lift, highlight rolloff, and saturation intent.
- `semanticColor`: observed/confidence pairs for neutral, skin, foliage, sky, warm light, saturated red, saturated green, and saturated blue.
- `styleProfile`: bounded style controls derived from the sample.
- `coverageConfidence`: overall confidence plus tonal/hue/semantic coverage entries.
- `renderProfileSeed`: target-aware adaptation intents.
- `algorithmVersion`: generating algorithm family.
- `modelVersion`: optional local model id when a model contributes to generation.

This package is saved with `FilmRoll`. A `.cube` export serializes only the stored base LUT. Adaptive post-process uses the package at Apply/Preview time and never mutates the saved LUT.

## Saved Metadata Shape

A Film Roll metadata package is shaped like:

```json
{
  "algorithmVersion": "model-assisted.v1",
  "modelVersion": "local-style-model.example",
  "baseLUT": "stored separately as LUT3D",
  "sampleQuality": {},
  "colorStatistics": {},
  "sceneLighting": {},
  "semanticColor": {},
  "styleProfile": {},
  "coverageConfidence": {},
  "renderProfileSeed": {}
}
```

Architecture and storage docs define the persisted Swift value shape.

Current Swift implementation stores this as `FilmRoll.sampleAnalysisPackage`. Reference-image creation uses the local `ReferenceImageAnalyzer` and `SampleAnalysisPackageBuilder` to produce deterministic metadata. Public source builds generate `FilmRoll.lut` with Algorithm V2. Private production builds may prefer a bundled local Core ML base-LUT predictor through a private release overlay; if model loading, prediction, or validation fails, creation should fall back to Algorithm V2 and record `modelVersion = nil`. Imported `.cube` rolls leave the package absent.

The private Core ML path should reject or weaken low-confidence samples before release. Coverage/confidence and render-profile seed metadata are saved immediately and used by the app-only adaptive post-process; future sample filtering and scene gating can use the same metadata to bypass or weaken model output before save.

## State Management Logic

Creation state should distinguish:

- `awaitingSample`: no sample selected.
- `analyzingSample`: sample decode, statistics, optional model inference, and LUT generation are running.
- `analysisFailed`: sample cannot produce a valid base LUT.
- `readyToNameAndSave`: a valid base LUT and metadata package exist.
- `saved`: Film Roll is persisted.

The user should not be able to export `.cube` until the base LUT exists and passes validation.

## Error States

Recoverable errors:

- Unsupported or corrupt sample image.
- Sample too small or too transparent.
- Sample too low confidence for strong generation.
- Optional local model unavailable.
- Optional local model output invalid.
- Generated LUT invalid or too discontinuous.
- Storage failure when saving metadata or LUT.

Recommended fallback:

- Offer deterministic Algorithm V2/V3 fallback only when it produces a valid LUT.
- Keep the selected sample so the user can retry.
- Do not silently produce a weak or invalid model-assisted Film Roll.

## Empty States

- Before sample import: show sample import prompt.
- During analysis: show local analysis progress.
- Failed analysis: explain that the sample cannot confidently create a Film Roll and allow replacing it.
- Missing base LUT: disable export and target application.

## Testing Requirements

Implementation should test:

- Low-color-coverage samples generate conservative coverage metadata.
- Night samples record low-key lighting and missing daylight color families.
- Daylight samples record broader color coverage when appropriate.
- Base LUT remains valid and export-compatible.
- Missing color families are mapped smoothly rather than left undefined.
- Render profile seed is saved without mutating the base LUT.
- Apply/Preview requests pass the saved sample package into the renderer.
- Adaptive rendering changes only the current render output and metadata, not the saved base LUT.
- Model output validation rejects malformed, out-of-range, or discontinuous LUT data.
- Fallback behavior is explicit and user-visible.

## Open Questions

- Should model inference output a style profile, a latent vector, a direct base LUT, or a combination?
- What minimum confidence should allow saving a model-assisted Film Roll?
- What sample warnings should be shown to users versus kept as internal diagnostics?
- How should the app communicate that `.cube` export is the base LUT while in-app rendering can be stronger?
- Which benchmark sample categories should define acceptable first-stage quality?

## Future Extension Points

- Add a benchmark harness for sample analysis outputs.
- Add local model experimentation behind a developer flag.
- Add diagnostics showing coverage/confidence by color family.
- Add a model-assisted algorithm version without replacing Algorithm V2 fallback.
- Extend target-aware post process with stronger masks and optional local vision models after the deterministic package is stable.
