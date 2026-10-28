# `heligrab` resource

**Review state:** Active manifest, player interaction, server exports, and event flow reviewed statically. Several API and trust-boundary concerns are recorded below; live helicopter behavior and multiplayer cleanup remain runtime-unverified.

**GitHub record:** [Script Resource Discussion #542](https://github.com/itschase/OwlMTA-2026/discussions/542); [Issue #449](https://github.com/itschase/OwlMTA-2026/issues/449) tracks the exported hanger lookup filter.

## What it does

`heligrab` lets a player catch and hang from configured helicopter models. The client tracks streamed helicopters, computes a nearest hand-to-side point, checks the drop point against the ground, and allows grab by `/grab` or the configured jump control. `/drop` or backspace releases the player. The client updates attachment position, animation, rotation, leg pose, and drop behavior as the helicopter moves. The operator can configure allowed bind/command names and whether client-side passenger count limits are enabled.

## Player experience and dependencies

Defaults are `/grab` or jump to grab and `/drop` or backspace to release. The active manifest loads `c_heli.lua`, `s_heli.lua`, and client help text. It declares no resource dependencies or persistence. Helicopter offsets and limits are keyed to vehicle display names, so custom vehicle naming or models need matching configuration before they can be used. The `.old` client file is not loaded by the manifest.

## Server API and known issue

The server exports `ToggleHangingWeightLimit`, `SetPlayerGrabbedHeli`, `IsPlayerHangingFromHeli`, `GetPlayerHangingData`, and `GetPlayersHangingFromHeli`. These provide an integration point for other gameplay systems to start/stop hanging and inspect its current state. `GetPlayersHangingFromHeli` currently ignores its `heli` argument when collecting players and compares the requested line against `data.line` even though the stored field is `line_percent`; see [Issue #449](https://github.com/itschase/OwlMTA-2026/issues/449). This can return players hanging from unrelated helicopters and makes the line filter fail.

## Server authority and future work

Normal grab validation (distance, alive state, not already in a vehicle, ground clearance, and capacity) is performed on the client before a local event sets `hanging` element data. The server accepts `PlayerGrabVehicle` and `PlayerDropFromHeli` as remote events; the former changes the sender's camera based on the supplied vehicle, while the latter relays a drop to other clients. `RemoveHangingPedFromVehicle` removes the sending player from their current vehicle. The exported setter can request attachment to any valid helicopter element, and the resource does not persist a server-authoritative hanging record. These flows need careful caller and client-server authority review before relying on them for consequential gameplay; client-computed range, capacity, state, and attachment cannot serve as server authorization.

The resource is a candidate for contextual interaction on a helicopter, but retain server validation for player state, target type, proximity, world/interior, capacity, and cleanup. Ordinary use should not depend on Discord roles. A future audit should inspect all callers of the exports, confirm detach/quit/death/resource-stop behavior, and consider replacing client element data as the authority for server decisions.

## Runtime verification

No MTA server was started and no runtime test was run. On a disposable server, verify each configured model and custom vehicle, successful and invalid grabs, side/line positioning, passenger limit, pilot camera changes, collision/drop behavior, death, disconnect, vehicle destruction, resource stop/restart, and the export's filtered results. Confirm all callers before changing event validation or the public export contract.
