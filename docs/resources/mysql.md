# `mysql`

## Status

- Tree state: active resource tree; marked protected in the tracked server snapshot.
- Tracked startup snapshot: first of the reviewed foundational resources; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified; no database connection was attempted.

## What it does

`mysql` is the central database provider. It opens the native `mta` connection at resource start, opens `core` lazily, exposes modern connection access, retains a legacy `mta_mysql` module connection and query helpers, and runs per-resource migrations recorded in `mta.migrations`.

## Player and staff use

Players do not interact with it directly. Nearly every persistent gameplay system depends on it. Staff diagnostic commands include `testdb` and `mysqlleaky`; these should be mapped to an explicit operator/developer capability and must never expose credentials or raw sensitive data.

## Operator use

The tracked [`settings.xml.bak`](../../mods/deathmatch/settings.xml.bak) contains placeholders for separate `mta` and `core` databases. It is a template, not configured deployment evidence. Some legacy callers also require the platform-specific `mta_mysql` module and matching native MySQL libraries.

The resource creates and writes `mta.migrations` but does not install the complete schemas. It also writes `maxime.log` through a legacy helper. Native connections request automatic reconnect; the legacy path attempts a ping/reconnect.

## Technical map

- Manifest: [`mods/deathmatch/resources/mysql/meta.xml`](../../mods/deathmatch/resources/mysql/meta.xml)
- Native and legacy API: [`mysql.lua`](../../mods/deathmatch/resources/mysql/mysql.lua) and [`mysql_external_module.lua`](../../mods/deathmatch/resources/mysql/mysql_external_module.lua)
- Migration runner: [`migrations.lua`](../../mods/deathmatch/resources/mysql/migrations.lua)
- Modern export: `getConn`; legacy exports include raw query/result and simple select/insert/update/delete helpers.
- No HTTP-callable export was found.

## Known risks and next work

- [Issue #121](https://github.com/itschase/OwlMTA-2026/issues/121) covers configuration preflight, native-module documentation, per-connection readiness, legacy export reconciliation, and verified migration reporting.
- [Issue #6](https://github.com/itschase/OwlMTA-2026/issues/6) owns schema/table migration, engine/collation work, and transaction boundaries.
- Several forum-related exports and legacy configuration getters appear incomplete. `s_server_global_maintenance.lua` contains automatic password/shutdown behavior but is not loaded by the manifest.

Disposable verification must cover blank/malformed settings, unavailable server, missing legacy module, both schema connections, reconnect, migration failure/recovery, diagnostics, and secret-safe logs before gameplay resources start.
