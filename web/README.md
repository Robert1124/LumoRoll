# LumoRoll Web

This folder contains the GitHub/project web page for LumoRoll.

## What It Uses

- Vite + React for the public webpage.
- GSAP for the page reveal, carousel feel, pointer parallax, and film-strip motion.
- The app's copied runtime assets from `LumoRoll/Resources/Assets.xcassets`:
  - `lightbox-back-frame.png`
  - `lightbox-front-block.png`
  - dark variants of both layers
  - `lumoroll-brand-icon.png`
- CSS/HTML replicas of the Home reversal-slide card and finite film strip because those are code-drawn in the app, not standalone PNG files.
- Interactive Apply preview with a real intensity range control and a draggable split handle.
- Remotion source in `src/remotion/` for a square teaser composition.
- HyperFrames-compatible HTML in `hyperframes/lumoroll-web-teaser.html`.

## Commands

```sh
npm install
npm run dev
npm run build
npm run remotion:still
```

Cloudflare Pages should build this folder with Node 22. The committed `.node-version` pins `22.16.0` for Pages builds that respect version files.

## Design Boundary

The website follows the app's MVP1 language: warm cream/noir surfaces, reversal slides, a layered light-box viewer, local-only processing copy, photo-only scope, and `33x33x33` `.cube` export. It should not introduce cloud, network AI, account, video, HDR, or generic photo-filter messaging.
