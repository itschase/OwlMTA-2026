# `customblips` resource

**Review state:** Full manifest and direct-caller source review. Client rendering and resource-stop behavior remain runtime-unverified.

## Purpose and player-facing behavior

`customblips` is a client-side drawing library that renders custom image markers and labels on the radar and F11 map. It provides distance-based visibility, rotation, icon coloring, text, secondary text, and optional paths. Players see the markers placed by gameplay systems; they do not manage access or authoritative game state through this resource.

## Integrations and API

All declared scripts in `meta.xml` run on clients. The resource exports client functions for creating/converting a custom marker and for changing stream radius, position, alpha, radar scale, visibility, color, text, image path, radar hiding, and rotation. Its render path runs on `onClientRender`; element destruction and resource stop are used for cleanup.

Two direct consumers were found:

- `sfia/c_radar.lua` creates and updates aircraft/vehicle markers, including callsign, heading, altitude, icon, position, and visibility.
- `pd-system/c_dispatch.lua` creates and updates police dispatch markers for on-duty members and vehicles, including callsign and siren state.

These client markers are presentation only; server-side eligibility and dispatch state belong to their consumer systems. No SQL, server event, permission predicate, or Discord integration is owned by `customblips`.

## Issues and source evidence

- **Cleanup can decrement the visible counter twice.** Each marker installs a resource-stop cleanup that decrements `VISIBLE_BLIP_COUNT`; `destroyCustomBlip` also removes the marker and decrements the same counter. Both current consumers explicitly destroy markers. A stale stop handler can undercount surviving markers and suppress rendering. See [Issue #370](https://github.com/itschase/OwlMTA-2026/issues/370). Runtime reproduction remains pending.
- **Invalid image arguments can reach an invalid dereference.** The check `not type(path) == "string"` does not reject non-string paths. If `dxImage:create` fails, the caller still reads `image.id`. See [Issue #371](https://github.com/itschase/OwlMTA-2026/issues/371). This is a source-confirmed malformed-input path, not a claim of exploitability.
- `isCustomBlipVisible` checks that an element is a widget but does not establish that it has a corresponding `streamedBlips` entry before reading its `visible` field. Existing consumers use IDs returned by `createCustomBlip`; no current failing caller was found. Track this as an edge-case review unless a concrete caller is identified.

## Discord and future interaction design

Ordinary players should not need a Discord role to see gameplay markers. The resource should remain a client presentation library. If future dashboards allow staff to change dispatch or aircraft visibility, the consumer must enforce its own server-side permission at each action boundary; a client blip or local export cannot grant authority.

## Runtime verification

Use a disposable client session to test marker create/update/destroy, destroying a marker before resource stop while another remains, invalid path/image load failure, radar/F11 visibility, and teardown when either `sfia` or `pd-system` stops. No MTA server or tests were run for this review.

## MTA references

- [onClientResourceStop](https://wiki.multitheftauto.com/wiki/OnClientResourceStop) documents the stopped resource root as the event source; confirm handler target and callback lifecycle against that contract.
- [dxCreateTexture](https://wiki.multitheftauto.com/wiki/CreateTexture) warns about texture memory use and recommends destroying textures when no longer needed. `customblips` has a custom image wrapper, so verify its cleanup against the actual element lifecycle.
