# `license-system` resource

**Review state:** Full manifest, client/server flow, staff manager, and direct entry-point review. Source behavior is documented; exam, payment, persistence, and GUI behavior remain runtime-unverified.

## What players do

Players approach licensing NPCs and use an interaction GUI. Depending on license type, the flow includes a knowledge quiz, driving checkpoints, or a fee for issuance/recovery. The resource covers car, motorcycle, boat, fishing, and firearm licenses. `/showlicenses` displays a nearby player's firearm-license information; the client-side interaction is more prominent than command use for ordinary licensing.

The client quiz and checkpoint are presentation/interaction flows. They are not proof to the server that the player completed an exam. A future dashboard or contextual interaction may make license status and renewal clearer, but issuance must remain a server-owned operation tied to a validated exam or authorized staff action.

## Staff and operator use

`/weaponlicenses` opens a staff gun-license manager. Source checks include lead-admin and faction/item permission paths. The UI has a narrower Tier 2 eligibility rule than the server mutation handlers currently enforce; track this separately in [Issue #395](https://github.com/itschase/OwlMTA-2026/issues/395). `gunlicense:synctable` is also remotely callable and accepts a client-provided table into shared element data without binding it to an authorized requester.

Operators should confirm the license-related character fields and inventory item definitions in the imported schema and item catalog before enabling the resource. License state is stored on character records (including car, bike, boat, fishing, and firearm flags); firearm manager history is handled separately through the resource's persistence functions. Exact schema migration and transaction guarantees have not been runtime-verified.

## Current server boundaries and issues

- **Exam and issuance:** Server events expose theory completion and license grants for multiple license types. The client performs quiz/checkpoint logic, but the server does not validate a server-owned exam session or completion record before updating license state. Client-supplied `skipSQL` and `usingGC` values influence persistence/charge branches. See [Issue #393](https://github.com/itschase/OwlMTA-2026/issues/393).
- **Fees and recovery:** `license:recover` accepts client-provided license label, price, item ID, and NPC name. `payFee` accepts amount/reason and uses event `source` for payment rather than binding the actor to the server-provided `client`. See [Issue #394](https://github.com/itschase/OwlMTA-2026/issues/394).
- **Gun-license staff tools:** The server must enforce the same tier-specific eligibility as the staff UI and must validate/authorize the `gunlicense:synctable` event before changing shared state. See [Issue #395](https://github.com/itschase/OwlMTA-2026/issues/395).

These are source-confirmed trust-boundary gaps, not claims of tested abuse. The current player license system is ordinary gameplay eligibility and must not depend on Discord staff roles or supporter levels. If Discord capabilities are later integrated, only an external staff grant may supplement existing local in-game permissions for administrative gun-license actions. It cannot replace faction, item, target, actor, or state checks.

## Connected resources and future interface

The resource connects NPC/right-click interaction, client quiz and checkpoint UI, character persistence, inventory items, money/GC settlement, faction permissions, and the staff gun-license manager. Keep these boundaries explicit when documenting the schema: account identity selects the active character, while license ownership and issuance belong to that character.

A future player dashboard can show license types, eligibility, expiry/renewal (if added), and required next steps. Staff views can search and review issuance history. Both should call the same server domain operations used by current flows. Commands remain available during migration; no command should be the only way to discover an essential player or operator operation.

## Runtime verification

On a disposable server and database, verify each exam flow, invalid and skipped exam events, every license fee/GC path, recovery item ownership, character switching, staff tiers, unauthorized table sync, persistence failures, reconnects, and partial transaction behavior. No server or tests were run for this source review.

## MTA reference

- [MTA Script security](https://wiki.multitheftauto.com/wiki/Script_security) explains that remote event parameters and `source` can be client-controlled, while server-side `client` identifies the remote caller.
- [MTA `triggerServerEvent`](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) documents the client-to-server event boundary.
