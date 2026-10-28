# Codebase review: initial architecture map

This is the first pass over the upstream `main` snapshot. It maps the major systems and records concrete findings for the full review; it is not a line-by-line audit of every resource yet. See [GAMEMODE_GUIDE.md](GAMEMODE_GUIDE.md) for the consolidated functional map, database ownership, account lifecycle, gameplay domains, UCP dependencies, and review queue.

## Repository scale and structure

- 1,093 Lua files across 144 active resource manifests under `mods/deathmatch/resources`.
- 114 additional Lua files are under `mods/deathmatch/resource-archive` and should be treated as inactive until a live dependency proves otherwise.
- Three SQL snapshots contain 125 `CREATE TABLE` statements in total: `data/core.sql`, `data/mta.sql`, and `data/data.sql`.
- The game is composed of MTA resources with broad shared exports. Major cross-cutting systems include `account`, `mysql`, `integration`, `global`, `admin-system`, `factions`, `item-system`, `vehicle`, and `logs`.

## Account and staff identity flow

1. An account is authenticated in the `account` resource. Account records and the legacy UCP/forum data live in the `core` schema; character and gameplay records live in `mta`.
2. Character login loads account/character values into server-side element data, including `admin_level`, `supporter_level`, and `account:gmlevel`.
3. `integration/g_staff.lua` exposes rank helpers (`isPlayerAdmin`, `isPlayerTrialAdmin`, `isPlayerSupporter`, and team-specific helpers). Many resources call these helpers, while some commands also inspect numeric element data directly. The user clarified that `supporter_level` means donator tier. Several code paths nevertheless use `isPlayerSupporter()` alongside admin checks for staff-like actions, so those paths need capability-by-capability review and donor access must not become moderation authority.
4. `integration/functions_s.lua` converts legacy forum group IDs in `forum_perms` into an `admin_level`. `integration/g_configs.lua` hard-codes the old forum group IDs and rank titles.
5. `admin-system/staff_manager/staff_manager_s.lua` has an active staff-rank editor for admin, supporter, and specialty-team ranks. A legacy `makePlayerStaff` function also writes GM element data, but its `/makestaff` command registration is commented out; this is not a durable or active GM assignment path.

## Permission findings to validate and fix

- **Legacy forum authority:** `integration/functions_s.lua` and `integration/g_configs.lua` couple admin rank assignment to forum group IDs. These should become a compatibility adapter during migration, then be retired after Discord grants are authoritative.
- **Scattered checks:** The common helper layer is useful, but access is also checked directly through `admin_level`, `supporter_level`, duty flags, and `account:gmlevel` across many resources. A mechanical search found hundreds of permission references, so centralization and phased migration are required.
- **GameMaster drift (initial finding; partially fixed):** The initial source review found `global/g_admin_globals.lua:getGameMasters()` returning players passing `integration:isPlayerSupporter()`. Commit [`6e17038`](https://github.com/itschase/OwlMTA-2026/commit/6e17038) changed the server helper to require login state and a positive `account:gmlevel`. A durable grant source, active assignment workflow, and the missing declared exports remain open under [Issue #14](https://github.com/itschase/OwlMTA-2026/issues/14).
- **Donator/staff permission collision:** `integration:isPlayerSupporter()` reads `supporter_level`, which represents donator tiers, but is included in multiple staff-like authorization checks. Audit those exact actions and separate paid perks from moderation powers before Discord role cutover.
- **Missing GM exports:** `global/meta.xml` declares client exports such as `isPlayerGameMaster`, `getPlayerGMTitle`, and `getPlayerGameMasterLevel`, but the active `global` Lua files do not define those functions. Active callers include `chat-system/s_chat_system.lua` and `forums/s_gmpost.lua`. Verify at runtime and restore or remove the broken exports/callers.
- **Element type guard precedence:** `integration/g_staff.lua` repeats guards written as `not getElementType(player) == "player"`. In Lua this negates the returned string before comparing it, so the intended non-player rejection does not work. Replace it with `getElementType(player) ~= "player"` and use one shared validator.
- **Client-side mirrors:** `account/c_characters.lua` sets rank element data client-side for UI display. Treat this as presentation state only; all authorization must read server-owned grants and cannot trust client element data.

## Packaging and importability

- `settings.xml.bak` contains placeholders for two database connections plus UCP/forum and Imgur settings. The entrypoint substitutes environment variables with `sed`; values containing `&` or the delimiter can corrupt the generated XML. Replace this with validated, XML-safe configuration generation and a checked-in example file with no deployable secrets.
- The Docker build downloads an unpinned MTA server archive. Pin its version/checksum and document the supported MTA version before claiming reproducible imports.
- The server config currently embeds a production client-version floor. Provide safe development defaults and require operators to opt into production settings.
- The root GPL-2.0 license conflicts with active source headers that describe the code as proprietary/confidential and prohibit copying. Preserve upstream notices and reconcile the repository license and headers before a public release.

## Review work remaining

- Build a resource inventory with dependencies, start order, database tables, exports, and active/inactive status.
- Trace account creation/login and schema ownership through their scripts and SQL, then document import prerequisites and a no-data-loss migration path.
- Inspect every server event that changes money, inventory, ownership, staff ranks, bans, faction membership, or character state for server-side authorization and validation.
- Reproduce the container build and MTA resource startup against disposable databases, then triage the first blocking failures.
- Inventory all hard-coded external services, URLs, API keys, forum assumptions, and operational endpoints before replacing the UCP.

## Findings added during the architecture pass

- The account registration path calls a localhost activation-mail endpoint that is not part of this repository. The forum login export is declared but no active implementation was located; account/character forum paths also query an `accounts` table through the MTA connection although the checked-in account table is in `core`.
- `account/login-panel/server.lua` previously selected only `mtaserial` during registration duplicate checks but later read `id` and `username` from that result. Committed source now selects `account_id`, frees the result on rejection, and validates password confirmation server-side.
- `account/s_characters.lua` character switching leaves live cash set; upstream PR #57 proposes clearing it. `adminjail_s.lua` writes jail columns against `accounts` although the checked-in jail columns are in `mta.account_details`; upstream PR #46 proposes the correction.
- The legacy UCP resource declares HTTP-callable management actions and provisions a `website` ACL account that belongs to the broad `Admin` group. The UCP web application itself is missing.
- Critical source-level authorization gaps were found in the sample audit: remotely triggerable `staff:editStaff` could update ranks without permission checks, and faction edit/delete plus staff/faction data events lacked server authorization. Committed source adds server authorization, validates rank/faction payloads, and moves staff side effects after the durable rank update. Further faction system handlers remain open; see Issues #38–39.
- Additional sampled transaction risks included negative personal bank withdrawals, faction transfers without `manage_finance` checks, insurance and inventory handlers trusting client-selected targets, and a remote bank-ledger writer. Committed source hardens bank handlers and history access. Insurance/inventory authorization, property purchase/keypad checks, car-shop ordering, job ID validation, payday event boundaries and the full event audit remain open. Character creation now checks account state and quota server-side and ignores client coordinates. These source changes have not been runtime tested; see [GAMEMODE_GUIDE.md](GAMEMODE_GUIDE.md) and Issues #15, #45–48.
- Discord is the planned primary production authentication source; browser OAuth proves identity, existing accounts require an explicit proof-of-control link, and in-game login uses a short-lived one-use server-redeemed ticket. Authentication remains separate from staff permissions. [DISCORD_AUTH_DESIGN.md](DISCORD_AUTH_DESIGN.md) records the proposed flow, capability vocabulary, blank role-ID slots, session revocation, and staged migration.
- A broader scan found 181 remotely-triggerable event declarations in active server scripts (rough count, not unique or confirmed vulnerabilities). A further handler-by-handler review is needed, starting with money, inventory, ownership, character, ban and staff actions.
- `event-system/bmxpier/server.lua` contained a hard-coded external score-submission key. Committed source removes the key and disables outbound submission; external credential revocation and repository-history cleanup remain tracked work. Do not copy the key into docs or logs.
- The checked-in `mtaserver.conf.bak` has 138 startup entries for 136 unique resources and 144 resource manifests overall. `event-system` and `selfck-system` are duplicated; eight manifests are not startup-listed. See [RESOURCE_INVENTORY.csv](../../RESOURCE_INVENTORY.csv).
- PRs #48/#49 (car shop purchase range), #54 (admin interior transfer), #55 (ammo scope), and #58 (elevator ID fallback) are review references only; none were imported. PR #67 is Discord Rich Presence, not role-based authorization.
- A reference fork with broad gameplay changes and webhook notifications was inspected but not copied. Its Discord code does not establish role-based staff permissions.

## Review status

The account/data, gameplay-domain, deployment, and sampled authorization architecture passes are complete at a map-and-triage level. The first hardening batch for account creation, staff/faction managers, banking, and the BMX outbound credential is committed to `main`; it has not been runtime-tested. The complete event/query inventory, permission call-site audit, dependency validation, disposable server boot, and runtime reproduction of reported issues remain outstanding.

## GitHub issue tracker

The remaining work is tracked in the private repository's GitHub Issues and assigned to `itschase`:

- [#1 Audit and secure every remotely triggered server event](https://github.com/itschase/OwlMTA-2026/issues/1)
- [#2 Make Discord the primary authentication source for production registration and login](https://github.com/itschase/OwlMTA-2026/issues/2)
- [#3 Replace legacy staff ranks with configurable capability grants](https://github.com/itschase/OwlMTA-2026/issues/3)
- [#4 Build website-free in-game management and retire unsafe legacy UCP access](https://github.com/itschase/OwlMTA-2026/issues/4)
- [#5 Make server configuration safe and reproducible](https://github.com/itschase/OwlMTA-2026/issues/5)
- [#6 Design and stage a versioned schema migration](https://github.com/itschase/OwlMTA-2026/issues/6)
- [#7 Build the player and staff feature usage guide](https://github.com/itschase/OwlMTA-2026/issues/7)
- [#8 Remove the embedded BMX score endpoint credential](https://github.com/itschase/OwlMTA-2026/issues/8)

Specific source findings are also tracked individually:

- [#10 Character cash across character switching](https://github.com/itschase/OwlMTA-2026/issues/10) · [#11 Admin jail table mismatch](https://github.com/itschase/OwlMTA-2026/issues/11) · [#12 Forum login/schema calls](https://github.com/itschase/OwlMTA-2026/issues/12) · [#13 Missing activation-mail service](https://github.com/itschase/OwlMTA-2026/issues/13)
- [#14 GameMaster/donor coupling and exports](https://github.com/itschase/OwlMTA-2026/issues/14) · [#15 Insurance/inventory event ownership](https://github.com/itschase/OwlMTA-2026/issues/15) · [#16 Car-shop order/range validation](https://github.com/itschase/OwlMTA-2026/issues/16) · [#17 Elevator SQL NULL fallback](https://github.com/itschase/OwlMTA-2026/issues/17) · [#18 Verify ammo visibility report](https://github.com/itschase/OwlMTA-2026/issues/18)
- [#19 Portable Docker and pinned MTA artifact](https://github.com/itschase/OwlMTA-2026/issues/19) · [#20 License/source-header mismatch](https://github.com/itschase/OwlMTA-2026/issues/20) · [#21 Startup list and manifests](https://github.com/itschase/OwlMTA-2026/issues/21) · [#22 Website ACL identity](https://github.com/itschase/OwlMTA-2026/issues/22) · [#23 Staff helper player-type guard](https://github.com/itschase/OwlMTA-2026/issues/23) · [#24 Wildcard ACL and client-side rank mirrors](https://github.com/itschase/OwlMTA-2026/issues/24)
- [#38 Faction roster/invitation authorization](https://github.com/itschase/OwlMTA-2026/issues/38) · [#39 Faction rank/duty authorization](https://github.com/itschase/OwlMTA-2026/issues/39) · [#40 Prison mutation authorization](https://github.com/itschase/OwlMTA-2026/issues/40) · [#41 MDC identity/search/mutation authorization](https://github.com/itschase/OwlMTA-2026/issues/41) · [#42 Account readiness typo](https://github.com/itschase/OwlMTA-2026/issues/42) · [#43 Registration failure safety](https://github.com/itschase/OwlMTA-2026/issues/43) · [#44 Remove old website links from in-game flows](https://github.com/itschase/OwlMTA-2026/issues/44)
- [#45 Insurance payment/claim validation](https://github.com/itschase/OwlMTA-2026/issues/45) · [#46 Property purchase/keypad validation](https://github.com/itschase/OwlMTA-2026/issues/46) · [#47 Job selection validation](https://github.com/itschase/OwlMTA-2026/issues/47) · [#48 Payday/shop wage event audit](https://github.com/itschase/OwlMTA-2026/issues/48)

See [DISCUSSIONS_AND_ISSUES.md](../planning/DISCUSSIONS_AND_ISSUES.md) for the workflow on adding source-backed findings and maintaining their status. Resource explanations are indexed in the [Resources Discussions catalog](https://github.com/itschase/OwlMTA-2026/discussions/37); the proposed website-free plan is [Discussion #36](https://github.com/itschase/OwlMTA-2026/discussions/36). Discussions hold topic documentation and design history; they do not replace these actionable issues.

## Website-free development direction

There is no UCP website available to use or treat as a required part of this project. The gamemode must be operable without a management website. Prioritize character, staff, faction, and administrative management through authenticated in-game interfaces and server-side workflows. A future website is an optional companion. Discord authorization is the planned production registration/login source through a narrowly scoped API; the MTA process can boot independently, while new logins fail closed when identity cannot be verified. An explicit audited operator bootstrap/recovery path is required.

## Discord role integration direction

Use a separate trusted Discord integration service or web API to map a verified Discord user ID to one game account and retrieve that user's roles in the configured guild. The MTA server should consume only the service's authenticated, bounded capability grants; it must not accept role IDs from a client. Treat `Support` and its levels as donator entitlements with no staff capabilities. Ship a fill-in mapping template for admin tiers, GameMaster, and donor tiers, with no role IDs preconfigured; each operator supplies IDs after creating roles in their own Discord server. Cache short-lived grants, fail closed when they expire, audit changes, and provide a documented operator-only, audited bootstrap/recovery mechanism for first setup and identity-service outages without silently enabling password-only production login.
