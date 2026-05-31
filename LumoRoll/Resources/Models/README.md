# Private Model Artifacts

The public LumoRoll repository does not include bundled Core ML model files.

The open-source build uses the local Algorithm V2 path for Film Roll LUT
generation. The production app may include a private, locally bundled Core ML
base-LUT predictor through a separate release overlay. That model runs on device
and does not add network or cloud processing.

Expected private release-only files, when available:

- `LumoRollBaseLUTPredictor.mlpackage`
- `LumoRollBaseLUTPredictor.metadata.json`

These files are intentionally ignored by Git.
