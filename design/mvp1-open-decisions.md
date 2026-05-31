# MVP1 Design Open Decisions

## Decided

- Product name is **LumoRoll**.
- `design/Lutroll/` is visual reference, not implementation architecture.
- Prefer `_check/09-final.png` for Home when screenshot/source drift exists.
- MVP1 LUT copy and specs use `33x33x33`.
- No Film Roll can be saved through an `Untitled Roll` fallback.
- Light and dark modes are required.
- Overall tone is warm cream/noir, film-inspired, clean, friendly, and slightly playful.
- SwiftUI should use SF Pro and SF Mono defaults. Custom serif is optional future work only after licensing is settled.
- Search, duplicate, and fullscreen Save to Photos are deferred unless explicitly approved.
- Fullscreen processed-frame Share, Edit, and Remove are approved for MVP1.
- Full-screen viewer is dark/noir and supports swipe browsing within one Film Roll.
- Detail does not expose a roll-level intensity setting in MVP1. Intensity belongs to the Apply flow and to rendered processed outputs.
- Home filter chips are deferred with search/filter behavior. Do not ship inactive visual-only chips.
- Detail follows system light/dark appearance. Full-screen viewer is always dark/noir. Roll mood themes are future work.
- Create Film Roll is a one-page flow: reference import, preview, naming, and Save stay together. MVP1 has no separate Step 2 analysis panel.
- Create save/progress copy should reference local `33x33x33` color cube generation without making it a separate pre-save step.
- Home carousel lighting brightens only the slide/photo window display or backlight. It must not recolor or retone the image, and non-centered images should read dimmer.
- File import supports standard still images that iOS can decode for SDR processing, with HEIC, JPEG, and PNG as the documented MVP1 baseline.

## Needs Main-Thread Decision

- None for MVP1 design scope at this checkpoint.

## Risks

- The prototype contains scoped-out affordances that could accidentally expand MVP1 if implementation copies it literally.
- Custom fonts in the prototype may create licensing and app-size risk if treated as required.
- Warm cream surfaces can become too low contrast if metadata text is too light.
- Film strip sprocket decoration can become visually noisy at small sizes.
- Palette swatches may be misread as editable controls unless kept clearly decorative.
- Fullscreen bottom actions need safe-area and Dynamic Type testing to avoid crowding.

## Follow-Ups

- QA should test Save to Photos permission timing against the separated "Save to Roll" path.
- Architecture should preserve stable image sizing for cards, film frames, and previews.
- Image Processing/LUT should provide final user-facing names for analysis states and export errors.

## Documentation Update Note

Created to record design decisions, risks, and unresolved MVP1 design questions.
