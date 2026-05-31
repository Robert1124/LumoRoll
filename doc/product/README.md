# Product Documentation

This folder records LumoRoll MVP1 product scope, user flows, information architecture, naming, permissions, empty states, error states, and save/share/export behavior.

## MVP1 Docs

- [MVP1 Product Spec](mvp1-product-spec.md): canonical scope, product decisions, dependencies, risks, and deferred features.
- [Information Architecture](information-architecture.md): screen map, navigation model, data surfaced by each screen, and future IA extensions.
- [Create Film Roll Flow](create-film-roll-flow.md): one-page reference photo import, local preview, required naming, save-time local generation, and save behavior.
- [Apply Photo Flow](apply-photo-flow.md): importing one target photo, choosing Photo Library or Files from the import panel, previewing intensity, and explicitly saving or cancelling.
- [Save, Share, Export Flow](save-share-export-flow.md): in-app save, Photos save, share sheet, and `.cube` export.
- [Permissions and Onboarding](permissions-onboarding.md): first-run stance and permission timing.
- [Empty and Error States](empty-error-states.md): product-level empty, loading, failure, and recovery states.
- [Naming and Copy](naming-and-copy.md): canonical names, labels, validation copy, and deferred copy decisions.
- [Fullscreen Viewer Flow](fullscreen-viewer-flow.md): immersive Film Roll photo browsing and viewer actions.

## Confirmed Product Decisions

- Canonical app name is `LumoRoll`.
- MVP1 is iPhone-first, photo-only, local-only, and account-free.
- MVP1 does not use network, cloud processing, iCloud sync, or network-based AI.
- Each Film Roll has exactly one reference image and one generated 33x33x33 LUT.
- A user must enter a non-empty Film Roll name before saving.
- Intensity blends the original photo with the LUT-processed output; it does not regenerate or mutate the LUT.
- Apply target import does not auto-save; the selected target shows preview/intensity controls and only `Save` writes to the current Film Roll.
- Photos write permission is requested only when the user explicitly chooses a visible Save to Photos action.
- `.cube` export starts from Film Roll detail through the system share/export sheet.
- Duplicate, search, and fullscreen Save to Photos are deferred beyond MVP1 unless later approved by the main thread.
- Fullscreen processed-frame Share, Edit, and Remove are part of MVP1.
