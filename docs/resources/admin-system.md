# `admin-system`

## Status

- Tree/startup state: active and present in the tracked startup snapshot; live startup unverified.
- Evidence: server-focused review of all 23 manifest-loaded server scripts; client presentation review remains partial.
- Runtime: unverified.

## What it does

`admin-system` is the central privileged toolbox for player correction/control, inventory and economy grants, punishment/history, character/account recovery, identity/progression edits, teleportation/observation, staff management, feedback, resource/ACL controls, and server configuration actions.

The full domain map is maintained in [Administration System: Current State](../architecture/ADMINISTRATION_CURRENT_STATE.md) and [Staff & Admin Discussion #173](https://github.com/itschase/OwlMTA-2026/discussions/173).

## Staff and operator experience

The command surface includes health/armor/skin/name/state correction, weapon/item/money/GameCoin creation, punishment and history, character reset/recovery, teleport/recon/supervision, staff roster/rank changes, resource start/stop/restart, ACL reload, and server password management. Legacy authority combines several administrator tiers, GameMaster/supporter, scripter, vehicle, mapping, and faction-management teams.

These actions must migrate individually to named capabilities. Supporter/donor status alone must grant no administrative authority.

## Technical map

- Manifest: [`mods/deathmatch/resources/admin-system/meta.xml`](../../mods/deathmatch/resources/admin-system/meta.xml)
- Major dependencies include `mysql`, `global`, `integration`, `anticheat`, `logs`, `pool`, `cache`, `item-system`, `weapon`, `bank`, `factions`, `bans`, `donators`, `announcement`, `hud`, `freecam`, `achievement`, `npc`, `realism`, `report`, and `prison-system`.
- State spans core/MTA tables, live element data, in-memory teleport/recon/timer state, staff changelogs, history, feedback, and external legacy records.
- Exported `addAdminHistory` is HTTP-callable and requires explicit ACL/exposure review.

## Known risks and work

- [#164](https://github.com/itschase/OwlMTA-2026/issues/164): bind remotely triggered privileged mutations to authenticated `client`.
- [#165](https://github.com/itschase/OwlMTA-2026/issues/165): authorize and make history removal consistent and auditable.
- [#166](https://github.com/itschase/OwlMTA-2026/issues/166): minimize and capability-scope sensitive administrative data.
- [#167](https://github.com/itschase/OwlMTA-2026/issues/167): validate feedback and bind attribution.
- [#168](https://github.com/itschase/OwlMTA-2026/issues/168): remove recovery-secret display and plaintext password broadcast.
- [#169](https://github.com/itschase/OwlMTA-2026/issues/169): make staff-rank and destructive reset workflows failure-safe.
- [#170](https://github.com/itschase/OwlMTA-2026/issues/170): restore recon/observation state across lifecycle changes.

Runtime verification must directly invoke every remote event without its UI, exercise all capabilities/hierarchy/targets, verify privacy redaction and audit, inject failure across destructive operations, restart during recon/timers/callbacks, remove dependencies, and prove no secret reaches chat, logs, API, or notification output.
