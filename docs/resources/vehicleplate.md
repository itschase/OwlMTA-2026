# `vehicleplate`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified.

## What it does

`vehicleplate` supplies the DMV interface for custom plates, vehicle registration and unregistration, insurance viewing and cancellation, vehicle-tax lookup, and purchase of a vehicle-sale paper.

## Player use

The DMV client creates its interaction NPCs in interior 5, dimension 4. Players request a server-generated list of eligible owned vehicles. Custom plates use donor GameCoins; registration changes use cash; insurance details come from the separate `insurance` resource; the sale-paper path delivers the document through the item system.

## Faction and staff use

Faction members with the `respawn_vehs` permission can register or unregister eligible faction vehicles. This resource declares no separate staff command. `vehicle_manager` uses the shared `checkPlate` export for its `/setvehicleplate` flow.

## Operator use

Primary data is stored in `vehicles` and `mdc_dmv`; insurance state belongs to the `insurance` resource. Important connections include `mysql`, `pool`, `vehicle`, `factions`, `insurance`, `donators`, `anticheat`, `global`, `logs`, `item-system`, and `rightclick`. Custom-plate purchases use donor purchase history, while registration changes write DMV and database logs.

DMV location, prices, plate policy, role/capability rules, tax behavior, and document delivery should become operator-visible configuration or documented policy rather than remaining spread across UI and server code.

## Technical map

- Manifest: [`mods/deathmatch/resources/[vehicle]/vehicleplate/meta.xml`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicleplate/meta.xml)
- Shared plate policy: [`g_plate_system.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicleplate/g_plate_system.lua)
- Server lists and mutations: [`s_plate_system.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicleplate/s_plate_system.lua)
- DMV UI: [`c_plate_system.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicleplate/c_plate_system.lua)
- Shared export: `checkPlate`.

## Known risks and next work

- [Issue #114](https://github.com/itschase/OwlMTA-2026/issues/114) covers binding every DMV mutation and charge to `client`, live vehicle/ownership/faction validation, server-side plate validation and uniqueness, nearby interaction state, and failure-safe payment/item/mutation handling.
- [Issue #45](https://github.com/itschase/OwlMTA-2026/issues/45) covers the separate insurance cancellation path.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) remains the parent remote-event audit.

Runtime verification must cover owned and faction vehicle lists, custom and duplicate/invalid plates, GameCoin and cash failure, registration and unregistration, remote/stale requests, insurance viewing/cancellation, tax lookup, sale-paper delivery, database failure, and audit output.
