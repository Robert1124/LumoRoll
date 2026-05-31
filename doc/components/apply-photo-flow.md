# Apply Photo Flow

## Purpose

Let the user select a target photo, preview the selected Film Roll LUT with adjustable intensity, and save the processed result back into the current Film Roll only after explicit confirmation.

## Inputs

- Film Roll ID.
- Imported target photo.
- Default intensity value.
- Import source choice: Photo Library or Files.
- Optional initial staged target path from Film Roll Detail.
- Optional initial import source for direct importer presentation.
- Optional edit context from Fullscreen Viewer: processed photo ID, stored original path, and current intensity.

## Outputs

- Saved processed photo in the Film Roll after the user taps `Save`.
- Replacement of an existing processed photo when an edit context is supplied.
- No Photos library write from this flow.

## Data Dependencies

- Film Roll LUT.
- Target photo temporary file.
- Rendered final output.
- Current intensity.

## Relationship To Other Modules

- Owned by Features.
- Uses a centered import target panel before selection.
- Calls Domain apply/save use cases.
- `ApplyFilmRollUseCase` loads the roll, sends `PhotoRenderRequest` to `PhotoRendering` with the saved sample analysis package when available, appends a `ProcessedPhoto` for new applies or replaces the matching processed photo for edits, updates the roll timestamp, and saves through `FilmRollRepository`.
- Processing performs LUT application and blending.
- Storage persists saved results through repository/asset protocols.
- The Domain apply use case intentionally has no `PhotoLibraryWriting` dependency.
- If repository save fails after rendering succeeds, `ApplyFilmRollUseCase` calls `PhotoRendering.discardRenderedPhoto(_:)` for the rendered processed/thumbnail outputs and rethrows the original save error.

## State Management

Feature model:

- Selected target photo path boundary for the later concrete importer.
- Intensity as a clamped `0...100` percentage; changing it must not regenerate the LUT.
- Preview mode and preview-render state drive the selected-target editor after import.
- Save-to-Film-Roll state: `idle`, `saving`, `saved(FilmRoll)`, or `failed(String)`.
- Save-to-Photos state remains separate in the feature model, but this screen does not show or trigger Save to Photos.
- On save failure, the selected target path and intensity remain available for retry.
- In edit mode, the model starts with the stored original path and prior intensity, and Save passes the existing processed photo ID so the use case replaces rather than appends.
- Duplicate save-to-Film-Roll calls are ignored while `saving`.
- Outside a save operation, selecting a different target photo resets stale save states to `idle` so old success/failure UI does not apply to the new target.
- Once Save to Film Roll starts, that save owns the selected target until it finishes. Target selection calls while saving are ignored so an in-flight save cannot be retargeted by later import UI.
- The custom Apply back/close action is disabled and ignored while saving, so it cannot discard the staged target file that the in-flight render still needs.
- Save completion still validates the captured target path/version before publishing `saved` or `failed`, keeping stale async completions from overwriting newer target state if this flow is extended later.

View-local:

- Split handle position.
- Import source confirmation dialog state.
- One-time initial import presentation state when a caller supplies Photo Library or Files.
- Temporary diagnostic Post/LUT buttons are not visible in the Apply editor.

## Error States

- Import cancelled.
- Unsupported image.
- Save to Film Roll failed.
- Roll missing.

Rendered-output cleanup is best-effort and must not mask the primary render/save error.

## Empty States

Before a target photo is selected, show one centered Import target panel and no preview. If a caller supplies an initial import source, present that native importer once and keep the same import panel available if the user cancels. If Film Roll Detail supplies an already staged target path, skip the empty import panel and show the selected-target preview editor immediately. The segmented Before/Split/After control, preview frame, intensity slider, Photos button, Files button, Save to Photos button, and Save button are hidden until a target is selected.

Tapping the Import target panel opens a source choice between Photo Library and Files. After a target photo is selected, the screen shows Before/Split/After preview, renders a temporary LUT preview for the current intensity, and exposes bottom `Save` and `Cancel` actions. `Save` stores the processed result in the current Film Roll. `Cancel` discards the staged target and temporary preview without saving. This flow does not write to Photos.

## Future Extension Points

- Batch apply.
- Crop/aspect adjustments.

## Task 7B Implementation Note

`ApplyPhotoScreen` binds the DesignSystem preview controls to `ApplyPhotoFeatureModel.previewMode` and `intensity`. `SplitPreview` owns only the local split fraction. In the Task 7B live root, apply models start without a selected target photo and no fake target path is preselected. Target/add tiles are tappable and call the injected `onImportTargetPhoto` boundary; the Task 7B root does not present PhotosUI, read files, or select placeholder paths, and the screen shows import unavailable copy in this build. Save to Film Roll and Save to Photos stay disabled until Task 8 supplies a real target selection path. Save to Film Roll calls the existing feature-model save path only after a target exists. Save to Photos only emits and clears the feature-model intent; Photos permission and writing remain Task 8.

## Task 8B2 Implementation Note

Task 8B2 wires the target import boundary to PhotosUI and `.fileImporter` in SwiftUI.

- Photos and Files target imports stage local still images into `tmp/imports`; PhotosPicker data lets staging detect the encoded type, while file imports preserve URL-extension validation through `stageImageFile(at:)`.
- The apply feature model receives only the staged app-owned relative path.
- Each target import attempt gets a generation ID. If an older Photos or Files import finishes after a newer import has started, the older staged import is discarded and cannot overwrite the newer target or error state.
- The before preview displays the selected target image through the display image store. After target selection, import controls are hidden instead of showing a target strip. Task 9 adds a temporary processed preview path for After and the processed side of Split.
- Changing intensity continues to update only feature-model state and never regenerates or mutates the Film Roll LUT.
- Successful staged targets are retained while the model needs the selected path. If a new target import finishes while the model is saving and the model rejects the selection, the newly staged import is discarded and the previous in-use staged path is kept. If the model accepts the new target, the previous staged import is discarded only after verifying the model no longer points at it.
- Task 8C replaces the Save to Photos stub with an explicit Photos write action.

## Superseded Task 8C Decision Note

Task 8C originally kept Apply sharing deferred and implemented two Apply destinations, including a separate `Save to Photos` path. The current product surface supersedes this: Apply no longer shows Save to Photos. The lower-level use case remains documented here because it still defines the separated Photos-write boundary for any future explicit output surface.

## Task 8C2 Implementation Note

Apply Save to Photos now uses `SaveAppliedPhotoToPhotosUseCase`, which loads the Film Roll, renders the selected target through `PhotoRendering`, writes only the rendered processed file through `PhotoLibraryWriting`, then discards the temporary render on both success and writer failure. Render failure does not call the writer or cleanup because no temporary rendered output exists. Repository save is not called, so the Film Roll manifest and Detail navigation remain unchanged.

`ApplyPhotoFeatureModel` owns a separate `SaveToPhotosState` (`idle`, `saving`, `saved(String)`, `failed(String)`). While either Save to Film Roll or Save to Photos is saving, target selection and duplicate save actions are ignored. A Photos save failure keeps the selected target and intensity for retry.

Task 8C2 follow-up fix: the Apply custom close action now preserves the selected staged target during in-flight Save to Film Roll and Save to Photos operations by ignoring close while `isSaving`.

## Task 9 Preview Rendering Decision

The Apply preview must display a real LUT-processed output for `After` and the processed side of `Split`. The preview renderer writes temporary app-owned JPEGs only; it does not append `ProcessedPhoto` records, does not write to Photos, and does not regenerate or mutate the Film Roll LUT when intensity changes.

## Task 10 UI Fix Note

`ApplyPhotoScreen` now hides preview chrome before target import and asks `PhotoDisplayImageStore` for the loaded display image aspect ratio. `SplitPreview` uses that aspect ratio for the preview frame, so portrait, square, and landscape images are displayed in matching proportions after loading instead of being forced into a fixed `3:4` container.

Follow-up: selected-target Apply layout no longer uses a vertical `ScrollView`. The preview frame keeps the loaded image aspect ratio, but the selected-target editor limits preview height to 50% of the available container, clamped to `260...430` pt. Very tall portrait photos therefore become narrower instead of changing frame ratio, so the title toolbar, preview mode control, preview frame, intensity slider, and save actions fit in one screen.

## Task 10 Manual Save Import Note

The current Apply screen is import-first until a target is selected. It shows a centered Import target panel, asks for Photo Library or Files when tapped, then opens the existing selected-target preview editor. Imported targets are not auto-saved. The bottom bar contains only `Save` and `Cancel`; Save writes to the current Film Roll through `ApplyFilmRollUseCase`, while Cancel returns without saving. Save to Photos remains available in lower-level use cases but is not surfaced by this flow.

When the Film Roll has sample analysis metadata, Apply preview and saved renders use app-only adaptive post process after the base LUT. This target-aware layer can change the preview/rendered JPEG, but it does not mutate the roll's saved base LUT and is not included in `.cube` export.

Current UI follow-up: the selected-target editor now shows only the intensity slider under the preview. The temporary diagnostic `Post` and `LUT` buttons remain out of the user-facing UI.

## Detail-Initiated Import Note

Film Roll Detail still has the staged-target routing support, but the projector Add Photo plus affordance is currently hidden. When the entry point is re-exposed, a selected target can open Apply directly into the preview/intensity editor and preserve the same Save and Cancel behavior without showing an intermediate blank import page.

## Fullscreen Edit Note

Fullscreen Edit opens this same Apply screen with an edit context instead of an import source. The screen labels the mode as Editing, preselects the saved processed photo's original asset, and initializes intensity from that photo. Saving renders to a fresh processed asset folder, keeps the processed photo ID stable, preserves the frame's original `createdAt`, updates the roll timestamp, and discards the previous processed asset folder after the manifest save succeeds.
