# `gate-manager` resource

**Review state:** Full manifest and direct client/server event-flow source review. Database schema, in-game behavior, and gate-type edge cases remain runtime-unverified.

## What players experience

Players can activate configured world gates through the `/gate` command or by clicking a gate. The server checks the gate's configured protection type, which can include public access, password, item/key, faction membership, a query string, vehicle access, or keycard. The server then moves the object, marks it busy, and may auto-close it after its configured delay. Nearby clients receive positional gate audio when a sound is configured.

The activation event currently has its reach checks commented out and assigns `reachedit = true`; an otherwise authorized player can request gate activation without being nearby. This is tracked in [Issue #430](https://github.com/itschase/OwlMTA-2026/issues/430). Source evidence does not establish whether any gate intentionally needs remote use.

## Staff and mapper workflow

`/gates` opens the manager for Trial Admins, scripters, and mapping-team members. The manager loads gate records, supports adding/editing gates, and exposes actions for deletion, reload, teleporting to a gate, and nearby-gate discovery. `gate-manager` exports server-side `createGate` and `removeGate` for other resources.

The add/save remote events check the triggering `client` through `canManageGates`; deletion and teleport also have command handlers. This resource retains the existing in-game permissions. Discord grants, if later integrated, should add named capabilities only at the appropriate staff boundary and must not replace gate item, password, faction, vehicle ownership, or world-state checks.

## Data and dependencies

- Gate configuration is read and written in the `gates` SQL table through `mysql`.
- `integration` provides the Trial Admin, scripter, and mapping-team checks.
- `global`, `factions`, `pool`, and `anticheat` support player names/titles, item/query checks, faction/vehicle access, loaded vehicle lookup, and protected gate element data.
- The manifest declares open/close/alarm audio assets and an MTA server minimum of 1.5.5-9.14060.
- The manifest has no explicit resource dependency declarations; operators should confirm its required exports are available before starting it.

## Future interaction and operations

A third-eye/context menu could offer an open/close action only after the same server checks succeed. A staff dashboard could combine gate search, geometry, protection type, notes, and nearby map placement, while routing every mutation through the same authorized server operation. Avoid duplicating gate logic in UI callbacks.

Before enabling the resource, confirm the `gates` schema, imported gate records, resource start order, and compatibility with the installed MTA version. Do not infer runtime startup from backup server configuration alone.

## Runtime verification

On a disposable instance, verify manager permissions, CRUD persistence, each protection type, distance/interior/dimension checks, vehicle reach, auto-close and busy-state cleanup, sound recipient cleanup, resource restart, and exported creation/removal callers. No MTA server or tests were run during this review.
