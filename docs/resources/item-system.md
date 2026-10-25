# `item-system`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded inventory, definition, use, world-item, command, creator, drug, split, book, safe, admin, media, casing, upgrade, metadata, and anti-duplicate script plus schema and representative callers.
- Runtime: unverified. The server has not been started.
- Discussion: [Script Resource: item-system](https://github.com/itschase/OwlMTA-2026/discussions/102).

## What it does

`item-system` is the shared inventory and item-instance provider. It defines item identity, name, description, model, weight, metadata, capacity, storage and use behavior; persists player/container items; and supports world items, books, notes, safes, locks, badges, drugs, ghettoblasters, vehicle upgrades, shell casings, item creation, and staff maintenance.

Stored inventory is cached server-side and persisted in `items`; world placement uses `worlditems` and `worlditems_data`. Numeric owner `type` polymorphically represents player, vehicle, world, safe, object, ped, or interior without foreign-key/provenance guarantees.

## Player, staff, and operator use

- Players can open inventories; use, destroy, show, split, give, and move items; interact with vehicle/interior/safe/world containers; drop/pick/move world objects; and use item-specific book, badge, lock, texture, drug, audio, upgrade, weapon, and money behavior.
- Staff commands inspect, delete, move, or convert items/world items. ItemCreator delegates to the administrative give-item command. Client UI visibility is never sufficient authority.
- Operators must treat the item definition/export contract as a central compatibility boundary. Representative callers span nearly every gameplay domain and depend on `mysql`, `global`, `pool`, `anticheat`, `factions`, world/container resources, and logs.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/item-system/meta.xml`](../../mods/deathmatch/resources/item-system/meta.xml)
- Core management/cache: [`s_item_management.lua`](../../mods/deathmatch/resources/item-system/s_item_management.lua)
- Cross-container moves: [`s_move_items.lua`](../../mods/deathmatch/resources/item-system/s_move_items.lua)
- World items: [`s_world_items.lua`](../../mods/deathmatch/resources/item-system/s_world_items.lua)
- Item creator server: [`ItemCreator/s_item_creator.lua`](../../mods/deathmatch/resources/item-system/ItemCreator/s_item_creator.lua)
- Exports form the shared ownership API: load/clear/send/give/take/update/move/has/space/count/get/delete plus definition, metadata, badge, NPC-use, media, and safe helpers.
- Critical remotes cover inventory subscribe/read, metadata, container moves, use/destroy/show/split, drop/pick/move/rotate/protect, item creation, books/textures/drugs/media/casings/upgrades/badges/artifacts.

## Source-confirmed risks

- Unsubscribe is wired to subscribe, and inventory read/subscription events accept arbitrary elements and forgeable source without consistent ownership/proximity. Existing [Issue #15](https://github.com/itschase/OwlMTA-2026/issues/15) owns this read/privacy boundary.
- Many mutating remotes use event source or caller-supplied elements as actor/target. Access helpers lack a complete proximity/key/container/session policy, and client coordinates reach world placement. [Issue #213](https://github.com/itschase/OwlMTA-2026/issues/213).
- SQL owner/state and live cache/world mutations occur separately; multi-step moves lack transaction, idempotency, and restart recovery. [Issue #214](https://github.com/itschase/OwlMTA-2026/issues/214).
- ItemCreator accepts a caller-supplied player before delegating to `giveitem`; downstream rechecks do not make attribution safe.
- MyISAM polymorphic owners have no foreign-key, uniqueness, instance-provenance, or versioned metadata constraints.
- Drug mixing is a fixed server-checked recipe but has no workbench/tool/session/provenance model; [Issue #152](https://github.com/itschase/OwlMTA-2026/issues/152) owns future opportunity design.
- Shell casing creation accepts client weapon/calibre/coordinates/count; [Issues #153](https://github.com/itschase/OwlMTA-2026/issues/153) and [#184](https://github.com/itschase/OwlMTA-2026/issues/184) own evidence/provenance remediation.

## Target direction

Use a server-issued inventory session scoped to actor, container, actions, proximity/world context, and expiry. Route all moves through one idempotent transaction/staged transfer service with immutable item-instance IDs, typed owners, versioned metadata, capacity/version checks, durable audit, reconciliation, and quarantine. Add organization policy adapters and provenance/custody extensions without treating proposed evidence or contextual UI as already implemented.

Runtime verification must cover every owner/container and role; same/cross world context; distance boundaries; direct events versus valid sessions; stale slots/elements; capacity and weight; protected organizations; concurrent pickup/use/destroy/move; DB/cache/world failure and restart; metadata size/type; weapon/ammo/armor/drug/money/key behavior; malicious coordinates; and each dependency stopped or restarted.
