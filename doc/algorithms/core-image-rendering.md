# Core Image Rendering

## Purpose

Define how LumoRoll applies generated LUTs to photos for preview, save, share, and internal thumbnails using Core Image.

## Inputs

- Source photo as a `CIImage` or decoded image source.
- Stored Float32 RGBA LUT cube data.
- LUT size, default `33`.
- Working color space assumption: SDR sRGB / Rec.709.
- Intensity value for downstream blending.
- Requested render size: preview, thumbnail, or full-resolution output.

## Outputs

- Preview image for before / split / after UI.
- Processed full-resolution image for save/share.
- Thumbnail image for Film Roll library and detail.

## Rendering Decisions

- Use Core Image for image processing.
- Use a Metal-backed `CIContext` for performance.
- `CoreImageRenderer` creates a shared `CIContext` with `MTLCreateSystemDefaultDevice()` when Metal is available.
- If no Metal device is available, `CoreImageRenderer` falls back to a normal Core Image `CIContext`.
- Use `CIColorCube` or `CIColorCubeWithColorSpace` with the stored Float32 RGBA cube data.
- Prefer `CIColorCubeWithColorSpace` when implementation can explicitly pass the sRGB/Rec.709 working color space.
- Current implementation attempts `CIColorCubeWithColorSpace` first with an sRGB color space and falls back to `CIColorCube` if needed.
- Domain `LUT3D` values are stored as RGB triplets in red-fastest order. Rendering expands them to Float32 RGBA cube data by appending alpha `1.0` for each sample.
- Keep rendering separate from SwiftUI views.
- Keep storage separate from rendering.

## Pipeline

1. Receive a decoded `CIImage`.
2. Normalize the image extent to origin `0,0`.
3. Downsample when rendering previews or thumbnails by bounding the longest side and rendering into exact integer pixel dimensions.
4. Apply the stored LUT through Core Image.
5. Blend original and LUT output according to intensity.
6. Render to an sRGB `CGImage` using RGBA8 output.
7. Save, share, or display the rendered output according to product flow.

The current API is lower-level and returns `CGImage`:

```swift
CoreImageRenderer().render(
    image,
    applying: lut,
    intensity: intensityPercentage,
    size: .preview(maxPixelDimension: 1200)
)
```

Full path-based `PhotoRendering` conformance is intentionally left for the storage/use-case integration layer because processed and thumbnail destination paths are repository-owned decisions.

## Preview vs Full Resolution

Previews should use downsampled images to keep UI responsive. Full-resolution rendering should happen only when the user explicitly saves, shares, or exports a processed photo.

The preview output must be visually consistent with full-resolution output, but minor differences from resize filtering are acceptable if documented in QA.

`CoreImageRenderer.RenderSize` currently supports:

- `.fullResolution`
- `.preview(maxPixelDimension:)`
- `.thumbnail(maxPixelDimension:)`

Preview and thumbnail render sizes clamp the requested maximum pixel dimension to at least `1` and do not upscale images smaller than the bound.

When the scaled aspect ratio produces fractional pixel dimensions, `CoreImageRenderer` chooses bounded integer target dimensions and applies exact x/y scale factors to fill that target extent. This avoids transparent padding from rendering a fractional transformed extent into a larger integral rectangle.

## Data Dependencies

- Stored Film Roll LUT data.
- Target photo image data.
- Architecture-owned rendering service or processing module.
- Product-owned save/share/export flow.

## Error States

- Source photo cannot be decoded.
- LUT data is missing, corrupt, or has the wrong sample count.
- Core Image filter creation fails.
- Render output exceeds memory budget.
- Output color conversion or file encoding fails.

## Empty States

Rendering is unavailable until both a Film Roll LUT and a target image exist.

## Future Extension Points

- Wider color spaces and HDR pipelines.
- Tiled rendering for very large images.
- Background processing queues and progress reporting.
- Additional Core Image filters before or after LUT application if product scope expands.

## Documentation Updates Completed

This document records the Core Image rendering contract, Metal-backed context decision, RGB-to-RGBA cube expansion, preview/full-resolution split, tested lower-level API, and failure modes.
