# LumoRoll Design System

## Purpose

Defines the MVP1 visual language, tokens, and platform interpretation for native SwiftUI implementation.

## Design Principles

- Film-inspired, not retro cosplay.
- Friendly and light, not childish.
- Native iOS first, with custom detail where it makes the Film Roll metaphor clearer.
- Photo content carries much of the color; UI should frame and organize it.
- Controls should feel tactile but restrained.

## Color Tokens

Use semantic names in SwiftUI rather than copying CSS variable names directly.

| Role | Light Value | Dark Value | Use |
| --- | --- | --- | --- |
| App background | `#F4EFE6` | `#1A1612` | Primary screen background |
| Raised surface | `#FBF7EF` | `#221D17` | Cards, panels, bottom controls |
| Secondary surface | `#ECE3D2` | `#2C261F` | Segmented controls, subtle fills |
| Primary text | `#1F1A14` | `#FBF7EF` | Main copy and icons |
| Secondary text | `#6E665B` | `rgba(255,255,255,0.60)` | Metadata, captions |
| Tertiary text | `#918879` | `rgba(255,255,255,0.42)` | Labels and hints |
| Hairline | `rgba(31,26,20,0.08)` | `rgba(255,255,255,0.10)` | Borders and separators |
| Strong hairline | `rgba(31,26,20,0.14)` | `rgba(255,255,255,0.16)` | Interactive outlines |
| Primary accent | `#E89B7A` | `#E89B7A` | Brand dot, active detail, highlight |

Film Roll palette accents may include peach `#E89B7A`, butter `#E8C26A`, sage `#A8B89A`, dusk `#7A85A0`, rose `#D9938E`, mint `#B6CDB6`, and plum `#8A7088`.

## Typography

SwiftUI implementation should use native iOS type by default:

- Display: `.largeTitle` / `.title` with `.serif` only if a future licensing/design decision approves a custom serif.
- Body and UI: SF Pro through SwiftUI system fonts.
- Technical labels, LUT metadata, frame ids, and `.cube` labels: SF Mono via `.monospaced()`.

Prototype fonts such as Instrument Serif, Geist, and Geist Mono are not approved app dependencies. A custom serif is optional future work only after licensing and app-size impact are settled.

Letter spacing:

- Avoid global negative letter spacing in SwiftUI.
- Use small positive tracking for uppercase mono labels.
- Keep body text readable at Dynamic Type sizes.

## Shape And Radius

MVP1 uses soft but not overly rounded shapes:

- Small controls and tags: 8-10 pt.
- Thumbnails: 10-12 pt.
- Cards and panels: 18-22 pt.
- Large drop zones and preview panels: 22-26 pt.
- Pills and circular icon buttons: capsule/circle.
- Film frames inside strips: 4 pt to keep the film-frame feel.

## Elevation

Use subtle shadows in light mode:

- Cards: low shadow plus hairline.
- Preview photo: stronger soft shadow.
- Bottom action surfaces: light shadow only when raised above scrolling content.

Dark mode should rely more on tonal separation and hairlines than heavy shadows.

## Iconography

Use SF Symbols in SwiftUI where they match the prototype intent:

- Add: `plus`.
- Close: `xmark`.
- Back: `chevron.left`.
- More: `ellipsis`.
- Search, if later approved: `magnifyingglass`.
- Photos import: `photo`.
- Film Roll/save-to-roll: `film`.
- Share: `square.and.arrow.up`.
- Save/download: `arrow.down.to.line`.
- `.cube` export: `cube`.
- Split compare: `arrow.left.arrow.right`.

Icons should be rounded, medium weight, and paired with accessible labels.

App identity uses the bundled `LumoRollBrandIcon` asset, derived from the production `AppIcon` artwork. It may appear in app-level branding surfaces such as the Library header, launch-adjacent brand moments, or documentation screenshots. It should not replace functional SF Symbol controls, Film Roll thumbnails, or user photo placeholders.

## Motion

Motion should be quick and purposeful:

- Screen transitions: native navigation transitions.
- Button press: native pressed state or slight scale.
- Palette reveal during analysis: sequential, optional, short.
- Split preview drag: direct manipulation with no lag.
- Avoid entry animations that can leave content invisible if the app backgrounds.

Respect Reduce Motion by replacing decorative transitions with fades or immediate state changes.

## Texture

The prototype uses a paper/grain texture. In MVP1 this should be subtle and optional:

- Use system materials or static lightweight texture only if it does not hurt performance.
- Avoid animated noise.
- Do not reduce text contrast.

## Documentation Update Note

Created to guide MVP1 SwiftUI design implementation from the prototype reference.

## Task 7A Implementation Note

The reusable SwiftUI design system now lives under `LumoRoll/DesignSystem/`.

- `LumoTheme` provides dynamic light/dark semantic colors, spacing, radius, fixed component metrics, native SF typography helpers, and palette conversion helpers for `FilmRollPaletteColor`.
- SwiftUI components use system fonts and SF Symbols only.
- Photo components do not read local files or decode paths. `LumoPhotoDisplayData` accepts an injected SwiftUI `Image?` plus placeholder metadata so later app/system wiring can supply decoded thumbnails.
- MVP1 copy in reusable components uses `33x33x33` where cube size is shown.
