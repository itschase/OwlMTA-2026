# `runcode` resource

**Review state:** Manifest, command/UI path, server remote handlers, export surface, and checked-in ACL references reviewed. Source hardening is present in the working tree; it is not committed or runtime-verified.

**Discussion:** [Script Resource: runcode #531](https://github.com/itschase/OwlMTA-2026/discussions/531).

## Purpose and operator workflow

This developer utility opens a GUI with `/runcode` for players accepted by `integration:isPlayerLeadScripter`. The operator can execute Lua on their own client or request server-side execution and view returned/error text. Client-side execution remains local. Server execution is arbitrary Lua and must be treated as privileged developer tooling, never as a general staff or Discord capability.

## Server authorization and logging

The server command and both remotely triggerable events now derive the actor from MTA's server-side `client` and check the existing Lead Scripter permission at the action boundary. The code-run event ignores its client-selected event `source`, rejects missing/non-player actors, and accepts only non-empty string payloads up to 16 KiB. The client-log event ignores its claimed actor and accepts only a bounded `client`-side report.

Audit output records the actor name, outcome, execution side, and payload byte count. It does not copy submitted Lua into server logs. Unauthorized-attempt logs are rate-limited per player and cleared on quit. The `runString` exports were removed because repository-wide search found no in-tree callers; external resources are not known, so any downstream dependency would need explicit review before restoring a narrower API.

The executable code remains intentionally powerful for a Lead Scripter. The permission check relies on Owl's current local scripter-level policy; Discord authorization is not implemented here and must not replace independent local action/target checks.

## Related configuration and dependencies

The resource calls `integration:isPlayerLeadScripter` and declares no dependency in its manifest. The old `ACL = 'Admin'` variable was unused and has been removed. `acl.xml` contains a `resource.runcode` object, but this source review does not establish the effective grants of a deployed server configuration. The resource is not listed in the checked-in startup snapshot; keep it disabled outside controlled development until runtime ACL/startup behavior is reviewed.

## Tracking and verification

Issue [#443](https://github.com/itschase/OwlMTA-2026/issues/443) tracks the source hardening and remaining disposable-server work. Verify unauthorized direct event calls, authorized server/client execution, truthful caller attribution, bounded payload behavior, Lead Scripter revocation, and effective ACL/export availability. No MTA server was started and no automated tests were run for this change.
