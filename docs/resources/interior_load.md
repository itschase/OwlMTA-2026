# `interior_load`

## Status

- Active resource under `mods/deathmatch/resources/[interior]/interior_load`; enabled in the tracked backup startup configuration.
- Full manifest, loader, client pickup, and direct-caller review completed from source.
- Live startup and all runtime behavior remain unverified; no MTA server/database was started.
- [Discussion #284](https://github.com/itschase/OwlMTA-2026/discussions/284).

## What it does

`interior_load` is the database-to-runtime projection for property elements and the client-side pickup layer. It reads undeleted properties, joins owner and business data, creates pooled synchronized `interior` elements, and publishes entrance/exit, property, keypad, safe, settings, business-note, and owner state. Clients turn these elements into two local pickups players can use to reach a property. Elevator pickups are coordinated through the same client queues, while `elevator-system` owns elevator persistence and travel.

The property database is the durable source of truth; these elements and pickups are runtime projections. Admin/property operations call its load/unload exports after changing persistent state. Other property-facing resources assume these elements and their element-data contract are ready.

## Player, staff, and operator use

- **Player:** sees entrance/exit markers and interacts with them using F/Enter. The pickup is a local affordance; `interior_system` owns server-side entry, purchase, and transition behavior.
- **Staff:** property create/reload/delete/restore workflows cause one-off projection updates or unloads; staff teleports, property inspection, ownership views, safe state, and previews consume the materialized interior element.
- **Operator/developer:** startup and resource restart rebuild undeleted property elements and schedule client pickup discovery. MySQL/pool/global/anticheat/HUD and property systems must be available. The checked-in configuration is only a startup snapshot.

## Startup and state flow

1. On resource start, the loader clears pooled-player interior marker state and disables ambient interior sounds.
2. It queries `interiors`, joined to business notes and owner character rows, for `deleted='0'` properties.
3. Rows are processed through a coroutine queue on repeating 50 ms timers, with HUD progress updates.
4. Each row replaces any existing pooled element with the same database ID, creates a new `interior` element, and replicates its property metadata and world coordinates.
5. Existing safe state is handed to `interior_system`; business note and other supplemental state are copied to the runtime element.
6. The client queues pickup creation as synchronized elements arrive and also scans existing elements after client resource startup for late join/restart recovery.
7. On queue completion, HUD progress is finalized, then a fixed additional 50-second timer broadcasts the client initialization signal.

## Technical map and resource relationships

- Manifest: [`meta.xml`](../../mods/deathmatch/resources/%5Binterior%5D/interior_load/meta.xml)
- Server loader: [`load_s.lua`](../../mods/deathmatch/resources/%5Binterior%5D/interior_load/load_s.lua)
- Client pickup queue: [`load_c.lua`](../../mods/deathmatch/resources/%5Binterior%5D/interior_load/load_c.lua)
- Active shared helpers are in [`interior_system/g_shared.lua`](../../mods/deathmatch/resources/%5Binterior%5D/interior_system/g_shared.lua); `interior_load/g_shared.lua` exists but is not manifest-loaded.
- `interior_system/c_pickups.lua` reads pickup metadata and dispatches entry events; `interior_system/s_interior_system.lua` owns the server entry authority.
- `elevator-system` creates property/vertical-travel elements and sends load/clear coordination events. `interior_load` creates only the client pickup projection.
- Property cleanup and transaction ownership crosses into `interior_system`, `interior-manager`, elevator, safe, item, object, and other property resources.
- Server exports: `loadOne(data, updatePlayers, massLoad)` and `unload(interiorOrID)`.

Important runtime element fields include `dbid`, `interior_id`, `entrance`, `exit`, `status`, `name`, `address`, activity timestamps, keypad values, safe state, business note, and `settings`.

## Source-confirmed findings and tracker ownership

- The loader decodes `data.settings`, but the mass-load query never selects the `settings` column, so loaded properties always receive an empty settings table. Existing [Issue #81](https://github.com/itschase/OwlMTA-2026/issues/81) owns this; do not duplicate it.
- Zero result rows, database errors, and query timeout have no explicit completion/failure state. No final readiness signal is sent and ambient interior audio has already been disabled. Coroutine resume errors are ignored. One new issue, [#278](https://github.com/itschase/OwlMTA-2026/issues/278), owns loader readiness, error visibility, retry, and generation reconciliation.
- The client pickup scan removes failed creation attempts from its pending queue rather than retrying. Interior pickup cleanup calls an undefined `thendestroyElement`, which can stop cleanup before remaining pickups/counters are cleared.
- Elevator pickup cleanup relies on child-destruction ordering; `clearElevators` clears bookkeeping but does not explicitly destroy existing pickup children.
- One-off property replacement destroys the old element before the replacement is fully constructed. If construction/dependency work fails, there is no rollback to the old projection; property lifecycle recovery belongs with [Issue #231](https://github.com/itschase/OwlMTA-2026/issues/231).
- The loader replicates `keypad_lock_pw` to all clients. The keypad credential/authority design is owned by [Issue #46](https://github.com/itschase/OwlMTA-2026/issues/46).
- Property entry pickup is not an authority token: the server accepts client-triggered entry without proximity/context checks. [Issue #228](https://github.com/itschase/OwlMTA-2026/issues/228) owns this entry boundary, including elevators/lifts.

These are static source findings, not demonstrated runtime failures.

## Modernization direction

Give the projection an explicit generation and readiness state with counts of loaded, invalid, failed, skipped, and retried rows. Publish successful completion for an empty world, but distinguish empty data from a failed query. Capture coroutine errors and quarantine malformed rows instead of silently counting them complete. Remove the fixed delay and let clients reconcile pickup state idempotently against the current generation. Retry missing pickup fields/creation failures. Validate and construct a replacement projection before retiring the previous element, with a recoverable fallback if later dependencies fail. Keep database mutation in property domain operations and keep interaction-context validation in `interior_system`.

## Runtime verification still required

After safe-start readiness, cover startup order/dependency outage, zero/one/large data sets, malformed rows, database timeout and recovery, accurate progress/generation readiness, property type/world-coordinate matrices, valid and missing settings, keypad secrecy, safe/business-note creation failures, late joins, duplicate scheduling, pickup retry/removal paths, elevator load/clear ordering, property reload while occupied, concurrent mutation, and crash/restart between projection steps. Until then, the loader is source-reviewed and runtime-unverified.
