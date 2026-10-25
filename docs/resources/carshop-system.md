# `carshop-system`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified.

## What it does

`carshop-system` places and stocks six dealerships, creates display vehicles and purchase interactions, and implements land and boat vehicle crushers. It bridges product data in `vehicles_shop` to persisted player vehicles in `vehicles`.

## Player use

Dealerships show available products, price, and tax. A player can purchase with cash, a bank balance, or an eligible token. The intended success path creates the vehicle record, grants its key, loads the vehicle, decrements stock, and tells the player to `/park` it.

At a crusher, an eligible owner drives into the interaction, receives a quote, confirms deletion, receives proceeds, and loses the vehicle keys and stored vehicle inventory. Both purchase and crusher flows change high-value persistent state and must be server-authoritative and failure-safe.

## Staff use

Lead administrators can use `/restartcarshops` or `/refreshcarshops`; manual refreshes are announced and logged. `vehicle_manager` uses the shop list for its library. The tow impound path reads shop price data when it needs a vehicle value.

## Operator use

Dealership displays refresh every ten minutes. Primary tables are `vehicles_shop`, `vehicles`, and `vehicle_logs`. The manifest includes the Belgica boat-crusher map. Important dependencies include `mysql`, `vehicle`, `vehicle_manager`, `item-system`, `anticheat`, `global`, `integration`, `logs`, `hud`, and `language-system`.

The manifest declares `getPriceFromModel`, but no implementation was found in the reviewed scripts. Operators should treat this as an unresolved integration contract until callers and runtime behavior are verified.

## Technical map

- Manifest: [`mods/deathmatch/resources/[vehicle]/carshop-system/meta.xml`](../../mods/deathmatch/resources/%5Bvehicle%5D/carshop-system/meta.xml)
- Dealership definitions: [`g_shops.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/carshop-system/g_shops.lua)
- Stock, display, and purchase server flow: [`s_shop.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/carshop-system/s_shop.lua)
- Crusher server flow: [`s_crusher.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/carshop-system/s_crusher.lua)
- Client purchase and crusher flows: [`c_shop.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/carshop-system/c_shop.lua) and [`c_crusher.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/carshop-system/c_crusher.lua)
- Exports include vehicle-price lookups, sale availability, and client/server shop definitions.

## Known risks and next work

- [Issue #16](https://github.com/itschase/OwlMTA-2026/issues/16) covers server-derived product, stock, range, payment, creation, key, reload, and stock-decrement safety.
- [Issue #113](https://github.com/itschase/OwlMTA-2026/issues/113) covers one-use crusher confirmation, live driver/location/ownership checks, server-recomputed payout, and failure-safe deletion/cleanup/payment.
- Source review also found a one-based-array fallback using index `0`, an undefined error-path variable, and a spawn-blocker tuple comparison that should be handled during bounded car-shop maintenance.

Runtime verification must cover every dealership and payment type, out-of-stock and concurrent purchase, vehicle creation/reload failure, `/park` handoff, both crushers, disconnect/cancellation, duplicate confirmation, cleanup, payout, and audit evidence in a disposable database.
