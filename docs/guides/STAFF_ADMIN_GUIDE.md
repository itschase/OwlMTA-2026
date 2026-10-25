# Staff and administration guide

This guide separates staff operations from player features and server operation. All current behavior below is source-derived; runtime validation has not yet happened.

## Authority domains

| Domain | Current source model | Target model |
|---|---|---|
| Moderation staff | Numeric account fields such as admin; legacy integration helpers | Explicit named capabilities resolved from configured Discord role IDs |
| GameMaster | Legacy `getGameMasters()` and chat predicates overlap with supporter status | Separate `gamemaster.*` capabilities, unrelated to donations |
| Supporter/donor | `supporter` and `supporter_level` fields; supporter tiers represent donation levels | Non-staff donor entitlements; configurable tiers, no moderation grant |
| Faction authority | Character faction, faction rank, stored rank permissions, duty state | Remain separate from server staff; Discord account authentication must not replace faction-specific authority |
| MTA ACL | Resource/user rights for engine operations and exports | Narrow host-level security boundary, never a mirror of all gameplay roles |

## Staff workflows found in source

- Staff rank changes use `staff_manager_s.lua` and `staff:editStaff`, with rank scope, target checks, asynchronous rechecks, bound updates, and staff changelog rows. This is a good pattern to generalize.
- Admin tools cover history, moderation, bans, jail, player inspection, reports, announcements, and staff management.
- `integration` exposes legacy forum permission and role helpers. Several gameplay systems make direct numeric-rank checks; replace these gradually with a capability service, preserving distinct actions and hierarchy rules.
- Faction management has its own member/rank/perk/duty/finance controls. Do not map faction leader to global admin by default.
- Report/support queues currently blend forum permissions, supporter duty, and admin duty; this needs a deliberate support capability separate from donor level.

## Source findings requiring issues/fixes

- Remote admin-history deletion lacks server-side creator/lead authorization even though the client UI enforces it. It can also reverse warning/punishment counters.
- `admin-system` exposes `addAdminHistory` through HTTP. Treat this as an externally callable mutation until HTTP exposure is removed or protected by an authenticated adapter.
- `/banaccount` has no visible target-admin hierarchy check, unlike online/offline player ban paths.
- Admin jail and login read/write jail state through inconsistent tables (`accounts` vs `account_details`).
- Faction invite, phone assignment, rank/duty configuration, and related setters need server-side permission checks at each event.
- Prison event handlers have missing law/duty checks; offline add-prisoner path appears to continue after a failed zone condition.
- MDC login accepts a client-supplied character ID without visible current-character ownership binding.
- The legacy integration helpers conflate donor/supporter with staff/GameMaster in some APIs and chat predicates.

These are findings to track, not a claim that each issue has already been filed or fixed. Link each concrete item to a GitHub Issue before implementation.

## Discord role mapping principles

1. Discord role IDs are blank operator configuration values. Role names are display only and cannot safely identify grants.
2. Staff grants use fine-grained capabilities (`moderation.warn`, `moderation.ban`, `history.read_all`, `history.delete_own`, `faction.manage`, `gamemaster.event_manage`). Avoid one all-powerful “admin role” for routine operations.
3. Donor tiers (`supporter.level_1`, `supporter.level_2`, etc.) grant explicitly listed cosmetic/quality-of-life entitlements only. They never imply staff status.
4. Resolve grants from verified Discord membership on a trusted backend. MTA clients cannot assert their own Discord roles.
5. Log actor account, linked Discord user ID, capability, target, action, outcome, and correlation ID. Protect the audit log from the actor.
6. Cache identity/grants only for a bounded interval and define revocation behavior. High-impact changes require fresh authorization; on verification failure, deny sensitive action and preserve normal account access where possible.
7. Keep faction rank, character duty, MTA ACL, and global staff capabilities independent.

## Operator handoff

Use the [Server Operator Guide](SERVER_OPERATOR_GUIDE.md) for deployment, ACL, external-service configuration, recovery, and incident handling. Routine player/staff management must be available in-game without a UCP.
