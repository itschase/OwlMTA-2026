# Project knowledge base

This file records the current understanding built from reading the repository. It is an evidence-based source map, not a claim that the MTA server has booted or that gameplay has been exercised. Detailed feature instructions, Discord design, and issue workflow live in the linked documents below.

## What this repository is

OwlGaming MTA is a large Multi Theft Auto roleplay gamemode made from independent MTA resources. Resources provide client scripts, server scripts, configuration, maps, exports, and event handlers; `meta.xml` describes their contents and dependencies. A resource's client UI is only the presentation side. Server handlers and trusted server exports own game state and must repeat authorization and input validation.

The current inventory counted 1,093 Lua files in 144 active resource manifests and 114 more Lua files in `resource-archive`. Three SQL snapshots contain 125 `CREATE TABLE` statements. The checked-in server configuration lists 138 resource startup entries for 136 unique resources; eight active manifests are not listed there. These are source snapshot counts and may change as the repository changes.

## Runtime and major resource responsibilities

- `account`, `login-panel`, and character resources authenticate an account and then load a character. Account identity and role data are account-level; cash, bank balance, faction, inventory, and other gameplay state attach to a character or game entity.
- `mysql` exposes database connections and query helpers used across resources. `core` contains account and legacy forum/UCP data; `mta` contains character and gameplay records. Many consumers rely on shared exports, so schema and resource changes must be traced across callers.
- `global` and `integration` expose shared helpers, rank checks, configuration, logging, and MTA-facing utilities. They form a natural migration seam for centralized capabilities, but many resources also read rank element data directly.
- `factions` and `ranks` own the legacy generic organization aggregate, membership, and in-game rank permissions. Current numeric types include gangs, mafias, law, government, medical, other, news, and commercial groups; duplicated type labels have already drifted. Faction rank, staff authority, Discord role grants, and being on duty are separate states. New player-facing design uses organizations through a compatibility facade rather than a destructive global rename.
- `item-system`, `vehicle`, `interior`, and `bank` own shared gameplay APIs for items, vehicles, property, and finance. Shops, jobs, public safety, and player-facing activities call into those domains.
- `admin-system` includes staff tools, enforcement, reports, jail, and staff-rank management. Staff tools have high impact and need server-side permission checks at every event.
- `payday` and job resources alter money and recurring gameplay state; police, medical, prison, licensing, and insurance resources cross character, faction, vehicle, and finance boundaries.

See [GAMEMODE_GUIDE.md](GAMEMODE_GUIDE.md) for the larger resource and table map and [RESOURCE_INVENTORY.csv](../../RESOURCE_INVENTORY.csv) for startup/dependency detail.

## Identity and permissions learned so far

The current account path loads numeric legacy fields such as `admin`, `supporter`, VCT, mapper, scripter, and FMT. `supporter_level` is donor tier, not staff rank. Existing code nevertheless mixes supporter checks into staff-like access, while `getGameMasters()` currently selects supporters. Several server handlers also trust old element data or scattered numeric checks. This makes “who logged in,” “what a Discord role grants,” “what faction rank permits,” and “whether the character is on duty” separate policy questions.

Target direction: use verified Discord authorization as the primary production identity for registration and login; migrate existing accounts through a proof-of-control link; resolve configured Discord role IDs into explicit named capabilities on a trusted backend; keep `Support`/donor tiers separate from moderation; and have game server handlers authorize by account and current server-side grant. Operators receive blank role-ID slots and configure their own guild. Detailed flows and migration stages are in [DISCORD_AUTH_DESIGN.md](DISCORD_AUTH_DESIGN.md).

## Website-free operation and API boundary

The primary product is the in-game gamemode. Discord authorization is the planned production registration/login path; character creation, normal player features, and routine staff administration must not need a UCP or management website. A future website should be an optional client of a versioned API contract owned by the project, so its implementation can be chosen by the server operator without reimplementing core account, permission, or gameplay rules. The identity service is a production login dependency, but not a process boot dependency.

MTA server-side `fetchRemote` is asynchronous. External identity checks therefore need a pending state and callback-driven result, not a synchronous join/login dependency. New registration/login fails closed when the API or Discord cannot authorize the user. Active sessions use bounded leases, and a verified authorization revocation ends the associated session; outage and lease expiry behavior must be explicit. Source-level API availability is not runtime verified against the target server build.

## Findings and known boundaries

- Earlier committed source hardening covers sampled account creation, staff/faction managers, and banking flows. The current review batch extends source fixes and validation across account settings/tutorial onboarding, interior and map management, staff/admin and faction flows, custom shops and jobs, phone/MDC, police/prison, cache, towing, and vehicle-interior entry. These changes are not runtime-verified.
- The vehicle lock/engine/parking audit remains open. A partial vehicle-system edit was not accepted into this checkpoint; issues #91–93 remain open for a complete, reviewable implementation.
- Insurance and inventory remote-event validation, car-shop payment ordering/range, and the full remote-event audit remain open. A rough scan counted 181 remote event declarations in active server scripts; this is a triage count, not 181 confirmed vulnerabilities.
- Existing feature walkthroughs currently cover account/character flow, staff/faction tools, and banking. Jobs, inventory, vehicles, property, public safety, medical, prison, player reports, and more still need feature-by-feature documentation from UI to handler to stored state.
- The missing UCP website, local activation-email dependency, forum integration, Docker configuration substitution, unpinned MTA server download, and license/header mismatch are portability and importability issues. See the review and rebuild plan before attempting deployment.
- Do not start a server or use a live database as a shortcut for exploration. Runtime validation, when planned, must use a disposable database and documented version/configuration.

## Documentation map

- [README](../../README.md): repository entry point and quick links.
- [Gamemode architecture guide](GAMEMODE_GUIDE.md): resource graph, lifecycle, schema ownership, permission model, and bug queue.
- [Feature usage guide](../guides/FEATURE_USAGE_GUIDE.md): player/staff entry points and current behavior.
- [In-game UI framework plan](UI_FRAMEWORK_PLAN.md): existing UI inventory, shared component proposal, MTA renderer choices, and rollout.
- [Player Wiki](../guides/PLAYER_WIKI.md): simplified gameplay instructions and player perspective.
- [Staff and Admin Guide](../guides/STAFF_ADMIN_GUIDE.md): staff authority boundaries, workflows, and Discord capability direction.
- [Server Operator Guide](../guides/SERVER_OPERATOR_GUIDE.md): install, configure, operate, recover, and integrate the server.
- [Codebase review](CODEBASE_REVIEW.md): findings, evidence, priorities, and review status.
- [Discord design](DISCORD_AUTH_DESIGN.md): primary login identity, role mapping, capabilities, revocation, and cutover.
- [Discord integration plan](DISCORD_INTEGRATION_PLAN.md): pairing, API contract boundary, grants, outage behavior, and migration sequence.
- [Enhancement register](../planning/ENHANCEMENT_REGISTER.md): architecture, player, security, integration, and documentation opportunities.
- [Optional integration API contract](API_CONTRACT.md): self-hostable API boundary for Discord, websites, media storage, and operator-selected log search.
- [Organizations framework](ORGANIZATIONS_FRAMEWORK.md): source-grounded legacy boundary, target organization service, capabilities, lifecycle, persistence, and migration.
- [Criminal roleplay framework](CRIMINAL_ROLEPLAY_FRAMEWORK.md): proposed opportunity, market, evidence, investigation, justice, organization, and operator systems.
- [Living roleplay systems blueprint](ROLEPLAY_SYSTEMS_BLUEPRINT.md): connected roleplay domains and reusable platform primitives beyond isolated scripts.
- [Economy, jobs, payday, and business current state](ECONOMY_AND_BUSINESS_CURRENT_STATE.md): source-reviewed money, obligation, work, supply, and business boundaries.
- [Criminal, investigation, justice, and corrections current state](CRIMINAL_JUSTICE_CURRENT_STATE.md): inherited enforcement primitives, trust gaps, and missing connected domains.
- [Administration current state](ADMINISTRATION_CURRENT_STATE.md): privileged command/event surface, sensitive data, failure behavior, and modernization boundary.
- [Documentation and planning program](../planning/DOCUMENTATION_PROGRAM.md): publishing system, artifact ownership, quality gates, batch workflow, and focus controls.
- [Complete resource manifest catalog](../reference/RESOURCE_CATALOG.md): every active-tree and archived resource manifest with its declared purpose and client/server script counts.
- [Maintained resource dossiers](../resources/README.md): player, staff, operator, technical, connection, risk, and verification views for resources that have entered detailed review.
- [Resource documentation status ledger](../../RESOURCE_DOCUMENTATION_STATUS.csv): all 179 active-tree and archived manifest rows with tree/startup state, individual Discussion and dossier links, documentation state, runtime state, and next action.
- [Resource and script audit playbook](../planning/RESOURCE_AUDIT_PLAYBOOK.md): required resource dossier, human/technical documentation views, coverage states, and audit/publishing workflow.
- [Rebuild plan](../planning/REBUILD_PLAN.md): deployment, stabilization, schema, UCP, and Discord sequence.
- [Issues and Discussions workflow](../planning/DISCUSSIONS_AND_ISSUES.md): where defects and durable explanations belong.
