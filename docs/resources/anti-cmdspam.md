# `anti-cmdspam`

## Status

- Tree/startup state: active and present in the tracked startup snapshot; live startup unverified.
- Evidence: full manifest-script source review.
- Runtime: unverified.

## What it does

`anti-cmdspam` observes MTA's server-side `onPlayerCommand`, warns at 25 counted commands, disables command handling after 50, and re-enables after five seconds without another command. Commands named exactly `Next` and `Previous` are excluded in source. Optional command-to-resource diagnostics exist but are hard-coded off.

## Player, staff, and operator experience

All players and staff share the same hard-coded thresholds. At the warning and disable points, staff receive messages through `global`; the player receives a short temporary command lock. There is no management command, database, durable history, or configurable policy file.

## Technical map

- Manifest: [`mods/deathmatch/resources/anti-cmdspam/meta.xml`](../../mods/deathmatch/resources/anti-cmdspam/meta.xml)
- Server implementation: [`server.lua`](../../mods/deathmatch/resources/anti-cmdspam/server.lua)
- Dependencies: `global` and `anticheat`.
- The disabled state is stored through protected element data; counters and timers are memory-only.

## Known risks and work

- [Issue #157](https://github.com/itschase/OwlMTA-2026/issues/157) replaces inactivity-based counting with a real burst/sustained rate limiter.
- The existing timer restarts after every command, so a slow continuous stream whose gaps remain below five seconds eventually triggers the rule even though it is not “50 commands in five seconds.”
- Player quit clears the counter but not the retained timer/table entry.
- Thresholds, exclusions, escalation, cooldown, and staff operational allowances are hard-coded; exact-case exclusions require runtime confirmation.

Runtime verification must cover 24/25/50/51 commands, gaps just below/at/above five seconds, long low-rate streams, cooldown cancellation, command-name casing, unknown commands, staff actions, parallel players, quit/reconnect, and resource restart.
