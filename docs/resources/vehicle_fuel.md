# `vehicle_fuel`

## Status and evidence

- Resource path: `mods/deathmatch/resources/[vehicle]/vehicle_fuel`.
- Source review: manifest scripts and the player-facing attendant/POS path reviewed; cross-resource settlement and complete runtime behavior still require verification.
- Runtime: unverified. The MTA server has not been started for this review.
- Startup snapshot: enabled in the tracked `mtaserver.conf.bak`; this does not establish the live server's startup configuration.
- GitHub record: [Script Resource Discussion #108](https://github.com/itschase/OwlMTA-2026/discussions/108); implementation tracking [Issue #342](https://github.com/itschase/OwlMTA-2026/issues/342) and [Issue #343](https://github.com/itschase/OwlMTA-2026/issues/343). Broader caller validation remains under [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1).

## Purpose in everyday terms

This resource gives vehicles fuel and battery state. Driving consumes fuel according to movement and vehicle handling. Engine, lights, and radio affect battery state. A vehicle that runs out of fuel has its engine shut off. Players can refuel at configured fuel attendants, refill a fuel can, and use that can through the vehicle context menu.

Fuel is stored as vehicle element data and expected to be saved/loaded by the vehicle persistence resources. Fuel attendants and their shop links are loaded from the `fuelpeds` data path. Fuel-can item type `57` stores its quantity in the item value. The resource also uses ATM card item type `150` and the `atm_cards` table for POS PIN checks. Confirm exact schema and persistence ownership against the current database before migration or production use.

## Player guide

1. Find a configured fuel attendant and interact through the existing NPC interaction flow.
2. For a vehicle, lower the window, request fuel, and turn the engine off if prompted. Choose cash or bank-card payment when a card is available, then choose a fixed amount or fill-up.
3. On foot, ask to refill a carried fuel can. A fuel can is item type `57`; the source caps it at 25 litres.
4. Use the vehicle right-click menu to use a fuel can. This menu is a current interaction entry point; a future contextual-action/third-eye interface could provide the same action without removing the compatibility path first.

The dialogue is client-rendered, but the server must own every decision that changes money, fuel, inventory, card authorization, or shop income. Current source does not yet enforce that complete boundary; see the implementation issues.

## Staff and operator guide

The current script exposes these commands. The exact gates below are source checks, not Discord roles:

| Command(s) | Source gate | Use |
|---|---|---|
| `/makefuelped`, `/makefuel`, `/makefuelnpc` | Trial Admin | Create an attendant at the operator's current position. |
| `/nearbyfuels`, `/nearbynpcs` | Trial Admin or Supporter | List nearby fuel attendants and their IDs/shop link. This Supporter check is an existing legacy utility entitlement, not staff authority. |
| `/gotofuel`, `/gotofuelped`, `/gotofuelnpc` | Trial Admin or Supporter | Teleport to an attendant by ID. Preserve the legacy gate only if product policy confirms it; it must not become an administrative Discord capability by implication. |
| `/delfuel`, `/deletefuel`, `/delfuelped`, `/deletefuelped` | Trial Admin | Mark an attendant deleted and remove it from the live world. |
| `/setfuelpedlink` | Admin | Link an attendant to an interior/shop record. |

Discord authorization is a future integration, not present behavior. If command authorization is migrated, route only staff actions through named staff capabilities in the standalone Discord identity adapter and an Owl-side authorization facade. Keep donor/supporter entitlement separate. Preserve local checks for command syntax, target record, shop/interior association, actor state, and mutation success. Do not turn a donor role into Admin, GameMaster, or Trial Admin. Player fueling must not require Discord staff authorization.

Operator configuration still needs decisions for fuel price/rate, vehicle capacities, fuel-free models, faction-funded fueling, donor free-fuel perk, attendant links, and logging levels. Faction IDs paying for fuel are hard-coded in the current source. `FUEL_PRICE` starts at a source value and is randomized hourly. These rules should become validated operator configuration with documented defaults and migration behavior.

## Resource and data flow

| Layer | Responsibility |
|---|---|
| `deplete_s.lua` | Server-side fuel/battery calculations, vehicle-enter synchronization, and timer/coroutine scheduling. Driver-present depletion starts on resource start. Empty-vehicle depletion is defined but its startup call is commented out. |
| `deplete_c.lua` | Client receives fuel/battery values and updates local element data for presentation. |
| `g_fuel.lua` | Shared model-to-tank-capacity map and exported `getMaxFuel`. Unlisted model IDs default to 100 litres. |
| `s_fuel_peds.lua` | Attendant creation/loading, dialogue state, cash/bank/faction/donor settlement, fuel-can purchase, shop income, and staff commands. |
| `c_fuel_peds.lua` | Dialogue GUI, fuel-can/POS interface, and server-event requests. Client choices are untrusted input. |
| `s_fuel_bank.lua` | Looks up the inserted card and checks its PIN for POS fueling. |

Important connections include `vehicle`, `vehicle_load`, `vehicle_manager`, `anticheat`, `global`, `bank`, `factions`, `donators`, `language-system`, `chat-system`, `item-system`, `mysql`, `pool`, `cache`, and HUD/NPC interaction resources. Many are implicit exports; startup order and compatibility need safe-start validation.

Core exported function: `getMaxFuel(id)` accepts a vehicle element or model ID and returns its mapped capacity, or `100` for an unlisted valid model. The manifest requests MTA server version `1.5.5-9.14060` or newer; verify the supported MTA build and all APIs against the intended deployment release before raising that floor.

## Source-confirmed defects and tracked work

- [Issue #342](https://github.com/itschase/OwlMTA-2026/issues/342): station conversation events accept client answers and caller-selected source elements; the server does not bind the exact attendant/player/step state. Delayed callbacks need fresh occupancy, vehicle, engine, dimension, proximity, price, and settlement checks. Fuel-can payment can precede a failed item update. This is a static trust/transaction finding, not a live exploit report.
- [Issue #343](https://github.com/itschase/OwlMTA-2026/issues/343): POS PIN event uses unvalidated client text in SQL construction, depends on ambient `thePlayer` state from a separate handler, does not establish the caller/card-owner relationship, and responds to client-selected event source. It lacks visible attempt throttling and one-use success state tied to the fuel purchase.
- A missing/unlinked `shop_link` previously caused numeric/string operations to receive `nil`. The source now normalizes missing links to `0` in attendant creation and the nearby listing, and `payShopOwner` safely skips absent attendant links. This is fixed in source only; runtime verification remains pending.
- Related design review: faction debit, bank/cash charge, item update, vehicle fuel, shop income and transfer record must be handled as an idempotent recoverable transaction. Donor free fuel currently skips player charge but still reaches shop-income settlement; confirm intended business policy.
- Source startup invokes the driver-present depletion loop but comments out `fuelDepleting(2)`, so parked/empty vehicles do not currently run that branch. Whether that is an intentional balance choice needs an explicit setting and operator documentation.
- Some debug strings are unconditional at the normal debug level for the empty-vehicle loop; use consistent `[vehicle_fuel]` categories and configurable verbosity before enabling that workload.

## Commands and interface modernization

Keep existing commands available while cataloging them with syntax, access policy, effects, audit events, and examples. For each command, record whether the same task could be offered through a dashboard or contextual action. This resource is a useful third-eye candidate: target an attendant, vehicle, fuel can, or linked shop; show only actions applicable to the current player and state. Server-side authorization and settlement remain authoritative regardless of interface.

## Discord/API integration boundary

No Discord role IDs or capability mapping are configured here. Future staff operations (creating/deleting/linking attendants) may call the standalone identity adapter through the host facade. Any check must resolve the current account on the server at the action boundary, fail closed during service outages, and still run this resource's local target/association/data validation. Supporter/donor benefits should use a distinct donor-tier entitlement, not administrative capabilities. Log the resource/action, actor account/character, target attendant/shop, decision source, and outcome without logging OAuth tokens, raw role lists, PINs, or secrets.

An optional API should expose stable, versioned operations rather than this resource's database schema or arbitrary Lua exports. The MTA resource remains the authority for live vehicle, inventory, position, faction, and money state. A website or bot can request permitted operations, but cannot decide or directly write authoritative game state.

## MTA API notes

- MTA's [script security guide](https://wiki.multitheftauto.com/wiki/Script_security) and [`triggerServerEvent`](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) documentation explain why server handlers should use the server-provided `client` to identify the remote caller and independently validate all client arguments.
- See MTA's [event model](https://wiki.multitheftauto.com/wiki/Event) for source/propagation semantics. Client event source is not proof that an element is a legitimate resource-owned attendant.
- These references inform the security review; they do not establish behavior in a running OwlMTA deployment.

## Validation plan (not yet run)

In a disposable, supported MTA/database environment, verify model capacity and fuel-free cases; vehicle/fuel persistence across restart; depletion and engine shutdown; battery, lights and radio behavior; each cash/bank/faction/donor path; fuel-can refill/use and failed inventory update; attendant create/load/link/delete; shop-income and database failure recovery; PIN success, failure, lock, throttling, card ownership and replay; GUI cleanup on disconnect/restart; and forged, stale, out-of-order or cross-player events. Confirm accurate receipts and logs. Do not mark these checks complete based on source inspection.
