# Next work record

Last updated: 2026-10-25 after the external-management, jobs, towing, and contextual-item publication batch.

## Verified project state

- `main` was synchronized with `origin/main` before this batch.
- The manifest census remains 179 resources: 144 active-tree and 35 archived.
- 46 resources have individual Discussions and versioned dossiers: 40 full manifest-script reviews and 6 partial reviews.
- Source review, proposed design, fixed-in-source behavior, and runtime verification remain distinct. All resource dossiers are runtime-unverified.
- The MTA server has not been started. Static review and safe-start preparation remain the gate.

## Completed publication batch

Six completed audits are now maintained as versioned dossiers and consistently named Script Resource Discussions:

1. `usercontrolpanel` — legacy website RPC and broad shared website ACL boundary.
2. `insurance` — vehicle policy, quote, claim, cancellation, accounting, privacy, and reconciliation flows.
3. `job-system` — civic-job selection, work sessions, rewards, service jobs, and progression.
4. `tow-system` — conventional towing, law-enforcement seizure, impound lanes, release, cleanup, and settlement.
5. `item-world` — persistent object lifecycle, permissions, deletion, retention, and evidence/storage boundaries.
6. `rightclick` — client presentation boundary and migration input for the contextual-action registry.

Discussions #247-#252 use the standardized `Script Resource: <resource>` format. Issues #240-#246 record the non-duplicate implementation units found by this batch.

## Cross-cutting tracker follow-up

- Update Issues #4/#22 with the complete legacy UCP HTTP-export and ACL evidence.
- Update Issues #15/#45 with the insurance actor/privacy, quote, claim, cancellation, and settlement matrix; link durability Issue #240.
- Update Issues #47/#77/#181 with the job selection, bus, fishing, and photography evidence; link service-work Issue #241.
- Update Issue #151 with the `rightclick` compatibility-adapter and context descriptor requirements.
- Cross-link `item-world` Issues #244-#246 with contextual-action Issue #151 and evidence/provenance Issues #153/#184.
- Update documentation tracker Issue #95 with the 46-topic, 40-full, 6-partial coverage counts.

## Active audit wave

Three bounded, non-overlapping reviews are in progress: `object-interaction` + `item-move`, `job-system-trucker` + `paynspray-system`, and `npc` + `object-system`. Consolidate each finished report into a maintained dossier, a consistently named resource Discussion, deduplicated implementation Issues, and parent-Issue evidence updates. Do not infer runtime success from static inspection.

The reusable Discord/MTA identity service is now being developed in a separate project chat and repository boundary. OwlMTA remains one host adapter and consumer; its in-repository documents define integration contracts rather than embedding the standalone product.

## Safe-start gate after static review

Before starting MTA, produce a reproducible disposable environment plan: sanitized configuration and secrets, schema import/migration order, resource start graph, optional-service stubs, least-privilege database accounts, seeded test identities, backup/rollback steps, logging destinations, and a smoke-test matrix. Starting the server is a later explicit phase and must not be represented as completed by static inspection.

The first static plan is now maintained in [Static Safe-Start Preflight](SAFE_START_PREFLIGHT.md) and discussed in [Server Operators #215](https://github.com/itschase/OwlMTA-2026/discussions/215). Its gates are requirements, not runtime results.
