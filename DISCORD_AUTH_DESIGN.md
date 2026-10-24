# Discord identity and permissions design notes

This is a proposed target design based on the current source review and the user's requirements. It does not implement an OAuth client, Discord bot, API, or database migration. Role IDs remain blank until each server operator creates their own Discord roles.

## Keep three decisions separate

1. **Authentication:** who completed login? A narrowly scoped, versioned identity API verifies Discord identity and resolves the linked game account. A website, bot, or OAuth callback is an optional client of this API, not a required management portal.
2. **Account selection:** which `core.accounts` identity and characters does that person control? A verified Discord ID is linked explicitly to one existing account.
3. **Authorization:** may this logged-in account perform a particular action now? A trusted role resolver produces named, short-lived capabilities from the configured guild's current role IDs.

Discord login does not grant staff status. A `Support` or other donor role grants configured donor entitlements only. GameMaster, each admin tier, and specialty teams are separate grants.

## Current legacy fields to migrate

`core.accounts` has numeric `admin`, `supporter`, `vct`, `mapper`, `scripter`, and `fmt` fields. `integration/g_configs.lua` maps admin 1–5 to Trial Administrator, Administrator, Senior Administrator, Lead Administrator, and Head Administrator. Supporter has levels 1–2; VCT, mapper, scripter and FMT have their own member/leader ranks. The code currently conflates some of these with `isPlayerStaff()`, and `getGameMasters()` checks supporter status. Do not preserve those mixed semantics in the new model.

The source has `account:gmlevel` readers/writers but no corresponding account column was found in `core.accounts`, and `global/meta.xml` declares GM exports whose active implementations were not located. Treat GameMaster as a separate new capability assignment; do not infer it from a donor rank or numeric admin rank without an explicit data reconciliation decision.

## Source-based legacy staff capability inventory

The following mappings are provisional examples for review, not grants or a new rank policy. A configured Discord role must not grant any listed action until its capability, target scope, duty/state requirements, and migration behavior are explicitly approved. Keep the existing game-side account and faction records authoritative during shadow evaluation.

| Legacy source | Source-confirmed behavior and overlap | Provisional capability examples and migration boundary |
| --- | --- | --- |
| Global administrator: `admin` / `admin_level` 1–5 | `integration/g_staff.lua` maps levels to Trial Admin, Admin, Senior Admin, Lead Admin, and Head Admin. The helpers use increasing thresholds; `isPlayerTrialAdmin(player, duty_required)` checks `duty_admin` only when requested. Core commands use different thresholds: `/punish` and `/recon` require Trial Admin, while other commands and staff tools use stronger checks. | Use per-action capabilities such as `moderation.punish_points`, `moderation.recon`, `moderation.account_lookup`, and `moderation.history.read`. Treat tier inheritance as explicit policy, not an implicit numeric comparison. A duty requirement remains a separate state check. |
| Supporter: `supporter` / `supporter_level` 1–2, plus `duty_supporter` | `isPlayerSupporter` accepts level 1 or higher; `isPlayerSupportManager` accepts level 2 or higher. The level itself does not require duty. Source and [#3](https://github.com/itschase/OwlMTA-2026/issues/3) identify supporter checks as alternatives to Trial Admin for `/forceapp`, `/oforceapp`, `/unforceapp`, `/freeze`, `/unfreeze`, and `/nudge`; `/check`, monitor actions, `/911`, and some teleport access also have supporter gates. | Map these levels to donor entitlements only, such as `donor.supporter_1` and `donor.supporter_2`. If an operational support team needs actions such as application review or player assistance, define separate `support.*` capabilities and an independent assignment source. Never derive moderation, player-control, account-inspection, or GameMaster authority from donor level. |
| GameMaster: `account:gmlevel` and `getGameMasters()` | `global/g_admin_globals.lua:getGameMasters()` currently returns every player accepted by `isPlayerSupporter`, without checking `account:gmlevel` or `duty_supporter`. GM level has client readers and staff-manager writers, but the `/makestaff` handler is commented out; `global/meta.xml` declares GM exports whose active definitions were not found. Active report callers use `getGameMasters()`. See [#14](https://github.com/itschase/OwlMTA-2026/issues/14). | Keep GM independent: examples include `gamemaster.reports.handle` or a specifically reviewed `gamemaster.events.manage`. First reconcile who currently receives `account:gmlevel`, how it persists, and which GM exports/callers are intended. Do not infer a GM grant from supporter, admin, or Discord role position. |
| Specialty teams: `scripter_level`, `vct_level`, `mapper_level`, `fmt_level` | Integration helpers define Tester ≥1, Scripter ≥2, Lead Scripter ≥3; VCT member ≥1 and Vehicle Consultant ≥2 (also a truthy `hasVctAdmin` override); Mapper member/leader at 1/2; FMT member/leader at 1/2. Team checks grant distinct tools and staff-manager scopes. | Keep separate examples such as `development.test`, `resource.manage`, `vehicle_team.catalog.manage`, `mapping.assets.manage`, and `faction_management.staff.manage`. Reconcile the VCT override and review each protected action; team membership alone should not imply global moderation. |
| Faction rank and duty | `faction_ranks.permissions` are checked for a particular faction through `hasMemberPermissionTo(player, factionID, action)`. `getCurrentFactionDuty` supplies separate current-duty state. Existing action names include `add_member`, `set_member_duty`, and `modify_duty_settings`. | Keep authority faction- and action-scoped, for example `faction.<faction_id>.member.invite` or `faction.<faction_id>.duty.configure`, together with membership/rank and duty checks where needed. A Discord role may not create faction membership, rank, or duty. |
| Broad staff predicates and staff-manager UI | `isPlayerStaff()` unions Trial Admin, Supporter, Scripter, VCT member, Mapping member, and FMT member. It is broader than an action permission and includes donor status. The staff manager itself excludes supporter-only access; it admits Trial Admin, VCT member, Lead Scripter, Mapping Team Leader, and FMT Leader. Rank editing has separate per-team hierarchy checks across admin, supporter, VCT, scripter, mapper, and FMT columns. | Replace broad authorization uses with checks such as `staff.roster.view` and team-scoped `staff.ranks.manage.<team>`, only where those actions are actually required. Preserve reviewed actor/target hierarchy for rank changes. A broad “staff” label or roster predicate must not become a universal capability. |

The shared helper guards in `integration/g_staff.lua` also use `not getElementType(player) == "player"`, which does not perform the intended type check in Lua; track that repair under [#23](https://github.com/itschase/OwlMTA-2026/issues/23). Forum group constants in `integration/g_configs.lua` are legacy forum identifiers, not Discord role IDs. Every Discord role ID in the operator template below remains blank and configurable per installation.

Keep remote-request identity and mutation findings distinct from this role-source migration: [#56](https://github.com/itschase/OwlMTA-2026/issues/56) covers admin-history deletion and the HTTP export, [#59](https://github.com/itschase/OwlMTA-2026/issues/59) spoofable actor arguments, [#66](https://github.com/itschase/OwlMTA-2026/issues/66) account-check requester binding, and [#67](https://github.com/itschase/OwlMTA-2026/issues/67) remaining admin remote events. Resolve those server-side trust boundaries alongside migration, without duplicating their tracked scope here.

## Capability vocabulary

Suggested keys are stable strings; their meaning is defined in game code and reviewed per protected action. Discord role position and display name have no authorization meaning.

| Role family | Example capability keys | Migration notes |
| --- | --- | --- |
| Administrator | `admin.trial`, `admin.standard`, `admin.senior`, `admin.lead`, `admin.head` | Configure explicit capabilities for each tier. If tiers inherit, make the inheritance visible in configuration. Do not use Discord role order or a raw `admin_level >= n` check as the final decision. |
| GameMaster | `gamemaster.events`, `gamemaster.characters`, or a deliberately small `gamemaster` bundle | Independent of admin and donor roles. Name the exact actions before granting it. |
| Support/donator | `donor.support`, `donor.tier_2`, etc. | `Support` is a donor role. `supporter_level` means donor levels only. Donor capabilities cover perks and cosmetic/economic entitlements, never moderation. |
| Specialty teams | `scripter.*`, `vehicle_team.*`, `mapping.*`, `fmt.*`, `tester.*` | Keep separate from administrator powers unless a reviewed action explicitly requires both. |
| Faction and duty | faction-rank capabilities and `duty.*` | These remain in-game assignments. A Discord staff role must not silently create faction membership or put someone on duty. |

Example operator template (every role ID is intentionally blank):

```yaml
discord:
  enabled: false
  guild_id: ""
  role_ids:
    admin_trial: ""
    admin_standard: ""
    admin_senior: ""
    admin_lead: ""
    admin_head: ""
    game_master: ""
    support: ""       # donor entitlement only
    donor_tier_2: ""
    scripter: ""
    vehicle_team: ""
    mapping_team: ""
    fmt: ""
```

Operators can leave a mapping unset. Startup should report that the role is unmapped and continue; it should not guess by role name. Before enabling authorization, validate that configured IDs are unique where required and belong to the configured guild.

## Target data boundaries

Keep game identity and gameplay records stable during the first migration. Add a narrowly scoped identity link and keep role configuration separate from player data:

- **Identity link:** unique `discord_user_id` ↔ `account_id`, `linked_at`, `link_method`, and revocation metadata. Enforce one-to-one linking by default. A Discord username is display data only and should not be a key.
- **Operator role map:** guild ID, Discord role ID, capability key, and enabled state. This is server configuration or a versioned settings table, not a client-submitted value. Allow several role IDs to grant one capability only through explicit operator configuration.
- **Resolved grant cache:** account ID, capability, source role ID, resolution time and expiry. Keep it short-lived; do not make an expired cache authoritative. It can remain in memory unless operations require persistent diagnostics.
- **Audit record:** account/Discord ID, capability or action, grant source, decision, timestamp, and correlation ID. Never store OAuth access tokens, bot tokens, or passwords in this table.

Do not store the complete Discord role list as a long-lived privilege snapshot. Do not put a bot token or OAuth client secret in resource Lua, `settings.xml`, an example file, or the game client.

## Login and account-link flows

### Optional browser OAuth callback

If Discord login/linking is implemented, use Discord's server-side OAuth2 Authorization Code Grant with a random `state`, exact callback URL validation, short-lived server session and minimum scopes. This callback/API handles only the browser authorization step; it is not a UCP or required control panel. The Discord access token and client secret stay on the backend. `identify` is sufficient to establish the immutable Discord user ID; Discord also documents `guilds.members.read` for the user's member record in a guild if the implementation chooses user-token role resolution. A bot-backed role resolver may be simpler for continuous current-role checks; evaluate current official scopes and gateway/API requirements at implementation time.

### Link an existing game account

Require proof of the existing game account through an authenticated in-game session or existing credentials, then require a one-time confirmation bound to the pending link. Do not link by matching email, forum ID, username, nickname, or a character name. Show the Discord identity being linked and audit both link and unlink. Use re-authentication and recovery review for unlinking an account that currently has staff grants.

### Log into MTA with Discord

1. Player chooses Discord login in the MTA login UI. The MTA server requests a cryptographically random, short-lived challenge from the account service and associates it with that connection.
2. The game displays a URL and one-time code. The player completes Discord OAuth in a normal browser and confirms the code while authenticated to the identity service.
3. The service verifies the OAuth user, resolves the unique linked `account_id`, and atomically marks the challenge consumed while issuing a short-lived one-use login ticket.
4. The MTA server redeems the ticket over a server-to-server authenticated channel. The service returns the account ID and minimal identity result; MTA then runs its normal ban, activation and account checks before character selection.

Bind the challenge to the pending MTA connection, expire it quickly, rate-limit attempts, and make ticket redemption one-use. The client must never supply the Discord ID, role IDs, role list, target account ID, OAuth token, or ticket result as authority. Do not require OAuth in an embedded game browser. If the identity API is down, keep boot and ordinary already-authenticated gameplay operating, and provide a documented recovery/login route for the operator.

## Authorization flow in the game

Protected server handlers call one server-side function such as `hasCapability(player, "vehicle.impound")`. That function resolves the authenticated `account_id`, fetches current grants from the trusted service/cache, applies explicit capability policy, and fails closed for staff actions if the grant is missing or expired. Game actions still require their separate state checks: player ownership, faction membership, duty, target validity, amount/limit checks, and authoritative MTA `client` identity. A Discord grant does not bypass game-domain invariants.

Never authorize from client-side element data, Discord role names, a `triggerServerEvent` argument, an MTA nickname, or an unverified webhook. Do not accept a client assertion that a user is a guild member. Log denials as well as grants for sensitive actions, without logging secrets.

## Migration sequence

1. Inventory and classify every legacy permission call: admin levels, supporter checks, GameMaster, scripter/mapper/VCT/FMT, faction ranks, duty and ACL. Record the exact action each call protects.
2. Add the capability API while it still delegates to existing server-side policy. Fix the bad player type guards and high-risk unauthenticated mutation paths before changing role sources.
3. Implement identity linking and optional Discord login separately from role authorization. Migrate one account-link cohort and verify duplicate/unlink/recovery handling.
4. Run Discord role resolution in **shadow mode**: record what capabilities would be granted and compare with legacy results, but do not allow shadow grants. Resolve mismatches with server operators.
5. Enable configured roles for a small staff group, with an owner recovery route and auditable rollback. Revoke cached grants promptly when roles change or accounts unlink.
6. Migrate each admin tier, GameMaster and specialty team explicitly. Migrate donor tiers only to donor capabilities. Remove forum-rank and legacy numeric authorization only after all call sites and account records are reconciled.
7. Remove UCP website ACL access and old rank mutation endpoints after replacement workflows are live. Keep the original schema and a reversible account/data backup until the new model is validated.

No real role IDs, Discord credentials, external account mappings, or live database changes belong in this template.
