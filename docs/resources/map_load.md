# `map_load`

## Status

- Active resource; full manifest and server/client caller review completed; runtime unverified.
- Discussion: [Script Resource: map_load](https://github.com/itschase/OwlMTA-2026/discussions/267).

## What it does

`map_load` reads approved/enabled map rows, groups descriptors on the server, publishes active IDs, and sends object/removal data to clients to create local objects. `map_manager` uses server exports to enable, disable, test, and inspect maps. Server/client exports share names but have different realm signatures.

## Workflow and persistence

- Durable desired state lives in `maps.approved/enabled` and `maps_objects`.
- The server holds `loaded_maps`; replicated `synced_maps` lists active map IDs.
- Each client keeps local map elements/removals, requests missing payloads, and cleans them on resource stop.
- Startup waits a fixed delay, reads all active objects, and broadcasts maps as clients join. Preview/test uses the same local ID namespace as production.
- No deployment generation/checksum, client acknowledgement, retry count, or durable reconciliation record exists.

## Source-confirmed findings

- `maps:requestServerMaps` replies using event `source` instead of authenticated `client`; source/target/map ID are not bounded, and repeated full requests have no rate or in-flight limit.
- `loadAllMaps` does not reliably publish an empty queue when zero rows are enabled; a failed query can leave stale state with no degraded marker/retry. Readiness is based on fixed delay, not database readiness.
- Activation treats an empty query table as a successful loaded map; `unloadMap` returns true even if no state changed. Server exports lack a documented caller capability contract.
- Queue update compares Lua tables by reference, causing redundant replicated writes. Payloads lack version/checksum and clients do not acknowledge render success.
- Stored object rows go to engine constructors without normalization; partial creation failure has no rollback. Test and production share an ID, so previewing a live map can unload/replace it.
- Test blip interior/dimension setter calls omit their values. Overlapping maps that remove the same world model are not reference-counted; unloading one can restore it while another still needs removal.
- All active payloads are delivered without spatial streaming or per-client byte budget; `/loadmaps` permits repeated full requests.

## Tracked work and target direction

- [Issue #62](https://github.com/itschase/OwlMTA-2026/issues/62) owns map lifecycle/request deployment; [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) owns remote request binding.
- [Issue #6](https://github.com/itschase/OwlMTA-2026/issues/6) owns database-engine and schema concerns.

Proposed direction: bind each request to `client`, rate-limit/coalesce delivery, publish explicit empty/degraded/ready states, retry after provider readiness, and use generation-versioned payloads. Isolate preview IDs, validate rows, rollback partial loads, reference-count world removals, and return structured load/unload results. Add diagnostics without requiring every client as a deployment gate.

## Runtime verification matrix

All runtime behavior remains unverified. Test active/empty/error startup, DB recovery, forged source/map IDs, repeated large requests, production-vs-preview, nonzero-world blips, malformed rows, partial renderer failure, overlapping removals, disable-last-map convergence, client/resource restart, and high object counts.
