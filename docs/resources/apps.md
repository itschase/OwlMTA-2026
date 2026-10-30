# `apps`

## Status

- Active resource at `mods/deathmatch/resources/apps`; its manifest loads the application manager and three player application steps.
- Full manifest, direct-caller, persistence, and workflow review completed from source.
- Latest source state: every application-manager remote now binds the MTA event client to an authenticated Trial Admin and records comparison-only `applications.review` or `applications.question_bank.manage` evidence; donor/supporter status cannot open or mutate the manager. The global pending-count refresh event is server-only. Decisions require the reviewer's lock, derive applicant/name from the pending row, accept only state 1/2 with a 2–500 character reason, and conditionally update the application plus `account_details.appstate` in one joined statement using MariaDB's documented [multi-table UPDATE](https://mariadb.com/docs/server/reference/sql-statements/data-manipulation/changing-deleting-data/update) form. The code immediately checks [ROW_COUNT](https://mariadb.com/docs/server/reference/sql-functions/secondary-functions/information-functions/row_count) before announcing success. A third-decline cooldown row is staged first and compensated on a definite execution/no-match failure; an indeterminate row-count read fails closed without guessing whether the cooldown should be removed. Question detail/save/delete inputs are typed and the part-specific deletion floor is corrected. Runtime, crash behavior, in-memory decline-streak recovery, and downstream notification/report follow-up remain unverified.
- The tracked backup startup list places it after account and shared service resources; this is not proof of current deployment order.
- No MTA server or database was started. Runtime behavior, live schema, ACL, and startup are unverified.
- [Discussion #286](https://github.com/itschase/OwlMTA-2026/discussions/286).
- Latest persistence checkpoint: source commit [`e371b21`](https://github.com/itschase/OwlMTA-2026/commit/e371b21), Issue comments [#281](https://github.com/itschase/OwlMTA-2026/issues/281#issuecomment-6514121793)/[#6](https://github.com/itschase/OwlMTA-2026/issues/6#issuecomment-6514122023), and [Discussion #286 comment](https://github.com/itschase/OwlMTA-2026/discussions/286#discussioncomment-19284319).
- Application-gate checkpoint: source commit [`81667d9`](https://github.com/itschase/OwlMTA-2026/commit/81667d9), [Issue #281 update](https://github.com/itschase/OwlMTA-2026/issues/281#issuecomment-6513911222), and [Script Resource Discussion #286 update](https://github.com/itschase/OwlMTA-2026/discussions/286#discussioncomment-19284167).
- Manager checkpoint: source commit [`9bc2b7b`](https://github.com/itschase/OwlMTA-2026/commit/9bc2b7b); Issue updates [#280](https://github.com/itschase/OwlMTA-2026/issues/280#issuecomment-6514020111), [#281](https://github.com/itschase/OwlMTA-2026/issues/281#issuecomment-6514020805), and [#282](https://github.com/itschase/OwlMTA-2026/issues/282#issuecomment-6514021085); Discussion updates [#286](https://github.com/itschase/OwlMTA-2026/discussions/286#discussioncomment-19284251), [#70](https://github.com/itschase/OwlMTA-2026/discussions/70#discussioncomment-19284254), and [#173](https://github.com/itschase/OwlMTA-2026/discussions/173#discussioncomment-19284255).

## Purpose and user workflows

`apps` provides the in-game application gate and staff application/question-bank manager. Account login reads `account_details.appstate`; source callers imply state 0 is quiz step 1, 1 is written responses, 2 is submitted/pending review, and 3 is admitted. This is an implicit convention, not a constrained state machine.

### Player application

1. The account rules flow starts the step corresponding to saved appstate. The login selection gate normally blocks accounts below state 3. The fixed-in-source bypass now accepts only legacy Trial Admin, compares `moderation.application.bypass` without granting, and requires both checked legacy-query execution and synchronized session readback before selection; supporter/donor status no longer bypasses the application.
2. Step 1 selects six questions. The server sends their records, including answer keys, to the client. The client grades answers locally and calls a completion event; the server advances the caller without validating an issued quiz or server-graded answers.
3. Step 2 selects four essay prompts. The client checks only that answer strings exceed one character and submits prompt/answer pairs. The server replaces the caller's pending row and updates appstate if insertion succeeds; the prior row is deleted before the new insert is known to have succeeded.
4. Step 3 alerts logged-in, on-duty staff through report/warning/chat integrations and reports which staff usernames were alerted. Staff may decline an application back to step 2 or accept it, causing an account transition after a delay.
5. A force-app row can impose a 24-hour wait in the displayed step-1 flow. The wait is not enforced by each server-side progression endpoint.

### Staff review and question bank

Staff open `/apps`, `/applications`, or press F7. The manager lists up to 75 applications and supports opening a response, accepting/declining with a reason, and creating/editing/deleting both quiz and essay questions. Review opens write reviewer/date fields and takes an in-memory lock; restart loses that lock. Fixed-in-source server and client gates now permit only legacy Trial Admin while comparing separate review and question-bank capabilities without granting. This is migration behavior, not completed Discord authority.

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

1. **Manager authorization and decision target — fixed in source, runtime open.** All manager remotes now bind an authenticated MTA event client, retain Trial Admin enforcement, compare separate named capabilities without granting, and reject donor authority. Decisions derive applicant/name/state from the stored pending row, require the actor's lock, allow only accept/decline with a bounded reason, conditionally update the pending application plus account state in one statement, and verify a positive affected-row count before follow-up. Third-decline cooldown staging has best-effort compensation; minimized audit and follow-up diagnostics avoid private application text. Runtime direct-call/replay/concurrency/crash evidence and in-memory decline-streak recovery remain open in [Issue #280](https://github.com/itschase/OwlMTA-2026/issues/280).
2. **Client-driven progression and unsafe replacement.** Correct quiz keys reach the client; completion and essay submission are not bound to server-issued stages/prompts; cooldown is not enforced on transitions; replacing a pending row deletes before a successful replacement. Tracked in [Issue #281](https://github.com/itschase/OwlMTA-2026/issues/281).
3. **Unbounded question selection and weak question-bank readiness.** Selectors do not validate the minimum question count and the manager delete check is inconsistent by question part. Tracked in [Issue #282](https://github.com/itschase/OwlMTA-2026/issues/282).
4. **Legacy supporter authority.** The login bypass and application manager are fixed in source to exclude supporter/donor status, but supporter remains accepted for force/unforce commands. Keep donor entitlements separate from reviewer, operator, or staff capabilities; see existing [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3).
5. **Review/privacy/reliability gaps.** The manager count refresh is server-only, but the step-3 path still discloses alerted staff usernames and other progression calls retain unchecked failure paths. Review locks and the three-decline streak remain memory-only; restart can reset them. The joined decision/account update reduces split-brain exposure but is not a transaction or crash-safety proof for MyISAM, and report/timer/redirect follow-up is diagnostic rather than durable. Existing broad ownership includes remote hardening [#1](https://github.com/itschase/OwlMTA-2026/issues/1), account application flow [#80](https://github.com/itschase/OwlMTA-2026/issues/80), admin-system controls [#164](https://github.com/itschase/OwlMTA-2026/issues/164), and schema/transaction groundwork [#6](https://github.com/itschase/OwlMTA-2026/issues/6).

## Modernization direction

Represent application progression as an explicit server-owned state machine tied to the authenticated account. Issue a bounded, expiring one-use quiz snapshot, keep answer keys server-side, validate the submitted essay against issued prompts, and enforce retry policy in every transition. Make review claims and terminal decisions conditional and recoverable. Keep question-bank minimums validated and surfaced as operator readiness. A future API or Discord identity service should call the same domain operations; neither should be required for ordinary in-game application processing. Discord role IDs remain configurable placeholders, and supporter role mapping must not imply staff review authority.

## Runtime verification still required

After safe-start preparation, test the minimum question counts and DB outage paths; direct calls to every progression and manager event; ordinary, supporter-only, and authorized staff callers; cross-account/tampered/replayed IDs; cooldown enforcement; essay replacement failure; concurrent reviewers; reconnect/restart recovery; privacy exposure; and startup reconciliation. These are plans, not completed runtime results.
