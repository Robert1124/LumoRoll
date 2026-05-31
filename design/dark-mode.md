# LumoRoll Dark Mode

## Purpose

Defines dark mode behavior for MVP1 while preserving the warm/noir film tone.

## Overall Direction

Dark mode should feel like a quiet viewing room, not a pure black pro editor. Use warm noir surfaces, cream text, subtle borders, and restrained accents.

## Token Mapping

| Role | Light | Dark |
| --- | --- | --- |
| Background | Warm cream | Noir `#1A1612` |
| Surface | Cream white | `#221D17` |
| Secondary surface | Cream 200 | `#2C261F` |
| Text | Ink | Cream |
| Metadata | Ink 500 | White at about 60% |
| Hairline | Ink at 8-14% | White at 10-16% |
| Accent | Roll/accent color | Same color, adjusted only for contrast |

## Screen Behavior

Home:

- Support dark mode, but keep the friendly library feel.
- Carousel cards should remain readable with photo thumbnails carrying color.
- The static `LumoRollBrandIcon` should keep its full-color artwork in both light and dark appearances; adapt only its surrounding border/shadow if needed.
- The selected card may use a lit photo-window treatment, but the light is a window display/backlight treatment only. It must not alter the thumbnail image's color, tone, saturation, contrast, or source pixels.
- Side cards should be visibly dimmer through reduced window/backlight intensity or a neutral overlay, but they should not disappear into the noir background.
- The light effect must be constrained to the slide photo window rather than glowing behind the entire card.
- Avoid flattening all cards into pure black.

Detail:

- Detail follows the system color scheme.
- The split light-box view finder must use dark transparent assets for both its labeled back frame and front viewer block in dark mode; neither layer should remain white against the noir page. The front viewer dark asset is generated from the same realistic source image as the light asset, with the molded plastic and screw highlights remapped into a warm charcoal palette.
- Film strip should remain deep/noir in both modes.

Apply:

- Default can remain light for editing clarity.
- If system dark mode is active, controls and preview labels must use dark tokens while keeping the image preview prominent.

Full-screen:

- Always dark/noir regardless of system appearance.
- This is an immersive media-viewing mode.

## Accessibility

- Maintain WCAG AA contrast for text and controls.
- Do not rely on palette swatch color alone to convey state.
- Increase hairline contrast where dark surfaces meet.
- Respect Increase Contrast by strengthening borders and reducing translucent overlays.

## Images And Overlays

- Use light tags on dark image regions and dark tags on light image regions where possible.
- Avoid permanent overlays that obscure important photo content.
- The split handle must remain visible over bright and dark photos.

## Documentation Update Note

Created to define MVP1 light/dark behavior for design implementation.
