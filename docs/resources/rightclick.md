# `rightclick`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of the only manifest-loaded script and representative world-item, social, vehicle, interior, banking, MDC, and NPC callers.
- Runtime: unverified. The server has not been started.
- Discussion: [Script Resource: rightclick](https://github.com/itschase/OwlMTA-2026/discussions/252).

## What it does

`rightclick` is a client-only singleton context-menu widget. A consumer creates a titled menu, adds header or action rows, and attaches its own client click handlers to the returned GUI elements. The resource supplies presentation and lifecycle only; it has no gameplay policy, persistence, server mutation, or authoritative action routing.

That boundary is important. A row being hidden or disabled does not authorize the eventual action. Every server event reached from a right-click consumer must derive the actor from MTA's authenticated `client` and revalidate the target, range, state, ownership, and capability.

## Player and developer use

Players see these menus across many unrelated systems. Representative uses include world-item storage/use/move/pickup/properties, social frisk/restraint/blindfold/stretcher actions, vehicle actions, property menus, ATM actions, MDC call/file actions, DMV papers, auction keys, fishing, safes, chairs, and NPC conversations.

For developers, `create(title)` replaces any open menu, `addRow` creates an action or header, legacy `addrow` preserves older callers, `destroy` closes it, and `isrcOpen` exposes the singleton. Consumers own labels, visibility rules, click handlers, local events, and server-event payloads.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/rightclick/meta.xml`](../../mods/deathmatch/resources/rightclick/meta.xml)
- Loaded implementation: [`rightclick_c.lua`](../../mods/deathmatch/resources/rightclick/rightclick_c.lua)
- Representative world-object routing: [`object-interaction/c_objects_rightclick.lua`](../../mods/deathmatch/resources/object-interaction/c_objects_rightclick.lua)
- Representative social routing: [`social/c_player_rightclick.lua`](../../mods/deathmatch/resources/social/c_player_rightclick.lua)
- Representative vehicle routing: [`[vehicle]/vehicle/c_vehicle_rightclick.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle/c_vehicle_rightclick.lua)
- Exports: `create`, `destroy`, `addRow`, compatibility alias `addrow`, and `isrcOpen`.
- Client event: `serverTriggerLeftClick` invokes the ordinary close-on-left-click behavior. Despite its name, it performs no server-side action.
- Persistence, commands, and server scripts: none.

Only one menu exists at a time. A left mouse-down while it is open schedules destruction after 250 milliseconds, allowing the selected row's handler to execute first. Menu dimensions grow as rows are added and are clamped to the screen. Resource stop naturally removes its client GUI state; there is no gameplay state to recover.

## Source-confirmed risks and limitations

- Authority is absent by design. Client checks performed before adding a row are affordances only and are bypassable by directly triggering the downstream event. Authorization defects belong to the resource that owns that backend mutation.
- The API carries no stable action ID, target identity, capability, range, disabled reason, expiry, audit correlation, or server-issued context. There is no central way to invalidate a menu when its target moves, disappears, changes owner, or loses an allowed state.
- The singleton menu and timer are global across consumers, so unrelated menus can replace or destroy one another. Consumers also attach ad hoc handlers directly to GUI rows, preventing centralized policy, telemetry, or lifecycle management.
- `destroy` checks only whether the stored handle is truthy before calling `destroyElement`; several menu handles and the destruction timer are undeclared globals. This is a low-severity collision and lifecycle risk in the shared client environment.
- `serverTriggerLeftClick` is remotely triggerable on the client but only closes that client's menu. No direct security impact was found; the name obscures its actual role.
- The widget has no keyboard/controller action model, focus semantics, consistent disabled-state explanation, or accessibility metadata. Long and translated labels depend on basic extent sizing.

These are source-confirmed characteristics and limitations. No contextual-action registry is implemented, no source fix is claimed, and runtime behavior remains unverified.

## Tracked work and target direction

[Issue #151](https://github.com/itschase/OwlMTA-2026/issues/151) is the exact target owner for a server-authoritative contextual-action registry and a backward-compatible adapter for existing `rightclick` consumers. [Issue #132](https://github.com/itschase/OwlMTA-2026/issues/132) owns authorization of social physical actions exposed through this menu; the button itself is not the authority defect. Issues #48, #153, and #184 do not belong to this presentation resource.

The target keeps the existing exports temporarily while consumers migrate to action descriptors containing an action ID, target, label/icon, server capability, range, state requirements, expiry, and disabled reason. The server should issue or independently validate action context at execution. Central menu lifecycle should handle target invalidation, consistent feedback, keyboard/controller navigation, accessibility, and audit correlation without moving gameplay authority into the client widget.

Runtime verification must cover open/replace/close behavior across competing consumers; rapid clicks and destruction timers; targets that move, stream out, or are destroyed; capability and ownership changes while a menu is open; direct forged downstream events; cursor-hidden and exclusive-GUI states; multiple resolutions and scale settings; screen edges; headers, disabled rows, long and translated labels; keyboard/controller behavior; resource stop/start order; and legacy `addrow` compatibility.
