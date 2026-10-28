# `fakevideo` resource

**Review state:** Partial manifest, client/server streaming, persisted texture catalog, and ClubTec/item-system caller review. Creation/deletion workflows and all texture lifecycle/runtime behavior need further review.

**GitHub record:** [Script Resource Discussion #545](https://github.com/itschase/OwlMTA-2026/discussions/545); [Issue #447](https://github.com/itschase/OwlMTA-2026/issues/447) tracks stalled pending batches after failed frame fetches.

## Purpose and use

`fakevideo` provides animated world textures for the video-player objects managed by `clubtec`. The server loads `textures_animated` rows into an in-memory catalog; client render code requests frame data, applies shaders to objects, and updates textures as players change dimension/interior. Frames are fetched from the URLs stored in the database and cached in the resource's `cache/` directory. Client/server exports expose `getFakevideoData`; `clubtec` uses that catalog to resolve video-disc data. Item movement and world-object flows also trigger dimension reloads through `item-system`.

This is infrastructure behind in-world media props rather than a standalone player command. `clubtec` governs the player-facing television/video-player workflow; operators should review both dossiers together. The manifest loads client and server forms of `g_fakevideo.lua`, the shader, image assets, and MTA server minimum 1.3.0-9.05000.

## Streaming and source finding

The remotely triggerable `fakevideo:stream` event accepts a catalog ID and caller-provided texture/object/loading-image context, then may fetch each catalog frame remotely. Concurrent callers are stored in one `data.pending` list while only the first request's rendering context is passed to the eventual client event. Failed frame callbacks only log and do not complete/clear that pending batch; subsequent requests can join stale pending state. This is tracked in [Issue #447](https://github.com/itschase/OwlMTA-2026/issues/447). Runtime symptoms are unverified.

The remote catalog synchronization and dimension-loading flows, cache directory writes, URL policy, response-size bounds, client shader event validation, and potential media privacy/availability implications remain open audit areas. Do not interpret MTA resource-root event restrictions as validation of client parameters.

## Dependencies and operations

The resource reads SQL through `mysql`, enumerates elements through `pool`, recognizes video-player items through `clubtec`, and is called by `item-system`. It writes fetched bytes to local resource cache and streams pixel/frame payloads with latent events. The manifest declares no explicit dependency ordering. Confirm SQL import, network policy, cache write permissions, caller resources, client assets, and startup order before enabling animated media.

## Future design and Discord boundary

Keep media asset transport separate from player/staff authorization. Discord roles should not determine which texture URLs may be fetched or replace in-game video-player ownership/use rules. A future media service adapter could be optional, but must preserve bounded, allowlisted server-side fetches, auditable cache expiry, per-request context, failure recovery, and optional-provider behavior.

## Runtime verification

After static review and safe-start preparation, verify catalog load, item/world placement, dimension changes, stream latency, failed/malformed/oversized URLs, concurrent viewer requests, client cleanup, shader application/removal, resource restart, and `clubtec` integration on a disposable server. No MTA server or tests were run.
