# `vehicle_manager`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; live startup is unverified.
- Evidence state: source-confirmed, partial source review.
- Runtime state: unverified.

## What it does

`vehicle_manager` is the administrative and content-management layer around vehicles. It provides vehicle lookup and inspection, vehicle logs and notes, creation and deletion workflows, restore/remove/force-sale actions, teleport and respawn tools, the vehicle library, custom model properties, and handling configuration and test-drive workflows.

## Player use

This is primarily a staff and content-management resource. Ordinary players may encounter its effects through vehicle definitions, custom handling, and vehicles created through approved shop or staff workflows, but it is not a normal player dashboard.

## Staff use

The resource exposes `/checkveh` and `/checkvehicle`, the vehicle manager UI, vehicle lookup and teleport commands, respawn/recovery actions, administrative notes, `/sethotwired`, vehicle-library tools, and handling editors. Access currently depends on a mixture of legacy trial-admin, admin, supporter, scripter, vehicle-consultant, faction, and duty predicates. These must be inventoried action by action before mapping Discord roles to named capabilities; donor/supporter status alone must not imply administrative authority in the rebuilt policy.

Administrative actions write vehicle logs and the central database. A future dashboard should call the same server-side command/capability layer rather than becoming a separate authorization path.

## Operator use

The resource relies on `mysql`, `pool`, `vehicle`, `vehicle_load`, `vehicle_fuel`, `factions`, `integration`, `anticheat`, `logs`, and car-shop/model data. It performs schema and record maintenance related to vehicle definitions, deletion state, logs, notes, and handling. Operators need an explicit backup and rollback procedure before enabling destructive or bulk vehicle actions.

## Technical map

- Manifest: [`mods/deathmatch/resources/[vehicle]/vehicle_manager/meta.xml`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_manager/meta.xml)
- Manager UI server: [`s_vehicle_manager.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_manager/s_vehicle_manager.lua)
- Commands and lifecycle actions: [`s_vehicle_commands.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_manager/s_vehicle_commands.lua)
- Vehicle audit history: [`s_vehicle_logs.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_manager/s_vehicle_logs.lua)
- Vehicle library: [`vehicle-library/s_vehicle_library.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_manager/vehicle-library/s_vehicle_library.lua)
- Handling workflows: [`vehicle-handling-editor`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_manager/vehicle-handling-editor)
- Exports include vehicle-log creation, custom vehicle property loading, shop-record lookup, and system vehicle deletion.

## Known risks and next work

- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) must cover every remotely callable manager, library, and handling action, including actor binding, target validation, and server-owned values.
- [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3) must replace the mixed legacy predicates with action-specific named capabilities while keeping supporter benefits separate.
- [Discussion #106](https://github.com/itschase/OwlMTA-2026/discussions/106) describes the planned staff control center and command registry.
- Runtime verification should use disposable vehicle records and exercise read-only search first, followed by notes, respawn, restore/remove, force sale, hotwire state, creation/deletion, handling changes, and rollback/audit evidence.
