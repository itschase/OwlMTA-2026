# Economy, Jobs, Payday, and Business: Current State

## Status

Source-reviewed domain map; runtime unverified. This records what the inherited resources currently implement and separates it from the target economy design.

## Current money and ownership model

- Character cash and bank balances live in `characters.money` and `characters.bankmoney` and are also represented as live element data.
- Organization/faction balances are team-element state persisted by faction code.
- `bank` is a partial transaction facade and `wiretransfers` is a journal, but balance changes and journal inserts are not one atomic double-entry ledger transaction.
- Organization participants are encoded as negative faction IDs in parts of the wire-transfer model; [Issue #149](https://github.com/itschase/OwlMTA-2026/issues/149) tracks typed ownership.
- Properties and business premises are primarily `interiors`: residential type 0, business type 1, rental type 3. An interior is not a complete business identity or employer.
- Active `business-system` edits the note attached to a business interior. The archive-only `business` resource contains incomplete historical ownership/employment ideas, lacks checked-in schema, and must not be described as available.

## Payday and recurring obligations

Online, logged-in, non-idle players reaching the saved-time threshold receive the hourly payday flow. It combines:

- Faction wage or welfare
- Bank interest and donor-tier bonus
- Income, vehicle, property, rental, and insurance charges
- License countdown and referral handling
- Vehicle/interior inactivity cleanup and impound maintenance
- A `payday:run` event consumed by NPC-shop wage/debt logic

This is one large timer-driven operation rather than a persisted obligation scheduler. It has no period idempotency key or defined offline settlement policy, and destructive maintenance is coupled to payroll.

Source-confirmed defects include welfare credited before its balance cap is checked, wages credited without confirming employer debit, invalid faction-rental table handling, inconsistent tax/arrears behavior, and a remotely triggerable `payday:run` path that can reach shop accrual. Forced payday commands are repeatable high-value operations under legacy rank checks.

Actionable work is split into [Issue #179](https://github.com/itschase/OwlMTA-2026/issues/179) for idempotent balance-backed payday, [#180](https://github.com/itschase/OwlMTA-2026/issues/180) for the server-only maintenance boundary, [#181](https://github.com/itschase/OwlMTA-2026/issues/181) for fishing/photography rewards, [#182](https://github.com/itschase/OwlMTA-2026/issues/182) for transactional truck orders, and [#183](https://github.com/itschase/OwlMTA-2026/issues/183) for the active business-note mutation and replacement boundary.

## Jobs and production

`job-system` stores one selected civic job on the character and separate progression rows. Active modules include delivery/trucking, taxi, bus, fishing, photography, mechanic, locksmith, and related helpers; stale files not loaded by a manifest are not current gameplay.

Current risks include client-selected job IDs, fishing sale price/recipient, and photography collection value. Bus route progression is tracked by [Issue #77](https://github.com/itschase/OwlMTA-2026/issues/77), with fare debit/recipient binding also requiring review.

`job-system-trucker` provides the clearest production chain: a business interior orders supplies, an order is persisted, a driver delivers an itemized load, supplies increase, and the driver is paid. The restart loader reads `orderWeight` while persistence uses `orderSupplies`, so paid orders can lose their supply map after restart. Claim, delivery, inventory update, order deletion, and reward are not one durable contract.

## Target boundaries

- A typed, balanced, idempotent transaction service with immutable reversals
- A persisted payday/obligation engine with explicit online/offline, arrears, partial-payment, and retry policy
- A business identity separate from premises, with ownership, shares, employment, roles, accounts, inventory, suppliers, contracts, and lifecycle
- A job-session state machine with server-owned job, location, tool/vehicle, route progress, reward formula, and anti-replay key
- Production/delivery contracts that reserve funds and inputs and atomically settle inventory and provider payment
- Bounded offline/background operations based on staffing, stock, capacity, demand, upkeep, and catch-up caps

## Later runtime gate

The matrix must cover exact/repeated/restarted payday periods; welfare/interest/tax/rent/insurance boundaries; solvent/insolvent employers; forced runs; client attempts to trigger maintenance; every active job's eligibility and payout; tampered fish/photo/fare values; supply-order creation, claim, restart, concurrent drivers, delivery, refund, database failure, and reconciliation.

Related: bank Discussion #100, jobs/business Discussion #104, Issues #6, #75-#77, #121, #140, #149, #179-#183, and the [Living Roleplay Systems Blueprint](ROLEPLAY_SYSTEMS_BLUEPRINT.md).
