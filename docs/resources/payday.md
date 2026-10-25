# `payday`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded script, callers, persistence, and schema.
- Runtime: unverified. The server has not been started.

## What it does

`payday` is the legacy hourly settlement and maintenance resource. It pays eligible online characters faction wages or welfare, bank interest, and donor bonuses; deducts income, vehicle, property, insurance, and rent charges; advances selected licenses and hours; awards referrals; and displays a payslip. The same hourly pass also taxes faction assets, scans inactive vehicles and interiors, clears impounds and shell casings, and tells NPC shops to accrue wages.

This is not an offline payroll or durable obligation engine. Its schedule, work queue, and accounting period exist only in memory.

## Player, staff, and operator use

- A logged-in, non-idle character becomes eligible with at least 58 saved minutes. `/timesaved` shows progress.
- Recognized on-duty faction work uses the current rank wage; otherwise the resource applies welfare. Interest, donor perks, taxes, insurance, and rent are then calculated.
- `/forcepayday` and `/forcepaydayall` use legacy administrator predicates and bypass the ordinary eligibility gates.
- Government faction ranks can use tax and welfare commands implemented by `factions`; the configured welfare value is read here.
- Checked-in settings enable inactivity scanning for vehicles and interiors. Policy, scheduling, cleanup, and payroll are therefore coupled in one failure domain.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/payday/meta.xml`](../../mods/deathmatch/resources/payday/meta.xml)
- Settlement: [`s_payday.lua`](../../mods/deathmatch/resources/payday/s_payday.lua)
- Tax helpers: [`s_taxes.lua`](../../mods/deathmatch/resources/payday/s_taxes.lua) and [`taxes_g.lua`](../../mods/deathmatch/resources/payday/taxes_g.lua)
- Client payslip: [`c_payday.lua`](../../mods/deathmatch/resources/payday/c_payday.lua)
- Commands: `/timesaved`, `/forcepayday`, `/forcepaydayall`; tax/welfare policy commands are owned by `factions`.
- Export: `getPropertyTaxRate` on client and server.
- Major dependencies: `mysql`, `global`, `factions`, `bank`, `donators`, `insurance`, interior and vehicle systems, `cache`, `datetime`, `announcement`, `item-system`, `hud`, and `npc`.
- Persistence touches `characters`, `settings`, `wiretransfers`, `interiors`, `vehicles`, accounts, and donor purchases. `wiretransfers` is a journal, not a balanced ledger.

## Source-confirmed risks

- Welfare is credited before the $25,000 eligibility cap is applied, so the displayed denial does not prevent the credit.
- Faction wages are credited before the employer debit, and debit failure is ignored.
- Faction rental values are stored as tables but later compared and passed as numbers, creating a Lua type-error path.
- The remotely callable server `payday:run` event allows clients to repeat NPC shop wage/debt processing.
- Forced runs can overlap scheduled or earlier coroutine batches; there is no persisted period key, idempotency, catch-up, or recovery cursor.
- Balance changes, journal inserts, insurance transfers, eviction, notifications, and character saves are independent operations whose results are often ignored.
- The welfare setter persists the old value instead of the requested amount, so a restart can restore stale policy.
- Personal obligations process only loaded assets and online players, allowing offline avoidance; multi-property insufficient-funds ordering is not deterministic.
- Inactivity destruction and operational cleanup run inside payroll, and old messages still refer to absent UCP/GC protections.

## Tracked work and target direction

- [Issue #179](https://github.com/itschase/OwlMTA-2026/issues/179): idempotent, balance-backed settlement.
- [Issue #180](https://github.com/itschase/OwlMTA-2026/issues/180): server-only maintenance and protected shop wage accrual.
- [Issue #48](https://github.com/itschase/OwlMTA-2026/issues/48): existing payday/shop event audit.
- [Issue #149](https://github.com/itschase/OwlMTA-2026/issues/149): typed account ownership instead of negative faction identifiers.

The target is a persisted obligation service with explicit periods, typed double-entry accounts, atomic settlement and journal records, deterministic arrears/eviction policy, separate maintenance schedules, named capabilities, dry-run/reconciliation tools, and explicit offline/catch-up rules.

Runtime verification must cover scheduler/restart overlap, all eligibility boundaries, welfare and wage funding, interest and rounding, personal/faction assets, rent ordering, insurance failure, atomic failure injection, forced-run authorization, client event abuse, referral idempotency, and every payslip state.
