# `achievement`

## Status

- Active resource; its manifest loads the client/server reward scripts plus image and sound assets.
- Full manifest, direct-caller, persistence, and workflow review completed from source.
- Tracked startup configuration includes it; live startup and runtime behavior are unverified.
- No MTA server or database was started for this review.
- [Discussion #285](https://github.com/itschase/OwlMTA-2026/discussions/285).

## What it actually does

Despite its name, the resource is a GameCoin reward and notification service, not a durable achievement/unlock system. `awardPlayer` updates `core.accounts.credits`, updates the live player's `credits` element data, displays a toast and sound, and attempts a generic `donators:addPurchaseHistory` row. There is no stable achievement catalog, unlock table, prerequisite/progress model, one-time policy, or player achievement history.

The current direct reward callers are the lead-admin `/givegc` command family in `admin-system` and a 75-GameCoin milestone awarded by `report` after 30 handled reports.

## Player experience

On award, a 400×70 banner appears near the lower-right screen edge, uppercases the title, displays the description and optional GameCoin amount, plays `achievement.mp3`, and fades after 15 seconds. A later award closes/replaces the existing banner; multiple persistent awards are not queued for presentation.

## Staff and operator use

There are no commands in this resource. Staff grants route through `admin-system` and require its lead-admin predicate; the report counter is advanced through normal report handling. A `/setsavedreports` command in `report` can alter live milestone progress and is hard-coded to account ID 1. All of these are current legacy workflows and must migrate to named capabilities and audited domain operations.

The resource exposes a server `awardPlayer(thePlayer, title, desc, gc)` function, client `displayAchievement(title, desc, gc)`, and client/server `playSoundFx` helpers. Those APIs do not validate a durable achievement definition or idempotency key.

## Persistence and dependencies

- Balance: `core.accounts.credits`.
- Generic donor purchase history: `mta.don_purchases`, through `donators:addPurchaseHistory`.
- Report progress: `mta.account_details.adminreports_saved`, loaded during account login.
- The balance and report progress are in separate databases; purchase history is a third non-atomic write.
- Direct dependencies include `mysql`, `donators`, and client GUI/audio. Callers add `admin-system`, `integration`, `logs`, `report`, `account`, and `anticheat`.

The current result of these operations is not one transaction: SQL balance, live element data, generic history, report progress, staff logs, and announcements can succeed or fail independently.

## Source-confirmed risks and tracker ownership

- The server registers `awardPlayer` with remote triggering enabled and trusts caller-supplied player, title, description, and reward amount. A client can attempt to mint arbitrary GameCoins for itself or another player. Existing [Issue #221](https://github.com/itschase/OwlMTA-2026/issues/221) is the exact authorization owner; no duplicate minting issue was opened.
- The admin grant and report milestone call path ignore settlement results; live balance and generic history are separate writes. Existing [Issue #222](https://github.com/itschase/OwlMTA-2026/issues/222) owns GameCoin settlement/ledger durability.
- Report progression resets its saved counter before reward success is known, while the reward is written in the separate `core` database and progress in `mta`. A restart or DB failure can lose or repeat a milestone. This distinct progression/idempotency boundary is tracked by [Issue #279](https://github.com/itschase/OwlMTA-2026/issues/279).
- `/setsavedreports` is a hard-coded account-ID administrative path with weak bounds and no immediate persistence. Named capability and staff-operation audit work remains related to [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3).
- `/gunserial` is also accessible to supporters, disclosing weapon source/creator identity; this belongs to the broader capability and staff/donor separation design, not the achievement resource.
- Other source defects include unchecked DB results, no idempotency/correlation, no reward amount/text validation, and live/DB divergence opportunities.

These findings are static. No exploit or runtime failure was exercised.

## Modernization direction

Split durable reward settlement from cosmetic notification. Define server-owned reward records with stable IDs, policy, scope, amount, and idempotency keys; credit through a shared GameCoin ledger; return a structured committed/duplicate/ineligible/error result; update live balance and display only from committed state. Persist report milestone progress and reward intent so reconnect/restart cannot lose or duplicate a reward.

If the product wants real achievements, add a versioned registry of account- or character-scoped unlocks, server-evaluated prerequisites, repeatability/cooldowns, earned timestamps, progress history, and authorized correction/revocation. The legacy free-form toast can remain a presentation adapter, not the achievement database or authority mechanism.

## Runtime verification still required

After safe-start preparation, verify direct client attempts to invoke `awardPlayer`, malformed/negative/fractional/extreme reward values, invalid/offline target, missing account/live balance, each DB/history failure point, valid staff grant, duplicate idempotency key, 29→30 report milestone, crash between award and progress persistence, recovery/reconnect, and rapid multiple banners. All behavior remains runtime-unverified.
