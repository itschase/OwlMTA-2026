# `advertisements`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified.

## What it does

`advertisements` combines a browser-based classifieds board, paid global advert broadcasts, automatic taxi/bus adverts, and a physical vehicle-auction system with bidding, buyout, ownership transfer, and key pickup.

## Player use

For classifieds, the browser requests a page or record. A player creates or edits an advert with name, section, phone, address, text, and expiry. Eligible creators, faction members, or staff manage it. A pushed advert broadcasts globally after its cooldown and normally costs money.

For vehicle auctions, the client UI expects an owner or authorized faction member to drive an eligible vehicle to the auction, submit it, and leave it on the floor. The current server handler does not independently establish all proximity, occupancy, location, actor, or submitted-value conditions, so this is intended UX rather than a trusted invariant. Other players bid or buy out. Completion is intended to transfer money and ownership, send durable notifications, and let the winner collect keys.

Taxi and bus job adverts broadcast periodically when eligible workers are active.

## Staff and operator use

Trial administrators can manage and push adverts under the legacy rules. The general management path also includes creators and members of an advert's faction. Vehicle sales write vehicle and general database logs, but this resource has no dedicated classified moderation history.

Primary tables include `advertisements`, `vehicle_auctions`, `vehicles`, `vehicle_logs`, and `insurance_data`. Included table definitions use MyISAM and belong in the broader migration work. Dependencies include `mysql`, `bank`, `global`, `factions`, `pool`, `announcement`, `item-system`, `anticheat`, `datetime`, `cache`, `logs`, `hud`, `integration`, `donators`, `account`, `rightclick`, and `realism`.

## Technical map

- Manifest: [`mods/deathmatch/resources/advertisements/meta.xml`](../../mods/deathmatch/resources/advertisements/meta.xml)
- Classified server/client/browser scripts and vehicle-auction scripts are all manifest-active.
- Auction completion calls the durable notification export in `announcement`.

## Known risks and next work

- [Issue #130](https://github.com/itschase/OwlMTA-2026/issues/130) covers classified actor/schema validation, faction attribution, record existence, server-derived price/cooldown, and failure-safe persistence/broadcast.
- [Issue #131](https://github.com/itschase/OwlMTA-2026/issues/131) covers auction result checks, numeric/proximity/state validation, concurrency, atomic settlement, ownership, keys, insurance, and audit.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) remains the parent remote-event audit; [Issue #6](https://github.com/itschase/OwlMTA-2026/issues/6) owns schema modernization.

Runtime verification must cover classified paging/ownership/faction/staff/cooldown/payment, missing/expired records, job adverts, auction submission/capacity, concurrent bid/buyout, cancellation/expiry, faction settlement, notification, transfer, insurance, and key pickup in a disposable database.
