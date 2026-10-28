# `job-system`

## Status

- Tree/startup state: active resource tree; live startup unverified.
- Evidence: full review of every manifest-loaded script, relevant schema, and representative callers.
- Runtime: unverified. The server has not been started for this rebuild.
- Related design discussion: [Jobs and businesses](https://github.com/itschase/OwlMTA-2026/discussions/104).
- Resource discussion: [Script Resource: job-system](https://github.com/itschase/OwlMTA-2026/discussions/249).

## What it does

`job-system` owns selection of one civic job per character and bundles the active fishing, photography, mechanic, taxi/taximeter, bus, and locksmith implementations. It also exposes job-title and progression-loading helpers. Long-haul delivery is implemented by the separate `job-system-trucker` resource; manifest-commented trucker scripts and unlisted sweeper/street-cleaner files are not active parts of this resource.

The selected job is stored in `characters.job`. The MyISAM `jobs` table stores per-character/per-job level, progress, and truck-run counters, but has no primary key, unique character/job constraint, or foreign keys. Most active modules do not advance this progression data, so it is not yet a unified career framework.

## Player, staff, and operator use

- The City Hall employment UI offers delivery driver, taxi driver, bus driver, city maintenance, mechanic, locksmith, and long-haul truck driver. `/myjob` displays the current title and progression; `/endjob` and `/quitjob` clear the selection.
- City maintenance grants a spray-can item and changes graffiti-tag state. Job-marked vehicles temporarily reject a mismatched driver.
- `/fish` starts the client fishing minigame. Caught fish become item `273`; the fisherman NPC quotes and buys the inventory.
- Photography's client scoring loop and `/totalvalue` command are inside a block comment, and the old photographer NPC creation is commented out. The active `cPhotoOption` UI event has no caller in the source tree; if invoked, it reads `getElementDimension(victoria)` even though `victoria` is only declared in the commented block. The separate `/photoheli` flow remains active. The old player interaction gap is tracked in [Issue #495](https://github.com/itschase/OwlMTA-2026/issues/495); server-authoritative photo totals and payouts remain covered by [Issue #181](https://github.com/itschase/OwlMTA-2026/issues/181).
- Mechanics service vehicles, change tires, paint, colors and headlights, install upgrades, and preview appearance. Fixed prices are paid from character cash.
- Taxi drivers use `/taxilight`; the taximeter synchronizes displayed fare, distance, running state, and light state between driver and passengers. This module does not perform a final fare settlement.
- Bus drivers use `/startbus`, follow a client-rendered route, and receive a direct cash reward at reported stops. Passenger entry invokes a $5 fare transfer.
- Locksmiths use `/copykey [type] [id]` while holding the original key. The code charges $25 although its success message says $15.
- The former `/resetcontract` staff command is commented out. On-duty Trial Administrators have a mechanic UI exception. Job-vehicle entry also contains a legacy on-duty supporter bypass; donor/supporter status must not provide vehicle authority.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/job-system/meta.xml`](../../mods/deathmatch/resources/job-system/meta.xml)
- Selection and progression: [`s_job_system.lua`](../../mods/deathmatch/resources/job-system/s_job_system.lua) and [`s_job_framework.lua`](../../mods/deathmatch/resources/job-system/s_job_framework.lua)
- Fishing: [`fishing/s_fishing_job.lua`](../../mods/deathmatch/resources/job-system/fishing/s_fishing_job.lua)
- Photography: [`photographer/s_photographer_job.lua`](../../mods/deathmatch/resources/job-system/photographer/s_photographer_job.lua)
- Mechanics: [`mechanic/s_mechanic_job.lua`](../../mods/deathmatch/resources/job-system/mechanic/s_mechanic_job.lua) and [`mechanic/s_mechanic_previews.lua`](../../mods/deathmatch/resources/job-system/mechanic/s_mechanic_previews.lua)
- Taxi and meter: [`taxi/s_taxi_job.lua`](../../mods/deathmatch/resources/job-system/taxi/s_taxi_job.lua) and [`taximeter/s_taximeter.lua`](../../mods/deathmatch/resources/job-system/taximeter/s_taximeter.lua)
- Bus: [`bus/s_bus_job.lua`](../../mods/deathmatch/resources/job-system/bus/s_bus_job.lua)
- Locksmith: [`locksmith/s_locksmith_job.lua`](../../mods/deathmatch/resources/job-system/locksmith/s_locksmith_job.lua)
- Exports: server `fetchJobInfoForOnePlayer`; client/server `getJobTitleFromID`.
- Major dependencies: `mysql`, `global`, `item-system`, `anticheat`, `factions`, `integration`, `logs`, `vehicle`, `pool`, `hud`, `rightclick`, and `colorblender`. Their readiness and startup order are implicit.

## Source-confirmed risks

- The remote job-accept handler trusts event `source`, accepts an arbitrary job ID, and does not prove login, City Hall proximity, prerequisites, or a valid transition. Repeated city-maintenance selection can repeat its item side effect. This is tracked by [Issue #47](https://github.com/itschase/OwlMTA-2026/issues/47).
- Fishing events accept a caller-supplied player, allow catch replay without authoritative job, rod, location, timing, or minigame proof, and accept the sale price from the client. Photography accepts a client collection value, directly credits faction `20`, and exposes a remote arbitrary collection-value write. [Issue #181](https://github.com/itschase/OwlMTA-2026/issues/181) owns these reward paths.
- Bus payment validates only that the authenticated client is in the driver seat. Route, job, bus model, position, stop order, dwell time, and completion are not server-owned. Repeating a stop logs a warning but still pays; terminal values can also be replayed. The fare event trusts a caller-selected payer and recipient, ignores debit failure, and can create money. [Issue #77](https://github.com/itschase/OwlMTA-2026/issues/77) owns progression and fare binding.
- Mechanic mutation and preview events trust event `source` and an arbitrary vehicle. They do not prove the authenticated actor, mechanic job or named capability, proximity, ownership/customer consent, or service context. Several paths charge before validating a successful mutation, and item, cash, save, and rollback outcomes are ignored.
- The taximeter accepts client distance, fare, position and running state. A client-supplied bypass flag can skip the controller check. `/taxilight` has an operator-precedence error that permits unintended model-420 occupants.
- Locksmith invalid key types leave shared globals nil or stale. Item grant success is ignored before charging, and duplication policy is reduced to possession of a matching key.
- Progress-row creation is a non-atomic select/insert with no uniqueness constraint. Job rewards, inventory changes, progression and logs have no common transaction, completion nonce, idempotency key, or restart reconciliation.
- Bus route and preview state are memory-only. A resource restart resets route anti-replay state and can leave a temporary vehicle preview applied until another restoration or vehicle reload.

## Tracked work and target direction

- [Issue #47](https://github.com/itschase/OwlMTA-2026/issues/47): authoritative job selection and transition validation.
- [Issue #77](https://github.com/itschase/OwlMTA-2026/issues/77): server-owned bus progression and bound fare transfer.
- [Issue #181](https://github.com/itschase/OwlMTA-2026/issues/181): server-owned fishing and photography work and rewards, including arbitrary client photo totals and faction payout values.
- [Issue #495](https://github.com/itschase/OwlMTA-2026/issues/495): restore or retire the disconnected photographer interaction flow without conflating the SAN front desk.
- [Issue #48](https://github.com/itschase/OwlMTA-2026/issues/48) remains the payday/shop-wage event parent; it does not own these direct job payouts.
- [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3) owns replacement of legacy staff/supporter bypasses with named capabilities.
- [Issue #241](https://github.com/itschase/OwlMTA-2026/issues/241) owns mechanic, taxi/taximeter, and locksmith authorization and failure-safe settlement.

The published follow-up should bind mechanic, taximeter, and locksmith actions to the authenticated actor and authoritative vehicle/work context, bound all values, and make payment and fulfillment compensating or atomic. This proposal is source-backed but is not yet a runtime-verified fix.

The target is a versioned job registry and durable server `JobSession` containing character, job, vehicle/tool, route or work state, timestamps, and a one-use completion nonce. Server checkpoints derive rewards; a ledger settles them idempotently; item and progression changes reconcile after failure or restart. Mechanic work should use a customer-approved work order and authoritative quote.

Runtime verification must cover job-ID and proximity tampering, repeated selection and cleanup, duplicate progression rows, fishing and photography replay/value spoofing, every bus route/order/dwell/fare boundary, mechanic actor/vehicle/value/payment/save failures, taximeter controller and range checks, locksmith inventory failure, disconnects, and resource/server restart during every active job.
