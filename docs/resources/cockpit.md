# `cockpit` resource

**Review state:** Full manifest-script source review. Rendering, aircraft behavior, texture memory, and client performance remain runtime-unverified.

## Purpose and player use

`cockpit` is a client-side instrument HUD for the pilot of a plane or helicopter. It automatically appears when the local player enters driver seat 0 of either vehicle type, except vehicle model 539. It draws aircraft attitude, altitude, speed, heading/compass, climb/descent indication, and ground/lock/gear/engine status. Leaving the eligible driver seat removes the render handler.

The manifest lists seats 0 and 1 in the entry guard, but the handler attaches the HUD only when the local player is actually occupant/driver of seat 0. No cockpit command, keybind, toggle, or control panel is registered here. A separate `realism` script registers `/cockpit` for a first-person camera view; it is not this instrument HUD.

## Staff, operator, and Discord authorization

There are no staff/admin/GameMaster controls, permissions, donor benefits, or Discord capability checks. The HUD is passive client presentation of the local pilot's current vehicle state and does not mutate server gameplay state.

The resource loads one client script and packages twelve instrument image assets. It declares a minimum MTA version of 1.3.5, which is an old manifest declaration rather than evidence of current compatibility. It has no database schema, external service, or configurable settings. The inventory snapshot lists it as enabled, but actual deployment startup and graphics behavior are not verified.

## Technical map and connections

- `meta.xml` loads only `aircraft_client.lua` as a client script and packages the graphics assets.
- `aircraft_client.lua` creates texture elements, listens to `onClientVehicleEnter` and `onClientVehicleExit` on the client root, attaches an `onClientRender` handler for an eligible local pilot, and samples altitude every 125 ms for the variometer.
- The display reads client vehicle state (rotation, world position, velocity, ground contact, lock, gear, and engine). It owns no vehicle state or persistent records.
- Commands and keybinds in this resource: none. Database tables: none. Exports/custom events: none.
- The unrelated `/cockpit` first-person view command is registered in `realism/c_fpview.lua` and should not be confused with this HUD.

## Source-confirmed findings and tracking

- **Texture loader runs for every client resource start.** `aircraft_client.lua:7-21` creates twelve textures and attaches the loader to `onClientResourceStart` using the global root, without filtering the started resource. MTA documents that the event fires for any client resource start and its `source` is that resource's root. The script overwrites previous texture references without destroying them or checking failure. See [Issue #363](https://github.com/itschase/OwlMTA-2026/issues/363) and the official [`onClientResourceStart`](https://wiki.multitheftauto.com/wiki/OnClientResourceStart) and [`dxCreateTexture`](https://wiki.multitheftauto.com/wiki/CreateTexture) references.
- **Variometer polling can outlive aircraft use.** `aircraft_client.lua:115-124` recursively schedules a 125 ms timer whenever the local player occupies any vehicle. The exit handler at `148-151` removes rendering but does not cancel the timer. The previous position sample is updated each tick at line 121; the altitude-delta calculation is rolling, so it is not reported as an identified defect. See [Issue #364](https://github.com/itschase/OwlMTA-2026/issues/364).
- **Aircraft model exception is undocumented.** The script excludes model 539 at line 132. The reason is not stated in source; treat any change to that exception as a design question, not a confirmed bug.

## Modernization opportunities

- Load textures once for this resource, check every creation result, and manage lifecycle cleanup without recreating handles on unrelated resource starts.
- Store the timer handle and bind sampling to the active aircraft/driver session; stop it on exit, loss of eligibility, or resource stop.
- Review speed units, indicator scaling, model 539 exclusion, aircraft coverage, and render cost against the current MTA build and representative aircraft.
- A player-facing settings panel could optionally control visibility or scale, but keep the automatic HUD as a simple default and preserve key/command alternatives if a toggle is added.

## Runtime verification still required

On a supported MTA client, verify all eligible plane/helicopter models, driver and passenger seats, model 539, enter/exit/jacking/switching between aircraft and other vehicles, texture-load failures, resource starts/restarts, HUD scaling and readings, timer cleanup, and sustained render/memory cost. Record the exact MTA build and client diagnostics. No server or tests were run for this review.
