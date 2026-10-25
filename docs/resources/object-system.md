# `object-system`

## Status

- Active resource; full manifest-script and representative interior/fall-protection caller review completed; runtime unverified.
- Discussion: [Script Resource: object-system](https://github.com/itschase/OwlMTA-2026/discussions/263).

## What it does

`object-system` streams custom interior object descriptors to clients. The server caches rows from `objects` by dimension. When a player enters a dimension, the client requests the descriptors, creates local MTA objects, briefly freezes the player during synchronization, and applies delayed fall protection. Staff can reload a dimension; interior lifecycle code can remove its object cache. A legacy HTTP export reloads a custom interior after UCP changes.

## Player, staff, and operator workflows

- **Player:** enter an interior dimension; client objects are cleared/recreated from a server snapshot; fall protection may return a falling player to an entrance.
- **Staff:** `/reloadinterior [dimension]` reloads custom objects for a dimension.
- **Operator/UCP:** an external caller may update `objects` then call the HTTP export to reload and notify administrators.
- **Interior lifecycle:** `interior_system` invokes `removeInteriorObjects` when properties are changed or removed; client spawn logic calls `isSafeToSpawn`.

## Technical map and persistence

- Manifest: [`meta.xml`](../../mods/deathmatch/resources/object-system/meta.xml); one server and one client script.
- Persistence: `objects`, a MyISAM table without a foreign key to the associated interior; dimensions/interiors are numeric fields.
- Server sends model, transform, interior, collision, scale, alpha, breakability, and row ID; the client creates local objects and stores `object:dbid` locally.
- Dependencies include `mysql`, `pool`, `global`, `integration`, `interior_system`, and `interior-manager`. Startup readiness for these dependencies is not explicit.

## Source-confirmed findings

- Remote `object:requestsync` accepts any client-supplied dimension and sends cached descriptors without binding to `client`, verifying the current dimension, or authorizing property access.
- Remote `onPlayerInteriorChange` accepts client-supplied interior/dimension and broadcasts a shared lifecycle event consumed by multiple resources. Forged world state can affect those listeners.
- Client fall protection forwards entrance coordinates to an `es-system` endpoint without a server-issued property/entrance token in this resource.
- HTTP export `processCustomInterior` accepts dimension and uploader identity from the caller; its authorization depends on the broad HTTP/ACL configuration. Issue #22 owns that general ACL boundary.
- `removeInteriorObjects` ignores database-delete results, then clears cache and clients. A failed delete can restore stale objects after restart.
- Asynchronous dimension loading has no deterministic empty/failed/ready contract. Client object construction does not validate model/transform data or safely handle object creation failure.
- Rapid dimension changes can leave stale timers; root pre-render monitoring and global occlusion changes have broad rendering/performance effects.
- `/reloadinterior` prints a syntax message for missing input but does not return before attempting a load.

## Tracked work and target direction

- [Issue #260](https://github.com/itschase/OwlMTA-2026/issues/260) owns dimension sync and authoritative interior transition state.
- Issue #1 is the general remote-event parent; #22 owns HTTP/ACL identity; #6/#121 own database readiness and schema modernization.

Proposed direction: bind sync requests to `client`, derive current world server-side, and send a versioned snapshot only for the authorized dimension. Replace the client-triggerable shared event with a server-only event. Add explicit load states, validate/quarantine rows, and clear client/cache state only after durable deletion is confirmed. Generation tokens should cancel stale transfers and fall-protection callbacks. Replace the broad HTTP reload surface with a narrow audited capability.

## Runtime verification matrix

All runtime behavior is unverified. Test empty/large/error DB loads; entry before/during/after load; forged source/dimension/interior and every shared-event consumer; rapid transitions and restart; invalid models/transforms; duplicate reloads; DB deletion failure; property changes while occupants are present; fall-protection coordinate tampering; HTTP ACL/identity cases; and object-count/render performance.
