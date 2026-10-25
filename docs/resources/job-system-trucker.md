# `job-system-trucker`

## Status

- Active resource; full manifest-script and caller review completed; runtime unverified.
- Discussion: [Script Resource: job-system-trucker](https://github.com/itschase/OwlMTA-2026/discussions/256).
- Review state: source-confirmed findings below; no runtime fix or server test is claimed.
- Player-facing resource for RS Haul delivery work and business supply orders.

## What it does

`job-system-trucker` handles freight loading, route assignment, delivery payout, run progression, and business supply orders. A character with civic job ID `1` uses an eligible truck, loads item `121`, delivers it to an assigned route, receives a weight/vehicle/route-based payout, and returns to the depot to close out accumulated runs. Business owners can order supplies for the business associated with their current interior; faction-owned businesses require finance permission.

Route state, assigned truck, and in-progress runs are primarily memory or element-data state. Durable records include `jobs` progression and `jobs_trucker_orders`; truck cargo is held in vehicle inventory. The manifest does not declare startup dependencies or a readiness contract.

## Player, business, and operator workflows

- **Player:** enter an eligible RS Haul truck, load supplies at warehouse markers, receive a route, deliver cargo, and return to the depot. Client markers describe the route, while the server calculates payout.
- **Business owner:** run `/ordersupplies [money]`; the server should derive the current business and payer, debit the authorized owner/business, and create an order.
- **Staff:** legacy job and route commands can set/delete jobs, set levels, respawn trucks, skip/refetch routes, or manage persistent order markers. Several commands use scripter/admin checks; `/setjob` and `/deljob` also accept supporter status, mixing donor entitlement with staff authority.

## Technical map

- Manifest and loaded script list: [`meta.xml`](../../mods/deathmatch/resources/job-system-trucker/meta.xml)
- Job lifecycle, route and order handling, and business supply submission are split across server scripts; client scripts provide route markers, warehouse interactions, and UI.
- Exports include truck capacity, supply ordering, order insertion, notifications, job display, and job reset helpers.
- Persistence: `jobs`, `jobs_trucker_orders`, `interiors.supplies`, character job state, and vehicle inventory.
- Runtime assumptions include `mysql`, `global`, `anticheat`, `pool`, `item-system`, `job-system`, `hud`, `bank`, `factions`, `interior-manager`, NPC settings, and loaded interior/vehicle data.

## Source-confirmed risks

- Remote truck lifecycle events use event `source` instead of binding the authenticated actor to `client`; they do not establish a server-owned work session.
- Loading checks an occupied job truck, but not the active trucker job, driver seat, warehouse dimension/proximity, or a loading cooldown. Delivery checks route assignment and vehicle/cargo but not destination proximity, dimension, route order, dwell, or travel.
- Warehouse teleport events lack a complete server-side proximity, job, model, and driver-seat check. Route creation can be requested remotely, and marker deletion lacks staff authorization.
- `giveTruckingMoney` accepts a caller-selected vehicle and can remove cargo from it before switching to the caller's occupied vehicle.
- Persistent route deletion checks `routes[5]` where the active route check appears to require `route[5]`. Free-route selection recursively retries without a real bound.
- Cash reward, cargo removal, run count, business stock, order deletion, and route release are separate operations without durable idempotency or reconciliation.
- Business orders persist itemized `orderSupplies`, but restart loading reads a nonexistent `orderWeight` and does not decode the saved supply map. Partial actual orders can credit full requested quantities after a fixed 50-unit cargo removal.
- `jobs_trucker_orders` uses MyISAM, limiting transaction coverage. In-memory assignments and run progress can be lost on an abrupt stop.

## Tracked work and target direction

- [Issue #182](https://github.com/itschase/OwlMTA-2026/issues/182) owns durable and transactional truck supply orders.
- [Issue #254](https://github.com/itschase/OwlMTA-2026/issues/254) owns the server-authoritative player freight work session and route lifecycle.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) is the general remote-event authorization parent; this audit supports a dedicated route-session owner.
- [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3) owns staff/supporter capability separation.
- [Issue #6](https://github.com/itschase/OwlMTA-2026/issues/6) owns schema-engine and transaction modernization.
- [Issue #209](https://github.com/itschase/OwlMTA-2026/issues/209) covers shared direct-money export limitations.

Proposed direction: persist a typed order payload and a server-owned run state machine from depot entry through loading, route checkpoints, delivery, and closeout. Bind every event to `client`, current job, driver seat, exact server vehicle, dimension, proximity, expected stage, and one-use completion key. Replace recursive route search with a bounded candidate list; settle cargo, stock, reward, and order state idempotently; reconcile interrupted sessions at startup. Donor entitlements must not grant staff or route-management authority.

## Runtime verification matrix

All behavior remains runtime-unverified. A future disposable-server pass must cover normal routes, wrong job/seat/dimension, remote load/delivery/teleport, event replay, cross-vehicle cargo deletion, all routes occupied, order restart and partial fulfillment, insufficient funds, database failures at each settlement step, mid-run disconnect/restart, and supporter-only staff command attempts.
