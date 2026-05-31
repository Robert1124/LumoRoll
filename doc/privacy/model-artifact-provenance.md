# Private Model Provenance Boundary

Status: public-source boundary note.

## Purpose

Clarify the privacy and redistribution boundary for LumoRoll's optional
model-assisted base-LUT path.

## Public Source Build

- The public repository does not include bundled Core ML model files.
- The public app source builds and runs with deterministic Algorithm V2.
- No user images are uploaded or processed through a network service.

## Production Model-Enabled Build

The production app may include a private, locally bundled Core ML predictor in a
separate release overlay. If included, it must remain an on-device resource and
must not add accounts, network requests, cloud processing, analytics, or
target-photo analysis at apply time.

Private release packaging may provide:

- `LumoRoll/Resources/Models/LumoRollBaseLUTPredictor.mlpackage`
- `LumoRoll/Resources/Models/LumoRollBaseLUTPredictor.metadata.json`

Those files are intentionally ignored in the public repository.

## Privacy Boundary

- Reference images remain local to the device.
- Generated LUTs and thumbnails remain in app-owned storage unless the user
  explicitly exports or saves an output.
- `.cube` export contains only LUT values and does not include model provenance,
  sample analysis internals, or user-photo metadata.

## Private Release Requirements

- Confirm training-photo and LUT-corpus licenses allow distribution of derived
  model weights.
- Keep source training data, checkpoints, evaluation outputs, and local paths out
  of public Git history.
- Maintain private provenance records for the model-enabled production release.
- Re-check App Store privacy answers against the exact model-enabled build.
