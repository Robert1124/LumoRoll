# LumoRoll Accessibility

## Purpose

Defines MVP1 accessibility requirements for the design system and screen behavior.

## Core Requirements

- Support Dynamic Type for all text.
- Keep tappable controls at least 44x44 pt.
- Provide labels for icon-only buttons.
- Preserve readable contrast in light and dark mode.
- Respect Reduce Motion, Increase Contrast, and Reduce Transparency.
- Do not rely on color alone to communicate state.

## Home

- Film Roll carousel cards announce roll name, photo count, created date, and whether the card is selected.
- The selected center card opens detail. Side-card taps may first center the card.
- Selection must not rely only on brightness; 3D position, scale, stacking order, selected label state, and page indicator also communicate state.
- The carousel uses haptics when the centered selection changes, but haptics are never required to understand state.
- Library home does not vertically scroll, so Dynamic Type and long roll names must truncate or scale instead of pushing controls off-screen.
- Palette swatches are decorative unless future interaction is added.
- Home does not expose a separate header brand/title cluster or header plus button.
- The blank add card announces "Create Film Roll"; the centered plus affordance is visual and the full card is the tap target.
- The add-card summary uses hidden reserved rows only for layout stability; those rows must remain inaccessible to VoiceOver.
- If search/filter chips are deferred, do not expose inactive controls.

## Create

- The `Add a reference` preview/button announces that it opens Photos or Files choices.
- Source choice actions clearly identify Photos and Files.
- Analysis progress should announce major state changes without excessive repeated updates.
- Save is disabled until the user enters or selects a name.
- Validation copy must explain that a name is required.
- Progress text must say `33x33x33` if it mentions cube size.

## Detail

- The film strip should be reachable by swipe navigation.
- The sample frame announces "Reference sample".
- Processed frames announce frame number and open full-screen viewer.
- The add tile announces "Import and apply photo".
- `.cube` export button announces "Export cube LUT file".

## Apply

- The centered Import target panel must be reachable as one button and announce that it opens import source choices.
- Source choices must clearly identify Photo Library and Files.
- Before a target is selected, preview controls, intensity controls, and bottom save actions are not exposed.
- After a target is selected, preview controls, intensity controls, and bottom `Save` / `Cancel` actions are exposed.
- Save progress or failure should be announced in plain language after the user explicitly taps `Save`.
- Save to Photos is not exposed from this Apply flow; permission denial copy belongs only to explicit Photos save surfaces.

## Full-Screen Viewer

- Close button announces "Close viewer".
- Current frame label includes sample/reference when applicable.
- Page indicator is accessible without reading every dot as a separate control unless dots are interactive.
- The photo preview has no pinch zoom or two-finger pan gesture-only controls.
- Processed-frame Share, Edit, and Remove buttons identify their action.
- Remove must use a confirmation dialog before deleting the processed frame.

## Visual Contrast

- Primary body text must meet WCAG AA.
- Metadata and labels should remain readable, especially on cream backgrounds.
- Photo overlay tags should use adaptive light/dark backgrounds.
- Split handle should remain visible across bright and dark images.

## Motion And Haptics

- Reduce Motion disables decorative palette pop, scan, and nonessential transitions.
- Carousel haptics should be subtle selection feedback and never required to understand state.

## Documentation Update Note

Created to capture MVP1 accessibility design requirements before implementation.
