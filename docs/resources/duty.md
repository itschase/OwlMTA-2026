# `duty`

## Status

- Active startup resource; full manifest-script/source-caller review; runtime unverified.
- Discussion: [Script Resource: duty](https://github.com/itschase/OwlMTA-2026/discussions/234).

## Current behavior

`duty` materializes faction-defined duty locations/packages and lets eligible members use `/duty` to select a kit and appearance or go off duty. `factions` owns configuration and member package perks; this resource grants/removes equipment, armor/weapons and appearance, persists `characters.duty`, and emits duty lifecycle events.

Membership, rank permission, assigned package, and active duty are separate. Discord global capabilities must not manufacture any of them.

- Manifest: [`mods/deathmatch/resources/duty/meta.xml`](../../mods/deathmatch/resources/duty/meta.xml)
- Dependencies: `factions`, `mysql`, `global`, `item-system`, `anticheat`, and `pool`.
- Current package/item/location JSON and MyISAM tables lack versioned relational integrity.

## Source-confirmed risks

- Runtime request does not fully server-check login, location/vehicle, world context, or package availability; item/skin/armor/weapon payloads can be caller-influenced. [Issue #87](https://github.com/itschase/OwlMTA-2026/issues/87).
- Item/SQL results are ignored; off-duty removes matching ordinary items, base appearance is overwritten, package ID is globally ambiguous, and restart has no issuance reconciliation. [Issue #220](https://github.com/itschase/OwlMTA-2026/issues/220).
- Nil/global-state assumptions and replicated full package tables increase restart and disclosure risk.

## Authorization and Discord boundary

`duty` consumes eligibility and configuration from `factions`; keep character membership, rank permissions, assigned package, active-duty state, location, and asset ownership as local gameplay checks. Discord-derived named capabilities may gate only global staff configuration surfaces. The separate `/dutyadmin` editor currently opens for lead admins, scripters, or FMT leaders, but its `dutyAdmin:Save` remote handler does not repeat that staff authorization and accepts replacement tables without validating their rows. This editor is not the same authority path as a faction member selecting an allowed duty package; track it under [Issue #344](https://github.com/itschase/OwlMTA-2026/issues/344).

Faction-linked permission residuals for package assignment and configuration are tracked in [Issue #39](https://github.com/itschase/OwlMTA-2026/issues/39) and overlapping [Issue #53](https://github.com/itschase/OwlMTA-2026/issues/53). These are static findings only; runtime verification remains pending.

The target uses typed faction/package/version references, canonical server kit reconstruction, issuance-owned item provenance, reversible appearance overlays, compensating fulfillment, normalized schema, and a readiness handshake with factions. Runtime tests must cover every authority combination, duplicated package IDs, forged kit/skin/location, full inventory and partial failure, owned identical items, death/logout/restart, package edits, and downstream duty consumers.
