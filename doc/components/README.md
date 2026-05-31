# Component Documentation

This folder documents important MVP1 UI, domain, and service components before implementation.

## Template

- [Component Documentation Template](component-template.md)

Every component document must include purpose, inputs, outputs, data dependencies, module relationships, state management, error states, empty states, and future extension points.

## Domain And Services

- [Film Roll Domain Model](film-roll-domain-model.md)
- [Local Film Roll Storage](local-film-roll-storage.md)
- [App Asset URL Resolver](app-asset-url-resolver.md)
- [Photo Import Service](photo-import-service.md)
- [Local Photo Image Loader](local-photo-image-loader.md)
- [Photo Rendering Service](photo-rendering-service.md)
- [Photo Preview Rendering Service](photo-preview-rendering-service.md)
- [Photos Library Writer](photos-library-writer.md)
- [LUT Export Action](lut-export-action.md)

## Screens And Flows

- [Library Screen](library-screen.md)
- [Create Film Roll Flow](create-film-roll-flow.md)
- [Film Roll Detail Screen](film-roll-detail-screen.md)
- [Apply Photo Flow](apply-photo-flow.md)
- [Fullscreen Viewer](fullscreen-viewer.md)

## UI Components

- [App Brand Assets](app-brand-assets.md)
- [Film Roll Card](film-roll-card.md)
- [Film Strip](film-strip.md)
- [Before / Split / After Preview](before-split-after-preview.md)
- [Intensity Slider](intensity-slider.md)
- [Project Website](project-website.md)

## Cross-Cutting Decisions

- SwiftUI views render state and send intents; they do not directly perform Core Image work, file I/O, Photos writes, or `.cube` serialization.
- Feature models own async state and call Domain use cases.
- Domain protocols hide concrete Processing, Storage, and SystemIntegrations implementations.
- Component visuals should follow the current design direction: reversal-slide Home carousel, Film Roll Detail projector viewer with bottom film transport, import-first Apply flow, immersive dark fullscreen viewer, and light/dark support.
