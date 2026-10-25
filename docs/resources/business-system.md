# `business-system`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded script, representative callers, lifecycle cleanup, and schema.
- Runtime: unverified. The server has not been started.

## What it does

Despite its name, the active `business-system` only manages the greeting/note attached to a type-1 business interior. It does not implement business ownership, employment, accounts, inventory, supply, profit, rent, or contracts. Those broader features belong to a separate archived resource and must not be claimed as active functionality.

Players with a matching interior key can use `/setbiznote`, the NPC shop interface, or the interior interface to set or clear the greeting. Trial administrators receive a legacy bypass. Property descriptions, pickups, and the shop UI display the synchronized note.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/business-system/meta.xml`](../../mods/deathmatch/resources/business-system/meta.xml)
- Server implementation: [`s_business_system.lua`](../../mods/deathmatch/resources/business-system/s_business_system.lua)
- The manifest-loaded client file contains no implementation; the real interfaces live in NPC and interior resources.
- Command: `/setbiznote`.
- Remote event: `businessSystem:setBizNote`.
- Persistence: `interior_business`, linked by convention to `interiors.id`; live `business:note` element data.
- Authority inputs: loaded type-1 interior state, item 4/5 keys, and legacy Trial Administrator status.
- Lifecycle is distributed across `interior_load`, `interior_system`, `interior-manager`, NPC, description, and property sale/delete paths.

## Source-confirmed risks

- The remote handler trusts a caller-supplied player element instead of binding the actor to MTA `client`; a malicious caller can attempt to borrow another player's key, dimension, or administrator state.
- The caller also influences the target/mode. The server should resolve the current business from authoritative actor state or a short-lived server-issued interaction token.
- Interior status is dereferenced without defensive validation and target resolution scans all interiors.
- SQL is assembled as text; note normalization covers apostrophes and byte length but not control sequences, color markup, whitespace, encoding, or character count.
- The staff bypass is broad and has no named capability, duty rule, reason, or immutable result audit.
- Concurrent edits are last-write-wins, clearing an absent row fails silently, and MyISAM provides no foreign-key lifecycle protection.
- The empty client script is dead manifest surface.

## Tracked work and target direction

- [Issue #183](https://github.com/itschase/OwlMTA-2026/issues/183) covers authoritative actor/target binding and explicitly separates this small premises-note feature from any future business framework.
- [Issue #140](https://github.com/itschase/OwlMTA-2026/issues/140) concerns the unrelated active-chat dependency on the archive-only broad business resource.
- [Issues #3](https://github.com/itschase/OwlMTA-2026/issues/3), [#46](https://github.com/itschase/OwlMTA-2026/issues/46), and [#150](https://github.com/itschase/OwlMTA-2026/issues/150) cover capability, property, and organization-asset boundaries.

Keep this component small or rename it as an interior/premises profile. A future business domain should be a separate entity with typed ownership, roles, accounts, inventory, contracts, and lifecycle. Runtime verification must cover every UI path, content boundary, spoofed actor/target, keys and staff capabilities, malformed/unloaded interiors, DB/log failure, concurrent editing, restart/reload, sale/delete/recreate, and all display consumers.
