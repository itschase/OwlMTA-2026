# `weapon`

## Status

- Active resource at `mods/deathmatch/resources/weapon`; it loads weapon, ammunition, attachment, sound, and server/client gameplay scripts.
- Full manifest, direct-caller, inventory, persistence, and cross-resource review completed from source.
- No MTA server or database was started. All runtime behavior remains unverified.
- [Discussion #291](https://github.com/itschase/OwlMTA-2026/discussions/291).

## Player and staff workflows

Players carry weapons as inventory item `115` and ammunition as item `116`. The resource projects those records into live MTA weapons, supports switching multiple weapons in one GTA slot, firing, reload/unload, eligible weapon renaming and fire-mode selection, holstered models, and spatial gun/reload/empty sounds. Ammunition counts and weapon provenance are encoded in legacy colon-delimited item strings:

```text
weapon_id : serial : display_name : loaded_rounds : modified_flag
ammo_type : rounds : serial
```

Faction-drop and Ammunation flows issue weapons/ammo with source serials; duty equipment uses a distinct source code and is treated as non-retrievable. Staff tools grant ammunition and inspect serial/source details. `/gunserial` currently also permits supporter status; this is legacy code, not intended staff policy.

## Runtime projection and integrations

`refreshWeaponsAndAmmoTables` reconstructs per-player weapon/ammo tables from inventory. `updateLocalGuns` removes live weapons, reissues a chosen weapon per slot, and applies the resource's extra-round compatibility convention. Account selection, inventory operations, ES recovery, paintball exit, and resource restart trigger reconstruction.

Key integrations: `item-system` (inventory and persistence), `npc` (faction-drop catalog/delivery), `admin-system` (staff ammo grant), `factions`/`duty` (duty gear), `es-system`/`pd-system` (law enforcement), `account` (character load), `paintball`, `parachute`, `global`, `cache`, `anticheat`, and `bone_attach`. The backup startup configuration starts some consumers before `weapon`; there is no provider readiness/version contract. This is not proof of deployment order.

## Important source boundaries

Some paths already derive state from server inventory: `weapon:reload` uses trusted MTA `client` and resolves weapon/ammo items from that player's inventory; `weapon:modify` also locates the requested item in the caller's inventory; `firemode` constrains values to supported modes; `canRetrieve` applies encoded duty/license policy to inventory movement. These are static source observations, not runtime validation.

## Source-confirmed defects and tracking

1. **Client-authoritative ammunition:** `weapon:syncAmmo` accepts client-supplied remaining rounds for owned DBIDs and stores them without a server-observed firing/capacity invariant. `weapon:unload` can convert that cached count to an ammo item. Reload/unload write weapon and ammo items separately and ignore persistence results. Tracked in [Issue #287](https://github.com/itschase/OwlMTA-2026/issues/287).
2. **Overbroad weapon item mutation and destructive targeting:** the editor sends name/modified fields, but server accepts arbitrary table indexes and can rewrite weapon ID, serial, ammo, and unknown fields. Satchel removal trusts a client-selected target and mutable display name; switching/rebuild routes also use event `source` for player state changes. Tracked in [Issue #288](https://github.com/itschase/OwlMTA-2026/issues/288).
3. **Attachment and utility event authority:** attachment events accept caller-selected source, model/bone/transform and do not verify equipped inventory ownership; object creation is unchecked. Any client can refill its extinguisher to 500 through a remote event. Tracked in [Issue #289](https://github.com/itschase/OwlMTA-2026/issues/289). The missing `attachments.xml` remains existing [Issue #219](https://github.com/itschase/OwlMTA-2026/issues/219), not duplicated here.
4. **Catalog/data defects:** weapon 11 uses a malformed ammo setting key; weapon 13 is absent from ammo-less mapping; weapon 36 has no clip-size branch; a faction-drop rocket ammo row references undefined ammo ID 35; `givePlayerAmmo` mutates the shared ammo catalog when custom rounds are supplied. Tracked in [Issue #290](https://github.com/itschase/OwlMTA-2026/issues/290).
5. **Privacy and capability boundary:** `/gunserial` reveals creator/license-holder identity and permits supporters. Existing [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3) owns staff/donor separation; do not grant staff capabilities through donor tiers.
6. **Additional review notes:** only the first positive ammo pack per ammo type is cached; attachment preferences and weapon stats have weak validation/lifecycle; live reload state can diverge on failures/restart. General remote hardening remains [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1), inventory mutation is [#213](https://github.com/itschase/OwlMTA-2026/issues/213), transaction foundation is [#6](https://github.com/itschase/OwlMTA-2026/issues/6), export contracts are [#208](https://github.com/itschase/OwlMTA-2026/issues/208), and duty lifecycle is [#220](https://github.com/itschase/OwlMTA-2026/issues/220).

## Operator and developer notes

The resource stores durable item state through `item-system`; local weapon/ammo tables and live MTA weapon state are projections. During a later safe-start phase, verify cold startup and provider ordering, character switches, inventory transfers, duty transitions, resource restarts, and failed writes before trusting the projection. The resource overwrites global weapon statistics at start and does not establish restoration on stop. `attachments.xml` is read/written under `:resources/` but missing from the repository/manifest.

## Modernization direction

Replace colon-delimited item values with versioned typed weapon/ammo records and a compatibility decoder. Route grant/equip/fire/reload/unload/confiscate/transfer through one server-owned service with idempotent inventory settlement. Separate policy capabilities (license, duty, staff) from client presentation (selector, sounds, holsters). Make serial inspection return minimum data for a named capability. Validate weapon/ammo definitions at startup and surface structured readiness to dependent resources. Keep all Discord role IDs configurable; donor entitlement, staff access, and faction/duty authority stay separate.

## Runtime verification still required

Test ammo spoof/replay, magazine limits, multiple packs, reload/unload failure injection, satchel targeting, metadata-field tampering, attachment transforms/models, extinguisher refill policy, all weapon/ammo catalog IDs, every NPC faction-drop row, `/gunserial` role access, and provider/resource restarts in a disposable MTA environment after the safe-start gate. These tests were not run.
