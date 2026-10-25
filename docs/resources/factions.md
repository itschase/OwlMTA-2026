# `factions`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded server, client, shared, manager, rank, and permission script plus schema and representative callers.
- Runtime: unverified. The server has not been started.
- Discussion: [Script Resource: factions](https://github.com/itschase/OwlMTA-2026/discussions/101).

## What it does

`factions` is the inherited organization system, not merely a gang feature. Numeric types represent gangs, mafias, law, government, medical, other, news, and a type-7 category whose labels currently disagree between shared code and manager UI. It owns membership, ranks, leaders, permissions, wages, notes, phones, assets, finance, duty packages, and duty locations. Other resources use it for public services, criminal groups, employers, vehicles, interiors, banking, chat, advertising, MDC, and staff tools.

A faction is materialized as an MTA team with extensive element data. Membership is many-to-many in `characters_faction`; ranks and permissions live in `faction_ranks`; duty definitions and allowlists span `duty_custom`, `duty_locations`, and `duty_allowed`.

## Player, staff, and operator use

- `/faction` or F3 opens membership UI for roster, online/duty state, MOTD, notes, ranks/wages, invite/kick/quit, member phone/perks/rank, vehicles, properties, finance, and duty configuration where permitted.
- Membership, leader status, rank permission, and active duty are separate authority inputs. Criminal types are structurally excluded from the current public-safety duty-package permission path; future criminal organization gameplay must not require public-service duty.
- Staff manager aliases open faction creation/edit/delete/member tools. Server-side manager authorization has been consolidated and recent duty/rank handlers contain meaningful ownership, membership, permission, and payload hardening; existing Issues #38, #39, #78, #82, and #87 require source reconciliation and later runtime validation.
- Admin commands cover membership/leadership/rank/money, government tax/welfare/budget/license policy, respawn, duty administration, conversion, cleanup, and location tools.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/factions/meta.xml`](../../mods/deathmatch/resources/factions/meta.xml)
- Core server: [`s_faction_system.lua`](../../mods/deathmatch/resources/factions/s_faction_system.lua)
- Manager server: [`faction_manager_s.lua`](../../mods/deathmatch/resources/factions/faction_manager_s.lua)
- Shared registry/exports: [`g_faction_exports.lua`](../../mods/deathmatch/resources/factions/g_faction_exports.lua)
- Rank permissions: [`ranks/s_permissions.lua`](../../mods/deathmatch/resources/factions/ranks/s_permissions.lua)
- Dependencies and consumers span `mysql`, `anticheat`, `pool`, `global`, `integration`, `logs`, `cache`, `duty`, `item-system`, `bank`, `payday`, vehicles, interiors, phone, chat, advertisements, MDC, and public-safety resources. More than 100 active Lua files call this provider.
- Finance uses `factions.bankbalance` and negative faction IDs in `wiretransfers`; assets use `vehicles.faction` and `interiors.faction`.

## Source-confirmed risks

- Type 7 is labeled both Dealership and Mechanic. [Issue #147](https://github.com/itschase/OwlMTA-2026/issues/147) owns the canonical type/policy registry.
- Membership/rank tables lack strong uniqueness and foreign-key integrity. [Issue #148](https://github.com/itschase/OwlMTA-2026/issues/148).
- Deletion spans faction, ranks, membership, duty, vehicles, and interiors without a transaction; vehicle deletion is invoked twice in succession. [Issue #150](https://github.com/itschase/OwlMTA-2026/issues/150).
- Negative ledger IDs require typed ownership. [Issue #149](https://github.com/itschase/OwlMTA-2026/issues/149).
- A blind rename would break manager/events/tables/element data and more than 100 callers; [Issue #146](https://github.com/itschase/OwlMTA-2026/issues/146) owns the compatibility facade.
- Finance/history uses synchronous queries and shared temporaries, risking blocking and cross-request state. [Issue #212](https://github.com/itschase/OwlMTA-2026/issues/212).
- Asynchronous startup exposes no ready/version contract, so consumers can observe partial teams, memberships, ranks, or duty caches. [Issue #211](https://github.com/itschase/OwlMTA-2026/issues/211).

## Target direction

Preserve resource/table/export/event identifiers behind a compatibility adapter while presenting a player-facing Organization service. Add a canonical type/policy/capability registry, immutable membership IDs and DB constraints, server-resolved permissions independent of rank labels, typed accounts/assets, transactional archive workflows with outbox/reconciliation, versioned cache readiness, and immutable privileged-action audits. Criminal groups remain ordinary organizations with suitable policies, not a special global staff class.

Runtime verification must cover outsiders/members/leaders/rank capabilities/staff duty; every organization type; online/offline targets; active/deleted/duplicate/orphan state; every remote with forged actor/org/rank/asset; each permission independently; DB failure at every mutation; provider restart and cache parity; concurrent membership/rank/finance; ledger boundaries; and deletion with loaded/unloaded/occupied assets.
