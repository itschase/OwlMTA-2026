# `pool`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: starts after `data`; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified.

## What it does

`pool` is the shared registry of live MTA elements. It keeps array pools by type and indexed maps for players, characters, vehicles, interiors, elevators, teams, peds, and objects so gameplay resources can resolve database/game IDs to live elements.

## Player and staff use

Players do not operate it directly, but most gameplay systems depend on its lookups. Staff diagnostics include `poolsize` and a server-side player-pool reallocation command. Those operations rely on legacy `integration` permission helpers.

## Operator use

Server pools react to join, quit, destruction, and player `dbid` changes. Client pools intentionally contain only streamed elements. On a resource restart, the server attempts to recover tables previously handed to `data`; it does not perform a complete validated rescan automatically.

Duplicate IDs overwrite indexed entries. Restored tables may contain stale elements, and dependent resources have no explicit pool-readiness barrier.

## Technical map

- Shared pool logic: [`pool_g.lua`](../../mods/deathmatch/resources/pool/pool_g.lua)
- Server lifecycle: [`pool_s.lua`](../../mods/deathmatch/resources/pool/pool_s.lua)
- Client streaming pool: [`pool_c.lua`](../../mods/deathmatch/resources/pool/pool_c.lua)
- Core exports: `allocateElement`, `getPoolElementsByType`, and `getElement`.
- Important connections include `data`, `integration`, and hundreds of gameplay callers.
- No remote event or HTTP export was found.

## Known risks and next work

- [Issue #119](https://github.com/itschase/OwlMTA-2026/issues/119) covers generation-aware rebuild, duplicate/stale validation, readiness, and documented restart recovery with `data`.
- [Issue #42](https://github.com/itschase/OwlMTA-2026/issues/42) separately tracks an account readiness-check typo involving `pool`.

Runtime verification must cover allocation/removal, player identity changes, duplicate IDs, client stream-in/out, `data`/`pool` restarts in both orders, dependent-resource recovery, and a full process restart.
