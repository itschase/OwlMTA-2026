# OwlGaming MTA — Rebuild in Progress

This repository is an active overhaul of the OwlGaming roleplay gamemode for Multi Theft Auto (MTA). It carries forward a large, mature codebase while we map how its resources work together, repair defects, modernize server-side validation, and make the project practical for independent server owners to configure and run.

**This is work in progress.** The inherited code and setup instructions have not yet been validated as a complete, working server deployment. Source reviews and selected code changes are underway; do not treat the current branch as a tested release.

## Project direction

- Keep the gamemode self-hostable and suitable for importing into another operator's server.
- Make account, character, gameplay, and routine staff workflows usable in game without requiring a website.
- Use Discord authorization as the planned primary identity path for registration and future logins. Operators configure their own authorization service and guild; role IDs ship blank, and unmapped roles grant no staff or donor access. A management website is not required.
- Separate staff authority from supporter/donor levels. Supporter levels represent donor benefits and must not grant staff permissions.
- Provide a documented API boundary so an independently built website or service can integrate without coupling core gameplay to that website.
- Make external services such as media storage and metrics/log search optional adapters that can be enabled by an operator.
- Document what resources do, how players and staff use them, how operators configure them, and how they depend on one another.

These are project goals, not claims that each integration or workflow is production-ready. An initial standalone Discord identity service and optional MTA account adapter now exist at source level: the game can begin linked-account admission, activate a bounded identity session after local gates, compare named capabilities without granting from them, and disconnect confirmed revocations. Legacy password registration/login and numeric authority remain active, durable provisioning and full capability cutover are incomplete, and no Discord/MTA runtime has been validated. The server process must still be able to start without the companion service, while a future Discord-primary production policy must fail closed rather than silently fall back to password-only login.

## Current state

The repository is in source-review and hardening work. The existing resource tree, account and character flows, staff/faction systems, vehicle and property features, and data model are being documented and reviewed incrementally. Some source-level defects and authorization boundaries have been corrected, and findings are tracked in GitHub Issues. Runtime behavior remains unverified until the project is brought up in a controlled MTA and database environment.

The inherited database and configuration still reflect the legacy gamemode. Schema restructuring, compatibility, deployment requirements, and upgrade/migration behavior are open work. No Discord role IDs, bot credentials, API secrets, or server-specific settings are supplied by this repository. Discord identity can be configured independently of role mapping; until role IDs are filled in, no Discord role-based staff or donor capabilities are granted.

### Latest fixed-in-source checkpoint — October 29, 2026

- Account lifecycle now has a canonical full-session logout distinct from character change, plus optional Discord-linked admission/session activation and confirmed-revocation disconnect handling. Password retirement, durable session leases, provisioning, recovery, and live service behavior remain open.
- Selected staff/application actions compare named Discord capabilities in shadow mode while legacy staff predicates remain enforcement. Donor/supporter tiers were removed from the reviewed freeze, nudge, application-bypass, and application-manager authority paths; supporter still requires a complete call-site audit.
- The application system now keeps quiz answer keys server-side, binds quiz and essay submission to authenticated accounts and stored stages, uses expiring server question snapshots, verifies affected rows, and avoids delete-before-insert replacement. Review decisions settle the application/account state together. Step-3 privacy/replay, reconnect/restart recovery, MyISAM failure behavior, and runtime validation remain open.
- No MTA server, game client, database, Discord application/service, or gameplay environment has been run. Every item above is `fixed-in-source`, not `runtime-verified` or release-ready.

See the [current next-work record](docs/planning/NEXT_WORK.md), [legacy-login migration map](docs/architecture/LEGACY_LOGIN_DISCORD_MIGRATION.md), [capability migration matrix](docs/architecture/CAPABILITY_MIGRATION_MATRIX.md), and [`apps` resource dossier](docs/resources/apps.md) for evidence and remaining work.

## Documentation and project tracking

Start with the [documentation hub](docs/README.md). The principal guides are:

- [Rebuild plan](docs/planning/REBUILD_PLAN.md) — phases, priorities, and readiness work.
- [Agent guidelines and activity read log](AGENTS.md) — operational conventions, rules, and chronological read log for multi-agent collaboration.
- [Gamemode architecture guide](docs/architecture/GAMEMODE_GUIDE.md) — major systems and resource relationships.
- [Resource catalog](docs/reference/RESOURCE_CATALOG.md), [resource dossiers](docs/resources/README.md), [documentation status ledger](RESOURCE_DOCUMENTATION_STATUS.csv), and [resource startup inventory](RESOURCE_INVENTORY.csv) — manifest coverage, maintained source reviews, row-by-row documentation progress, and startup inventory.
- [Resource and script audit playbook](docs/planning/RESOURCE_AUDIT_PLAYBOOK.md) — documentation coverage, evidence standards, and completion gates.
- [Feature usage guide](docs/guides/FEATURE_USAGE_GUIDE.md) — feature discovery and usage notes.
- [Player wiki](docs/guides/PLAYER_WIKI.md) — player-facing workflows and questions.
- [Staff and admin guide](docs/guides/STAFF_ADMIN_GUIDE.md) — staff capabilities and operational procedures.
- [Server operator guide](docs/guides/SERVER_OPERATOR_GUIDE.md) — setup, configuration, dependencies, and hosting notes.
- [Codebase review](docs/architecture/CODEBASE_REVIEW.md) and [enhancement register](docs/planning/ENHANCEMENT_REGISTER.md) — findings and improvement opportunities.
- [Project knowledge log](docs/architecture/PROJECT_KNOWLEDGE.md) — consolidated discoveries and decisions.
- [Discord identity and permissions design](docs/architecture/DISCORD_AUTH_DESIGN.md) and [Discord integration plan](docs/architecture/DISCORD_INTEGRATION_PLAN.md) — proposed identity linking and configurable role-to-capability mapping.
- [Optional integration API contract](docs/architecture/API_CONTRACT.md) — boundary for future external clients and services.
- [In-game UI framework plan](docs/architecture/UI_FRAMEWORK_PLAN.md) — a future direction for consistent in-game interfaces.
- [Organizations framework](docs/architecture/ORGANIZATIONS_FRAMEWORK.md) — compatibility-first migration from legacy factions to general organizations, capabilities, assets, finance, and lifecycle.
- [Criminal roleplay framework](docs/architecture/CRIMINAL_ROLEPLAY_FRAMEWORK.md) — connected opportunity, market, evidence, investigation, justice, and counterplay design.
- [Living roleplay systems blueprint](docs/architecture/ROLEPLAY_SYSTEMS_BLUEPRINT.md) — shared platform primitives and a complete connected-domain opportunity map.
- [Current economy/business](docs/architecture/ECONOMY_AND_BUSINESS_CURRENT_STATE.md), [criminal justice](docs/architecture/CRIMINAL_JUSTICE_CURRENT_STATE.md), and [administration](docs/architecture/ADMINISTRATION_CURRENT_STATE.md) maps — source-reviewed inherited behavior and modernization boundaries.
- [Documentation and planning program](docs/planning/DOCUMENTATION_PROGRAM.md) — artifact hierarchy, publishing lanes, quality gates, batch workflow, and focus controls.
- [Issues and Discussions index](docs/planning/DISCUSSIONS_AND_ISSUES.md) — published tracker links and documentation workflow.
- [Next work record](docs/planning/NEXT_WORK.md) — most recent fixed-in-source checkpoint, publication evidence, unresolved risks, and bounded continuation.
- [Coding conventions](docs/reference/coding_conventions.md) and [useful functions](docs/reference/useful_functions.md) — inherited developer references under review.

Use [GitHub Issues](https://github.com/itschase/OwlMTA-2026/issues) for actionable defects and implementation tasks. Use [GitHub Discussions](https://github.com/itschase/OwlMTA-2026/discussions) for feature plans, resource documentation, gameplay and staff guidance, operator knowledge, and design questions. Record source findings as findings; mark runtime claims as unverified until tested on a server.

## Development status and contributions

Changes should preserve existing player workflows where possible, validate remote event callers and server-owned state, and make authority decisions using explicit capabilities rather than trusting client-supplied values. Discord role mappings remain operator-configured, with supporter tiers modeled separately from staff access. Existing local credentials are a migration concern; production login must follow the configured Discord authorization policy.

Before proposing a behavior change, identify the resource, its metadata and dependencies, the client/server event flow, related data tables, and the operator-facing configuration. For each new or changed feature, document player use, staff use, operator setup, and known limitations as applicable. Runtime validation should be recorded separately from static source review.

See [Rebuild plan](docs/planning/REBUILD_PLAN.md) for the current work sequence. Release and deployment steps are still being verified; the previous source README is preserved below for historical reference only.

<details>
<summary>Original source README</summary>

# OwlGaming MTA

This repository contains the OwlGaming MTA codebase for Multi Theft Auto. The recommended way to deploy the code is using a docker image.

## Credits

The code in this repository comes from various sources from probably nearly a decade of development. Thank you to everyone who contributed over the years.

## Building for release

- Build the image `docker build -t owlgaming-mta .`
- Refer to the environment variable below and deploy using your MySQL Database
```shell
docker run -p 22003:22003 -p 22005:22005 -p 22126:22126/udp -e MTA_DATABASE_NAME=... owlgaming-mta
```
- You can grab the latest structures for your database from `mods/deathmatch/data`

## Logs

Logs are written to `mods/deathmatch/resources/logs/logs` as they are created in game. It's recommended to pick these up using Filebeat with Elasticsearch to make them searchable.

## Quick Links

* [Coding Conventions](docs/reference/coding_conventions.md)
* [Useful Functions](docs/reference/useful_functions.md)

## Docker Build Environment Variables

### MTASERVER.CONF
- `SERVER_IP`
- `SHOULD_BROADCAST`
- `OWNER_EMAIL_ADDRESS`

### SETTINGS.XML
- `PRODUCTION_SERVER`
- `MTA_DATABASE_NAME`
- `MTA_DATABASE_USERNAME`
- `MTA_DATABASE_PASSWORD`
- `MTA_DATABASE_HOST`
- `MTA_DATABASE_PORT`

- `CORE_DATABASE_NAME`
- `CORE_DATABASE_USERNAME`
- `CORE_DATABASE_PASSWORD`
- `CORE_DATABASE_HOST`
- `CORE_DATABASE_PORT`

- `FORUMS_API_KEY`
- `IMGUR_API_KEY`

</details>
