# OwlMTA-2026 documentation

This directory is the maintained documentation hub for the rebuild. Repository Markdown is organized by purpose so architecture, audience instructions, planning records, generated references, and per-resource dossiers can expand without returning clutter to the repository root.

All runtime behavior remains unverified unless a document explicitly records a controlled runtime result. Source review, proposed design, fixed-in-source work, and runtime verification are separate states.

## Architecture and framework design

- [Project knowledge](architecture/PROJECT_KNOWLEDGE.md) — consolidated source-backed understanding and documentation map.
- [Gamemode guide](architecture/GAMEMODE_GUIDE.md) — lifecycle, domains, resource relationships, persistence, and security boundaries.
- [Codebase review](architecture/CODEBASE_REVIEW.md) — audit findings, risks, and review state.
- [Discord authorization design](architecture/DISCORD_AUTH_DESIGN.md) and [integration plan](architecture/DISCORD_INTEGRATION_PLAN.md) — identity, role mapping, capabilities, leases, revocation, and migration.
- [Legacy Login to Discord Session Migration](architecture/LEGACY_LOGIN_DISCORD_MIGRATION.md) — source-reviewed consumer map and ordered conversion from password/forum authority to Discord-backed account sessions.
- [API contract](architecture/API_CONTRACT.md) — optional self-hosted external service and website boundary.
- [UI framework plan](architecture/UI_FRAMEWORK_PLAN.md) — shared in-game application and interaction direction.
- [Organizations Framework](architecture/ORGANIZATIONS_FRAMEWORK.md) — compatibility-first migration from legacy factions.
- [Criminal Roleplay Framework](architecture/CRIMINAL_ROLEPLAY_FRAMEWORK.md) — opportunity, markets, evidence, investigation, justice, and counterplay.
- [Living Roleplay Systems Blueprint](architecture/ROLEPLAY_SYSTEMS_BLUEPRINT.md) — connected roleplay domains and reusable platform primitives.
- [Economy, Jobs, Payday, and Business: Current State](architecture/ECONOMY_AND_BUSINESS_CURRENT_STATE.md) — inherited money, recurring obligation, job, supply, and business boundaries.
- [Criminal Roleplay, Investigation, and Corrections: Current State](architecture/CRIMINAL_JUSTICE_CURRENT_STATE.md) — implemented enforcement primitives and missing connected domains.
- [Administration System: Current State](architecture/ADMINISTRATION_CURRENT_STATE.md) — privileged command/event surface, dependencies, risks, and target boundary.

## Audience guides

- [Player Wiki](guides/PLAYER_WIKI.md)
- [Feature Usage Guide](guides/FEATURE_USAGE_GUIDE.md)
- [Staff and Admin Guide](guides/STAFF_ADMIN_GUIDE.md)
- [Server Operator Guide](guides/SERVER_OPERATOR_GUIDE.md)

## Planning and project governance

- [Rebuild Plan](planning/REBUILD_PLAN.md)
- [Agent operations guide](agent-guidelines.md) — model-neutral startup, shared-checkout, security, publication, credential, and handoff workflow.
- [Mandatory agent rules and activity read log](../AGENTS.md) — repository requirements and chronological verified handoffs.
- [AI & Agent Operations Discussion Program](planning/AGENT_OPERATIONS_DISCUSSIONS.md) — public category structure for autonomous contributor onboarding, research, development, documentation, publication, and coordination.
- [Enhancement Register](planning/ENHANCEMENT_REGISTER.md)
- [Documentation and Planning Program](planning/DOCUMENTATION_PROGRAM.md)
- [Resource Audit Playbook](planning/RESOURCE_AUDIT_PLAYBOOK.md)
- [Command and Interaction Strategy](planning/COMMAND_AND_INTERACTION_STRATEGY.md) — evaluate command audiences and use cases, and map suitable workflows to in-game controls while preserving validated server authority.
- [Issues and Discussions workflow/index](planning/DISCUSSIONS_AND_ISSUES.md)
- [Next work record](planning/NEXT_WORK.md) — current verified state, bounded next audit batch, tracker follow-up, and safe-start gate.
- [Static Safe-Start Preflight](planning/SAFE_START_PREFLIGHT.md) — confirmed inherited boot path, blockers, disposable environment, ordered gates, and later smoke matrix.

## Resource documentation

- [Resource dossier index](resources/README.md) — maintained player/staff/operator/technical reviews.
- [Complete manifest catalog](reference/RESOURCE_CATALOG.md) — generated active/archive inventory with documentation notes.
- [Resource documentation status ledger](../RESOURCE_DOCUMENTATION_STATUS.csv) — row-by-row publication and verification state.
- [Resource startup inventory](../RESOURCE_INVENTORY.csv) — tracked startup snapshot and manifest metadata.

## Inherited developer reference

- [Coding conventions](reference/coding_conventions.md)
- [Useful functions](reference/useful_functions.md)

These references are inherited material under review; they do not override the current security, architecture, or documentation rules.

- [MTA server event and outbound request notes](reference/MTA_SERVER_BOUNDARIES.md).
