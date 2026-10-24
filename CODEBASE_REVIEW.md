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
5. `admin-system/staff_manager/staff_manager_s.lua` directly changes admin, supporter, and GM rank element data. That path and persistence need review before Discord becomes authoritative.

## Permission findings to validate and fix

- **Legacy forum authority:** `integration/functions_s.lua` and `integration/g_configs.lua` couple admin rank assignment to forum group IDs. These should become a compatibility adapter during migration, then be retired after Discord grants are authoritative.
- **Scattered checks:** The common helper layer is useful, but access is also checked directly through `admin_level`, `supporter_level`, duty flags, and `account:gmlevel` across many resources. A mechanical search found hundreds of permission references, so centralization and phased migration are required.
- **GameMaster drift:** `global/g_admin_globals.lua:getGameMasters()` currently returns players passing `integration:isPlayerSupporter()`. This conflates GameMaster status with a donator tier and should be replaced by an explicit GameMaster grant.
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
- `account/login-panel/server.lua` selects only `mtaserial` during registration duplicate checks but later reads `id` and `username` from that result.
- `account/s_characters.lua` character switching leaves live cash set; upstream PR #57 proposes clearing it. `adminjail_s.lua` writes jail columns against `accounts` although the checked-in jail columns are in `mta.account_details`; upstream PR #46 proposes the correction.
- The legacy UCP resource declares HTTP-callable management actions and provisions a `website` ACL account that belongs to the broad `Admin` group. The UCP web application itself is missing.
- PRs #48/#49 (car shop purchase range), #54 (admin interior transfer), #55 (ammo scope), and #58 (elevator ID fallback) are review references only; none were imported. PR #67 is Discord Rich Presence, not role-based authorization.
- A reference fork with broad gameplay changes and webhook notifications was inspected but not copied. Its Discord code does not establish role-based staff permissions.

## Review status

The account/data, gameplay-domain, and runtime/security architecture passes are complete at a map-and-triage level. The complete resource/event/query inventory, call-site authorization audit, dependency validation, disposable server boot, and runtime reproduction of reported issues remain outstanding. No tests or server boot were run during this documentation pass.

## Discord role integration direction

Use a separate trusted Discord integration service or web API to map a verified Discord user ID to one game account and retrieve that user's roles in the configured guild. The MTA server should consume only the service's authenticated, bounded capability grants; it must not accept role IDs from a client. Treat `Support` and its levels as donator entitlements with no staff capabilities. Ship a fill-in mapping template for admin tiers, GameMaster, and donor tiers, with no role IDs preconfigured; each operator supplies IDs after creating roles in their own Discord server. Cache short-lived grants, fail closed when they expire, audit changes, and provide a documented local owner recovery mechanism for first setup and Discord outages.
