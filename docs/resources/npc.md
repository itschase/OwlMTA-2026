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
- Supply ordering accepts client-selected payer, cost, supply map, and shop identity. This overlaps the durable supply contract in #182.
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

## Runtime verification matrix

All runtime behavior remains unverified. Test clean/upgraded database startup; every shop type; owner/keyholder/faction/outsider access; remote/direct management events; forged player/shop/product/price/inventory data; multi-quantity and concurrent purchases; payment/item failure; wage/profit/supply replay; faction-drop stock races; data migration; supporter-only commands; resource restart; and owner notification/supply privacy.
