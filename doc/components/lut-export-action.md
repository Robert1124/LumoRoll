# LUT Export Action

## Purpose

Export a Film Roll's generated LUT as a `.cube` file through user-controlled file export/share UI.

## Inputs

- Film Roll ID.
- LUT descriptor or stored LUT data.
- Safe suggested `.cube` filename based on Film Roll name.
- User export destination from system UI.

## Outputs

- `.cube` file URL from the Domain export use case, then exported document/share presentation from system UI.
- Success/cancellation/failure state.

## Data Dependencies

- Stored LUT binary.
- Optional cached `.cube` file.
- Roll name for display filename.
- `.cube` serializer in Processing.
- `FilmRollAssetWriting` export method for writing cached/export-ready cube text to an app-controlled URL.

## Relationship To Other Modules

- Initiated by Film Roll Detail feature.
- `ExportLUTUseCase` loads the roll, asks `LUTExporting` to serialize the stored LUT, creates a safe filename ending in `.cube`, caps the sanitized base name to 80 characters, and writes the cube text through `FilmRollAssetWriting`.
- Storage can cache or stage the export file.
- SwiftUI/SystemIntegrations presents file exporter/share UI after `ExportLUTResult` is ready.
- SwiftUI button must not serialize `.cube` content directly.

## State Management

Feature model owns export progress and presentation state. The action should prevent duplicate concurrent exports for the same roll.

## Error States

- Roll missing.
- LUT file missing or corrupt.
- `.cube` serialization failed.
- Export file write failed.
- File export cancelled.
- File export failed.

Cancellation from the system export/share UI is not a user-facing error and should not replace a successful prepared export with a failure message.

## Empty States

Not available if the Film Roll lacks a valid LUT. That should be treated as a corrupted roll error, not a normal empty state.

## Future Extension Points

- Export multiple LUT sizes.
- Include README/license note in an export package.
- Share directly to other apps.

## Task 8C Decision Note

The Detail `.cube` action continues to call `ExportLUTUseCase` for serialization and staging. When the feature model reaches `ready(ExportLUTResult)`, the SwiftUI screen must present a system file export/share UI using the staged `.cube` file and suggested filename, then clear or neutralize presentation state after dismissal.
