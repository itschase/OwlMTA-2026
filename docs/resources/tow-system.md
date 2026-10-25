# `tow-system`

## Status

- Tree/startup state: active resource tree; live startup unverified.
- Evidence: full review of every manifest-loaded script, relevant schema, and representative callers.
- Runtime: unverified. The server has not been started for this rebuild.
- Discussion: [Script Resource: tow-system](https://github.com/itschase/OwlMTA-2026/discussions/250).

## What it does

`tow-system` combines conventional Roadside Towing & Recovery behavior, player tow requests, vehicle impound and release, law-enforcement impound lanes, impound reports, tow statistics, and the inactivity sale invoked by payday. It changes both live vehicle state and durable position/impound records.

This is currently two overlapping impound models. The conventional faction-`4` lot uses fixed colshapes and a fixed $1,000 release. The newer LEO path assigns a vehicle to a row in `leo_impound_lot`, records a client-described fine and release date, and projects a free-text report into `mdc_impounds`.

## Player, staff, and operator use

- A player uses `/towtruck` to toggle the single global request beacon sent to faction `4`. A Trial Administrator or eligible faction leader uses `/resettowbackup`.
- Faction-`4` tow drivers bring an attached vehicle into fixed lot colshapes. The resource marks it impounded, disables its engine, adds notice item `72`, writes `towstats`, and notifies its owner. Eligible members use `/impoundbike` for motorcycles and bicycles.
- The conventional release NPC lists loaded impounded vehicles owned by the character or their faction. The current `releaseCar` source is hardened to bind MTA `client`, require lot proximity, verify ownership or faction membership, require impounder `4`, and charge a server-fixed $1,000. This is fixed in source but remains runtime unverified.
- The LEO interface selects LSPD (`1`), SCoSA (`50`), or RT (`4`), finds a booth vehicle and a free lane, and collects the duration, fine and narrative report. Release uses a department NPC, storage/fine display, release date, cash payment, faction credit, and vehicle relocation.
- `/unimpound` is a Trial Administrator command. `/fixlanes`, `/scripterCreateLot`, and `/rtMoveImpoundsToNewLot` use legacy scripter predicates.
- Payday calls the exported `clearImpound`, which attempts to delete vehicles whose day-of-year impound marker appears older than 14 days and credits their estimated value to faction `4`.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/tow-system/meta.xml`](../../mods/deathmatch/resources/tow-system/meta.xml)
- Conventional towing/release: [`s_tow.lua`](../../mods/deathmatch/resources/tow-system/s_tow.lua)
- Tow beacon: [`s_backup.lua`](../../mods/deathmatch/resources/tow-system/s_backup.lua)
- Cleanup/sale: [`clear_impound.lua`](../../mods/deathmatch/resources/tow-system/clear_impound.lua)
- LEO lanes, impound and release: [`leo-impound/impound_s.lua`](../../mods/deathmatch/resources/tow-system/leo-impound/impound_s.lua)
- Exports: `CanTowTruckDriverVehPos`, `CanTowTruckDriverGetPaid`, `cannotVehpos`, `clearImpound`, and `getImpoundLanes`.
- Commands: `/towtruck`, `/resettowbackup`, `/impoundbike`, `/unimpound`, `/fixlanes`, `/scripterCreateLot`, `/rtMoveImpoundsToNewLot`.
- Persistence: `vehicles` impound/position state, MyISAM `leo_impound_lot`, `mdc_impounds`, `towstats`, and `wiretransfers`, plus live protected vehicle state and an in-memory request beacon.
- Major dependencies: `mysql`, `vehicle`, `vehicle_manager`, `pool`, `factions`, `global`, `bank`, `anticheat`, `cache`, `announcement`, `logs`, `datetime`, `carshop-system`, and the item system.

## Source-confirmed risks

- LEO open, commit, release, direct unimpound, and NPC speech events use caller-selected event `source` rather than binding the authenticated `client`. Commit does not recheck badge, faction membership, current faction duty, rank or a named impound capability.
- The client chooses department, duration, fine, officer identity, badge/rank, vehicle display fields, violations, location, narrative, release NPC, vehicle ID, and release cost. Duration and fine are insufficiently bounded and are concatenated into SQL. Release does not rederive ownership, correct impounder/NPC, proximity, wait/seizure rule, or cost.
- A lane is read as free before the vehicle is moved. The later conditional lane update ignores affected rows, so concurrent operations can move multiple vehicles toward one lane or leave vehicle and lane state inconsistent.
- Impound and release span live flags, engine/handbrake, notice item, vehicle position, lane, report, notification, logs, cash debit, faction credit, bank journal, and lane clearing. Results are mostly ignored and there is no transaction, idempotency key, compensation, or startup reconciliation.
- The towing-notice expression has concatenation/comparison precedence that prevents the intended complete notice text from being stored.
- Impounder identifiers disagree: one administrative path accepts `1`, `59`, or `4`, while the shared release helper accepts `1`, `50`, or `4`.
- The lane-repair startup/timer is commented out, and its memory assumptions are not established by active startup. Orphaned lanes therefore do not automatically converge.
- Cleanup compares day-of-year integers. It fails across year rollover, does not distinguish seized vehicles or impounding factions, sums value before confirming deletion, ignores deletion outcome, credits all proceeds to faction `4`, and does not explicitly reconcile lane or MDC state.
- Conventional checks mix raw `faction` element data with faction APIs and do not consistently require active duty or an action-specific towing permission. Trailer-detach payment and `towstats` are not one durable, replay-safe tow job.
- The global beacon is memory-only, has no durable request lifecycle or rate limit, and broadcasts to faction members without an explicit duty policy.

## Fixed-in-source and unverified behavior

The conventional `releaseCar` handler now derives the player from `client`, validates the selected loaded vehicle, checks lot proximity, verifies character ownership or faction membership, requires the conventional impounder, and uses a fixed server-side price. That correction must not be generalized to the separate LEO release path, which still has the source-confirmed boundaries above. Neither path has been runtime tested in this rebuild.

## Tracked work and target direction

- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) is the parent remote-event authorization audit.
- [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3) owns migration from legacy administrator/scripter predicates to named capabilities.
- [Issue #6](https://github.com/itschase/OwlMTA-2026/issues/6) owns schema-engine and transaction modernization.
- [Issue #149](https://github.com/itschase/OwlMTA-2026/issues/149) owns typed financial account identities.
- [Issue #180](https://github.com/itschase/OwlMTA-2026/issues/180) owns the server-only payday maintenance trigger, not tow cleanup correctness.
- [Issue #189](https://github.com/itschase/OwlMTA-2026/issues/189) is relevant to replacing free-text justice records, but does not authorize or settle an impound.
- Vehicle Issues [#91](https://github.com/itschase/OwlMTA-2026/issues/91)-[#93](https://github.com/itschase/OwlMTA-2026/issues/93) cover separate lock, engine, and parking request boundaries.
- [Issue #242](https://github.com/itschase/OwlMTA-2026/issues/242) owns authoritative actor, capability, proximity, vehicle, impound-state, and release-price validation.
- [Issue #243](https://github.com/itschase/OwlMTA-2026/issues/243) owns atomic and reconcilable lane, vehicle, fee, cleanup, and sale state.

Published follow-up work binds the implementation target for every LEO tow/impound/release event and makes lane, vehicle, report, fee, release, and cleanup state recoverable. These are source-backed proposals, not completed fixes or runtime-verified behavior.

The target is a typed `ImpoundCase` with authenticated actor, organization and duty/capability evidence, vehicle, reason/evidence, fine/storage policy, seizure or release time, lane, and audited state transitions. Lane reservation and vehicle persistence should be atomic or use a durable outbox; release payment should be server-priced and idempotent; startup should reconcile vehicle, lane and case state. MDC should consume a structured projection rather than own the free-text transaction.

Runtime verification must cover every faction/rank/duty/capability and badge combination; forged sources, departments, NPCs, fields and direct events; booth and lane concurrency; duration/fine bounds; conventional tow chains and bikes; owner/faction/other and loaded/unloaded release; every injected persistence/payment failure; restart during impound/release; orphaned lanes; year rollover and retention policy; deletion/proceeds failure; tow-payment replay; and beacon quit/restart behavior.
