# SFIA Aviation and Airport Systems

**Resource:** `sfia`  
**Review state:** Manifest, server workflows, major client flows, database references, and in-repository callers reviewed statically. Runtime behavior is unverified.  
**Tracking:** Issues [#501](https://github.com/itschase/OwlMTA-2026/issues/501)–[#508](https://github.com/itschase/OwlMTA-2026/issues/508), assigned to `itschase` in [Milestone #7](https://github.com/itschase/OwlMTA-2026/milestone/7). The standardized `Script Resource: sfia` Discussion is pending publication.

## What the resource provides

`sfia` groups several aviation/public-airport features under one resource: flight tracking and ATC-style radar, FAA/airport gate and bridge controls, airport/pilot interactions, a pilot roster and delivery mission, FAA device/landing-area registry screens, and airport maps with NOTAM text. It contains 10 client and 10 server script declarations in `meta.xml`, including shared `g_airtrack.lua`, `g_radar.lua`, and `g_airgates.lua` loaded independently on both sides. The manifest advertises exports for the aircraft passenger list and connected-plane gate exit coordinates and declares a minimum MTA server version of `1.3.0-9.04570`.

The checked-in `mtaserver.conf.bak` lists `sfia` as a startup resource. That file is a historical snapshot, not proof that a live server uses this startup order.

## Player and operator workflows

### Aircraft tracking, radar, and ATC visibility

The client periodically detects whether the local player is driving an aircraft with its engine running, or is inside a client-defined ATC area, and asks the server to register that aircraft/tower context. The server stores player-to-vehicle entries in an in-memory `blips` table and sends tracking data to registered clients, which draw aircraft markers. The exported `getPlayersInAircraft()` returns players currently occupying models listed in the shared `trackingMinHeight` table; `chat-system` uses this for aircraft chat routes.

The radar/VMAT path tracks aircraft and vehicles equipped with item 264 around configured airport areas. Server state holds listener and VMAT-vehicle tables. `/refreshvmat` refreshes the cache under faction/integration checks; a remotely triggerable event also returns the vehicle list and can request cache refresh. `customblips` supplies the client-rendered map icons. The remote airtrack handlers currently accept client-supplied tracking state without validating the associated role, occupancy, area, or vehicle type on the server; see [#507](https://github.com/itschase/OwlMTA-2026/issues/507).

### Gates and connected aircraft

Server code creates gate interaction shapes, control boxes, inside/outside pickups, and fuel props from shared gate data. Players use the `F` key near a pickup to enter/exit the airport interior. For a connected aircraft bridge, the gate can route entry/exit through aircraft interior data. `vehicle-interiors` calls the exported `getDataForExitingConnectedPlane(gateID, plane)` to receive the airport-side exit coordinates. The airport control UI can be opened through `object-interaction`; the separate IPPC computer UI also sends gate-control events.

The server exposes remote gate mutation events for opening/closing, bridge connection/disconnection, and checks. The client authorization helper currently returns `true`; the intended faction/admin check in that helper is commented out, and the server handlers do not authorize their remote callers. See [#501](https://github.com/itschase/OwlMTA-2026/issues/501).

### Pilot roster and delivery mission

On server resource start, `s_pilotmission.lua` reads `sfia_pilots`, caches rows in element data, and creates the pilot-mission NPC in interior 3/dimension 3091. `ped-system` displays **Get listing** for that NPC. The client presents roster management buttons only to players with FAA faction 47's `add_member` permission; it displays **Get task** to a character name found in the cached roster.

Mission waypoints, pickup/dropoff zones, allowed aircraft tiers, and completion checks live in `c_pilotmission.lua`. At the client-detected completion, it sends operation type 3 and one of three amounts (250, 750, or 1800) to `sfia_pilots:doquery`. The server event also performs roster insert/delete operations, has no server-side authorization, and accepts caller/amount as parameters; one formal parameter named `client` shadows MTA's built-in remote caller variable. Thus the current source does not establish server-verified mission settlement. See [#504](https://github.com/itschase/OwlMTA-2026/issues/504).

### Reception, licenses, VMAT, and FAA device

`c_airport.lua` contains dialogue for an FAA receptionist, LSIA gatekeeper, and VMAT device. The dialogue lets players request pilot-license information, send a message to FAA members, and request a vehicle movement/air-traffic device (item 264). The server uses `mdc:getPlayerPilotLicenses`, faction 47 membership recipients, and `global:giveItem` to provide these functions. A server-side initializer in this file that would create the receptionist is commented out; an active owner for each interactive ped must be confirmed through the NPC/ped integration before runtime.

The FAA device client UI shows landing-area registry entries, lets FAA members add/edit/delete records and coordinates in the interface, and provides airport-map/NOTAM screens. `faadevice/server.lua` listens for remote CRUD events. The client-side controls do not protect these server mutation endpoints. In addition, the startup loader queries `faa_registry` with `x` and `y` fields, but the checked-in `mta.sql` contains no `faa_registry` definition; the source's commented DDL omits those queried coordinate fields. See [#502](https://github.com/itschase/OwlMTA-2026/issues/502) and [#503](https://github.com/itschase/OwlMTA-2026/issues/503).

The airport-map book reads and writes `pilot_notams.id=1`. The table exists in `mta.sql`, but no seed row is included. A new database therefore receives the “No input” fallback, and the current update only targets an existing row. The write event is remotely enabled and the server does not repeat the faction 47 check used to show the client-side editor. See [#505](https://github.com/itschase/OwlMTA-2026/issues/505) and [#508](https://github.com/itschase/OwlMTA-2026/issues/508).

## Direct callers and dependencies

| Caller or dependency | Relationship |
|---|---|
| `chat-system` | Calls exported `getPlayersInAircraft()` for aircraft chat routing. |
| `vehicle-interiors` | Calls exported `getDataForExitingConnectedPlane()` during aircraft interior exit handling. |
| `object-interaction` | Opens the airport gate control UI for clicked gate controls. |
| `computers-system/websites/ippc.lua` | Opens gate information/control and sends gate state changes from the in-game IPPC interface. |
| `ped-system` | Opens the pilot listing and starts the local pilot mission from a ped marked `pilotmission`. |
| `item-system` | Uses the FAA electronic-map-book item to request the FAA map UI; other FAA device flows use item 264. |
| `customblips` | Renders aircraft/vehicle tracking markers on the client. |
| `factions`, `integration`, `global` | Supply faction/capability checks, staff checks, names, protected data, item/money functions, and local chat. |
| `mysql`, `pool`, `anticheat`, `mdc`, `interior_system`, `chat-system` | Persistence, vehicle lookups, protected NPC data, pilot-license lookup, interior travel, and roleplay chat. |

The resource manifest does not declare explicit dependency metadata for these integrations. Startup snapshot order and actual export readiness need a later controlled start graph review.

## Source findings and future design

- [#501](https://github.com/itschase/OwlMTA-2026/issues/501): server-authoritative gate-control policy and type/range validation.
- [#502](https://github.com/itschase/OwlMTA-2026/issues/502): FAA landing registry server permissions, actor binding, and validation.
- [#503](https://github.com/itschase/OwlMTA-2026/issues/503): missing FAA registry schema and migration contract.
- [#504](https://github.com/itschase/OwlMTA-2026/issues/504): server-authoritative pilot-roster edits and mission rewards.
- [#505](https://github.com/itschase/OwlMTA-2026/issues/505): NOTAM writer authorization and content limits.
- [#506](https://github.com/itschase/OwlMTA-2026/issues/506): bind airport NPC actions and VMAT issuance to verified interactions/capabilities; validate text and rate.
- [#507](https://github.com/itschase/OwlMTA-2026/issues/507): verify aircraft/tower tracking context and lifecycle server-side.
- [#508](https://github.com/itschase/OwlMTA-2026/issues/508): seed or safely create the NOTAM singleton row.

These event/authority observations are source-based, not runtime demonstrations. MTA's [Script security guidance](https://wiki.multitheftauto.com/wiki/Script_security) notes that remotely supplied source/arguments can be forged and recommends server-side use of the built-in `client` value to identify the actual remote caller.

Discord roles should not assign in-character FAA membership or grant a player a pilot license. A future external Discord adapter may support operator-defined out-of-character capabilities, but each server mutation must still validate its in-game actor, current FAA/faction authority, and target state locally. An optional project API can expose read-only operational data or explicitly scoped actions without making a website mandatory.

For the website-free direction, the FAA device, gate controls, pilot registration, flight missions, and NOTAM editing are intended in-game workflows. Replace the “apply at our websites” flight-school line with an in-game application/contact path, while keeping external websites optional. The pilot mission should retain visible waypoints and feedback but move route state, eligibility, aircraft checks, and settlement to the server. Gate and FAA device controls can migrate into shared in-game dashboards after the underlying authorization and persistence contracts are defined.

## Runtime verification checklist

After the static safe-start gate, use a disposable server/database to check: manifest and implicit export startup order; plane entry/exit and tower visibility; tracking listener cleanup on exit, character change, vehicle destruction, and quit; VMAT cache/listeners across airport-area boundaries; gate use for ordinary and bridge-connected aircraft; interior exit coordinates; FAA registry fresh import and CRUD; NOTAM seed/update persistence through both map book and IPPC callers; receptionist/NPC registration; license lookup and VMAT issuance policy; pilot roster changes and every delivery aircraft tier; direct remote-event tampering, malformed payloads, and request spam; and UI behavior without a companion website.

No MTA server, database import, or runtime test was started for this source review.
