# `ipb` resource

**Review state:** Manifest, player access flow, remote settings/stat events, CPU sampler, and client GUI callers reviewed. Data exposure and performance behavior remain runtime-unverified.

**Discussion:** [Script Resource: ipb #534](https://github.com/itschase/OwlMTA-2026/discussions/534).

## Purpose and user workflow

IPB is an in-game performance browser for server resources. A Scripter can open it with `/ipb` or `/perfbrowse`; the client GUI requests server statistics, chooses categories/options/filters, and refreshes the selected view every two seconds. Operators may enable a five-second sampler that retains up to 999 high-usage Lua timing rows in memory and warns active IPB listeners above a configurable threshold. The sampler is process-local: it is not a durable incident log and its history is lost on resource/server restart.

## Access and server events

The command handler checks `integration:isPlayerScripter` and sends the client an open event. The server's `ipb.toggle` handler separately requires the configured `AccessRightName` (default `general.http`) before registering the player as a listener. Thus the UI can be opened for a Scripter who lacks the ACL right, while that player will not receive stats. The logout cleanup also uses the ACL predicate rather than the command predicate. This inconsistency is source-confirmed; its intended policy is not established. See [Issue #442](https://github.com/itschase/OwlMTA-2026/issues/442).

Client events for enabling/listening, category, options, and filter changes derive the player from MTA's server-side `client`. The category/options/filter handlers require an existing listener, but do not validate the supplied values or re-check access on every update. The GUI's “Lua time recordings” view is replaced server-side with the in-memory high-usage samples. Treat this as operationally privileged information; confirm the intended exposure policy before broadening access.

## Configuration and dependencies

The manifest settings control sample enablement (`SaveHighCPUResources`), minimum logged CPU percent (`SaveHighCPUResourcesAmount`), notification threshold (`NotifyIPBUsersOfHighUsage`), and required ACL right (`AccessRightName`). The resource uses MTA's performance statistics API, timers, element/player events, and ACL permission checks, plus Owl's `integration:isPlayerScripter` and date/time helper. No database persistence is declared. The manifest has no explicit resource dependencies; ensure the integration export and MTA APIs are available before enabling.

## Operator and future management notes

Keep Scripter command access and ACL-based telemetry access as one explicit policy decision; avoid a UI-open path that appears authorized but returns empty data. Bound and normalize category/options/filter values, preserve ACL checks when settings change, and make sampler thresholds and retention visible in the operator configuration reference. A future dashboard may present current resource cost and recent samples, but should not turn transient samples into permanent logs without a separate retention/privacy decision. Discord capabilities, if adopted, should control a narrowly named global staff access boundary; donor/supporter tiers should not grant server diagnostics.

## Runtime verification

On a disposable server, verify Scripter versus ACL-only access, UI open/close and logout, permission changes during a session, each stats category, Lua timing samples, filtering inputs, threshold boundaries, timer cleanup, memory cap, resource restart, and behavior when `integration` is unavailable. No server or tests were run.
