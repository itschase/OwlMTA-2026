# Next work record

Last updated: 2026-10-26 after publishing the weapon editor authority fix.

## Latest published batch — 2026-10-26

Three audited resources now have maintained dossiers and standardized Script Resource Discussions: `es-system` #303, `cargo` #304, and `event-system` #305. Coverage is 65/179: 59 full source reviews and 6 partial; all remain runtime-unverified.

Issues #292-#296 cover medical bill settlement, death/seizure authority, medical recovery custody, injury actions/control recovery, and hospital dispatch. Issues #297-#299 cover forklift transfer authorization, the incomplete shipping-order flow, and compiled client-source reproducibility. Issues #300-#302 cover paintball match authority, basketball/golf sessions, and skating/manifest reliability. Existing shared ownership was retained: stretcher paths update #132; cargo restart recovery links to #214; duplicate startup stays with #21; event remotes remain under #1; fall protection stays #260; item authorization remains #213.

A focused `weapon:modify` server-side ownership/field validation fix is published in [commit `3a85580`](https://github.com/itschase/OwlMTA-2026/commit/3a85580). It covers only the weapon editor handler; Issue #288 remains open for satchel removal and switch/rebuild event authority, and the fix is runtime-unverified.
## Verified project state

- `main` was synchronized with `origin/main` before this batch.
- The manifest census remains 179 resources: 144 active-tree and 35 archived.
- 65 resources have individual Discussions and versioned dossiers: 59 full manifest-script reviews and 6 partial reviews.
- Source review, proposed design, fixed-in-source behavior, and runtime verification remain distinct. All resource dossiers are runtime-unverified.
- The MTA server has not been started. Static review and safe-start preparation remain the gate.


## Previous publication batch — 2026-10-25

Five source-audited resources now have maintained dossiers and standardized Script Resource Discussions: `computers-system` #283, `interior_load` #284, `achievement` #285, `apps` #286, and `weapon` #291. These bring resource documentation to 62/179: 56 full and 6 partial; all remain runtime-unverified.

New milestone #2 issues #273-#278 cover computer email ownership/passwords, IPPC authorization, computer-service reliability, flight validation, and interior loader readiness. Issue #279 covers report reward milestone idempotency. Issues #280-#282 cover application manager authorization, application lifecycle integrity, and question-bank readiness. Each issue is assigned to `itschase`; dossiers, Discussions, and issues are cross-linked. Existing ownership for GameCoin settlement, general remote hardening, and donor/staff separation was retained.

The completed `apps` audit also confirmed legacy supporter access in manager/login-bypass and force-application paths. Keep that as evidence for existing role-separation Issue #3 rather than creating a duplicate authorization-policy issue.

The weapon audit added Issues #287-#290 for server-authoritative ammunition settlement, typed weapon metadata/destructive event ownership, attachment/utility authorization, and catalog integrity. Existing Issues #1/#3/#6/#18/#184/#208/#219/#220 remain linked as broader or exact sub-scope owners; the missing attachment file was not duplicated.

## Completed publication batch

The active `elevator-system` resource now has a full manifest/direct-caller source dossier and standardized [Script Resource Discussion #272](https://github.com/itschase/OwlMTA-2026/discussions/272). Issues #268-#271 track lift-state loading, interior lock lookup, administration mutation integrity, and the remote roleplay-action event. Door and lift travel were added to existing interaction-context Issue #228; empty-table ID allocation remains in #17 and property cleanup in #231. No duplicate travel issue was opened. Runtime remains unverified.

Four interior and map resources now have maintained dossiers and consistently named Discussions #264-#267. Issues #46/#62/#64/#231 retain ownership of the keypad, map-review, staff-management, and property-lifecycle findings; no duplicate issue was opened.

The `npc` and `object-system` source audits are now published as [Script Resource Discussions #262-#263](https://github.com/itschase/OwlMTA-2026/discussions/262) with versioned dossiers. Issues #260/#261 track their distinct dimension-sync and shop-management/security work; broader HTTP, schema, payday, and business-order boundaries remain linked to their existing owners.

Four additional resources are published as dossiers and consistent Script Resource Discussions:

1. `job-system-trucker` — freight job sessions, business supply ordering, delivery and settlement.
2. `paynspray-system` — repair invoices, payer/receiver balances, insurance claims, and repair completion.
3. `object-interaction` — client world-object routing and ownership of downstream action authority.
4. `item-move` — client transform editor and paired server persistence boundary.

Discussions #256-#259 are indexed under `docs/resources/README.md`. Issues #254-#255 cover the new trucker route-session and Pay 'n' Spray invoice units; existing Issues #151, #182, #213, and #214 own contextual actions, business order durability, item-move authorization, and edit persistence respectively.

Six completed audits are now maintained as versioned dossiers and consistently named Script Resource Discussions:

1. `usercontrolpanel` — legacy website RPC and broad shared website ACL boundary.
2. `insurance` — vehicle policy, quote, claim, cancellation, accounting, privacy, and reconciliation flows.
3. `job-system` — civic-job selection, work sessions, rewards, service jobs, and progression.
4. `tow-system` — conventional towing, law-enforcement seizure, impound lanes, release, cleanup, and settlement.
5. `item-world` — persistent object lifecycle, permissions, deletion, retention, and evidence/storage boundaries.
6. `rightclick` — client presentation boundary and migration input for the contextual-action registry.

Discussions #247-#252 use the standardized `Script Resource: <resource>` format. Issues #240-#246 and #253 record the non-duplicate implementation units found by this batch.

## Cross-cutting tracker follow-up

- Update Issues #4/#22 with the complete legacy UCP HTTP-export and ACL evidence.
- Update Issues #15/#45 with the insurance actor/privacy, quote, claim, cancellation, and settlement matrix; link durability Issue #240.
- Update Issues #47/#77/#181 with the job selection, bus, fishing, and photography evidence; link service-work Issue #241.
- Update Issue #151 with the `rightclick` compatibility-adapter and context descriptor requirements.
- Cross-link `item-world` Issues #244-#246 with contextual-action Issue #151 and evidence/provenance Issues #153/#184.
- Update documentation tracker Issue #95 with the 62-topic, 56-full, 6-partial coverage counts.

## Active audit wave

The next publication wave should take two resource pairs from the remaining active manifest census, prioritizing first those with player-facing persistence, money, permissions, or startup dependencies. Keep each subtask bounded to manifest-loaded scripts and direct callers, then publish a dossier and consistently named Discussion before creating only non-duplicate implementation Issues.

The reusable Discord/MTA identity service is now being developed in a separate project chat and repository boundary. OwlMTA remains one host adapter and consumer; its in-repository documents define integration contracts rather than embedding the standalone product.

## Safe-start gate after static review

Before starting MTA, produce a reproducible disposable environment plan: sanitized configuration and secrets, schema import/migration order, resource start graph, optional-service stubs, least-privilege database accounts, seeded test identities, backup/rollback steps, logging destinations, and a smoke-test matrix. Starting the server is a later explicit phase and must not be represented as completed by static inspection.

The first static plan is now maintained in [Static Safe-Start Preflight](SAFE_START_PREFLIGHT.md) and discussed in [Server Operators #215](https://github.com/itschase/OwlMTA-2026/discussions/215). Its gates are requirements, not runtime results.
