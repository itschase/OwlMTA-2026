# `report` resource

**Review state:** Full active manifest, player submission path, staff command surface, queue lifecycle, statistics, and direct integration review. Source state is documented; client/server behavior and recovery have not been runtime-verified.

## Player reporting

The active `/report` entry is registered by `help`, not by the legacy report GUI. It opens the Help Center's Report Center, retrieves report types from `report`, and submits through `clientSendReport`. The older `report/c_reports.lua` GUI has a separate submit path, but its `/report` command handler is commented out; do not confuse that archived-in-practice UI with the current entry point.

The client checks reason length and blocks another submission while one is pending. Those checks improve the interface but do not constrain a remote event. The server must independently bind the reporter to MTA's authenticated caller and validate the target, category, reason, and rate.

## Staff workflow and commands

Staff use report queue commands including `/reports`, `/ar`/`acceptreport`, `/ara`, `/fr`/`falsereport`, `/tr`/`transferreport`, `/cr`/`closereport`, `/car`/`closeallreports`, `/dr`/`dropreport`, `/er`/`endreport`, `/ri`/`reportinfo`, `/cp`/`changereport`, `/ur`, `/showadminreports`, `/getsavedreports`, and `/setsavedreports`. `/reportlazyfix` and `/cks` are maintenance-oriented commands. Their actual permission behavior is implemented through existing integration staff helpers and legacy forum-permission checks; several type/duty-specific checks are commented out, so this dossier records code behavior without inventing a policy hierarchy.

The staff UX should eventually consolidate queue search, assignment/transfer, response, closure, and immutable audit history into a dashboard. Commands remain available during any migration. Every UI or command should call the same server-side operation.

## Queue, persistence, and logging

- The open report queue is held in a Lua table. On report resource stop/start, it is copied to/from the `data` resource's in-memory storage. A full server restart does not have durable queue recovery in this path.
- Closed reports and staff session counters use SQL. Staff accept/transfer/close `dbLog` calls in `s_reports.lua` are commented out, leaving an audit gap.
- `report:syncStats` accepts client-computed online/duty minute totals and writes them to `online_sessions`. The account is bound to `client`, but counters are not bounded or derived from server elapsed time.
- `#279` tracks reward milestone idempotency and `/setsavedreports`; it is not a substitute for server-authoritative queue or session-stat handling.

## Connections and authority

The active flow connects `help`, `integration`, `global`, `data`, `mysql`, `anticheat`, `pool`, `achievement`, and UI/layout integrations in `admin-system`, `hud`, and `job-system-trucker`. Staff routing depends on report type and duty state. Existing GameMaster/Supporter coupling is tracked separately in [Issue #14](https://github.com/itschase/OwlMTA-2026/issues/14); preserve that as a legacy-policy concern, not as permission to conflate donor tiers and moderation authority.

Discord staff capabilities may eventually complement existing in-game staff checks for protected queue actions. They must not bypass target validation, active character/account binding, report assignment, duty rules, or action audit. Ordinary player submissions do not require Discord staff or supporter roles.

## Source-confirmed issues

- The remotely callable `clientSendReport` handler uses event `source` as reporter and checks only logged-in state; the client chooses event data and supplies target/type/reason. Server validation is needed. See [Issue #399](https://github.com/itschase/OwlMTA-2026/issues/399).
- `report:syncStats` writes unbounded client-provided online/duty minutes. Derive elapsed time on the server or validate a server-issued session counter. See [Issue #400](https://github.com/itschase/OwlMTA-2026/issues/400).

These are source-level trust-boundary findings, not tested exploit claims.

## Runtime verification

On a disposable server, verify current Help Center submission, valid/invalid targets and types, reason limits, repeat/rate behavior, staff permission and duty routing, queue handoff across resource restart and full server restart, SQL failures, session counter changes, and queue audit recovery. No server or tests were run.

## MTA reference

- [MTA Script security](https://wiki.multitheftauto.com/wiki/Script_security) explains why remote event `source` and parameters are untrusted and why server-side `client` should bind the caller.
- [MTA `triggerServerEvent`](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) documents the client-to-server event boundary.
