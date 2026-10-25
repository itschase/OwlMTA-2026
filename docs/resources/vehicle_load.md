# `vehicle_load`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; live startup is unverified.
- Evidence state: source-confirmed, partial source review.
- Runtime state: unverified.

## What it does

`vehicle_load` is the startup loader for persisted vehicles. It reads non-deleted vehicle records, creates the MTA vehicle elements, allocates them in the shared pool, and restores identity, ownership, faction, position, appearance, damage, upgrades, lock, fuel, battery, radio, hotwire, impound, and respawn state. Its manifest explicitly says new gameplay logic should not be added here.

## Player and staff use

There is no normal player command or standalone staff interface. Players and staff experience its result: persisted vehicles exist after startup with their saved state. One exported `loadOneVehicle` function allows another trusted server resource to reload an individual record.

## Operator use

The loader is sensitive to database readiness and to the availability of `mysql`, `pool`, `global`, `anticheat`, `vehicle`, `vehicle_fuel`, `vehicle_manager`, and related model/texture functions. Startup order is therefore a release gate even though the manifest does not declare those dependencies.

The loader reports progress through the HUD and processes records in batches. Operators need a clear completion signal and a quarantine/recovery path for malformed rows so one bad vehicle cannot make startup status ambiguous.

## Technical map

- Manifest: [`mods/deathmatch/resources/[vehicle]/vehicle_load/meta.xml`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_load/meta.xml)
- Loader: [`load_s.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_load/load_s.lua)
- Primary data owner: `vehicles`; additional lookups and state are supplied by connected vehicle and model resources.
- Export: `loadOneVehicle`.

## Known risks and next work

- Define structured startup logs for total rows, loaded rows, skipped/deleted rows, failures, duration, and the affected vehicle ID without exposing sensitive data.
- Document how malformed serialized fields, invalid models, duplicate pool entries, and failed element creation are handled.
- Runtime verification should use a disposable database containing empty, normal, damaged, impounded, faction-owned, customized, and intentionally malformed sample rows. The production server remains unrun until that fixture and rollback plan exist.
