# `saveplayer-system`

## Status

- Active startup resource; full manifest-script review; runtime unverified.
- Discussion: [Script Resource: saveplayer-system](https://github.com/itschase/OwlMTA-2026/discussions/232).

## Current behavior

This one-script server resource increments non-idle online time each minute and saves a limited character-core snapshot hourly, on quit, on local `savePlayer`, through `/saveme`, or through lead-admin `/saveall`. Account character change fires `savePlayer` before clearing state. It does not own money, bank, inventory, factions, jobs, licenses, appearance, or most subsystem persistence.

- Source: [`s_saveplayer_system.lua`](../../mods/deathmatch/resources/saveplayer-system/s_saveplayer_system.lua)
- Writes position, rotation, health, armor, world context, last login/area, time, alcohol, and account last login.
- Dependencies include `mysql`, protected player state, `account`, `freecam-tv`, and every listener using the shared save event.

## Source-confirmed risks

- The global hourly queue is never cleared; every hour appends players and reschedules historical entries. [Issue #216](https://github.com/itschase/OwlMTA-2026/issues/216).
- Two DB writes are independent and ignored; no dirty state, version, retry, stop flush, or repair exists. [Issue #217](https://github.com/itschase/OwlMTA-2026/issues/217).
- Every save synthetically fires `onVehicleExit` without a real exit, repeating unrelated lifecycle effects. [Issue #218](https://github.com/itschase/OwlMTA-2026/issues/218).
- Concurrent manual/hourly/quit/change writes are last-writer-wins; override coordinates can disagree with saved area.

The target is a revisioned, deduplicated per-character persistence coordinator with explicit domain ownership, pre-switch flush barrier, observable durable outcomes, graceful shutdown, and unclean-start reconciliation. Runtime validation must cover several hourly cycles, every save trigger, DB failure/latency, character change, vehicles, override modes, provider restart, graceful stop, crash, and field-by-field reload.
