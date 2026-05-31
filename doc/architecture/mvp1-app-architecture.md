# MVP1 App Architecture

## Purpose

Define the first implementation architecture for LumoRoll MVP1: a native, iPhone-first, local-only SwiftUI app for creating Film Rolls from one reference image, applying the generated LUT to photos, saving results, and exporting `.cube` files.

## Platform Baseline

- Minimum target: iOS 17+.
- UI framework: SwiftUI.
- State observation: Observation (`@Observable`, `@Bindable`, `@State`, `@Environment` where appropriate).
- Photo import: PhotosUI and document/file import where needed.
- Image processing: Core Image through a Metal-backed `CIContext`.
- Persistence: app-owned files in Application Support.
- Networking: none in MVP1.

## Layered Shape

LumoRoll should be organized as these logical modules:

- `App`: app entry, dependency construction, root navigation, scene-level environment.
- `Features`: SwiftUI screens, feature models, feature-specific coordinators.
- `DesignSystem`: reusable visual components and tokens that mirror `design/Lutroll`.
- `Domain`: Film Roll entities, value types, use cases, and service protocols.
- `Processing`: Core Image LUT generation, LUT application, intensity blending, thumbnail rendering, `.cube` data generation.
- `Storage`: file-backed repository, manifest loading/saving, asset path management.
- `SystemIntegrations`: PhotosUI import, file import/export, share sheet, Photos write access.

The implementation may begin as folders in one app target. It can move to Swift Package modules later if boundaries need compiler enforcement.

## Runtime Composition

The app root constructs concrete services once and injects use cases or feature dependencies into the root feature model. Feature views receive observable models or value bindings, not concrete storage or processing services directly.

Expected app-root wiring:

- `FilmRollRepository` protocol -> file-backed repository in Storage.
- `PhotoImporting` protocol -> PhotosUI/file import adapter in SystemIntegrations.
- `PhotoRendering` protocol -> Core Image renderer in Processing.
- `LUTGenerating` protocol -> LUT generator in Processing.
- `LUTExporting` protocol -> `.cube` serializer/export helper through Processing and SystemIntegrations.
- `PhotoLibraryWriting` protocol -> explicit Photos save adapter in SystemIntegrations.

## Data Flow

1. Feature receives user intent.
2. Feature model calls a domain use case.
3. Use case talks to protocols owned by Domain.
4. Concrete services do processing, file work, or system integration.
5. Use case returns domain values or typed errors.
6. Feature model publishes view state through Observation.
7. SwiftUI re-renders from state.

## Non-Goals

- No Xcode project is created by this document.
- No SwiftData model in MVP1.
- No networking, account system, cloud sync, video, HDR, Log, or advanced Display P3 pipeline.
- No Core Image, Photos write, file I/O, or `.cube` serialization inside SwiftUI view structs.

## Risks

- Large photos can exceed memory if decoded at full size in UI or loaded eagerly.
- Concurrent writes to `manifest.json` need serialization.
- SwiftUI navigation state can drift if routes store large model payloads instead of stable IDs.

## Future Extension Points

- Move logical modules to Swift Package targets.
- Add SwiftData only if query complexity exceeds manifest needs.
- Add iCloud sync by swapping repository implementation after MVP1.
- Add video/HDR workflows through new processing protocols without changing SwiftUI view boundaries.
