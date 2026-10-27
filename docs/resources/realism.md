# `realism` resource

**Review state:** Full active manifest, command inventory, client/server event paths, and direct integration review. This is a bundled gameplay resource with many unrelated systems; the notes below keep each behavior attached to its owner. Runtime behavior remains unverified.

## Player-facing systems

The active manifest covers vehicle crashes/ejection, seatbelts and helmets, handbrakes, indicators and cruise control, glowsticks, walking styles, smoking, alarms, peds/head synchronization, emitters, thermal vision, water behavior, speedometer, ladders, and other visual/vehicle helpers. The source includes commands such as `/cc` or `/cruisecontrol`, `/indicator_left`, `/indicator_right`, `/indicator_both`, `/seatbelt` or `/belt`, `/detach`, `/unhook`, `/throwaway`, `/switchhand`, `/passjoint`, `/walklist`, and `/lc` for ladder-truck interaction.

These are ordinary roleplay and vehicle systems. They do not require Discord staff roles or supporter levels. Inventory, vehicle occupancy, actor identity, world position, and character state must be validated by the owning server-side feature.

## Staff and operator controls

- `/setwalkingstyle` and `/setwalk` manage a player's walking style.
- Trial-admin `/createemitter`, `/nearbyemitters`, `/delemitter`, and `/delemitters` manage ambient emitters.
- Some other control paths cross into `admin-system`, `integration`, or vehicle/faction systems; preserve their existing local permission checks.
- The resource has persistence for walking style and shared element data, but most bundled behavior is transient. Operators should distinguish persisted character fields from live vehicle/player flags.

Discord staff capabilities may later complement local checks for protected staff emitter or forced-style actions. They must not replace actor/target validation, existing trial-admin policy, vehicle association, inventory possession, or audit logging. Donator/supporter tiers are separate from staff authority.

## Connected resources

Important integrations include `account`, `item-system`, `artifacts`, `global`, `anticheat`, `integration`, `pool`, `hud`, `vehicle`, and `tow-system`. The resource mixes client HUD/input, server mutations, persistent character values, item consumption, and vehicle state; evaluate each event against its paired caller rather than applying one resource-wide permission rule.

## Source-confirmed follow-up Issues

- [#401](https://github.com/itschase/OwlMTA-2026/issues/401): bind crash ejection to current occupant and server-derived crash/destination state.
- [#402](https://github.com/itschase/OwlMTA-2026/issues/402): bind the seatbelt/helmet mutation target to the authenticated player and current vehicle.
- [#403](https://github.com/itschase/OwlMTA-2026/issues/403): validate handbrake target association before changing a vehicle.
- [#404](https://github.com/itschase/OwlMTA-2026/issues/404): validate glowstick possession, placement, bounds, and server cooldown.
- [#405](https://github.com/itschase/OwlMTA-2026/issues/405): make walking-style application internal-only or bind it to the authenticated target.
- [#406](https://github.com/itschase/OwlMTA-2026/issues/406): pass and clear the correct player identity through smoking timer cleanup.
- [#407](https://github.com/itschase/OwlMTA-2026/issues/407): compare alarm interior to player interior and dimension correctly.
- [#408](https://github.com/itschase/OwlMTA-2026/issues/408): authorize remote vehicle-alarm requests against vehicle ownership/access.
- [#409](https://github.com/itschase/OwlMTA-2026/issues/409): bind remote drunkness changes to a valid server-side consumption/session path.

The source manifest includes `s_weapon_jams.lua`, but its implementation is block-commented; weapon jams should not be described as active. The district-reporting body in `s_alarm.lua` is also commented. These findings are source-only; actual gameplay impact remains unverified.

## Future interactions and diagnostics

This resource has many strong candidates for contextual interaction: seatbelt status when entering a vehicle, handbrake controls on the current vehicle, indicators and cruise control in a driver panel, glowstick placement from a held item, smoking/hand-off actions from inventory context, and staff-only emitter tools in a searchable operator console. Each interface should call the same domain operation as the existing command or input and preserve its action-boundary checks.

Add bounded diagnostic logs for rejected actor/target/state combinations, failed item settlement, timer cleanup, and staff actions. Avoid per-frame render logging. Long-lived timers and attached client objects should be cleaned up on resource stop, player quit, character change, element destruction, and provider restart as appropriate.

## Runtime verification

Verify each included behavior in its own scenario: crash/seatbelt states, vehicle occupancy and handbrake, glowstick inventory/cooldown, walking-style save/reload, smoking timer cleanup, alarm dimension/interior delivery, drunkness persistence, staff emitter permissions, and resource restart/quit cleanup. No MTA server or tests were run.

## MTA reference

- [MTA Script security](https://wiki.multitheftauto.com/wiki/Script_security) describes the remote event trust boundary for `client`, `source`, and client-supplied parameters.
- [MTA `triggerServerEvent`](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) documents client-to-server event delivery.
