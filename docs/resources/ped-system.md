# `ped-system`

## Status

- Tree state: active. Full manifest, five Lua scripts, database schema, direct event paths, and active-tree callers reviewed.
- Startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; snapshot only, not evidence of a live server.
- Source review: full manifest/script and workflow review; identified four implementation/security issues and one disconnected legacy event path.
- GitHub tracking: [Issue #469](https://github.com/itschase/OwlMTA-2026/issues/469) (remote staff action authorization), [#470](https://github.com/itschase/OwlMTA-2026/issues/470) (NPC treatment caller/target validation), [#471](https://github.com/itschase/OwlMTA-2026/issues/471) (final treatment kit actor), [#472](https://github.com/itschase/OwlMTA-2026/issues/472) (fake-name gender lookup), [#473](https://github.com/itschase/OwlMTA-2026/issues/473) (unhandled NPC-menu events), and [#474](https://github.com/itschase/OwlMTA-2026/issues/474) (public-transport provider contract). All are assigned to [Milestone #7: Resource Audit and Security Baseline](https://github.com/itschase/OwlMTA-2026/milestone/7).
- Discussion: [Script Resource: ped-system #475](https://github.com/itschase/OwlMTA-2026/discussions/475).
- Runtime: unverified. No MTA server/client was started.

## What it does in everyday terms

`ped-system` is the shared framework for persistent, named world pedestrians: service clerks, receptionists, mission contacts, job/event NPCs, and other human-like world characters. It loads saved NPC definitions from the `peds` database table, creates server peds with their appearance and behavior, exposes common name/skin helpers, and gives players context actions when they right-click a nearby NPC.

This is separate from the `npc` resource, which owns shop and business trading workflows. A ped may act as the visible interaction point for another system; the other resource still owns the actual application, price, inventory mutation, or service policy.

## Player guide

- Aim at and right-click an NPC to open actions selected by the NPC's `rpp.npc.type` value. The client requires a ped target and a click position within three world units before it constructs the menu; server handlers must still validate range, dimension, interior, identity, and state.
- The active interaction map includes city-hall reception, job board, business registration, politics, DMV/plates, bank/cards, ticket lookup, fuel/toll, impound, elections, hospital/emergency-services desk, prison arrival/release, airport/FAA, construction, cargo, pilot missions, locksmith, K9, paintball, BMX, Santa/event actions, and mission contacts.
- Those menu rows dispatch events to their owning resources. Opening a menu does not establish that the downstream service is available or that its server handler is safe; follow the caller into the resource that processes the action.
- When an eligible emergency-services member right-clicks a sufficiently injured NPC, the client offers `Heal`. The server treatment path uses a first-aid kit, may restore an NPC, posts local roleplay text, credits service/government accounts, and writes a database log. Its remote actor/target boundary and final-kit branch are under review in Issues #470 and #471.
- The resource itself does not add a general-player command for talking to NPCs.

## Staff and operator guide

| Command or control | Source behavior |
|---|---|
| `/ped [behavior] [gender] [skin] [name]` | Trial-admin-only temporary NPC at the caller's position. Defaults to behavior 1, random gender/skin/name where omitted, and records a spawn position for respawn. |
| `/makeped [interaction type]` | Trial-admin-only persistent NPC at the caller's position. Inserts a default NPC into `peds`, records creator account/time, then loads it. Review DB insert failure handling before relying on it for production content. |
| Right-click `ADM: Edit` | Client menu is shown to on-duty admins or scripters; editor UI also checks trial-admin/scripter. Server persistence still must enforce trusted caller identity (Issue #469). |
| Right-click `ADM: Respawn` | Client menu is restricted to on-duty admins or scripters, but the server `peds:respawnPed` handler has no matching permission check (Issue #469). |
| `/hidemyid`, `/givemefakename` | Scripter-only toggles for player element data. `/givemefakename` reads the gender key with reversed `getElementData` arguments (Issue #472). |

`/fuelped` is inside a Lua block comment and is not registered by the active script. The interaction types and staff tiers are hard-coded across the client menu and server scripts. There is no Discord role mapping in this resource. Future Discord capabilities should complement server-side action checks and retain the established separation between staff authority, faction/duty eligibility, and donor entitlements.

## Technical map and data flow

| File | Responsibility |
|---|---|
| `meta.xml` | Loads `g_peds.lua` on both server and client, plus `s_peds.lua`, `c_peds.lua`, and `c_peds_rightclick.lua`; exports name, nametag, random-name/skin, and skin-gender helpers on both sides. |
| `g_peds.lua` | Shared random name/skin tables, skin-gender lookup, `showPedNametag`, and `getPedName`. |
| `s_peds.lua` | Loads and persists NPCs, populates element data and pool IDs, creates temporary/permanent peds, handles respawn/healing/admin events, and contains the public-transport behavior. |
| `c_peds.lua` | Responds to NPC damage behavior (immortal, scared, defend, panic), builds an older generic NPC menu, and hosts the staff NPC editor. |
| `c_peds_rightclick.lua` | Maps NPC type strings to right-click labels and events owned by other resources; also builds medic and staff rows. |
| `mods/deathmatch/data/mta.sql` | Declares the persistent `peds` table. It stores identity/type, behavior, world transform, skin/gender, money and owner, animation, sync/nametag/frozen flags, comments, and creator metadata. |

At resource start, `loadAllPeds` queries `peds` IDs, builds a coroutine per row, and resumes the load jobs on a timer. `loadOnePed` fetches each row, creates the ped, assigns a pool ID, sets interior/dimension, names and behavior data, restores optional animation/frozen state and owner/money data, and consults `item-system` badge helpers. `savePed` persists NPC money when called. There is no player-account data or separate NPC save service here.

Important element data includes `rpp.npc.dbid`, `rpp.npc.type`, `rpp.npc.name`, `rpp.npc.behav`, `rpp.npc.spawnpos`, `rpp.npc.spawnpos2`, owner/money, animation, synced, nametag, and creator metadata. Existing consumers may also read compatibility keys such as `dbid`, `name`, `ped:name`, or `nametag`.

The `peds` table schema is present in `mta.sql`, but no deployment database contents are inferred from that schema. The `mta.sql` table uses MyISAM in this snapshot; transaction/rollback guarantees for content edits should not be assumed.

## NPC behavior and event ownership

| Behavior | Source description / implementation |
|---|---|
| `0` and `3` | Described as immortal; the client damage handler restores health and cancels damage. `3` duplicates `0`. |
| `1` | Scared; client chooses a hands-up or crouch animation after damage. |
| `2` | Defends itself; client-side response drives aim/fire and asks the server to reload the specified ped weapon. |
| `4` | Panics and runs after damage. |
| `5` | Public-transport passenger. A marker attached to a temporary ped looks for a tram and calls `exports.trams:npcEnterTramPassenger`. No `trams` resource or startup entry exists in this repository snapshot; confirm whether an external resource is required. |

`c_peds_rightclick.lua` is a routing table rather than a central business-logic owner. It forwards to `bank`, `vehicleplate`, `vehicle_fuel`, `toll`, `prison-system`, `es-system`, `sfia`, `cargo`, `event-system`, and other feature resources. The active source search found no external `exports.ped-system` callers; do not confuse that with the many resources that create their own peds or consume `rpp.npc.*` element data.

The server has remotely triggerable `peds:respawnPed`, `peds:healPed`, `peds:deletePed`, and `peds:saveeditped` events. MTA's security guidance says client-supplied event `source` and arguments are not trusted; derive actor identity from `client`. The resource currently uses missing authorization, an event-source check, or caller-supplied player arguments in these handlers. See [MTA Script Security](https://wiki.multitheftauto.com/wiki/Script_security) and [MTA predefined variables](https://wiki.multitheftauto.com/wiki/Predefined_variables_list#MTA_predefined_variables). Client-side menu restrictions are useful presentation but cannot replace server validation.

## Source-confirmed work

- [Issue #469](https://github.com/itschase/OwlMTA-2026/issues/469): bind admin respawn, edit, and delete actions to trusted `client`; validate the live player permission/duty state and authoritative target ped. Keep internal server helper calls distinct from client-triggered event entry points.
- [Issue #470](https://github.com/itschase/OwlMTA-2026/issues/470): bind NPC healing to the actual caller; validate emergency-services eligibility, first-aid inventory, target identity, proximity, dimension/interior, and target state on the server.
- [Issue #471](https://github.com/itschase/OwlMTA-2026/issues/471): the one-kit branch passes undefined `thePlayer` to `takeItem` and `hasItem` rather than the function's `player` parameter. The invalid reference is source-confirmed; exact runtime error/reporting depends on the helper behavior.
- [Issue #472](https://github.com/itschase/OwlMTA-2026/issues/472): `/givemefakename` calls `getElementData("gender", thePlayer)` instead of passing the player element first and the key second.
- [Issue #473](https://github.com/itschase/OwlMTA-2026/issues/473): the generic client menu listens for `serverTriggerNPCmenu`, but a repository-wide search found no active trigger; its `clientHealByNPC` request also has no server handler in the tracked source. Confirm external dependencies before removal or reconnection.
- [Issue #474](https://github.com/itschase/OwlMTA-2026/issues/474): behavior 5 expects an external resource named `trams`, but no provider or startup entry is included in the repository snapshot.

Additional review candidates: the `clientReloadPedWeapon` event accepts a ped argument without validating the caller/target; a permanent ped insert is followed by `insert_id()`/load without checking the insert result; and temporary/permanent ped respawn failure paths need entity/pool cleanup review. These are not yet established as runtime failures.

## Interaction modernization and future Discord boundaries

This resource is a strong candidate for the planned third-eye/context action layer: show the NPC's name/type, distance, available public action, and staff-only maintenance controls in distinct surfaces. Keep the current right-click behavior as a compatibility path while each downstream service gains a supported interface. Avoid copying prices, faction policy, or inventory mutations into the UI.

An operator dashboard could search the NPC registry by ID/name/type/owner, preview its world location/interior/dimension, show creator/history, and safely edit/delete/respawn with server-side audit events. Use a shared action service with typed permissions and target/state checks. Discord staff roles may eventually satisfy named staff capabilities after the external identity adapter verifies them, but local action checks remain mandatory. Donor/supporter ranks must not grant NPC administration.

## Runtime verification still required

After static safe-start preparation, verify database load order and failure behavior, persistent and temporary NPC creation, each behavior, right-click distance/interior/dimension handling, treatment inventory and billing, admin save/delete/respawn authorization, K9/event/service-specific NPC callers, resource restart/stop cleanup, public-transport behavior with and without an external `trams` resource, and logs/pool state after partial failures. All runtime claims remain unverified.
