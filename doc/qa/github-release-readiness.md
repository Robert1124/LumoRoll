# GitHub Public Release Readiness

Status: public-source cleanup note on 2026-05-31.

## Purpose

Record the repository boundary before switching LumoRoll from a private GitHub
repository to a public open-source repository.

## Public Scope

The public repository includes:

- Native iOS app source.
- Deterministic Algorithm V2 LUT generation and `.cube` import/export support.
- Swift tests for app, domain, storage, rendering, and fallback behavior.
- Design documentation and public visual assets.
- Project website source under `web/`.

The public repository excludes:

- Private Core ML model artifacts and metadata.
- Offline training datasets, checkpoints, evaluation outputs, and training
  scripts.
- Internal implementation logs, agent prompts, and local coordination notes.
- Local signing configuration and developer-specific build state.

## Ignore Policy

The root `.gitignore` excludes:

- Xcode build output and local user state.
- Python, Node, Vite, Remotion, and generated web output.
- `data/`, `tools/`, and Python research `tests/`.
- `AGENTS.md` and `doc/implementation/`.
- `LumoRoll/Resources/Models/` except for its public README.
- `downloads/` and generic checkpoint formats such as `*.pt`, `*.pth`,
  `*.ckpt`, and `*.onnx`.

## Model Boundary

Public source builds do not include a bundled Core ML predictor or public model
runtime implementation. The app source uses Algorithm V2 for reference-image
Film Roll creation.

Production builds may include a private, locally bundled Core ML predictor
through a separate private release overlay if model provenance and
redistribution rights are cleared outside the public repository.

## License Boundary

Source code and documentation are MIT licensed.

LumoRoll names, app icons, brand assets, and product imagery are reserved brand
assets and are not licensed for unrestricted reuse. See the root `NOTICE`.

## Public Visibility Checklist

- Recreate or rewrite Git history so excluded files never appear in public
  commits.
- Verify `git ls-files` contains no model artifacts, private execution logs,
  agent files, offline training scripts, offline datasets, local absolute paths,
  Apple Team IDs, or secrets.
- Verify public source builds pass without the private model.
- Confirm app icons and brand imagery are generated/owned and intentionally
  published as reserved assets.
- Keep private model provenance outside public Git.

## Verification Run

Completed on 2026-05-31 before the public-ready commit:

- `npm run build` in `web/` passed.
- `xcodebuild -project LumoRoll.xcodeproj -scheme LumoRoll -destination 'generic/platform=iOS Simulator' build` passed.
- `xcodebuild -project LumoRoll.xcodeproj -scheme LumoRoll -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.5' test` passed with 239 tests.
- `git ls-files` audit found no tracked private model runtime, model artifacts,
  private training scripts, local execution logs, agent prompt files, Apple Team
  ID, personal bundle ID, obvious secrets, or local absolute paths.
