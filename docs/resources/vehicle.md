# `vehicle`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; the live target configuration is not verified.
- Evidence state: source-confirmed, partial source review.
- Runtime state: unverified; the server has not been started for this rebuild.

## What it does

`vehicle` is the central runtime resource for player and faction vehicles. It controls common vehicle state and interaction such as engines, keys, locks, windows, doors, horns, odometer activity, variants, saved position, right-click actions, and vehicle persistence helpers. Other resources use its exports to inspect vehicle features and save or create vehicles.

## Player use

Players encounter this resource whenever they enter or interact with a vehicle. The current client interface exposes engine start and stop, lock and unlock, inventory, doors, windows, fuel-can use, parking, vehicle-interior entry for supported models, and several vehicle-specific actions. Item type `3` represents a vehicle key. `/park` saves the current position as the vehicle's future spawn position; it is not a garage-storage system.

The intended engine flow checks for a key on the client unless the vehicle is eligible for the legacy staff/supporter/faction or hotwire exceptions. The server moves an available key into the vehicle while the engine runs and returns it when the engine stops. The current server handlers do not yet enforce every part of that intended boundary; see Issues #91-#93.

## Staff and faction use

Faction vehicles have `/fpark` and `respawn_vehs` permission paths. Legacy staff, supporter, scripter, tow, and vehicle-consultant checks also expose vehicle recovery or management actions across this resource and `vehicle_manager`. Those numeric predicates are migration inputs for the future named-capability system; supporter/donor status must remain separate from staff authority.

## Operator notes

The resource owns live vehicle state and writes the `vehicles` table and vehicle activity timestamps. It relies on resources including `mysql`, `global`, `anticheat`, `item-system`, `factions`, `integration`, `logs`, `datetime`, `vehicle_fuel`, and `vehicle_manager`. These links are mostly implicit Lua export calls rather than declared manifest dependencies, so startup-order validation remains part of the safe-start gate.

The manifest exposes `reloadVehicle` with `http="true"`. That is an inbound HTTP-call surface and needs explicit ACL and deployment review before a public server is started.

## Technical map

- Manifest: [`mods/deathmatch/resources/[vehicle]/vehicle/meta.xml`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle/meta.xml)
- Main state and parking: [`s_vehicle_system.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle/s_vehicle_system.lua)
- Engine lifecycle: [`engine_s.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle/engine_s.lua) and [`engine_c.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle/engine_c.lua)
- Right-click actions: [`c_vehicle_rightclick.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle/c_vehicle_rightclick.lua)
- Persistence helpers: [`save_s.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle/save_s.lua)
- Important exports include vehicle feature checks, shop vehicle creation, save helpers, door definitions, variants, activity/protection checks, and safe storage helpers.

## Known risks and next work

- [Issue #91](https://github.com/itschase/OwlMTA-2026/issues/91): bind outside lock requests to keys, authorized relationships, and proximity.
- [Issue #92](https://github.com/itschase/OwlMTA-2026/issues/92): bind engine control and key movement to the actual driver and server-derived audience.
- [Issue #93](https://github.com/itschase/OwlMTA-2026/issues/93): bind parking requests to the real actor and current vehicle state.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1): complete the remote-event authorization audit.
- [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3): replace legacy staff/supporter predicates with named capabilities without granting staff authority from donor roles.

Runtime verification must cover key transfer, engine start/stop, hotwire exceptions, lock/unlock, owner and faction parking, disconnect handling, persistence, and rejected remote requests on the selected MTA release.
