# Resource and script audit playbook

## Purpose

Use this playbook to build a trustworthy explanation of every active and archived resource, its scripts, and the systems it connects. A manifest inventory is the census; it is not proof that the resource's code, user workflows, permissions, or runtime behavior have been understood.

## Scope and evidence

For every resource, begin with `meta.xml`, startup configuration, and every declared client/shared/server script. Follow each important script into its internal callers, remote events, commands, exports, timers, callbacks, data files, SQL tables, and external services. Mark whether a file is active, archived, disabled, development-only, or uncertain. Treat comments and manifest descriptions as clues; confirm behavior in code.

For every player-facing feature, trace a complete scenario from the player's entry point through server validation, state changes, persistence, resulting feedback, and error paths. Trace staff and operator use separately. Follow cross-resource transitions until the responsible resource and data owner are identified.

Record evidence labels consistently: `source-confirmed`, `inferred`, `proposed`, `fixed-in-source`, and `runtime-verified`. Never promote source inspection into a runtime claim.

## Required resource dossier

Each resource needs these fields, or an explicit `not applicable` with a reason:

1. **Identity:** name, manifest path, active/archive state, startup state, description, and documentation owner/status.
2. **Human explanation:** what the feature means to a player, why it exists, how to find it, what to do, prerequisites/costs, expected result, and common failure messages.
3. **Staff explanation:** who may act, what each action changes, required duty/faction/target conditions, approvals, audit trail, and recovery path.
4. **Operator explanation:** configuration keys, dependencies/start order, database/import requirements, secrets, logs, backup/retention, optional integrations, and safe enable/disable instructions.
5. **Technical map:** client/server/shared scripts, commands and keybinds, events and exports, trusted actor source, permission checks, state machine, validation, rate limits, callbacks/timers, persistence owner, and error handling.
6. **Connections:** upstream resources called, downstream callers, tables read/written, external endpoints, and related resource dossiers.
7. **Risks and opportunities:** source defects, security boundaries, data integrity, performance, accessibility, UX friction, configuration gaps, and feasible improvements.
8. **Evidence and status:** source locations, related Issues/Discussions, static-review findings, and runtime verification state.

## Completion states

Track these independently per resource:

- `cataloged` — manifest and tree status recorded.
- `source-reviewed` — scripts, call paths, state ownership, and permissions traced to evidence.
- `player-documented` — player workflow and failure cases explained in plain language.
- `staff-documented` — staff authority and procedures explained.
- `operator-documented` — setup, configuration, dependencies, logs, and recovery explained.
- `integration-mapped` — callers, callees, data tables, and cross-resource transitions linked.
- `runtime-verified` — tested on a recorded MTA build and disposable database, with setup and result captured.

One status never implies another. A resource may be source-reviewed while its runtime behavior remains unverified. Archived resources must not be described as available gameplay unless active startup or runtime evidence confirms it.

## Issues and Discussions

Create or update an Issue for a concrete defect, security boundary, portability blocker, data migration task, or bounded implementation unit. Include the affected resource/file/function or event, user/operator impact, evidence, expected behavior, dependencies, acceptance criteria, and validation still required. Link the parent audit issue when work is part of a broader domain review. Keep unresolved findings open; close only when acceptance criteria are evidenced.

Use Discussions to explain systems, answer likely player/staff/operator questions, record designs, and describe enhancement proposals. Prefer one thread per resource in the `Script Resources` category, named exactly for that resource. Add separate audience-oriented threads for player workflows, staff/admin procedures, operator runbooks, and cross-resource architecture when the detail warrants it. Include source links, current confidence/status, cross-links, open questions, and related Issues. Avoid posting unsupported runtime claims.

Keep detailed maintained guides in the repository and link them from the Discussion. Update the resource catalog and tracker index whenever a resource dossier or tracker record changes.

## Audit cadence and review gates

1. **Census:** regenerate the manifest catalog and compare it with startup lists, archive paths, dependency declarations, and resource references.
2. **Domain batches:** review related resources together (account/auth, economy/jobs, vehicles/property, factions/public safety, administration, communication, core infrastructure). Keep code changes scoped to owned resources and document cross-domain findings as links.
3. **Trust-boundary pass:** for each remote handler, record how the actor is derived, which values are server-owned, required capability/state/proximity/ownership checks, rate limits, and audit output.
4. **Human walkthrough:** write one or more end-to-end scenarios in player, staff, and operator language, including outcomes when dependencies fail.
5. **Cross-resource review:** verify callers, exports, startup assumptions, schemas, and feature flags. Record missing or implicit dependencies as issues.
6. **Publication checkpoint:** update repository docs, Issues, Discussions, and milestones; commit coherent changes and summarize what is fixed in source versus still unverified.
7. **Safe startup gate:** keep the MTA server unrun until static review, configuration/secret checks, dependency/startup audit, and disposable database preparation are complete. Then use an isolated environment and record the exact server build, schema snapshot, logs, and results.

## Focused work assignments

When parallel work is authorized, assign one bounded resource or clearly separated resource group per chat. Each assignment identifies allowed paths, related Issues, required call-site tracing, prohibited side effects, and a report format. Do not have parallel workers edit shared docs or the same resource simultaneously. A completed report includes changed files, source evidence, issues found, docs needed, validation performed/not performed, and unresolved questions. Consolidate findings into shared docs and trackers before calling a domain complete.

## Definition of a documented system

A system is documented when a reader can answer, with evidence: what it does; how a player uses it; which staff can operate it; what the server owner must configure; which resources and tables participate; how permission and state changes are validated; what happens on failure; where to find logs; which Issues remain; and what has or has not been verified at runtime.
