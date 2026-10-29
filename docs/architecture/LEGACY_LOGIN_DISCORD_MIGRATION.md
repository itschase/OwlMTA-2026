# Legacy Login to Discord Session Migration Map

## Status and objective

This is a source-reviewed migration map. MTA, Discord, the identity service, databases, reconnects, and role changes have not been runtime-validated.

The target is not merely a Discord button. A verified Discord authorization lease becomes the production account-admission proof and remains bound to the active Owl account session. Owl still owns durable internal account IDs, characters, bans, device policy, local gameplay state, and persistence. Gameplay resources consume a narrow server-only account facade; they do not call Discord, accept raw Discord/account IDs from clients, or interpret role IDs.

## Current source state

The first compatibility slice exists:

- `account/login-panel/server.lua` centralizes password and Discord-linked admission through the same active-account, ban, serial/device, duplicate-session, `account_details`, tutorial/application, and character-selection gates.
- `account/discord_identity_s.lua` validates adapter provenance, stages/activates the identity session, provides the server-only `hasDiscordCapability` facade, clears state at lifecycle boundaries, and disconnects a matching Discord-admitted session on confirmed terminal revocation.
- Character change retains the account-level lease, while non-seamless account reset, password admission, resource stop, and terminal authorization loss clear or end external authority as documented.

The migration is not complete:

- `accounts:login:attempt` still provides full password authentication and legacy hash upgrade.
- `playerRegister` still provisions password accounts and calls the inherited activation path.
- Login still synchronizes numeric `admin_level`, `account:gmlevel`, specialist ranks, and `supporter_level` as legacy authorities.
- No active gameplay resource calls `account:hasDiscordCapability`; capability migration has not begun.
- Full account logout is incomplete: character change exists, but the client-side `accounts:characters:logout`/`accounts:logout` paths do not establish a complete server account-session termination workflow.
- Legacy forum link UI still sends a forum username and password to `forum:login`; it is unrelated to Discord OAuth and should not survive the identity migration.
- The adapter/service runtime, durable identity storage, new-account provisioning, recovery, restart, outage, and reconnect matrices remain unverified.

Repository search found `account:id` in 88 active-resource files, `admin_level` in 26, `account:gmlevel` in 11, `supporter_level` in 6, and `account:loggedin` in 8. These counts are discovery leads, not a demand to replace every use. Local account/character gates remain valid; only admission proof and global role-derived authority migrate to the Discord-backed session contract.

## Authority model

| Concern | Canonical authority | Migration rule |
|---|---|---|
| Production login/registration | Verified Discord identity lease plus Owl local gates | Fail closed when configured identity proof is unavailable; do not silently fall back to passwords. |
| Durable game identity | Immutable Owl account ID linked to verified installation-scoped Discord identity | Never use raw Discord IDs as gameplay primary keys or client claims. |
| Active account session | Owl account resource plus matching adapter lease/generation | Rebind on every protected query; clear on logout, switch, restart boundary, expiry, or confirmed revocation. |
| Staff/GameMaster authority | Named Discord capabilities through the server-only Owl facade | Migrate action by action; retain hierarchy, duty, target, state, proximity, and audit checks. |
| Supporter/donor access | Separate entitlement/tier result | Never grant staff, GameMaster, organization, duty, or moderation authority. |
| Character/organization/duty/ownership | Owl gameplay resources and database state | Keep local; a global capability cannot bypass domain rules. |
| Bans/device/duplicate session | Owl server-side admission policy | Apply before and immediately before final session commit for every admission method. |
| Recovery | Audited operator/owner recovery with uniqueness and revocation | Password recovery may remain only as a bounded migration/recovery mechanism, not an automatic production fallback. |

## Ordered migration units

### 1. Production identity and durable service contract

Complete Issues #2, #68, and #551: durable installation/account/Discord links, one-use connection-bound login proof, adapter/version pinning, authenticated transport, bounded lease, revocation, restart/outage semantics, and disposable conformance evidence.

### 2. Discord-first provisioning and legacy-account linking

Complete Issue #43 with an idempotent Core/MTA account transaction and recovery record. New registration begins from verified Discord authorization. Existing accounts require controlled proof and explicit one-to-one linking; a Discord subject or account cannot be rebound silently.

### 3. Canonical account logout, reconnect, and account switch

Complete Issue #96 before retiring password login. Define one server workflow that saves/clears the character, invalidates pending callbacks and adapter state, clears non-synchronized claims, ends the local account session, and returns the client to admission. Character change must remain distinct and preserve the same account lease.

### 4. Staff and GameMaster capability migration

Complete Issues #3 and #14 through an action inventory and shadow comparison. Start with narrow global actions, record legacy-versus-capability decisions without granting on mismatch, and migrate only after the action's independent policy checks are documented. Do not bulk-replace numeric rank reads or synchronize capability lists to clients.

### 5. Supporter entitlement separation

Inventory the six `supporter_level` consumer files. Map only donor benefits to the separate entitlement result. Remove supporter fallthrough from staff/GameMaster selection and reports. Role loss refreshes entitlement without manufacturing moderation authority.

### 6. Device, recovery, and secret retirement

Complete Issues #158 and #201: in-game device enrollment/revocation, privacy/retention rules, removal of client-shipped hash material, dependent-scheme rotation, and audited owner recovery. Password admission is retired only after the replacement and rollback/recovery paths are proven.

### 7. Remove obsolete forum identity paths

Retire `forum:login`, forum password UI, forum-link element data, and missing forum integration dependencies unless a separately justified non-authentication feature remains. Never translate this flow into a second credential system.

## Per-resource conversion checklist

For each legacy consumer:

1. classify it as local session state, global capability, donor entitlement, organization/duty authority, MTA ACL, or obsolete integration;
2. trace the manifest-loaded client and server callers plus every export/event consumer;
3. keep `client`, account, character, target, ownership, duty, proximity, state, value, and settlement checks server-side;
4. use `exports.account:hasDiscordCapability` only for the named global action and fail closed on missing/stale grants;
5. keep donor entitlements outside the capability path;
6. add bounded decision/outage/revocation diagnostics without tokens, raw Discord identity, role IDs, or private payloads;
7. update the resource dossier, owning Issue, relevant Discussion, migration matrix, and runtime test cases;
8. preserve a rollback path until the Discord-backed behavior is verified in the disposable environment.

## Existing ownership

No new umbrella Issue is needed. Use #2 for production authentication, #3 for capability migration, #14 for GameMaster/supporter separation, #43 for provisioning, #68 for the service/adapter/Owl contract, #96 for session lifecycle, #158 for device policy, #201 for legacy secret rotation, and #551 for the pre-authentication challenge/admission slice. Update stale Issue text when source has advanced instead of creating parallel trackers.
