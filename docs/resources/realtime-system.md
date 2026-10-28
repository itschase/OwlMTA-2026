# `realtime-system`

## Status

- Tree state: active resource; manifest, server/client scripts, startup snapshot, interior-settings integration, and direct callers reviewed.
- Startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; this is a configuration snapshot, not proof of the live server configuration.
- Source review: complete for this resource and its direct time-setting caller. Runtime clock synchronization, timezone behavior, and interior visuals remain unverified.
- GitHub tracking: [Issue #480](https://github.com/itschase/OwlMTA-2026/issues/480) tracks caller-bound time refreshes; [#481](https://github.com/itschase/OwlMTA-2026/issues/481) tracks `/setgametime` input validation; [#482](https://github.com/itschase/OwlMTA-2026/issues/482) tracks offset bounds/normalization. All are assigned to [Milestone #7: Resource Audit and Security Baseline](https://github.com/itschase/OwlMTA-2026/milestone/7).
- Discussion: [Script Resource: realtime-system #483](https://github.com/itschase/OwlMTA-2026/discussions/483) in `Script Resources`.
- Runtime: unverified; no MTA server/client was started.

## What the resource does

`realtime-system` makes the GTA world clock follow the server's real local clock, with a configurable hour offset. It also sends per-player time updates for interiors and supports interior-specific day/night overrides. It does not store clock state in SQL. The server recalculates the world clock at resource start and every 30 minutes; it adjusts the in-game minute duration to align minute changes to real-time minute boundaries.

MTA distinguishes the GTA world clock (`setTime`) from system real time (`getRealTime`). `setMinuteDuration` controls how many real milliseconds one in-game minute lasts. See [MTA `getRealTime`](https://wiki.multitheftauto.com/wiki/GetRealTime), [`setTime`](https://wiki.multitheftauto.com/wiki/SetTime), and [`setMinuteDuration`](https://wiki.multitheftauto.com/wiki/SetMinuteDuration).

## Manifest, configuration, and persistence

`meta.xml` loads:

- `s_realtime_system.lua` server-side.
- `c_update_client_time.lua` client-side.
- `c_clock.lua` is present but commented out in the manifest, so it is not part of the declared resource runtime.

The manifest setting `*offset` defaults to `0`. The server adds it to `getRealTime().hour` and applies a single +/-24 adjustment. The setting is not documented or constrained to a range in the manifest. An offset outside the single-wrap range, or a non-integer value, can leave an invalid value for `setTime`; see Issue #482. This is an operator setting, not a player preference.

There is no table or durable clock record owned by this resource. Interior time policy is persisted by `interior_system` in interior/vehicle settings data, and `realtime-system` reads it through `exports.interior_system:getInteriorSetting(dimension, "time")`. The code comments define `0=auto`, `1=day`, `2=night`; values 1 and 2 set the affected client to 12:00 or 00:00, while auto retains the real-time-derived hour/minute.

## Player experience

- Outside interiors, the server synchronizes the GTA world clock to the server's local real time plus `offset`.
- In a private interior or vehicle interior with positive interior and dimension IDs, the server sends a client-specific time update. The interior's setting can force day or night; auto follows the real-time clock.
- `/settime day` and `/settime night` are registered by the loaded client script. They change only that player's local visual clock while the player's dimension is nonzero; the script tells players the purpose is to brighten or darken interior objects. This is not an account permission or server-wide time change. A later server refresh can replace the local override.
- The script comment in `c_clock.lua` describes showing the HUD clock based on watch/phone/PDA inventory or vehicle occupancy, but that file is not declared in `meta.xml`; no active `updateHudClock` handler from this resource should be assumed from the manifest alone.

This resource has no normal character progression, inventory ownership, economy, or database transaction of its own. The client `/settime` command is a local presentation control and should not be mistaken for the staff command.

## Staff and server-operator controls

- `/setgametime [hour] [minute]` is a server command gated by `exports.integration:isPlayerAdmin(thePlayer)`. It sets the shared GTA world time and sends an administrative notification. The source describes the change as temporary; the periodic real-time correction will later restore the configured clock.
- The minute check currently rejects values greater than 60, so `60` passes the local guard despite MTA's documented 0–59 range; the condition also repeats `hour < 0` where a `minute < 0` check appears intended. If `setTime` returns false, the command does not send a clear failure response. Tracked in Issue #481.
- Operators configure `offset` in the MTA resource settings. Document the server OS timezone and daylight-saving policy along with that value: `getRealTime()` uses server-side local time by default, so changing machine timezone/DST can change the displayed game clock independently of the resource setting.

The `/setgametime` permission currently uses the legacy local admin predicate. In a future Discord-linked staff model, this action should map to a narrow capability such as `world.time.manage`, checked by the trusted host at the action boundary. No Discord role ID or Discord authorization is implemented here, and Discord donor/supporter roles must not grant this staff action.

## Runtime flow and resource connections

1. At resource start, `updateTime` reads the `offset`, calls `getRealTime`, sets the shared world clock, and schedules the minute-duration alignment. It repeats on a 30-minute correction timer.
2. After the initial start, periodic correction iterates online players in nonzero interiors and calls `refreshClientTime` for them.
3. `c_update_client_time.lua` requests a refresh on client resource start and after the `setPlayerInsideInterior` transition event when the local player is moving from dimension zero. The server answers with a targeted `updateClientTime` event.
4. The server also handles `onPlayerInteriorChange` and exports `refreshClientTime` for other server resources.
5. Direct caller found: `[interior]/interior_system/s_settings.lua` calls the export after a time setting is saved, passing the actor's interior, the interior/vehicle dimension ID, and the actor. The setting owner loads/saves the setting; this resource only translates it into the player's visual time.
6. MTA's event security guidance says client arguments and event source can be faked and the server-provided `client` identifies the caller. `refreshClientTime` currently serves both the remote event and server export, accepts an optional `player` parameter, then assigns that value to `client` before sending the update. The remote handler therefore lets a caller select a different player as the client-event recipient. The impact shown by source is a client-side visual time update, not a demonstrated server clock change. Issue #480 tracks separating the remote wrapper from the internal/export path. See [MTA Script security](https://wiki.multitheftauto.com/wiki/Script_security) and [`triggerServerEvent`](https://wiki.multitheftauto.com/wiki/TriggerServerEvent).

The `weather` and `weather-system` resources are separate startup entries. This resource sets time only; weather selection and any visual coordination with weather are not established by its manifest or direct caller graph.

## Commands, interfaces, and future usability

The current interfaces are two chat commands and the interior settings workflow. For later UI work, keep the distinctions explicit:

- Player: offer an accessible local lighting preference only if it does not override a property owner's/server-defined interior time policy; expose the current interior policy in a contextual interior panel where appropriate.
- Staff: put shared world-time changes in a searchable world/environment panel with a reason, duration or reset policy, permission check, and audit record; retain `/setgametime` during migration.
- Operator: centralize timezone/offset, correction interval, and interior auto/day/night defaults in configuration and an operator dashboard. Keep safe defaults and blank external integration credentials; this resource currently has no external API or Discord service dependency.

These are design opportunities, not implemented features. No command has been removed.

## Source-confirmed issues and follow-up

- [Issue #480](https://github.com/itschase/OwlMTA-2026/issues/480): bind remote refreshes to the triggering player; separate the client request handler from the server export so trusted interior-setting callers can still target a player.
- [Issue #481](https://github.com/itschase/OwlMTA-2026/issues/481): reject minute 60 and negative minutes, and report invalid input or a failed `setTime` call.
- [Issue #482](https://github.com/itschase/OwlMTA-2026/issues/482): constrain or normalize the configured offset, document timezone/DST behavior, and report invalid configuration.
- The unused `c_clock.lua` is not counted as a live HUD feature because the manifest comments it out. Confirm callers and intended status before re-enabling or deleting it.
- `/settime` permits a client to override their own visual time in a nonzero dimension. Whether this should yield to an interior's configured time is a gameplay policy question; the static source shows no server-side time mutation from this command.

## Runtime verification still required

In a disposable test environment, check minute alignment and the 30-minute correction, positive/negative/boundary offsets, operating-system timezone and DST changes, player entry/exit and reconnect, interior/vehicle interior auto/day/night settings, setting changes, overlapping interior transitions, `/settime` versus server refreshes, `/setgametime` valid/invalid values, and forged refresh events targeting another player. Verify resource stop/restart timer cleanup and debug output. None of these runtime checks has been performed.
