# `npc`

## Status

- Active resource; full manifest-script and representative caller/schema review completed; runtime unverified.
- Discussion: [Script Resource: npc](https://github.com/itschase/OwlMTA-2026/discussions/262).
- Findings are source-confirmed unless explicitly marked proposed or fixed-in-source; no server runtime has been tested.

## What it does

`npc` combines static retail NPCs, player-owned custom shops, faction-drop weapon shops, shop staffing/wages, inventory and supply restocking, owner contact, sales/income reporting, and staff shop management. Customers buy catalog goods; owners or keyholders manage listings and stock; faction members access restricted shops. It also processes shop wages and debt on the shared payday trigger.

## Human workflows

- **Customer:** click a shopkeeper, browse catalog, buy with cash or card, and receive the item/weapon/phone.
- **Business owner/keyholder:** stock goods from inventory/world items, edit/remove listings, manage contacts/capacity, inspect income and wages, pay wages, collect profit, and order supplies.
- **Faction member/leader:** see and buy restricted faction-drop stock; authorized management can configure those items.
- **Staff/operator:** create, move, rename, inspect, reload, or delete shops; run wage and status tools. Several legacy commands mix supporter status with staff-like authority.

## Technical map and persistence

- Manifest: [`meta.xml`](../../mods/deathmatch/resources/npc/meta.xml); server and client scripts cover general shops, custom shops, faction drops, commands, wages, and UI.
- Core persistence: `shops`, `shop_contacts_info`, `shop_products`, `interiors.supplies`, `phones`, and selected `worlditems` paths. Shop logs are cached and periodically saved.
- Core shop tables are MyISAM and have no foreign keys. `pMetadata` depends on a runtime migration rather than the checked-in base schema.
- Runtime dependencies include `mysql`, `data`, `pool`, `global`, `integration`, `anticheat`, `bank`, `factions`, `logs`, `item-system`, `item-world`, `weapon`, `interior_system`, and others; runtime start order is not proven by the checked-in config snapshot.

## Source-confirmed findings

- Custom-shop add/edit/remove events accept client-selected player/shop/product values without consistent `client` binding, owner/key/faction-finance checks, proximity, or authoritative inventory validation.
- Faction-drop create/remove/config events lack the server-side authorization implied by UI checks. Purchases can mutate money/items before stock decrement success, allowing oversell or inconsistent settlement.
- Contact, capacity, sales-log, and owner-notification events can be directly invoked without a consistent owner or finance boundary; notification text can be injected.
- Baseline supply ordering accepted client-selected payer, cost, supply map, and shop identity. The current source changes close those input-trust paths as described below; durable cross-resource settlement remains tracked by #182.
- Shop open/static purchase does not fully recheck login, proximity, dimension/interior, or shop lock. Standard purchases debit before confirmed item delivery, and several downstream writes are unchecked/non-atomic.
- The existing Issue #75 purchase hardening remains incomplete: a quantity reservation can delete the entire multi-unit listing; restoration creates a new row identity and successful purchase does not decrement quantity correctly.
- `shop:removeMeFromCurrentShopUser` can clear a caller-selected player/shop lock. `/checksupply` has its scripter restriction commented out and discloses stock to players in the same dimension.
- Shared `getFactionID` references undefined variables. `pMetadata` migration and MyISAM readiness remain deployment assumptions.

Some paths are fixed or partially hardened in source: `shop:solvePendingWage` binds `client`, derives the interior/payer, and checks owner/key/finance permission; `shop:customShopBuy` binds the actor and reloads item/price from SQL. The residual quantity defect remains. None of these source fixes is runtime-verified.

## Tracked work and target direction

- [Issue #261](https://github.com/itschase/OwlMTA-2026/issues/261) owns shop management and faction-drop authorization and stock safety.
- [Issue #75](https://github.com/itschase/OwlMTA-2026/issues/75) owns the custom-shop purchase boundary and residual quantity behavior.
- [Issue #182](https://github.com/itschase/OwlMTA-2026/issues/182) owns durable business supply ordering and delivery.
- [Issues #48/#180](https://github.com/itschase/OwlMTA-2026/issues/180) own payday/shop-wage triggers and maintenance.
- Issues #1/#3/#6/#121/#149/#209 cover general remote authorization, named capabilities, schema readiness, typed financial accounts, and money API limitations.

Proposed direction: centralize shop-interaction validation and per-action management authorization. Derive actor, property, organization, item, price, quantity, payer, and inventory on the server. Use conditional stock reservations with idempotent delivery/payment and compensation/reconciliation. Audit listing, faction-drop, wage, inventory, finance, and staff changes. Donor tiers must remain separate from staff authority.

## Command use cases and non-command alternatives

| Command(s) | Source-confirmed use and current authority | Fitting alternative |
|---|---|---|
| `/checksupply`, `/checksupplies` | Stock/business guidance; ownership and key checks differ between the handlers. | Owner management panel showing server-filtered stock for the current business. |
| `/makeshop` | Trial Administrator creates a shop at the current position. | Audited staff shop editor with type, skin, name and placement preview. |
| `/delshop`, `/deleteshop`, `/delnearbyshops`, `/delnearbynpcs` | Trial Administrator deletion, including a confirmation path for custom-shop inventory. | Staff editor with exact target, impact summary, reason and confirmation. |
| `/nearbyshops`, `/nearbynpcs` | Owner, Trial Administrator, or Supporter inspects nearby shops. | Property panel for the owner and a separate capability-gated staff inspector. |
| `/moveshop`, `/movenpc` | Owner, Trial Administrator, or Supporter moves a shop inside the interior. | Owner placement mode plus a separately authorized staff correction mode. |
| `/gotoshop` | Trial Administrator teleports to a shop. | Staff search panel with an audited teleport action. |
| `/reloadshop`, `/reloadnpc`, `/reloadped` | Trial Administrator reloads one shop from SQL. | Staff diagnostics panel showing load and dependency results. |
| `/renameped`, `/renamenpc`, `/renameshop` | Trial Administrator or Supporter renames a shop. | Owner management for owned NPCs and a separate staff correction action. |
| `/resetshopwage`, `/showallcustomshops` | Trial Administrator finance reset and global inspection. | Staff finance/diagnostics panel with before/after values and audit reason. |
| `/forceupdateshopwage`, `/convertshopgenerics`, `/saveshopconfigs` | Scripter/admin maintenance or migration. | Restricted console/maintenance job, not a normal player or Discord workflow. |

## Current focused source changes

**Fixed in source, runtime unverified:** `shop:solvePendingWage` now derives its actor from MTA [`client`](https://wiki.multitheftauto.com/wiki/Client), verifies the shopkeeper, active business, matching interior/dimension, five-unit proximity, owner/key or faction `manage_finance` access, and server-held wage. A failed wage write refunds the player before success effects.

`updateShopSupplies` now ignores the caller-supplied player, interior ID, total price, and shopkeeper name. It derives the interior and shopkeeper, rebuilds allowed product keys and prices from the loaded server catalog, validates finite positive integer quantities, and computes cost server-side. Immediate stock is persisted before the trucker settlement call; if settlement fails, the previous stock JSON is restored. A one-unit order has no driver-delivery half, so it uses the same trucker payer authorization (owner bank or faction bank) without creating an empty delivery contract. The former second debit is removed.

This is compensating source logic, not an atomic cross-resource transaction. Rollback itself can fail, and the interior stock row and trucker order ledger still have separate lifecycles. Shop selection among multiple shopkeeper peds in one interior, DB write semantics, and all settlement outcomes require runtime verification.

## Discord authorization boundary

**Proposed only:** no Discord authorization consumer exists in this resource.

- Action-specific global staff capabilities could include `shop.create`, `shop.delete`, `shop.teleport`, `shop.reload`, `shop.finance.reset`, and narrowly scoped `shop.inspect`. These are staff powers, never donor/supporter tiers.
- Supporter/donor status may grant cosmetic or convenience entitlements only. It must not authorize moving, renaming, inspecting, financing, or mutating another business.
- Owner, keyholder, faction membership, `manage_finance`, current interior, proximity, shop state, payer, item, and price remain local server-derived checks. Discord must not substitute for them.
- Future capability checks belong at the existing server command handlers in `s_generalshop_system.lua`, `s_custom_shop.lua`, `functions_s.lua`, `s_migrations.lua`, and `faction_drop_s.lua`, immediately before target lookup or mutation. Every remote event must still bind `client` and repeat local state checks per MTA's [`Script security`](https://wiki.multitheftauto.com/wiki/Script_security).

## Runtime verification matrix

All runtime behavior remains unverified. Test clean/upgraded database startup; every shop type; owner/keyholder/faction/outsider access; remote/direct management events; forged player/shop/product/price/inventory data; multi-quantity and concurrent purchases; payment/item failure; wage/profit/supply replay; faction-drop stock races; data migration; supporter-only commands; resource restart; and owner notification/supply privacy.
