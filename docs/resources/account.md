# `account`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded shared, server, client, login, character, tutorial, settings, news, and rules script plus schema and representative integrations.
- Runtime: unverified. The server has not been started.
- Discussion: [Script Resource: account](https://github.com/itschase/OwlMTA-2026/discussions/99).

## What it does

`account` owns the inherited username/password registration and login interface, account/session element data, tutorial and application gates, character quota/create/list/select/spawn/change/logout, account and character F10 settings, email capture, news/rules presentation, saved client preferences, and an obsolete forum-link path.

The current player flow is local credential submission, Core and MTA account loading, legacy account/rank/credit state attachment, tutorial/application/device/ban checks, character selection or creation, then a large multi-resource character hydration and spawn. Character change saves and clears state before returning to selection.

This is not yet Discord authentication. Discord-first identity, role-to-capability grants, and active-session revocation remain proposed work in Issues #2, #3, #68, and #96.

## Player, staff, and operator use

- The login panel accepts registration or returning credentials and can remember them locally. Character selection lists owned active characters; creation collects roleplay identity and appearance before a server-selected starting location.
- Normal character selection binds the requested character ID to the authenticated account. Recent F10 settings code uses server-side actor/account/character binding plus per-setting allowlists and normalization; Issue #79 remains open until runtime validation and every writer are reconciled.
- Authorized staff can use `/loginto` to enter another account's character. Rules, news, and patch-note update commands are also present. These actions require capability/audit redesign; donor/supporter status must remain separate from staff authority.
- Operators need both Core and MTA schemas plus a long dependency chain including `mysql`, `anticheat`, `global`, `integration`, `cache`, `pool`, `item-system`, `factions`, `logs`, `donators`, `bans`, `serialwhitelist`, `prison-system`, and spawn-time feature resources.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/account/meta.xml`](../../mods/deathmatch/resources/account/meta.xml)
- Modern login panel: [`login-panel/server.lua`](../../mods/deathmatch/resources/account/login-panel/server.lua) and [`login-panel/client.lua`](../../mods/deathmatch/resources/account/login-panel/client.lua)
- Character lifecycle: [`s_characters.lua`](../../mods/deathmatch/resources/account/s_characters.lua), [`c_characters.lua`](../../mods/deathmatch/resources/account/c_characters.lua), [`s_create_character.lua`](../../mods/deathmatch/resources/account/s_create_character.lua), and [`c_create_character.lua`](../../mods/deathmatch/resources/account/c_create_character.lua)
- Settings boundary: [`f10-settings/s_f10_settings.lua`](../../mods/deathmatch/resources/account/f10-settings/s_f10_settings.lua)
- Persistence spans `core.accounts`, `account_details`, `characters`, `account_settings`, `character_settings`, `characters_faction`, jobs, custody, item, and organization state.
- Live state duplicates database identity and authority across player element data such as `account:*`, `loggedin`, `dbid`, staff/team ranks, credits, and hydrated character state.
- Key remote families cover login/registration, tutorial/application completion, character list/create/select/spawn/change/logout/quota/correction, email, legacy forum linking, and account/character settings.

## Credential, privacy, and lifecycle findings

- New registration uses bcrypt-sha256; accepted legacy salted double-MD5 credentials are upgraded in place. The client remember-me feature stores the reusable plaintext password in reversibly encrypted XML.
- Registration writes `core.accounts` and MTA `account_details` separately and calls an absent localhost activation-mail service. Issue #43 owns partial cross-schema provisioning; Issues #12/#13 own forum and activation dependencies.
- The email-change event previously trusted a client-supplied account ID and had no authenticated-session boundary. The source now derives the account from the logged-in server session, validates and parameterizes the update, synchronizes the email only after DB success, and returns the actual result. [Issue #527](https://github.com/itschase/OwlMTA-2026/issues/527) remains open for runtime, duplicate-address, and DB-failure validation. No active password-recovery consumer was found, so takeover impact is not established.
- Login commits identity, email, ranks, and session state before serial-whitelist denial. Issue #158 owns moving device policy before session commit and complete rollback.
- After an account resource restart, `account/s_main.lua:onJoin` preserves existing `loggedin` and account state if `account_details` contains the account ID, then `account/s_login.lua` consumes a one-use local seamless flag without rechecking activation, ban, serial, authorization generation, or session age. The Discord adapter/session lease boundary belongs to Issues #68 and #96; no bounded lease exists in current Owl source.
- Login synchronizes email, credits, staff/support ranks, punishment, admin-jail, and related account data more broadly than minimum gameplay need. Server-only session claims and field-level synchronization need an explicit consumer inventory.
- Shared hash constants are shipped in a client-loaded file. Any intended secret is therefore public to every connecting client and must be removed or replaced.
- Character creation performs quota lookup, name lookup, insert, logging, and temporary state changes as separate operations. Concurrent or failed requests lack a durable idempotency/reconciliation boundary.
- Character spawn is a long side-effectful hydration sequence. Dependency/DB failure after state is cleared can strand a partial character session.
- The spawn-correction remote accepts a client-provided expected location and can teleport from the selection area; correction must come from stored server state or a server-issued one-use context.
- The obsolete forum-login path transmits a forum password and depends on missing legacy integration. It should be retired under the Discord/website-independent identity work, not rebuilt as a parallel login system.

## Target direction

Use immutable internal account IDs linked to verified Discord identities; short-lived, revocable, installation-bound sessions; server-held named capabilities; supporter tiers as separate entitlements; staged/idempotent provisioning; one canonical active-character session; minimal client claims; audited staff impersonation; and recoverable character creation/change/spawn phases. Local password verification should remain only as a bounded, audited migration or owner-recovery mechanism until retired.

Bounded implementation work is tracked by [Issue #201](https://github.com/itschase/OwlMTA-2026/issues/201) for client-shipped hash constants, [#202](https://github.com/itschase/OwlMTA-2026/issues/202) for atomic character creation, [#203](https://github.com/itschase/OwlMTA-2026/issues/203) for staged spawn hydration, and [#204](https://github.com/itschase/OwlMTA-2026/issues/204) for server-derived spawn correction. Existing Issues #2, #43, #74, #79, and #158 retain identity, provisioning, protected-data, settings, and device-session ownership.

Runtime verification must cover legacy hash upgrade and bcrypt boundaries; remember-me migration; activation/provisioning partial failures; duplicate/concurrent registration; Discord link/revoke/outage and ticket replay when implemented; serial/ban/session ordering; account resource and dependency restart; character ownership/quota/name/concurrent creation; every spawn hydration failure point; forged correction coordinates; settings type/allowlist/persistence; privacy synchronization; donor/supporter/staff isolation; `/loginto` hierarchy/audit; and independent Core/MTA DB outages.
