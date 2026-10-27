# `dynamic_lighting_vehicles` resource

**Review state:** Full manifest and direct-export source review. The active script calls the `dynamic_lighting` client API; rendering, element lifecycle, and performance require runtime verification. The older archived variant is documented separately at [`archive/dynamic_lighting_vehicles.md`](archive/dynamic_lighting_vehicles.md).

## What players see

This client resource builds headlight effects for streamed vehicles using spot lights from `dynamic_lighting`. It tracks per-vehicle light handles, updates their direction/position/color, applies a null shader to the headlight texture, and removes effects on resource stop, element destruction, or stream-out. It exposes no direct player command, database table, or staff workflow in its manifest.

## Connections and operating expectations

- `dynamic_lighting` supplies the client light API; its exported functions must be available when this consumer initializes and when vehicle effects are created.
- The manifest does not declare an explicit dependency, so startup ordering is implicit.
- Vehicle data and game authority belong to other resources; this client script provides visuals and does not grant control over vehicles.
- Visual effects are ordinary presentation and do not need Discord staff or supporter roles.

## Source comparison and future interaction

The active `c_vehicleLight.lua` has a narrower resource-change trigger condition than the archived copy. The archive dossier records that difference. A future vehicle context menu can expose a lighting status or local preference only; server-side vehicle ownership and state remain with the owning gameplay resource.

The periodic updater reads the current `lights` state into local `state`, but the darkness normalization at line 146 references `new_state`, which is local to a separate callback. The condition therefore falls back to mode 1 in this function, including when the current state is mode 2. This source-confirmed issue is tracked in [Issue #392](https://github.com/itschase/OwlMTA-2026/issues/392); the visual impact needs runtime confirmation.

## Runtime verification

Verify shader fallback, client API compatibility, streamed vehicle creation/destruction, element-data toggles, resource stop/restart cleanup, and cost under dense traffic. Static source review does not establish graphics behavior or performance.
