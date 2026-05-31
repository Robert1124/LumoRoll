# Project Website Design

## Purpose

Define the public project webpage visual direction so it extends LumoRoll's app language instead of becoming a generic product landing page.

## Source Inputs

- App visual source: `design/Lutroll/`.
- Home reference: `design/Lutroll/_check/09-final.png`.
- Detail reference: `design/Lutroll/_check/10-detail.png`.
- Native design tokens: `design/design-system.md` and `LumoRoll/DesignSystem/LumoTheme.swift`.
- Runtime visual assets copied from `LumoRoll/Resources/Assets.xcassets` into `web/public/lumoroll-assets/`.

## Required Visual Structure

- First viewport uses a full-page warm cream product stage with the LumoRoll name, concise local-first copy, and an interactive reversal-slide Film Roll carousel.
- The reversal slide is code-drawn in the web layer because the app's Home slide card is also code-drawn rather than a standalone PNG asset.
- The Film Roll detail showcase must preserve the app's layer order: back frame image, finite CSS film strip, front block image.
- The film strip body, sprockets, leader/trailer, and frames are CSS/HTML replicas because the app draws these in SwiftUI.
- Apply showcase uses a before/split/after preview with a real intensity slider. Intensity changes the processed side of the preview without changing the split position.
- Split preview uses a draggable white handle that moves the before/after divider. The handle should remain visually light and touch-friendly, matching the app's simple preview control tone.
- Privacy/export section states only MVP1-safe claims: local processing, photo-only scope, explicit Photos write, and `33x33x33` `.cube` export.

## Assets

Copied web assets:

- `web/public/lumoroll-assets/lumoroll-brand-icon.png`
- `web/public/lumoroll-assets/app-icon.png`
- `web/public/lumoroll-assets/lightbox-back-frame.png`
- `web/public/lumoroll-assets/lightbox-front-block.png`
- `web/public/lumoroll-assets/lightbox-back-frame-dark.png`
- `web/public/lumoroll-assets/lightbox-front-block-dark.png`

Do not use the older `FilmLightBoxViewerPlate` assets unless the main thread explicitly decides to revert away from the current back-frame/front-block implementation.

## Motion Rules

- GSAP controls page entrance, film motion, and subtle pointer parallax.
- GSAP also eases split-position changes when the user switches between Before, Split, and After.
- Prefer transforms and opacity.
- Respect reduced-motion settings.
- The selected slide window may brighten as presentation lighting, but the photo colors must not be retouched.
- HyperFrames composition timelines must be finite and registered through `window.__timelines`.

## Copy Rules

- Use `LumoRoll`, `Film Roll`, `33x33x33`, and `.cube`.
- Avoid third-party film-brand names.
- Avoid exact style-copying claims.
- Do not introduce network AI, cloud processing, accounts, video, HDR, or Display P3 advanced workflow copy for MVP1.

## Future Extension Points

- Add real App Store/TestFlight links after release packaging is decided.
- Add final screenshots from the iOS app once release UI is frozen.
- Add localized website copy if the root README localization expands.
