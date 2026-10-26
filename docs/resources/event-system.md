# `event-system`

## Status

- Active manifest loads basketball, paintball, golf, and ice-skating scripts; several BMX/skate/Easter modules are commented out and treated as dormant.
- Full active workflow and direct caller audit completed from source.
- A nested comment inside an XML comment appears in `meta.xml`; standard XML well-formedness is in question and MTA parser acceptance is runtime-unverified.
- Backup server config lists `event-system` twice and starts the snow resource later; this is only a tracked startup snapshot.
- No MTA server or tests were run.
- [Discussion #305](https://github.com/itschase/OwlMTA-2026/discussions/305).

## Player workflows

### Basketball

Players request to pick up nearby court balls, then pass, shoot, drop, dunk, or retrieve them. Balls/courts are recreated on resource start. The server stores a `heldby` state, but `basketball:status` accepts caller-provided fake client/source values and does not verify a registered ball, proximity, or existing ownership. Client held-ball state is shadowed by a local parameter, allowing repeated pickup requests. One boundary helper calls `setElementInterior` twice where the second operation appears intended to assign dimension; a rotation condition is impossible.

### Paintball

Players join a $50 entry lobby, receive the less-populated team, choose a loadout, ready up, and are moved to the arena after four participants are ready. The client reports damage, the server tracks HP, and the last team standing ends/restores the match. Leaderboard and raised-money values are handed through the `data` resource on a coordinated resource restart; feedback is stored in XML. Staff commands can list markers, reset leaderboard, or replace a lobby.

Current server remotes use event `source` instead of authenticated `client` for join/exit/ready/damage/feedback/read. Loadout accepts client-selected weapons/ammo/skin. Damage accepts client-selected attacker, victim, weapon, body part, and loss without verifying a server-observed shot or same opposing active match. Feedback read authorization is client-side; writes trust username/text. Several state cleanup paths can leave a lobby stuck, create multiple start timers, or replace a lobby while players remain in the arena.

### Golf

Players activate golf item 115 subtype 2 or `/golf`, spawn a ball, choose a club, and submit a trajectory. The server trusts client-selected player, ball, coordinates, club, force, and direction, and does not maintain exclusive ball ownership. No persistent round/stroke/score system exists. Source also contains a duplicate `/resetgolf` registration, dead weather conditions, and a quit handler attached to a questionable element.

### Ice skating

Starting `shader_snow_ground` triggers `events:skating`, which creates a Glen Park ice colshape. Entrants with item 274 receive forced walk style 138. Initialization is not idempotent or recoverable if the one-shot event is missed; hit/leave handlers do not fully scope element type, dimension, or ownership of forced movement state.

## Staff, operator, and integration map

Staff: `/paintballmarkers` (scripter), `/resetleaderboard` and `/resetlobby` (scripter or lead admin). Ordinary basketball, golf, and skating have no staff control panel. Paintball ped entry depends on externally created/configured peds. `shader_snow_ground` is an event-system caller. Other dependencies/callers include data, global, integration, anticheat, cache, weapon, realism, ped-system, item-system, account assets, ES, PD, and bone_attach. Most data is memory/element data; process restart does not guarantee recovery. Paintball feedback XML is file-backed, while leaderboard/money only survive a coordinated `data` resource handoff.

## Source-confirmed risks and tracker

1. **Paintball match authority:** spoofable actor/source, client loadout/damage, exposed feedback reads, unbounded feedback writes, duplicate timers, abandoned match/quit/reset cleanup, and weak persistence. Tracked in [Issue #296](https://github.com/itschase/OwlMTA-2026/issues/296), under general event parent [#1](https://github.com/itschase/OwlMTA-2026/issues/1). Entry money durability also links to [#209](https://github.com/itschase/OwlMTA-2026/issues/209).
2. **Basketball and golf object/session authority:** forged actor/ball/player/coordinates, no one-ball/session constraints, and unsafe lifecycle. Tracked in [Issue #297](https://github.com/itschase/OwlMTA-2026/issues/297).
3. **Skating init and manifest/startup:** validate XML manifest and make `events:skating` idempotent/order-independent; constrain same-dimension player cleanup. Tracked in [Issue #298](https://github.com/itschase/OwlMTA-2026/issues/298). Duplicate startup/dependency graph remains existing [Issue #21](https://github.com/itschase/OwlMTA-2026/issues/21).
4. **Protected element data:** `paintball:*`, `golf:ball`, and basketball `heldby` are part of existing [Issue #74](https://github.com/itschase/OwlMTA-2026/issues/74); correct element-data flags do not replace server authorization.

## Modernization direction

Use one durable server-owned match/session aggregate for each competitive event, with legal transitions, authoritative team/loadout/damage scoring, idempotent entry/fee/refund, and an explicit recovery path. Give basketball and golf independent object ownership sessions with bounds and one-ball-per-player rules. Make seasonal map state a configured provider that can initialize repeatedly and across restarts. Distinguish temporary event stats from durable player history; do not imply persistence that only exists during a resource handoff.

## Runtime verification still required

After safe-start, test direct/faked event source and caller arguments; team/lobby/loadout/damage replay; quit/exit/death/reset/restart in each match state; simultaneous basketball pickups; foreign/remote golf balls and trajectory bounds; malformed manifest handling; snow/event start order; duplicate skating initialization; dimension changes; and failure of the `data` handoff. None was run.
