# Administration System: Current State

## Status

Server-focused source review of all 23 manifest-loaded `admin-system` server scripts, with client callers traced for remote boundaries. Client presentation is not yet a complete line-by-line review. Runtime is unverified.

## Scope

`admin-system` is a broad privileged toolbox covering player state, inventory/economy grants, punishment and history, character/account recovery, identity/progression edits, teleportation and observation, staff management, feedback, resource control, server password, and legacy recovery helpers.

It depends on `mysql`, `global`, `integration`, `anticheat`, `logs`, `pool`, `cache`, `item-system`, `weapon`, `bank`, `factions`, `bans`, `donators`, `announcement`, `hud`, `freecam`, `achievement`, `npc`, `realism`, `report`, and `prison-system`.

## Main administrative domains

- Player correction and control: unmask/unblindfold/uncuff, mute, disarm, health/armor/skin/name, freeze, eject, reconnect, kick, and recovery.
- High-value creation/mutation: weapons, ammunition, items, cargo, money, keys, and GameCoins.
- Enforcement/history: punishment points, admin history, jail, character kill/recovery, check/monitor, feedback, and staff records.
- Identity/progression: demographic fields, languages, marriage, licenses, limits, and application state.
- Movement/observation: teleport locations, goto/gethere/send, interior/dimension, recon/disappear/supervise.
- Operator actions: resource state/restart, ACL reload, gatekeeper restart, development mode, and server password.
- Staff manager: roster, role edits, specialty teams, changelog, notifications, and linked cleanup.

Legacy checks mix administrator tiers, GameMaster/supporter, scripter, vehicle, mapping, and faction-management teams. These must become action-specific capabilities; donor tier must grant none.

## Highest-priority findings

- Several remote events reuse command handlers and authorize a player element supplied in the payload rather than MTA server `client`. This can expose weapon creation, inventory mutation, freeze, duty, and information paths; tracked by [Issue #164](https://github.com/itschase/OwlMTA-2026/issues/164).
- Admin-history removal lacks a server authorization boundary and spans record deletion plus warning/punishment counters; [Issue #165](https://github.com/itschase/OwlMTA-2026/issues/165).
- Check/history/inventory/monitor/feedback paths expose sensitive account, IP, finance, notes, punishment, and inventory data through broad or forgeable checks; [Issue #166](https://github.com/itschase/OwlMTA-2026/issues/166).
- Feedback attribution, rating, content, SQL, duplication, and read authorization need hardening; [Issue #167](https://github.com/itschase/OwlMTA-2026/issues/167).
- A command reveals a stored forum 2FA recovery secret and server-password changes broadcast the plaintext password; [Issue #168](https://github.com/itschase/OwlMTA-2026/issues/168).
- Staff-rank changes and destructive character reset span non-atomic database/live-state side effects; [Issue #169](https://github.com/itschase/OwlMTA-2026/issues/169).
- Recon return and visibility/collision state are memory-only and lack complete stop/restart/disconnect recovery; [Issue #170](https://github.com/itschase/OwlMTA-2026/issues/170).

## Target administration model

- Central command/action registry with descriptions, examples, named capabilities, hierarchy, duty/context, target policy, audit category, and dashboard action
- Server-derived actor for every remote path and execution-time reauthorization for timers/callbacks
- Focused domain dashboards rather than one omnipotent panel
- Field-minimized privacy views with explicit investigation purpose and access audit
- Immutable correction history, idempotent destructive workflows, dry-run/preflight, repair queues, and rollback
- Secrets managed through reset/rotation flows that never disclose stored material
- Structured audit results for success, denial, partial failure, compensation, and recovery

## Later runtime gate

Exercise every remote without its UI; forged actor/source; all legacy roles and new capabilities; target hierarchy; invalid/stale/destroyed targets; replay/rate burst; privacy redaction; history deletion concurrency; destructive failure injection; resource restart during recon/timers/callbacks; dependency outages; resource-control allowlists; and proof that no secret reaches chat/log/API output.

Related: staff control center Discussion #106, Issues #1, #3, #24, and #164-#170.
