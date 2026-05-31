# LumoRoll Brand Assets

## Purpose

Define how the provided app icon artwork is used in the native iOS app and where brand assets should not be used.

## Source

- Source type: generated image artwork provided by the project owner.
- Added to app on May 25, 2026.
- Public repository license boundary: source code and documentation are MIT licensed; LumoRoll brand assets, app icons, and product imagery are reserved brand assets. See the root `NOTICE`.

## Bundled Outputs

- `LumoRoll/Resources/Assets.xcassets/AppIcon.appiconset/`: iPhone app icon slots and the `1024x1024` iOS marketing icon.
- `LumoRoll/Resources/Assets.xcassets/LumoRollBrandIcon.imageset/`: 1x/2x/3x static brand mark for SwiftUI app-level identity.

Generated outputs use the rounded transparent slide-style replacement that matches the message-supplied final icon direction, without the earlier oversized outer backing.

## In-App Usage

- Use `LumoRollBrandIcon` only on app identity surfaces when a screen explicitly has an app identity slot.
- If the visible app name is not shown near the mark, expose `LumoRoll` as the image accessibility label.
- Current Library home does not show a brand icon, title cluster, or `Your color rolls` header; creation is owned by the carousel add card.

## Non-Usage

- Do not replace functional SF Symbol controls with the brand artwork.
- Do not use the brand icon as a Film Roll thumbnail, photo placeholder, import action, export action, or error indicator.
- Do not introduce alternate app icons until settings and user-facing behavior are designed.

## Light And Dark Mode

The brand image is full-color static artwork and should render unchanged in light and dark appearances. Surrounding surfaces, shadows, and borders should adapt using existing `LumoTheme` colors.

## Release Review

- Verify all generated PNG slots are square and opaque.
- Confirm the 1024px marketing icon renders correctly in App Store tooling.
- Review home-screen small-size legibility on device.
- Keep the brand assets reserved unless the project owner explicitly publishes a broader asset license.
