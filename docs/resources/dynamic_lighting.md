# `dynamic_lighting` resource

**Review state:** Partial manifest/API review. This is the active client-side shader lighting provider, distinct from the older archived copy at [`archive/dynamic_lighting.md`](archive/dynamic_lighting.md). Rendering, performance, and start-order behavior remain runtime-unverified.

## Purpose and player experience

The manifest describes a per-pixel dynamic lighting resource. It loads three client scripts and lighting shader files, then exports client functions for creating and updating point/spot lights, controlling light properties, and configuring global shader behavior. It is a visual library; it has no direct player command or staff command in its manifest.

## Connections and control boundaries

- `dynamic_lighting_vehicles` calls the client exports to create, position, color, and destroy vehicle headlight effects.
- The active `dynamic_lighting_flash` resource uses dynamic lighting alongside attachment/rendering helpers for player flashlight visuals.
- These are client exports and affect presentation. They do not authorize server-side vehicle ownership, item use, travel, or staff actions.
- No SQL or persistent gameplay records are declared by this resource.

The manifest does not declare explicit resource dependencies. Operators should start the provider before consumers that call its exports, and verify actual startup order against the server's current configuration rather than relying on `.bak` snapshots.

## Player, staff, and operator use

Players experience light effects produced by client consumers; they do not operate this library directly. No staff workflow or permission boundary is present. Discord roles should not be involved in ordinary rendering. If staff-only diagnostic controls are added, they must authorize the server action and keep visual settings separate from gameplay permissions.

## Future development and diagnostics

Document the exported parameter types/ranges and measure light/shader limits on supported MTA builds before changing defaults. Consumers should release created lights during element/resource teardown and handle provider restart. Diagnostics should be bounded and report failed shader/light creation at the consumer boundary without logging every render tick.

## Runtime verification

Verify shader compilation, supported graphics capabilities, export calls across resource starts/stops, light cleanup on element stream-out/destruction, dimension/interior filtering, and resource restart. None of these behaviors has been confirmed on a running server.
