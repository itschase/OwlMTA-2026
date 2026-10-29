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

---

## 2. Activity Read Log (Chronological)

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
