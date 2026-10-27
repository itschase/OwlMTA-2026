# `colorblender` resource

**Review state:** Full manifest and direct-caller source review for the picker and its mechanic-job integration. MTA GUI behavior, current compatibility, and server-side mechanic eligibility remain runtime-unverified.

## Purpose and player use

`colorblender` is a reusable client-side HSV/RGB/hex color-picker window. Players encounter it indirectly through the mechanic vehicle-customization workflow; it is not a standalone command or player feature. A mechanic can select vehicle paint colors or headlight color, preview changes, and then save or cancel through the mechanic UI.

## Technical map and connections

- `meta.xml` loads `c_blender.lua`, packages four image assets, and exports `openPicker(id, start, title)`, `closePicker(id)`, and `isPickerOpened(id)` to client resources.
- `c_blender.lua` maintains picker windows by caller-supplied string ID, converts HSV and RGB, accepts six-digit hex text, draws the selection interface, and emits local client events `onColorPickerChange`, `onColorPickerOK`, and `onColorPickerCancel`.
- `job-system/mechanic/c_mechanic_job.lua` is the direct consumer found. It opens a picker for paint or headlights, sends color previews to the mechanic's server handlers, and submits or restores color state when saved/cancelled. The mechanic system owns vehicle eligibility, the actual preview, and persistence—not the picker.
- Picker GUI state and current color are client memory only. The helper owns no database, server script, account state, external service, command, or keybind.
- Ordinary use is a UI utility and does not require staff, donor, or Discord roles. Any Discord or local staff policy for mechanic actions belongs at the mechanic server mutation boundary, not in this generic color picker.

## Staff, operator, and command review

No staff/operator workflow or configuration is declared in this resource. The picker API is exported client-side and requires its consumer to pass a unique ID; `openPicker` returns false if that ID is already active, and close/query operations report whether it exists. There are no slash commands to replace. The visual dialog is the appropriate interaction for selecting a color; future work should focus on readability, accessibility, and resolution scaling rather than adding command equivalents.

## Findings and improvement opportunities

The source review found no concrete resource-specific defect to file. That is not runtime validation. Follow-up opportunities include:

- Verify multiple picker lifecycle behavior, cursor ownership, event-handler cleanup, Escape/close flows, and consumer cancellation paths in MTA.
- Check GUI scaling and usability across supported resolutions and input methods.
- Confirm each consuming resource validates vehicle ownership, mechanic eligibility, current state, and submitted color values on its server-side preview/save handlers.
- Document the exported helper's unique-ID and event contract for future consumers before adding more call sites.

## Runtime verification still required

In a disposable MTA client/server, verify open/query/close semantics, color conversion and hex editing, simultaneous picker IDs, click/drag behavior, cursor restoration, resource stop/restart, mechanic preview/save/cancel, and client/server mechanic authorization. No server or tests were run for this review.
