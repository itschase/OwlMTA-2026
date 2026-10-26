# `es-system`

## Status

- Active resource with six server and five client scripts in the manifest; `/carry`/consent code in `s_drag.lua` is fully commented out.
- Full manifest, client caller, direct integration, money, inventory, and persistence audit completed from source.
- Backup startup configuration is evidence of intended ordering, not proof of deployment.
- No MTA server or database was started; runtime behavior is unverified.
- [Discussion #303](https://github.com/itschase/OwlMTA-2026/discussions/303).

## Gameplay and staff workflows

### Death, respawn, and weapon legality

On death, the resource handles jail cases or offers an ordinary respawn flow. Accepting death records the event, removes selected drug items, checks weapon/ammo items against character gun-license fields, faction type, and `weapon:isWeaponCCWP`, then rebuilds live weapons and respawns at a hard-coded hospital location. The server also maintains a short in-memory kill log shown through `/showkills` to trial admins.

The client can choose a `victimDropItem` flag when accepting death. `item-system:dropItemOnDead` is currently an empty function, so the flag can bypass the weapon seizure branch without a real drop. The source-3 CCW check recognizes licensed stock but does not verify that the current holder matches the serial creator/license holder; the neighboring `canRetrieve` path does.

### Injury and medical service

Damage handlers track injury in memory, apply health/control effects, and clear restrictions on spawn/quit. Type-4 faction members can `/examine` a nearby player and `/heal` within range using a first-aid item; healing charges the target and credits a hard-coded faction. Type-4 members can `/prescribe` item 132 for themselves. Trial admins can `/revive` and `/fakeinjury`.

`/recovery` places a target in medical detention by debiting bank funds, crediting faction 2, writing recovery fields, and freezing the target. It has no duty, proximity, hospital, target-state, or named action-capability checks in its source path; payment results and DB operations are not treated as one settlement. `/assist` is the related action that explicitly checks duty and broadcasts a beacon to on-duty faction-2 members.

### Medical bills and dispatch

On-duty faction 164 can use `/bill`. The client presents cash, bank, insurance, or refusal choices; the server-side payment event accepts doctor, faction, amount, insurance, and action from the client rather than consuming a server-created pending bill. The source permits a zero-payment result to pass through and credits the caller-selected faction, creating a faction-balance/wire-history integrity risk.

Stretcher interactions originate from social, ped, object, and vehicle right-click UI. The server stores stretcher state in memory and attaches/warps patients. Counter-ped events produce hospital radio/PA messages; current server handlers trust client-supplied ped name, option, chat/text, and do not establish the legitimate ped or proximity. The hospital greeting also emits an airport event/text path by mistake.

## Persistence and dependencies

Persistent fields include character gun-license flags and medical recovery fields. Bank/faction settlement and inventory deletion are cross-resource operations. Injuries, stretchers, assists, the death-view timer, and kill log are memory/runtime state. Dependencies include `mysql`, `global`, `factions`, `prison-system`, `logs`, `anticheat`, `item-system`, `weapon`, `integration`, `bank`, `pool`, and `chat-system`; related callers include account spawn/save, object fall protection, social/ped/object/vehicle interaction, and computer assets. No readiness contract or declared manifest dependency graph exists.

## Source-confirmed implementation risks

1. **Medical bill settlement trusts mutable client fields.** `payMedicalBill` accepts client doctor/faction/amount/insurance/action without a pending bill token, then independently charges and credits. The source path can credit an arbitrary positive amount to a selected faction when the client reports matching insurance and charge amounts. This needs a one-use server-owned bill aggregate and idempotent ledger settlement.
2. **Death seizure can be skipped.** `acceptDeath` trusts a client-selected drop flag. The drop helper is empty, so the bypass avoids deletion without actually creating a world item.
3. **Licensed gun ownership is not tied to the current holder in one CCW check.** The source-3 CCW helper ignores the player argument while retrieval checks the encoded holder.
4. **Recovery payment, custody, and persistence can disagree.** The command omits state/location/duty checks, forces a debit without checking success, credits the hospital faction separately, then writes recovery and freezes the target. DB failure can leave conflicting money/custody state.
5. **Fall protection accepts client-supplied coordinates.** A remote caller can request a teleport/revive without a server-owned entrance/session, and the handler refers to an undefined `targetPlayer`. This exact object-system boundary is tracked by [Issue #260](https://github.com/itschase/OwlMTA-2026/issues/260), not duplicated.
6. **`doHeadHit` accepts arbitrary targets.** Its remote event changes target health/animation without binding caller or damage event. No legitimate caller was found.
7. **Stretcher lifecycle remotes accept target/vehicle/coordinates and actor fields from clients.** They omit medic duty, same-world distance, patient consent/incapacity, ambulance ownership/model/access, and lifecycle checks. Social physical-action authority is already tracked in [Issue #132](https://github.com/itschase/OwlMTA-2026/issues/132); update that owner with the stretcher path.
8. **Injury restart/validation risks.** A resource restart can discard injury state without restoring controls. `/heal` converts price to a number but later compares it without handling `nil`.
9. **Dispatch remotes impersonate hospital staff and spam.** Client-provided ped/option/text is not tied to a registered local hospital interaction or proximity.
10. **One global death-view timer couples separate players.** A second death can overwrite a pending timer; another player's acceptance/revive can kill it.

## Tracker ownership and planned work

Dedicated implementation issues are [#292 medical bill settlement](https://github.com/itschase/OwlMTA-2026/issues/292), [#293 death/seizure authority](https://github.com/itschase/OwlMTA-2026/issues/293), [#294 medical recovery custody](https://github.com/itschase/OwlMTA-2026/issues/294), [#295 injury/control recovery](https://github.com/itschase/OwlMTA-2026/issues/295), and [#296 hospital dispatch](https://github.com/itschase/OwlMTA-2026/issues/296). Shared ownership remains with [#1 remote-event audit](https://github.com/itschase/OwlMTA-2026/issues/1), [#3 staff/donor separation](https://github.com/itschase/OwlMTA-2026/issues/3), [#6 transaction foundations](https://github.com/itschase/OwlMTA-2026/issues/6), [#132 stretcher/social action authority](https://github.com/itschase/OwlMTA-2026/issues/132), [#149 faction balances](https://github.com/itschase/OwlMTA-2026/issues/149), [#153 evidence chain](https://github.com/itschase/OwlMTA-2026/issues/153), [#189 custody domain](https://github.com/itschase/OwlMTA-2026/issues/189), [#209 money ledger](https://github.com/itschase/OwlMTA-2026/issues/209), and [#260 object-system fall protection](https://github.com/itschase/OwlMTA-2026/issues/260).

## Modernization direction

Model death consequences, seizure evidence, medical billing, recovery custody, injury, and transport as separate server-owned workflows. Use explicit actor/target/session/state checks; settle payer, insurance, and faction credits atomically; give each bill and custody action an immutable ID and audit trail; make restart recovery deterministic. Reconcile who owns hospital/service organizations instead of carrying hard-coded faction IDs 2 and 164 forward. Discord roles may grant named staff capabilities only; faction membership/duty and donor status remain independent.

## Runtime verification still required

Verify every direct event with forged caller/source/target, bill replay/substitution and ledger failure, each death item-loss policy, source-3 weapon license holder edge cases, recovery with insufficient funds/off-duty/distance/DB failure/reconnect, injury restart and malformed price, stretcher lifecycle and vehicle/world checks, hospital dispatch spam, and concurrent player death timers in a disposable server. These checks were not run.
