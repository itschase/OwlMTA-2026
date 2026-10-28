# SAPT System

**Resource:** `sapt-system`

**Review state:** Full manifest, player workflow, server event, persistence, and direct-caller source review. Static evidence only; runtime behavior is unverified.
**Tracking:** Issues [#496](https://github.com/itschase/OwlMTA-2026/issues/496)–[#500](https://github.com/itschase/OwlMTA-2026/issues/500), all assigned to `itschase` in [Milestone #7](https://github.com/itschase/OwlMTA-2026/milestone/7). Standardized resource Discussion: [#512](https://github.com/itschase/OwlMTA-2026/discussions/512).

## What it does

`sapt-system` is the San Andreas Public Transport (SAPT) bus route and passenger-information system. SAPT drivers can select a line and route in an in-game IBIS panel, advance through the configured stops, and announce stop information. Passengers in marked SAPT buses are charged a fare. A leader command opens a separate panel intended for editing route data, but that editor is currently only an empty shell.

## Player workflow

1. A player who is in the driver's seat of a model 431 or 437 vehicle is offered the IBIS window if faction membership is SAPT faction ID 64.
2. A driver selects a three-digit line. The client asks the server whether that line exists; after selecting a route, the server returns the route's destination and database ID. Stop names and coordinates come from the route catalog sent to the client.
3. The IBIS controls move the local checkpoint/blip to earlier or later stops. **Announce** or `/busann` displays start, current, next, or end-of-service messages through `global:sendLocalText`.
4. When a driver exits a matching SAPT bus, the server tells the client to stop the route and close IBIS.
5. A non-driver passenger entering a model 431 or 437 vehicle whose `faction` element data equals 64 is charged $10. The fare is credited to the faction returned by the name `San Andreas Public Transport`; if payment fails, the passenger is removed from the vehicle and moved one unit upward from their prior position.

Source does not show a requirement that a fare-paying passenger carry the SAPT ID item. `item-system/g_items.lua` defines a SAPT ID item restricted to faction 64, but repository search found no direct caller connecting that item to `sapt-system` behavior.

## Staff and server-operator workflow

The server registers `/ibisadmin`. It checks faction 64 membership and the faction leader flag, then opens three tabs: Routes, Destinations, and Stops. The tabs have no controls or handlers. Server globals `currentRoutes`, `currentLines`, and `currentDestinations` are empty tables and are not populated from SQL. This command does not currently provide a working editor.

The operator's route catalog is stored in three tables:

| Table | Stored information | Use |
|---|---|---|
| `sapt_destinations` | Destination name and short `destinationID` | IBIS destination display and lookup |
| `sapt_routes` | Line, route, and destination code | Match a driver's selected line and route |
| `sapt_locations` | Route database ID, stop number, name, and coordinates | Ordered checkpoints and announcement text |

These tables are defined in `mods/deathmatch/data/mta.sql`. That dump explicitly omits table data and contains no SAPT seed inserts in the checked-in SQL directory. A clean import of this dump therefore does not supply any destination, route, or stop catalog. The schemas are MyISAM/latin1 and do not declare foreign keys or indexes beyond each table's primary key.

The loader reads destinations and routes, then performs one additional locations query for every route. Each client can invoke the remote fetch event; each request rebuilds the global server tables and resends the result. No resource settings, independent logging facility, CRUD writes, or cache invalidation API are present.

## Resource map and relationships

`meta.xml` loads two client files (`c_sapt_system.lua`, `c_sapt_leader.lua`) and two server files (`s_sapt_leader.lua`, `s_sapt_system.lua`). It declares no explicit dependencies. Source calls indicate integrations with:

- `factions`: SAPT membership/leadership checks and faction lookup.
- `global`: player/faction money operations and local text.
- `hud`: fare notifications.
- `mysql`: route, destination, and stop reads.

`item-system` defines the SAPT ID badge for faction 64 but is not directly invoked by this resource. No active direct `job-system` route enrollment or vehicle-dispatch flow was found. The system reads `faction` element data from a passenger vehicle to determine whether it represents a SAPT bus.

## Source-confirmed issues and design boundaries

- **Remote announcements:** `sapt:server_announceStops` trusts client-provided current/next stop strings and broadcasts them without checking caller identity, current faction/vehicle/seat, server-owned route progress, or a server-side cooldown. The current spam guard exists only in client code. Tracked by [#496](https://github.com/itschase/OwlMTA-2026/issues/496).
- **Lookup input and load:** `server:sapt_checkData` is remotely triggerable. It accepts loosely typed arguments; a non-numeric route value can make `tonumber(value)` nil before string concatenation. It has no request throttle. Tracked by [#497](https://github.com/itschase/OwlMTA-2026/issues/497).
- **Unimplemented leader editor:** `/ibisadmin` exposes an empty UI and there are no route-catalog writes in this resource. Tracked by [#498](https://github.com/itschase/OwlMTA-2026/issues/498).
- **Empty catalog and per-request N+1 reads:** the checked-in SQL has schema only; catalog loading performs one stop query per route for every fetch. Tracked by [#499](https://github.com/itschase/OwlMTA-2026/issues/499).
- **Checkpoint helper contract:** `createCheckpoint(posX, posY, posZ, announce)` tests globals `x`, `y`, and `z` to decide whether coordinates exist, while creating the marker from its parameters. Current call sites set those globals first, so this is a hidden precondition rather than a reproduced user-visible failure. Tracked by [#500](https://github.com/itschase/OwlMTA-2026/issues/500).
- **Client startup listener:** `getDataReady` is registered for `onClientResourceStart` on `localPlayer`; the MTA Wiki documents the event source as the started resource's root element. Consequently, the handler is not bound to the documented source element. The client still has a fetch-on-open fallback, but initialization behavior should be checked and corrected.
- **No route session authority:** route/stop progression and the selected stop are client-side variables. The server does not maintain an active driver/route session to validate announcements.

These are static code observations, not demonstrations of runtime impact. MTA's [Script security guidance](https://wiki.multitheftauto.com/wiki/Script_security) says remotely supplied event arguments are untrusted and recommends binding remotely triggered actions to the server variable `client`. The [`onClientResourceStart` reference](https://wiki.multitheftauto.com/wiki/OnClientResourceStart) documents the event source as the started resource's root element.

Discord authorization should remain an optional out-of-character integration. It must not grant SAPT membership, change a player's in-character route authority, or replace faction leadership checks. Any future Discord staff capability should be applied at an administrative action boundary, while SAPT roleplay membership and route management policy remain explicit server configuration.

## Commands and interaction modernization

`/busann` duplicates the IBIS announcement button; both should eventually call one server-authoritative route action. `/ibisadmin` is an operator/faction-leader command with an empty GUI behind it. A future interaction/dashboard pass could expose route progress to drivers and replace the empty route editor with validated in-game forms, while preserving commands for accessibility and compatibility. The server must own the route, stop index, authorization, and announcement cooldown regardless of input method.

## Runtime verification plan

After the static safe-start gate is complete, verify with a disposable database/server:

- Empty catalog startup and clear driver-facing behavior.
- Seeded line/route/destination selection, stop ordering, previous/next checkpoints, end-of-route cleanup, and marker/blip deletion.
- Driver eligibility, passenger fare debit/credit, insufficient funds behavior, vehicle faction data, and vehicle exit cleanup.
- `/busann` and GUI announcement parity; forged event calls, invalid payload types/lengths, calls by passengers/non-SAPT players/outside buses, cooldown bypass attempts, and route/stop mismatch.
- Faction leader and non-leader `/ibisadmin` behavior, and verify there are no hidden mutation paths.
- Database query counts with multiple routes and repeated clients; resource restart/cache behavior after editing data.
- Correct event source binding for client initialization and IBIS open-before-fetch timing.

No MTA server or runtime test was started for this review.
