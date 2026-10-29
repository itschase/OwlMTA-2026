# `bans`

## Status

- Tree/startup state: active and present before account login in the tracked startup snapshot; live startup unverified.
- Evidence: full manifest-script source review.
- Runtime: unverified.

## What it does

`bans` implements database-backed account, serial, and IP enforcement; online/offline/manual ban commands; unban and ban lookup; alternate-account/network/device investigation; a legacy forum-thread bridge; and an external join-time proxy/GeoIP check.

Player connections are checked by serial/IP and account login checks account ID. Ordinary players have no commands. Staff commands cover online/offline, account, serial, IP, lookup, alternate accounts, and two-step unban. Access relies mainly on legacy Trial Administrator predicates, with some alternate-account views also available to supporters.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/bans/meta.xml`](../../mods/deathmatch/resources/bans/meta.xml)
- Enforcement: [`ban_s.lua`](../../mods/deathmatch/resources/bans/ban_s.lua)
- Investigation: [`whois_s.lua`](../../mods/deathmatch/resources/bans/whois_s.lua)
- Exports: `checkAccountBan` and `addToBan`.
- Dependencies: `mysql`, `global`, `integration`, `cache`, `admin-system`, and account login.
- Primary persistence: `core.bans`; investigation also reads core accounts and MTA account/character/faction data.
- The resource synchronously waits on some connection/login queries and hard-codes a plaintext obsolete GeoIP endpoint plus legacy OwlGaming appeal/forum behavior.
- `checkAccountBan` now returns `true` for an active ban, `false` for a completed no-match query, and `nil` for invalid account input, query-start failure, timeout, or database error. Account login fails closed on `nil`; punishment-point automation reports that points were recorded but does not create a new ban when current ban state cannot be verified. The export emits bounded account/check outcome diagnostics without query text. This is fixed in source only and remains runtime-unverified.

## Known risks and work

- Parent [Issue #57](https://github.com/itschase/OwlMTA-2026/issues/57) tracks ban-source/hierarchy/legacy reconciliation.
- [#159](https://github.com/itschase/OwlMTA-2026/issues/159): `addToBan` returns a boolean although callers require an inserted numeric ID, breaking confirmed-success handling.
- [#160](https://github.com/itschase/OwlMTA-2026/issues/160): the account-ban export and its two in-tree callers now distinguish no match from database failure; target, serial, IP/range, multiple-match, other outage paths, and runtime validation remain.
- [#161](https://github.com/itschase/OwlMTA-2026/issues/161): immutable lift/expiry history, scoped hierarchy, and safe confirmation.
- [#162](https://github.com/itschase/OwlMTA-2026/issues/162): wrong-database and broken alternate-account queries plus sensitive-data scope.
- [#163](https://github.com/itschase/OwlMTA-2026/issues/163): retire or isolate the raw-IP external proxy check.
- [#122](https://github.com/itschase/OwlMTA-2026/issues/122): remove the separate forum dependency.

Runtime verification must cover every identifier and command path, permanent/timed/lifted/expired and multiple matches, malformed/range inputs, hierarchy, concurrency, DB latency/failure, punishment integration, forum/provider absence, actor-scoped history/confirmation, redaction, Discord revocation, and restart behavior.
