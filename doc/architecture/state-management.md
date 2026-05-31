# State Management

## Purpose

Define how SwiftUI and Observation should model state for MVP1 without leaking long-running work or service details into view structs.

## Baseline

- Use SwiftUI value state for small local UI controls.
- Use `@Observable` feature models for screen/flow state.
- Use async tasks in feature models or use cases, not in low-level view layout.
- Keep image data and rendered output references as file URLs or lightweight IDs where possible.

## State Categories

View-local state:

- Search query.
- Selected preview mode: before, split, after.
- Split handle position.
- Slider drag value before committing.
- Temporary focus state.

Feature model state:

- Library load status.
- Film Roll list.
- Create flow step.
- Selected imported reference.
- Analysis/generation progress.
- Name validation.
- Apply flow selected photo.
- Render status and current preview asset.
- Save/export/share status.

Domain state:

- Film Roll metadata.
- Reference image asset identity.
- LUT descriptor and file identity.
- Processed photo records.

Persistent state:

- `manifest.json`.
- Asset files under the app storage layout.

## Loading States

Use explicit state enums for async work:

```text
idle -> loading/processing -> ready
idle -> loading/processing -> failed(error)
```

Do not represent processing by optional values alone.

Task 6B feature models use Swift Observation (`@Observable`) and are main-actor UI state owners:

- `LibraryFeatureModel.State`: `idle`, `loading`, `loaded([FilmRoll])`, `failed(String)`. An empty library is `loaded([])`, not an error.
- `CreateFilmRollFeatureModel.Phase`: `idle`, `importing`, `processing`, `naming`, `saving`, `complete(FilmRoll)`, `failed(String)`. Draft name and selected reference data remain in memory after save failure so the user can retry.
- `FilmRollDetailFeatureModel.State`: `idle`, `loading`, `loaded(FilmRoll)`, `failed(String)`.
- `FilmRollDetailFeatureModel.ExportState`: `idle`, `exporting`, `ready(ExportLUTResult)`, `failed(String)`.
- `FilmRollDetailFeatureModel.ManagementState`: `idle`, `renaming`, `removing`.
- `ApplyPhotoFeatureModel.SaveState`: `idle`, `saving`, `saved(FilmRoll)`, `failed(String)`.
- `ApplyPhotoFeatureModel.SaveToPhotosState`: `idle`, `saving`, `saved(String)`, `failed(String)` for explicit Photos writes. This state must remain separate from `SaveState` so a Photos save never implies that a Film Roll frame was appended.

Feature model intents are lightweight route flags or IDs only. They do not carry image bytes, picker adapters, concrete Photos permissions, Core Image objects, or serialized `.cube` work.

Refresh failures after loaded content are non-destructive:

- Library and detail reload failures preserve the previous `loaded` state and publish `lastErrorMessage`.
- Initial load failures may still move to `failed(String)` because there is no previous content to preserve.

Duplicate operation guards:

- Library load/reload returns immediately while already `loading`.
- Create save returns immediately while already `processing` or `saving`.
- Detail export returns immediately while already `exporting`.
- Detail rename/remove returns immediately while another management action is active.
- Apply save-to-Film-Roll returns immediately while already `saving`.
- Apply Save to Photos returns immediately while already `saving`.
- Apply target selection returns immediately while Save to Film Roll or Save to Photos is `saving`; the explicit save owns the selected target until it finishes.

Starting a new Create import or selecting a new reference image clears the previous `savedFilmRoll` completion state. A completed roll must not remain observable once the user begins a new create attempt.

Stale async completion is ignored after user input changes:

- Apply save-to-Film-Roll captures the selected target version before awaiting Domain work. Target selection is blocked while `saving`; the captured version/path guard remains as a defensive stale-completion check before publishing `saved` or `failed`.
- Create save captures the current draft/reference version before awaiting Domain work. If the user starts a new import or selects a different reference before the save resumes, the old create result must not publish `savedFilmRoll`, `complete`, or `failed` over the new create attempt.

## Concurrency Rules

- Feature models run user-triggered tasks using Swift concurrency.
- Repository writes are serialized to avoid manifest corruption. `FileFilmRollRepository` is an actor so manifest reads/writes and encoder/decoder access are actor-isolated without production `@unchecked Sendable`.
- `ApplyFilmRollUseCase` serializes each load-render-save apply operation through an internal async gate. This keeps concurrent applies for the same roll from loading the same old manifest and losing one processed-photo record through last-save-wins behavior.
- Rendering and LUT generation run off the main actor.
- UI state updates return to the main actor.
- Cancel obsolete render tasks when intensity, image, or roll changes.
- Swift 6 isolation note: Domain protocols and use-case value types that cross feature model boundaries are `Sendable`. Feature models keep injected Domain dependencies out of Observation tracking while all observable state mutations stay on the main actor.

## Intensity State

Intensity is a preview/render parameter, not a LUT mutation. Changing intensity must blend original and LUT-processed output and must not regenerate or rewrite the Film Roll LUT.

## Empty States

- Empty library: show create affordance and a friendly Film Roll oriented empty state.
- Empty processed photos in detail: show the reference sample as the projected frame and only bottom film frame; the projector plus affordance is hidden in this iteration.
- Empty import selection: show picker/drop-zone state.

## Error States

- Import unavailable or cancelled.
- Unsupported image type.
- Reference analysis failed.
- LUT generation failed.
- Render failed.
- Save to app storage failed.
- Save to Photos denied or failed.
- Export/share cancelled or failed.

## Future Extension Points

- Add persistence-backed state restoration.
- Add progress reporting from processing services.
- Add batch rendering by extending feature model states, not by moving processing into views.
