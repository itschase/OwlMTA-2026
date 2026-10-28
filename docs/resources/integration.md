# `integration`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: starts before `cache`; full dependency order is implicit and unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified; no external request was sent.

## What it does

`integration` contains the legacy numeric staff/supporter/team predicates used throughout the gamemode and a hard-coded OwlGaming forum bridge. It sets staff-related player element data, supplies role/title checks on both server and client, and can create an external forum topic and write its thread ID to `core.bans`.

## Player and staff use

Most staff commands call this resource to decide whether an account is an administrator, GameMaster or auxiliary team member, often combined with duty state elsewhere. Supporter levels are also exposed here. These are current legacy inputs, not the final policy. The rebuild must keep supporter/donor entitlement separate from staff authority and replace action checks with server-owned named capabilities.

## Operator use

Forum group numbers, titles, and the OwlGaming endpoint are hard-coded. The bridge reads `forumsAPIKey` from server settings and places it in a query string. Missing configuration still produces a request containing the string `nil`. Failures only produce debug output and are not durably retried.

No key value belongs in source, documentation, logs, or client state. Any retained provider adapter must be disabled by default, configurable, and outside the server startup critical path.

## Technical map

- Staff/supporter policy: [`g_staff.lua`](../../mods/deathmatch/resources/integration/g_staff.lua)
- Server helpers: [`functions_s.lua`](../../mods/deathmatch/resources/integration/functions_s.lua)
- Legacy forum adapter: [`s_forums.lua`](../../mods/deathmatch/resources/integration/s_forums.lua)
- Connections include `anticheat`, `mysql`, `global`, `core.bans`, staff command callers, and the external forum endpoint.
- `createForumThread` is explicitly non-remote; no HTTP export was found.

## Known risks and next work

- [Issue #122](https://github.com/itschase/OwlMTA-2026/issues/122) covers retiring or isolating the forum bridge, secret transport, optional configuration, bounded delivery, and migration to the self-hosted API where warranted.
- [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3) owns capability mapping and supporter/staff separation.
- The malformed player-type checks in `g_staff.lua` were corrected in the current source batch. [Issue #23](https://github.com/itschase/OwlMTA-2026/issues/23) remains open for runtime validation of invalid, destroyed, non-player, and live player inputs.
- [Issue #68](https://github.com/itschase/OwlMTA-2026/issues/68) owns the self-hosted Discord identity/capability API.

Runtime verification must cover every retained predicate, disconnected/non-player values, disabled/missing forum configuration, safe provider failure, role refresh, capability migration, and absence of secrets in logs/URLs.
