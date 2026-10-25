# Enhancement and discovery register

This is a living design backlog. Items are opportunities, not claims that work has been approved or implemented. Confirm each against current source and link actionable work to GitHub Issues before coding.

## Architecture and reliability

- Build an automated resource graph from manifests and `exports.*`/`call` references, then detect missing resources, exports, startup duplicates, implicit order, and dead resources.
- Add resource health checks and structured start/stop diagnostics with resource name, dependency, schema revision, and correlation ID.
- Replace manual duplicated config templates with validated config generation, required-variable checks, XML-safe substitution, and versioned examples.
- Pin MTA server artifacts and dependencies; produce reproducible deployment builds.
- Split schema migrations by database and owning resource, with migration checksums, preflight, backup, rollback plan, and schema compatibility gates.
- Replace MyISAM where transactional correctness is required; define transaction boundaries for multi-step money, inventory, ownership, and account provisioning.
- Standardize structured logs, safe error context, log rotation, retention, and operator-visible diagnostics without leaking secrets.
- Build an internal UI compatibility layer for lifecycle, focus/input, themes, reusable controls, layout, notifications, and consistent cleanup; adopt it incrementally instead of rewriting every screen.

## Player experience

- Replace broken activation email and website/forum dead ends with local in-game registration, recovery, appeals, rules/help, and account settings.
- Add clear failure messages for disabled external services instead of silently failing legacy HTTP calls.
- Provide a discoverable in-game help index built from resource feature metadata and command registration.
- Keep feature prerequisites visible: character state, item/license, faction membership, on-duty state, proximity, balance, and cooldown.
- Restore or deliberately retire features whose scripts exist but are not active in manifests (e.g. event-system BMX/Easter entries); document distinction between installed and started.

## Security and data integrity

- Audit every client-triggerable event by entry point, authoritative actor derivation, input validation, permission, proximity, ownership, rate limit, state transition, and audit logging.
- Centralize money/inventory/vehicle/property mutations into domain services with idempotency keys and transactional semantics.
- Add privacy ownership rules for phones/SMS/contacts, MDC, account records, inventories, and staff history.
- Create consistent hierarchy checks and immutable audit events for staff grants, bans, jails, faction rank changes, donor grants, and Discord role refreshes.
- Remove browser/client authority for prices, item IDs, vehicle IDs, account/character IDs, faction IDs, payer IDs, and status fields.
- Inventory HTTP-callable exports and apply deny-by-default ACL/network exposure; distinguish internal exports from public HTTP APIs.

## Discord authentication, authorization, and optional web integration

- Make Discord authorization the primary production identity path for registration and login. Keep the MTA process boot independent of the API and define an explicit operator setup/recovery path; do not silently fall back to password-only login.
- Use one-time game-account pairing, explicit consent, immutable Discord IDs, role-ID placeholders, bot/API secrets on trusted server side, and revocation/audit.
- Migrate legacy accounts by proof of control. Track active MTA sessions so a verified Discord authorization revocation disconnects the related session; bound lease and outage behavior.
- Keep admin levels, GameMaster/moderation, faction authority, and donor/supporter tiers distinct. Blank/unmapped role IDs grant no capabilities.
- Keep any future UCP/API as an optional adapter with a narrow authenticated contract and no duplicated business rules.
- Give website builders a self-hostable, versioned project API so they can choose their web stack and presentation without recreating account, role, or moderation policy. See `API_CONTRACT.md`.

## Businesses, jobs, and production

- Build a shared business/job framework for staffing, payroll, inventory, contracts, supply orders, maintenance, demand, and financial ledgers.
- Add bounded background operations for businesses, with stock, upkeep, staffing, demand, and catch-up caps. Active player work should remain valuable and predictable.
- Connect legal supply chains across jobs and businesses, starting with existing resources that can prove the order/delivery/payment path.
- Consider a configurable fictional illicit-production system using abstract recipes, risk, quality, distribution, evidence, and law-enforcement counterplay. Keep its content separate from real-world manufacturing instructions.
- Record every payout and stock change through authoritative, auditable domain services; define transaction and persistence guarantees before enabling automated money generation.

## Organizations and connected criminal roleplay

- Treat the legacy `factions` resource as a compatibility-backed generic organization aggregate. Move player-facing language, new APIs, and dashboards toward organizations without renaming tables, exports, events, and element data blindly.
- Define organization behavior through named capabilities and composable policies instead of duplicated numeric type branches. Keep Discord staff grants, donor tiers, organization roles, duty, and MTA ACL separate.
- Support public services, government, companies, newsrooms, clubs, unions, community groups, crews, gangs, criminal enterprises, fronts, and temporary task forces through one extensible organization foundation.
- Make recruitment, applications, relationships, units, assets, finance, succession, archival, and audit explicit lifecycle systems.
- Build criminal roleplay from contacts, preparation, opportunity, provenance, markets, evidence, investigation, justice, victim recovery, and meaningful failure rather than isolated payout commands.
- Use abstract fictional illicit recipes and configurable risk. Do not publish real harmful production instructions.
- Replace omniscient wanted markers with incident alerts, witness observations, evidence, authorized suspicion, warrants, and scoped case information.
- Design influence as changing relationships, market access, presence, information, and institutional attention instead of permanent kill-count territory.

Detailed direction lives in `ORGANIZATIONS_FRAMEWORK.md` and `CRIMINAL_ROLEPLAY_FRAMEWORK.md`.

## Immersive interaction and voice

- Prototype a shared contextual interaction registry for nearby vehicles, doors, interiors, NPCs, businesses, and service points; filter choices by current capability and world state.
- Add a configurable proximity-voice experience with whisper/normal/shout, radio, phone, and vehicle contexts, while retaining a controlled transition for existing text roleplay.
- Build a discoverable command/feature catalog that powers in-game help, examples, access descriptions, and staff command search.
- Add role-gated player/staff/operator dashboards as focused views over shared systems, including map-based interiors and operational status.

## Optional media and asset providers

- Design a `MediaStorageProvider` boundary for report evidence, administrative screenshots, and optional game assets; default disabled/local, no provider-specific calls from gameplay resources.
- FiveManage could be one configurable provider later. Keep API credentials server-side, use short-lived one-time upload URLs for untrusted clients, store provider IDs separately from gameplay records, and let operators disable or replace the provider.
- Confirm current API shape, file limits, retention, pricing, and terms before implementation. Do not assume a FiveManage SDK is enabled or required.

## Optional observability and log search

- Maintain local server, authentication, database, gameplay-audit, and deferred-query logs as the no-dependency baseline.
- Add secret/PII filtering, structured levels and correlation IDs, rotation and retention before building remote forwarding.
- Support an operator-selected collector/backend adapter. Grafana Alloy → Loki → Grafana is one optional path for searching and dashboards; it must be disabled unless configured and must not make server startup depend on Grafana.
- Keep labels low-cardinality to control Loki indexing costs; keep request IDs and individual player/account identifiers in structured metadata or log text with privacy controls.
- Document which log files are collected, network destinations, access controls, backup/retention, and how an operator disables the integration.

## Documentation system

- Every active and archived resource needs a catalog record: manifest path, purpose, user/staff/operator audiences, dependencies/exports, state ownership, active/archived status, known limitations, and links to detailed procedures.
- Keep four views distinct: resource architecture (what connects), player wiki (how to use it in-game), staff/admin handbook (authorized staff flows), operator runbook (install/configure/operate/recover), plus Discord design and engineering plan.
- Put actionable bugs/security defects in GitHub Issues; reserve Discussions for Q&A, design choices, planned features, and detailed topic explanations.
- Track each resource's documentation state as `cataloged`, `source-reviewed`, `player-documented`, `staff-documented`, `operator-documented`, and `runtime-verified`; do not label one level as another.
