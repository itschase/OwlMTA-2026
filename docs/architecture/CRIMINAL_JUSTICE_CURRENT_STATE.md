# Criminal Roleplay, Investigation, and Corrections: Current State

## Status

Source-reviewed domain map; runtime unverified. This distinguishes current disconnected enforcement mechanics from the proposed [Criminal Roleplay Framework](CRIMINAL_ROLEPLAY_FRAMEWORK.md).

## Current resource graph

- `factions` supplies generic Gang and Mafia organization types plus roster, ranks, chat, assets, and finance. It does not create a complete criminal lifecycle.
- `phone` hotlines can mark a vehicle stolen and notify police.
- `pd-system` provides dispatch/backup, APBs, ANPR, speed enforcement, citations, fingerprint lookup, police equipment, impound-facing tools, and jail/release commands.
- `mdc` searches characters, vehicles, and properties and stores licenses, free-text crimes, wanted/warrant text, APBs, ANPR data, stolen flags, and faction-scoped accounts/permissions.
- `social` provides frisk, restraint, blindfold, and related physical actions.
- `prison-system` provides booking, sentences, fines, cells, gates, and release. A separate `characters.pdjail_*` path and admin jail also exist.
- `item-system` contains fixed drug-mixing/effect logic and shell-casing world item 271; `weapon` manages weapon/ammunition item values. There is no shared provenance/evidence pipeline.
- `camera-system` implements traffic-speed cameras, not general CCTV footage or case evidence.
- `forums` contains disabled historical vehicle/interior theft workflows, is not started, and depends on obsolete forum tables and URLs. It is design history, not playable theft.

## Present capabilities

The source contains stolen-vehicle reporting, officer record searches, citations, APB/ANPR, licenses, impound display, booking/release, restraints/frisking, raw fingerprint display, shell-casing props, fixed two-input drug mixing, dispatch, and speed-camera violations.

It does not contain a reusable criminal opportunity state machine, contacts/reputation/heat/debt, dynamic illicit markets, fronts/laundering, production batches/provenance, influence, witness observations, evidence collection and custody, investigation timeline, evidence-linked warrants, court cases, bail/counsel/trial/appeal, probation/parole, meaningful custody activities, victim restitution, or unified operator policy.

## Important source risks

- MDC remote authorization remains tracked by Issues #41 and #52; APB restoration by #89.
- Ticket actor/record/payment binding is tracked by #84; dispatch and police weapons by #85-#86.
- Social physical-action authority is tracked by #132.
- Booking now contains meaningful authorization and bounds, but persistence spans jail tables, character fields, element data, money, ledger, MDC, restraint, inventory, skin, and teleport state without a recoverable transaction.
- Shell-casing creation accepts client-supplied calibre, position, and count without authoritative shot/weapon correlation.
- Drug transformation accepts client item identifiers and performs sequential take/give/refund without a server-owned recipe session or batch provenance.
- MDC wanted/warrant state is boolean/free text; APBs exist in more than one model.
- Raw fingerprint identity is exposed at close range without collection artifact, purpose, custody, quality, or audit.

Bounded follow-up work is tracked by [Issue #184](https://github.com/itschase/OwlMTA-2026/issues/184) for casing provenance, [#185](https://github.com/itschase/OwlMTA-2026/issues/185) for drug transformation, [#186](https://github.com/itschase/OwlMTA-2026/issues/186) for custody reconciliation, [#187](https://github.com/itschase/OwlMTA-2026/issues/187) for warrant records, [#188](https://github.com/itschase/OwlMTA-2026/issues/188) for APB consolidation, [#189](https://github.com/itschase/OwlMTA-2026/issues/189) for justice-record separation, and [#190](https://github.com/itschase/OwlMTA-2026/issues/190) for in-world fingerprint identification.

## Target slices

1. A server-owned theft-to-fence opportunity with victim recovery and investigation hooks ([Issue #152](https://github.com/itschase/OwlMTA-2026/issues/152)).
2. Evidence identity and append-only chain of custody ([Issue #153](https://github.com/itschase/OwlMTA-2026/issues/153)).
3. Auditable warrant/case records and a compatibility projection to legacy MDC state.
4. Recoverable booking/release and separation of allegations, citations, charges, conviction, custody, and staff sanction.
5. Server-owned fictional contraband recipes, batches, markets, risk, and enforcement counterplay.

## Later runtime gate

Cover civilian/off-duty/on-duty roles; every MDC permission; direct remote calls; APB/ANPR/stolen-state lifecycle; real versus forged shot/casing data; evidence pickup/transfer/seizure/retention; booking failure after every side effect; ticket/payment consistency; contraband replay/capacity/failure; camera boundaries; and operation with all legacy forum services absent.

Related design: [Organizations Framework](ORGANIZATIONS_FRAMEWORK.md), [Criminal Roleplay Framework](CRIMINAL_ROLEPLAY_FRAMEWORK.md), Discussions #141-#143, and Issues #40-#41, #52, #84-#89, #132, #152-#153, and #184-#190.
