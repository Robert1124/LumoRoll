# Permissions and Onboarding

## Purpose

Keep LumoRoll privacy-forward without adding a heavy onboarding sequence. MVP1 should ask for permissions only when the user takes an action that requires them.

## Onboarding Stance

MVP1 does not require an account, cloud setup, network connection, or long tutorial. First launch should open the Library.

If the Library is empty, the empty state explains the core action and points to creating the first Film Roll.

## Permission Timing

Photos import:

- Use system photo picker behavior for user-selected photo access.
- Ask only for access needed to import the selected reference or target image.

Files import/export:

- Use system file picker/export sheet as needed.
- Do not request broad file access.

Photos write:

- Request only when the user explicitly taps Save to Photos.
- Do not request Photos write permission during onboarding, Film Roll creation, or Save to Film Roll.

Network:

- MVP1 should not request network access for core processing.
- No account, cloud processing, or network-based AI is in scope.

## Inputs

- User action: create Film Roll, import target photo, Save to Photos, share, or export `.cube`.
- System permission state.

## Outputs

- System picker, permission prompt, share sheet, or export sheet.
- Clear recovery path if permission is denied.

## Dependencies

- Privacy documentation for local-only guarantees.
- QA review for App Store permission wording and denied-permission paths.
- Architecture support for local storage without account setup.

## Empty and Error States

- Empty Library: invite user to create a Film Roll without requesting permissions first.
- Photos write denied: explain that LumoRoll can still save inside the app and that Photos access is only needed to save to Photos.
- Import cancelled: return to the previous screen without error.
- Export/share cancelled: dismiss without error.

## Suggested Permission Copy

- Photos write rationale: `LumoRoll needs permission to save this edited photo to your Photos library.`
- Denied Photos write: `This photo was not saved to Photos. You can still save it to the Film Roll or change access in Settings.`

## Future Extension Points

- Short first-run tips after implementation validates the need.
- Optional privacy explainer screen.
- iCloud permission and account-adjacent messaging if sync enters MVP2.
