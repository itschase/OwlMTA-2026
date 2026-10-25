# `donators`

## Status

- Active startup resource; full manifest-script/schema/caller review; runtime unverified.
- Discussion: [Script Resource: donators](https://github.com/itschase/OwlMTA-2026/discussions/235).

## Current behavior

`donators` is the account GameCoin storefront and entitlement cache. It presents purchases/history and grants or toggles perks affecting chat/cosmetics, bills/taxes, capacity/character slots, items/phones/languages, selection/radio/ATM tiers, and inactivity protections. `core.accounts.credits`, supporter tier, `mta.donators`, purchase rows, and live perk/credit element data are separate stores.

Donor/supporter tier, GameCoins, individual perks, staff/GameMaster capability, faction membership/rank/duty, and future Discord grants are distinct authority/value domains.

## Source-confirmed risks

- GUI/activation/update events accept caller-selected donor/source/target; GameCoin transfer trusts separate client total and amount, permitting minting and privacy exposure. [Issue #221](https://github.com/itschase/OwlMTA-2026/issues/221).
- Wallet debit, perk/domain grant, items, phone/language/account state, and history are non-atomic. [Issue #222](https://github.com/itschase/OwlMTA-2026/issues/222).
- Entitlements lack unique identity; duration-zero semantics, expiry cleanup/revocation, restart reload, and typed values drift. [Issue #223](https://github.com/itschase/OwlMTA-2026/issues/223).
- Dynamic pricing can reach zero; key/phone/username flows lack complete server ownership/uniqueness boundaries; staff-on-duty behavior is mixed into a donor helper.

The target separates donor tier, wallet, versioned catalog, purchase fulfillment, and entitlement service; uses a conditional atomic ledger and idempotent fulfillment jobs; and provides named commerce audit/grant capabilities. Runtime tests must adversarially cover every remote/product, transfers/concurrency, failure at every cross-schema/domain leg, pricing boundaries, expiry/restart, duplicate rows, ownership and downstream perk consumers.
