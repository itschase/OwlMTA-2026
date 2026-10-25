# `item-world`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded script, the `worlditems` schema, and representative `item-system` and contextual-action callers.
- Runtime: unverified. The server has not been started.
- Discussion: [Script Resource: item-world](https://github.com/itschase/OwlMTA-2026/discussions/251).

## What it does

`item-world` materializes persistent world-item rows as MTA object elements. It loads their position, rotation, item value, creator, protection, metadata, and use/move/pickup permissions; exposes APIs for trusted resources to create, update, query, and delete objects; and provides the item-properties editor.

It does not own the complete drop, pickup, movement, or container transaction. Those mutations are implemented primarily by `item-system`. Likewise, the client-side object context menu may hide an unavailable action, but that is only an affordance: the server handler that performs the action must authorize it independently.

## Player, staff, and operator use

Players encounter objects created by item drops or loaded from the database. `object-interaction` evaluates the replicated permission policy to offer Use, Move, Pick up, or Properties actions. Depending on the item, Use can lead to storage, video, audio, computer, seating, or another owning resource.

The editable permission modes are no-one, everyone, interior key holders, administrators, factions, named characters, the interior owner, the original placer, and a legacy query-string rule. Property key holders, staff, and scripters are intended to manage these rules through the client editor. Operators also configure the startup inactivity scanner that removes old unprotected world items.

Organization protection is separate from the action-permission policy. The `protected` field stores a legacy faction ID, while pickup and movement enforcement is performed mainly by `item-system`.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/item-world/meta.xml`](../../mods/deathmatch/resources/item-world/meta.xml)
- Object lifecycle and exported mutations: [`s_items.lua`](../../mods/deathmatch/resources/item-world/s_items.lua)
- Startup loading and retention cleanup: [`s_load_items.lua`](../../mods/deathmatch/resources/item-world/s_load_items.lua)
- Shared permission evaluator: [`g_permissions.lua`](../../mods/deathmatch/resources/item-world/g_permissions.lua)
- Server property handlers: [`s_permissions.lua`](../../mods/deathmatch/resources/item-world/s_permissions.lua)
- Client property editor: [`c_permissions.lua`](../../mods/deathmatch/resources/item-world/c_permissions.lua)
- Representative contextual caller: [`object-interaction/c_objects_rightclick.lua`](../../mods/deathmatch/resources/object-interaction/c_objects_rightclick.lua)
- Persistence: `worlditems`; `worlditems_data` remains in the schema, but the loaded implementation stores current metadata in `worlditems.metadata`.
- Exports: object creation; item-value and metadata access; permission access/evaluation; property-editor eligibility; single and bulk deletion.
- Remote events: property-data read and property save. The context-menu, pickup, movement, and use events belong to their respective consumer resources.
- Important dependencies: `mysql`, `anticheat`, `pool`, `item-system`, `global`, `integration`, `factions`, interior/key state, `datetime`, `item-texture`, and HUD loading.

On startup, the resource applies retention deletion queries, selects every remaining row, and schedules object construction incrementally. Loaded objects carry their database ID, item definition/value, creator/date, protection, action policy, exact-transform flag, metadata, scale, and rendering state. There is no explicit readiness signal. An orderly restart reconstructs objects from SQL; database and live-element mutations are not transactional.

## Source-confirmed risks

- The remote property-save handler is explicitly a blind save. It validates the supplied object only enough to identify a world item, but does not authorize `client`, require proximity, recheck key/ownership/staff authority, constrain permission IDs, validate permission payload size and shape, or restrict the legacy query-string mode.
- The property-data read handler similarly accepts any supplied world object and returns its creator name, creation date, and protection state without an access or proximity check.
- The exported `setPermissions` implementation calls misspelled `mysqL` methods and writes an undeclared global `result`, so the export will error when exercised.
- `deleteOne` deletes from singular `worlditem` instead of `worlditems`. The live object can disappear while its row remains and is recreated on restart.
- Startup always executes an exterior-item cleanup query even when the configured inactivity mode is absent or off. That unconditional query also omits storage IDs 223 and 231 from the exemptions described and used by the mode-specific queries.
- Negative item IDs used for world weapons are loaded without replicated `worlditem.permissions`. The client fallback calls `getPermissionsFromDB`, which exists only in the server script, so contextual permission evaluation can fail for those objects.
- Shared `canEditItemProperties` uses client global `localPlayer` instead of its player argument for key checks. The client happens to provide that global, while the exported server version cannot safely use the same implementation.
- Permission type 8 evaluates a stored legacy query string. This is a substantially broader and less reviewable authority surface than typed capabilities.
- Object-creation failure deletes the persisted row, conflating a rendering/model failure with invalid durable data. Failed or empty startup queries also have no deterministic completion/readiness path.
- Permission reads, database fallbacks, and mutation helpers use undeclared globals and have limited database-failure handling. Element state and SQL can diverge.

These are source-confirmed findings. No correction in this dossier is fixed in source, and none has been runtime verified.

## Tracked work and target direction

[Issue #151](https://github.com/itschase/OwlMTA-2026/issues/151) defines the future server-authoritative contextual-action registry. It should consume world-item permissions, not treat the replicated client check as authority. [Issue #153](https://github.com/itschase/OwlMTA-2026/issues/153) defines future evidence identity and chain of custody. [Issue #184](https://github.com/itschase/OwlMTA-2026/issues/184) owns authoritative shell-casing creation in `item-system`; `item-world` is relevant later because it loads and retires the resulting world object, including through retention cleanup. Issues #48 and #132 do not own this resource's persistence or permission defects.

[Issue #244](https://github.com/itschase/OwlMTA-2026/issues/244) owns permission read/mutation authority, [Issue #245](https://github.com/itschase/OwlMTA-2026/issues/245) owns durable table-correct deletion, and [Issue #246](https://github.com/itschase/OwlMTA-2026/issues/246) owns configured retention and protected/evidence object handling.

Published non-duplicate work from this audit is to:

- authorize and validate world-item property reads and permission mutations server-side, including retiring or tightly isolating query-string permissions;
- make single/bulk deletion durable, table-correct, idempotent, and restart-safe;
- honor the configured retention mode, reconcile documented exemptions, and add explicit evidence/legal-hold retention classes; and
- expose loading readiness and quarantine invalid rows instead of deleting durable state after an object-construction failure.

The target is a typed, versioned world-item instance with immutable identity and provenance; server-issued placement/use/move/pickup context; typed access-control entries for characters, organizations, property roles, and staff capabilities; transactional or idempotent database/element lifecycle; explicit retention policy; and observable recovery. Existing exports and element data remain compatibility contracts while callers migrate.

Runtime verification must cover every ordinary, storage, weapon, casing, lock, note, and money item class; each permission type for use/move/pickup; owner, key holder, faction member, placer, staff-duty, and outsider actors; forged property reads and saves; malformed and oversized policy data; near/far and cross-dimension actions; protected and deleted factions; database and object-creation failures; delete/restart resurrection; inactivity modes and age boundaries; zero and large row sets; dependency stop/restart order; and evidence-retention behavior.
