# `prison-system`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded script, schema, and representative callers.
- Runtime: unverified. The server has not been started.

## What it does

`prison-system` executes custody: booking, roster UI, configured cells and processing zones, online/offline sentence clocks, fines, prisoner appearance, gates, intercom, and release. It is not a court, case-management, evidence, or conviction system.

Officers use `/arrest` or the prison UI to add, update, or release prisoners; prisoners use `/jailtime`; authorized faction members can use `/intercom`. Trial administrators retain bypasses. The server export `checkForRelease` is called by account/character and administrator flows.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/prison-system/meta.xml`](../../mods/deathmatch/resources/prison-system/meta.xml)
- Shared configuration: [`g_prison.lua`](../../mods/deathmatch/resources/prison-system/g_prison.lua)
- Custody implementation: [`s_prison.lua`](../../mods/deathmatch/resources/prison-system/s_prison.lua)
- Gate implementation: [`s_gates.lua`](../../mods/deathmatch/resources/prison-system/s_gates.lua)
- Commands: `/arrest`, `/jailtime`, `/intercom`.
- Remote mutations include prisoner add/change/remove and single/all gate movement.
- Persistence spans `jailed`, `characters.pdjail*`, bank balances, `wiretransfers`, `mdc_crimes`, appearance/restraint columns, items, and live jail element data.
- Separate PD jail and administrator jail paths create three overlapping custody/sanction state models.

## Source-confirmed risks

- Automatic release calls the remote `removePrisoner` handler internally without an MTA `client`. The authorization helper rejects it, while surrounding code still clears live state and teleports the player; the persisted row can remain and reapply custody later.
- Gate mutation events have no server-side authorization, duty, location, rate, or actor check.
- Roster view precedence permits off-duty law access and exposes names, cells, charges, fines, and updater identity more broadly than mutation policy.
- The configured offline-manager faction path reads a membership table as a scalar faction ID and cannot work as intended.
- Booking references an undefined `thePlayer` when returning restraint items, which can abort before custody activation.
- Booking and release are long non-transactional sequences across custody, money, MDC, item, appearance, and world state with no operation ID or reconciliation.
- Duplicate detection returns after its first loop iteration; recovery code can dereference a missing cell; prison appearance overwrites persistent character appearance without a pre-custody snapshot.
- Fines, payouts, and journals do not form an atomic, funds-checked transaction.

## Tracked work and target direction

- [Issue #40](https://github.com/itschase/OwlMTA-2026/issues/40) owns direct-event authorization, gate access, roster-duty policy, and current hardening verification.
- [Issue #186](https://github.com/itschase/OwlMTA-2026/issues/186) owns recoverable booking/release and custody-state reconciliation.
- [Issue #189](https://github.com/itschase/OwlMTA-2026/issues/189) separates criminal custody from allegations, charges, convictions, citations, and staff sanctions.
- [Issues #149](https://github.com/itschase/OwlMTA-2026/issues/149) and [#153](https://github.com/itschase/OwlMTA-2026/issues/153) cover typed money ownership and evidence/case boundaries.

The target is a server-owned custody service with canonical state, immutable booking/release history, typed case/charge references, idempotent staged operations, startup/login reconciliation, pre-custody appearance and inventory snapshots, privacy-scoped roster reads, and operator repair tools. Bail, hearings, release conditions, visitation, prison work, education, treatment, recreation, parole, and probation are future designs rather than current features.

Runtime verification must directly invoke every remote event for every role/duty/location combination; test all sentence, fine, cell, online/offline, AFK, quit, restart, and concurrency boundaries; inject failure after every side effect; prove automatic/manual release convergence; and verify privacy, access audit, restoration, and dependency failure behavior.
