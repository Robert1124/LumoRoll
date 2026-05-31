# Empty and Error States

## Purpose

Define recoverable product states for MVP1 so users always know what happened and what to do next.

## Empty States

Empty Library:

- Purpose: first-run or no saved rolls.
- State contract: library load succeeds as `loaded([])`, not as an error.
- Visual: blank reversal-slide Film Roll card.
- Layout: directly on the Home background with no separate white/surface panel; card size and position match the one-Film-Roll carousel state; the blank card includes a centered add affordance; no page dot, header plus, header title/icon cluster, or bottom create pill; create prompt sits closer to the card than saved-roll metadata.
- Message: `Create your first Film Roll`
- Primary action: tapping the blank card.

Empty Film Roll:

- Purpose: a new roll has a reference image but no processed photos.
- State: show the reference sample as the center projection and only bottom film frame. The projector plus affordance is hidden in this iteration.
- Message: `Add a photo to start this roll.`
- Primary action: `Import Photo`

No target photo selected:

- Purpose: apply flow has not received a target photo.
- Action: show photo picker entry points and return to Detail on cancel.

## Loading States

Create save/generation:

- Message: `Building your Film Roll...`
- Detail: `This usually takes a few seconds.`
- State: keep the user on the one-page create flow after Save and prevent duplicate save attempts.

Preview render:

- Message: `Preparing preview...`
- State: keep controls disabled until a preview is ready.

Final render/save:

- Message: `Saving...`
- State: prevent duplicate taps and keep the output recoverable.

## Error States

Unsupported image:

- Message: `This photo could not be used.`
- Recovery: choose another photo from Photos or Files.

Analysis failed:

- Message: `LumoRoll could not build this Film Roll.`
- Recovery: retry analysis or choose another reference.

Empty Film Roll name:

- Message: `Enter a name to save this Film Roll.`
- Recovery: focus the name field.
- State contract: save is blocked before creation work starts; do not generate or save an `Untitled Roll`.

Image load failed:

- Message: `This photo could not be loaded.`
- Recovery: choose another photo or return to the previous screen.

Preview/render failed:

- Message: `The preview could not be rendered.`
- Recovery: retry or choose another photo.

Save to Film Roll failed:

- Message: `This photo was not saved to the Film Roll.`
- Recovery: retry save.
- State contract: keep the selected target photo and current intensity for retry.

Save to Photos denied:

- Message: `This photo was not saved to Photos.`
- Recovery: save to Film Roll, share, or change Photos access in Settings.

Export `.cube` failed:

- Message: `The LUT could not be exported.`
- Recovery: retry export.

Create Film Roll save failed:

- Message: `This Film Roll was not saved.`
- Recovery: retry after checking the name and reference image.
- State contract: keep the draft name and selected reference image data for retry.

Share/export cancelled:

- State: no error message required.

## Dependencies

- Architecture must preserve enough in-memory state to retry failed saves or exports when possible.
- Image processing must distinguish unsupported input, analysis failure, render failure, and export failure.
- QA must verify denied permissions and large-image failures.

## Future Extension Points

- Broken asset repair UI.
- Local diagnostics for export compatibility.
- Draft recovery for interrupted creation or apply flows.
