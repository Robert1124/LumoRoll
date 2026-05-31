# Reference Image Analysis

## Purpose

Extract a compact style descriptor from one reference image. MVP1 analysis must be deterministic, fast, local, and explainable enough to test without model dependencies.

## Inputs

- Decoded reference image.
- Source color metadata when available.
- Algorithm configuration, including analysis downsample size and statistic bounds.

## Output: Style Descriptor

The style descriptor should include:

- Luminance histogram summary.
- Shadow, midtone, and highlight percentile values.
- Per-channel mean and robust percentile values.
- White-balance/channel-balance offsets.
- Saturation distribution summary.
- Optional warm/cool split-tone bias from shadow and highlight color tendencies.
- Analysis warnings, such as low contrast, extreme clipping, or too few useful pixels.

The descriptor is metadata, not a LUT. It can be persisted for debugging and future migration, but rendering should use the generated LUT.

## Normalization

MVP1 normalizes analysis input to SDR sRGB / Rec.709. If source metadata is unavailable or not supported, the app should assume sRGB and record the fallback in metadata.

The MVP1 pipeline should not attempt HDR tone mapping, Log transforms, or advanced Display P3 preservation.

## Downsample Strategy

Reference analysis uses a downsampled image, not the full-resolution original. The goal is stable style statistics with lower memory use.

Recommended implementation direction:

- Preserve aspect ratio.
- Limit the long edge to an implementation-defined analysis size. Task 4B uses a conservative 128-pixel max long edge to keep the first decoded bitmap path small and deterministic; later profiling can tune this upward to 512 or 1024 pixels.
- Use a high-quality resize filter when drawing into the analysis bitmap.
- Ignore fully transparent pixels if alpha is present.
- Avoid loading multiple full-resolution buffers at once.

## Statistics

Use robust statistics instead of single-pixel extremes:

- Luminance percentiles, such as 1%, 5%, 50%, 95%, and 99%.
- RGB channel means and percentiles after normalization.
- Saturation mean and percentiles from an HSV/HSL-like representation.
- Shadow/midtone/highlight masks based on luminance ranges.
- Average shadow hue bias and highlight hue bias for split-tone approximation.

Outlier handling should ignore a small percentage of clipped dark and bright pixels so borders, specular highlights, and sensor noise do not dominate the look.

## Edge Cases

- Very small images: analyze at native size and record a low-confidence warning.
- Monochrome or near-monochrome images: reduce saturation transform strength.
- Very low contrast images: bound contrast expansion to avoid harsh LUTs.
- Very high contrast images: avoid crushing shadows or clipping highlights further.
- Heavy color cast: cap channel correction so the generated LUT remains usable.
- Transparent images: analyze non-transparent pixels; fail if too few useful pixels remain.
- Corrupt or unsupported files: return a decode failure for product UI to handle.

## Data Dependencies

- Core Image or Image I/O decoding and color conversion.
- Storage for optional descriptor metadata and analysis warnings.
- QA fixtures for deterministic expected descriptor ranges.

## Relationship To Other Modules

Reference analysis feeds LUT generation. It does not directly render output images and does not mutate stored Film Rolls after creation.

## Future Extension Points

- Skin-tone protection masks.
- Neutral-gray detection and protection.
- Local model-assisted style classification.
- Multiple-reference style averaging outside MVP1.

## Documentation Updates Completed

This document defines the reference analysis contract, normalization rules, downsample behavior, and edge cases for MVP1.

Task 4 implementation records:

- `ReferenceImageAnalyzer.Descriptor.neutral` is available as the deterministic baseline for MVP1 generation tests and early integration.
- A simple pixel-stat API computes luminance mean, contrast, saturation mean, channel bias, warmth, and warnings while ignoring transparent pixels.
- `Data` analysis decodes the first ImageIO image, draws it into an sRGB RGBA analysis bitmap with a 128-pixel max long edge, normalizes byte channels to `0...1`, preserves alpha from formats that provide it, and feeds those pixels into the same statistic path.
- Corrupt, unsupported, empty, or fully transparent decoded images throw `LumoError.importFailed` so product UI can present an import failure state.

Algorithm V2 implementation records:

- The descriptor now includes robust luminance percentiles, tonal-zone RGB biases and warmth, hue-sector saturation tendencies, and soft protection strengths for neutral and skin-hue samples.
- Percentile statistics replace single-pixel min/max as the tone-map source so clipped borders, specular highlights, and isolated dark pixels do not dominate generated LUTs.
- Low-alpha pixels are excluded from descriptor statistics so mostly transparent colored pixels do not bias the generated LUT.
- The analyzer remains deterministic, local-only, and based on the existing SDR sRGB downsample path.
