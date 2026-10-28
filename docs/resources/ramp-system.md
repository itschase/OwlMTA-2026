# `ramp-system`

## Status

- Tree state: active resource; manifest, client/server scripts, SQL schema, startup snapshot, and direct item caller reviewed.
- Startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; snapshot only.
- Source review: full manifest/schema/client/server/caller review. Runtime movement, collision, and asset appearance are unverified.
- GitHub tracking: [Issue #476](https://github.com/itschase/OwlMTA-2026/issues/476) (remote lift control authorization and bounds), [#477](https://github.com/itschase/OwlMTA-2026/issues/477) (ramp command SQL inputs), and [#478](https://github.com/itschase/OwlMTA-2026/issues/478) (nearby listing ignores interior). All are assigned to [Milestone #7: Resource Audit and Security Baseline](https://github.com/itschase/OwlMTA-2026/milestone/7).
- Discussion: pending; title should be `Script Resource: ramp-system` in `Script Resources`.
- Runtime: unverified; no MTA server/client was started.

## What players and operators use it for

`ramp-system` creates persistent garage car lifts: a frame plus a vertically moving platform stored in the `ramps` database table. Players use the inventory item **Lift Remote** (item 151) near a lift to open a scrollbar control and raise or lower the platform. This is different from the separate vehicle deployment ramp: item 117 is named **Ramp** and is described for loading DFT-30s; its behavior lives in the `vehicle` resource.

The model assets in this resource replace the GTA lift models used for the frame, platform, and stand. Resource start loads stored lift records, creates objects in their saved interior and dimension, and removes the original world models for the replaced lift IDs.

## Player guide

- A trial admin creates a garage lift with `/addramp`; the command also gives that player item 151, the Lift Remote.
- Use the Lift Remote near the matching lift. `item-system` searches for a lift object with the item's DB ID within 30 units and opens the client scrollbar.
- Moving the scrollbar sends `moveRamp` with a lift element and desired position. The intended UI range is 0–100. The server moves the platform over time and writes the target to `ramps.liftposition`.
- Players do not need a chat command for ordinary use. The client GUI closes with its Close button.
- The intended interaction requires proximity and the item at the client UI entry. The server event currently does not repeat those checks; Issue #476 tracks the authoritative validation work.

## Staff and operator guide

| Command | Source behavior |
|---|---|
| `/addramp` | Trial-admin-only; creates a lift roughly three units in front of the caller, persists its transform and creator, loads the objects, gives item 151, and posts an admin warning. |
| `/delramp [id]` | Trial-admin-only; deletes the DB row and destroys matching lift/frame objects. The raw ID is inserted into SQL; see Issue #477. |
| `/moveramp [id]` | Trial-admin-only; updates the saved transform to the caller's current position/orientation and reloads the lift. The raw ID is inserted into SQL; see Issue #477. |
| `/nearbyramps` | Trial-admin-only; lists lifts within 11 units in the caller's dimension. The search does not also filter interior; see Issue #478. |
| `/gotoramp [id]` | Trial-admin-only; moves the caller to the target lift's position/interior/dimension. |

The command permissions use `integration:isPlayerTrialAdmin`. No Discord role logic, staff dashboard, audit event catalog, or resource export is declared. Keep the existing staff policy on the server and validate all command arguments independently.

## Technical map and stored data

| File | Role |
|---|---|
| `meta.xml` | Loads `c_ramp.lua` client-side and `s_ramp.lua` server-side and downloads the TXD/DFF/COL assets. It does not declare `<export>` entries or dependency metadata. |
| `c_ramp.lua` | Loads and replaces object models 2052, 2053, and 2365 with custom TXD/DFF/COL assets; registers the `showRampControls` GUI event and sends the chosen scrollbar target through `moveRamp`. |
| `s_ramp.lua` | Implements DB-backed lift creation/loading/deletion/movement, staff commands, nearby listing, teleport, and the remotely triggerable lift movement handler. |
| `item-system/s_item_system.lua` | When item 151 is used, searches for a nearby `garagelift` object with a matching `dbid` and sends `showRampControls` to that player. |
| `item-system/g_items.lua` | Defines item 151 as “Lift Remote” and the distinct item 117 as “Ramp.” |
| `data/mta.sql` | Defines `ramps`: ID, JSON transform, interior, dimension, rotation, creator, and saved lift position. The supplied `data.sql` has no `ramps` insert rows in the reviewed snapshot. |

Each loaded frame has element data `garagelift`, `lift`, `dbid`, and `creator`; the moving platform has `lift.position`. The frame also receives `lift.moving` while a move is in progress. These values are runtime element state, not an independent saved history. The server writes the requested `liftposition` to MySQL before the movement timer clears `lift.moving`; database failure/partial movement behavior is not checked here.

The client runs `applyMods()` immediately and schedules two more calls one second apart. Each call loads and replaces the same model IDs again, without checking return values or retaining/unloading the loaded TXD/DFF/COL handles. The reason for the repeated passes is undocumented; review visual reliability and asset lifetime before changing it.

MTA's `moveObject` smoothly interpolates a server object toward its target coordinates; this resource derives height/time from the scrollbar delta. MTA's model-replacement guidance documents the TXD/COL/DFF load order and warns about replacement behavior; compare the current calls (TXD, DFF, then COL) with the documented order before tuning them. See [MTA `moveObject`](https://wiki.multitheftauto.com/wiki/MoveObject), [MTA `engineReplaceModel`](https://wiki.multitheftauto.com/wiki/EngineReplaceModel), and [MTA Script Security](https://wiki.multitheftauto.com/wiki/Script_security).

## Source-confirmed work

- [Issue #476](https://github.com/itschase/OwlMTA-2026/issues/476): the remote `moveRamp` event accepts caller-supplied target element and position without checking trusted actor identity, lift membership, item possession, range, interior/dimension, valid bounds, or movement state. Client-side item/UI checks do not protect this server handler.
- [Issue #477](https://github.com/itschase/OwlMTA-2026/issues/477): `/delramp` and `/moveramp` concatenate a raw command ID into SQL; `/addramp` concatenates creator and JSON strings. Validate values and use the project's safe query/parameterized SQL path.
- [Issue #478](https://github.com/itschase/OwlMTA-2026/issues/478): `/nearbyramps` checks dimension and distance but not interior, so coordinate-overlapping objects in another interior may appear in the result.

Additional operator follow-up: `SmallestID()` and insert are separate operations, so simultaneous admin creation can contend for the same ID; inspect `query_free` success and affected rows; handle failed `fromJSON`, object creation, asset loading, or MySQL updates; and decide whether the two delayed asset replacement passes are necessary. These are follow-up review items, not runtime-confirmed failures.

## Discord, API, and dashboard direction

This is player-facing physical equipment, not a staff role. Discord authentication should not grant Lift Remote access by itself; the server should verify the item, the target lift, proximity, interior/dimension, current movement state, and a valid target. An API could expose authorized lift inventory/configuration to a separate operator website, but no HTTP/API integration exists here today.

A later in-game operator interface could search lifts by DB ID, location/interior/dimension, creator, and saved position; preview them on a map; and create/move/delete with audit records and server-side permission checks. A player context menu can surface lift operation only when item and proximity rules pass, while retaining the Lift Remote workflow until parity is verified.

## Runtime verification still required

After static safe-start preparation, test a fresh schema with no lift rows, multiple persisted lifts, all four interiors/dimensions, item-151 use, 0/100 and intermediate movement, rapid/reversed input, resource stop during movement, deleted/missing rows, database failure, mismatched/stale elements, concurrent admin creation, model/collision/texture appearance, and the separate item-117 vehicle ramp flow. Runtime remains unverified.
