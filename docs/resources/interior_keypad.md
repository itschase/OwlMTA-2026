# `interior_keypad`

## Status

- Active resource; full manifest and paired `interior_system` caller review completed; runtime unverified.
- Discussion: [Script Resource: interior_keypad](https://github.com/itschase/OwlMTA-2026/discussions/265).

## What it does

`interior_keypad` turns world-item ID 169 into a keyless property lock. Owners install/remove the pad, create a four-digit PIN, lock/unlock, and toggle auto-lock. The normal client UI also shows a police button with no implemented action.

## Workflow and data

- Install links a keypad world-item ID into `interiors.keypad_lock`.
- Open derives the property from the pad value and uses element data to display the client interface.
- `interior_load` replicates `keypad_lock`, `keypad_lock_pw`, and `keypad_lock_auto`.
- Client compares entered PIN to a replicated MD5 hash. On success it marks the local UI logged in, then calls the core property lock event with `usingKeypad=true`.
- Registration sends a client-computed hash; auto-lock is scheduled on the client after door use.
- Uninstall attempts to clear property state and return the item through `item-system`.
- Dependencies on `interior_system`, `interior_load`, `item-system`, `item-world`, `mysql`, `global`, and HUD/interior elements are implicit.

## Source-confirmed risks and safeguards

- The verifier is replicated to every client, uses unsalted MD5 over a four-digit space, and is checked only client-side. No rate limit, lockout, or successful/failed PIN audit exists.
- `interior_system` treats caller-supplied `usingKeypad=true` as a full ordinary-key bypass. It does not require authenticated `client`, a successful PIN session, the installed pad, proximity, or matching property.
- Several keypad remotes use event `source` as actor. Open/install/uninstall/slot-cleanup/sound handlers do not consistently prove target type, identity, linkage, ownership, proximity, or world context.
- Passcode registration trusts arbitrary supplied hash data and does not check prior PIN, session, pad, or DB result. Auto-lock uses client timers and blind toggles.
- Install, property state, inventory pickup, SQL, and element data can diverge. Sound broadcasts accept client code/coordinates and are not scoped to relevant players.
- Some source safeguards exist: owner checks on passcode/auto-lock/uninstall use `client`; uninstall checks locked state and inventory capacity; client UI limits normal PIN entry to four digits; quit/stop attempts to clear usage markers. These do not fix the bypass and are runtime-unverified.

## Tracked work and target direction

- [Issue #46](https://github.com/itschase/OwlMTA-2026/issues/46) owns property purchase/keypad validation and the entire authentication/installation boundary.
- [Issue #231](https://github.com/itschase/OwlMTA-2026/issues/231) owns property/item transaction recovery; #228/#151 are adjacent proximity/context interaction designs.

Proposed direction: keep verifiers server-side, rate-limit attempts, and issue short-lived sessions bound to authenticated player, exact persistent pad, property revision, range, and world context. Replace bypass toggles with capability-checked desired state; separate internal install calls from remote events; audit attempts/changes; make auto-lock server-owned; and reconcile pad/property/item state at startup.

## Runtime verification matrix

All runtime behavior remains unverified. Test owner/co-keyholder/outsider roles, wrong or orphaned pads, same/cross dimension, PIN guessing and malformed values, direct bypass and source substitution, session replay/expiry, install/uninstall failures, multiple pads, auto-lock disconnect/restart races, sound payload/rate limits, and audit recovery.
