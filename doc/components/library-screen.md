# Library Screen

## Purpose

Show the user's saved Film Rolls as the app home screen and primary entry point.

## Inputs

- Film Roll summaries from a library feature model.
- Create action.
- Open-roll action.

## Outputs

- Cover Flow-style 3D reversal-slide Film Roll carousel with a trailing blank add card.
- Empty library state.
- Navigation intent to Film Roll detail.
- Modal intent to create a new Film Roll.

## Data Dependencies

- Film Roll ID, name, created date, reference thumbnail, reference thumbnail aspect ratio when loaded, palette, processed photo count.
- Repository load status.

## Relationship To Other Modules

- Owned by Features.
- Uses DesignSystem components such as cards, palette swatches, and empty states.
- Calls Domain use cases through a feature model.
- Must not access Storage directly.

## State Management

View-local:

- Centered slide index and selected carousel item ID. The selected item can be either a saved Film Roll or the trailing add card.
- Horizontal drag translation for the Cover Flow carousel.
- No vertical scroll state; Library home is a fixed viewport screen.
- Linear first/last carousel boundaries; the carousel does not wrap from the last card to the first or from the first card to the last.
- Dynamic Cover Flow transform derived from each card's normalized offset from center.

Feature model:

- `LibraryFeatureModel.State`: `idle`, `loading`, `loaded([FilmRoll])`, or `failed(String)`.
- Empty repository results are represented as `loaded([])`.
- Duplicate load/reload calls are ignored while `loading`.
- If a reload fails after content is loaded, the previous `loaded([FilmRoll])` state is preserved and `lastErrorMessage` carries the refresh error.
- `pendingIntent`: `createFilmRoll` or `openFilmRoll(id:)`; intents carry IDs only and no image data. The root Create route is now emitted from the centered blank add card rather than a header plus button.

## Error States

- Library load failure.
- Missing thumbnail fallback.
- Manifest recovery warning.

## Empty States

When no Film Rolls exist, show a friendly create-first state directly on the Home background. The blank reversal-slide Film Roll card must use the same card width, center scale, reserved title region, and center-plus-20 card placement as the saved-roll carousel state, so its size and position match the saved-roll presentation. Empty state does not show the carousel page dot, a bottom create pill, header plus button, or header brand/title cluster. Creation is available by tapping the blank card, which contains a centered add affordance. Place the `Create your first Film Roll` prompt in the same title area above the card, not below it. Do not wrap this empty state in a separate white/surface panel, show a generic photo placeholder, or show a blank carousel.

## Future Extension Points

- Sort options.
- Long-press actions.
- Duplicate/delete if added after MVP1 planning.
- Search by notes or palette tags.

## Task 7B Implementation Note

`LibraryScreen` renders only approved MVP1 controls: the reversal-slide carousel, the blank add card, empty state, and retry state. It does not show a header icon/title cluster, header plus button, search, filters, duplicate controls, Home bottom tabs, Preview LUT, long-press affordances, inactive commands, or vertical home scrolling. The screen dispatches `LibraryFeatureModel` intents; `LumoRollRootView` performs navigation.

## Task 8B2 Implementation Note

Library cards now receive reference thumbnail relative paths through `FilmRollDisplayData`. The screen asks the app display image store for each card thumbnail at a bounded card size and keeps the existing placeholder if loading fails or the path is unavailable. The carousel does not synchronously decode image data in `body`.

## Task 10 UI Fix Note

The library now uses a horizontal reversal-slide carousel. Cards keep a square slide-mount ratio, first and last cards can center in the viewport, and selection haptics fire when the centered card changes. `ReversalFilmRollCard` constrains the lit effect to the photo window display/backlight, does not recolor or retone thumbnails, and avoids third-party film-brand copy.

## Task 10B Carousel Refinement Note

The Home carousel first used repeated `ScrollView` cells. That was superseded by Task 10C because the desired effect is a Cover Flow-style 3D carousel rather than a flat horizontal list.

## Task 10C Perspective Carousel Note

The Home carousel now uses a fixed viewport with no vertical `ScrollView`. Horizontal dragging updates a custom Cover Flow transform from each card's normalized offset. The centered slide is front-facing, larger, highest in z-order, and has the brightest photo-window display/backlight; this presentation must not mutate thumbnail color, tone, saturation, contrast, or pixels. Left and right slides rotate toward the center, have dimmer photo windows, and sit behind the selected card. `SlideMountCard` keeps the same outer mount size while its photo window has fixed height and width derived from the loaded reference image aspect ratio with clamps. Missing aspect ratio falls back to the default slide-window ratio until the thumbnail load cache provides dimensions.

Current follow-up removes looped carousel behavior. Snap index math now clamps at the first and last saved Film Roll, and drag translation is bounded so outward drags at either end do not visually continue into a wrapped card.

Follow-up: card activation is a tap gesture on the card instead of a nested `Button`, while the carousel owns a high-priority horizontal drag gesture. This keeps left/right swipe available across the whole card surface. The carousel group sits lower in the fixed viewport so the slide carousel reads as the center of the Home page.

Current add-card follow-up: the header icon/title and header plus were removed. The carousel always appends a blank reversal-slide add card after saved rolls. When this card is selected, the title above the carousel reads `Create a new roll`; the summary reserves the same metadata and palette row height as a saved roll so paging to the add card does not shift the rest of the Home layout. Tapping the centered add card opens Create Film Roll. In the no-roll state, the same blank card shows a centered add affordance while `Create your first Film Roll` sits in the reserved title area above it.

Current layout follow-up: the selected roll title/metadata block now sits above the slide carousel in a reserved-height region. The title top inset remains lifted by 20 pt from the raw carousel inset, while the card position is computed independently so the slide card center sits exactly 20 pt below the available viewport center. The title-to-carousel spacing is derived from the available height, and the carousel/page-dot visual group uses no extra vertical offset. The blank no-roll card uses the same title-above-card and center-plus-20 placement as saved-roll carousel cards. The title region is reserved for saved rolls, the trailing add card, and the no-roll empty state so switching or starting empty does not move the carousel geometry.
