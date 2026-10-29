# Resource and script audit playbook

## Purpose

Use this playbook to build a trustworthy explanation of every active and archived resource, its scripts, and the systems it connects. A manifest inventory is the census; it is not proof that the resource's code, user workflows, permissions, or runtime behavior have been understood.

Track row-by-row progress in `RESOURCE_DOCUMENTATION_STATUS.csv`. Regenerate it with `tools/generate-resource-documentation-status.ps1` whenever a resource Discussion or maintained dossier is added, then review the changed rows before committing.

## Scope and evidence

For every resource, begin with `meta.xml`, startup configuration, and every declared client/shared/server script. Follow each important script into its internal callers, remote events, commands, exports, timers, callbacks, data files, SQL tables, and external services. Mark whether a file is active, archived, disabled, development-only, or uncertain. Treat comments and manifest descriptions as clues; confirm behavior in code.

For every player-facing feature, trace a complete scenario from the player's entry point through server validation, state changes, persistence, resulting feedback, and error paths. Trace staff and operator use separately. Follow cross-resource transitions until the responsible resource and data owner are identified.

Record evidence labels consistently: `source-confirmed`, `inferred`, `proposed`, `fixed-in-source`, and `runtime-verified`. Never promote source inspection into a runtime claim.

## Command-to-interaction review

Commands are a valid interface for operators and experienced users, but they can hide functionality from players and make multi-step tasks error-prone. During every resource audit:

- Inventory each loaded command, its audience and actual use case, permission and state requirements, arguments, side effects, output, and failure feedback.
- Classify the task: quick status/lookup, repeatable personal action, world-object interaction, staff workflow, or server-operator maintenance.
- Compare an alternative appropriate to that task: persistent dashboard/panel for broad management, contextual action for nearby entities, guided form for multi-field operations, keybind for frequent actions, or a discoverable help/search catalog for rare commands.
- Map each proposed interaction to the same server-owned permission, validation, state, persistence, and audit path as the existing command. A new UI must not widen authority or trust client-submitted values.
- For every command and protected server event, classify whether it needs a Discord-derived capability. Record the proposed capability key, plugin/host-adapter call boundary, separate local gameplay checks, and outage/expired-grant behavior. Explicitly mark actions that should remain local gameplay, faction/duty, donor-only, or MTA-operator authorization rather than inventing a Discord gate.
- Keep aliases as a fallback where useful; document whether they are player-facing, staff-only, operator-only, deprecated, or intentionally retained for automation.
- Record source-confirmed current behavior separately from proposed interaction design, and link cross-resource overlap rather than creating duplicated panels.

The cross-resource proposal and evaluation criteria are maintained in [`COMMAND_AND_INTERACTION_STRATEGY.md`](COMMAND_AND_INTERACTION_STRATEGY.md).

## Discord capability review for scripts

The reusable [MTA Discord Identity adapter](https://github.com/itschase/mta-discord-identity) exposes server exports for connection-bound pre-auth login, authenticated linking/session exchange, `hasCapability(player, name)`, `getDonorTier(player)`, and local session clearing. Owl's host integration still has to validate the returned opaque account reference through trusted Core state, resolve logged-in account IDs for linking, and make every local policy decision. The adapter returns only named capabilities and a separate donor tier; raw Discord role IDs remain in the operator-managed identity-service configuration.

For each resource command, remote event, export, and staff control, auditors should record:

1. Whether the operation is a normal player action, character-owned action, faction-rank/duty action, global staff/GameMaster action, donor entitlement, or server-operator action.
2. If a Discord grant is appropriate, the narrow named capability key and exact server-side action boundary where it should be checked.
3. The independent local conditions that still apply: actor derived from MTA `client`, ownership, active character, faction membership/rank, duty, target/proximity/world, limits, and current state.
4. Behavior when unlinked, expired, revoked, role-removed, plugin/API unavailable, or the adapter resource is stopped. Elevated actions fail closed; ordinary local gameplay and process boot must not become accidental API dependencies.
5. Whether the donor tier is relevant. `getDonorTier` is entitlement information only and must never replace a staff/GameMaster capability.

### Where scripts check authorization

Record the check at the server-side action boundary, not just where a button or menu is shown:

- A command checks the trusted command caller before doing privileged work. A remote event repeats the check using MTA's server-provided `client`; hiding the corresponding UI or button is only presentation, not authorization.
- An exported function documents whether it is callable by other resources, its trusted actor input, and whether the caller must provide or inherit an authorization context. Do not treat a client-supplied account/player ID as proof of identity.
- A privileged mutation checks the narrow capability immediately before its action, then checks local conditions such as active character, faction/rank/duty, ownership, target, proximity, world/interior, and current state. Shared helpers may centralize policy, but each reachable entry path must be shown to reach the helper.
- Gameplay resources call an Owl-owned authorization facade; that facade alone adapts to the reusable Discord identity plugin's stable server export contract. Keep raw role IDs, Discord HTTP calls, bot credentials, and plugin-specific details out of gameplay scripts.
- The dossier records the exact handler/helper and capability key, whether a grant is required at login or only for the action, and behavior for unlinked, expired, revoked, or unavailable authorization. Revocation should clear affected grants and terminate or restrict linked sessions according to the identity/session design.
- Do not add a Discord check to ordinary character gameplay merely because the feature has a script or command. Mark such actions `not required` and explain which local policy authorizes them. Donor tier is an entitlement input, never a substitute for staff or GameMaster authority.

During migration, compare the existing permission predicate and every caller before replacing it. Record any intentional policy change explicitly; do not silently translate numeric admin levels, faction ranks, duty state, donor levels, or MTA ACL into a Discord role hierarchy. The external plugin's export contract and revocation timing remain proposed until verified against the pinned plugin version and supported MTA runtime.

Do not scatter role IDs, Discord REST requests, bot tokens, or raw-role comparisons through gameplay resources. Prefer one Owl-side authorization facade over the generic adapter, then migrate call sites by capability with legacy-policy comparison and rollback. Plugin exports and the host account resolver remain source-level contracts until verified together in the supported MTA runtime.

## Required resource dossier

Each resource needs these fields, or an explicit `not applicable` with a reason:

1. **Identity:** name, manifest path, active/archive state, startup state, description, and documentation owner/status.
2. **Human explanation:** what the feature means to a player, why it exists, how to find it, what to do, prerequisites/costs, expected result, and common failure messages. For every command or keybind, identify its audience and actual use case; consider a discoverable in-game panel, contextual/third-eye action, keybind, guided prompt, or dashboard that fits the task. Record tradeoffs and preserve command compatibility where practical instead of assuming every command should be removed.
3. **Staff explanation:** who may act, what each action changes, required duty/faction/target conditions, approvals, audit trail, and recovery path.
4. **Operator explanation:** configuration keys, dependencies/start order, database/import requirements, secrets, logs, backup/retention, optional integrations, and safe enable/disable instructions.
5. **Technical map:** client/server/shared scripts, commands and keybinds, events and exports, trusted actor source, permission checks, state machine, validation, rate limits, callbacks/timers, persistence owner, and error handling.
6. **Connections:** upstream resources called, downstream callers, tables read/written, external endpoints, and related resource dossiers.
7. **Discord authorization review:** distinguish authentication, global named capability, donor tier, character/faction/duty policy, and MTA operator ACL. Identify the server-only check location and stable adapter contract; document `not required` when applicable.
8. **Risks and opportunities:** source defects, security boundaries, data integrity, performance, accessibility, UX friction, configuration gaps, and feasible improvements.
9. **Evidence and status:** source locations, related Issues/Discussions, static-review findings, and runtime verification state.

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
