# OwlGaming MTA rebuild plan

## Goal

Restore this repository as a maintainable, deployable OwlGaming roleplay server, then modernize its database and account-management integrations without losing existing player data. Discord authorization is the planned primary identity source for production registration and login. The MTA process should start independently of the identity service; production login should fail closed when Discord authorization cannot be verified.

## What the repository currently contains

- The runtime is a large collection of MTA resources under `mods/deathmatch/resources` with additional disabled or archived resources under `resource-archive`.
- Runtime state is split between the `mta` and `core` MySQL databases. Their bootstrap snapshots are `mods/deathmatch/data/mta.sql` and `mods/deathmatch/data/core.sql`; `data.sql` appears to hold a small settings table. Several tables use MyISAM and `latin1`, and the `core` schema includes account, forum, and Django-era UCP data.
- `settings.xml.bak` configures separate runtime/core DB connections, a UCP website password, a forums API key, and an Imgur client ID. The inherited login flow calls a localhost activation-mail endpoint. The current branch now includes an optional Discord-linked account adapter and server-only capability facade, but legacy password/forum paths remain active and no Discord application/service runtime has been verified.
- The Docker image downloads the current MTA Linux server binary at build time, while the checked-in server config specifies a minimum client version of `1.5.7-9.20324.0`. This needs an explicit compatibility policy and repeatable pinned builds.
- The Dockerfile creates `mtasa` with Debian's `useradd`, then invokes Alpine-specific `adduser -D -S`; that second command fails on the Debian base image. The redundant command is removed in this initial repair.

## Current fixed-in-source checkpoint

- Optional linked-account Discord admission, post-gate identity-session activation, server-only capability comparison, confirmed-revocation disconnect, lifecycle clearing, and canonical full-account logout exist in source. They do not yet constitute Discord-first registration/login, durable provisioning, password retirement, or runtime validation.
- Freeze/unfreeze, nudge, application bypass, and application-manager paths have bounded capability-shadow/donor-separation work. Legacy staff predicates remain enforcement; most action consumers remain to migrate.
- Application quiz, essay, and review paths now bind trusted callers and stored stages/targets, keep quiz keys server-side, bound question snapshots and answers, verify affected rows, use insert-first replacement, and reduce split application/account decisions. Memory-only challenges/streaks, step-3 privacy/replay, MyISAM recovery, and runtime evidence remain open.
- The repository remains in delivery stage 1 below. Do not interpret source fixes or static parsing as permission to skip the safe-start preflight.

## Proposed delivery sequence

### 1. Map and harden source before starting a server

- Inventory resources, their dependencies, SQL tables, and resource start order.
- Finish account, character, staff, faction, economy, inventory, vehicle and administration source reviews, prioritizing remotely triggered state changes.
- Correct confirmed defects, add secret-free diagnostics and document each resource flow and integration.
- Inspect metadata references, schema/bootstrap consistency, configuration generation and ACL statically. Do not start the server during this source-review stage.
- Keep archived resources out of the active dependency graph unless a required gameplay feature depends on them.

### 2. Prepare and validate a reproducible disposable boot

- Make the container build deterministic and validate required configuration before starting MTA.
- Pin or otherwise record the MTA server artifact version; align the server config's client minimum with the supported release.
- Separate development and production configuration, remove embedded secrets from generated config artifacts, and document required ports and health/log behavior.
- After source review is ready, boot only against disposable databases, capture startup errors, and resolve blocking resource load errors.
- Add focused checks for Lua syntax, resource metadata references, SQL bootstrap consistency, and container startup as workflows are repaired.

### 3. Introduce a versioned database layout

- Preserve the current `mta` and `core` schemas as the legacy import contract initially; do not rename or drop tables in place.
- Define a new, documented schema with explicit ownership boundaries for identity/accounts, characters/gameplay, staff/audit, and integration data.
- Add ordered, repeatable migrations and a read-only preflight that checks source version, row counts, duplicates, and orphaned IDs before any copy or cutover.
- Migrate incrementally to InnoDB and `utf8mb4`, adding foreign keys only after existing data passes integrity checks. Keep rollback snapshots and a dual-read/verification stage before cutover.

### 4. Keep account and server management website-free

- No UCP website is available. Keep character management, staff/faction tools, moderation and routine operator workflows in authenticated MTA interfaces and server-side resources. Discord is the planned production identity provider; the website is optional.
- Retire or narrowly secure legacy HTTP endpoints and remove the broad website ACL identity; do not assume a replacement management site exists.
- A website may be built later as an optional companion, but must not be needed for server startup or in-game management. The authorization API is needed for production registration/login and is not a UCP.
- Use a narrowly scoped OAuth callback/identity API for browser authorization. This is not a management website and must not replace in-game operations.
- Use unique immutable Discord account links, short-lived sessions/tickets, rate limits, CSRF protection on browser flows and audit records. Never silently merge accounts by username or email.
- Maintain a revocation feed or bounded session-status check so a Discord authorization revoke invalidates the linked MTA session promptly. Define outage and lease-expiry behavior; never leave a revoked session authorized indefinitely.

### 5. Add Discord-focused operations

- Link Discord identities to existing accounts through an explicit in-game or web confirmation flow.
- Make configured Discord role IDs the source of truth for staff capabilities, including distinct administrator levels and the GameMaster role. Treat `supporter_level` and the Discord `Support` role as donator tiers only; they must never grant moderation powers. Map roles to named capabilities rather than relying on Discord role names or hard-coded role ordering.
- Ship a fill-in role mapping template with entries for admin tiers, GameMaster, and donator tiers. Leave role IDs unset with clear setup instructions; each operator creates roles in their own Discord server and fills in their own IDs before enabling role integration.
- Resolve and cache role grants on the server through a trusted bot/API integration. Never accept a Discord user ID, role list, or rank supplied by an MTA client. Fail closed when role state is missing or stale, with a narrowly scoped owner recovery path for an offline Discord outage.
- Preserve existing gameplay checks behind a single server-side authorization service during migration. Translate calls such as `isPlayerAdmin` and `isPlayerSupporter` into capability checks first, then migrate callers in groups while keeping permission behavior explicit and auditable.
- Keep GameMaster distinct from administrator and donator permissions. Role revocation must invalidate cached capabilities and in-game sessions promptly.
- Add staff workflows only after authorization mapping is documented. Enforce permissions server-side and log every staff action.
- Queue outbound notifications and make retries idempotent. An identity-service outage must not stop process boot; new production registrations/logins fail closed, and existing sessions remain valid only through a bounded, documented lease.

## Initial priorities

1. Complete the source map and high-risk remote-event review before any server startup.
2. Agree on the account and character data model; inventory schema readers/writers and define a reversible migration.
3. Make container/config generation portable and pin the MTA server artifact.
4. Prepare a disposable environment and boot only after source review, then capture startup errors and validate resource loading.
5. Keep the gamemode manageable in-game without a website; stage Discord-primary registration/login, verified legacy-account linking, revocation handling, then role capabilities.

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
