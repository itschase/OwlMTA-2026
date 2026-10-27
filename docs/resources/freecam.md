# `freecam` resource

**Review state:** Full manifest, player command, server event, export, and direct admin/recon caller review. Permission behavior and camera cleanup remain runtime-unverified.

## What it does

`freecam` gives an authorized player a detached, movable camera. The `/freecam` client command checks that the player is logged in, alive, and either a Trial Admin, scripter, or has `canFly`; it then hides/freezes the player and starts local camera movement. The server tracks `freecam:state` and logs activation. It also exports enable/disable/state and camera-option helpers for other resources.

This is an administrative or approved camera capability, not a normal gameplay movement mode. It must not be granted by a supporter tier. A future Discord capability could complement the existing local policy only after the caller identity and active account have been rebound server-side.

## Connections and integration

- `admin-system` uses the resource during recon workflows and deactivates freecam through trusted server-side event calls.
- `interior_system` disables freecam during certain interior transitions.
- `integration` supplies Trial Admin/scripter checks; `global` and `logs` support admin notification and audit.
- Client state drives collision presentation, while the server changes player alpha, frozen state, and protected state data.
- The manifest declares shared/client/server exports, but no explicit dependency ordering.

## Source finding

The remote `freecam:asyncActivateFreecam` and `freecam:asyncDeactivateFreecam` handlers use event `source` as the target and do not validate server-side `client` or recheck activation permission. The client command's check does not secure the server event. Deactivation is also guarded by `if true or isEnabled(source)`, making the state path unconditional. This is tracked in [Issue #435](https://github.com/itschase/OwlMTA-2026/issues/435). MTA's [Script security guidance](https://wiki.multitheftauto.com/wiki/Script_security) explains why remote event source and arguments must not establish caller identity.

## Operator and future interaction notes

Keep trusted resource-to-resource recon controls on a server-only path and keep remote player self-activation bound to the requesting player plus the existing permission predicate. A staff camera dashboard can list eligible targets and synchronize start/stop state, but must call the same audited server operation. Operators should verify `admin-system`, `integration`, `global`, `logs`, and `interior_system` availability before starting dependent flows.

## Runtime verification

On a disposable instance, verify each permitted role, ordinary-player denial, forged target events, activation/deactivation symmetry, death/vehicle/character-change exits, recon transitions, interior teleports, resource restarts, and element alpha/frozen/collision restoration. No MTA server or tests were run.
