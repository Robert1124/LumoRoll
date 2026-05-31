# Project Website

## Purpose

Provide a GitHub-ready public webpage for LumoRoll that presents the app's core Film Roll metaphor, local-first processing boundary, and `.cube` export capability using the same design language as the native app.

## Inputs

- LumoRoll design tokens and behavior from `design/`.
- Runtime PNG assets from `LumoRoll/Resources/Assets.xcassets`.
- Code-drawn app components used as web references:
  - `ReversalFilmRollCard.swift`
  - `FilmRollDetailScreen.swift` light-box transport layout.
- GSAP animation rules.
- Remotion and HyperFrames composition source for reusable teaser motion.

## Outputs

- Vite/React webpage under `web/`.
- Copied web-safe assets under `web/public/lumoroll-assets/`.
- Remotion teaser composition under `web/src/remotion/`.
- HyperFrames-compatible teaser HTML under `web/hyperframes/`.

## Data Dependencies

The webpage uses only static assets and local UI state. It does not load user photos, app manifests, generated LUTs, model files, training data, analytics, or network-backed application data.

## Relationship To Other Modules

- Design ownership is documented in `design/project-website.md`.
- The web project is separate from the iOS target and is not included by `project.yml`.
- The page reuses app asset files by copy, not by linking into `.xcassets`.

## State Management

- React state owns the selected hero Film Roll card.
- React state owns the Apply preview mode (`before`, `split`, `after`).
- React state owns Apply intensity as a `0...100` value. The value updates the visible label, the range control fill, and CSS variables that blend the processed preview side.
- React state owns the Split preview divider as a percentage. Pointer dragging inside the preview updates the divider and switches the preview mode back to `split`; the white handle also supports keyboard left/right/home/end adjustment.
- GSAP owns entrance, pointer parallax, eased split-position transitions, and decorative finite film motion.

## Error States

- Missing copied assets degrade the light-box and brand imagery; run `npm run build` and browser verification after asset changes.
- If reduced motion is enabled, entry animations are skipped and content remains visible.
- If pointer drag is unavailable, the split handle remains keyboard-adjustable and the Before/Split/After tabs still provide fixed preview states.
- If JavaScript fails, the page will not mount because it is a React/Vite app; keep copy and assets simple enough for future static fallback work.

## Empty States

The public page uses static sample Film Roll data and does not have user-empty states.

## Future Extension Points

- Add real app screenshots from a release build.
- Add release/download links.
- Add localized web copy.
- Add a static prerender/export step if the GitHub Pages deployment strategy requires it.
