# `elections` resource

**Review state:** Full manifest and direct-caller source review with database-schema tracing. Voting and ped lifecycle remain runtime-unverified.

## Player workflow

The resource creates an election NPC at a fixed position, interior, and dimension. Players right-click the ped and choose Talk to open a GUI populated from replicated candidate data. The GUI currently hides voting when the account's local `electionsvoted` flag is set or displayed account hours are below ten, then sends a candidate name to the server. Those GUI checks are presentation only and are not enforced in the vote event handler.

## Staff workflow and authority

`/electionmanager` opens the candidate-management interface; `/electionvotes` displays totals. Server-side candidate add/remove/reset and totals access are gated by `integration:isPlayerHeadAdmin`. The client also hides the manager button for non-head-admins, but the server check is the operative boundary. Elections are managed by staff; donor/supporter status has no evidenced role here. Future Discord integration should provide a named staff capability to the existing server-side authorization boundary and should not change voter eligibility policy.

## Persistence and connections

`mta.sql` defines the `elections` table with unique candidate names and vote totals. The resource caches candidates on `resourceRoot` and refreshes after management operations. The account table `account_details.electionsvoted` stores whether the account has voted; login hydrates the field to player element data. Candidate totals do not preserve individual ballots or election-cycle history. The schema also has character-level election fields that this resource does not use, so the account-versus-character policy should be made explicit before redesign.

The election ped's Talk option is supplied by `ped-system`. The voting GUI and staff management controls are owned by `elections`. No website/UCP is required for ordinary voting or the current management workflow.

## Source-confirmed findings

- **Server-side eligibility and one-vote rules are absent from the remote vote handler.** The client checks hours and prior-vote state, but the server event increments the selected total and marks the account voted without rechecking authenticated account, hours, or prior vote. See [Issue #372](https://github.com/itschase/OwlMTA-2026/issues/372). A direct/repeated request can bypass UI checks at the source boundary; live behavior has not been tested.
- **Candidate name is dereferenced before confirming it exists.** `updateVotes` searches the current cache, then reads `currentVotes[vote].votes` without handling a missing match. A stale or malformed selection can cause a nil-index failure. See [Issue #373](https://github.com/itschase/OwlMTA-2026/issues/373).
- The client hours comparison assumes the element data converts to a number; absent/non-numeric data can produce an invalid comparison. The UI remains non-authoritative regardless.
- Ped cleanup and recreation use client-ped events inside the server script and call `createPed` without arguments. Confirm event semantics and runtime results against the target MTA build before filing or changing this path.
- Candidate add/remove/reset update UI/cache state without consistently checking database outcomes; review persistence failure handling before claiming management operations succeeded.

## Future usability and operations

Keep the player vote flow in a clear GUI, with server-authoritative eligibility, a single accepted ballot per defined election/account policy, explicit success/rejection feedback, and a current candidate list. An in-game management dashboard can replace repetitive candidate commands while preserving per-action staff checks. Provide operators with a safe reset/backup procedure and report database failures without claiming success. Any future API should expose explicit election operations and never rely on browser/UCP availability.

## Runtime verification

On a disposable database, verify eligible/ineligible accounts, repeated and concurrent submissions, stale candidates, database failure during candidate management, election reset semantics, login hydration, ped creation/death/restart, and results after resource restart. No server or tests were run for this review.

## MTA references

- [onPedWasted](https://wiki.multitheftauto.com/wiki/OnPedWasted) is documented as a server-side ped event; this is the reference point for reviewing the current server script's client-event registrations.
- [createPed](https://wiki.multitheftauto.com/wiki/CreatePed) requires a model ID and X/Y/Z arguments. The current zero-argument recreation call should be handled as a source defect candidate; observed runtime results remain unverified.
