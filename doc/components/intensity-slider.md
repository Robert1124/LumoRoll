# Intensity Slider

## Purpose

Control how strongly the selected Film Roll LUT is blended with the original image.

## Inputs

- Current intensity value, expected 0...100.
- Change callback.
- Enabled/loading state.
- Optional visual mode for light/dark context.

## Outputs

- Updated intensity value.
- Render/preview intent through the owning feature model.

## Data Dependencies

- None beyond current view state and feature model value.

## Relationship To Other Modules

- Reusable UI component in DesignSystem.
- Used by Apply Photo in MVP1.
- Does not mutate LUT data.

## State Management

The slider can keep local drag state for smooth interaction. The feature model owns the committed intensity used for preview/final render.

## Error States

- Disabled while no photo is selected.
- Disabled or debounced while render cannot keep up.

## Empty States

If no image is selected, hide or disable the slider depending on final product direction.

## Future Extension Points

- Numeric stepper.
- Haptic ticks at 0, 50, and 100.
- Per-roll default intensity if a future product version adds roll-level settings.
