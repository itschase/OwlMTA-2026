# `vehicle_fuel`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; live startup is unverified.
- Evidence state: source-confirmed, partial source review.
- Runtime state: unverified.

## What it does

`vehicle_fuel` models fuel and battery state. It calculates fuel loss from movement and vehicle handling, tracks battery use and recovery from the engine, lights, and radio, shuts an engine down when fuel is exhausted, synchronizes fuel data to the driver, and provides station-ped conversations for buying fuel or filling a fuel can.

## Player use

At a configured fuel attendant, a player can talk to the ped from a vehicle or on foot. Vehicle fueling requires the engine to be off. The conversation offers cash or eligible bank-card payment and fixed amounts or a fill-up. A player carrying item type `57` can ask for a fuel-can refill. The vehicle right-click menu also exposes fuel-can use.

Some models are explicitly marked fuel-free, including bicycles, trailers, trains, boats, and selected special vehicles. The shared `getMaxFuel` export determines a model's tank capacity.

## Staff and operator use

The source contains a fixed list of faction IDs whose organizations pay for fuel. That hard-coded policy should become operator data or named configuration during the economy review. The price begins from a source default and is randomized hourly; this behavior and its business/economy effects need deliberate balancing before runtime rollout.

The depletion loop spreads work across timers and coroutines according to player and vehicle counts. Operators should profile its timer cadence and debug output under realistic vehicle populations before enabling production diagnostics.

## Technical map

- Manifest: [`mods/deathmatch/resources/[vehicle]/vehicle_fuel/meta.xml`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_fuel/meta.xml)
- Depletion and battery model: [`deplete_s.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_fuel/deplete_s.lua)
- Fuel attendant and payment flow: [`s_fuel_peds.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_fuel/s_fuel_peds.lua)
- Bank-card support: [`s_fuel_bank.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_fuel/s_fuel_bank.lua)
- Shared capacity rules: [`g_fuel.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle_fuel/g_fuel.lua)
- Important connections include `vehicle`, `anticheat`, `global`, `bank`, `factions`, `language-system`, and the item system.

## Known risks and next work

- The complete station conversation, payment, item, and remote-event paths still require the project-wide authorization and transaction audit in [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1).
- Fuel price, tank capacity, depletion, faction payment, and fuel-free model rules need an operator-owned configuration design.
- Runtime verification should cover cash and bank payment, insufficient funds, faction-paid fuel, fuel-can refill/use, engine shutdown, battery depletion, resource restart, and vehicle save/load consistency.
