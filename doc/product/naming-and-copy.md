# Naming and Copy

## Purpose

Keep LumoRoll language consistent, friendly, and clear. Copy should support the Film Roll metaphor without hiding important technical output such as `.cube` export.

## Canonical Names

- App name: `LumoRoll`
- Saved LUT package: `Film Roll`
- Reference image in detail: `Sample`
- Applying target image: `Photo`
- LUT export: `.cube`
- Intensity control: `Intensity`

Avoid:

- `Lutroll`
- `Untitled Roll` as a saved fallback
- `Filter` as the primary product object name
- `AI` language for MVP1 baseline
- `Cloud`, `sync`, or account language in MVP1 flows
- Third-party film-brand names on cards, buttons, or documentation intended as product UI.

## Required Copy Rules

- A Film Roll name is required before save.
- Names should be trimmed before validation.
- Save action should be disabled or blocked until the name is non-empty.
- Use `Film Roll` in primary actions and documentation when referring to saved LUT packages.
- Use `.cube` when referring to LUT file export.
- Do not promise exact copying of another image or creator's style.
- The app icon and `LumoRollBrandIcon` may support app-level identity, but functional controls should keep clear SF Symbol labels and accessibility names.

## Core Labels

Library:

- App title: `LumoRoll`
- Slide card brand line: `LUMOROLL`
- Slide card category line: `COLOR ROLL`
- Slide card lower labels: `LUT`, `33x33x33`
- Empty title: `Create your first Film Roll`
- Add-card selected title: `Create a new roll`
- Add-card accessibility action: `Create Film Roll`

Create:

- `Pick a photo sample or a cube LUT`
- `Add a reference`
- `Building your Film Roll...`
- `Name your roll.`
- `Save as Film Roll`
- `Enter a name to save this Film Roll.`

Detail:

- `Film Roll`
- `Sample`
- `Export .cube`
- `Add photo`
- `Used on [n] photos`

Apply:

- `Applying`
- `Import target`
- `Photo Library`
- `Files`

Fullscreen:

- `Sample Reference`
- `Frame 01`
- `Edit`
- `Remove`

Permissions:

- `LumoRoll needs permission to save this edited photo to your Photos library.`
- `This photo was not saved to Photos. You can still save it to the Film Roll or change access in Settings.`

## Deferred Copy

The prototype includes duplicate and search affordances. These are not MVP1 features unless the main thread later approves them. MVP1 copy should not mention:

- Duplicate roll.
- Library search.
- Video.
- Cloud sync.
- Accounts.

## Dependencies

- Design system should use these terms in visible UI.
- Documentation and implementation should use `LumoRoll` consistently.
- QA should review copy for privacy, permission, and style-copying risk.

## Future Extension Points

- More localized copy.
- User education for `.cube` compatibility.
- Optional style naming suggestions generated fully on device.
