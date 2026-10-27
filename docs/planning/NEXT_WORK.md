# Next work record

Last updated: 2026-10-27 during the death and datetime documentation continuation.

## Current continuation — 2026-10-27

Completed a full manifest-script source review of `vehicle_fuel` and expanded its maintained dossier. It now explains player fueling, staff commands and their legacy gates, database/element-data paths, resource connections, MTA event trust boundaries, Discord/API placement, command-to-contextual-action opportunities, and a runtime validation matrix.

Published and verified Issue [#342](https://github.com/itschase/OwlMTA-2026/issues/342) for station conversation and transaction integrity, and Issue [#343](https://github.com/itschase/OwlMTA-2026/issues/343) for POS PIN caller/card authorization. Both were checked against existing open issues before creation and remain runtime-unverified.

Fixed in source: absent fuel-shop links are normalized to `0` when attendants are created/listed, shop-income diagnostics tolerate unavailable peds/invalid charges, and missing shop links skip income settlement safely. This does not close the issues' wider state, trust, database, or transaction work.

Next: review the issues against the repository's SQL wrapper/card schema before implementation; inspect sibling vehicle and bank callers; deduplicate findings against existing issues; then continue the next high-risk active resource and update its dossier/index/Discussion/Issues as one publishing batch. No MTA runtime was started and no automated tests were run; static diff/whitespace review is the only validation for this source adjustment.

The faction/duty review from the concurrent project audit is now reflected in resource dossiers and GitHub Issues. Issues [#38](https://github.com/itschase/OwlMTA-2026/issues/38), [#39](https://github.com/itschase/OwlMTA-2026/issues/39), and [#53](https://github.com/itschase/OwlMTA-2026/issues/53) now distinguish older reported missing checks from current source coverage and remaining roster privacy, offline membership, package payload, and actor-binding tasks. [Issue #344](https://github.com/itschase/OwlMTA-2026/issues/344) separately tracks the global `dutyAdmin:Save` authorization/payload gap. Local faction rank/duty policy remains distinct from any future Discord global staff capability.

The API review compared Owl's proposed `/api/v1` document with the published standalone service's implemented `/v1` contract. They differ; Owl still lacks its host adapter, login integration, local capability facade, and revocation disconnect handler. Updated [Issue #68](https://github.com/itschase/OwlMTA-2026/issues/68) to make contract reconciliation and the Owl host slice the actionable work. [`API_CONTRACT.md`](../architecture/API_CONTRACT.md) now clearly labels the target routes as proposed and records the actual separate-service route snapshot. The standalone service currently uses process-local state and has not been verified inside a real MTA server.

Audited the complete `death` manifest and direct CK/cemetery callers; added [`docs/resources/death.md`](../resources/death.md), updated the status ledger and resource index, and created [Issue #345](https://github.com/itschase/OwlMTA-2026/issues/345). A remote cemetery-list handler previously used the client-supplied event source as the reply recipient; it now binds the caller to MTA's `client`, validates source equality, and replies only to that caller. The response is public memorial data, so impact is documented as recipient spoofing/unwanted response delivery. Runtime verification and request-rate review remain open.

Audited `datetime` and the direct IPPC consumer; added [`docs/resources/datetime.md`](../resources/datetime.md) and created [Issue #346](https://github.com/itschase/OwlMTA-2026/issues/346) for mixed timestamp epochs and IPPC classification. Because `now()` values are stored and read across many resources, changing its epoch requires a consumer and legacy-data migration plan. Also created [Issue #349](https://github.com/itschase/OwlMTA-2026/issues/349) and fixed the remote clock-sync response to bind to authenticated `client`, validate source equality, and target only the caller. Published [Script Resource: death #347](https://github.com/itschase/OwlMTA-2026/discussions/347) and [Script Resource: datetime #348](https://github.com/itschase/OwlMTA-2026/discussions/348). The status ledger records 75 of 179 resources with maintained dossiers (70 full source reviews and 5 partial) and 75 individual resource Discussions; both dossiers remain runtime-unverified.

Committed and pushed cache, prison, NPC/shop, truck-supply, tow, and map-manager source/dossier updates as [3d4fcc4](https://github.com/itschase/OwlMTA-2026/commit/3d4fcc4). The shop restock path calculates stock keys/prices from server catalog state, settles one-unit restocks without creating an empty delivery, preserves the existing owner/faction payer selection, commits local stock before settlement, and compensates local stock if trucker settlement fails. These writes still are not transactional across resources; a failed compensation is logged. Updated [Issue #182](https://github.com/itschase/OwlMTA-2026/issues/182) to capture this shared ledger boundary and runtime matrix. Updated [Issue #62](https://github.com/itschase/OwlMTA-2026/issues/62), assigned it to Milestone #7, and recorded map validation, actor/state checks, conditional transitions, and incomplete MyISAM rollback limits. Cache #63, prison #54/#341, and the six resource dossiers remain source-only; all need safe-start/runtime verification later. No MTA server was started and no tests were run.

Next review map converter compatibility against representative legacy map files, validate current upload/testing tab policy, and inspect every failure path around map load/unload and audit rollback. Continue the wider audit queue with the Discord-capability boundary recorded for each server action and command-to-interaction review attached to each resource dossier.

## Current publication state — 2026-10-27

Consolidated the pending phone/MDC source work after rechecking the live checkout and manifest callers. Phone SMS and contact updates now validate requester/login and owned phone/contact state, respect server-owned privacy settings, bound contact fields to the table schema, and the contact editor sends email separately from address. MDC login/main derive the active character from the validated requester; downstream data and mutation handlers remain open. Added command/interaction reviews for phone and MDC, including future Discord capability boundaries and where local gameplay/faction/operator authority must remain. Updated Issue #55 to separate source-fixed scope from residual phone paths, #41/#52 to correct MDC progress, and created [Issue #340](https://github.com/itschase/OwlMTA-2026/issues/340) for Supporter access to emergency-call logs. Static review only; no MTA start or runtime verification.

Retrospective command review now has its first applied example: `interior-manager`. Its dossier records `/interiors` and `/ints`, `/checkint` and `/checkinterior`, `/setintfaction`, and `/setinttomyfaction`, distinguishing current catalog/details UI from the proposed guided/contextual improvements. It also documents where an external Discord capability could apply and where property ownership and faction rank must remain local authority. Updated [Issue #64](https://github.com/itschase/OwlMTA-2026/issues/64) to replace stale event/search claims with current source evidence and the remaining donor-privacy and catalog data-shape work; linked findings to [Issue #327](https://github.com/itschase/OwlMTA-2026/issues/327). Static review only; no server started.

Command-interface audit direction: extended [`COMMAND_AND_INTERACTION_STRATEGY.md`](COMMAND_AND_INTERACTION_STRATEGY.md) to explicitly cover the existing dossier set as well as future resource reviews. Retrospective work will verify commands against manifest-loaded scripts, record an explicit no-command finding where applicable, describe the user's actual task and audience, compare a suitable in-game interaction (or justify keeping the command), and keep UI/API authorization on the same server-side operation. Issue [#327](https://github.com/itschase/OwlMTA-2026/issues/327) remains the cross-resource tracker; no new duplicate issue is needed. This is planning guidance, not an implemented UI or runtime finding.

Most recent: audited `help`, published [Script Resource Discussion #339](https://github.com/itschase/OwlMTA-2026/discussions/339), and created Issues [#337](https://github.com/itschase/OwlMTA-2026/issues/337) and [#338](https://github.com/itschase/OwlMTA-2026/issues/338). The dossier explains `/helpme`, F1, `/report`, the dynamic command catalog, location blips, the PM URL-copy integration, command alternatives, and why help visibility is not command authorization. Removed the Supporter alternative from the client command-editor predicate; Trial Admin remains the source's existing edit permission. Issue #337 now records that source fix and the remaining server-side payload/cache work. Issue #338 now captures the ambient-event-source path used by post-edit refreshes and links official MTA event-security documentation. These changes are source/documentation-only and not runtime-verified. Current individual resource coverage is 73/179: 67 full source reviews and 6 partial, all runtime-unverified.

Reconciled cache Issue [#63](https://github.com/itschase/OwlMTA-2026/issues/63) with the image-boundary source changes and explicit unresolved fetch/API limits. The cache dossier is linked with existing non-image lookup and restart-contract issues #118/#119; no duplicate issue was created. Cache behavior remains runtime-unverified.

Updated prison Issue [#54](https://github.com/itschase/OwlMTA-2026/issues/54) to identify committed source changes separately from runtime evidence. Created [#341](https://github.com/itschase/OwlMTA-2026/issues/341) for the separate remotely callable gate controls after checking open-issue matches; linked both to the prison dossier and Milestone #7. Prison gate permission and roster-visibility policy remain unresolved.

Published the four pending, standardized Script Resource Discussions directly through the signed-in Brave session after the workspace GitHub credential lacked Discussion write permission: `activities` #316, `bone_attach` #317, `clothes` #318, and `official-interiors` #319. The prior source dossiers already existed and are linked from each discussion. The individual resource coverage is now 69/179: 63 full source reviews and 6 partial reviews, all runtime-unverified. The manifest census remains 179 resources (144 active-tree, 35 archived).

This wave also created Issues #320-#323 after checking current issue matches: unauthorized `clothes:tempfix` resource restarts, requester/NPC interaction binding for clothes lists and dialogue, snowball teardown input cleanup, and checked lifecycle for global interior collision overrides. Issues #306-#315 remain linked to the four resource dossiers; each new issue is assigned under Milestone #7. These four candidates were searched before creation, and a matching `createObject` false-flag finding was already covered by #308 rather than duplicated.

Audited `artifacts`, added its source dossier, and published [Script Resource Discussion #328](https://github.com/itschase/OwlMTA-2026/discussions/328). Issues #324-#326 cover unbound bulk cleanup, equip entitlement, and the empty `/removeartifacts` command path. Issue #327 in Milestone #4 tracks a cross-resource command inventory and fit-for-purpose in-game alternatives. Published [Plans & Enhancements Discussion #329](https://github.com/itschase/OwlMTA-2026/discussions/329) and added reusable command-audit requirements to the playbook and [Command and Interaction Strategy](COMMAND_AND_INTERACTION_STRATEGY.md).

Added Issue #330 for source-confirmed client texture-handle cleanup in `artifacts`; this issue separates a resource-owned presentation lifecycle from shared attachment state.

Checked the standalone identity plugin at revision `619d18f`: it exposes server-side named-capability and donor-tier checks, and asks the host gamemode to resolve account identity through a server-only callback. Updated the audit standards to record a Discord capability decision for every resource command, protected event, export, and staff control. The intended pattern is one Owl-side authorization facade calling the reusable plugin, followed by each resource's local ownership, faction/duty, proximity, target, and state checks. The external adapter is not integrated into Owl yet; no resource receives a Discord grant by default.

Audited `gatekeepers-system`, published [Script Resource Discussion #334](https://github.com/itschase/OwlMTA-2026/discussions/334), and created Issues #331-#333 for locksmith key settlement, factionless key-list handling, and global ped-damage suppression. No commands are loaded in that resource; its existing NPC context menu is documented as the current interface and an input for future third-eye/context unification.

Posted the per-resource Discord authorization review to the existing [Discord identity Discussion #239](https://github.com/itschase/OwlMTA-2026/discussions/239), linking the audit standard, external adapter contract, and the distinction between Discord grants and local gameplay/faction/donor checks.

Audited `animation-system`, published standardized [Script Resource Discussion #336](https://github.com/itschase/OwlMTA-2026/discussions/336), and created [Issue #335](https://github.com/itschase/OwlMTA-2026/issues/335) for unbound animation mutation/sync event payloads and duplicate subscriptions. The dossier inventories player command use cases and alternatives, finds no current staff-only command (so ordinary emotes need no Discord role), and records where a future staff animation control would check the external adapter's named capability. Corrected the stale `/fixcar` help entry in source; static diff only.

The prior batch brought coverage to 72/179 resources with individual Discussions: 66 full source reviews and 6 partial; all runtime-unverified. New publications were Discussions #316-#319, #328-#329, #334, and #336; Issues #320-#333 and #335. Issues #320-#326 and #330-#333, #335 are grouped under Milestone #7; #327 belongs to Milestone #4. Help Issues #337-#338 are also assigned under Milestone #7.

The API credential's `CreateDiscussion` permission denial remains a publication-channel constraint; browser publication succeeded. Future Discussion batches should continue using the title form `Script Resource: <resource>` and update the generator, ledger, and index in the same publication batch. The new resource Discussion pages were verified live at the linked GitHub URLs above.

The next audit wave should select high-impact remaining active resources, review manifest-loaded files plus direct callers and persistence, then publish dossiers, standardized Discussions, and deduplicated Issues. Maintain the static-review/safe-start gate; no MTA server has been started.

## Previous audit wave — 2026-10-26

The `activities`, `bone_attach`, `clothes`, and `official-interiors` dossiers and their standardized Discussions were published in the next wave above after the workspace credential returned a `CreateDiscussion` permission denial and browser publication was used. The status ledger records the current links.

`activities` source review found snowball creation and throw remotes trust actor/trajectory payload fields instead of binding them to MTA's authenticated caller; this maps to focused [Issue #306](https://github.com/itschase/OwlMTA-2026/issues/306) and umbrella Issue #1. The `clothes` audit retained existing authorization [Issue #58](https://github.com/itschase/OwlMTA-2026/issues/58) and created distinct issues #312-#315 for upload intake, shop settlement, manufacture/copies/resale, and texture streaming. `bone_attach` now has lifecycle/API [Issue #310](https://github.com/itschase/OwlMTA-2026/issues/310), and the independent phone object-key bug is [Issue #311](https://github.com/itschase/OwlMTA-2026/issues/311); existing weapon remote Issue #289 remains owner of the weapon caller path. `official-interiors` issues #307-#309 track authorized catalog repair, geometry defects, and measured on-demand loading.

Issues #306-#315 are assigned to `itschase` and grouped under [Milestone #7: Resource Audit and Security Baseline](https://github.com/itschase/OwlMTA-2026/milestone/7). The milestone is an implementation tracker; it does not imply fixes or runtime checks are complete.

The next publication batch should use consistent `Script Resource: <resource>` titles and link each completed dossier to deduplicated implementation issues. The current ledger tracks 69 maintained dossiers (63 full, 6 partial), of which 65 have individual Discussions. The four new dossiers are full static reviews and runtime-unverified.

## Latest published batch — 2026-10-26

Three audited resources now have maintained dossiers and standardized Script Resource Discussions: `es-system` #303, `cargo` #304, and `event-system` #305. Coverage is 65/179: 59 full source reviews and 6 partial; all remain runtime-unverified.

Issues #292-#296 cover medical bill settlement, death/seizure authority, medical recovery custody, injury actions/control recovery, and hospital dispatch. Issues #297-#299 cover forklift transfer authorization, the incomplete shipping-order flow, and compiled client-source reproducibility. Issues #300-#302 cover paintball match authority, basketball/golf sessions, and skating/manifest reliability. Existing shared ownership was retained: stretcher paths update #132; cargo restart recovery links to #214; duplicate startup stays with #21; event remotes remain under #1; fall protection stays #260; item authorization remains #213.

A focused `weapon:modify` server-side ownership/field validation fix is published in [commit `3a85580`](https://github.com/itschase/OwlMTA-2026/commit/3a85580). It covers only the weapon editor handler; Issue #288 remains open for satchel removal and switch/rebuild event authority, and the fix is runtime-unverified.
## Verified project state as of 2026-10-27

- `main` was synchronized with `origin/main` before this batch.
- The manifest census remains 179 resources: 144 active-tree and 35 archived.
- 75 resources have individual Discussions; the repository now has 75 maintained dossiers (70 full source reviews and 5 partial reviews). All dossier and Discussion findings remain runtime-unverified.
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
