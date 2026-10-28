# `glue-system` resource

**Review state:** Full client command and server attachment-event review. Attachment policy, cleanup behavior, and live vehicle interactions remain runtime-unverified.

**GitHub record:** [Script Resource Discussion #537](https://github.com/itschase/OwlMTA-2026/discussions/537); [Issue #448](https://github.com/itschase/OwlMTA-2026/issues/448) tracks server-side event validation.

## Player use

The client `/glue` command attaches a player to the contacted vehicle, or attaches the player's occupied vehicle to a nearby vehicle. A second invocation detaches the current attachment. Client code computes relative position and rotation and sends these values to server events. The active manifest loads one client and one server script; no database, staff command, Discord role, or explicit export is declared.

## Server authority and issue

The server exposes `gluePlayer`, `ungluePlayer`, `glueVehicle`, and `unglueVehicle` as remote events. `gluePlayer` attaches the authenticated `client` to the client-supplied vehicle using client-supplied slot and transforms, with no validation of vehicle type, proximity, occupancy, world, or attachment policy. `glueVehicle` checks a 20-unit distance from `client` to event `source`, but does not fully validate element types or world relationship. `unglueVehicle` changes collision/frozen/position state and detaches arbitrary event `source` without binding it to the caller's valid attached pair. See [Issue #448](https://github.com/itschase/OwlMTA-2026/issues/448). These are source-confirmed trust-boundary gaps; gameplay impact is not runtime-verified.

## Dependencies and operator notes

The reviewed manifest has no resource dependencies or persistence. Server trailer attach/detach handlers emit nearby-player debug diagnostics, and vehicle respawn reenables collisions. Before enabling, verify that callers/resource configuration are understood and that attachment cleanup handles quit, respawn, vehicle destruction, and resource restart. The client backup file is not loaded and should not be treated as active behavior.

## Future interaction and runtime verification

This is a natural contextual-interaction candidate for attaching/detaching only the current player or vehicle after server validation. Keep current roleplay permission local; Discord roles are irrelevant to ordinary vehicle attachment. On a disposable server test valid attachment, invalid/distant/cross-dimension targets, occupied vehicles, chained attachments, attacker-selected targets, logout/respawn, and collision restoration. No MTA server or tests were run.
