# LumoRoll MVP1 Design Spec

## Purpose

This document is the design contract for LumoRoll MVP1. It translates the `design/Lutroll/` prototype into native iOS product requirements without treating the JSX/CSS prototype as implementation architecture.

Canonical product name: **LumoRoll**.

## Source Of Truth

- Visual reference: `design/Lutroll/`, especially `_check/10-detail.png`, `_check/11-apply.png`, and `_check/12-fullscreen-dark.png`, plus the current Home reversal-slide carousel direction recorded in `design/screens.md`.
- When older Home grid screenshots and the current Home carousel direction drift, prefer the current Home carousel direction.
- The prototype's React/CSS files are reference artifacts only. SwiftUI implementation should use native patterns documented in `design/swiftui-mapping.md`.

## MVP1 Experience

LumoRoll lets a user create a named Film Roll from exactly one reference image, apply that Film Roll to photos, save processed results into the app, explicitly save or share outputs, and export the generated LUT as a `.cube` file.

MVP1 must remain:

- iPhone-first.
- Photo-only.
- Local-first.
- Warm, light, friendly, film-inspired, and slightly playful.
- Useful as a creative tool without looking like a complex professional grading suite.

## Required Corrections From Prototype

- Use `33x33x33` for LUT language. Do not ship `32x32x32` copy.
- A Film Roll cannot be saved as `Untitled Roll`. The save action is disabled until the name field contains a valid user-entered name.
- Use **LumoRoll** capitalization in app chrome, docs, and user-facing text.
- Home slide-card copy must avoid third-party film-brand names and trade dress.
- Do not treat prototype-only CSS filter recipes as image-processing requirements.
- Do not ship search, duplicate, or fullscreen Save to Photos in MVP1 unless the main thread explicitly approves scope expansion.

## Visual Direction

The tone is warm cream plus noir film utility:

- Cream paper-like app surfaces.
- Deep ink text and controls.
- Small peach/sage/dusk/butter accents drawn from each Film Roll's palette.
- Reversal-slide cards on Home, with one centered lit selection and dimmer unselected side cards. The lighting brightens only the slide/photo window display/backlight; it must not alter the image color, tone, saturation, contrast, or thumbnail pixels.
- Noir treatment for immersive photo viewing and optional dark detail treatment.
- Film cartridge and film strip motifs as recognizable product signatures.

Avoid:

- Generic photo-filter app styling.
- Heavy pro color-grading UI.
- Overly cute novelty treatment.
- One-note beige-only screens; accents and photo content should break up the warm base.

## App Structure

Primary MVP1 screens:

- Home library.
- Create Film Roll.
- Film Roll detail.
- Apply photo.
- Full-screen viewer.

Supporting surfaces:

- Import source chooser.
- Save/export/share confirmation.
- Empty states.
- Error states.
- Permission prompts only at action time.

## Core Interaction Rules

- Film Roll creation always starts from one reference image.
- The reference sample appears first in the Film Roll Detail projector transport film.
- Applying a Film Roll imports one target photo, shows preview/intensity controls, and saves to the current Film Roll only after explicit `Save`.
- Intensity blends the original image and LUT-processed image. It does not regenerate, modify, or replace the LUT.
- Saving to Photos is an explicit action and must not happen as a side effect of saving into the Film Roll.
- Export `.cube` from the Film Roll detail context.

## Documentation Update Note

Created for MVP1 design-system alignment. Future design changes must update the relevant file in `design/` before or alongside implementation.
