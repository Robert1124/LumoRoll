# LumoRoll

LumoRoll is a native iPhone-first SwiftUI app for turning one reference photo into a reusable LUT, importing local `.cube` LUTs as personal Film Rolls, applying Film Rolls to photos, and exporting LUTs as `.cube` files.

The product is intentionally light, friendly, film-inspired, and local-first. It is not a generic filter app and not a professional grading suite.

## Current Status

The app implementation exists in this workspace.

- Generated Xcode project: `LumoRoll.xcodeproj`
- Project definition: `project.yml`
- App target: `LumoRoll`
- Test target: `LumoRollTests`
- Minimum deployment target: iOS 17
- UI framework: SwiftUI
- Processing: Core Image with a Metal-backed `CIContext` and fallback context
- Default LUT size: `33x33x33`
- Media scope: photos only

## Open Source Boundary

This public repository includes the native app source, deterministic Algorithm V2 LUT generation path, tests, design documentation, and project website source.

The production app may include a private, locally bundled Core ML base-LUT predictor. That model implementation, artifact, and metadata are intentionally not included in this public repository. Public source builds use Algorithm V2 for reference-image Film Roll creation.

## App Features

- Create a Film Roll from exactly one reference image, or from one local `.cube` LUT file.
- Import reference and target photos from Photos or Files.
- Analyze the reference image or parse the `.cube` LUT locally on device.
- Generate and store a 33x33x33 base LUT locally. Public source builds use deterministic Algorithm V2; production builds may add a private local Core ML predictor in a separate release overlay and still fall back to Algorithm V2 if the model is unavailable or returns an invalid residual.
- Store a local sample analysis package with quality, coverage/confidence, lighting, style, and render-profile seed metadata when a roll is created from a reference image.
- Require a user-provided Film Roll name before save.
- Persist Film Rolls, reference assets, generated LUT data, processed outputs, thumbnails, and metadata inside the app.
- Browse a horizontal reversal-slide Film Roll carousel.
- Open a Film Roll detail screen with the reference sample first, followed by processed frames.
- Apply a Film Roll to a target photo through an import-first flow with intensity preview, explicit `Save`, and `Cancel`.
- Render saved outputs by applying the base LUT, optional app-only adaptive post process, and intensity blending.
- Save processed output back into the Film Roll.
- Save processed output to Photos only after the user explicitly chooses Save to Photos.
- Export the Film Roll base LUT through a system `.cube` file export flow. Sample analysis, confidence, model, and adaptive metadata stay inside the app and are not written into `.cube`.
- View frames in a dark fullscreen viewer; processed frames can be shared, edited, or removed.

The current app is photo-only and local-first. It does not include video import/export, video processing, HDR, Log workflows, advanced Display P3 handling, iCloud sync, accounts, cloud processing, network-based AI, search, duplicate, or fullscreen Save to Photos.

## Architecture

The app is split into focused layers:

- `LumoRoll/App/`: app entry point, root navigation, dependency container, and display image store.
- `LumoRoll/Domain/`: models, protocols, and use cases.
- `LumoRoll/Processing/`: reference analysis, LUT generation, `.cube` import/export, Core Image rendering, thumbnails, and JPEG encoding.
- `LumoRoll/Storage/`: file-backed Film Roll repository, manifest, asset store, and asset writer.
- `LumoRoll/SystemIntegrations/`: app-owned path resolution, import staging, local image loading, and add-only Photos writing.
- `LumoRoll/DesignSystem/`: SwiftUI theme and reusable visual components.
- `LumoRoll/Features/`: Library, Create, Detail, Apply, and Fullscreen screens and feature models.
- `LumoRollTests/`: unit and boundary tests for each layer.
- `web/`: Vite/React project website plus GSAP motion, Remotion teaser source, HyperFrames teaser HTML, and copied web-safe visual assets.

Domain protocols keep UI, PhotosUI, PhotoKit, storage, and rendering dependencies outside core use-case logic.

## Documentation

Documentation is required for this project and is part of the implementation contract.

- `doc/README.md`: development documentation index.
- `design/README.md`: design documentation index and prototype guidance.
- `doc/qa/github-release-readiness.md`: public-release readiness and risk notes.

Design artifacts live under `design/`. Development, architecture, algorithm, component, privacy, and QA docs live under `doc/`.

## Local Development

Regenerate the Xcode project after changing `project.yml` or adding/removing Swift files:

```sh
xcodegen generate
```

Run the test suite on the expected simulator:

```sh
xcodebuild -project LumoRoll.xcodeproj -scheme LumoRoll -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test
```

Build the app:

```sh
xcodebuild -project LumoRoll.xcodeproj -scheme LumoRoll -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' build
```

Run the project website:

```sh
cd web
npm install
npm run dev
```

## Future Work

Hardening follow-ups include memory profiling, display cache eviction review, temporary-file cleanup review after crash recovery, and public/private release packaging checks for the optional local model.

Future candidates include iCloud sync, video support, HDR / Log / Display P3 workflows, advanced skin-tone and neutral-gray protection controls, richer model quality controls, richer LUT controls, and additional organization/sharing features.

## License

Source code and documentation are available under the MIT License. LumoRoll brand assets, app icons, and product imagery are not licensed for unrestricted reuse; see `NOTICE`.
