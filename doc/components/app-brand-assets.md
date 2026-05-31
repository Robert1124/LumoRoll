# App Brand Assets

## Purpose

Document the production app icon and matching in-app brand mark used by LumoRoll MVP1.

## Inputs

- Source artwork: generated image artwork provided by the project owner.
- Asset catalog destinations:
  - `LumoRoll/Resources/Assets.xcassets/AppIcon.appiconset/`
  - `LumoRoll/Resources/Assets.xcassets/LumoRollBrandIcon.imageset/`

## Outputs

- iPhone AppIcon PNGs for notification/settings/Spotlight/app launcher sizes plus the 1024px marketing icon.
- `LumoRollBrandIcon`, a universal 1x/2x/3x image set for SwiftUI app-level branding.
- Outputs are generated as a rounded transparent slide-style replacement that matches the message-supplied final icon direction, so the extra outer backing does not read as an icon border.

## Data Dependencies

These assets are static bundled resources. They do not depend on user photos, app storage, Photos permissions, networking, or generated Film Roll content.

## Relationship To Other Modules

- Xcode uses `AppIcon` through `ASSETCATALOG_COMPILER_APPICON_NAME`.
- SwiftUI screens can load `Image("LumoRollBrandIcon")` for app identity surfaces.
- Functional buttons continue to use SF Symbols through the design system button components.

## State Management

Brand assets are stateless. SwiftUI views should treat them as decorative app identity only when surrounding text already exposes the app name. If the visible app title is omitted, the image should expose `LumoRoll` through accessibility.

## Error States

If `LumoRollBrandIcon` is missing from the bundle, SwiftUI will render an empty image slot. Keep nearby supporting copy understandable and make missing-brand visual QA part of release review.

## Empty States

Do not use the brand icon as the empty Film Roll placeholder. Empty states should continue to describe the missing user content and the next available action.

## Future Extension Points

- Add alternate app icon support only after the user-facing settings behavior is designed.
- Revisit launch screen branding if the app moves beyond the current system `UILaunchScreen` configuration.
- Keep brand assets reserved according to the root `NOTICE`.
