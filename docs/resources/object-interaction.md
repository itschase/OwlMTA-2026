# `object-interaction`

## Status

- Active resource; full manifest and caller review completed; runtime unverified.
- Discussion: [Script Resource: object-interaction](https://github.com/itschase/OwlMTA-2026/discussions/258).
- The tracked server configuration enables this resource, but that snapshot does not prove live startup.

## What it does

`object-interaction` is the client routing layer for right-clicking world objects. It offers actions for item storage/use/movement/pickup, permission editing, chairs, showers, stretchers, gates, computers, audio and video equipment, and related object-specific systems. It has no server script or persistence of its own.

The resource is a compatibility bridge between `item-world` permission data, `item-system` inventory actions, `rightclick` presentation, and specialized object resources. A visible menu row is only a client affordance; every backend action still needs server authorization in its owning resource.

## Player and operator workflow

1. A client click handler checks whether an exclusive GUI is open, identifies a clicked object, and calculates a client-side interaction range.
2. For `item-world` objects it reads replicated item ID, value, metadata, and permission state to choose visible actions.
3. Menu rows route to inventory browsing, item use/move/pickup, properties, chairs, computers, audio/video, or object-specific interactions.
4. `item-system` inventory hover code also calls the exported `clickObject` helper.

There are no commands for normal play, no persistence, no server configuration, and no resource-owned audit log. Staff may see additional object actions based on client-side predicates.

## Technical map and boundaries

- Manifest: [`meta.xml`](../../mods/deathmatch/resources/object-interaction/meta.xml)
- Loaded scripts: `c_objects.lua` and `c_objects_rightclick.lua`; the shared helper and billiards server files are commented out.
- Client exports: `clickObject`, `areYouSure`.
- Dependencies are implicit and include `rightclick`, `global`, `item-world`, `item-system`, `integration`, `sittablechairs`, plus action-specific resources.
- Object identity, policy, transforms, and persistence belong to `item-world`/`item-system`; specialized actions belong to their backend resources.

## Source-confirmed findings

- Client-side `item-world:can` policy controls row visibility but cannot prevent direct invocation of downstream events.
- World-item pickup remains in `item-system` Issue #213. Opening storage uses event `source` and checks only a subset of player/object context; it does not independently enforce the shown permission or proximity.
- Clubtec audio handlers, stretcher interactions, airport access, and object-specific operations have backend validation gaps that must be reviewed in their owning resources.
- Interaction distance is computed from clicked coordinates with incomplete bounding-box handling for negative extents and Z. No centralized line-of-sight, interior, dimension, or target-validity check protects the menu lifecycle.
- Shower teleport/freeze behavior is client-side and has no server-owned session or interruption cleanup.
- A global object-break handler cancels breaking for every client object, not only managed world objects.
- `/debugmodeloutput` is available to all clients and prints local model/transform details. Its companion destroys a client-side element only and does not perform durable deletion.
- Actions are hard-coded by item/model IDs and event names. There is no stable action ID, target revision, expiry, revocation, or audit correlation.
- The storage confirmation warns about contents, then calls the same backend pickup flow; final authorization/deletion safety belongs to that backend.
- Airport fueling is unfinished. Dependency start order and readiness are not declared.

Existing safeguards include an exclusive-GUI check, client object/range checks, permission-based row visibility, jail restrictions on the Move row, and normal capacity/confirmation prompts. These are presentation protections, not runtime-verified authorization.

## Tracked work and target direction

- [Issue #151](https://github.com/itschase/OwlMTA-2026/issues/151) owns the server-authoritative contextual-action registry and compatibility adapter.
- [Issue #213](https://github.com/itschase/OwlMTA-2026/issues/213) owns item-system pickup/storage and caller/target authorization boundaries.
- [Issue #244](https://github.com/itschase/OwlMTA-2026/issues/244) owns world-item permission reads and mutations.
- Social physical-action authorization is tracked by #132; evidence handling is bounded by #153/#184.

The proposed direction is a typed action descriptor carrying action ID, target identity/revision, actor capability, range, world context, expiry, disabled reason, and audit correlation. The owning server resource must issue or validate the execution context. Shared geometry/range code should behave consistently for asymmetric models, and each interaction should recheck target type, existence, position, interior/dimension, policy, and state on execution. Shower/stretcher actions should use server-owned sessions with interruption cleanup. Object-break cancellation should be limited to protected managed objects.

## Runtime verification matrix

All runtime behavior is unverified. A future disposable-server pass should cover dependency stop/start order; target movement/destruction and permission changes while a menu is open; asymmetric/negative bounds, line of sight, range, interior and dimension; every item permission and object type; forged downstream events and substituted targets; shower/stretcher interruption; unrelated object break events; debug commands; exclusive GUI and repeated clicks; and resource restart during an active interaction.
