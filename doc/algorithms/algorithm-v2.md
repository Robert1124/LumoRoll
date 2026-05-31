# Algorithm V2

## Purpose

Algorithm V2 upgrades LumoRoll's traditional local LUT generation so Film Rolls capture more of a reference image's usable color character without using AI, network calls, cloud processing, video, HDR, Log, or Display P3 advanced handling.

The output remains a deterministic SDR / sRGB / Rec.709 `33x33x33` 3D LUT that can be applied locally through Core Image and exported as a standard `.cube` file.

## Inputs

- One decoded reference image.
- Non-transparent SDR sRGB analysis pixels from the existing ImageIO downsample path.
- LUT size, default `33`.
- Algorithm version, defaulting to `mvp1.traditional.v2` for newly generated photo-based Film Rolls.

Imported `.cube` Film Rolls keep the imported-cube algorithm version and do not run Algorithm V2.

## Outputs

- `ReferenceImageAnalyzer.Descriptor` with robust luminance, chroma, and tonal-zone statistics.
- `LUT3D` RGB samples in red-fastest order.
- Validation guarantees inherited from the Domain model: finite values, exact sample count, and all RGB channels clamped to `[0, 1]`.

## Data Dependencies

- ImageIO decode and the existing sRGB downsample path.
- Domain `LUT3D` validation.
- Core Image rendering and `.cube` export consume the same generated RGB samples.

## Relationship To Other Modules

Algorithm V2 remains inside Processing. It feeds Domain `CreateFilmRollUseCase` through `LUTGenerating`, and it does not change SwiftUI state management, file storage layout, Photos permission behavior, apply intensity blending, or `.cube` export presentation.

## Analysis Descriptor

Algorithm V2 keeps the existing descriptor fields for compatibility and adds richer fields:

- Luminance percentiles: p1, p5, p25, p50, p75, p95, and p99.
- Zone color biases for shadows, midtones, and highlights.
- Zone warmth for shadows, midtones, and highlights.
- Global chroma percentiles.
- Hue-sector saturation tendencies for red, orange, yellow, green, cyan, blue, and magenta.
- Neutral protection strength derived from low-chroma pixel prevalence.
- Skin protection strength derived from skin-hue prevalence.

The analyzer still records low-contrast, low-saturation, low-confidence, and assumed-sRGB warnings.

The main-thread product decision for MVP1 is to include only lightweight LUT-generation-time neutral and skin-hue soft protection. This is not target-photo semantic masking, not an adaptive apply-time system, and not an AI feature. Advanced user-facing skin/neutral controls remain MVP2.

## Generation Strategy

Generation starts from the identity cube and applies a bounded transform in this order:

1. Filmic percentile tone map.
2. Tonal-zone color balance.
3. Hue-selective saturation.
4. Neutral and skin soft protection blend.
5. Final clamp.

### Filmic Percentile Tone

V2 uses luminance percentiles instead of min/max extremes. The generator maps black, shadow, midpoint, highlight, and white control points with a smooth curve:

- Black and white range compression comes from robust p1 and p99 values, not single-pixel extremes.
- The midpoint comes from p50 and is capped so the LUT does not overcorrect a very dark or very bright reference.
- The curve uses a gentle toe and shoulder so highlights roll off and shadows avoid hard clipping.

### Tonal-Zone Color Balance

Reference pixels are grouped by luminance zone:

- Shadows: low luminance.
- Midtones: middle luminance.
- Highlights: high luminance.

Each zone contributes a capped RGB bias and warmth value. When generating the cube, smooth luminance weights blend these zone biases so shadow, midtone, and highlight colors can differ. This replaces the V1 single global warmth value.

### Hue-Selective Saturation

V2 adjusts chroma by hue sector instead of applying one global saturation multiplier. Sector weights are smooth rather than hard thresholds so colors near boundaries do not jump. The saturation change is bounded per sector to avoid neon colors or gray collapse.

### Neutral And Skin Protection

Protection is a soft blend back toward the tone-mapped value, not a separate mask stored with the image:

- Low-chroma cube samples are protected based on neutral protection strength so whites, grays, and blacks do not pick up strong casts.
- Skin-hue samples are protected based on skin protection strength so portraits remain usable when the reference contains people.

Protection affects LUT generation only. It does not analyze target photos at apply time, and it does not change the intensity slider behavior.

## State Management Logic

New photo-created Film Rolls store Algorithm V2 LUT data once at save time. Existing Film Rolls keep their stored LUT and algorithm version. Intensity remains a render-time blend between original and LUT-processed output and must not regenerate or mutate the LUT.

## Error States

Algorithm V2 uses the existing error surface:

- Corrupt, unsupported, empty, or fully transparent reference images fail import.
- Unsupported LUT sizes fail with `invalidLUTSize`.
- Invalid generated values fail Domain validation.

No network, model download, or cloud error state is introduced.

## Empty States

No new UI empty state is introduced. Create Film Roll still requires a selected source and a non-empty name before save.

## Testing Requirements

Algorithm V2 must be covered by focused tests proving:

- Analyzer descriptors include robust luminance percentiles and ignore outlier extremes better than min/max.
- Shadows and highlights can receive different warmth/color tendencies from the same reference.
- Green-heavy references can reduce green-sector saturation without forcing the same change onto skin-hue samples.
- Neutral and skin-hue cube samples move less than saturated non-protected samples.
- Generated LUTs remain finite, clamped, red-fastest, and export-compatible.
- Newly generated photo-based LUTs default to `mvp1.traditional.v2`.

## Future Extension Points

- Tune the analysis downsample size after real-device profiling.
- Add developer-visible diagnostic overlays for descriptor statistics.
- Add optional user-facing generation strength controls.
- Add local-only Core ML style encoders in a future algorithm family without changing the exported `.cube` contract.
