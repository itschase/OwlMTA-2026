# OwlMTA-2026 documentation

This directory is the maintained documentation hub for the rebuild. Repository Markdown is organized by purpose so architecture, audience instructions, planning records, generated references, and per-resource dossiers can expand without returning clutter to the repository root.

All runtime behavior remains unverified unless a document explicitly records a controlled runtime result. Source review, proposed design, fixed-in-source work, and runtime verification are separate states.

## Architecture and framework design

- [Project knowledge](architecture/PROJECT_KNOWLEDGE.md) — consolidated source-backed understanding and documentation map.
- [Gamemode guide](architecture/GAMEMODE_GUIDE.md) — lifecycle, domains, resource relationships, persistence, and security boundaries.
- [Codebase review](architecture/CODEBASE_REVIEW.md) — audit findings, risks, and review state.
- [Discord authorization design](architecture/DISCORD_AUTH_DESIGN.md) and [integration plan](architecture/DISCORD_INTEGRATION_PLAN.md) — identity, role mapping, capabilities, leases, revocation, and migration.
- [API contract](architecture/API_CONTRACT.md) — optional self-hosted external service and website boundary.
- [UI framework plan](architecture/UI_FRAMEWORK_PLAN.md) — shared in-game application and interaction direction.
- [Organizations Framework](architecture/ORGANIZATIONS_FRAMEWORK.md) — compatibility-first migration from legacy factions.
- [Criminal Roleplay Framework](architecture/CRIMINAL_ROLEPLAY_FRAMEWORK.md) — opportunity, markets, evidence, investigation, justice, and counterplay.
- [Living Roleplay Systems Blueprint](architecture/ROLEPLAY_SYSTEMS_BLUEPRINT.md) — connected roleplay domains and reusable platform primitives.

## Audience guides

- [Player Wiki](guides/PLAYER_WIKI.md)
- [Feature Usage Guide](guides/FEATURE_USAGE_GUIDE.md)
- [Staff and Admin Guide](guides/STAFF_ADMIN_GUIDE.md)
- [Server Operator Guide](guides/SERVER_OPERATOR_GUIDE.md)

## Planning and project governance

- [Rebuild Plan](planning/REBUILD_PLAN.md)
- [Enhancement Register](planning/ENHANCEMENT_REGISTER.md)
- [Documentation and Planning Program](planning/DOCUMENTATION_PROGRAM.md)
- [Resource Audit Playbook](planning/RESOURCE_AUDIT_PLAYBOOK.md)
- [Issues and Discussions workflow/index](planning/DISCUSSIONS_AND_ISSUES.md)

## Resource documentation

- [Resource dossier index](resources/README.md) — maintained player/staff/operator/technical reviews.
- [Complete manifest catalog](reference/RESOURCE_CATALOG.md) — generated active/archive inventory with documentation notes.
- [Resource documentation status ledger](../RESOURCE_DOCUMENTATION_STATUS.csv) — row-by-row publication and verification state.
- [Resource startup inventory](../RESOURCE_INVENTORY.csv) — tracked startup snapshot and manifest metadata.

## Inherited developer reference

- [Coding conventions](reference/coding_conventions.md)
- [Useful functions](reference/useful_functions.md)

These references are inherited material under review; they do not override the current security, architecture, or documentation rules.
