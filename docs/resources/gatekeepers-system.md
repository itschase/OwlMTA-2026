# `gatekeepers-system` resource

**Review state:** Full manifest-script and direct-caller static review. NPC placement, interaction range, event behavior, and server settlement remain runtime-unverified.

## Purpose and player use

`gatekeepers-system` is an NPC interaction layer for several city services. Its client right-click handler detects nearby peds marked with `talk` metadata and routes the selected interaction by NPC name or server-set properties. It is an interaction dispatcher; many resulting workflows belong to other resources.

Players right-click a talk-enabled ped within three world units, choose **Talk**, then use the contextual option or service UI. Examples include the city-hall prompt, locksmith, shop, bank, tow/impound, clothing, police/airport, fuel/toll, and medical conversations. Not every listed path is implemented here; the dispatcher triggers events or UI exports in owning resources.

### Current command inventory and future interface

The manifest-loaded scripts declare no commands. The player entry point is already contextual: right-click a talk-enabled NPC and choose an action. The current client uses a hard-coded NPC-name branch and event dispatch. Future interaction work should inventory those branches, move stable options to data-driven descriptors, and let a consistent third-eye/context menu display actions based on server-validated context. Multi-step services such as key duplication and government applications should open guided forms; service lookup should remain attached to the appropriate NPC. Do not create command aliases for actions that have no command today.

This is the current resource's direct application of [`COMMAND_AND_INTERACTION_STRATEGY.md`](../planning/COMMAND_AND_INTERACTION_STRATEGY.md): preserve discoverable context while sharing one trusted server domain operation with any later UI.

## Staff and operator workflows

There is no staff command or dedicated operator UI in this manifest. `locksmithNPC:getFactionInts` uses `factions:hasMemberPermissionTo(client, factionID, "manage_interiors")` to find faction-owned interiors eligible for keys. This remains a local faction-rank permission; a Discord global role must not create faction membership or bypass the faction's own permission. Server operators must keep dependent resources such as `global`, `factions`, `pool`, `item-system`, `anticheat`, and the resources that own each dispatched event available. The manifest declares no database schema, configuration settings, or explicit export dependencies.

## Discord capability classification

Ordinary NPC dialogue, government ID purchase, key duplication, and shop/service use should be authorized by server-side identity, interaction context, inventory, funds, and owning-resource policy. Faction interior-key access stays under the character's faction membership/rank and the existing `manage_interiors` permission. This resource does not need a blanket Discord capability.

If a future Discord capability is required for an explicitly global staff action, check it at the owning admin action boundary through the planned Owl authorization facade and reusable [MTA Discord Identity adapter](https://github.com/itschase/mta-discord-identity). Do not put raw role checks in this NPC dispatcher. The current Owl source has no integration with that external plugin.

## Technical map and direct callers

- `meta.xml` loads `s_peds.lua`, `s_cityhall_ped.lua`, `s_locksmith.lua`, `c_ped_rightclick.lua`, `c_cityhall_ped.lua`, and `c_locksmith.lua`.
- `c_ped_rightclick.lua` listens to client world clicks, checks for a nearby `ped` with `talk` element data, builds the Talk/Close menu, then dispatches by name or properties (`ped:fuelped`, `ped:tollped`, `shopkeeper`, `carshop`). This script calls into `ped-system`, `elections`, `npc`, `bank`, `tow-system`, `clothes`, `license-system`, `es-system`, `health-addon`, vehicle resources, and other feature owners.
- `s_cityhall_ped.lua` exposes `cityhall:makeIdCard`, derives name/gender/birth date/fingerprint from the authenticated MTA `client` and element state, charges `$5`, and grants item 152. The client city-hall menu also offers a job-application event owned elsewhere.
- `c_locksmith.lua` opens the key-duplicator form and sends a requested key type/ID to the server. Faction interior IDs arrive from the server after faction permission checks. The client UI's `$50` price and ownership check are presentation only; the server does not repeat them.
- `s_locksmith.lua` handles that request and the faction-ID lookup. The money/item exports are owned by `global` and `item-system`.
- `s_peds.lua` schedules a ped to respawn after six minutes when a ped under this resource root is wasted, copying its model, position, rotation, interior, dimension, and element data.
- Locksmith NPC creation in `c_locksmith.lua` is present but the `onClientResourceStart` hook is commented out. A live NPC is not established by that file; the ped may be created by another resource. Verify active source/data before describing deployment placement.

Remote MTA events in this resource include `cityhall:makeIdCard`, `locksmithNPC:givekey`, and `locksmithNPC:getFactionInts`. The handlers should derive the requester from MTA `client`; the event source and payload are not authorization. See the MTA [Event](https://wiki.multitheftauto.com/wiki/Event), [addEventHandler](https://wiki.multitheftauto.com/wiki/AddEventHandler), and project [server boundary notes](../reference/MTA_SERVER_BOUNDARIES.md).

## Persistence and lifecycle

This resource does not declare its own database tables. The ID card is an inventory item and cash changes use shared money functions; key records are item-system values representing vehicles, properties, garages, elevators, or faction interiors. The target resource/record and item lifecycle belong to those domain resources. NPC positions are not established by a loaded settings file in this manifest.

## Source-confirmed findings and tracking

- **#331 — [Make locksmith key duplication server-authoritative](https://github.com/itschase/OwlMTA-2026/issues/331).** The remotely callable handler accepts player, arbitrary item ID/value, and client-controlled cost; it grants before charging and has no proximity or original-key validation. Shared `takeMoney` treats non-positive costs as successful no-op deductions, so a forged cost can bypass payment. Full economic/gameplay impact is runtime-unverified.
- **#332 — [Return an empty faction-key list for players outside factions](https://github.com/itschase/OwlMTA-2026/issues/332).** The UI requests faction interiors for every opener, but the server passes possibly absent faction data directly to `pairs`.
- **#333 — [Scope ped damage protection to intended NPCs](https://github.com/itschase/OwlMTA-2026/issues/333).** A client handler cancels `onClientPedDamage` globally for all peds; intended scope and consequences require runtime verification.
- `cityhall:makeIdCard` uses MTA `client` and current character data, then charges the fixed server-side `$5`. The player cannot select the target or cost through its payload. Its rate/duplicate behavior has not been tested.
- Global remote authorization umbrella: [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1). Inventory authority: [Issue #213](https://github.com/itschase/OwlMTA-2026/issues/213). These broader issues do not replace the locksmith's specific settlement work in #331.

## Modernization opportunities

- Replace hard-coded NPC names with stable service descriptors containing server-owned identity, available action keys, required context, owner resource, and capability/local-policy owner.
- Use the same contextual interaction registry for players, door/vehicle/world-object actions, and future third-eye controls. A button is never proof that the server should accept its event.
- For each action, have the owning resource validate actor, NPC/service session, proximity, interior/dimension, current character, key/item ownership, permission, and authoritative price/state.
- Present clear quotes and receipts for financial actions. Settle cash, items, and durable permissions idempotently; log service denials and outcomes without sensitive values.
- Keep player services, staff actions, and operator maintenance visibly separate. Where an administrative option is added to an NPC, use a specific capability at the owning domain boundary and keep donor entitlements separate.
- Give operators a documented NPC registry/map view with resource owner, world location, service, dependent events, and enable/disable state, once placements are reliably discovered from source and runtime.

## Runtime verification still required

After static review and safe-start preparation, test key duplication with owned/non-owned keys, every supported type, faction permissions, forged item/value/player/cost, zero/negative/large cost, insufficient money, item-store failure, double requests, and player disconnect. Test factionless locksmith access and multiple faction memberships. Test ID-card charge/grant consistency and reconnect behavior. Verify which resource creates each service ped, speech range in interior/dimension contexts, all dispatch destinations, global ped damage suppression, ped death/respawn, resource stop/restart, and missing dependent resources. No MTA server or client was started for this review.
