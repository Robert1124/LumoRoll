# Dependency Direction

## Purpose

Define how LumoRoll code may depend across layers so MVP1 stays testable and local services can be replaced later.

## Direction

Allowed high-level dependency direction:

```text
App
  -> Features
  -> DesignSystem
  -> Domain

App
  -> Processing
  -> Domain

App
  -> Storage
  -> Domain

App
  -> SystemIntegrations
  -> Domain
```

Features can depend on Domain and DesignSystem. Domain owns protocols. Processing, Storage, and SystemIntegrations implement those protocols. App wires concrete implementations together.

## Protocol Ownership

Protocols that describe app behavior belong in Domain:

- `FilmRollRepository`.
- `LUTGenerating`.
- `PhotoRendering`.
- `PhotoPreviewRendering`.
- `PhotoImporting`.
- `PhotoLibraryWriting`.
- `LUTExporting`.
- `FilmRollAssetWriting`.
- `ThumbnailRendering`.
- `SharePresenting` if a protocol is needed for testing.

`LUTGenerationRequest` carries reference image `Data`, requested LUT size, and algorithm version. Domain owns that request shape; Processing implements `LUTGenerating` by analyzing the image bytes locally before building the LUT.

Concrete types belong in their implementation layers:

- `FileFilmRollRepository` in Storage.
- `CoreImagePhotoRenderer` in Processing.
- `LUTGenerator` in Processing.
- `PhotosPickerPhotoImporter` in SystemIntegrations.
- `PhotoKitPhotoLibraryWriter` in SystemIntegrations.

## SwiftUI Boundary

SwiftUI views may:

- Render view state.
- Bind to feature models.
- Trigger intents such as `model.createTapped()` or `model.saveToPhotosTapped()`.

SwiftUI views must not:

- Create `CIImage`, `CIFilter`, or `CIContext`.
- Read or write files.
- Request Photos write authorization directly.
- Serialize `.cube` files.
- Mutate repository manifests.

## Dependency Injection

Use constructor injection for feature models and use cases. The app root should create a dependency container and pass required use cases into root and child feature models.

Avoid global singletons for app services. A shared Metal-backed `CIContext` can be owned by the processing service or dependency container, but access should still pass through protocols/use cases.

## Testing Implication

Use cases and feature models should be testable with fake Domain protocols. Processing and Storage can be tested separately with deterministic image fixtures and temporary directories after implementation begins.

## Risks

- If Features import concrete Storage or Processing types, later iCloud/video/HDR work will be harder.
- If Domain imports SwiftUI or Core Image too early, core behavior becomes difficult to test without UI/system frameworks.
