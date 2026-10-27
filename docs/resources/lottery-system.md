# `lottery-system` resource

**Review state:** Full active manifest and direct shop/item/event caller review. Ticket purchase is currently disabled in the shop source; the active resource still runs a daily draw timer. Runtime and deployment configuration remain unverified.

## Current player experience

The resource loads one server script. Players can run `/checkjackpot` and `/checknumber`; both report the stored jackpot/draw number unless the jackpot value is `-1`, in which case they report that someone has already won. The resource schedules a draw every 24 hours. On a draw it deletes every inventory item with ID `68`, announces the draw to logged-in players, chooses a new number from 2 through 48, saves it, and resets the jackpot to zero.

The ticket purchase option (item `68`, price `$75`) is commented out in `npc/g_shopinfo.lua`, and the corresponding purchase flow in `npc/s_generalshop_system.lua` is commented out/disabled. Do not document ticket purchases as currently available. A separate Easter event script uses item `68`, but that script is excluded from the active event-system manifest; treat any collision as conditional on that event being enabled.

## Persistence and connected resources

- The resource reads/writes `settings` rows named `lottery` and `lotteryNumber` through `mysql`.
- `item-system` owns inventory item `68` and exposes the deletion operation called by the daily draw.
- `npc` contains disabled purchase code and calls the lottery exports if restored.
- No staff command or role-gated management interface was identified. The resource exports jackpot/number getters, an update function, a draw function, and a cooldown helper.

The current jackpot update and draw code performs direct SQL updates rather than a single transaction with inventory removal and prize settlement. Keep any future prize payout, ticket ownership, draw result, and audit record in one recoverable server-side settlement design.

## Source-confirmed dormant defect and future design

`canThisPlayerBuyTicket` is exported, but its inspected shop caller is disabled. It uses `getElementType(theBuyer, "account:id")` as the cooldown key. MTA's `getElementType` returns the element type; it does not read element data. If ticket purchasing is re-enabled, callers would share the same cooldown key instead of being tracked by account. This is documented as dormant until sales return in [Issue #398](https://github.com/itschase/OwlMTA-2026/issues/398).

Before restoring sales, define when entries close, prevent early disclosure of winning numbers, validate the active character/account, derive price and ticket number on the server, distinguish ordinary tickets from event rewards, make draw/payout idempotent, and preserve a staff-auditable result history. Ordinary player participation should not require Discord roles; any staff override would use separate local admin checks and a future additive named Discord capability.

## Runtime verification

Verify resource-start persistence, daily timer lifecycle, item deletion scope, draw-number announcement timing, jackpot reset, disabled shop behavior, cooldown semantics, and restart/retry settlement on a disposable server/database before enabling sales. No server or tests were run.

## MTA reference

- [MTA `getElementType`](https://wiki.multitheftauto.com/wiki/GetElementType) documents that the function returns the type of an element.
- [MTA Script security](https://wiki.multitheftauto.com/wiki/Script_security) is the baseline for remote caller identity and server-owned ticket settlement.
