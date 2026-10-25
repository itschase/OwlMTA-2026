# `item-move`

## Status

- Active resource; full manifest and paired server-caller review completed; runtime unverified.
- Discussion: [Script Resource: item-move](https://github.com/itschase/OwlMTA-2026/discussions/259).
- The tracked server configuration enables it, but the live startup state is unknown.

## What it does

`item-move` is a client transform editor for persistent world-item objects. Players/property holders and authorized staff can select a visible object, adjust position/rotation with keyboard, mouse, or numeric fields, reset or protect it, then save. The UI owns no database writes; persistence and server authorization are implemented by `item-system`.

## Player and operator workflow

1. `object-interaction`, item inventory code, or a staff command triggers `item:move` with an object.
2. The editor remembers the local transform, disables collision locally, and opens controls.
3. Client input changes the preview transform.
4. Protect forwards `protectItem` to `item-system`; Save forwards the object plus six client-selected transform values to `item-system`.
5. The backend updates `worlditems` and the live element transform, which `item-world` reloads later.

The editor has no exports, server script, durable edit session, version lock, or persistence of its own. The manifest loads four client-side scripts; `shared/functions.lua` is client-loaded despite its name.

## Source-confirmed findings

- The local `canEditObject` function is never called, so the UI's stated eligibility policy does not prevent users from opening the editor.
- The server save handler uses authenticated `client` for permission checks, but trusts the caller-selected event source object and all supplied coordinates/rotations. It does not prove the target is a persistent world item, validate its ID/parent/context, require proximity or an active edit session, or check finite/range-bounded transforms.
- SQL values are built from client transform strings; DB success and live-element correction are sequential, without transaction, revision, lock, or reconciliation. Concurrent editors silently race.
- Default/exterior movement policy can permit remote movement when the item has the default everyone policy, unless another key/protection check blocks it.
- Keyboard/controller next/previous/deselect paths reference undefined `gExisting`; `isChanged()` always returns true, so unchanged objects still submit a save.
- Protected-item handling blocks keyboard movement but numeric fields can still change the local preview. Item ID 169 is blocked in the normal client path but is not independently denied by the server save handler.
- Selection disables collision locally. Cleanup restores normal state for common close/reset paths, but resource stop does not explicitly restore collision. Repeated saves can be sent while the editor remains open.
- Several client globals are undeclared, controls claim an unmapped F key, and failure feedback from SQL/authorization is limited.

Current server safeguards use `client`, `item-world` permission evaluation, organization protection, staff rank/duty checks, and additional restrictions for item IDs 138/139. These do not validate the supplied target and transform, and runtime behavior remains unverified.

## Tracked work and target direction

- [Issue #213](https://github.com/itschase/OwlMTA-2026/issues/213) owns actor/target binding, proximity/context, and malicious placement validation; extend it for `item:move:save` rather than duplicating.
- [Issue #214](https://github.com/itschase/OwlMTA-2026/issues/214) owns SQL/live-state atomicity, concurrency, restart recovery, and reconciliation.
- [Issue #244](https://github.com/itschase/OwlMTA-2026/issues/244) owns typed permission policy and item-world authorization.
- [Issue #151](https://github.com/itschase/OwlMTA-2026/issues/151) owns the contextual action that should begin the move flow.

Proposed direction: issue a short-lived server move session bound to the authenticated actor, exact object instance and revision, original transform, permissions, proximity, and world context. Validate finite numbers and safe bounds on the server, parameterize persistence, use optimistic versioning, and return explicit accept/reject results with authoritative resync. Make one idempotent client cleanup path restore collision, controls, cursor, and freeze state for close, target destruction, dimension change, rejection, and resource stop. Implement real dirty tracking and remove or repair the undefined navigation controls.

## Runtime verification matrix

All runtime behavior is unverified. A future disposable-server pass should cover actor roles and every move permission; protected and special item IDs; interior/dimension and distance; malformed/extreme transforms; direct save calls with invalid/non-world targets; two-editor races and target pickup/delete; DB failure and restart exact-transform load; keyboard/mouse/controller controls; no-op saves; collision/freeze/cursor cleanup; and unavailable dependencies.
