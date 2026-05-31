# Film Roll Card

## Purpose

Present a Film Roll summary in the library as a small mounted reversal-slide card.

## Inputs

- Film Roll ID.
- Name.
- Reference thumbnail.
- Palette swatches.
- Created date.
- Processed photo count.
- Open action.
- Centered state.
- Center progress / photo-window display/backlight amount.
- Reference image aspect ratio when available.

## Outputs

- Tappable card.
- Accessible label summarizing name and photo count.
- Open-roll intent.

## Data Dependencies

- Library summary from Domain.
- Thumbnail file resolved by Storage and exposed as displayable image data/URL by the feature model.

## Relationship To Other Modules

- UI component in DesignSystem or Features depending on implementation granularity.
- Used by Library Screen.
- Does not call repositories or processing services.

## State Management

Stateless apart from pressed/highlighted visual state and the injected centered/progress values. The library feature model owns data freshness.

## Layout Constraints

The Home variant is square to match a mounted reversal-slide proportion. The decoded image's intrinsic size must never expand the outer carousel cell.

Every card in the Home carousel uses the same base outer dimensions. The carousel transform may scale the centered card visually, but the base mount size remains stable. Side cards are dimmer through photo-window display/backlight attenuation or a neutral overlay, rotated toward center, and can overlap inward behind the centered card. The lit effect belongs only to the photo window, not to the whole card back, and must not alter the thumbnail image's color, tone, saturation, contrast, or stored pixel data.

The photo window has fixed height across the carousel. Its width follows the loaded reference image aspect ratio and is clamped to a minimum and maximum width within the slide mount. When aspect ratio is missing, use the fallback slide-window ratio until the display image cache reports dimensions.

Card copy may use `LUMOROLL`, `COLOR ROLL`, `LUT`, and `33x33x33`; it must not use third-party film-brand names.

## Error States

- Missing thumbnail: show a generated placeholder using palette colors.
- Missing or invalid aspect ratio: use fallback ratio and keep the outer card stable.
- Extreme aspect ratio: clamp photo-window width inside the mount.
- Long name: truncate in the card header and title area.
- Missing palette: show neutral swatches.

## Empty States

Not used alone. Library Screen owns the empty library state.

## Future Extension Points

- Context menu for share, duplicate, rename, or delete.
- Favorite marker.
- Last-used metadata.
