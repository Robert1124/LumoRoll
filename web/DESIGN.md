# LumoRoll Web Visual Identity

## Style Prompt

LumoRoll web uses the app's warm cream and noir film language. The page should feel light, tactile, and product-quality: a cream paper surface, reversal-slide Film Roll cards, a layered light-box viewer, finite black film strips, restrained peach/sage/dusk accents, and small monospaced technical labels for `.cube` and `33x33x33`.

## Colors

- App background: `#F4EFE6`
- Raised surface: `#FBF7EF`
- Secondary surface: `#ECE3D2`
- Primary text: `#1F1A14`
- Muted text: `#6E665B`
- Accent peach: `#E89B7A`
- Film black: `#2A2520`
- Noir background: `#1A1612`

## Typography

- Primary UI: system sans, matching SwiftUI SF Pro behavior.
- Display moments: restrained Georgia fallback to echo the prototype serif without adding a licensed custom font.
- Technical labels: `ui-monospace`, `SF Mono`, Menlo, Consolas.

## Motion

- Quick, tactile reveals using GSAP timelines.
- Carousel cards use transform, opacity, and filter only.
- Film strip movement is finite and reversible in HyperFrames; no infinite repeats in composition timelines.
- Respect reduced-motion settings on the website.

## What Not To Do

- Do not make the page a generic SaaS landing page.
- Do not use third-party film-brand names or trade dress.
- Do not recolor or retone photo windows when a slide is selected; only dim or light the window presentation.
- Do not flatten the detail viewer into one rectangle; preserve back-frame, film, front-block layering.
- Do not introduce cloud, network AI, video, HDR, or account messaging for MVP1.
