# Local Film Roll Storage

## Purpose

Provide the concrete app-private repository for Film Roll metadata and assets.

## Inputs

- Create/update/delete requests from Domain use cases.
- Asset files staged by import or processing.
- Metadata values.

## Outputs

- Film Roll summaries and details.
- Persisted `manifest.json`.
- App-private asset files.
- Typed storage errors.

## Data Dependencies

- `Application Support/LumoRoll`.
- Per-roll manifests under `LumoRoll/film-rolls/<roll-id>/manifest.json`.
- Per-roll asset folders under generated ID folder names.
- Temporary staging folder.

## Relationship To Other Modules

- Concrete implementation in Storage.
- Implements Domain `FilmRollRepository`.
- Called by Domain use cases.
- Never called directly by SwiftUI views.

## State Management

Repository manages serialized writes and manifest caching if needed. Feature state is updated only through use case results.

Task 8B display and import helpers read app-owned relative paths through a resolver rooted at `Application Support/LumoRoll/`. These helpers do not mutate manifests; they only stage temporary imports or load display-sized images.

Task 8B1 concrete support services:

- `AppAssetURLResolver` validates app-owned relative paths before reads or writes.
- `PhotoImportStagingService` writes staged originals under `tmp/imports/<import-id>/original.<ext>`.
- `LocalPhotoImageLoader` reads only resolver-approved app-owned paths and returns bounded display image data.

## Error States

- Application Support unavailable.
- Manifest missing or corrupt.
- Asset file missing.
- Atomic write failure.
- Disk full.
- Unsupported schema version.
- Unsafe relative path rejected before reading or staging assets.

## Empty States

If no manifest exists on first launch, create an empty manifest in memory and write it on first successful save.

## MVP1 Implementation Notes

- `AssetStore` receives an injected base URL so tests can use a temporary directory and production can pass Application Support.
- Folder names use generated UUID-style roll IDs and never derive from user-visible Film Roll names.
- `FileFilmRollRepository` is an actor that writes `FilmRollManifest` JSON with stable ISO 8601 dates and atomic manifest writes.
- MVP1 Task 3 persists metadata and folder lifecycle only; copying image bytes and generated LUT export assets is deferred to later import, rendering, and export tasks.
- Task 8B support services stage temporary import originals under `tmp/imports/<import-id>/` and resolve display image paths without exposing file I/O to SwiftUI view bodies.

## Future Extension Points

- Schema migrations.
- Storage size cleanup.
- iCloud-backed repository.
- Optional SwiftData index if query needs grow.
