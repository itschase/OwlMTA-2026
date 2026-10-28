# OwlGaming MTA gamemode guide

This guide maps the active server as it exists in the imported upstream snapshot. It is an architecture and code-reading guide, not a certification that every resource works or a line-by-line security audit. The server is a network of MTA resources: each resource owns part of the behavior, exposes exports/events, and shares state through element data and the databases.

## How to read the tree

- `mods/deathmatch/mtaserver.conf.bak` is the only server config snapshot in this checkout; it has 138 `startup="1"` entries for 136 unique resources. Resource groups such as `[vehicle]` and `[interior]` are directories; the resource itself is usually a child directory containing `meta.xml`.
- `mods/deathmatch/resources/**/meta.xml` is the authoritative resource manifest: scripts, client/server side, exports, dependencies, and settings.
- `mods/deathmatch/resources/**` contains active code. `mods/deathmatch/resource-archive/**` contains inactive historical code; do not assume it runs.
- `mods/deathmatch/data/{core,mta,data}.sql` are bootstrap snapshots, not guaranteed to match any existing operator's live database.
- Shared resources such as `mysql`, `global`, `integration`, `account`, and `logs` are the infrastructure layer. Gameplay resources call their exports rather than forming a single application entry point.

When tracing a feature, start at its resource `meta.xml`, identify its server scripts and exported functions, follow cross-resource `exports.*` calls and custom events, then follow the SQL tables and client UI. Treat server scripts as the authority; client scripts and element-data mirrors are not trusted authorization inputs.

### MTA API reading notes

Use the [official MTA wiki](https://wiki.multitheftauto.com/wiki/Main_Page) as the API reference when tracing engine behavior. In particular, the wiki's [script security guidance](https://wiki.multitheftauto.com/wiki/Script_security) says event parameters and `source` are client-controlled while server-side `client` identifies the caller of `triggerServerEvent`. Several fixes in this pass use `client` for that reason. Check event registration (`addEvent` remote-trigger flag), element types, and client/server script declarations in the resource manifest together; UI-side checks are not server authorization.

For UI flows, follow `triggerServerEvent` into a server handler and the targeted `triggerClientEvent` response. For persistence, distinguish native MTA `dbQuery`/`dbExec` from the legacy mysql resource wrappers and confirm which connection and schema each function uses. The MTA wiki's [triggerServerEvent](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) and [addEventHandler](https://wiki.multitheftauto.com/wiki/AddEventHandler) pages are useful reference points while reading these call chains. Engine API behavior and version compatibility should be rechecked when the server artifact is pinned.

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

Registration still creates `core.accounts` and `mta.account_details` in separate writes, so failure can leave a partial account; the localhost activation-mail service is also missing. The current working changes validate password confirmation and repair the serial lookup. Character creation remains a remotely-triggerable event, but the current working handler now checks authenticated account state and quota, validates numeric fields/date/language, ignores the client-supplied spawn array in favor of the currently selected server default, and emits tagged diagnostics. A schema migration should make account creation atomic; a runtime pass should confirm normal login and character flows after these source changes.

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
- The MTA process should boot independently of Discord, but production registration and login require a fresh successful Discord authorization result. If the identity service is unavailable, new logins fail closed; existing sessions are governed by bounded leases and explicit revocation handling.

### Discord as the planned primary login method

Treat identity authentication and staff authorization as separate decisions. Discord authorization proves which Discord account completed OAuth; a unique account link determines which game data is loaded; current configured guild roles determine staff and donor capabilities. A successful OAuth login alone must never grant staff access. Role IDs remain blank in the public template and grant nothing until an operator configures them.

Recommended flow for the replacement account service:

1. Use Discord's server-side OAuth2 Authorization Code Grant from the web service, with unpredictable `state`, an exact registered callback, short-lived sessions and the minimum scopes needed. Keep the client secret and access tokens on the web service; never ship them in MTA Lua or browser code. Discord documents `identify` for identity and `guilds.members.read` for the authenticated user's member data in a guild; role resolution can instead be performed by the trusted bot service. Recheck current scope behavior when implementation starts.
2. Link an existing game account only after the user proves control of it (a current authenticated game session or existing password plus a one-time confirmation). Store an immutable Discord user ID mapped uniquely to the game account ID. Do not auto-merge on email, Discord username, display name or matching character name.
3. For in-game Discord login, have the MTA server create a random, short-lived login challenge. The player completes OAuth in a browser and confirms that challenge through the account service; the service issues a one-use ticket bound to the challenge and linked account. The MTA server redeems the ticket server-to-server and receives only the game account ID and a success result. Expire and consume the ticket atomically; do not let the client submit a Discord ID, OAuth token, role list or account ID as proof.
4. For first-time users, create the game account only after verified OAuth and explicit consent/required account checks. Keep an audited operator bootstrap and recovery procedure for setup failures and account-link disputes. The service must not be a process boot dependency, but production registration/login cannot silently fall back to local password authentication when authorization is unavailable.
5. Audit link, unlink, login and recovery events. Require re-authentication and a cooldown or staff-reviewed recovery for unlinking an account with active staff grants. Default to one game account per Discord identity unless multi-account linking is explicitly designed.

The gamemode should expose a versioned, self-hostable API contract for account identity and authorization, with a website as an optional client implemented by whoever operates the server. The website must not reimplement game permission rules or be required for management. An in-game code-and-browser flow avoids embedding Discord OAuth in the MTA client; the game server redeems a one-use ticket asynchronously. The authorization service is required for production registration/login, while ordinary server startup remains independent. In-game management remains available without a website.

Before cutover, enumerate each call site of `isPlayerAdmin`, `isPlayerSupporter`, direct rank element-data reads, `account:gmlevel`, faction permissions, specialty team levels and duty checks. Classify the action it protects, then map it to a named capability. Do not globally redefine `isPlayerSupporter` until donor perks and staff checks have been separated.

Concrete findings in this snapshot:

- Since commit [`6e17038`](https://github.com/itschase/OwlMTA-2026/commit/6e17038), server `getGameMasters()` requires a logged-in player and a positive `account:gmlevel`; donor status alone no longer fills its report/list callers. No durable login-time GM grant source or active GM assignment workflow was found, so the list can be empty until Issue [#14](https://github.com/itschase/OwlMTA-2026/issues/14) is completed. Some report callers still use `duty_supporter` as the separate on-duty flag.
- `integration/g_staff.lua` repeats `not getElementType(player) == "player"`; Lua precedence makes that check ineffective. Use `getElementType(player) ~= "player"` and validate server-side callers consistently.
- `global/meta.xml` declares GameMaster exports that were not found in active global Lua definitions, while active callers exist. Verify resource export behavior and repair/remove the mismatch.
- `account/c_characters.lua` mirrors some rank data client-side for display; this must never decide access.
- Remote state-changing events need sender validation against MTA's authoritative `client` variable, not a spoofable `source`, plus server-side permission and value checks.

## Missing UCP and external service dependencies

The UCP website is absent. `resources/usercontrolpanel` exposes HTTP-callable operations (including staff messaging, server stats and kick) and creates a `website` ACL account from a configured password. `acl.xml` places `user.website` in the broad `Admin` group, which has more authority than a narrow web API identity should need. Disable/restrict this integration during migration and replace it with a small authenticated API with per-action permissions, audit logging, rate limits and revocable credentials.

There is no UCP website available to reference or depend on. Other non-portable dependencies found include a localhost activation email endpoint, OwlGaming news/rules URLs, forums API settings and Imgur configuration. The Docker entrypoint also substitutes configuration values into XML using `sed`; values with XML or sed metacharacters can corrupt the output. It reads `WEBSITE_PASSWORD`, which is not listed in the README environment variables. The Dockerfile obtains an unpinned MTA server download, so builds are not reproducible yet. The target is an MTA server that boots independently of external services, uses Discord authorization for production registration/login, and supports routine management in-game without a website. The self-hosted identity API is a login dependency, not a UCP; the server must report an unconfigured service clearly and provide an audited operator setup route.

`event-system/bmxpier/server.lua` sent player names and scores to an external endpoint with a hard-coded key in the URL. The key and outbound submission were removed in committed source. Treat the historical key as exposed: rotate/disable the remote credential after confirming endpoint ownership, and assess repository-history cleanup. `acl.xml` also gives the `Everyone` group broad objects at first glance; MTA's [ACL model](https://wiki.multitheftauto.com/wiki/Access_Control_List) applies the ACL lists assigned to wildcard groups, so evaluate the effective rights before treating this as an exploit. The `user.website` membership in `Admin`, however, is explicit and needs restriction.

## High-priority bug and upstream review queue

These began as source-level findings or upstream reports, not reproduced runtime failures. Committed source fixes address staff/faction manager access, bank transactions/history, character creation and the BMX outbound score credential. The changes still need review and disposable-environment runtime validation. Other rows remain open. No server boot or exploit reproduction has been performed.

| Finding | Evidence / next action |
| --- | --- |
| **Critical: remote staff rank editing lacked an authorization boundary** | Fixed in committed source: `admin-system/staff_manager/staff_manager_s.lua` requires server-side staff access, validates ranks, limits edits by team, excludes donor authority, and persists the account update before audit/notification side effects. Runtime validation remains open. |
| **High: remote faction administration lacked an authorization boundary** | Fixed in committed source: `factions/faction_manager_s.lua` checks server-side access for view/edit/delete, validates inputs, and logs failures. Client-side access helpers were aligned to exclude donor-only status. Runtime validation remains open. |
| **High: staff data events disclosed protected information** | The staff read events now use the same server authorization check as edits. Verify response behavior after the requester disconnects and against a running server. |
| **Critical: bank handlers lacked amount and faction authorization** | Fixed in committed source: `bank/s_bank_system.lua` validates positive amounts, checks `manage_finance`, compensates failed transfers where possible, restricts personal/business history to owned accounts, and removes the client-triggerable ledger writer. Because bank persistence spans element data and MyISAM tables, failures cannot be made atomic without schema work. |
| **High: insurance and inventory events trust client-selected targets** | Still open. `insurance/s_main.lua` purchase/cancel/faction settings and `item-system/s_item_management.lua` inventory fetch/subscribe paths need server-side ownership/permission checks; unsubscribe is wired to subscribe. |
| **High: remotely writable bank history** | Fixed in committed source: the client-triggerable bank transaction-log event was removed; trusted in-server resources continue to use the server export. |
| Character creation trusted client state | Fixed in committed source: `account/s_create_character.lua` checks account authentication and quota, validates input values, ignores client coordinates, and logs failures. Runtime validation remains open. |
| Character cash may survive a character switch | `account/s_characters.lua` clears character IDs and bank data but not live cash. Review [upstream PR #57](https://github.com/OwlGamingCommunity/MTA/pull/57) and validate the transition. |
| Admin jail writes to the wrong table | `admin-system/Player/adminjail_s.lua` refers to `accounts`; jail columns are in `mta.account_details`, while `core.accounts` has no such fields. Review [PR #46](https://github.com/OwlGamingCommunity/MTA/pull/46). |
| Forum login/account calls may target absent APIs/schema | Character scripts use `accounts` through the legacy MTA DB wrapper and call `logintoForumAccount`; the export is declared but its active implementation was not found. Trace before deciding whether to remove legacy UI. |
| Registration serial duplicate check was inconsistent | Fixed in committed source: duplicate lookup selects `account_id`, releases results, validates password confirmation server-side, and logs query failures. Runtime validation remains open. |
| UCP identity has broad ACL access | `usercontrolpanel` website account is in `Admin`; scope the identity down or remove the legacy endpoint before deployment. |
| Public event validation needs audit | Many resources register remotely triggerable events. Review authorization and input validation for money, inventory, ownership, staff ranks, bans, faction membership and character state. |
| Ammo visibility bug reported upstream | Review [PR #55](https://github.com/OwlGamingCommunity/MTA/pull/55) and verify the affected `ammo` resource call. |
| **High: car purchase can charge before stock is confirmed** | Still open. `[vehicle]/carshop-system/s_shop.lua` charges before checking stock, and the server handler lacks explicit distance validation. Review [PR #48](https://github.com/OwlGamingCommunity/MTA/pull/48) and [PR #49](https://github.com/OwlGamingCommunity/MTA/pull/49); independently audit the server-side flag/freeze flow before adopting. |
| Elevator empty-table fallback may miss SQL NULL | Review [PR #58](https://github.com/OwlGamingCommunity/MTA/pull/58); `MIN()` can return a result row whose value is NULL, so a truthy result object may not mean a next ID exists. |
| Admin self-transfer is only warned | Review [PR #54](https://github.com/OwlGamingCommunity/MTA/pull/54) and decide whether policy should block or only warn. |
| Discord Rich Presence is not role management | [PR #67](https://github.com/OwlGamingCommunity/MTA/pull/67) is a closed, unmerged Rich Presence change; it does not provide Discord OAuth, guild roles or authorization. |

The BMX score submission credential and outbound request were removed in committed source; revoke the historical credential with its owner. These findings are source-level, not runtime exploit demonstrations; no server was started and no event was triggered. A broad search found 181 remotely-triggerable event declarations in active server script files; this is a rough declaration count and requires a handler-by-handler audit. A static inventory of resource manifests and startup status is in [RESOURCE_INVENTORY.csv](../../RESOURCE_INVENTORY.csv).

Original forks were inspected as references. `starinjs/OwlGamingPlus` has broad divergences and webhook-oriented Discord code, not a verified role authorization system; do not transplant the fork wholesale. A separate fork contains suspicious launcher artifacts in its history; none were imported or executed. Fork content and PR patches require selective review.

## Suggested order for the full understanding pass

1. Record every resource, manifest, dependency, exported API, remote event and declared setting; reconcile startup state against `mtaserver.conf.bak` and verify which omitted resources are intentionally manual.
2. Trace authentication, registration, account linking, character create/select/switch/spawn, and every persistence listener end to end.
3. Build a table-to-resource read/write map for all three schemas. Identify cross-schema joins, duplicate APIs, engine/collation assumptions and orphan risks.
4. Trace money, item, vehicle, property and faction transactions from client event to server validation, export, database mutation and log record.
5. Build a permission call-site inventory and capability matrix before changing any staff or donor semantics.
6. Review each high-risk event and each upstream PR against current source. Reproduce only in a disposable environment once a runnable MTA/MySQL setup is available.
7. Document import prerequisites, disabled legacy integrations, clean configuration defaults and a reversible migration path before broad gameplay rewrites.

The initial quantitative inventory and additional first-pass findings are in [CODEBASE_REVIEW.md](CODEBASE_REVIEW.md); feature entry points and usage are in [FEATURE_USAGE_GUIDE.md](../guides/FEATURE_USAGE_GUIDE.md); sequencing decisions are in [REBUILD_PLAN.md](../planning/REBUILD_PLAN.md); the detailed Discord identity, login and capability migration proposal is in [DISCORD_AUTH_DESIGN.md](DISCORD_AUTH_DESIGN.md).
