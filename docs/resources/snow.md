# `snow`

**Purpose:** Render a configurable falling-snow effect on each player's client and provide local visual settings.

**Evidence state:** Manifest, client/server scripts, settings UI, and related ground shader/weather references reviewed. Runtime rendering and saved-setting behavior have not been verified in MTA.

## Player experience

The client starts particle snowfall when the resource starts. `/snow` toggles the effect when the server setting `snow_toggle` is enabled. Holding Ctrl while pressing `S` also invokes the toggle command; the handler checks the Ctrl key state, so plain movement input should not toggle snowfall. `/snowsettings` opens the local settings window when `gui_enabled` is enabled.

The settings GUI lets a player choose real/cartoon flakes and adjust density, wind direction/speed, flake size, fall speed, jitter, and cursor highlighting. These detailed visual preferences are stored in the player's local `settings.xml`; they are not character or account data and are not controlled by Discord. The client draws the effect during `onClientRender`, so density has a direct client performance cost.

The F10 graphics panel separately shows an account-persisted “Enable snowfall” checkbox when this resource is running. Static review found that the value is saved and replicated as local-player data but is not applied to the snow effect; see [Issue #526](https://github.com/itschase/OwlMTA-2026/issues/526). Do not confuse this stored account preference with the detailed local XML settings or the server's `snow_toggle` permission setting.

The commands `/ssize`, `/swdir`, `/swspeed`, `/sdensity`, and `/salpha` are also registered in the particle script as direct client-side tuning controls. The `/sdensity` immediate-decrease loop bound was corrected in source; [Issue #525](https://github.com/itschase/OwlMTA-2026/issues/525) remains runtime-unverified.

## Staff and operator behavior

The server resource settings `gui_enabled` and `snow_toggle` are read once by `snow_s.lua`. On the client's `onClientReady` request, the server returns those two values only to the triggering client. The settings control whether players may open the configuration GUI or toggle snow; they do not change the server's authoritative weather.

Ground appearance is a separate feature in [`shader_snow_ground`](shader_snow_ground.md), controlled by `/groundsnow` and a client preference. Ambient weather is separate again in [`weather-system`](weather-system.md). The weather-system's commented-out help window describes snow roleplay guidance, but its `/snowinfo` command is not registered there.

## Resource connections

- `snow_gui.lua` calls the client functions in `snow.lua` directly and writes local configuration through MTA's XML helpers.
- `snow_s.lua` responds to the client-ready event with the server's GUI and toggle settings.
- `shader_snow_ground` changes world textures; it does not enable/disable this particle effect.
- `weather-system` changes GTA weather and documents winter roleplay context; neither resource is a server-authoritative snow simulation in this code.
- `account/f10-settings` surfaces two different preferences: `snowfall` for particles and `groundsnow` for the ground shader. The ground shader preference is applied by the F10 client handler; the snowfall preference currently lacks an equivalent apply path ([Issue #526](https://github.com/itschase/OwlMTA-2026/issues/526)).
- The `social` resource exposes “Make snowball” in the local-player context menu when `weather:getSnowLevel()` returns 2. That helper currently reports level 2 when `shader_snow_ground` is running, not when the `snow` particle resource is enabled. `activities` then creates the temporary snowball and handles throws. The remote snowball actor/trajectory trust gap is already tracked in [Issue #306](https://github.com/itschase/OwlMTA-2026/issues/306). The relevant source is `social/c_player_rightclick.lua`, `activities/snowball/s_snowball.lua`, and `weather/g_temp.lua`; see the [social](social.md) and [activities](activities.md) dossiers.
- The manifest exports several client functions (`updateSnowType`, density/wind/size/jitter updates, start/stop, and setting toggles) for other client resources. No active external callers were identified in the scoped search.

## Operator and future-development notes

- This is a client visual resource; it does not create server-persisted snow conditions, affect vehicle handling, or establish weather hazards as game rules.
- Keep player visual preferences local. Server-wide policy should only decide whether the GUI and toggle are allowed; it should not trust client visual settings as gameplay authority.
- The client event only returns settings to its actual MTA `client`. Future Discord authorization is not needed for this player preference flow. Staff-only server controls, if added later, should use a separate capability boundary.
- A future context interaction could expose visual options without adding more commands, but `/snow` and `/snowsettings` remain current interfaces until a replacement is designed.
- [Issue #525](https://github.com/itschase/OwlMTA-2026/issues/525) tracks the corrected density-decrease defect; static source fix is not a runtime verification.

## Source map

- `meta.xml` — client/server scripts, help config, exports, and the two server settings.
- `snow.lua` — particle lifecycle, render loop, controls, and setting updates.
- `snow_gui.lua` — configuration UI and local XML persistence.
- `snow_s.lua` — client-ready settings response.
