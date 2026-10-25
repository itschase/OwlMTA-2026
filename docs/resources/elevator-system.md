# `elevator-system`

## Status

- Active resource under `mods/deathmatch/resources/elevator-system`.
- Full manifest, client/server caller, persistence, and integration review completed from source.
- The tracked backup startup configuration marks it enabled; live configuration and runtime behavior are unverified.
- No MTA server or database was started for this review.
- Discussion: [Script Resource: elevator-system](https://github.com/itschase/OwlMTA-2026/discussions/272).

## What it does

This resource implements two related movement systems. Legacy elevators connect two endpoints and can carry players, vehicles, or both. Lifts group multiple floor pickups into a single elevator interface. Both systems update player position and world interior/dimension, and hand property-aware movement to `interior_system`.

## Player use

### Door elevators

At an elevator endpoint, the player interacts through the client pickup flow maintained by `interior_system`. The server checks configured mode, disabled and one-way state, linked-interior locks, and vehicle-driver eligibility, then moves the player or occupied vehicle. Modes are stored as `0` players only, `1` players and vehicles, `2` vehicles only, and `3` locked. A separate disabled value also blocks travel.

### Multi-floor lifts

Players enter a lift pickup, view its floor list, select a floor, and activate travel. The current client builds and submits the destination coordinates, interior, dimension, pickup, same-interior flag, and displayed floor number. Those values are currently consumed by the server travel handler; see [Issue #228](https://github.com/itschase/OwlMTA-2026/issues/228) for the required server-owned interaction-context work.

## Staff use

The resource exposes command-based construction, inspection, repair, and state controls:

- Elevators: `/addelevator` (`/adde`), `/aelevator` (`/adde2`), `/delelevator` (`/dele`), `/nearbyelevators` (`/nearbye`), `/fixnearbyelevators` (`/fixnearbye`), `/delnearbyelevators` (`/delnearbye`), `/delefromint` (`/delelevatorsfrominterior`), and `/toggleelevator` (`/togglee`).
- Lifts: `/addlift`, `/dellift`, `/nearbylifts`, and `/togglelift`.

Legacy gates use existing Trial Admin, Scripter, Lead Admin, and Supporter checks, varying by command. Those are current-source predicates, not a proposed Discord role policy: donor/supporter status must remain distinct from staff authority in a future named-capability mapping. The temporary `/fixnearbyelevators` repair path is intentionally available without the same explicit staff check as other repair/configuration commands and should be reviewed before production policy is finalized.

## Server-operator view

The manifest declares four scripts and these server exports:

- `findElevator`, `reloadOneElevator`, `loadOneElevator`, `delElevatorsFromInterior`
- `findLift`, `reloadOneLift`, `loadOneLift`

There are no `<include>` dependencies in the manifest. Source-level direct integrations include `mysql`, `pool`, `anticheat`, `integration`, `global`, `interior_system`, `interior-manager`, `datetime`, `logs`, and client `hud`.

The `elevators` table holds paired endpoint coordinates, rotations, interiors/dimensions, vehicle mode, disabled state, and one-way state. The `lifts` parent table stores lift ID, disabled state, and comment. `lift_floors` stores each floor location, world context, floor number, and display name. Legacy elevator loading is scheduled after resource initialization; lift loading is attached to `onResourceStart`. A backup server config snapshot lists this resource for startup, but that file is not evidence of a live deployment.

Property cleanup calls the exported elevator deletion function. `interior_load` coordinates client pickup loading. Item type 73 changes a nearby elevator's vehicle mode through a server-side proximity check and a non-remote event.

## Technical map

- Manifest: [`meta.xml`](../../mods/deathmatch/resources/elevator-system/meta.xml)
- Door elevator server behavior: [`s_elevator_system.lua`](../../mods/deathmatch/resources/elevator-system/s_elevator_system.lua)
- Door elevator client behavior: [`c_elevator_system.lua`](../../mods/deathmatch/resources/elevator-system/c_elevator_system.lua)
- Lift server behavior: [`s_elevator_lift.lua`](../../mods/deathmatch/resources/elevator-system/s_elevator_lift.lua)
- Lift interface and event caller: [`c_elevator_lift.lua`](../../mods/deathmatch/resources/elevator-system/c_elevator_lift.lua)
- Property-side elevator caller/cleanup: [`c_pickups.lua`](../../mods/deathmatch/resources/%5Binterior%5D/interior_system/c_pickups.lua) and [`s_interior_system.lua`](../../mods/deathmatch/resources/%5Binterior%5D/interior_system/s_interior_system.lua)
- Startup evidence: [`mtaserver.conf.bak`](../../mods/deathmatch/mtaserver.conf.bak)

## Source-confirmed findings and trackers

- Door travel's remotely triggerable `elevator:enter` handler correctly uses MTA's server-provided `client` for actor identity, but trusts the remote source elevator and `goingin` direction without checking that the caller is at the selected endpoint in its interior and dimension. Tracked with the broader [Issue #228](https://github.com/itschase/OwlMTA-2026/issues/228), which now includes the door-elevator path.
- The `lift:use` handler accepts client-supplied coordinates and world context and does not confirm a loaded source floor, server-owned destination floor, lift membership, proximity, or enabled state. This lift path is part of the same interaction-context boundary in #228.
- Lift enabled/disabled state is not loaded onto active lift elements and is not enforced in travel. [Issue #268](https://github.com/itschase/OwlMTA-2026/issues/268).
- The interior lock helper queries `type` but reads the misspelled `rype` key, changing type-2 lock behavior. [Issue #269](https://github.com/itschase/OwlMTA-2026/issues/269).
- Elevator/lift admin workflows have abort continuation, target/player validation, parent-floor relationship, blank-name, partial-create, and mutation/reload mismatch defects. [Issue #270](https://github.com/itschase/OwlMTA-2026/issues/270).
- `lift:me` is remotely triggerable and forwards caller-provided text to the local roleplay-action path; its current client trigger is commented out, but modified clients can still invoke it. [Issue #271](https://github.com/itschase/OwlMTA-2026/issues/271).
- [Issue #17](https://github.com/itschase/OwlMTA-2026/issues/17) already owns the SQL-NULL/empty-table case in smallest elevator ID allocation. [Issue #231](https://github.com/itschase/OwlMTA-2026/issues/231) owns elevator cleanup as part of recoverable property lifecycle transactions.

These are static findings. They have not been demonstrated in a running server. MTA's remote-event guidance states that client-supplied event arguments and source are untrusted and that the server should use `client` to identify the remote caller; see [triggerServerEvent](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) and [Script security](https://wiki.multitheftauto.com/wiki/Script_security).

## Modernization direction

Replace client-authored movement destinations with server-resolved floor and endpoint records. Issue short-lived, single-use interaction context only after server-side proximity, dimension/interior, loaded-element, permission, vehicle, mode, disabled, lock, and one-way checks. Treat elevator and lift state as persistent domain state with explicit load/reload behavior. Validate administrative IDs and relationships at mutation boundaries, wrap multi-row creation and deletion in transactions or compensating workflows, and route all movement and roleplay events through named capability and audit interfaces. Keep current player commands and UI as compatibility adapters while an in-game operator panel is developed.

## Runtime verification still required

Use a disposable server/database only after safe-start readiness is approved. Cover player/vehicle mode matrices, driver and passenger travel, endpoint distance and world context, forged/replayed events, lift-floor membership, enabled/disabled reload behavior, locked property types, all admin mutation failures, roleplay action event limits, property cleanup, resource restart and database outage recovery. Until then, source review is complete but runtime state remains unverified.
