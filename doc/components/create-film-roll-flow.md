# Create Film Roll Flow

## Purpose

Guide the user through importing one reference image or one `.cube` LUT, naming the Film Roll, generating or importing the local LUT on save, and saving it to the app library.

## Inputs

- Reference image from PhotosUI or Files, or a UTF-8 `.cube` file from Files.
- User-provided Film Roll name.
- Create use case input: user-visible roll name and either reference image `Data` with optional preferred file extension, or `.cube` text `Data` with optional original filename.
- Create use case dependencies: LUT generation, `.cube` LUT import, imported-LUT preview rendering, thumbnail rendering, asset writing, repository save.

## Outputs

- New Film Roll persisted in app storage.
- Library refresh.
- Success, failure, or cancellation state.

## Data Dependencies

- Temporary imported reference image.
- Generated LUT or imported `.cube` LUT after the explicit save action.
- Generated reference thumbnail after the explicit save action.
- Palette summary after local analysis.
- Required name before final save.
- Reserved internal roll ID; user-visible names must not be used as storage paths.

## Relationship To Other Modules

- Owned by Features.
- Uses SystemIntegrations for import.
- Uses Domain create use case.
- Domain use case calls Processing and Storage through protocols.
- `LUTGenerating` receives the actual reference image bytes in `LUTGenerationRequest`; Processing analyzes those bytes before generating the 33x33x33 LUT and sample analysis package.
- `LUTImporting` receives `.cube` text bytes for file-imported LUTs. Imported LUTs skip reference analysis and store the parsed LUT directly.
- `LUTPreviewRendering` creates a local PNG preview from an imported LUT so the existing one-reference-asset Film Roll storage model remains unchanged.
- `FilmRollAssetWriting` reserves the roll ID and stores the reference image plus generated thumbnail.
- If reference asset storage fails after a roll ID is reserved, or if repository save fails after reference assets are written, `CreateFilmRollUseCase` calls `FilmRollAssetWriting.discardFilmRollAssets(filmRollID:)` and rethrows the original error.
- Uses DesignSystem button, card, palette, field, and progress components. MVP1 does not use a visual stepper for Create Film Roll.

## State Management

Feature model states:

- `idle`.
- `importing`.
- `naming`.
- `processing`.
- `saving`.
- `complete(FilmRoll)`.
- `failed(String)`.

The feature model owns `draftName`, selected reference image `Data`, optional preferred file extension, selected `.cube` `Data`, and optional `.cube` filename. Selecting either source keeps the user on the same Create Film Roll page and moves the draft to `naming` so the source state and name field are available together. Local LUT analysis/generation or `.cube` parsing is deferred until the explicit save action. `canSave` is true only when a source is selected and the trimmed name is non-empty. Calling save with a blank name must be blocked before `CreateFilmRollUseCase` is invoked; the app must not auto-save an `Untitled Roll`.

On save failure, the draft name and selected reference data remain available for retry. Duplicate save requests while the phase is `processing` or `saving` return immediately and must not start a second create use-case call.

Starting a new import clears the selected reference, selected `.cube`, preferred extension, and prior `savedFilmRoll`, then moves to `importing`. Selecting a new reference or `.cube` clears any prior completion and moves to `naming`, so old success state cannot leak into a new create attempt.

If a save is already awaiting Domain work and the user starts a new import or selects a different reference, the feature model treats the old save completion as stale. The old result must be ignored so it cannot overwrite the new reference, `importing`/`naming` phase, or cleared `savedFilmRoll`.

View-local state:

- Text field focus.
- Add Reference source dialog state.
- Native Photos picker and Files importer presentation state.

## Error States

- User cancels import.
- Unsupported or unreadable image.
- Unsupported, malformed, non-UTF-8, or non-3D `.cube` LUT.
- Analysis fails.
- LUT generation fails.
- Thumbnail generation fails.
- Name is empty.
- Roll ID reservation fails.
- Reference asset write fails.
- Storage save fails.

Cleanup failure must not replace the primary create error. The cleanup boundary is best-effort and exists to prevent staged reference assets from becoming unmanaged if final manifest/repository save fails.

## Empty States

The one-page create form shows one `Add a reference` preview/drop-zone state before a photo or `.cube` file is selected. Tapping it opens a source choice for Photos or Files; the separate inline Photos and Files buttons are not shown. The name field remains part of the same page, but Save stays disabled until both a source and valid name are present.

## Future Extension Points

- Name suggestions from palette or location metadata if local-only and privacy-reviewed.
- Multiple reference images in MVP2.
- Advanced LUT controls after baseline creation.

## Task 7B Implementation Note

`CreateFilmRollScreen` is a SwiftUI shell for the one-page create flow: reference import, selected-reference preview, required name, and Save. The Step 1 copy is `Pick a photo sample or a cube LUT`; the empty preview says `Add a reference`. The view presents PhotosUI and file import through a single Add Reference source choice instead of inline Photos and Files buttons. Save remains disabled until a real importer supplies reference data or `.cube` data and the trimmed name is non-empty. It shows `33x33x33` copy and keeps Save disabled until `CreateFilmRollFeatureModel.canSave` is true. Reference-image save now persists sample analysis, coverage/confidence, and render profile seed with the Film Roll; `.cube` imports keep the base LUT path and may omit sample analysis metadata.

## Task 8B2 Implementation Note

Task 8B2 replaces the inert import closures with PhotosUI and file importer presentation in the SwiftUI boundary.

- Photos import uses PhotosPicker item data for still images after the user chooses Photos from the Add Reference source dialog, does not request broad Photos-library permission, and lets staging detect the encoded data type instead of trusting the picker item's first advertised content-type extension.
- Files import accepts HEIC/HEIF, JPEG, PNG, and `.cube` files through `.fileImporter`.
- Image sources are staged through `PhotoImportStagingService` before the feature model receives bytes. `.cube` files are read as security-scoped UTF-8 text data and are not staged as photos.
- Each import attempt gets a generation ID. If an older Photos or Files import finishes after a newer import has started, the older staged import is discarded and cannot overwrite the newer selection or error state.
- The selected reference preview uses the display image store and staged `relativePath`; no image file is decoded synchronously in `body`.
- Import cancellation keeps the prior draft intact if no new image was staged.
- Import failure surfaces user-facing error copy in the create screen.
- Staged reference cleanup is best-effort after cancel, replacement, stale completion, staged-read failure, or successful save because the create model stores the selected reference bytes independently.

## Task 10 Cube Import Note

Files-based Create Film Roll import now accepts `.cube` LUT files. Save remains disabled until the user selects a photo or `.cube` source and enters a non-empty name. Imported `.cube` files are parsed locally on Save; malformed files fail recoverably and keep the draft available. The parsed LUT is stored in the Film Roll manifest, and a generated PNG preview is stored as the reference original so existing library/detail components can render the roll without adding a second reference model in MVP1.

The app bundle declares `com.lumoroll.cube` as an imported document type for the `cube` filename extension and conforms it to `public.plain-text`. This declaration is required so iOS Files can recognize and enable `.cube` files in the Create Film Roll file picker instead of graying them out.

## Task 9 Create Flow Decision

The current MVP1 implementation intentionally performs reference analysis, LUT generation, thumbnail rendering, asset storage, and repository save inside the explicit Save action after the user has named the Film Roll. MVP1 no longer includes a separate Step 2 panel; any copy about building a 33x33x33 color roll belongs to the one-page create form or save-time progress state, not a separate pre-save generated state.
