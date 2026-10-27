# Command and in-game interaction strategy

## Purpose

The legacy gamemode exposes many useful operations only through typed commands. Commands are fast and scriptable for experienced users, but they can be hard to discover, difficult to remember, and awkward for multi-step or world-context actions. Each resource audit should consider how its operations could become easier to find and use without changing who is authorized to perform them.

This is a proposed product direction, not a claim that a replacement UI exists. Existing commands remain documented and should not be removed merely because a graphical alternative is planned.

## Choose an interface by the task

| Task shape | Preferred interaction to evaluate | Example |
|---|---|---|
| Frequent personal toggle | Inventory action, radial/quick menu, or configurable keybind | Wear or remove an owned artifact |
| Nearby world object or person | Contextual action menu / third-eye interaction | Enter a door, inspect a vehicle, interact with a service NPC |
| Multi-field creation or configuration | Guided in-game form with validation and preview | Create or edit an interior, business, job route, or map submission |
| Broad staff overview | Role-aware dashboard with search, filters, audit history, and confirmation | Review reports, manage active scenes, inspect player records |
| Server-wide operation | Operator console/dashboard with explicit state, safeguards, and recovery steps | Configure resources, inspect dependencies, manage backups |
| Rare lookup or expert shortcut | Searchable command catalog; retain a command alias | Find a command by task name, permission, or example |

No one interface fits every action. Keep narrow frequent actions close to the player, contextual actions attached to the relevant world entity, and broad administrative controls in a dashboard. Avoid duplicating a workflow across several panels without a clear use case.

## Authorization and state invariants

- The server remains authoritative for actor identity, permissions, ownership, proximity, price, target, and persistent state.
- UI controls and command arguments are requests, not proof of authority or truth.
- For each privileged workflow, identify the exact server-side Discord capability check through the reusable identity adapter and an Owl host authorization facade. Do not scatter raw role checks across resources.
- Player, staff/GameMaster, faction-duty, donor/supporter, and server-operator capabilities remain distinct. A donor tier never implies staff authority.
- Discord roles may eventually map to named capabilities through a configurable host integration. A visible Discord role must not directly become a trusted client-side permission check; server-side identity and current role state govern the capability grant.
- Every panel action and command should call the same validated domain operation where feasible, so permissions, persistence, and audit behavior do not drift.
- Destructive, financial, identity, and moderation actions require clear previews, confirmation, actor/target context, and an auditable result.
- If Discord, an API, a database, an optional observability provider, or a media provider is unavailable, the in-game UI must report a meaningful state and fail safely without silently granting access.

## Per-resource command review record

Apply this review to **every existing and future resource dossier**, not only newly audited resources. Re-open the resource manifest and declared scripts before deciding what commands are active; a command mentioned in old documentation, a disabled file, or a neighboring resource is not proof that the resource currently registers it. Record an explicit `No manifest-loaded commands found` result when appropriate, then document the actual player, staff, or operator entry point that the resource does expose.

For each source-confirmed, manifest-loaded command, document:

1. Exact command, aliases, manifest-loaded file, and source lines.
2. Intended audience, current permission check, required duty/state, arguments, and side effects.
3. Player or operator task it supports, expected output, errors, and frequency/context.
4. Existing in-game entry points and any duplicated implementation path.
5. Most suitable alternative (or why a command is best), discoverability, accessibility, keyboard/controller impact, and confirmation requirements.
6. Server API/capability that both UI and command should call; state and audit evidence required.
7. Migration approach: keep alias, announce replacement, observe use, and remove only after compatibility and automation impact are understood.

For the retrospective pass, group commands that reach the same underlying workflow and flag duplicates across resources. Prioritize workflows by player friction, frequency, risk of mistyped/destructive actions, and contextual relevance. Recommend an in-game replacement only when it improves that specific task; retain expert, accessibility, recovery, and automation shortcuts where a command remains the clearest interface. A command-only resource is not automatically a dashboard candidate, and a resource with no commands may already have a better contextual entry point.

Each recommendation must explain the real user goal in plain language, who uses it, the current command or entry point, the proposed interaction (or why the current command is suitable), and the shared server operation and authorization boundary. Treat Discord capability mapping as a separate decision for privileged actions; ordinary player actions continue to use local gameplay/ownership rules, while faction/duty, donor entitlement, and MTA operator ACL remain distinct. Do not make raw Discord role IDs a resource-level dependency.

Also record each action's authorization source: Discord-derived named capability, local account/gameplay policy, faction rank/duty, donor entitlement, or MTA operator ACL. A UI replacement must use the same server-side capability facade and local state checks as its command counterpart.

## First application: `artifacts`

The current source has `/myartifacts`, which prints worn artifact names and a count, and `/removeartifacts`, which removes all worn artifacts. These commands support a small personal status/cleanup task. A future inventory or appearance panel could show owned wearable items, current worn state, allowed wear/remove actions, and brief item descriptions. It should operate through server-validated inventory actions and distinguish ownership from a transient visual attachment. A single contextual action can remain useful for an item currently selected; a broad staff dashboard is unnecessary for ordinary wardrobe use.

Current behavior and issues are documented in [`../resources/artifacts.md`](../resources/artifacts.md). This proposed direction does not imply that the worn artifact table is persisted or that every artifact is an inventory-owned item; the source audit must map those records per item path.

## Later cross-resource applications

As new commands are audited, classify them before proposing UI:

- `/listints` is an information lookup and may fit an in-game searchable catalog with previews and map context.
- Property creation/editing is a guided staff workflow, not a quick context menu if it needs many fields and persistent writes.
- Door, lift, vehicle, and nearby service actions fit contextual interaction only after server-side proximity, world, key/ownership, and permission checks.
- Moderation and GameMaster work benefit from searchable target/action forms, clear scope, reason capture, confirmation, and audit history. Authority still derives from the corresponding capability, not the panel that exposes it.
- Server-wide resource, database, and log controls belong to an operator surface and need recoverable actions and separation from player-facing UI.

These examples are design prompts. Confirm each command and permission against the resource's current loaded code before documenting it as present behavior.

## Delivery sequence

1. Retrospectively add or verify a command-and-interaction section in every existing dossier, including explicit no-command findings; continue the same review for every new dossier.
2. Build and maintain a cross-resource inventory of source-confirmed loaded commands, grouping duplicates by underlying domain operation and marking review coverage so gaps are visible.
3. Select one small player workflow and one staff workflow for a validated vertical slice.
4. Establish shared panel navigation, server authorization, error/empty states, logging, and accessibility conventions from that slice.
5. Expand only after caller, permission, data, and runtime behavior are verified in a disposable environment.
