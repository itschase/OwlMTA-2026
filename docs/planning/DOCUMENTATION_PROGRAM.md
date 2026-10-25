# Documentation and Planning Program

## Purpose

The rebuild needs broad documentation without losing architectural focus. This program defines how discoveries, ideas, defects, decisions, and implementation work become durable, connected records rather than scattered chat notes.

## Canonical artifact layers

| Layer | Purpose | Canonical location |
|---|---|---|
| Repository overview | Product direction, status, warnings, and entry points | Root `README.md`, `docs/README.md`, and `docs/architecture/PROJECT_KNOWLEDGE.md` |
| Current architecture | Source-grounded resource, lifecycle, database, permission, and data-flow understanding | `docs/architecture/GAMEMODE_GUIDE.md`, `docs/architecture/CODEBASE_REVIEW.md`, and resource dossiers |
| Target architecture | Proposed cross-resource frameworks and migration boundaries | Named framework/design Markdown files |
| Audience guidance | What players, staff, and operators actually do | Player Wiki, Staff/Admin Guide, Server Operator Guide, and feature guides |
| Resource record | One maintained technical and human explanation per manifest | `docs/resources/<resource>.md` and the coverage ledger |
| Decision/history | Open questions, alternatives, rationale, and accessible explanations | GitHub Discussions |
| Action backlog | One reproducible defect or bounded implementation outcome | GitHub Issues |
| Delivery grouping | Release-oriented sequencing and exit criteria | GitHub Milestones and rebuild plan |
| Verification | Static checks, controlled runtime results, failures, and evidence | Issue comments, dossier status, and release/startup records |

Repository Markdown is the maintained source of truth. Discussions make it discoverable and preserve design conversation. Issues track work; they do not replace architecture documentation.

## Documentation packages

Every substantial system should receive a package with:

1. **Current-state evidence:** resources, scripts, events, exports, commands, tables, configuration, integrations, and active/archive/startup state.
2. **Human explanation:** what a player experiences and why the system matters.
3. **Staff explanation:** authority, workflow, target conditions, audit, recovery, and prohibited shortcuts.
4. **Operator explanation:** configuration, dependencies, startup, storage, privacy, maintenance, failure, backup, and rollback.
5. **Target design:** desired behavior, domain boundary, alternatives, compatibility, and non-goals.
6. **Security model:** authoritative actor, trusted state, validation, rate limits, concurrency, idempotency, privacy, and audit.
7. **Connection map:** upstream providers, downstream consumers, shared data, and cross-domain consequences.
8. **Delivery slices:** smallest coherent proof, later expansion, production-hardening requirements, and migration order.
9. **Verification matrix:** static evidence, disposable runtime scenarios, failure injection, regression cases, and status.
10. **Published links:** repository document, Discussion, Issues, milestone, related resource dossiers, and audience guides.

## Status vocabulary

- `cataloged`: a manifest or concept is known, but behavior has not been traced.
- `source-reviewed`: manifest-loaded scripts and material call paths have been inspected.
- `documented-current`: current behavior is explained for relevant audiences.
- `documented-target`: proposed behavior and migration boundary are explained.
- `issue-backed`: actionable gaps are represented by bounded Issues.
- `discussion-published`: a durable GitHub topic exists and links the maintained document.
- `fixed-in-source`: code changed and passed proportionate static checks, but runtime is not implied.
- `runtime-verified`: documented scenarios passed on the selected MTA/database environment.
- `release-ready`: configuration, migration, security, recovery, documentation, and runtime gates are satisfied.

Never collapse these states. In particular, source-reviewed and fixed-in-source do not mean runtime-verified.

## Publishing lanes

### Resource lane

One topic per manifest in `Script Resources`, backed by one maintained dossier when full review begins. Resource Discussions explain purpose, use, connections, and open work. Concrete defects remain Issues.

### Player lane

Publish approachable guides and Q&A around tasks players actually attempt: account linking, character creation, communication, organizations, vehicles, housing, work, business, public services, crime, reporting, recovery, and accessibility. Avoid exposing hidden mechanics, security thresholds, or staff-only data.

### Staff lane

Document actions by named capability, target/state requirements, duty rules, evidence needed, audit produced, failure handling, and escalation. Preserve command aliases while dashboards and contextual actions are built.

### Operator lane

Document installation, blank configuration, startup order, schema versions, backups, adapters, secrets, retention, privacy, monitoring, safe mode, disaster recovery, and release gates. Do not depend on a missing UCP.

### Architecture and future-work lane

Publish major design boundaries such as Discord identity, organizations, voice, contextual interaction, economy/ledger, evidence/cases, living-world simulation, APIs, optional providers, and UI. Each topic separates present source from proposal.

### Developer lane

Document event contracts, exports, DTOs, state machines, ownership, schema, migrations, logging, test fixtures, deprecations, compatibility adapters, and known call sites.

## Batch workflow

1. Select one coherent domain batch, normally four to six resources or one cross-cutting framework.
2. Freeze the scope and list dependencies and prohibited side effects.
3. Parallelize read-only audits across non-overlapping resources.
4. Consolidate findings and resolve contradictions against source.
5. Create or update bounded Issues before findings disappear into prose.
6. Write maintained dossiers/designs and update audience guides.
7. Publish Discussions with absolute source/document links.
8. Cross-link Issues, Discussions, milestones, documents, and parent trackers.
9. Regenerate coverage/status indexes.
10. Commit and push one coherent batch.
11. Record what remains source-only and what later runtime work must prove.
12. Assign the next batch before the current context is lost.

## Focus controls

- Keep one named primary batch and at most three parallel research batches.
- Do not let an idea skip directly to code if its owning domain, authority, persistence, and failure behavior are undefined.
- Prefer reusable framework Issues only when at least two real consumers are identified.
- Keep feature brainstorms in design documents/Discussions until an implementation slice is bounded.
- Split Issues by verifiable outcome, not by broad aspiration.
- Maintain parent trackers for resource coverage, remote-event security, schema modernization, identity, organizations, UI, and release readiness.
- Close a tracker only when its linked coverage evidence proves completion.
- Preserve unimplemented ideas in an enhancement register, but promote mature ideas into dedicated designs instead of continually expanding one file.

## Issue quality gate

Every implementation or defect Issue should contain:

- Status: source-confirmed, inferred, proposed, fixed-in-source, or runtime-verified
- Evidence paths and relevant function/event/export/table names
- Player, staff, operator, security, or data impact
- Explicit scope and non-goals
- Dependencies and related records
- Acceptance conditions that can be verified
- Runtime test cases still required
- Migration, rollback, privacy, and observability requirements where relevant

Search open and closed Issues first. Update a parent or existing Issue when the outcome is already owned there.

## Discussion quality gate

Every Discussion should include:

- Audience and scope
- Current source-backed behavior, if any
- Proposed direction clearly labeled
- Important alternatives and tradeoffs
- Open decisions
- Maintained repository document
- Related Issues, resource topics, and milestones
- No secrets, private IDs, or unverified runtime claims

## Documentation debt controls

- Generated indexes must be reproducible from source inventories where practical.
- Relative repository links must resolve; published Discussion links must be absolute.
- Commands, capabilities, events, exports, tables, and configuration keys should become searchable registries rather than being repeated manually forever.
- Deprecated names and aliases need owner, replacement, telemetry, and removal criteria.
- Screenshots and media are supplementary; text must remain usable and searchable.
- Every runtime discovery updates both the relevant Issue and maintained documentation.
- Every material code change states whether player, staff, operator, API, migration, or security docs changed or were not applicable.

## Current priority sequence

1. Complete resource and remote-event static coverage while preserving runtime-unverified status.
2. Resolve portable startup, schema, secret, and external-dependency blockers.
3. Establish Discord identity, session revocation, capability, configuration, logging, and migration foundations.
4. Establish organization compatibility, typed transactions, contextual actions, and shared UI contracts.
5. Prove one connected player loop and one staff/operator recovery loop in a disposable environment.
6. Expand by connected domains, publishing the full documentation package with each slice.

The MTA server remains unrun until the safe-start prerequisites and disposable environment are documented and prepared.
