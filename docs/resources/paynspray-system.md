# `paynspray-system`

## Status

- Active resource; full manifest-script and caller review completed; runtime unverified.
- Discussion: [Script Resource: paynspray-system](https://github.com/itschase/OwlMTA-2026/discussions/257).
- Player-facing vehicle repair, billing, and insurance/employer payment resource; operator commands manage shop locations.

## What it does

The resource loads configured Pay ’n’ Spray locations from the `paynspray` table into repair colshapes and blips. A player entering a repair area receives a quote based on vehicle value and damage, then may pay cash, card, or use eligible insurance/employer coverage. Staff can create and remove repair locations. Temporary vehicles receive free service.

The current invoice is stored as synchronized player element data rather than a durable server-owned invoice record. Payment, receiver credit, banking logs, insurance claims, and repair are separate operations. There are no exports or explicit manifest dependency declarations.

## Player and operator use

- Players drive into a repair colshape, receive a quote, choose a payment path, and wait through a short repair delay.
- `/makepaynspray` and `/delpaynspray` persist location changes and create or remove live elements; `/listpaynspray` reports nearby locations.
- Runtime dependencies include `mysql`, `integration`, `pool`, `anticheat`, `global`, `bank`, `factions`, `logs`, `insurance`, vehicle state, and faction/team availability.

## Source-confirmed risks

- The invoice event does bind the caller with `client == source`, but acceptance does not verify a server-owned invoice, allowed payment type, same quoted vehicle, current damage, originating shop, proximity, expiry, or replay status.
- An unrecognized payment type skips debit branches but still credits faction `4`, consumes the bill, and repairs the current vehicle. This can create money and free repairs.
- The player may switch vehicles between quote and acceptance. The handler repairs the current occupied vehicle rather than the quoted target.
- Insurance debit success is ignored before faction credit, claim creation, and repair. Employer payment debits the payer but its receiver credit is commented out.
- `sprayEffect` can clear engine failure and write a repair log before successful payment; cancellation or an unpaid evaluation can therefore mutate vehicle state.
- Debits, credits, wire transfer, claim, invoice consumption, and repair are not atomic or idempotent. Timers are not safely coalesced, and the delayed callback does not revalidate player/vehicle/invoice state.
- Invoice data is synchronized to clients; there is no authoritative invoice ID, target binding, lifecycle, expiry, or restart recovery.
- Admin location mutations do not reliably check database outcomes. Loaded blips do not receive the saved interior/dimension even though colshapes do.

## Tracked work and target direction

- [Issue #45](https://github.com/itschase/OwlMTA-2026/issues/45) owns insurance quote, claim, and settlement validation.
- [Issue #240](https://github.com/itschase/OwlMTA-2026/issues/240) owns durable and reconcilable insurance accounting.
- [Issue #149](https://github.com/itschase/OwlMTA-2026/issues/149) owns typed financial account identities.
- [Issue #209](https://github.com/itschase/OwlMTA-2026/issues/209) documents shared money-export atomicity and audit limits.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) remains the broader event-authorization parent.
- [Issue #255](https://github.com/itschase/OwlMTA-2026/issues/255) owns the repair invoice, payment, and completion lifecycle.

Proposed direction: create a server-only expiring invoice bound to the player, exact vehicle generation, quote inputs, shop location, allowed payment methods, and a one-use status. Revalidate the same vehicle and context on acceptance; reject unknown payment types; check every payer debit before any receiver credit; and settle the ledger, insurer claim, and repair exactly once. Move repair effects into successful completion and cancel invoices on exit, vehicle switch, disconnect, or restart. Keep location database state and world elements reconciled.

## Runtime verification matrix

All behavior remains runtime-unverified. A future disposable-server pass must cover valid cash/card/insurance/employer repair, unknown and malformed payment types, invoice replay, vehicle switch, shop exit and dimension change, insurer debit failure, employer balance conservation, cancellation without repair effects, disconnect/vehicle destruction during delay, restart with pending invoice, database mutation failure, and interior-shop blip placement.
