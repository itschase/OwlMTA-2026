# `chance-system` resource

**Review state:** Full manifest-script and direct-caller source review. Runtime command behavior and supported MTA Lua behavior remain unverified.

## Purpose and player use

`chance-system` supplies three small OOC roleplay commands: `/luck [max]` returns a random integer between 1 and the chosen maximum (100 when omitted); `/chance [0-100]` announces a success/failure attempt at a stated percentage; `/flipcoin` announces heads or tails. Results are announced through `global:sendLocalText` and do not change character, inventory, money, or persistent state.

These are quick, low-stakes player actions, so retaining the commands is practical. A future help/search catalogue may list them and a lightweight panel could reproduce the same server-generated rolls, but neither is currently implemented. No staff, faction, donor, GameMaster, or operator workflow is registered.

## Technical map and connections

- `meta.xml` loads only `s_chance-luck.lua` on the server and contains no exports, custom network events, client scripts, settings, or version-specific dependencies.
- `tryLuck` handles `/luck`, `tryChance` handles `/chance`, and `oocCoin` handles `/flipcoin`.
- All outcomes are generated server-side and passed to `global:sendLocalText`; no other direct callers were found in the reviewed code.
- The resource owns no tables, files, long-running state, or external endpoint. There is no resource-specific configuration.
- Discord authorization is not required for these ordinary roleplay utilities. Any future UI should call the same server-owned roll logic and should not turn a client-supplied result into authority.

## Source-confirmed findings and tracking

- **`/chance` is one point below its stated probability.** `s_chance-luck.lua:16-38` classifies `math.random(100) >= p1` as failure. Success therefore occurs only when the roll is lower than the requested integer percentage, making 100% fail on roll 100 and reducing intermediate integer success rates by one in 100. See [Issue #360](https://github.com/itschase/OwlMTA-2026/issues/360).
- **`/luck` does not validate its maximum.** `s_chance-luck.lua:1-14` converts input using `tonumber` and passes the result to `math.random` without requiring an allowed positive integer bound. See [Issue #361](https://github.com/itschase/OwlMTA-2026/issues/361). Exact handling of invalid numeric forms should be checked on the supported MTA Lua version when fixed.
- `/chance` accepts numeric values in the inclusive 0–100 range but does not define whether fractional percentages are intended. Define and document that behavior during correction.
- `/luck`'s no-argument path draws 1–100. `/flipcoin` draws from 1–2. No runtime command invocation was performed.

## Modernization opportunities

- Correct `/chance` threshold semantics and choose a clear fractional-input policy.
- Validate `/luck` input as a positive integer within a documented bound and provide consistent syntax feedback.
- Keep commands as fast alternatives while listing them in discoverable in-game help; do not force a dashboard for a one-step random roll.
- If a panel or contextual action is later added, reuse server-side random generation and local OOC output, with no Discord role dependency.

## Runtime verification still required

On a disposable MTA environment, exercise all commands with missing, valid, boundary, fractional, nonnumeric, zero, negative, and excessive inputs; confirm OOC recipient/range behavior and current MTA Lua argument handling. Record the MTA build and exact results. No server or tests were run for this review.
