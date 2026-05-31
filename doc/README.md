# Documentation Folder

All development documentation for LumoRoll belongs in this folder. Design artifacts belong in `design/`, not `doc/`.

Current documentation status: MVP1 public implementation exists through deterministic Algorithm V2, sample analysis metadata, app-only adaptive post process, and later UI hardening tasks. Private model-enabled production builds are documented as a release-only boundary outside the public source tree.

This includes:

- Product decisions.
- Architecture decisions.
- Component documentation.
- Algorithm and image-processing notes.
- Data structure documentation.
- Privacy documentation.
- QA and risk reviews.
- App Store review considerations.

## Structure

- `doc/product/`: user flows, scope, feature behavior, copy, empty states, and error states.
- `doc/architecture/`: SwiftUI architecture, module boundaries, navigation, persistence, and state management.
- `doc/algorithms/`: reference image analysis, Algorithm V2 baseline, private local model boundary, sample analysis metadata, app-only adaptive post process, LUT application, intensity blending, and `.cube` export.
- `doc/components/`: component-level documentation for important UI and domain components.
- `doc/privacy/`: privacy policy notes, permission model, and local-processing guarantees.
- `doc/qa/`: risk reviews, edge cases, performance concerns, App Store risks, and test strategy.

## MVP1 Implementation Map

The implemented app currently spans these documented areas:

- App shell and navigation: `doc/architecture/navigation-model.md`, `doc/architecture/state-management.md`, and component docs for Library, Create, Detail, Apply, and Fullscreen.
- Domain and use cases: `doc/components/film-roll-domain-model.md`, `doc/components/create-film-roll-flow.md`, `doc/components/apply-photo-flow.md`, `doc/components/lut-export-action.md`, and `doc/components/photos-library-writer.md`.
- Processing: `doc/algorithms/model-assisted-coreml-artifact.md`, `doc/algorithms/sample-analysis-base-lut-workflow.md`, `doc/algorithms/adaptive-post-process.md`, `doc/algorithms/algorithm-v2.md`, `doc/algorithms/reference-image-analysis.md`, `doc/algorithms/lut-generation.md`, `doc/algorithms/core-image-rendering.md`, `doc/algorithms/intensity-blending.md`, `doc/algorithms/cube-export.md`, and `doc/components/photo-preview-rendering-service.md`.
- Storage and app-owned files: `doc/architecture/file-storage-layout.md`, `doc/architecture/persistence-strategy.md`, `doc/components/local-film-roll-storage.md`, `doc/components/photo-import-service.md`, `doc/components/app-asset-url-resolver.md`, and `doc/components/local-photo-image-loader.md`.
- QA and privacy: `doc/qa/` and `doc/privacy/` remain the owned homes for risk reviews and privacy notes. Do not move those decisions into root READMEs.
- GitHub release readiness: `doc/qa/github-release-readiness.md`.
- Private model artifact privacy/provenance boundary: `doc/privacy/model-artifact-provenance.md`.

## Future Direction Notes

- Model-assisted processing direction: `doc/algorithms/model-assisted-lut-render-profile.md`. The public app source does not include the private model implementation or artifact; private production builds must keep that runtime and provenance outside public Git.
- Sample analysis and base LUT first-stage workflow: `doc/algorithms/sample-analysis-base-lut-workflow.md`. The current app implements the core local workflow; remaining future work focuses on richer scene gating, sample filtering, and quality controls.

## Required Component Documentation Template

Every core component must document:

- Purpose.
- Inputs.
- Outputs.
- Data dependencies.
- Relationship to other modules.
- State management logic.
- Error states.
- Empty states.
- Future extension points.

## Documentation Rule

Before implementation starts, the relevant docs must exist or be updated. After a task is complete, the docs must record what changed and what remains open.
