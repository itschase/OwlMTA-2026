# `bank`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded shared, server, client, teller, ATM, and card script plus schema and representative callers.
- Runtime: unverified. The server has not been started.
- Discussion: [Script Resource: bank](https://github.com/itschase/OwlMTA-2026/discussions/100).

## What it does

`bank` provides teller-based personal and organization balances, deposit, withdrawal, transfer, and history; persistent ATM placement; and physical ATM-card issuance, PIN, lock, limit, withdrawal, deposit, transfer, and history flows. Character balances live in `characters.bankmoney`, organization balances in `factions.bankbalance`, transfers in `wiretransfers`, and cards/ATMs in `atm_cards` and `atms`. Live player/team element data mirrors balances.

Teller handlers now bind the actor to MTA `client`, require login, normalize finite positive integer amounts, recheck organization membership plus `manage_finance`, and attempt compensation if a second leg fails. This is meaningful source hardening, but runtime validation and durable settlement remain open.

## Player, staff, and operator use

- A banker ped opens personal and eligible organization banking. A physical item 150 card can be inserted into an ATM for PIN-authenticated actions.
- Card tiers currently impose five-hour in-memory withdrawal limits of $10,000, $50,000, or unlimited. New cards use a default PIN and replacement/recovery/cancel workflows span both inventory and database state.
- Trial Administrators can add/list ATMs; Administrators can delete them. ATM rows are reloaded on resource start and pool registration.
- Operators need `mysql`, `item-system`, `pool`, `global`, `anticheat`, `logs`, `hud`, `factions`, and `cache` ready in compatible order.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/bank/meta.xml`](../../mods/deathmatch/resources/bank/meta.xml)
- Teller implementation: [`s_bank_system.lua`](../../mods/deathmatch/resources/bank/s_bank_system.lua)
- ATM implementation: [`s_atm_system.lua`](../../mods/deathmatch/resources/bank/s_atm_system.lua)
- Shared banking helpers: [`g_atm_functions.lua`](../../mods/deathmatch/resources/bank/g_atm_functions.lua)
- Server exports include card info, bank balance mutation, transaction logging, and ATM effects; shared `hasBankMoney` is the balance predicate.
- Remote surface covers teller operations and ATM/card inspect, insert/eject, issue, lock/unlock, recover/cancel, PIN, deposit/withdraw/transfer, history, and number-copy flows.
- `atms` and `atm_cards` use MyISAM. `card_number` is text without a uniqueness constraint. The manifest's transfer-type documentation is behind active callers.

## Source-confirmed risks

- ATM handlers do not share the teller hardening. Early card events use forgeable event `source`; transaction events accept caller-selected ATM/card context without a server-owned proximity/PIN session. [Issue #205](https://github.com/itschase/OwlMTA-2026/issues/205).
- ATM amount checks are incomplete, so [Issue #76](https://github.com/itschase/OwlMTA-2026/issues/76) remains open despite teller fixes.
- Debit, credit, fee, organization payment, item/live state, and journal writes are independent. Several results are ignored; offline personal transfer has a branch that never performs its intended debit. [Issue #207](https://github.com/itschase/OwlMTA-2026/issues/207).
- Card issue/replacement/recovery/cancel can charge, remove, grant, or persist only part of the result. Universal PIN `0000`, no failed-attempt throttle, restart-reset limits, non-unique card numbers, and stop-time inserted-card removal require redesign. [Issue #206](https://github.com/itschase/OwlMTA-2026/issues/206).
- Balance helpers can mutate live state before SQL succeeds and normalize trusted negative input with `abs`, hiding caller errors.
- `ATM_wiretransfers` is queried although only the canonical `wiretransfers` table was found; related history code also references undefined/global state.
- Negative integers encode organization ledger identity; [Issue #149](https://github.com/itschase/OwlMTA-2026/issues/149) owns typed account references.

## Target direction

Use typed character/organization/system accounts, a single balance repository, immutable idempotent ledger entries, actor/reason/correlation fields, atomic transaction or durable outbox/saga settlement, server-owned teller/ATM/card sessions, parameterized queries, durable rolling limits, versioned card state, named `bank.atm.manage` capability, and operator reconciliation.

Runtime verification must cover cold start and dependency loss; every amount boundary; personal and organization permissions; online/offline transfer parity; failure at every debit/credit/fee/item/journal leg; history privacy; ATM placement/reload; card issue/replace/recovery/full inventory/duplicate/SQL failure; forged actor/ATM/card and PIN abuse; every limit boundary; inserted-card restart; missing fee recipient; and legacy ledger migration.
