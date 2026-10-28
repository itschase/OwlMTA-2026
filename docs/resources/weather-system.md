# `weather-system`

**Purpose:** Server-coordinated weather changes and staff controls for ambient weather, rain, and wave height.

**Evidence state:** Manifest and script source reviewed. Runtime behavior, weather synchronization across interiors/dimensions, and database persistence have not been verified in MTA.

## What players experience

The server periodically selects a GTA weather ID and sends it to clients through `weather:update`. A character-spawn event sends the current weather to that player. The client applies it when the player is logged in and in the main world (interior 0, dimension 0); the spawn synchronization uses a `forced` flag so the weather can be applied regardless of that normal world check.

The client periodically restores the selected weather when outside an interior. In an interior it switches to weather ID 3 and applies a black sky gradient. Character selection and resource start/stop reset the client's weather to ID 1. These interactions are source behavior; the intended visual policy for custom interiors and dimensions still needs an in-game review.

## Staff controls found in source

All commands below are registered by `s_weather_system.lua` unless marked client-side. Existing integration checks are the source's current authority policy; they are not Discord-role mappings.

| Command | Existing check | Source behavior |
|---|---|---|
| `/getweather` | Trial Admin | Reports the server's current weather ID. |
| `/eta` | Trial Admin | Reports the estimated next weather transition time. |
| `/etanow` | Trial Admin, then requires Admin | Advances the weather queue immediately. A Trial Admin who is not also an Admin is passed to the autosuspend event; confirm this policy before changing it. |
| `/srl <level>` | Senior Admin | Sets rain level and announces the change to staff. Current input handling is tracked in [Issue #522](https://github.com/itschase/OwlMTA-2026/issues/522). |
| `/sw <weatherID>` | Trial Admin | Updates the current weather ID, broadcasts it, and writes the supplied value to `settings` where `name='weather'`. |
| `/swb <weatherID>` | Admin | Requests a blended weather transition. |
| `/swh <height>` | Admin | Sets wave height. Current input handling is tracked in [Issue #522](https://github.com/itschase/OwlMTA-2026/issues/522). |
| `/setfw`, `/fw`, `/resetfw` | Client-side Admin check | Set, create, or clear a client-local fireworks position. `/fw` uses the last position set by `/setfw`; no shared server effect is established by this code. |

The old weather, wind, time, and water commands in the latter portion of the server script are inside block comments and are not registered by this resource.

## Scheduling and persistence

On resource start, the server schedules `changeWeather` after five seconds. When the queue has fewer than four entries, the function fills it to eight with entries whose weather-style value is hard-coded as `1`; the separate `generateWeatherTypes()` function is not used by that fill path. Each entry receives a delay of 10–26 minutes or 29–120 minutes, generated as seconds and used by the timer. The chosen style then selects a random ID from the first `weatherStates` group.

After a scheduled change, the resource updates `settings.value` for `settings.name='weather'` using the server's `getWeather()` result. `/sw` writes its submitted ID to that row. This resource does not show a corresponding startup read of that row, so the database write alone does not establish that a previous weather value is restored after restart. Queue state is in memory.

## Resource connections

- `integration` supplies the staff predicates used by the commands.
- `mysql` writes the `settings` row. The manifest does not declare these runtime resource relationships as explicit `<include>` dependencies.
- `weather:update` is a server-to-client custom event in this resource. The MTA wiki describes `triggerClientEvent` as the server/client messaging mechanism and recommends targeting recipients when possible: [MTA `triggerClientEvent`](https://wiki.multitheftauto.com/wiki/TriggerClientEvent).
- MTA documents weather IDs as 0–255 and provides separate immediate and blended weather setters: [MTA `setWeather`](https://wiki.multitheftauto.com/wiki/SetWeather), [MTA `setWeatherBlended`](https://wiki.multitheftauto.com/wiki/SetWeatherBlended). Repository gameplay policy may use a smaller range.

## Operator notes and follow-up

- Verify that the database schema and seed data contain the expected `settings` row, and decide whether startup should load it or deliberately begin a fresh schedule.
- Decide whether weather selection should use `generateWeatherTypes()` or remain biased to style 1; the active queue path currently hard-codes style 1.
- Confirm the intended behavior for interiors, private dimensions, late character spawns, and the distinction between `/sw` and `/swb`.
- Validate numeric inputs and supported ranges before passing them to MTA or SQL. The source-confirmed command issues are tracked in [Issue #522](https://github.com/itschase/OwlMTA-2026/issues/522); no runtime result is claimed.
- Consider moving command discovery, staff authorization, and durable audit entries behind the planned capability and administration layers. No Discord authorization is implemented here.

## Source map

- `meta.xml` — declares one client and one server script, plus weather icon assets.
- `s_weather_system.lua` — weather schedule, staff commands, database writes, and spawn synchronization.
- `c_weather_system.lua` — client weather application, interior handling, and client-side staff fireworks controls.
