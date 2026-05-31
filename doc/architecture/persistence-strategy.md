# Persistence Strategy

## Purpose

Define how MVP1 stores Film Rolls, generated LUTs, thumbnails, reference images, processed results, and metadata locally.

## Decision

Use a file-backed repository in the app container:

```text
Application Support/LumoRoll/
```

The repository owns:

- A root `manifest.json` index.
- Per-roll asset folders.
- Atomic writes for metadata and assets.
- Cleanup of temporary files after failed saves.

SwiftData is not used in MVP1 unless a later documented decision shows the manifest approach is insufficient.

## Why File-Backed

- The app stores binary assets as first-class data.
- MVP1 query needs are small: list rolls, load one roll, append processed photo, update metadata.
- A manifest keeps schema explicit and portable.
- `.cube` LUT export maps naturally to file assets.
- It avoids adding database migration risk before the app has real query complexity.

## Repository Contract

The Domain `FilmRollRepository` should support:

- Load all Film Roll summaries.
- Load one Film Roll detail by ID.
- Create a Film Roll atomically after reference image, LUT, thumbnail, and metadata are available.
- Append a processed photo result.
- Update roll metadata if rename/delete is added.
- Delete a roll and its assets if deletion enters MVP1.
- Resolve app-private asset URLs for render/export services through controlled methods.

Task 6A introduced a separate Domain asset-writing boundary for use cases. `FilmRollAssetWriting` reserves internal roll IDs, stores the reference image plus generated thumbnail, discards staged roll assets after failed create saves, and writes staged `.cube` export text. The concrete file-backed implementation remains a later integration task; use cases must not derive storage paths from user-visible names.

Task 10L adds local model-assisted-ready metadata to the persisted `FilmRoll` value. A Film Roll created from a sample image may carry `sampleAnalysisPackage`, which includes sample quality, color statistics, scene lighting, style profile, coverage/confidence, and render profile seed. `.cube`-imported rolls may leave this value absent. Repository persistence continues to treat the manifest as the source of truth and writes the package inline with the roll metadata.

Saved `ProcessedPhoto` records may carry `adaptiveRenderMetadata` for Apply-time target analysis and adjustment. This metadata describes how the app rendered that specific target photo; it does not mutate the saved base LUT and is not used by `.cube` export.

## Manifest

`manifest.json` should be the source of truth for metadata and asset references. It should store relative paths, not absolute container paths.

Expected metadata:

- Schema version.
- Roll ID.
- User-facing name.
- Creation and update timestamps.
- Reference image asset path.
- Reference thumbnail path.
- LUT binary path.
- `.cube` path if cached.
- Palette summary.
- Processed photo records.
- Processing version.
- Optional sample analysis package for sample-created rolls.
- Optional adaptive render metadata for processed photos.

## Atomicity

Creation should stage files first, then commit manifest last. If manifest commit fails, staged files should be cleaned up or left in a temporary folder that is safe to purge on next launch.

Manifest writes should use an atomic replace pattern.

Create use case ordering should avoid asset writes for invalid names or failed LUT generation. After successful LUT generation and thumbnail rendering, asset storage can reserve a roll ID and stage the reference assets before repository save.

If reference asset writing fails after ID reservation, or if repository save fails after reference asset writing succeeds, the create use case must request `discardFilmRollAssets(filmRollID:)` and preserve the original error. If apply renders processed outputs but repository save fails, the apply use case must request `PhotoRendering.discardRenderedPhoto(_:)` and preserve the original save error. Cleanup hooks are best-effort; cleanup failure must not hide the primary failure.

Concrete cleanup adapters must validate path components before deleting folders. `discardFilmRollAssets(filmRollID:)` may only remove a folder under `film-rolls/<safe-roll-id>/`, and rendered-photo cleanup may only remove a processed-photo folder shaped like `film-rolls/<safe-roll-id>/processed/<safe-photo-id>/...` under `AssetStore.rootURL`.

Apply operations have a wider race than a single repository write: load, render, append metadata, then save. `ApplyFilmRollUseCase` serializes that full sequence so concurrent applies against one use-case instance merge processed photos instead of overwriting each other with a stale manifest snapshot.

## Errors

Repository errors should be typed enough for features to distinguish:

- Storage unavailable.
- Manifest decode failed.
- Asset missing.
- Write failed.
- Data version unsupported.
- Cleanup failed.

## Future Extension Points

- Add migrations through `schemaVersion`.
- Add search/sort metadata without changing asset paths.
- Swap repository implementation for iCloud sync in MVP2.
- Introduce SwiftData only for richer queries while keeping files as asset storage.
