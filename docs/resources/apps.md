# `apps`

## Status

- Active resource at `mods/deathmatch/resources/apps`; its manifest loads the application manager and three player application steps.
- Full manifest, direct-caller, persistence, and workflow review completed from source.
- The tracked backup startup list places it after account and shared service resources; this is not proof of current deployment order.
- No MTA server or database was started. Runtime behavior, live schema, ACL, and startup are unverified.
- [Discussion #286](https://github.com/itschase/OwlMTA-2026/discussions/286).
- Application-gate checkpoint: source commit [`81667d9`](https://github.com/itschase/OwlMTA-2026/commit/81667d9), [Issue #281 update](https://github.com/itschase/OwlMTA-2026/issues/281#issuecomment-6513911222), and [Script Resource Discussion #286 update](https://github.com/itschase/OwlMTA-2026/discussions/286#discussioncomment-19284167).

## Purpose and user workflows

`apps` provides the in-game application gate and staff application/question-bank manager. Account login reads `account_details.appstate`; source callers imply state 0 is quiz step 1, 1 is written responses, 2 is submitted/pending review, and 3 is admitted. This is an implicit convention, not a constrained state machine.

### Player application

1. The account rules flow starts the step corresponding to saved appstate. The login selection gate normally blocks accounts below state 3. The fixed-in-source bypass now accepts only legacy Trial Admin, compares `moderation.application.bypass` without granting, and requires both checked legacy-query execution and synchronized session readback before selection; supporter/donor status no longer bypasses the application.
2. Step 1 selects six questions. The server sends their records, including answer keys, to the client. The client grades answers locally and calls a completion event; the server advances the caller without validating an issued quiz or server-graded answers.
3. Step 2 selects four essay prompts. The client checks only that answer strings exceed one character and submits prompt/answer pairs. The server replaces the caller's pending row and updates appstate if insertion succeeds; the prior row is deleted before the new insert is known to have succeeded.
4. Step 3 alerts logged-in, on-duty staff through report/warning/chat integrations and reports which staff usernames were alerted. Staff may decline an application back to step 2 or accept it, causing an account transition after a delay.
5. A force-app row can impose a 24-hour wait in the displayed step-1 flow. The wait is not enforced by each server-side progression endpoint.

### Staff review and question bank

Staff open `/apps`, `/applications`, or press F7. The manager lists up to 75 applications and supports opening a response, accepting/declining with a reason, and creating/editing/deleting both quiz and essay questions. Review opens write reviewer/date fields and takes an in-memory lock; restart loses that lock. The UI and list endpoint currently permit Trial Admin or supporter. This describes legacy code, not intended Discord role mapping or future policy.

## Commands, events, and dependencies

- Player manager: `/apps`, `/applications`, F7.
- Admin-system cross-resource commands: `/forceapp`, `/fa`, `/oforceapp`, `/ofa`, `/unforceapp`, `/unfa`.
- Player flow remote events include `apps:startStep11`, `apps:finishStep1`, `apps:startStep2`, `apps:processPart2`, `apps:startStep3`, and `apps:retakeApplicationPart2`.
- Manager remotes include list/count, question detail/save/delete, application detail/open/close, and application state update handlers. The manifest declares no exports.
- Direct dependencies include MySQL, cache, integration, global, report, account, and anticheat. Account owns login gating and account-state progression; report supplies staff notifications and reviewer statistics.

## Persistence and operator notes

- `applications`: pending/reviewed answers and reviewer data; legacy MyISAM table without foreign keys, state constraints, or one-pending-row uniqueness.
- `applications_questions`: quiz/essay prompt bank, mutable and deletable.
- `force_apps`: retry timestamp with no unique account constraint.
- `account_details.appstate`, `appdatetime`, and `appreason`: shared account progression.
- Startup recomputes a pending count but does not reconcile inconsistent application/account state. Restart loses review locks and decline-attempt counters.
- The two selectors assume at least six valid quiz questions and four essay questions; loops select distinct entries without a prior readiness count. Underfilled or empty banks can fail or prevent bounded completion. The question delete guard also uses incorrect shared threshold logic.
- Operators must supply the schema and seeded question bank and ensure the database and direct service dependencies are ready. The tracked `mtaserver.conf.bak` is a historical startup snapshot only.

## Source-confirmed issues and tracker

1. **Unauthenticated manager remotes and caller-controlled decision target.** Detail reads and question/application mutations lack server-side reviewer checks. Application decisions accept client-supplied applicant ID/name/state/reason rather than deriving the account from the stored row. Client UI checks are not authorization. Tracked in [Issue #280](https://github.com/itschase/OwlMTA-2026/issues/280).
2. **Client-driven progression and unsafe replacement.** Correct quiz keys reach the client; completion and essay submission are not bound to server-issued stages/prompts; cooldown is not enforced on transitions; replacing a pending row deletes before a successful replacement. Tracked in [Issue #281](https://github.com/itschase/OwlMTA-2026/issues/281).
3. **Unbounded question selection and weak question-bank readiness.** Selectors do not validate the minimum question count and the manager delete check is inconsistent by question part. Tracked in [Issue #282](https://github.com/itschase/OwlMTA-2026/issues/282).
4. **Legacy supporter authority.** The login bypass is fixed in source to exclude supporter/donor status, but supporter remains accepted for the manager and force/unforce commands. Keep donor entitlements separate from reviewer, operator, or staff capabilities; see existing [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3).
5. **Review/privacy/reliability gaps.** Any client can attempt repeated count/notification requests; the step-3 path discloses alerted staff usernames; several DB calls lack checked failure handling. Review lock and decline throttle are memory-only. Existing broad ownership includes remote hardening [#1](https://github.com/itschase/OwlMTA-2026/issues/1), account application flow [#80](https://github.com/itschase/OwlMTA-2026/issues/80), admin-system controls [#164](https://github.com/itschase/OwlMTA-2026/issues/164), and schema/transaction groundwork [#6](https://github.com/itschase/OwlMTA-2026/issues/6).

## Modernization direction

Represent application progression as an explicit server-owned state machine tied to the authenticated account. Issue a bounded, expiring one-use quiz snapshot, keep answer keys server-side, validate the submitted essay against issued prompts, and enforce retry policy in every transition. Make review claims and terminal decisions conditional and recoverable. Keep question-bank minimums validated and surfaced as operator readiness. A future API or Discord identity service should call the same domain operations; neither should be required for ordinary in-game application processing. Discord role IDs remain configurable placeholders, and supporter role mapping must not imply staff review authority.

## Runtime verification still required

After safe-start preparation, test the minimum question counts and DB outage paths; direct calls to every progression and manager event; ordinary, supporter-only, and authorized staff callers; cross-account/tampered/replayed IDs; cooldown enforcement; essay replacement failure; concurrent reviewers; reconnect/restart recovery; privacy exposure; and startup reconciliation. These are plans, not completed runtime results.
