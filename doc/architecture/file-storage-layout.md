# File Storage Layout

## Purpose

Define the app-private file layout for MVP1 assets under Application Support.

## Root

```text
Application Support/
  LumoRoll/
    film-rolls/
      <roll-id>/
        manifest.json
        reference/
          original.<ext>
          thumbnail.jpg
        lut/
          cube-33.lutbin
          export.cube
        processed/
          <photo-id>/
            original.<ext>
            rendered.jpg
            thumbnail.jpg
            metadata.json
    tmp/
      imports/
        <import-id>/
          original.<ext>
```

`manifest.json` is the per-roll source of truth for MVP1 metadata. A root manifest/index can be added later if listing performance or migration needs justify it.

Task 10L stores sample analysis package and adaptive render metadata inline in `manifest.json`. The physical asset layout does not change. A future migration may split large diagnostics into `metadata.json` files, but the first local implementation keeps the metadata small enough for the manifest.

## Naming Rules

- Use stable generated IDs for folders.
- Roll and processed photo folder IDs must be path-safe single components.
- Keep user-provided names out of file paths.
- Store original extension where safe.
- Store relative paths in metadata.
- Keep temporary writes under `tmp/` until committed.
- Resolve app-owned relative paths through `AppAssetURLResolver` before reads or writes outside the storage adapter.

## Asset Types

Staged import original:

- App-owned temporary copy of a user-selected reference or target photo.
- Stored under `tmp/imports/<import-id>/original.<ext>` before the photo is committed into a Film Roll.
- Import IDs must be generated path-safe IDs and must not include user-visible filenames.
- Staged import paths are relative to `Application Support/LumoRoll/` so downstream processing never depends on PhotosPicker or security-scoped file URLs.

Reference original:

- The imported image used to generate the Film Roll.
- Exactly one per Film Roll in MVP1.
- For Film Rolls created from imported `.cube` files, this is a generated PNG preview sampled through the imported LUT. It is app-generated, not a copy of a user photo, and keeps the one-reference-asset storage contract intact.

Reference thumbnail:

- Small image for cards and strips.
- Generated locally.

LUT binary:

- Internal representation optimized for applying the LUT.
- For imported `.cube` rolls, the manifest stores the parsed LUT values directly using the same LUT model as generated rolls.

`.cube` export:

- Text file generated from the LUT.
- Task 8A writes the export-ready cached file as `lut/export.cube` inside the Film Roll folder.
- The user-facing suggested filename is kept separate from the internal cache path so Film Roll names do not become app-container paths.

Processed original:

- MVP1 stores an app-owned copy of the source photo used for an applied result.
- The Domain apply use case generates the processed photo ID before rendering and passes it to the renderer so `processed/<photo-id>/` matches manifest metadata.
- Storing the original keeps Film Roll records independent of temporary picker URLs and supports future re-rendering or share/save retry flows.

Rendered result:

- Output image saved into the Film Roll.
- Stored as `processed/<photo-id>/rendered.jpg` in MVP1.
- App-only adaptive post process may be baked into this JPEG when the roll has a sample analysis package. The exported `.cube` is still only the base LUT.

Processed thumbnail:

- Small preview for strip/card use.
- Stored as `processed/<photo-id>/thumbnail.jpg` in MVP1.

## Storage Policy

- Store all app library assets inside the app container.
- Do not write to the system Photos library unless the user explicitly chooses Save to Photos.
- Do not rely on external file URLs staying available after import; copy imported assets into app storage.
- Exclude transient `tmp/` files from user-visible state.
- Manifest asset paths are stored relative to `Application Support/LumoRoll/`, for example `film-rolls/<roll-id>/reference/thumbnail.jpg`.
- Task 8A concrete adapters write reference originals, reference thumbnails, processed originals, rendered JPEGs, thumbnails, and cached `.cube` files under the owning Film Roll folder only.
- Files-based `.cube` imports are not staged under `tmp/imports/` because they are text LUT data, not image assets. The parsed LUT is persisted only after the user names and saves the Film Roll.
- Cleanup operations validate the expected folder shape before deletion. Roll cleanup only removes `film-rolls/<safe-roll-id>/`; processed cleanup only removes `film-rolls/<safe-roll-id>/processed/<safe-photo-id>/`.
- Task 8B path resolution must reject absolute paths, empty paths, and `..` traversal before reading display images or staged imports.
- Task 8B1 also rejects `file://` strings and malformed components, and confirms resolved URLs remain under `Application Support/LumoRoll/`.

## Risks

- Storing both originals and rendered outputs can grow quickly.
- Missing assets referenced by manifest need graceful recovery.
- User names may contain path-unsafe characters, so names must never become folder names.
- Task 8A full-resolution rendering is not tiled yet; large source files still need Task 8/QA memory profiling.

## Future Extension Points

- Add cache eviction for thumbnails or temporary rendered previews.
- Add storage size reporting.
- Add migration folders for future LUT resolutions or HDR assets.
