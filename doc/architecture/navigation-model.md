# Navigation Model

## Purpose

Define MVP1 navigation with stable routes, predictable system presentation, and no large image payloads in navigation state.

## Core Approach

- Use `NavigationStack`.
- Store push navigation with enum routes.
- Use a fullscreen cover for the immersive viewer.
- Push Create, Detail, and Apply in the current MVP1 app shell.
- Routes hold stable IDs or lightweight context. Image bytes must never be stored in navigation state.

## Root Routes

Current route model:

```swift
enum AppRoute: Hashable {
    case createFilmRoll
    case filmRollDetail(id: String)
    case applyPhoto(
        filmRollID: String,
        initialImportSource: ApplyTargetImportSource?,
        initialTargetPhotoPath: String? = nil,
        editContext: ApplyPhotoEditContext? = nil
    )
}
```

The library is the root screen. Create, Film Roll detail, and Apply are pushed onto the stack. Apply may receive lightweight context: an initial import source for importer presentation, a staged target path when Detail has already completed the source picker, or an edit context for an existing processed photo. This keeps image bytes, selected Photos items, file URLs, import progress, save state, and retry state within feature screens/models instead of route state.

## Fullscreen Destinations

Current fullscreen presentation:

```swift
enum AppFullscreenCover: Identifiable {
    case photoViewer(filmRoll: FilmRoll, startIndex: Int)
}
```

The current viewer route carries a loaded Film Roll snapshot so the fullscreen viewer can browse frames without repository I/O. A future hardening pass may switch this to roll ID plus frame identity and reload fresh state.

## Flow Mapping

- Library saved Film Roll card tap: push `filmRollDetail(id)`.
- Library blank add card tap: push `createFilmRoll`.
- Detail import photo: present a Detail-owned source choice and native picker/importer, then push `applyPhoto(rollID, nil, stagedTargetPath, nil)`.
- Apply import panel: if no initial source exists, ask for Photo Library or Files on the Apply screen.
- Detail `.cube` action: system `.fileExporter` from the Detail screen after `ExportLUTUseCase` prepares cube content.
- Film frame tap: fullscreen cover with the loaded Film Roll snapshot and start index.
- Fullscreen Share: stay in fullscreen and present SwiftUI `ShareLink` for the resolved app-owned processed render file.
- Fullscreen Edit: dismiss fullscreen and push `applyPhoto(rollID, nil, nil, editContext)`.
- Fullscreen Remove: stay in fullscreen, call the root removal closure, refresh Detail/Library state after success.

## State Restoration

MVP1 does not require full restoration of in-progress create/apply flows. It should safely reload the library and route to a detail screen if the route ID still exists. If the selected roll was deleted or missing, return to library and show a non-blocking error.

## Error Handling

- Missing roll ID: pop to library or dismiss modal.
- Failed import: keep current screen and show retry message.
- Failed render/save/export: keep the user in the flow with the selected image and current intensity intact.

## Future Extension Points

- Deep link to a Film Roll detail.
- Dedicated edit roll screen.
- Route groups for video/HDR features in MVP2.
