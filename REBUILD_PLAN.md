# OwlGaming MTA rebuild plan

## Goal

Restore this repository as a maintainable, deployable OwlGaming roleplay server, then modernize its database and account-management integrations without losing existing player data. Discord should be an optional identity and staff-management integration, not a dependency for starting the game server.

## What the repository currently contains

- The runtime is a large collection of MTA resources under `mods/deathmatch/resources` with additional disabled or archived resources under `resource-archive`.
- Runtime state is split between the `mta` and `core` MySQL databases. Their bootstrap snapshots are `mods/deathmatch/data/mta.sql` and `mods/deathmatch/data/core.sql`; `data.sql` appears to hold a small settings table. Several tables use MyISAM and `latin1`, and the `core` schema includes account, forum, and Django-era UCP data.
- `settings.xml.bak` configures separate runtime/core DB connections, a UCP website password, a forums API key, and an Imgur client ID. The server login flow calls a localhost activation-mail endpoint. No Discord integration was found in the current resource/config search.
- The Docker image downloads the current MTA Linux server binary at build time, while the checked-in server config specifies a minimum client version of `1.5.7-9.20324.0`. This needs an explicit compatibility policy and repeatable pinned builds.
- The Dockerfile creates `mtasa` with Debian's `useradd`, then invokes Alpine-specific `adduser -D -S`; that second command fails on the Debian base image. The redundant command is removed in this initial repair.

## Proposed delivery sequence

### 1. Establish a reproducible boot

- Make container build/start deterministic and validate required configuration before starting MTA.
- Pin or otherwise record the MTA server artifact version; align the server config's client minimum with the supported release.
- Separate development and production configuration, remove embedded secrets from generated config artifacts, and document required ports and health/log behavior.
- Boot the server against disposable databases and resolve resource load errors before feature work.

### 2. Stabilize the existing game mode

- Inventory resources, their dependencies, SQL tables, and resource start order.
- Triage startup errors and high-impact player paths first: account login/registration, character selection/creation, persistence, inventory, vehicles, and jobs/factions.
- Add focused checks for Lua syntax, resource metadata references, SQL bootstrap consistency, and container startup as these workflows are repaired.
- Keep archived resources out of the active dependency graph unless a required gameplay feature depends on them.

### 3. Introduce a versioned database layout

- Preserve the current `mta` and `core` schemas as the legacy import contract initially; do not rename or drop tables in place.
- Define a new, documented schema with explicit ownership boundaries for identity/accounts, characters/gameplay, staff/audit, and integration data.
- Add ordered, repeatable migrations and a read-only preflight that checks source version, row counts, duplicates, and orphaned IDs before any copy or cutover.
- Migrate incrementally to InnoDB and `utf8mb4`, adding foreign keys only after existing data passes integrity checks. Keep rollback snapshots and a dual-read/verification stage before cutover.

### 4. Replace the missing UCP path

- Provide a separate web API/UI for account self-service: account recovery, email verification, linked Discord identity, character overview, and support requests.
- Use Discord OAuth2 for identity proof and a unique account-link table; never use a Discord username as a credential or silently merge accounts by email.
- Use short-lived, revocable sessions, rate limits, CSRF protection, and audit records for account changes. Keep password hashing compatible during transition and rehash on successful login where needed.
- Keep the MTA server as the authority for gameplay and use a narrow authenticated API for actions requiring in-game changes.

### 5. Add Discord-focused operations

- Link Discord identities to existing accounts through an explicit in-game or web confirmation flow.
- Make configured Discord role IDs the source of truth for staff capabilities, including distinct administrator levels and the GameMaster role. Treat `supporter_level` and the Discord `Support` role as donator tiers only; they must never grant moderation powers. Map roles to named capabilities rather than relying on Discord role names or hard-coded role ordering.
- Ship a fill-in role mapping template with entries for admin tiers, GameMaster, and donator tiers. Leave role IDs unset with clear setup instructions; each operator creates roles in their own Discord server and fills in their own IDs before enabling role integration.
- Resolve and cache role grants on the server through a trusted bot/API integration. Never accept a Discord user ID, role list, or rank supplied by an MTA client. Fail closed when role state is missing or stale, with a narrowly scoped owner recovery path for an offline Discord outage.
- Preserve existing gameplay checks behind a single server-side authorization service during migration. Translate calls such as `isPlayerAdmin` and `isPlayerSupporter` into capability checks first, then migrate callers in groups while keeping permission behavior explicit and auditable.
- Keep GameMaster distinct from administrator and donator permissions. Role revocation must invalidate cached capabilities and in-game sessions promptly.
- Add staff workflows only after authorization mapping is documented. Enforce permissions server-side and log every staff action.
- Queue outbound notifications and make retries idempotent; Discord outages must not block login or gameplay.

## Initial priorities

1. Build and boot the existing server in a disposable environment.
2. Capture the startup log and resolve blocking resource/database errors.
3. Agree on the account and character data model before changing SQL layouts.
4. Build a migration inventory from both schema snapshots and the code that reads/writes those tables.
5. Implement UCP replacement and Discord linking only after the account migration and threat boundaries are defined.

## Safety constraints for schema work

- Never run a destructive migration against a live database as part of development.
- Treat the checked-in SQL files as legacy snapshots, not proof that an existing production database matches them.
- Require a backup, migration dry-run report, and explicit cutover plan before changing the live schema.
- Keep Discord tokens, OAuth secrets, database passwords, and API keys outside the repository.

## Permission migration principles

- Discord assigns roles; the gamemode grants narrowly defined capabilities. A role such as `GameMaster` should grant only the GM actions configured for that server.
- Administrator tiers should be explicit capabilities (`admin.trial`, `admin.standard`, `admin.senior`, `admin.lead`, `admin.head`) with documented inheritance rules, not implicit numeric comparisons against a role position.
- Donator entitlements, GameMaster, scripter, mapper, and vehicle-team permissions remain separate grants. The legacy `supporter_level` represents donator tiers, but `isPlayerSupporter` is also used in some staff-like checks in this codebase. Audit each call site and remove donor tier as an authorization path for moderation. A Discord role may grant more than one capability only through visible configuration.
- Check authorization on the server for every state-changing action. Client UI checks are presentation only.
- Record who changed a role mapping, who received/revoked the grant, when it changed, and which action used it. Never log bot tokens or OAuth secrets.
- During rollout, compare old and new permission decisions in logs without letting the comparison grant access. Cut over by staff group after review.
