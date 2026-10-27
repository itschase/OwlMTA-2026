# `interior-manager`

## Status

- Active resource; full manifest, caller, command, and interaction source review completed; runtime unverified.
- Discussion: [Script Resource: interior-manager](https://github.com/itschase/OwlMTA-2026/discussions/264).

## What it does

`interior-manager` supplies the staff property catalog and lifecycle controls. `/interiors` and `/ints` let staff search, inspect history/notes/occupants, teleport, soft-delete, restore, permanently remove, force-sell, and toggle properties. It also exposes `addInteriorLogs` for other resources. Owners can transfer a property to their faction when they meet the existing ownership and `manage_interiors` checks.

Supporters and mapping roles receive limited inspection/navigation or lifecycle options under legacy role predicates. This makes role policy and privacy part of the resource contract, not merely UI details.

## Commands and interaction opportunities

The manifest loads `s_interior_manager.lua`; these command handlers are source-confirmed in that active script. The catalog command already opens a multi-tab staff window, so the useful modernization is to make that existing interface discoverable from a staff control center and complete workflows in the right context—not to build a duplicate interior dashboard.

| Command | Current audience and task | Current entry point | Future interface and authorization direction |
|---|---|---|---|
| `/interiors`, `/ints` | `integration:isPlayerAdmin`; opens the complete interior catalog. | Command opens `createIntManagerWindow`; the existing UI has search and management actions. | Link the existing catalog from a staff control center and improve search/filter/map context there. Keep `/interiors` and `/ints` as fast aliases. Gate catalog data with a narrow proposed capability such as `interiors.catalog.read`; continue server-side role/capability, actor, and query checks. |
| `/checkint [ID]`, `/checkinterior [ID]` | Trial Admin **or Supporter**; opens details including ownership, logs, notes, and occupants. Omitting or supplying an invalid ID falls back to the player's current dimension. | Command opens the details window; some catalog row actions also request it through `interiorManager:checkint`. | Open details by selecting a catalog row and offer a nearby-property shortcut where appropriate. Review the existing Supporter access because this view exposes account/character, occupant, and staff-note data: donor tier must not silently become staff authority, and any donor entitlement must be a separate, privacy-reviewed policy. A proposed staff capability could be `interiors.inspect`; do not use it as a substitute for local property/context checks. |
| `/setintfaction [Faction Name or Faction ID]` | `integration:isPlayerAdmin`; while inside a property, transfers it to the selected eligible faction, unlocks it, changes key items, reloads it, and logs/notifies the transfer. | Server command, scoped to the property resolved from the actor's current interior. | A property details workflow could search/select the faction, preview the property and resulting key/ownership changes, then require confirmation. Keep a staff shortcut if it remains useful. A proposed capability such as `interiors.transfer.staff` must be checked server-side through Owl's adapter boundary; actor identity, current property, faction existence/eligibility, and recoverable persistence remain local checks. |
| `/setinttomyfaction [Faction ID]` | Current character must own the property and hold that faction's `manage_interiors` permission; the player must be inside the property and the faction purchase rule must pass. | In-property command performs the ownership transfer. | Evaluate a guided transfer action in the property/ownership interface with clear faction and key consequences. This is character ownership plus faction-rank authority; it should not require a global Discord staff capability or let a Discord role replace local faction membership/rank checks. Keep the command available for experienced users. |

These are proposed interface improvements, not implemented controls. Source line anchors: `s_interior_manager.lua` registers the catalog at lines 31–38, details at 150–215, and transfer commands at 275–400. The MTA [`addCommandHandler` reference](https://wiki.multitheftauto.com/wiki/AddCommandHandler) describes server command arguments and notes that a console invocation can have no player source; runtime/console behavior for these handlers has not been verified. Cross-resource command comparison is tracked by [Issue #327](https://github.com/itschase/OwlMTA-2026/issues/327).

## Technical workflow and persistence

- Manifest loads server manager, client manager, audit-log server code, and shared definitions on both realms; no dependencies are declared.
- Catalog and search query `interiors`, `characters`, and `factions`, then send results to the client. Inspection loads property data, `interior_logs`, `interior_notes`, and characters whose saved dimension matches the property.
- Notes are capped at 500 characters and escaped. Lifecycle wrappers validate IDs and delegate to `interior_system` commands, which repeat authorization/state checks.
- Ownership transfer updates `interiors`, deletes/reissues keys, reloads the property, logs, and notifies admins.
- Core tables are MyISAM and have no foreign keys. Destructive property/key/log/runtime changes are not atomic.
- Server HTTP export `addInteriorLogs` is marked `http="true"`.

## Source-confirmed findings

- `addInteriorLogs` accepts interior, actor, action text, and `clearPreviousLogs` without caller provenance or input bounds. The option can erase prior logs; permanent property removal also deletes audit rows. Effective reach depends on MTA HTTP/ACL configuration.
- Catalog/search SQL select `interiors.y` twice instead of `z`, and the positional result mapping expects aliases that are unlikely to match. Owner username is read without being selected. Search exposes account IDs inconsistently.
- The full catalog is synchronous and unpaged. Supporter inspection can reveal property history, internal notes, owner/account links, occupant identities, and last-login information.
- Note changes are scoped, escaped, and authorized, but cannot clear a note and the client reports success before receiving a server result.
- Manager action wrappers generally bind `client`, validate positive IDs, and enforce their intended minimum role; downstream commands recheck. This is source-confirmed protection, not runtime validation.
- Ownership transfer spans SQL, keys, runtime state, logs, and notifications without transaction, version, idempotency, or repair workflow. Stale catalog views have no structured result/refresh contract.

## Tracked work and target direction

- [Issue #64](https://github.com/itschase/OwlMTA-2026/issues/64) owns manager/staff gating and should include role-scoped catalog privacy.
- [Issue #231](https://github.com/itschase/OwlMTA-2026/issues/231) owns non-atomic property transfer, sale, and cleanup.
- [Issue #22](https://github.com/itschase/OwlMTA-2026/issues/22) owns the broad HTTP/ACL identity boundary.

Proposed direction: remove HTTP exposure or make the log writer narrow, append-only, and provenance-backed. Replace positional arrays with named records, repair query fields, page/filter results, rate-limit search, and return structured success/failure. Separate supporter inspection from destructive permissions and make ownership transfer versioned and recoverable with durable deletion tombstones.

## Runtime verification matrix

All runtime behavior remains unverified. Test role boundaries; empty/large catalog; query correctness; privacy by role; notes including clear/update/failure; concurrent stale actions; soft-delete/restore/remove/force-sale; ownership transfer at each failure point; and HTTP/ACL log-forgery/erasure cases.
