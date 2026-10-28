# `forums` resource

**Review state:** Active manifest and all listed scripts reviewed statically, with neighboring staff and gameplay callers checked. The GameMaster School screen remains available, but its submit handler is empty in active code; theft and interior-post workflows are disabled or inert. No live forum connection was exercised.

**GitHub record:** [Script Resource Discussion #539](https://github.com/itschase/OwlMTA-2026/discussions/539); [Issue #122](https://github.com/itschase/OwlMTA-2026/issues/122) tracks the legacy bridge, and [Issue #541](https://github.com/itschase/OwlMTA-2026/issues/541) tracks the non-persistent GameMaster School submission.

## What operators and staff encounter

The resource loads three clusters of functionality:

- `/gmschool` opens a client form for a GameMaster or administrator to record players taught and notes. The form submits `gmpost:submit`, but the server handler's database and notification implementation is inside a Lua block comment. The current button therefore sends data to a handler that performs no posting or persistence.
- `/vehpost` and `/intpost` command registrations are commented out. Their corresponding submit handlers are also inert because their former implementation is block-commented. The client forms and event handlers remain in the resource, but active code provides no working approval or post workflow.
- `/resetdrunk` and `/setdrunklevel` are active commands gated through `exports.global:isPlayerAdmin`. They update `characters.alcohollevel` for a resolved, logged-in character. Reset tells the target to relog for the effect; the set command reports the value but does not issue that same refresh instruction. This is a direct database update, not a new authorization or alcohol gameplay system.

The resource has no manifest dependencies declared even though its active command code calls `global` and `mysql`. The commented theft/interior posting code refers to additional exports including integration, pool, anticheat, vehicle, item-system, interior-manager, and MySQL forum helpers. Their presence in commented code does not mean the active feature depends on them at runtime.

## Persistence, external services, and current limits

The only active data writes in this resource are the character alcohol-level updates. Historical forum-post SQL, fixed Owl forum user IDs, forum/category IDs, legacy URLs, and approval-side mutations are inside commented code and are not evidence of a functioning forum connection here. The separate active forum bridge is tracked by [Issue #122](https://github.com/itschase/OwlMTA-2026/issues/122); callers must be inventoried there before retirement or replacement.

Do not treat the GameMaster School form as a durable staff record. Until an in-game record system is implemented and audited, operators should assume submissions are discarded. Likewise, the old theft/interior forms should not be represented as available commands solely because their client UI and event declarations remain in the tree.

## Permission and modernization notes

`isPlayerAdmin` is the inherited numeric staff predicate for the active alcohol commands. Future Discord authorization should map configured role IDs to named staff capabilities and enforce them server-side at each command/action boundary; a Discord role should not be used to grant ordinary alcohol gameplay. The GameMaster School action belongs to a distinct GameMaster/moderator capability, while administrative alcohol overrides remain a staff capability. No Discord role IDs are configured in this resource.

The command actions are candidates for an audited in-game staff dashboard with explicit target selection, current value, reason, confirmation, and an append-only change record. The GameMaster School form should become a searchable training record with actor, trainees, timestamp, outcome/notes, retention policy, and authorization checks. Both should call shared server-owned operations; a future website should be an optional client of the project's own API, not a requirement. Any retained forum or Discord notification should be an optional adapter whose delivery failure cannot undo or conceal the in-game record.

## Runtime verification

No server was started and no runtime tests were run. Before enabling this resource on a disposable server, check the actual startup list and availability of `global` and `mysql`; exercise admin command target resolution, persistence/relogin behavior, and audit logging; confirm `/gmschool` submissions are still discarded; and verify the old `/vehpost` and `/intpost` commands cannot be invoked. Review the `global` and `mysql` callers before adding manifest dependencies or changing command access.
