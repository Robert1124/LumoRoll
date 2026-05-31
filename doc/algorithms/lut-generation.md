# LUT Generation

## Purpose

Generate the reusable 33x33x33 3D LUT for a Film Roll from the reference image style descriptor. MVP1 uses a deterministic traditional transform rather than AI-generated or cloud-generated LUTs.

## Inputs

- Style descriptor from reference image analysis.
- LUT size, default `33`.
- Algorithm version.
- Working color assumption: SDR sRGB / Rec.709.

## Outputs

- Float32 RGBA cube data for `CIColorCube` or `CIColorCubeWithColorSpace`.
- RGB triplets for `.cube` export.
- Validation metadata, including LUT size, domain, min/max output range, and algorithm version.

## Generation Steps

1. Create an identity RGB cube with size `33x33x33`.
2. For each cube sample, normalize coordinates into `[0, 1]`.
3. Apply a bounded tone curve derived from reference luminance statistics.
4. Apply channel balance derived from robust RGB channel statistics.
5. Apply saturation adjustment derived from reference saturation distribution.
6. Apply subtle split-tone-style offsets to shadows and highlights when the descriptor supports it.
7. Clamp every RGB output channel to `[0, 1]`.
8. Store each Domain/export sample as RGB triplets in red-fastest order. Rendering-specific RGBA expansion with alpha `1.0` belongs to the Core Image rendering task.

## Style Transform

The MVP1 transform should be useful but restrained. The goal is to create a reusable personal color roll, not to exactly clone the reference image or produce unstable extreme grades.

Transform components:

- Tone curve: maps shadows, midtones, and highlights using percentile-based control points.
- Channel balance: shifts RGB channels gently toward the reference color bias.
- Saturation: scales chroma around luminance, capped to avoid neon or gray collapse.
- Split tone: applies separate low-strength color bias in shadow and highlight ranges.

Each component must have implementation-defined caps. Caps are part of product safety: they keep odd reference images from creating unusable LUTs.

## Ordering

Recommended transform order:

1. Tone curve.
2. Channel balance.
3. Saturation adjustment.
4. Split-tone offset.
5. Final clamp.

The order must stay deterministic and be recorded in algorithm version metadata.

## State Management Logic

Once saved, the LUT data is immutable for that Film Roll. Intensity changes do not regenerate the LUT. Future algorithm updates should either migrate explicitly or keep existing Film Rolls on their original algorithm version.

## Validation

Generated LUTs must satisfy:

- Size is exactly `33` for MVP1 default.
- Sample count is `33 * 33 * 33`.
- Every Domain/export sample has three Float32 RGB channels.
- RGB values are finite and within `[0, 1]`.
- Rendering conversion must add alpha `1.0` when building Core Image color-cube data.
- Export RGB values match render RGB values before text formatting precision.

## Error States

- Style descriptor is missing required fields.
- LUT size is unsupported.
- Generated values contain NaN or infinity.
- Sample count or memory layout is invalid.

## Future Extension Points

- Additional LUT sizes.
- User-adjustable generation strength.
- Multiple named algorithm versions.
- Advanced skin-tone and neutral-gray protection controls or target-photo masks.
- Local AI-assisted descriptor generation, if fully offline and approved for MVP2.

## Documentation Updates Completed

This document defines identity cube generation, transform components, clamping, validation, and immutability for MVP1 LUTs.

Task 4 implementation records:

- `LUTGenerator` produces 33x33x33 Domain `LUT3D` values with `35937` samples and `107811` RGB values.
- Neutral descriptors preserve black and white corners as identity.
- Transform order is tone, channel balance, saturation, split-tone offset, and final clamp.
- The current transform is intentionally bounded and deterministic; richer percentile-derived control points remain future refinement.

Algorithm V2 implementation records:

- New photo-created Film Rolls default to algorithm version `mvp1.traditional.v2`.
- Transform order is filmic percentile tone, tonal-zone color balance, hue-selective saturation, neutral/skin soft protection, and final clamp.
- Luminance p1/p99 range compression, p50 midpoint correction, and p5/p95-derived contrast make outliers less dominant than the earlier min/max-style baseline.
- V2 remains deterministic and `.cube` export-compatible; imported `.cube` Film Rolls keep the imported-cube algorithm version and bypass V2 generation.
