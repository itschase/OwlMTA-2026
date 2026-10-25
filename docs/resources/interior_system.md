# `interior_system`

## Status

- Active `[interior]` startup resource; full manifest-script/schema/caller review; runtime unverified.
- Discussion: [Script Resource: interior_system](https://github.com/itschase/OwlMTA-2026/discussions/237).

## Current behavior

`interior_system` is the property/interior aggregate for entrances/exits/dimensions, houses/business/government/rentals, character or organization ownership, keys/keypads/locks, purchase/sale/transfer, previews, settings, safes, protection/activity, shouting, and destructive cleanup. `interior_load` builds runtime elements; this resource mutates state and triggers reload/convergence.

- Manifest: [`mods/deathmatch/resources/%5Binterior%5D/interior_system/meta.xml`](../../mods/deathmatch/resources/%5Binterior%5D/interior_system/meta.xml)
- Dependencies include database/pool/load, money/items/factions, logs/cache, vehicle/freecam/HUD, and many property-owned shop/ATM/elevator/object resources.

## Source-confirmed risks

- Purchase and keypad paths trust client property/cost/type/state or keypad bypass inputs; [Issue #46](https://github.com/itschase/OwlMTA-2026/issues/46).
- Standard entry/preview lacks server-issued proximity/target context. [#228](https://github.com/itschase/OwlMTA-2026/issues/228).
- Settings mutation bypasses UI authorization and trusts target/data. [#229](https://github.com/itschase/OwlMTA-2026/issues/229); persistence-load is #81.
- Occupant eviction uses invalid array/player keys. [#230](https://github.com/itschase/OwlMTA-2026/issues/230).
- Purchase/transfer/sale/cleanup spans money, owner, keys, occupants, safes and dependent assets without recoverable transaction; seller payment can precede failed government debit. [#231](https://github.com/itschase/OwlMTA-2026/issues/231).

The target preserves compatibility behind a Property service with server interaction contexts, authoritative pricing/state, typed owner/access grants, versioned settings, idempotent core settlement, and durable cleanup outbox/reconciliation. Runtime tests must cover every property/actor/access/payment/state combination, forged target/cost/context, concurrency/replay, dependency failure at every leg, ownership transfer, occupant cleanup, restart/crash and cache parity.
