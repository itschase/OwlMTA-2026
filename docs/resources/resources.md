# `resources`

## Status

- Active startup resource; full manifest/file/consumer review; runtime unverified.
- Discussion: [Script Resource: resources](https://github.com/itschase/OwlMTA-2026/discussions/233).

## Current behavior

Despite its name, `resources` is not an MTA resource manager. It contains no scripts, commands, events, exports, database, or authority. It is a shared client asset bundle for logos, loading/selection images, fonts, and interface/vehicle sounds used by many account, HUD, phone, item, vehicle, interior, social, report, and NPC resources.

- Manifest: [`mods/deathmatch/resources/resources/meta.xml`](../../mods/deathmatch/resources/resources/meta.xml)
- All declared assets were present and non-empty in static review.
- Startup order is the only dependency contract; consumers create their own font/image/sound handles and have inconsistent fallback behavior.

## Source-confirmed risk

`weapon/attach/c_attach.lua` references `:resources/attachments.xml`, but no such file exists or is declared. [Issue #219](https://github.com/itschase/OwlMTA-2026/issues/219) owns restoration/removal and fresh-client validation.

The compatibility name should remain unless every `:resources/` reference migrates. Target improvements are machine-readable asset consumers/dependencies, license/provenance and content versions, CI checks for every static reference, and consistent client fallback/readiness behavior. Runtime validation must cover fresh/warm cache, provider start/stop/restart, missing/corrupt assets, low-memory font failure, package size/cache invalidation, version skew, and Linux filename case sensitivity.
