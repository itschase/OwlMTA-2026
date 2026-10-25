# `insurance`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded script, schema, exported API, and representative payday, Pay'n'Spray, vehicle, vehicle-manager, and DMV callers.
- Runtime: unverified. The server has not been started.
- Discussion: [Script Resource: insurance](https://github.com/itschase/OwlMTA-2026/discussions/248).

## What it does

`insurance` is the legacy vehicle-policy interface. A player on duty in a faction configured in `insurance_factions` can open `/insurance`, view company text and statistics, quote a loaded vehicle, offer a policy to an online player, list policies associated with the current insurer, and request cancellation. Some editing and access-grant controls are visibly unfinished.

The intended purchase flow is salesperson quote, customer confirmation, and policy insertion. Payday later obtains policy fees through the exported analyzer, while Pay'n'Spray reports repair claims. Current source does not charge money when a policy is accepted, does not persist a balanced insurer/customer transaction, and does not bind the confirmation to a server-owned quote.

## Player, staff, and operator experience

- `/insurance` opens only when the current faction duty has an insurance-company row.
- Faction leaders see client controls for company news, subscription text, and the premium multiplier. This client check is not an authoritative server boundary.
- Salespeople enter a VIN and premium, resolve an online owner by displayed character name, and prompt that player to accept or refuse.
- The management view lists policies and offers cancellation. Vehicleplate, vehicle deletion, and vehicle-manager paths also call insurance cancellation.
- Operators must seed and maintain insurance factions and policy tables. There is no repair/reconciliation command, migration, or documented claims-settlement operator flow.

## Technical map

- Manifest: [`mods/deathmatch/resources/insurance/meta.xml`](../../mods/deathmatch/resources/insurance/meta.xml)
- Server: [`s_main.lua`](../../mods/deathmatch/resources/insurance/s_main.lua)
- Client: [`c_main.lua`](../../mods/deathmatch/resources/insurance/c_main.lua)
- Command: `/insurance`.
- Server exports: `analyzeInsurance`, `getVehicleInsuranceData`, and `cancelPolicy`.
- Remote server events: `insurance:sql`, `insurance:sellinfo`, `insurance:calculate`, `insurance:sell`, `insurance:outputchatbox`, `insurance:finalpurchase`, `insurance:cancel`, and `insurance:claims`.
- Persistence: `insurance_factions` and `insurance_data`; live vehicle insurance element data; global server caches keyed by faction and vehicle.
- Dependencies: `mysql`, `factions`, `pool`, `cache`, `anticheat`, `payday`, `paynspray-system`, `vehicle`, `vehicle_manager`, and `vehicleplate`.

## Source-confirmed risks

- All mutation events are remotely callable without authoritative actor, active-duty capability, target ownership, proximity, or workflow validation. `insurance:sql` accepts a client-supplied column name and faction ID.
- Policy creation trusts client-supplied salesperson, customer, VIN, protection, premium, and insurer. It does not bind `client` to the confirming customer, rederive vehicle ownership or price, require the salesperson's duty/capability, prevent duplicates, debit funds, or validate database insertion before reporting success.
- Any client can request cancellation of any cached vehicle policy. Database/cache state is removed before a loaded vehicle update is proven, so failure can split persistence, cache, and live element data.
- The remotely enabled claims event accepts arbitrary vehicle IDs and unbounded positive or negative amounts even though its intended caller is the server-side Pay'n'Spray path.
- Opening the UI sends the complete global policy and insurer caches to the client. Presentation filters rows locally, exposing other insurers' customer names, vehicle IDs, premiums, claims, and cashout state.
- Quote and sale-info events disclose arbitrary loaded vehicle owner, plate, model, and value without a server-side insurer permission check.
- Payday analysis mutates cached cashout totals as a side effect. Retry can double-count, and persistence occurs only every five hours or on orderly resource stop. A crash loses recent accounting, external database changes can be overwritten, and the failure log references an undefined variable.
- Policy rows identify customers by mutable display name rather than stable character/account ownership. No source-enforced unique vehicle policy or referential-integrity boundary was found.
- The vehicle-ID formatter appends its accumulated string instead of the vehicle ID, producing broken transaction descriptions.

## Tracked work and target direction

- [Issue #15](https://github.com/itschase/OwlMTA-2026/issues/15) owns insurance/inventory event ownership, including actor, target, read, and organization boundaries.
- [Issue #45](https://github.com/itschase/OwlMTA-2026/issues/45) owns insurance payment and claim validation, including server-derived quotes, confirmation, settlement, cancellation, and replay protection.
- [Issue #240](https://github.com/itschase/OwlMTA-2026/issues/240) owns durable premium accounting, idempotent settlement, restart reconciliation, and the vehicle-ID formatter defect.

The target is proposed rather than current: a server-owned policy entity linked to stable customer, vehicle, and insurer-organization IDs; typed coverage/rates; one-use expiring quotes; explicit owner consent; authoritative price and balance checks; effective, expired, cancelled, and superseded states; append-only premium and claim entries; atomic or idempotent payday/repair settlement; privacy-scoped reads; immutable audit; and operator reconciliation. Cache must be a rebuildable projection rather than the only recent accounting state.

Runtime verification must cover civilian, owner, non-owner, insurer member/leader, off-duty, wrong-insurer, staff, and operator roles; direct and forged events; loaded/unloaded, personal/faction, transferred, deleted, and duplicate-policy vehicles; quote expiry/replay and disconnects; accept/refuse with insufficient, exact, and changed funds; failure at every database and ledger step; cancellation from every caller; negative, zero, excessive, duplicate, and rolled-back claims; repeated payday and crash/restart; multi-vehicle and multi-insurer settlement; cache/database drift; privacy field scope; and every dependency stopping or restarting.
