# `carradio`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified.

## What it does

`carradio` maintains the server's internet-radio station directory and synchronizes it to players. It replaces the GTA radio stream with audio attached to vehicles, including exterior attenuation and window-aware volume. Its station list also supplies the separate ghettoblaster path.

## Player use

Players change a vehicle's station through the normal vehicle radio control, set volume with `/setvol`, and can open the MP3 interface through the item system. A donor-owned station can be purchased, edited, ordered, renewed, enabled, or removed through the station manager, subject to the current legacy GameCoin and ownership rules.

## Staff use

`/radios` opens the station manager. Lead administrators are intended to manage default stations. `/srd` lets a trial administrator silence nearby vehicle radios. The existing role checks are part of the future named-capability migration; donor ownership of a station does not grant staff authority.

## Operator use

The server refreshes the station list every 15 minutes; clients request it on a slightly longer interval. The `radio_stations` table stores station ID, name, source, owner, registration and expiry dates, enabled state, and display order. Purchase history goes through `donators:addPurchaseHistory`; no dedicated station-administration audit trail was found in this resource.

The operator must define an allowed stream URL/content policy, request limits, refresh behavior, and failure handling before enabling player-submitted sources in production.

## Technical map

- Manifest: [`mods/deathmatch/resources/[vehicle]/carradio/meta.xml`](../../mods/deathmatch/resources/%5Bvehicle%5D/carradio/meta.xml)
- Station directory: [`stations_s.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/carradio/stations_s.lua)
- Vehicle radio server flow: [`s_radio.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/carradio/s_radio.lua)
- Station manager: [`radio_manager_s.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/carradio/radio_manager_s.lua)
- Client playback: [`c_radio.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/carradio/c_radio.lua)
- Exports: server/client `getStreams` and client `showMP3GUI`.
- Important connections include `mysql`, `anticheat`, `vehicle`, `global`, `hud`, `integration`, `donators`, `cache`, `scoreboard`, and item-system callers.

## Known risks and next work

- [Issue #112](https://github.com/itschase/OwlMTA-2026/issues/112) covers station ownership/admin authorization, renewal, forced refresh, vehicle radio authority, bounded station/volume values, default-station creation, and the enabled/expiry query.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) remains the parent remote-event audit.
- [Issue #74](https://github.com/itschase/OwlMTA-2026/issues/74) covers protected element-data policy.

Runtime verification must cover station refresh, vehicle playback, window/position attenuation, MP3 and ghettoblaster callers, owner and staff management, GameCoin failure, expiry, invalid streams, rate limiting, and service restart.
