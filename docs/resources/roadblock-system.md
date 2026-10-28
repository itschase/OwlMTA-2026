# `roadblock-system`

## Status

- Tree state: active resource; manifest, shared configuration, client/server scripts, startup snapshot, help entries, faction permissions, and spike-effect caller reviewed.
- Startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; snapshot only.
- Source review: full manifest and direct workflow review. Placement validation is already tracked; runtime placement, world-context behavior, and vehicle effects are unverified.
- GitHub tracking: existing [Issue #88](https://github.com/itschase/OwlMTA-2026/issues/88) covers model/placement validation and duty policy. New [Issue #487](https://github.com/itschase/OwlMTA-2026/issues/487) covers listing/removal scope; [#488](https://github.com/itschase/OwlMTA-2026/issues/488) covers spike collision context; [#489](https://github.com/itschase/OwlMTA-2026/issues/489) covers missing faction-data handling. The new issues are assigned to [Milestone #7: Resource Audit and Security Baseline](https://github.com/itschase/OwlMTA-2026/milestone/7); Issue #88 remains under its existing Milestone #2.
- Discussion: [Script Resource: roadblock-system #490](https://github.com/itschase/OwlMTA-2026/discussions/490) in `Script Resources`.
- Runtime: unverified; no MTA server/client was started.

## Purpose and player workflow

`roadblock-system` gives eligible faction members a client placement tool for temporary traffic-control objects: barriers, fences, cones, rope, detour signs, stairs, and a spikestrip. The object menu is built from a shared table filtered by the player's current faction duty. The player previews an object about six meters ahead, adjusts position/rotation with keyboard controls, and presses Space to send the placement request. These are temporary server objects, not a persistent map or database record.

The ordinary interface begins with `/rbs`. The help resource labels it for PD use. It opens only when the client has a current faction-duty result and the server's faction-type policy passes. The client list combines entries for the faction type and, where defined, the specific faction ID.

## Available object sets

The shared `g_roadblocks.lua` table provides type-wide sets for Law (`-2`), Government (`-3`), and Medical (`-4`), plus faction-specific sets for Tow faction ID 4, LSIA ID 47, Duffy ID 83, and JGC ID 74. Faction-specific entries add or narrow objects; the client merges them with the type list and de-duplicates by model ID.

The model 1593 spikestrip is only in the Law list. When placed, the server creates a `colCuboid` tagged `type="spikes"`. The separate `spike-system/c_spikes.lua` listens for client-side `onClientColShapeHit` and applies wheel-state damage to the vehicle controlled by the local player. This roadblock-created spike does not use `spike-system`'s own `/throwspikes` inventory/count arrays, so it has different placement, counting, and removal controls.

## Staff and operator controls

- `/nearbyrb` and `/nearbyrbs` list roadblock objects within ten world units.
- `/delrb [id]` and `/delroadblock [id]` remove the selected array slot and its associated spike shapes.
- `/delallrbs` and `/delallroadblocks` are restricted by `integration:isPlayerTrialAdmin` and remove all active roadblocks.
- A global cap of 50 objects is enforced by the server array. It is not a per-player or per-faction quota.
- Creation/removal and global cleanup are logged through `logs:dbLog` under category 28; this is an audit log call, not persistent roadblock storage.

The client menu requires current duty, but server-side `isRoadblockEditAllowed` calls `factions:getPlayerFactionTypes`, which returns the player's faction memberships grouped by faction type. It does not require active duty. The server event independently accepts the model and placement values from the client. Those create-event findings are already owned by [Issue #88](https://github.com/itschase/OwlMTA-2026/issues/88); do not duplicate them. MTA's guidance says client-supplied event arguments cannot be trusted and the server-provided `client` is the trusted caller identity: [Script security](https://wiki.multitheftauto.com/wiki/Script_security).

The faction helper also assumes `getPlayerFactionTypes` returns a table. The faction export returns nil when a player has no faction element data, and the roadblock helper immediately iterates the result with `pairs`. The commands may therefore hit a nil iteration instead of returning a clean denial for an un-factioned player. This is tracked separately in [Issue #489](https://github.com/itschase/OwlMTA-2026/issues/489).

The remove/list workflow has separate scoping concerns. The nearby search checks XYZ distance only, not interior or dimension. Removal then accepts any numeric occupied slot for an eligible faction member, without confirming the roadblock was the one just listed, is nearby, or belongs to the actor's authorized scope. This can confuse same-coordinate objects across worlds and makes slot IDs act as global removal handles. Tracked in [Issue #487](https://github.com/itschase/OwlMTA-2026/issues/487).

## Runtime state, persistence, and dependencies

- `roadblocksarr` is an in-memory server table. It resets when the resource stops/restarts; it is not read from or written to SQL.
- `meta.xml` declares `g_roadblocks.lua` once as server code and once as client code, then loads `c_roadblocks.lua` client-side and `s_roadblocks.lua` server-side.
- The server calls `factions` for faction membership/type policy, `anticheat` for protected element data, `pool` to allocate spike colshapes, and `logs` for actions. The client calls `factions` for current duty and faction metadata.
- The checked-in startup snapshot starts `spike-system` before `roadblock-system`; `spike-system` consumes the shared `type="spikes"` colshape marker. Actual runtime order and event delivery have not been verified.
- For model 1593, the visible object is assigned the caller's interior and dimension, but the newly created collision shape is not. MTA uses element dimensions to separate world contexts; the spike handler also requires `matchingDimension`. The shape can therefore affect vehicles in dimension 0 while its object is elsewhere, and fail to trigger for vehicles sharing a nonzero dimension/interior. Tracked in [Issue #488](https://github.com/itschase/OwlMTA-2026/issues/488). See [MTA `setElementDimension`](https://wiki.multitheftauto.com/wiki/SetElementDimension).

## Discord, dashboards, and command modernization

There is no Discord integration here. Roadblock placement is a faction-duty activity; Discord staff roles should not create faction membership or replace the local faction/duty policy. A future contextual placement UI could replace `/rbs` while retaining the current command during migration. Staff dashboards may inspect or remove temporary objects under an explicit operational capability, with actor, target, world context, and reason recorded. Donor/supporter levels must not grant placement, removal, or staff authority.

## Source-confirmed follow-up

- [Issue #88](https://github.com/itschase/OwlMTA-2026/issues/88): derive the caller from trusted MTA state, decide and enforce duty policy, derive the allowed model set server-side, validate coordinates/rotation/range, and handle creation failures.
- [Issue #487](https://github.com/itschase/OwlMTA-2026/issues/487): scope nearby listing/removal by interior, dimension, proximity, and the decided ownership/permission rule.
- [Issue #488](https://github.com/itschase/OwlMTA-2026/issues/488): apply matching interior/dimension to the roadblock spikestrip colshape and preserve paired cleanup.
- [Issue #489](https://github.com/itschase/OwlMTA-2026/issues/489): handle missing or invalid faction membership data as a normal permission denial.
- Client placement updates an object from `onClientPreRender` and calls `moveObject` repeatedly while previewing; profile its frame cost and input responsiveness in runtime before redesigning it.
- Clarify operator semantics for `/delallrbs`: it removes the global temporary set, so its trial-admin restriction and audit record are an important boundary.

## Runtime verification still required

In a disposable environment, verify `/rbs` access for on-duty/off-duty members and each supported faction, every configured model list, placement preview and key controls, forged model/coordinate requests, object-cap behavior, spike damage in dimension 0 and nonzero interior/dimension, nearby listing/removal across world contexts, global cleanup permissions/logs, resource stop/restart cleanup, and client frame impact. None has been tested in MTA.
