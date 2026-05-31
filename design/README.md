# Design Folder

All design-related material for LumoRoll belongs in this folder.

This includes:

- Product concept design.
- Page structure.
- User flows.
- Information architecture.
- Visual direction.
- Design tokens.
- Colors, typography, spacing, radius, icon style, and motion rules.
- Component design.
- Film Roll card design.
- Film strip design.
- Detail screen design.
- Before / after screen design.
- Full-screen viewer design.
- Wireframes and mock descriptions.

## Current Source

The current design prototype source lives in:

- `design/Lutroll/`

Future design work should extend this direction instead of introducing a disconnected visual language.

`design/Lutroll/` is a visual reference and prototype source, not production implementation architecture. Do not modify it during MVP1 documentation work unless explicitly assigned.

When the prototype source and screenshots drift, prefer `design/Lutroll/_check/09-final.png` for the Home direction.

## Current Visual Direction

- Warm, clean, lightweight, film-inspired.
- Slightly playful, but not childish.
- Product-quality rather than novelty-filter style.
- Home uses a fixed-viewport Cover Flow-style 3D reversal-slide Film Roll carousel with one centered front-facing card, inward-rotated dim side cards, selected-roll title/metadata above the carousel, and the centered card positioned 20 pt below the available viewport center. The no-roll empty state reuses that same title-above-card and card-center placement. Center-card lighting affects only the slide/photo window display/backlight; it does not recolor or retone the image.
- Detail uses a large adaptive center projected frame with no visible background block or top frame caption, a larger bottom finite film transport, and a split light-box viewer: a larger labeled square back frame (`LUMOROLL` / `LIGHT BOX`) sits behind the moving film, while a smaller square front viewer block sits above the film. The front viewer keeps the current size and aperture proportion, uses the provided true-transparent realistic molded-plate front-block source image in light mode, and derives dark mode from that same image so the screw relief and molded edge detail stay consistent. The back frame leaves the bottom labels visible below the front block. The film passes between those two layers, so the selected film frame is seen through the front aperture at the same size as the film-strip cell rather than as a separate enlarged thumbnail. The light/dark view-finder assets use fully transparent outside/window cutouts and opaque plate material, film frames are not tap targets, inactive film cells are dimmed, the selected cell stays bright under the viewer, and the moving black film body stops at the actual film edges. `.cube` export and Add Photo live as circular icon buttons in the top-right header row beside the menu.
- Apply flow uses a centered target import panel and source choice dialog, then opens preview/intensity controls with explicit Save or Cancel.
- Full-screen viewer uses a darker immersive treatment.
- The production app must support both light and dark modes.

Canonical product name: **LumoRoll**.

## Current MVP1 Implementation Alignment

The SwiftUI MVP1 implementation now exists and maps the design language into native components under `LumoRoll/DesignSystem/` and feature screens under `LumoRoll/Features/`.

The app icon artwork is installed in `LumoRoll/Resources/Assets.xcassets/AppIcon.appiconset/`, with a matching in-app `LumoRollBrandIcon` asset used only for app-level identity.

Implemented MVP1 screens:

- Library: horizontal reversal-slide Film Roll carousel with empty/loading/error states.
- Create: one-page reference import from Photos or Files, local preview, required naming, and save state.
- Detail: roll metadata, top-right `Export .cube`, Add Photo, and menu circular icon buttons, large adaptive center projected frame without a visible container background or top frame caption, bottom film transport with reference sample first, and light/dark square reference-style light-box view finder assets with the body-level plus affordance hidden.
- Apply: centered target import panel; tapping it asks for Photo Library or Files, then the imported target enters the preview/intensity editor with `Save` and `Cancel`.
- Fullscreen viewer: dark frame browser with reference sample first; processed frames can be shared, edited, or removed.

The current Apply and Fullscreen screens do not surface Save to Photos. Photos library writes remain explicit only where a future visible Save to Photos action is shown.

MVP1 design corrections:

- Use `33x33x33` LUT language, not `32x32x32`.
- Do not use third-party film-brand names or trade dress on slide-card copy.
- Do not allow an `Untitled Roll` save path; every Film Roll must be user-named.
- Defer search, duplicate, and fullscreen Save to Photos unless the main thread explicitly approves them.
- SwiftUI should use native SF Pro/SF Mono defaults; a custom serif is future-only until licensing is settled.

## MVP1 Design Documents

- `design/mvp1-design-spec.md`: MVP1 design contract and prototype interpretation.
- `design/design-system.md`: visual tokens, type, color, motion, icon, and texture rules.
- `design/brand-assets.md`: app icon, in-app brand mark, provenance, and release-review notes.
- `design/components.md`: core component behavior and states.
- `design/screens.md`: Home, Create, Detail, Apply, and Full-screen screen specs.
- `design/dark-mode.md`: light/dark token mapping and dark viewer behavior.
- `design/swiftui-mapping.md`: native SwiftUI translation notes.
- `design/accessibility.md`: accessibility requirements for MVP1 design.
- `design/mvp1-open-decisions.md`: decided items, open questions, risks, and follow-ups.
- `design/project-website.md`: public project website visual direction, copied asset rules, and motion rules.

## Design Documentation Rule

If a future task changes product behavior, visual structure, component behavior, empty states, or motion, update the relevant design document in `design/` before or alongside implementation.

Do not edit `design/Lutroll/` prototype source files during documentation-only tasks unless the task explicitly assigns that source.
