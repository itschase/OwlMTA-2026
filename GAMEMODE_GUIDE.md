# OwlGaming MTA gamemode guide

This guide maps the active server as it exists in the imported upstream snapshot. It is an architecture and code-reading guide, not a certification that every resource works or a line-by-line security audit. The server is a network of MTA resources: each resource owns part of the behavior, exposes exports/events, and shares state through element data and the databases.

## How to read the tree

- `mods/deathmatch/mtaserver.conf.bak` is the only server config snapshot in this checkout; it has 138 `startup="1"` entries for 136 unique resources. Resource groups such as `[vehicle]` and `[interior]` are directories; the resource itself is usually a child directory containing `meta.xml`.
- `mods/deathmatch/resources/**/meta.xml` is the authoritative resource manifest: scripts, client/server side, exports, dependencies, and settings.
- `mods/deathmatch/resources/**` contains active code. `mods/deathmatch/resource-archive/**` contains inactive historical code; do not assume it runs.
- `mods/deathmatch/data/{core,mta,data}.sql` are bootstrap snapshots, not guaranteed to match any existing operator's live database.
- Shared resources such as `mysql`, `global`, `integration`, `account`, and `logs` are the infrastructure layer. Gameplay resources call their exports rather than forming a single application entry point.

When tracing a feature, start at its resource `meta.xml`, identify its server scripts and exported functions, follow cross-resource `exports.*` calls and custom events, then follow the SQL tables and client UI. Treat server scripts as the authority; client scripts and element-data mirrors are not trusted authorization inputs.

## Boot and service graph

The checked-in startup sequence begins with `mysql`, `data`, `pool`, `global`, `release-notes`, `resources`, `datetime`, `integration`, and `anticheat`, followed by shared UI, logging, bans, account, staff and gameplay services. the precise sequence is in `mtaserver.conf.bak`; there are duplicate startup lines for `event-system` and `selfck-system` that should be removed after checking runtime dependencies.

The first resources to understand are:

| Resource | Responsibility / useful entry points |
| --- | --- |
| `mysql` | Native MTA database handles and query helpers. `mysql/mysql.lua` opens `mta` and `core`; `mysql/mysql_external_module.lua` also opens a legacy C-module connection to `mta`. |
| `global` | Shared gameplay helpers, element data helpers, money/rank utility functions and shared tables. `global/g_admin_globals.lua` includes global staff/game-master queries. |
| `integration` | Cross-resource compatibility and staff/rank checks. `integration/g_staff.lua`, `integration/functions_s.lua`, and `integration/g_configs.lua` are key permission paths. |
| `account` | Authentication, account registration, character selection, spawn and character switching. Start with `account/login-panel/server.lua` and `account/s_characters.lua`. |
| `saveplayer-system` | Periodic, quit and explicit `savePlayer` persistence of character state. Many resources listen to the same event to persist their owned state. |
| `logs`, `bans`, `admin-system`, `donators` | Audit/logging, enforcement, staff tools and donor entitlements. These cross-cutting services need special attention during permission migration. |

There are 144 resource manifests; eight are not startup-listed in the checked-in config snapshot: `elections`, `forums`, `guied`, `hardwaresurvey`, `object-browser`, and the `[dev]` tools `ipb`, `runcode`, and `sfxbrowser`. Confirm whether these are intentionally manual/dev-only before cleanup. `usercontrolpanel` is startup-listed despite its missing website service, which makes its ACL scope a deployment issue.

Resource dependencies are declared partly in manifests and partly through runtime export calls. Startup order alone does not prove a dependency is correct. A full importability pass still needs an actual disposable server boot and log review.

## Account, character and persistence lifecycle

1. On join, `account/s_main.lua` initializes unauthenticated state; `account/s_login.lua` handles the login UI gate and IP/serial bans.
2. `account/login-panel/server.lua` receives login and registration events. Account credentials and account-level ranks are in `core.accounts`; gameplay account details are in `mta.account_details`.
3. Legacy passwords are verified using the stored salted MD5 format and upgraded after successful login to `bcrypt_sha256$` (bcrypt work factor 12). New bcrypt verification hashes the submitted password with SHA-256 first.
4. Successful login loads account IDs and legacy rank values into server element data, loads donor perks, and progresses through rules/tutorial gates to character selection.
5. `account/s_characters.lua` lists active characters from `mta.characters`, checks ownership and character state, then restores money/bank, position, inventory, faction membership and other roleplay state during spawn.
6. `saveplayer-system/s_saveplayer_system.lua` saves general character state periodically, on quit, and on `savePlayer`. Individual resources also attach listeners for the data they own. Character cash is live player element data and is handled by economy/resource code; do not assume the general save script persists all subsystems.
7. Character change saves the outgoing character and resets login/character identifiers before returning to selection. The current code does not clear live `money` at this boundary; upstream PR #57 addresses this potential cross-character cash carry-over.

The current registration path inserts rows into both schemas, then calls `http://127.0.0.1:8000/api/send-activation-mail/`. That service is not included here. The legacy forum link path also calls `integration:logintoForumAccount`, which is declared as an export but has no active implementation located in this snapshot. Treat registration and forum linking as incomplete until external dependencies are replaced or made configurable.

## Database ownership and model

There are three schema snapshots:

| Schema | Snapshot | Current purpose |
| --- | --- | --- |
| `core` | `mods/deathmatch/data/core.sql` | Accounts, credentials, activation/forum IDs, numeric staff and donor ranks, and legacy Django/UCP tables. 11 tables, all InnoDB. |
| `mta` | `mods/deathmatch/data/mta.sql` | Character and gameplay state: factions, vehicles, interiors, items, jobs, banking ledger, account details, etc. 113 tables: 106 MyISAM and 7 InnoDB. |
| `data` | `mods/deathmatch/data/data.sql` | Shared settings table. One MyISAM table. |

There are no explicit foreign-key contracts in these snapshots. Cross-schema IDs and application code provide much of the relationship logic. The code uses both native prepared `dbQuery`/`dbExec` calls and older `exports.mysql:query*` string-based helpers; the legacy C-module connection adds another path to the same MTA database. This mixture complicates transaction safety, error handling and schema ownership. Inventory every query before consolidating connections or moving tables. MyISAM tables cannot provide normal transactional guarantees, so table-engine conversion belongs in a planned data migration, not an incidental code change.

Useful domain tables: `characters`, `characters_faction`, `factions`, `interiors`, `items`, `vehicles`, `jobs`, `jobs_trucker_orders`, and `wiretransfers`. Table definitions are in `mta.sql` (search `CREATE TABLE`).

## Gameplay system map

| Domain | Main resources / data flow |
| --- | --- |
| Factions and ranks | `factions/s_faction_system.lua` loads `factions` and `characters_faction`; `factions/g_faction_exports.lua` exposes membership and rank helpers; `ranks/s_permissions.lua` centralizes faction-rank permissions. Factions own vehicles and interiors. Membership, rank and on-duty status are distinct. |
| Jobs | `job-system/s_job_system.lua` manages the character's selected job (`characters.job`) and shared job state. Taxi, bus, street cleaning, mechanic, fishing, photography, locksmith and trucking modules use additional state in `jobs` and `jobs_trucker_orders`. Jobs are separate from factions. |
| Items and inventory | `item-system/s_item_management.lua` is the server-side ownership API for player, vehicle, world, safe/object, ped and interior items. The `items` table uses an owner type and owner ID. Client inventory is a view; use exports to move/create items rather than writing rows directly. |
| Vehicles | `[vehicle]` contains vehicle ownership, loading, management, fuel, plates and vehicle interiors; `carshop-system` handles purchases and `carradio` handles radio. `vehicle_load/load_s.lua` loads rows and creates MTA elements. Vehicles link characters/factions, impound, insurance, fuel, inventory, properties and economy. |
| Interiors and property | `[interior]` contains core property, load, management, keypad, official-property and vehicle-interior resources. `interiors` supports character or faction ownership and property state; payday processes taxes/rent. Elevator state has a separate resource. |
| Economy | Cash is live player element data; bank balances are character state; `bank` exposes transfer operations and records ledger entries in `wiretransfers`. `payday/s_payday.lua` processes wages, benefits, interest and recurring tax/upkeep deductions. Shops and vehicle/property systems cross this boundary. |
| Public safety and health | `pd-system`, `mdc`, `LSFD`, `sapt-system`, `sfia`, `prison-system`, `insurance`, `license-system`, `bans` and `report` cover police, medical, legal, licensing and player support loops. They depend on faction rank, duty state, character identity and vehicle/economy/item APIs. |
| Communication and presentation | `chat-system`, phone, radio, HUD and scoreboard provide client-facing features. Verify all consequential actions at the server event handler; UI visibility is not a permission check. |

These boundaries are the main rebuild seams: changing an item, vehicle, money or identity contract can affect several resources. Trace callers and event listeners before changing an export or table.

## Permission model and Discord migration

Today, account login loads numeric fields such as `admin_level`, `supporter_level`, and specialty-team levels from `core.accounts`; staff helpers and some direct callers use those values. Legacy forum group configuration also influences admin rank. `admin-system/staff_manager` can change rank element data. This is not yet a single authorization service.

The user's intended model is:

- Discord role IDs are operator-provided configuration slots. No OwlGaming Discord IDs or assumed role names belong in the template.
- Separate admin tiers and a GameMaster grant map to explicit capabilities. GameMaster is not a donor tier.
- `Support` / `supporter_level` represent donator tiers only. Donor status must not grant moderation or staff authority, even where current code uses `isPlayerSupporter()` in staff-like checks.
- Discord linking must prove control of both identities. The MTA client cannot submit trusted Discord role lists or role IDs. The server should consume short-lived capabilities from a trusted service, fail closed on stale authorization, audit grants/revocations/actions, and retain a narrowly scoped owner recovery path.
- Discord must remain optional for basic server boot and gameplay. If Discord is unavailable, ordinary players should continue to play; only protected staff actions need fresh grants.

Before cutover, enumerate each call site of `isPlayerAdmin`, `isPlayerSupporter`, direct rank element-data reads, `account:gmlevel`, faction permissions, specialty team levels and duty checks. Classify the action it protects, then map it to a named capability. Do not globally redefine `isPlayerSupporter` until donor perks and staff checks have been separated.

Concrete findings in this snapshot:

- `getGameMasters()` currently selects players through `isPlayerSupporter()`, conflating GameMaster and donor status.
- `integration/g_staff.lua` repeats `not getElementType(player) == "player"`; Lua precedence makes that check ineffective. Use `getElementType(player) ~= "player"` and validate server-side callers consistently.
- `global/meta.xml` declares GameMaster exports that were not found in active global Lua definitions, while active callers exist. Verify resource export behavior and repair/remove the mismatch.
- `account/c_characters.lua` mirrors some rank data client-side for display; this must never decide access.
- Remote state-changing events need sender validation against MTA's authoritative `client` variable, not a spoofable `source`, plus server-side permission and value checks.

## Missing UCP and external service dependencies

The UCP website is absent. `resources/usercontrolpanel` exposes HTTP-callable operations (including staff messaging, server stats and kick) and creates a `website` ACL account from a configured password. `acl.xml` places `user.website` in the broad `Admin` group, which has more authority than a narrow web API identity should need. Disable/restrict this integration during migration and replace it with a small authenticated API with per-action permissions, audit logging, rate limits and revocable credentials.

Other non-portable dependencies found include the localhost activation email endpoint, OwlGaming news/rules URLs, forums API settings and Imgur configuration. The Docker entrypoint also substitutes configuration values into XML using `sed`; values with XML or sed metacharacters can corrupt the output. It reads `WEBSITE_PASSWORD`, which is not listed in the README environment variables. The Dockerfile obtains an unpinned MTA server download, so builds are not reproducible yet.

`event-system/bmxpier/server.lua` sends player names and scores to an external endpoint with a hard-coded key in the URL. Treat the key as exposed: remove it from source and rotate/disable the remote credential after confirming endpoint ownership. `acl.xml` also gives the `Everyone` group broad objects at first glance; verify effective permissions using MTA's ACL semantics before treating that entry as proven exposure. The `user.website` membership in `Admin`, however, is explicit and needs restriction.

## High-priority bug and upstream review queue

These are source-level findings or upstream reports, not all reproduced runtime failures. Review each patch before applying it.

| Finding | Evidence / next action |
| --- | --- |
| **Critical: remote staff rank editing lacks an authorization boundary** | `admin-system/staff_manager/staff_manager_s.lua:116-206` registers `staff:editStaff` remotely and its handler writes admin, supporter and specialty ranks without a staff check. Client-supplied rank values are concatenated into SQL update fragments without numeric/range validation. Treat as direct privilege escalation; disable or gate this path before any public server operation, then replace it with the central capability service. |
| **High: remote faction administration lacks an authorization boundary** | `factions/faction_manager_s.lua:38-39,153-154` exposes faction edit/delete mutations with no apparent handler permission check. The faction list/member events are also remotely callable. Gate mutations and sensitive roster data server-side. |
| **High: staff data events disclose protected information** | In the staff manager, `staff:getStaffInfo`, `staff:getTeamsData`, and `staff:getChangelogs` are remotely callable without apparent permission checks. Restrict them along with rank mutation. |
| Character cash may survive a character switch | `account/s_characters.lua` clears character IDs and bank data but not live cash. Review [upstream PR #57](https://github.com/OwlGamingCommunity/MTA/pull/57) and validate the transition. |
| Admin jail writes to the wrong table | `admin-system/Player/adminjail_s.lua` refers to `accounts`; jail columns are in `mta.account_details`, while `core.accounts` has no such fields. Review [PR #46](https://github.com/OwlGamingCommunity/MTA/pull/46). |
| Forum login/account calls may target absent APIs/schema | Character scripts use `accounts` through the legacy MTA DB wrapper and call `logintoForumAccount`; the export is declared but its active implementation was not found. Trace before deciding whether to remove legacy UI. |
| Registration serial duplicate check is inconsistent | The query selects `mtaserial`, but subsequent code reads `id` and `username`; inspect and correct duplicate/account-1 logic. |
| UCP identity has broad ACL access | `usercontrolpanel` website account is in `Admin`; scope the identity down or remove the legacy endpoint before deployment. |
| Public event validation needs audit | Many resources register remotely triggerable events. Review authorization and input validation for money, inventory, ownership, staff ranks, bans, faction membership and character state. |
| Ammo visibility bug reported upstream | Review [PR #55](https://github.com/OwlGamingCommunity/MTA/pull/55) and verify the affected `ammo` resource call. |
| Car shop purchase location issue reported upstream | Review [PR #48](https://github.com/OwlGamingCommunity/MTA/pull/48) and [PR #49](https://github.com/OwlGamingCommunity/MTA/pull/49); independently audit the server-side flag/freeze flow before adopting. |
| Elevator empty-table fallback may miss SQL NULL | Review [PR #58](https://github.com/OwlGamingCommunity/MTA/pull/58); `MIN()` can return a result row whose value is NULL, so a truthy result object may not mean a next ID exists. |
| Admin self-transfer is only warned | Review [PR #54](https://github.com/OwlGamingCommunity/MTA/pull/54) and decide whether policy should block or only warn. |
| Discord Rich Presence is not role management | [PR #67](https://github.com/OwlGamingCommunity/MTA/pull/67) is a closed, unmerged Rich Presence change; it does not provide Discord OAuth, guild roles or authorization. |

The staff and faction event findings are source-confirmed gaps in the sampled handlers, but have not been triggered against a running server. A broad search found 181 remotely-triggerable event declarations in active server script files; this is a rough declaration count and requires a handler-by-handler audit. A static inventory of resource manifests and startup status is in [RESOURCE_INVENTORY.csv](RESOURCE_INVENTORY.csv).

Original forks were inspected as references. `starinjs/OwlGamingPlus` has broad divergences and webhook-oriented Discord code, not a verified role authorization system; do not transplant the fork wholesale. A separate fork contains suspicious launcher artifacts in its history; none were imported or executed. Fork content and PR patches require selective review.

## Suggested order for the full understanding pass

1. Record every resource, manifest, dependency, exported API, remote event and declared setting; reconcile startup state against `mtaserver.conf.bak` and verify which omitted resources are intentionally manual.
2. Trace authentication, registration, account linking, character create/select/switch/spawn, and every persistence listener end to end.
3. Build a table-to-resource read/write map for all three schemas. Identify cross-schema joins, duplicate APIs, engine/collation assumptions and orphan risks.
4. Trace money, item, vehicle, property and faction transactions from client event to server validation, export, database mutation and log record.
5. Build a permission call-site inventory and capability matrix before changing any staff or donor semantics.
6. Review each high-risk event and each upstream PR against current source. Reproduce only in a disposable environment once a runnable MTA/MySQL setup is available.
7. Document import prerequisites, disabled legacy integrations, clean configuration defaults and a reversible migration path before broad gameplay rewrites.

The initial quantitative inventory and additional first-pass findings are in [CODEBASE_REVIEW.md](CODEBASE_REVIEW.md); sequencing decisions are in [REBUILD_PLAN.md](REBUILD_PLAN.md).
