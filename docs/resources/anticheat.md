# `anticheat`

## Status

- Tree/startup state: active and present in the tracked startup snapshot; live startup unverified.
- Evidence: full manifest-script source review.
- Runtime: unverified.

## What it does

`anticheat` is a shared protected-element-data API plus a collection of legacy heuristics. Server resources use it to mark element-data keys as protected and update them without triggering its own change detector. It also contains client-reported rapid-kill alerts, an unused speed-alert remote, a client-side explosion filter, mod-information display, and an hourly money comparison.

It is not a comprehensive or independently authoritative anti-cheat system. Several signals originate on the client and are best treated as advisory diagnostics.

## Player and staff experience

There are no ordinary player commands. The client counts local kills and suppresses some locally observed explosions. Trial administrators can use `/mods [player]` to view cached MTA modification information. DM/speed signals notify staff but currently create no durable enforcement case or ban.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/anticheat/meta.xml`](../../mods/deathmatch/resources/anticheat/meta.xml)
- Server code: [`s_anticheat.lua`](../../mods/deathmatch/resources/anticheat/s_anticheat.lua) and [`s_element.lua`](../../mods/deathmatch/resources/anticheat/s_element.lua)
- Direct dependencies: `global`, `pool`, and `integration`; private element-data sync also relies on account's `edu` client event.
- Important exports: `changeProtectedElementDataEx`, `setEld`, `changeProtectedElementData`, `protectElementData`, `allowElementData`, and `fetchH`.
- Baseline join protection covers only selected account/identity keys; many gameplay keys are protected only when a caller uses these exports.
- No database or files are owned; mod cache and handles are memory-only.

## Known risks and work

- [Issue #74](https://github.com/itschase/OwlMTA-2026/issues/74) owns alignment with MTA's protected-element-data policy, including restart reinitialization.
- [Issue #155](https://github.com/itschase/OwlMTA-2026/issues/155) replaces spoofable/unbounded client-reported alerts with server-owned observations and bounded telemetry.
- [Issue #156](https://github.com/itschase/OwlMTA-2026/issues/156) repairs or retires the broken money scan, whose mismatch path reads undefined variables and claims a ban it does not perform.
- Client-side explosion authorization is bypassable and can false-positive; it cannot be a security boundary.
- Mod cache lacks player-quit cleanup, and protected-change notices can flood staff without durable coalesced logging.

Runtime verification must cover fresh join and resource restart, each sync mode, forged protected-data writes, account dependency restart, alert spoof/flood, kill-window reset, explosion/projectile cases, mod-info lifecycle, money mismatch behavior, and diagnostic redaction.
