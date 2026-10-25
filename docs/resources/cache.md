# `cache`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: starts after its foundational dependencies; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review; image hardening is fixed in source.
- Runtime state: unverified.

## What it does

`cache` provides shared lookups for accounts, characters, businesses, factions, and images. It uses pooled online elements when possible and falls back to `core.accounts` or the relevant `mta` tables. It also stores downloaded images for the server and clients.

## Player and staff use

There is no primary standalone UI. Many gameplay and administrative resources use cache exports and reply events to translate IDs into names or records. Image callers can request cached profile or resource images through the image subfeature.

## Operator use

The resource reads `core.accounts`, `mta.characters`, `businesses`, and `factions`. Username state is passed through `data` for an orderly cache-resource restart but does not survive a process restart. Server images use `images_cache`; client files use private `@images_cache` paths.

The current image path validates actor/source, IDs, URL format, JPEG/PNG signatures, and request/storage bounds. Gravatar ownership cannot be proved from the server-side data currently supplied. This source correction remains open under #63 until runtime validation.

## Technical map

- Manifest: [`mods/deathmatch/resources/cache/meta.xml`](../../mods/deathmatch/resources/cache/meta.xml)
- Lookup files: paired `*_s.lua` and `*_c.lua` scripts under [`cache`](../../mods/deathmatch/resources/cache)
- Image cache: [`images_s.lua`](../../mods/deathmatch/resources/cache/images_s.lua)
- Important connections include `mysql`, `pool`, `global`, `factions`, `data`, many gameplay consumers, and bounded external image fetches.
- No HTTP-callable export remains in current source.

## Known risks and next work

- [Issue #118](https://github.com/itschase/OwlMTA-2026/issues/118) covers non-image lookup caller binding, ID/name bounds, faction SQL parameterization, rate limiting/coalescing, reply ownership, and returned-data minimization.
- [Issue #63](https://github.com/itschase/OwlMTA-2026/issues/63) covers the fixed-in-source image fetch/write boundary and pending runtime validation.
- [Issue #119](https://github.com/itschase/OwlMTA-2026/issues/119) covers the shared `data` restart contract.

Runtime verification must cover pool and SQL hits/misses, malformed/high-rate/duplicate requests, stale sessions, database failure, cache restart, process restart, every image format/limit, external failure, file cleanup, and forged replies.
