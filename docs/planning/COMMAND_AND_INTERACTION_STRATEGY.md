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

For each discovered command, document:

1. Exact command, aliases, manifest-loaded file, and source lines.
2. Intended audience, current permission check, required duty/state, arguments, and side effects.
3. Player or operator task it supports, expected output, errors, and frequency/context.
4. Existing in-game entry points and any duplicated implementation path.
5. Most suitable alternative (or why a command is best), discoverability, accessibility, keyboard/controller impact, and confirmation requirements.
6. Server API/capability that both UI and command should call; state and audit evidence required.
7. Migration approach: keep alias, announce replacement, observe use, and remove only after compatibility and automation impact are understood.

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

1. Continue recording command audiences and interaction alternatives in every dossier.
2. Build a cross-resource command inventory and group duplicate workflows by underlying domain operation.
3. Select one small player workflow and one staff workflow for a validated vertical slice.
4. Establish shared panel navigation, server authorization, error/empty states, logging, and accessibility conventions from that slice.
5. Expand only after caller, permission, data, and runtime behavior are verified in a disposable environment.
