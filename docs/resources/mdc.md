# `mdc`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded shared, server, client, GUI, and APB-overlay script plus schema and integration callers.
- Runtime: unverified. The server has not been started.

## What it does

`mdc` is the legacy public-safety records interface. It searches people, vehicles, plates/VINs, and properties; presents warrants, free-text crimes, licenses, calls, impound and speed-camera history; manages APB/ANPR alerts, stolen status, toll controls, pilot records, and MDC user accounts.

It is not a case, evidence, court, or chain-of-custody service. Its current warrant is one mutable wanted flag plus free text; crimes are append/delete text rows; APB and ANPR are separate global lists. The proposed investigation framework is not implemented.

## Player, staff, and operator use

- Ordinary players have no intended access. Entry is normally supplied by a vehicle/computer integration; `/mdc` is commented out.
- An MDC user needs an account in `mdc_users`, an active faction duty, and matching organization permissions in `mdc_groups`. `/apblist` toggles the in-vehicle overlay.
- Level-2 MDC users see account-administration controls, but that restriction is currently client-side only.
- Lead administrators/scripters can create accounts; FAA, Trial Administrator, or scripter paths refresh pilot licensing; two migration commands are scripter-only.
- Donor/supporter status is not an authority predicate in this resource.

## Commands and interaction opportunities

| Command(s) | Current audience and use | Current entry point | Future direction and Discord boundary |
|---|---|---|---|
| `/apblist` | Toggles the client's APB overlay. | The in-car/APB presentation is already a contextual overlay. | Keep the shortcut and add the toggle to the vehicle/computer public-safety interface if needed. It must not reveal records to a player who lacks the server-side APB view policy; the overlay switch itself is presentation, not authorization. |
| `/makemdcaccount [target] [organization] [level]` | Lead Admin or Scripter creates, updates, or removes a character's MDC access level. | Command-based staff provisioning; an account-management GUI also exists. | Improve the existing staff form with target/organization/level preview, explicit confirmation, and audit detail. A proposed `mdc.accounts.manage` Discord capability belongs at the server mutation boundary, with current staff hierarchy and organization scope retained as local checks. |
| `/refreshpilotlicenses` | Eligible aviation-faction leader, Trial Admin, or Scripter refreshes the shared pilot-license cache. | Operator/staff maintenance shortcut. | Surface refresh status and failure in an aviation/public-safety operator panel; retain the command for recovery. A future named grant may protect the global staff path, but eligible faction leadership remains a separate local authority check. |
| `/convertmdcaccounts`, `/removeduplicatedaccounts` | Scripter-only migration utilities; the duplicate-removal command explicitly warns not to run twice. | Database maintenance commands, not normal play. | Keep out of the player and general staff dashboards. Replace with versioned, reviewable, repeat-safe migrations with backup, dry-run, and result reporting; retain only a documented operator recovery path. These are database/operator actions and should not become ordinary Discord staff capabilities. |

The `/mdc` shortcut remains commented out; normal access is through the existing vehicle/computer entry points. These command alternatives are proposals, not implemented replacements. Record every future command against its manifest-loaded script and preserve the server authorization/data path. See [Issue #327](https://github.com/itschase/OwlMTA-2026/issues/327).

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/mdc/meta.xml`](../../mods/deathmatch/resources/mdc/meta.xml)
- Core server: [`mdc.lua`](../../mods/deathmatch/resources/mdc/mdc.lua)
- Shared/server permissions: [`permissions_g.lua`](../../mods/deathmatch/resources/mdc/permissions_g.lua) and [`permissions_s.lua`](../../mods/deathmatch/resources/mdc/permissions_s.lua)
- Migrations: [`migrations.lua`](../../mods/deathmatch/resources/mdc/migrations.lua); `changes.sql` is manual history, not automatically executed.
- Major state: `mdc_users`, `mdc_groups`, `mdc_criminals`, `mdc_crimes`, `mdc_apb`, `mdc_anpr`, `mdc_calls`, pilot/DMV/impound tables, `speedingviolations`, characters, vehicles, interiors, and factions.
- Runtime caches include APB/ANPR/pilot data, player `mdc_account`, and resource-root `mdc_groups`.
- Dependencies include `mysql`, `cache`, `pool`, `global`, `anticheat`, `factions`, `integration`, `toll`, `tow-system`, and `data`.
- Server exports: `getPlayerPilotLicenses`, `cleanUpMdcUsersAndGroups`, `login`, and `getANPRTable`; client/shared policy exports are also present.

## Source-confirmed risks

- Login and the main view now bind to the current logged-in requester and derive the active character ID from server state; the client-supplied character ID is ignored. The main response uses the validated requester for its permission checks and reply. These are fixed-in-source entry-boundary changes, not runtime verified. Nearly every downstream read and mutation still needs action-specific checks for account, duty, capability, target, and organization. This includes person searches and crime/warrant/profile/pilot/APB/ANPR/stolen/toll/account mutations and deletions.
- Search returns broad identity, contact, property, vehicle, crime, license, wanted, and history data without server authorization or field minimization. Global APB/ANPR lists and overlays are not organization/audience filtered.
- MDC account administration is client-authorized only. Account creation corrupts the requested level and checks duplicate organization using the wrong value.
- Deleted-faction cleanup passes an undefined variable; empty group results do not establish a safe empty cache.
- Unloaded vehicle search references an undefined model-name variable; crime-query cleanup frees the wrong result; warrant attribution references an undefined organization variable.
- APB creation UI checks the view permission rather than `canAddAPB`; the server checks neither.
- APB/ANPR caches can be changed before DB success, and person search silently creates a criminal-record row merely by viewing someone.
- The client vehicle-access gate contains unreachable branches when a faction value exists and computer entry bypasses the proximity gate. Client presentation cannot be the authority boundary.

## Tracked work and target direction

- [Issue #52](https://github.com/itschase/OwlMTA-2026/issues/52) tracks verification of active-character binding at login/main entry; that boundary is fixed in source but awaits runtime verification. [Issue #41](https://github.com/itschase/OwlMTA-2026/issues/41) tracks the separate broad review of search and mutation authorization, privacy, and remote-event coverage.
- [Issue #89](https://github.com/itschase/OwlMTA-2026/issues/89) owns authorized APB creation.
- [Issues #153](https://github.com/itschase/OwlMTA-2026/issues/153), [#187](https://github.com/itschase/OwlMTA-2026/issues/187), [#188](https://github.com/itschase/OwlMTA-2026/issues/188), and [#189](https://github.com/itschase/OwlMTA-2026/issues/189) define the future evidence, warrant, incident-alert, and justice-record boundaries.
- [Issue #193](https://github.com/itschase/OwlMTA-2026/issues/193) corrects account level/organization uniqueness; [#194](https://github.com/itschase/OwlMTA-2026/issues/194) repairs orphan cleanup and empty caches; [#195](https://github.com/itschase/OwlMTA-2026/issues/195) repairs search results and DB-result lifecycle.

The target is a central server policy for every operation and sensitivity tier; active-duty organization capability checks; server-derived actor and organization; immutable read/write audit; field-level minimization, purpose and retention; typed identifiers and records; append-only correction/supersession; async transactional persistence with cache reconciliation; and compatibility projections for a future case/evidence domain.

Runtime verification must cover every account/duty/organization/capability combination; vehicle, computer, overlay, and direct-event entry; forged sources and identifiers; every permission independently; field redaction and audience policy; add/remove/restart and DB-failure cache behavior; duplicate accounts and deleted factions; loaded/unloaded vehicles; all warrant/crime/license/stolen/impound/toll lifecycles; and dependency loss with fail-closed behavior.
