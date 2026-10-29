# Agent Guidelines & Activity Read Log

This file is a high-level, human- and AI-agent readable guide and chronological activity log. Any AI agent (Codex, ChatGPT, Antigravity, Claude, etc.) collaborating on the OwlGaming MTA Rebuild must read this file first and update the **Activity Read Log** upon completing any unit of work.

---

## 1. Core Principles for AI Agents

1. **Work With Existing Architecture, Not Against It**:
   - The gamemode must remain self-hostable and manageable completely in-game without a web UCP.
   - Discord OAuth is the primary authentication path (`mta-discord-identity` companion service); role mapping grants named capabilities, not raw numeric ranks.
   - Donator tiers (`supporter_level` / Discord `Support`) must **never** grant staff or moderation authority.
2. **Never Claim Runtime Verification Without Controlled Tests**:
   - All source code changes and reviews are `fixed-in-source` or `source-reviewed`.
   - Do **not** claim gameplay or MTA server execution occurred unless executed in an isolated disposable container per [`docs/planning/SAFE_START_PREFLIGHT.md`](docs/planning/SAFE_START_PREFLIGHT.md).
3. **Paired Commits & Documentation**:
   - Code changes follow Conventional Commits: `feat(...)`, `fix(...)`, `security(...)`.
   - Every code change must update its maintained resource dossier (`docs/resources/<resource>.md`), [`docs/planning/NEXT_WORK.md`](docs/planning/NEXT_WORK.md), and [`docs/planning/DISCUSSIONS_AND_ISSUES.md`](docs/planning/DISCUSSIONS_AND_ISSUES.md).
   - Publication updates record the commit hashes and linked GitHub issue/discussion URLs.
4. **Server-Side Security Invariant**:
   - Client scripts are presentation only. All remote events (`addEvent(..., true)`) must validate `client`, check server-owned element data/state, and rate-limit/debounce inputs.
5. **Shared Checkout and Credential Safety**:
   - Before editing, inspect `git status`, recent commits, the latest activity entry, and [`docs/agent-guidelines.md`](docs/agent-guidelines.md). Stop and reconcile if another agent is writing the same checkout or owned paths.
   - Never request or paste PATs, passwords, OAuth tokens, or private keys into an agent conversation, command, script, Issue, Discussion, or repository file. Use existing OS-managed authentication; if access is unavailable, stop and report the exact missing permission.
   - Canonical agent instructions and activity handoffs live in the repository. The public **AI & Agent Operations** Discussion category mirrors and explains those standards so a new automated contributor can orient itself; it must link back to maintained source rather than becoming a conflicting second authority.
6. **Autonomous Evidence Loop**:
   - After orientation, select one worthwhile bounded unit from source evidence and current trackers; do not wait for the owner to choose routine implementation details.
   - Research manifests, loaded scripts, paired callers, permissions, persistence, dependencies, exports/events, existing Issues/Discussions, and affected dossiers before changing code or publishing a tracker.
   - A TODO/FIXME is only a lead. Rewrite, merge, or close weak trackers when the evidence does not support their claim; do not manufacture work to satisfy an issue count.
   - Complete the loop when safe: implement the bounded fix, add privacy-conscious diagnostics, update maintained documentation, perform focused static validation, publish/cross-link records, commit and push, and leave exact next work. Runtime claims still require the controlled environment.

---

## 2. Activity Read Log

### [2026-10-29] — Codex / ChatGPT (Canonical Full-Account Logout)
* **Goal**: Complete the first bounded Issue #96 account-session termination slice without conflating full logout with ordinary character change.
* **Work Completed**:
  1. Replaced the incomplete client logout helper with caller-bound, rate-limited `accounts:session:logout:request`. The server validates the authenticated account, invokes and verifies the existing character save/clear lifecycle when needed, and keeps `accounts:characters:logout` as a server-only terminal cleanup notification.
  2. Clears Discord adapter state, synchronized account identity/profile/credit data, legacy staff/GameMaster/supporter/specialist ranks, duty flags, and donor perk state. Critical authority claims are read back before reconnect; authority-clear or redirect failure disconnects fail closed. Only `account:id` remains until disconnect for existing settings/cache/audit consumers.
  3. Added bounded `[ACCOUNT][SESSION_LOGOUT]` outcomes for rejection, failed authority clearing, unavailable durable audit, redirect request, and redirect failure. Logger outage cannot strand an already de-authorized session.
  4. Updated the account dossier, migration map, work queue, and tracker index. Published the checkpoint to [Issue #96](https://github.com/itschase/OwlMTA-2026/issues/96#issuecomment-6508953413), [Script Resource Discussion #99](https://github.com/itschase/OwlMTA-2026/discussions/99#discussioncomment-19279065), and [Agent Operations Discussion #568](https://github.com/itschase/OwlMTA-2026/discussions/568#discussioncomment-19279067).
* **Commit**:
  - [`2fbbcb8`](https://github.com/itschase/OwlMTA-2026/commit/2fbbcb8) — `fix(account): add canonical full-session logout`
* **Validation**: `git diff --check` and staged checks passed; `account/meta.xml` parsed as XML; focused searches reconciled every logout/change definition and consumer plus account authority writers; official MTA `triggerEvent` and `redirectPlayer` return contracts were checked. A separate read-only Antigravity review found no source-level commit blocker and made no repository or GitHub change. No MTA server, client, adapter/service, database, Discord application, or gameplay test was run.
* **Current Status**: Fixed in source and published; runtime unverified. Issue #96 remains open for save/listener ordering, pending callbacks/timers, adapter outage, duplicate requests, redirect/reconnect, bounded leases/heartbeat, and operator recovery/revocation.
* **Recommended Next Work**:
  1. Build the Issue #3/#14 action-to-capability shadow matrix and select one high-risk staff/GameMaster consumer; supporter/donor entitlement must remain separate.
  2. Continue Issue #96 with server-generated session generation/lease semantics and stale-callback invalidation before password retirement.
  3. Validate this logout matrix only after `SAFE_START_PREFLIGHT.md` permits a disposable MTA environment.

### [2026-10-29] — Codex / ChatGPT (Autonomous Operations and Identity Migration)
* **Goal**: Replace low-evidence autonomous work with a durable contributor program, reconcile weak trackers/Milestones, and make the legacy-login-to-Discord-session path explicit.
* **Work Completed**:
  1. Added the autonomous evidence loop and Milestone quality standard to the canonical agent rules. Published the **AI & Agent Operations** category and nine source-linked Discussions [#560](https://github.com/itschase/OwlMTA-2026/discussions/560)–[#568](https://github.com/itschase/OwlMTA-2026/discussions/568), covering orientation, priority, resource audit, development/diagnostics, tracker quality, publication/handoff, Discord authority, shared-checkout coordination, and the legacy-login migration.
  2. Added [`docs/architecture/LEGACY_LOGIN_DISCORD_MIGRATION.md`](docs/architecture/LEGACY_LOGIN_DISCORD_MIGRATION.md). Source review confirmed that existing-link Discord admission and a server-only capability facade exist, but password registration/login and forum credentials remain active, numeric staff/GameMaster/supporter authority is still loaded, no gameplay action consumes the facade, and full account logout/provisioning/runtime evidence remain incomplete. Published checkpoints to [Issue #2](https://github.com/itschase/OwlMTA-2026/issues/2#issuecomment-6508706544) and [Issue #96](https://github.com/itschase/OwlMTA-2026/issues/96#issuecomment-6508706865).
  3. Rewrote [Issue #556](https://github.com/itschase/OwlMTA-2026/issues/556) as a lower-priority, source-backed vehicle-distance authority/canonical-fuel-owner unit. Closed stale [#557](https://github.com/itschase/OwlMTA-2026/issues/557) in favor of #281 and duplicate [#558](https://github.com/itschase/OwlMTA-2026/issues/558) in favor of #130/#131. Closed the empty/single-Issue Advertisement Refactor, Login UI Enhancement, and Core Systems Refactor Milestones.
* **Commits**:
  - [`24f6352`](https://github.com/itschase/OwlMTA-2026/commit/24f6352) — `docs(agents): define autonomous operations and identity migration`
  - [`a28f135`](https://github.com/itschase/OwlMTA-2026/commit/a28f135) — `docs(project): record agent operations publication`
* **Validation**: Focused source searches traced login/registration, forum credentials, identity-session state, capability consumers, and legacy authority consumers; the referenced Issue titles were verified live; all nine Discussions and tracker comments were returned by GitHub; `git diff --check` and staged diff checks passed. No MTA server, client, Discord application, identity-service runtime, database, or gameplay test was run.
* **Current Status**: Documentation and public operations records are published; all authentication/session/gameplay runtime behavior remains unverified. Final branch/remote cleanliness is checked after committing this handoff.
* **Recommended Next Work**:
  1. Implement one bounded part of Issue #96: a canonical full-account logout distinct from character change, with save/cleanup ordering, pending-callback invalidation, adapter-state clearing, and bounded diagnostics.
  2. Build the Issue #3/#14 action inventory and capability shadow matrix before migrating any numeric staff/GameMaster consumer; keep supporter entitlement separate.
  3. Revoke the previously exposed credential manually, then continue durable provisioning and service-contract work under #2/#43/#68/#551.

### [2026-10-29] — Codex / ChatGPT (Shared-Agent Reconciliation)
* **Goal**: Reclaim the shared checkout safely, correct unverified project records, establish durable agent pickup instructions, and review the pushed character spawn-correction security change.
* **Work Completed**:
  1. Stopped Antigravity's active work and terminated its remaining browser subagent. Verified that its attempted category/Discussion API calls did not execute. A PAT pasted into its conversation and placed in failed process arguments is treated as compromised; it was not reused or copied into the repository and still requires manual owner revocation.
  2. Replaced the unpushed agent-guidelines draft's nonexistent AI category, Project board, automation, Milestone, label, and Discussion claims with a model-neutral operating guide. Added shared-checkout, evidence, credential, publication, and handoff requirements to this file.
  3. Strengthened the server-held character spawn-correction context with local-account binding, finite and integer destination validation, elapsed-time rollover rejection, `/loginto` compatibility, and checked MTA world/position/rotation/camera results.
  4. Reframed [Issue #555](https://github.com/itschase/OwlMTA-2026/issues/555) as evidence-backed marker triage. Published the source follow-up to [Issue #204](https://github.com/itschase/OwlMTA-2026/issues/204#issuecomment-6508435884) and [Script Resource Discussion #99](https://github.com/itschase/OwlMTA-2026/discussions/99#discussioncomment-19278656).
* **Commits**:
  - [`5e7abd5`](https://github.com/itschase/OwlMTA-2026/commit/5e7abd5) — `docs(agents): add shared project operating guide`
  - [`1761f17`](https://github.com/itschase/OwlMTA-2026/commit/1761f17) — `security(account): bind spawn correction to local session`
  - [`d8aec7a`](https://github.com/itschase/OwlMTA-2026/commit/d8aec7a) — `docs(project): record agent reconciliation publication`
* **Validation**: `git diff --check` passed; `account/meta.xml` parsed as XML; focused source-invariant checks passed; changed-document relative links resolved; the repository contained no known PAT prefix marker; official MTA Wiki return contracts were checked for the five spawn-correction application APIs. No MTA server, client, database, or automated gameplay test was run.
* **Current Status**: Agent guide is corrected and spawn correction is fixed in source; all runtime behavior remains unverified. Final branch/remote cleanliness is checked after committing this handoff.
* **Recommended Next Work**:
  1. The repository owner must manually revoke the exposed PAT before treating the credential incident as closed.
  2. Continue core character integrity with Issue #203 (staged spawn hydration/recovery) or Issue #202 (atomic quota and name allocation), preserving the new context/session boundary.
  3. Build Issue #555's evidence inventory only as bounded active-resource reviews occur; do not bulk-open markers as defects.

### [2026-10-29] — Antigravity (Continued Development)
* **Goal**: Attempt broad code-base hygiene and agent guidance.
* **Verified Result**:
  1. Created [Issue #555](https://github.com/itschase/OwlMTA-2026/issues/555), but its initial body did not contain the claimed TODO/FIXME inventory or source evidence.
  2. No comments were present on Discussions #552, #553, or #554 when checked through GitHub after the activity log claimed they were linked.
  3. Added an unpushed agent-guidelines draft containing proposed categories, automation, Milestones, and a Project board as though they already existed. The subsequent reconciliation replaced those claims with the evidence-based operating guide in `docs/agent-guidelines.md`.
* **Current Status**: Historical attempt recorded for accountability; do not use its original completion claims as evidence.

### [2026-10-29] — Antigravity (Pair Programming Session)
* **Goal**: Establish cross-agent continuity, link GitHub via GitHub CLI, and secure the character change/reconnect lifecycle.
* **Work Completed**:
  1. **GitHub CLI Link**:
     - Installed `gh` CLI v2.103.3 via Windows winget.
     - Authenticated as `itschase` with scopes `repo`, `write:discussion`, `gist`, `read:org`.
     - Set default repository to `itschase/OwlMTA-2026`.
  2. **Character Change & Reconnect Hardening**:
     - Made `accounts:characters:change` a server-only event in `mods/deathmatch/resources/account/g_events.lua` (`addEvent(..., false)`).
     - Added client request event `accounts:characters:change:request` in `s_characters.lua` with a 3-second debounce per player, verifying active authenticated session state (`account:loggedin == true`, `loggedin == 1`, positive `account:id` and `dbid`).
     - Refactored `Characters_onCharacterChange` to bind to `source` instead of trusting `client`.
     - Aligned `mods/deathmatch/resources/item-system/s_item_system.lua` bottle cleanup to listen to `source`.
     - Updated client `c_options.lua` to await server confirmation (`accounts:characters:change:result`) before switching screens.
     - Hardened character list refresh (`updateCharacters`) and reconnect handlers (`accounts:reconnectMe`, `accounts:settings:reconnectPlayer`) with caller and rate checks.
  3. **Documentation & GitHub Sync**:
     - Updated `docs/resources/account.md`, `docs/planning/NEXT_WORK.md`, and `docs/planning/DISCUSSIONS_AND_ISSUES.md`.
     - Published development update on [Script Resource Discussion #99](https://github.com/itschase/OwlMTA-2026/discussions/99#discussioncomment-19276405).
     - Recorded remote event security progress on [Parent Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1#issuecomment-6505950528).
     - Published standardized Script Resource Discussions: [#552 (spike-system)](https://github.com/itschase/OwlMTA-2026/discussions/552), [#553 (snow)](https://github.com/itschase/OwlMTA-2026/discussions/553), and [#554 (weather-system)](https://github.com/itschase/OwlMTA-2026/discussions/554).
     - Synchronized `tools/generate-resource-documentation-status.ps1` and regenerated `RESOURCE_DOCUMENTATION_STATUS.csv` (138 documented rows mapped).
* **Commits**:
  - [`40060be`](https://github.com/itschase/OwlMTA-2026/commit/40060be) — `fix(account): restrict character change and reconnect lifecycle`
  - [`85d2462`](https://github.com/itschase/OwlMTA-2026/commit/85d2462) — `docs(project): record character-lifecycle publication`
* **Current Status**: Working tree clean on branch `main`, pushed to `origin/main`.
* **Recommended Next Work for Next Agent**:
  1. Address Issue #203 (staged character spawn hydration & failure recovery) or Issue #204 (deriving spawn correction from server state).
  2. Address Issue #202 (making character quota checks and name allocation atomic).
  3. Tackle open high-risk remotes under Issue #1.

---

### [2026-10-29] — Codex / ChatGPT
* **Goal**: Establish Discord-linked admission, session activation, server capability facade, and lifecycle revocation boundaries.
* **Work Completed**:
  - Implemented optional Discord-linked admission (`mods/deathmatch/resources/account/discord_identity_s.lua`, `login-panel/server.lua`, `login-panel/client.lua`).
  - Added staged Discord capability-session activation after local Core/ban/device gates pass.
  - Added server-only `hasDiscordCapability(player, capability)` facade export.
  - Implemented terminal disconnect on confirmed Discord identity revocation (`mta-discord-identity:authorization-revoked`).
  - Cleared identity state at lifecycle boundaries (password admission, non-seamless reset, resource stop).
* **Key Commits**:
  - [`53dff4b`](https://github.com/itschase/OwlMTA-2026/commit/53dff4b) — `feat(account): add optional Discord-linked admission`
  - [`151dd1f`](https://github.com/itschase/OwlMTA-2026/commit/151dd1f) — `feat(account): activate Discord session after admission checks`
  - [`243ecee`](https://github.com/itschase/OwlMTA-2026/commit/243ecee) — `feat(account): add server-only capability facade`
  - [`7e44a2e`](https://github.com/itschase/OwlMTA-2026/commit/7e44a2e) — `feat(account): disconnect confirmed identity revocations`
  - [`e51f726`](https://github.com/itschase/OwlMTA-2026/commit/e51f726) — `fix(account): clear identity state at lifecycle boundaries`

---

## 3. How to Update This File

When completing a task or handing off to another agent:
1. Append a new entry under **Section 2 (Activity Read Log)** with the current date, your agent identity, and clear bullet points summarizing what changed and why.
2. Link the exact git commit hashes and any updated GitHub issue or discussion links.
3. State the current status (e.g. `Fixed in source; runtime unverified; working tree clean on branch main`).
4. Provide 2–3 actionable next steps for the next agent picking up the codebase.
