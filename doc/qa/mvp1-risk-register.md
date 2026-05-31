# MVP1 Risk Register

Status: updated for the public Algorithm V2 source tree on 2026-05-31.

| ID | Risk | Area | Impact | Likelihood | Mitigation | Test/Review |
| --- | --- | --- | --- | --- | --- | --- |
| R1 | Large photos cause high memory use or crashes. | Performance | High | Medium | Downscale analysis and previews, use Metal-backed Core Image, release intermediates, test older devices. Full-resolution render paths remain the main risk. | See performance-memory-test-plan.md and task-9-final-audit.md. |
| R2 | Processing is slow on older iPhones. | Performance | Medium | Medium | Use Metal-backed `CIContext`, background work, progress states, cached thumbnails. | Timed device matrix tests still required. |
| R3 | `.cube` exports fail in common editing apps. | Compatibility | High | Medium | Current writer uses standard 33x33x33 text, `TITLE`, `DOMAIN_MIN`, `DOMAIN_MAX`, normalized RGB values, and safe filenames. Cross-app import tests remain required. | See cube-compatibility-test-plan.md. |
| R4 | LUT result does not generalize well to other photos. | Product quality | Medium | High | Set expectations, provide before/split/after preview, intensity blending, allow discard. | Visual QA across varied image sets. |
| R5 | Users think the app copies protected styles exactly. | Legal/user expectation | Medium | Medium | Use color-inspired wording, avoid clone/exact-copy claims. | Copy review before release. |
| R6 | Photos permission prompt appears too early. | Trust/App Review | High | Low | Implementation uses PhotosUI/file importer for import and add-only PhotoKit authorization only from Save to Photos. | Clean-install device permission timing test still required. |
| R7 | Save to Photos fails after editing. | Reliability | Medium | Medium | Current Save to Photos renders a temporary output, writes to Photos, and discards the temp render on success or failure. User can retry or save to Film Roll separately. | Failure-state tests and denial UX review. |
| R8 | Share/export fails or leaves temporary files. | Reliability/storage | Medium | Medium | File export has explicit preparing/ready/failed states. Current `.cube` cache is written under the Film Roll `lut/export.cube`; repeated exports overwrite it. | Export cancellation/failure and storage tests. |
| R9 | App sandbox storage grows without clear cleanup. | Storage | Medium | Medium | Film Roll deletion removes associated files, temp cleanup, storage review. | Repeated import/delete tests. |
| R10 | Corrupt or unsupported images break create/apply flows. | Reliability | Medium | Medium | Staging validates still images and allowed types; use cases avoid partial saved Film Rolls or clean rendered outputs on save failure. | Corrupt/unsupported asset tests. |
| R11 | Light/dark mode has unreadable controls over photos. | UI/accessibility | Medium | Medium | Test both appearances and photo contrast cases. | UI visual QA. |
| R12 | Accessibility labels or controls are incomplete. | Accessibility | Medium | Medium | VoiceOver labels for import, save, export, split control, intensity slider. | Accessibility test pass. |
| R13 | Source metadata such as location is unintentionally preserved in exports. | Privacy | Medium | Medium | Current rendered JPEGs are generated from `CGImage` without source metadata options, but original selected image bytes are stored in app sandbox for saved rolls. Do not expose originals externally without review. | Metadata QA before release. |
| R14 | App Store privacy answers drift from implementation. | Compliance | High | Medium | Reconcile privacy docs, SDKs, entitlements, and App Store answers before submission. | Release checklist. |
| R15 | App icon or in-app brand assets fail release review or have incomplete provenance. | Compliance/brand | Medium | Medium | AppIcon slots are generated from the provided opaque square PNG and a separate `LumoRollBrandIcon` is used only decoratively. Record generated-artwork rights/provenance or replace with final owned artwork before submission. | Asset catalog build validation, small-size device review, App Store icon check, provenance review. |
| R16 | Algorithm V2 skin-hue and neutral soft protection may misclassify wood, sand, sunsets, food, or warm clothing as protected skin/neutral regions. | Product quality | Medium | Medium | Keep protection soft, LUT-time only, and bounded; preserve intensity preview and user cancel/remove paths. Advanced controls remain MVP2. | Algorithm V2 fixture tests plus visual QA across portraits, landscapes, interiors, and warm object photos. |
| R17 | A private production Core ML model fails to load or returns malformed residual output on some OS/device combinations. | Reliability | High | Medium | Private model-enabled builds must fall back to Algorithm V2, assert bundle inputs/outputs, and reject invalid residuals before LUT creation. Public source builds do not include the model runtime or artifact. | Private release model contract, predictor, invalid residual, and fallback tests. Real-device timing still required for model-enabled releases. |
| R18 | Private Core ML preprocessing drifts from training preprocessing. | Product quality | Medium | Medium | Private release checks should verify EXIF orientation, sRGB-style render, resize, tensor order, and stats order against private golden fixtures. Public Algorithm V2 does not depend on these private fixtures. | Private tensor/stats and model contract tests before model-enabled release. |
| R19 | Private model or adaptive metadata leaks into `.cube` export or users expect exported LUT to match app adaptive rendering exactly. | Compatibility/user expectation | Medium | Medium | Export serializes only `FilmRoll.lut`; sample package, private model version, confidence, and adaptive metadata remain app-only. Product copy must distinguish baseline `.cube` from in-app adaptive rendering. | AppContainer boundary export assertions and copy review. |
| R20 | Low-confidence samples such as documents, screenshots, black borders, or atypical graphics produce weak LUTs. | Product quality | Medium | High | Persist coverage/confidence metadata now; add richer sample filtering and scene gating before release tuning. Public Algorithm V2 remains deterministic and model-free; private model-enabled releases need separate weak-sample gating. | Algorithm V2 visual QA plus private model visual QA before model-enabled release. |

## Current Blockers

- Real-device memory, performance, and Photos permission timing have not been verified.
- Cross-app `.cube` compatibility has not been manually completed.
- Metadata stripping for rendered outputs needs verification with actual saved/shared files.
- A product decision is still needed on explicit maximum import dimensions or file size for MVP1.
- Generated app icon provenance and final commercial-use approval must be recorded before App Store submission.
- Algorithm V2 needs visual QA on real reference/target sets before public release.
- Private model-enabled releases still need real-device Core ML load/inference timing, memory, and fallback verification.
