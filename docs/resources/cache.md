# `cache`

## Status

- Tree state: active resource tree.
- Evidence state: full manifest-script review with direct image-caller tracing. The image hardening described below is fixed in the current source and awaits commit/runtime verification.
- Runtime state: MTA startup, network, filesystem, database, and gameplay behavior are unverified; no tests or server/client startup were performed.

## What it does

`cache` provides shared lookups for accounts, characters, businesses, factions, and images. It uses pooled online elements when possible and falls back to `core.accounts` or the relevant `mta` tables. It also stores downloaded images for the server and clients. Cache data is derived presentation/lookup state, not authoritative account or gameplay state.

## Player and staff use

There is no standalone cache UI. Players encounter cached results through character selection, social friend and notification views, and interior pickup presentation. Account avatars use positive account IDs and client-derived Gravatar URLs; interior artwork uses negative interior IDs and the fixed OwlGaming interior-image path.

## Commands and interaction alternatives

The scripts loaded by `meta.xml` register no commands. Cache lookups are exports and event-backed support operations, so there is no current command to replace with a panel or third-eye action. User-facing controls should remain in the owning character, social, or interior interface and call the same bounded cache operation rather than exposing raw URL or cache-maintenance fields.

## Operator use

The resource reads `core.accounts`, `mta.characters`, `businesses`, and `factions`. Username state is passed through `data` for an orderly cache-resource restart, but this is not proof that it survives a process restart. Server images use `images_cache/<md5(id)>.tex`, with accounting in `images_cache/index.txt`; client files use private `@images_cache/<md5(id)>.tex` paths. Operators should treat these files as disposable derived data, monitor retrieval failures and disk use, and leave invalidation to the resource that owns the changed record.

There is no cache-specific staff command or operator UI. The manifest exposes lookup and image functions to other resources but no HTTP-callable export. Account lifecycle code performs server-side avatar invalidation after relevant changes.

## Discord capability classification

Ordinary cache lookups, avatar/interior retrieval, local cache validation, and lifecycle invalidation do not need a Discord capability. Their authority comes from the authenticated MTA client, server-owned account/character state, and the policy of the resource presenting the data. A Discord gate would make routine gameplay presentation depend on an external staff identity system and would not prove ownership of an account, Gravatar hash, or interior.

If a future operator-only purge or diagnostic action is added, authorization should be defined at that explicit maintenance boundary through the planned Owl authorization facade; it should not gate ordinary exports or player image requests. No Discord capability, role ID, or identity-plugin integration exists in this resource today. Donor/supporter status is unrelated to cache authority.

## Technical map

- Manifest: [`mods/deathmatch/resources/cache/meta.xml`](../../mods/deathmatch/resources/cache/meta.xml)
- Lookup files: paired `*_s.lua` and `*_c.lua` scripts under [`cache`](../../mods/deathmatch/resources/cache)
- Image cache: [`images_s.lua`](../../mods/deathmatch/resources/cache/images_s.lua) validates remote requests and owns fetch/storage/delivery; [`images_c.lua`](../../mods/deathmatch/resources/cache/images_c.lua) derives supported URLs and validates the private client cache.
- `account/c_characters.lua` requests account avatars and lets the local account invalidate its own avatar. `account/s_characters.lua` performs server-side lifecycle invalidation. A legacy string-URL call remains inside commented-out code and is not active behavior.
- `social/c_friends.lua` and `social/c_notif.lua` request avatars using positive account IDs.
- `[interior]/interior_system/c_pickups.lua` requests artwork using the negative numeric interior ID.
- Important connections include `mysql`, `pool`, `global`, `factions`, `data`, many other gameplay lookup consumers, and bounded external image fetches.
- No HTTP-callable export remains in current source.

## Fixed in current source: image boundary

- Player-originated server handlers require MTA's trusted `client` to be a player and equal `source`; a client cannot submit image bytes directly.
- IDs are bounded to nonzero integral signed 32-bit values on both sides.
- Positive IDs accept only `https://www.gravatar.com/avatar/<32 hexadecimal characters>?d=404`. Negative IDs accept only `https://owlgaming.net/assets/interiors/<positive interior ID>.jpg`, whose path ID must equal the negated cache ID. No broader allowlist is proposed.
- Received and cached data must be nonempty JPEG or PNG bytes by signature and at most 2 MiB. Server and client remove corrupt, oversized, or incomplete files.
- Server storage is bounded to 512 indexed entries and 32 MiB. Replacement failures and rejected legacy files repair their quota accounting.
- Fetch work is bounded to 32 simultaneous requests globally and four per player. Requests for the same ID/URL are coalesced, and every waiting player counts against the per-player limit.
- A cache miss or refresh now queues through a server-private helper carrying the already-authenticated requester. It does not re-enter the remote handler through server-side `triggerEvent`, where MTA does not set the remote `client`; this keeps the first request associated with its player and subject to the per-player cap. See the [MTA event-system contract](https://wiki.multitheftauto.com/wiki/Event).
- Client delivery uses a latent event limited to 50 KB/s and occurs only after validation and successful persistence inside the server quota.
- Remote removal is limited to the positive account ID matching the caller's server-side `account:id`; server-internal lifecycle invalidation remains available.

These are static, fixed-in-source statements, not claims of runtime verification.

## Known risks and next work

- [Issue #118](https://github.com/itschase/OwlMTA-2026/issues/118) covers non-image lookup caller binding, ID/name bounds, faction SQL parameterization, rate limiting/coalescing, reply ownership, and returned-data minimization.
- [Issue #63](https://github.com/itschase/OwlMTA-2026/issues/63) covers the fixed-in-source image fetch/write boundary and pending runtime validation.
- [Issue #119](https://github.com/itschase/OwlMTA-2026/issues/119) covers the shared `data` restart contract.
- The active callers establish the two exact URL shapes, but the request does not give the server a verifiable account-ID-to-Gravatar-hash relationship for offline accounts. Host/path validation bounds the fetch; hash ownership remains unresolved policy.
- The negative-ID relationship for interior images is enforced, but source does not define an ownership, proximity, or visibility policy for requesting a known interior ID. None is invented here.
- The legacy positional `fetchRemote` call does not expose response headers, an in-transfer byte cap, or an explicit redirect policy to this code. Content and size checks occur after callback delivery but before persistence or client delivery.
- The concurrency limits bound in-flight fetches, but a failed/rejected fetch does not establish a server-side per-player or per-key retry cooldown. Rapid repeated failures can therefore start new requests as soon as a slot frees; add a bounded backoff before enabling this path publicly.
- MTA's resource file API does not provide directory enumeration here. Legacy files absent from `index.txt` cannot be counted proactively; when accessed, each is validated and admitted within quota or removed.
- JPEG/PNG signature validation checks the expected container prefix, not full image decodability. Texture creation, external-server behavior, crash timing, filesystem failure, and restart reconciliation remain runtime-unverified.

Runtime verification must cover pool and SQL hits/misses; malformed, duplicate, and high-rate requests; stale sessions; database failure; cache-resource and process restarts; valid, corrupt, truncated, oversized, and unsupported image data; external failures and redirects; quota exhaustion and replacement failure; request coalescing and both concurrency limits; disconnects during fetch; file cleanup; texture failure; and forged sources, IDs, URLs, sizes, replies, and removals. No tests or MTA runtime validation were performed for this documentation update.
