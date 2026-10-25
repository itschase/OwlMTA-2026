# Next work record

Last updated: 2026-10-25 after the core identity, authority, economy, and inventory publication batch.

## Verified project state

- `main` was synchronized with `origin/main` before this batch.
- The manifest census remains 179 resources: 144 active-tree and 35 archived.
- 34 resources have individual Discussions and versioned dossiers: 28 full manifest-script reviews and 6 partial reviews.
- Source review, proposed design, fixed-in-source behavior, and runtime verification remain distinct. All resource dossiers are runtime-unverified.
- The MTA server has not been started. Static review and safe-start preparation remain the gate.

## Completed core audit batch

The five resources that already had early individual Discussions now have full versioned dossiers:

1. `account` — registration/login/character entry, session state, database and Discord migration boundaries.
2. `bank` — transfers, ATMs, journals, ownership, balance authority, and failure/reconciliation behavior.
3. `factions` — legacy organization membership, ranks, duty, wages, policy, permissions, and compatibility API inputs.
4. `item-system` — inventory authority, item definitions/metadata, transfers, world items, persistence, and cross-resource contracts.
5. `global` — shared exports, money/items/notifications/permissions helpers, caller assumptions, and blast radius.

Discussions #99-#102 and #73 are updated in place rather than duplicated. Every resource discussion now uses the standardized `Script Resource: <resource>` format.

## Cross-cutting tracker follow-up

- Keep Issues #41/#52 as the parent MDC authorization/privacy units and add the complete remote-event matrix from the `mdc` dossier.
- Keep Issue #40 as the prison direct-event parent and add gate, roster-duty, offline-manager, and automatic-release evidence.
- Keep Issue #48 as the payday/shop event parent and link settlement Issues #179/#180.
- Add the source-confirmed bus-fare debit/recipient problem to Issue #77.
- Update Issue #95 with the current coverage counts and the five new resource Discussions.
- Keep camera Issues #191/#192 and MDC Issues #193-#195 bounded; do not split implementation until source ownership and acceptance overlap are reassessed.

## Next publication wave

Full source audits are complete for `saveplayer-system` + `resources`, `duty` + `donators`, and `pd-system` + `interior_system`. Convert those reports into six dossiers, six consistently named resource Discussions, non-duplicate Issues, and parent-Issue evidence updates. A follow-on compact wave should cover `usercontrolpanel` + `insurance`, `job-system` + `tow-system`, and `item-world` + `rightclick`.

## Safe-start gate after static review

Before starting MTA, produce a reproducible disposable environment plan: sanitized configuration and secrets, schema import/migration order, resource start graph, optional-service stubs, least-privilege database accounts, seeded test identities, backup/rollback steps, logging destinations, and a smoke-test matrix. Starting the server is a later explicit phase and must not be represented as completed by static inspection.

The first static plan is now maintained in [Static Safe-Start Preflight](SAFE_START_PREFLIGHT.md) and discussed in [Server Operators #215](https://github.com/itschase/OwlMTA-2026/discussions/215). Its gates are requirements, not runtime results.
