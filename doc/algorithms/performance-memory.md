# Performance and Memory

## Purpose

Define MVP1 constraints for keeping image analysis, LUT generation, preview, and full-resolution rendering responsive and memory-conscious on iPhone.

## Principles

- Analyze downsampled reference images.
- Render previews from downsampled target images.
- Render full-resolution output only for explicit save/share actions.
- Keep the generated LUT small and reusable.
- Avoid holding several full-resolution image buffers at the same time.
- Use a Metal-backed `CIContext`.
- Reuse a shared `CIContext` instead of creating one per render.
- Fall back to a CPU/Core Image context when Metal is unavailable.

## LUT Memory

A 33x33x33 LUT has `35937` samples. Stored as Float32 RGBA:

```text
35937 samples * 4 channels * 4 bytes = 574,992 bytes
```

This is small enough to store with each Film Roll in MVP1, while thumbnails and full-resolution images need stricter memory handling.

## Reference Analysis

Reference analysis should downsample before statistics are computed. The full-resolution reference can be stored, but analysis should use a bounded working image.

Risks:

- Large source images may decode into high memory buffers.
- Wide images may create large intermediate buffers if resized late.
- Unsupported color metadata can trigger unexpected conversion behavior.

Mitigations:

- Decode with downsample options where possible.
- Normalize once into the working color assumption.
- Release intermediate buffers promptly.
- Record fallbacks in metadata.

## Preview Rendering

Previews should use dimensions matched to the UI viewport rather than source resolution. This applies to before, split, and after states.

The split preview should not require two separate full-resolution rendered images. It can compose from the original preview and processed preview at preview size.

Current `CoreImageRenderer` preview and thumbnail rendering accepts a maximum pixel dimension. The renderer normalizes image origin to `0,0`, scales only when the source exceeds the bound, and renders into exact bounded integer dimensions before LUT application and blending.

## Full-Resolution Rendering

Full-resolution rendering is reserved for:

- Saving processed output into the Film Roll.
- Saving explicitly to the system Photos library.
- Sharing processed output.

If full-resolution render memory is too high, implementation should consider:

- Rendering at the decoded image size only once.
- Avoiding duplicate retained buffers.
- Using autorelease boundaries where relevant.
- Future tiled rendering if required.

Current limitation: full-resolution rendering is not tiled. Very large source images can still create large Core Image intermediates for the prepared original, LUT output, blend mask, and final blended image.

## Error States

- Memory pressure during decode.
- Memory pressure during full-resolution render.
- Core Image render failure.
- Export file write failure due to storage limits.
- Thumbnail generation failure.

Product UI should show friendly retry or reduced-size messaging rather than losing the Film Roll.

## Test Strategy

Performance fixtures should include:

- Small images.
- Typical iPhone photos.
- Large high-megapixel photos.
- Wide panoramas.
- Very dark, very bright, and high-saturation images.
- Images with alpha.

Tests should track peak memory where practical once implementation exists.

Current automated coverage uses deterministic small bitmap fixtures for LUT cube expansion and red-fastest ordering, intensity endpoints, midpoint blending, semi-transparent alpha preservation, LUT immutability, and preview/thumbnail dimension bounds. Large-image memory profiling remains a QA follow-up.

## Future Extension Points

- Tiled full-resolution rendering.
- Background render queue with progress.
- Device-class-based render size limits.
- HDR and wider color pipeline memory budgets outside MVP1.

## Documentation Updates Completed

This document records downsample boundaries, shared context reuse, CPU fallback, full-resolution rendering limits, current non-tiled limitation, LUT memory size, and performance risks for MVP1.
