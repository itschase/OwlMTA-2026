# `gps` resource

**Review state:** Full active manifest, player command, shared street-location helper, and known caller source review. GPS rendering, pathfinding, and live caller behavior remain runtime-unverified.

## Player use

The active player-facing navigation flow is `/gps <zip code>`. It checks the player's GPS item (`111`), looks up the property entrance by zip code, and places a local blip/checkpoint. The active manifest does not load the older `c_gps.lua`, `c_drawroute.lua`, or `s_gps.lua` files, so this is not evidence of turn-by-turn route guidance or the old inventory-triggered panel.

The F11 map has a collapsible street-name overlay. Client speed-limit information comes from map/node data. The shared `getPlayerStreetLocation` helper returns street/area context for server and client consumers.

## Connected resources

- `interior_system` resolves a zip code to a property entrance and its dimension.
- `item-system` provides the GPS item and its inventory definition.
- `phone` uses `getPlayerStreetLocation` when constructing emergency hotline context; `realism` uses it for the speedometer.
- Shared navigation uses pathfinding, minimum heap, street-name, vehicle-node, and map data scripts loaded by the manifest.

The resource defines no SQL table and no staff authority in its active flow. `/speednode` is a scripter-only node diagnostic. Regular navigation and location description do not need Discord staff or supporter roles. Local item entitlement and world context remain owned by their respective gameplay systems.

## Source-confirmed findings

- **Zip lookup passes an undefined actor.** `c_gps_navigation.lua` calls `interior_system:findProperty(player, zipCode)`, but `player` is not defined in this client command closure. The client export expects an element to resolve dimension when the input is a zip code. This may break `/gps` zip lookup and is tracked by [Issue #396](https://github.com/itschase/OwlMTA-2026/issues/396).
- **Street-location cache throttling is shared across players.** `functions_g.lua` stores location per character, but uses one global five-second `last_check`; server callers in `phone/s_hotlines.lua` can therefore read stale location for a different caller during that window. A failed node lookup also leaves any previous cached street intact. This is tracked by [Issue #397](https://github.com/itschase/OwlMTA-2026/issues/397).

These are static source findings. The actual failure or staleness observed by players has not been tested on an MTA server.

## Future interaction and operations

A unified map/dashboard can combine zip lookup, nearest services, route preview, and current street context without making `/gps` the only entry point. Preserve item entitlement, active dimension, and property resolution at the gameplay boundary. Staff/admin map layers should be separately permissioned and should not change ordinary civilian navigation.

Operators should keep map and vehicle-node data with the resource and validate it before enabling navigation. Resource-specific SQL configuration was not found. Startup order with `interior_system` matters for zip resolution; the manifest has no explicit dependency declaration.

## Runtime verification

On a disposable instance, verify GPS-item eligibility, valid/invalid zip codes, interiors/dimensions, marker arrival and cleanup, map overlay, speed-limit data, two hotline callers queried inside one five-second window, and unsupported-coordinate fallback. No server or tests were run.
