# `item-system`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded inventory, definition, use, world-item, command, creator, drug, split, book, safe, admin, media, casing, upgrade, metadata, and anti-duplicate script plus schema and representative callers.
- Runtime: unverified. The server has not been started.
- Discussion: [Script Resource: item-system](https://github.com/itschase/OwlMTA-2026/discussions/102).

## Current fixed-in-source checkpoint

The container-to-player `moveFromElement` slice now derives the actor from MTA `client`, requires `source == client`, an active account/character, a matching account-and-character-bound five-minute server-issued inventory session, current access/proximity, integer slot/index identity, and a short request cooldown. Vehicle driver/key/organization ownership plus lock/impound state, interior mailbox key/government access, safe keys, and item-world `use` policy for recognized storage objects are rechecked on the server when the inventory opens and when an item moves. Character change/logout clears the session. The client still uses `weaponcap` for presentation, but it no longer submits an ammunition amount.

For stored weapon pickups, the server calls the guarded server `weaponcap` export, bounds the grant by the stored amount plus current per-weapon and total capacity, and rechecks capacity after persistence. A conditional native database update/delete must report exactly one affected row before the built-in server `giveWeapon` runs. The item instance is locked while pending; cache projection is isolated from the confirmed database transition; live-grant failure attempts a conditional restoration; failed restoration keeps the instance quarantined in-process; and bounded diagnostics record reason codes without player, account, Discord, item-metadata, or credential data. Inventory subscribe/send/unsubscribe events are now server-only, the unsubscribe handler no longer points to subscribe, container subscriptions revalidate session/access before updates, and a timer clears expired sessions.

This is not a crash-safe transaction. MyISAM cannot atomically combine the stored item transition with the live MTA weapon grant, so process failure between those steps, failed compensation, resource restart during an in-flight callback, and every runtime event/order case remain open under [Issue #214](https://github.com/itschase/OwlMTA-2026/issues/214). The in-process quarantine is diagnostic containment, not durable recovery; it disappears on restart while any already-committed row state remains. Other `item-system` mutation handlers remain under [Issue #213](https://github.com/itschase/OwlMTA-2026/issues/213); indirect frisk/admin inventory subscriptions and other read/privacy paths remain under [Issue #15](https://github.com/itschase/OwlMTA-2026/issues/15). No MTA or database runtime has been performed.

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

- Direct inventory subscribe/send/unsubscribe events are server-only and unsubscribe is correctly wired in current source. Indirect frisk/admin subscriptions and other inventory read paths still need purpose, target, proximity, role, and lifecycle review under [Issue #15](https://github.com/itschase/OwlMTA-2026/issues/15).
- The `moveFromElement` container weapon-pickup slice is caller/session/access-bound and server-derives ammunition in current source. Many other mutating remotes still use event source or caller-supplied elements as actor/target, and client coordinates still reach world placement. [Issue #213](https://github.com/itschase/OwlMTA-2026/issues/213).
- The weapon-pickup slice now uses conditional affected-row proof, an in-process item lock, and best-effort compensation. SQL owner/state and live cache/world mutations still cannot form a crash-safe MyISAM transaction; multi-step moves lack durable operation identity and restart reconciliation. [Issue #214](https://github.com/itschase/OwlMTA-2026/issues/214).
- ItemCreator accepts a caller-supplied player before delegating to `giveitem`; downstream rechecks do not make attribution safe.
- MyISAM polymorphic owners have no foreign-key, uniqueness, instance-provenance, or versioned metadata constraints.
- Drug mixing is a fixed server-checked recipe but has no workbench/tool/session/provenance model; [Issue #152](https://github.com/itschase/OwlMTA-2026/issues/152) owns future opportunity design.
- Shell casing creation accepts client weapon/calibre/coordinates/count; [Issues #153](https://github.com/itschase/OwlMTA-2026/issues/153) and [#184](https://github.com/itschase/OwlMTA-2026/issues/184) own evidence/provenance remediation.

## Target direction

Use a server-issued inventory session scoped to actor, container, actions, proximity/world context, and expiry. Route all moves through one idempotent transaction/staged transfer service with immutable item-instance IDs, typed owners, versioned metadata, capacity/version checks, durable audit, reconciliation, and quarantine. Add organization policy adapters and provenance/custody extensions without treating proposed evidence or contextual UI as already implemented.

Runtime verification must cover every owner/container and role; same/cross world context; distance boundaries; direct events versus valid sessions; stale slots/elements; capacity and weight; protected organizations; concurrent pickup/use/destroy/move; DB/cache/world failure and restart; metadata size/type; weapon/ammo/armor/drug/money/key behavior; malicious coordinates; and each dependency stopped or restarted.
