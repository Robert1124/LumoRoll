# Private Model Boundary

## Purpose

Document how the public source tree treats LumoRoll's optional model-assisted
base-LUT path.

## Public Repository Behavior

The public repository does not include the Core ML runtime implementation, model
artifacts, model metadata, training checkpoints, training datasets, or offline
model-training scripts.

Reference-image Film Roll creation remains fully local and uses deterministic
Algorithm V2. This is the expected behavior for public source builds.

## Production App Boundary

The production app may include a private, locally bundled Core ML base-LUT
predictor in a separate release overlay. If present, the model runs on device
and predicts an intermediate base LUT from the selected reference image. The app
still falls back to Algorithm V2 when model loading, inference, or validation
fails.

The private model must not introduce accounts, network requests, cloud
processing, analytics, or target-photo analysis at apply time.

## Runtime Contract

- Public source builds: `AppContainer.makeLive` uses `LUTGenerator` and
  Algorithm V2. There is no public Core ML predictor implementation or bundled
  model artifact.
- Private production builds: private release packaging may add a local predictor
  implementation plus `LumoRollBaseLUTPredictor.mlpackage` and matching metadata
  under `LumoRoll/Resources/Models/`.
- `.cube` export includes only the generated base LUT. Model metadata and sample
  analysis details remain app-internal.

## Release Requirements For Private Model Builds

- Confirm training-photo and LUT-corpus rights allow distributing derived model
  weights.
- Keep source datasets, checkpoints, evaluation manifests, and local training
  logs out of the public repository.
- Record provenance evidence in private release notes.
- Re-run app privacy review before distributing a model-enabled build.

## Future Extension Points

- A public sample model can be added later only if its training data and license
  are cleared for redistribution.
- Model quality controls and scene gating should remain local-only and should not
  expand MVP1 into cloud or network AI.
