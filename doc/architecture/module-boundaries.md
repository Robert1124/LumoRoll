# Module Boundaries

## Purpose

Keep LumoRoll implementation understandable by giving every layer a narrow responsibility and preventing UI, storage, processing, and system APIs from bleeding into each other.

## App

Purpose:

- Own the `@main` app type, scene setup, dependency construction, and app-wide environment.

May contain:

- Dependency container.
- Root app model.
- Root `NavigationStack`.
- App launch and migration checks.

Must not contain:

- Core Image algorithms.
- Repository internals.
- Screen-specific UI layout.

## Features

Purpose:

- Own user-facing flows and feature state.

Expected feature areas:

- Library.
- Create Film Roll.
- Film Roll detail.
- Apply photo.
- Fullscreen viewer.
- Export/share/save actions.

May contain:

- SwiftUI screen views.
- Feature `@Observable` models.
- Route bindings and local validation.
- View state enums.

Must not contain:

- Core Image filter construction.
- File I/O.
- Photos library write calls.
- `.cube` string/data serialization.

## DesignSystem

Purpose:

- Provide reusable visual components, tokens, spacing, color, typography, buttons, cards, film strips, sliders, and preview controls aligned with `design/Lutroll`.

May contain:

- Stateless SwiftUI components.
- Design tokens and semantic colors.
- View modifiers for shared visual treatment.

Must not contain:

- Domain use cases.
- Storage or processing dependencies.
- Feature navigation decisions.

## Domain

Purpose:

- Define product concepts and use case contracts independent of frameworks where practical.

May contain:

- `FilmRoll`, `FilmRollID`, `FilmRollAsset`, `ProcessedPhoto`, `LUTDescriptor`.
- Use cases such as create roll, load library, apply roll, save processed photo, export LUT.
- Protocols for storage, rendering, import, export, and Photos writes.
- Typed errors.

Must not contain:

- SwiftUI views.
- Core Image implementation details.
- Concrete file path layout.
- PhotosUI implementation details.

## Processing

Purpose:

- Own local image analysis, LUT generation, rendering, blending, thumbnail generation, and `.cube` serialization.

May contain:

- Core Image and Metal-backed `CIContext`.
- 33x33x33 color cube generation.
- LUT application.
- Original/processed blend for intensity.
- Render-size limits.

Must not contain:

- SwiftUI screens.
- Manifest persistence.
- Photos permission prompts.

## Storage

Purpose:

- Own app-private data persistence.

May contain:

- File-backed repository.
- `manifest.json` read/write logic.
- Asset path allocation.
- Atomic write helpers.
- Cleanup for failed partial saves.

Must not contain:

- Core Image rendering algorithms.
- Photos library writes.
- SwiftUI views.

## SystemIntegrations

Purpose:

- Isolate Apple system UI and capabilities from domain logic.

May contain:

- PhotosUI picker adapter.
- Document picker/file importer adapter.
- Share sheet adapter.
- Photos library save adapter.
- Security-scoped file access if file import needs it.

Must not contain:

- LUT generation.
- Manifest schema ownership.
- Feature layout.

## Boundary Rule

If code needs Core Image, file handles, Photos permissions, or `.cube` serialization, it belongs below Features and behind a Domain protocol.
