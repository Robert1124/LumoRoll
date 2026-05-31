# Architecture Documentation

This folder defines the MVP1 iOS architecture for LumoRoll before app code is created.

## Architecture Set

- [MVP1 App Architecture](mvp1-app-architecture.md): platform baseline, layers, runtime composition, and constraints.
- [Module Boundaries](module-boundaries.md): responsibilities for App, Features, Domain, Processing, Storage, SystemIntegrations, and DesignSystem.
- [Dependency Direction](dependency-direction.md): allowed imports, protocol ownership, and app-root wiring.
- [Navigation Model](navigation-model.md): `NavigationStack`, enum routes, sheets, and fullscreen covers.
- [State Management](state-management.md): SwiftUI plus Observation rules for view, feature, and shared state.
- [Persistence Strategy](persistence-strategy.md): file-backed repository, manifest ownership, and no SwiftData for MVP1.
- [File Storage Layout](file-storage-layout.md): Application Support folder structure and asset naming.
- [Async Processing Flow](async-processing-flow.md): create, apply, save, export, and Photos write flows.

## MVP1 Decisions

- Minimum target: iOS 17+.
- UI: SwiftUI with Observation.
- Architecture: layered modules named App, Features, Domain, Processing, Storage, SystemIntegrations, and DesignSystem.
- Dependency direction: UI/features depend inward on domain use cases and protocols; concrete Processing, Storage, and SystemIntegrations services are wired at the app root.
- Persistence: file-backed local repository under `Application Support/LumoRoll`.
- Metadata index: `manifest.json`.
- Asset storage: reference images, thumbnails, processed results, LUT binaries, and `.cube` exports as files.
- SwiftData: not used in MVP1 unless a later documented decision adds it.
- Navigation: `NavigationStack` with enum routes and item-based sheets/fullscreen covers.
- SwiftUI view boundary: views must not directly perform Core Image work, file I/O, Photos writes, or `.cube` serialization.

## Open Follow-ups

- Confirm concrete image and thumbnail file formats with the Image Processing / LUT worker.
- Confirm final App Store privacy wording with QA / Privacy.
- Implementation starts as folders in one app target. Local Swift Package modules are deferred until boundaries need compiler enforcement.
