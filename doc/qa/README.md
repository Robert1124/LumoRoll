# QA and Risk Documentation

This folder records LumoRoll MVP1 quality strategy, risk review, compatibility testing, performance testing, and edge/failure-state coverage.

## MVP1 Risk Areas

- Large photo memory usage.
- Slow processing on older devices.
- `.cube` export compatibility across editing apps.
- Incorrect or disappointing LUT generalization.
- Photos permission timing and user trust.
- File export failures.
- App sandbox storage growth.
- Corrupt or unsupported images.
- Permission denied states.
- Accessibility and light/dark mode quality.
- User misunderstanding around "copying" the style of a reference image.
- App Store review expectations for privacy policy and photo access.

## Documents

- [MVP1 Risk Register](mvp1-risk-register.md): prioritized risk table, mitigations, and blockers.
- [MVP1 Test Strategy](mvp1-test-strategy.md): device matrix, core flow coverage, privacy tests, reliability tests, visual/accessibility tests.
- [Cube Compatibility Test Plan](cube-compatibility-test-plan.md): `.cube` export validation and cross-app import plan.
- [Performance and Memory Test Plan](performance-memory-test-plan.md): large-image, timing, memory, and storage-growth checks.
- [Edge Cases and Failure States](edge-cases-failure-states.md): expected behavior for import, create, apply, save, share, export, storage, accessibility, and privacy-sensitive failures.
- [Task 9 Final QA and Privacy Audit](task-9-final-audit.md): current implementation audit for MVP1 privacy, Photos, `.cube`, performance, failure-state, and user-expectation risks.

## Release Readiness Notes

MVP1 is not release-ready until real-device QA confirms permission timing, large-image behavior, `.cube` compatibility, storage cleanup, accessibility, and failure recovery.
