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

These are project goals, not claims that each integration or workflow is already implemented. The Discord authentication service and MTA adapter are not implemented. The server process should be able to start without them, while user registration and login in production require a successful Discord authorization result. Development and owner recovery must use an explicit, audited setup path rather than silently falling back to password-only login.

## Current state

The repository is in source-review and hardening work. The existing resource tree, account and character flows, staff/faction systems, vehicle and property features, and data model are being documented and reviewed incrementally. Some source-level defects and authorization boundaries have been corrected, and findings are tracked in GitHub Issues. Runtime behavior remains unverified until the project is brought up in a controlled MTA and database environment.

The inherited database and configuration still reflect the legacy gamemode. Schema restructuring, compatibility, deployment requirements, and upgrade/migration behavior are open work. No Discord role IDs, bot credentials, API secrets, or server-specific settings are supplied by this repository. Discord identity can be configured independently of role mapping; until role IDs are filled in, no Discord role-based staff or donor capabilities are granted.

## Documentation and project tracking

Start with these guides, which are being expanded alongside the source review:

- [Rebuild plan](REBUILD_PLAN.md) — phases, priorities, and readiness work.
- [Gamemode architecture guide](GAMEMODE_GUIDE.md) — major systems and resource relationships.
- [Resource catalog](RESOURCE_CATALOG.md), [resource dossiers](docs/resources/README.md), [documentation status ledger](RESOURCE_DOCUMENTATION_STATUS.csv), and [resource startup inventory](RESOURCE_INVENTORY.csv) — manifest coverage, maintained source reviews, row-by-row documentation progress, and startup inventory.
- [Resource and script audit playbook](RESOURCE_AUDIT_PLAYBOOK.md) — documentation coverage, evidence standards, and completion gates.
- [Feature usage guide](FEATURE_USAGE_GUIDE.md) — feature discovery and usage notes.
- [Player wiki](PLAYER_WIKI.md) — player-facing workflows and questions.
- [Staff and admin guide](STAFF_ADMIN_GUIDE.md) — staff capabilities and operational procedures.
- [Server operator guide](SERVER_OPERATOR_GUIDE.md) — setup, configuration, dependencies, and hosting notes.
- [Codebase review](CODEBASE_REVIEW.md) and [enhancement register](ENHANCEMENT_REGISTER.md) — findings and improvement opportunities.
- [Project knowledge log](PROJECT_KNOWLEDGE.md) — consolidated discoveries and decisions.
- [Discord identity and permissions design](DISCORD_AUTH_DESIGN.md) and [Discord integration plan](DISCORD_INTEGRATION_PLAN.md) — proposed identity linking and configurable role-to-capability mapping.
- [Optional integration API contract](API_CONTRACT.md) — boundary for future external clients and services.
- [In-game UI framework plan](UI_FRAMEWORK_PLAN.md) — a future direction for consistent in-game interfaces.
- [Organizations framework](ORGANIZATIONS_FRAMEWORK.md) — compatibility-first migration from legacy factions to general organizations, capabilities, assets, finance, and lifecycle.
- [Criminal roleplay framework](CRIMINAL_ROLEPLAY_FRAMEWORK.md) — connected opportunity, market, evidence, investigation, justice, and counterplay design.
- [Living roleplay systems blueprint](ROLEPLAY_SYSTEMS_BLUEPRINT.md) — shared platform primitives and a complete connected-domain opportunity map.
- [Documentation and planning program](DOCUMENTATION_PROGRAM.md) — artifact hierarchy, publishing lanes, quality gates, batch workflow, and focus controls.
- [Issues and Discussions index](DISCUSSIONS_AND_ISSUES.md) — published tracker links and documentation workflow.
- [Coding conventions](coding_conventions.md) and [useful functions](useful_functions.md) — inherited developer references under review.

Use [GitHub Issues](https://github.com/itschase/OwlMTA-2026/issues) for actionable defects and implementation tasks. Use [GitHub Discussions](https://github.com/itschase/OwlMTA-2026/discussions) for feature plans, resource documentation, gameplay and staff guidance, operator knowledge, and design questions. Record source findings as findings; mark runtime claims as unverified until tested on a server.

## Development status and contributions

Changes should preserve existing player workflows where possible, validate remote event callers and server-owned state, and make authority decisions using explicit capabilities rather than trusting client-supplied values. Discord role mappings remain operator-configured, with supporter tiers modeled separately from staff access. Existing local credentials are a migration concern; production login must follow the configured Discord authorization policy.

Before proposing a behavior change, identify the resource, its metadata and dependencies, the client/server event flow, related data tables, and the operator-facing configuration. For each new or changed feature, document player use, staff use, operator setup, and known limitations as applicable. Runtime validation should be recorded separately from static source review.

See [Rebuild plan](REBUILD_PLAN.md) for the current work sequence. Release and deployment steps are still being verified; the previous source README is preserved below for historical reference only.

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

* [Coding Conventions](coding_conventions.md)
* [Useful Functions](useful_functions.md)

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
