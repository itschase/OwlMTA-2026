# Discord identity and gameplay authorization plan

## Goal and boundaries

Discord authorization is the planned primary identity path for production registration and login. The gamemode remains manageable in-game and does not require a UCP website. Operators self-host or select the documented authorization service and configure their own guild. Role IDs ship blank; identity authentication and role-based staff/donor grants are separate, so unmapped roles grant no elevated access. The API defined in [`API_CONTRACT.md`](API_CONTRACT.md) owns Discord verification, account resolution, and role mapping. MTA receives only minimal identity and named-grant results through authenticated server-to-server calls.

Keep these authorities distinct:

- **Game account:** durable local account and login/recovery anchor.
- **Discord identity:** verified immutable Discord user ID, explicitly linked one-to-one with a game account per installation.
- **Capabilities:** named global grants resolved by the API from operator-configured role IDs, such as `moderation.use`, `gamemaster.events`, or `faction.applications.review`.
- **Donor entitlement:** `supporter.level_1` or `supporter.level_2`; donation levels do not grant staff, GameMaster, faction, or duty authority.
- **Faction rank/duty:** character-local rank and active duty state, independent of Discord global capabilities.
- **MTA ACL:** host-managed resource/engine permissions, not gameplay grants.

## Reusable standalone integration boundary

The Discord integration should be developed as its own reusable, self-hostable project rather than embedded throughout OwlMTA. Its generic contract must not depend on Owl's tables, numeric staff ranks, faction resource, character schema, or UI.

Use three layers:

1. **Identity service and Discord application/bot.** Own OAuth, guild policy, link/login challenges, one-use tickets, per-installation credentials, configurable role-to-capability/donor mapping, bounded sessions, revocation, rate limits, and audit.
2. **Reusable MTA adapter resource/SDK.** Own asynchronous `fetchRemote`, challenge/status flows, ticket redemption, grant/session caching, heartbeat/revocation, stale callback rejection, least-privilege ACL requests, errors, health, and stable server exports/events. It operates on opaque installation/account references supplied by an integration host.
3. **OwlMTA integration layer.** Map Owl's authenticated internal account ID to the generic adapter; provision/link accounts through Owl's migration rules; translate named global capabilities into Owl action checks; and keep organization membership/rank/duty, property access, inventory ownership, donor commerce, and gameplay policy inside OwlMTA.

The current standalone implementation is in [`itschase/mta-discord-identity`](https://github.com/itschase/mta-discord-identity) (source reviewed at revision `619d18f`). The generic MTA resource exports `beginLink`, `exchangeTicket`, `hasCapability`, `getDonorTier`, and `clearPlayerSession`. Owl's host adapter must implement the server-only `mta-discord-identity:resolve-account` callback from the validated, logged-in account session. Resource scripts should not each call Discord or interpret role IDs; use one Owl-side authorization facade that consumes the adapter's named-grant check and then composes the resource's own local checks. This repository does not yet contain that host integration, and the external service/configuration has not been deployed or runtime-verified with Owl.

Other MTA servers should be able to implement only the small host interface and use the same service/adapter without importing Owl resources or schemas. Publish the protocol, adapter contract, version compatibility, threat model, example integration, migrations, and conformance tests independently. Keep provider-specific Discord code behind the service boundary so the MTA adapter consumes a stable identity/grant API rather than Discord APIs or raw role IDs.

## Operator configuration

Keep all role IDs blank by default and place actual values in operator-owned API deployment configuration. Do not ship Owl role IDs, guild IDs, Discord bot credentials, or API keys. Example configuration shape (values are intentionally blank):

```yaml
discord:
  enabled: false
  guild_id: ""
  roles:
    staff_trial:
      role_id: ""
      capabilities: ["moderation.use"]
    staff_admin:
      role_id: ""
      capabilities: ["moderation.use", "moderation.manage"]
    gamemaster:
      role_id: ""
      capabilities: ["gamemaster.events"]
    faction_applications:
      role_id: ""
      capabilities: ["faction.applications.review"]
    supporter_1:
      role_id: ""
      donor_tier: "supporter.level_1"
    supporter_2:
      role_id: ""
      donor_tier: "supporter.level_2"
```

The service validates Discord Snowflake strings, rejects duplicate or conflicting mappings, and treats empty configuration as no Discord-derived grants. Startup output may summarize configured capability names/counts, but must not reveal secrets or raw user data. MTA configuration needs only a disabled-by-default API URL and per-install credential in an operator-managed server-only secret file/facility, excluded from source control and client downloads; it does not need role IDs or a Discord bot token. Document filesystem access, provisioning, rotation, and revocation. Never place the credential in Lua source, client settings, `meta.xml`, URL query strings, or synchronized element data.

## Link and unlink flow

1. For an existing legacy account, the player proves account control through the controlled migration flow and explicitly requests linking. MTA derives the account ID from a validated server session. New accounts start with Discord authorization and are provisioned after identity and consent checks.
2. MTA asynchronously creates a challenge with `POST /api/v1/game/link-challenges`. The API binds it to the authenticated installation and account, stores only a hash of a cryptographically random code, expires it within 10 minutes, and allows only one pending challenge per account.
3. The player redeems the code through an operator-controlled Discord bot interaction. The trusted bot/service derives the immutable Discord user ID from the authenticated interaction and verifies guild membership against the service's configured guild. A website consent page is optional and is not a UCP.
4. The service atomically consumes the code and commits the link, enforcing one account per Discord identity and one Discord identity per account within that installation. A conflicting link requires unlink or audited recovery; it is never overwritten silently.
5. MTA polls the authenticated `GET /api/v1/game/link-challenges/{challenge_id}` status endpoint asynchronously. On `redeemed`, it requests a grant refresh. Polling stops at a terminal state or challenge expiry.
6. The logged-in player can explicitly confirm unlink in-game. MTA clears local cached grants immediately and calls the API unlink endpoint. If Discord is unavailable or the owner loses access, use an operator-mediated, step-up-authenticated recovery process with audit and uniqueness checks.

Challenge creation and redemption are idempotent and rate-limited. Repeating the same redemption for the same identity is safe; a different identity cannot redeem an already consumed code. Include request IDs and idempotency keys as defined in the API contract.

## Authorization and outage behavior

- The service resolves configured role IDs into named capabilities and the separate donor tier. Never pass raw Discord roles to MTA. Never accept client-supplied role IDs, account IDs, or authority data.
- MTA authorizes in server-side handlers from current account/session and server-owned grant state. Do not put API-derived capabilities in client-synchronized element data.
- Grants have a maximum 10-minute lifetime with an explicit `expires_at` and policy revision. Refresh asynchronously after linking and on login/near expiry. Sensitive API-derived actions fail closed after expiry. New production login fails closed during identity-service outages; existing sessions are accepted only under their bounded lease, after which the operator recovery procedure applies.
- Do not fall back to supporter, forum group text, client data, or stale numeric admin flags when Discord refresh fails. Existing legacy authority remains unmigrated until each call site has an explicit migration and rollback plan.
- Unlink clears local session grants immediately. Role removal takes effect on the next successful refresh, no later than grant expiry. Log refresh age, request ID, and outcome without bearer credentials. Audit links, unlink/recovery, grant decisions, targets, results, timestamps, and trace IDs with data minimization.

## MTA request handling

MTA's server-side `fetchRemote` is asynchronous; no join, login, gameplay handler, or resource-start path waits for it. Use explicit connection attempts (1 or 2), a short connection timeout (for example 3000 ms), bounded in-resource concurrency, rate-limited polling, and bounded retry/backoff. Requests with the same `queueName` run serially, so separate the bounded challenge-poll and grant-refresh queues if one flow could delay the other. MTA does not document a TLS-verification toggle for `fetchRemote`; confirm certificate-chain/CA behavior, HTTPS, redirects, supported options, and outbound reachability on the selected server build. Set `maxRedirects = 0` for authenticated API calls where supported and treat network/TLS/DNS/destination failures as optional-service outages.

Pass request ID, account ID, operation, player element, and a server-maintained session generation as callback arguments. Before applying a callback, check that the player still exists, is logged into the same account, and the pending request/session generation still matches. Derive account ID from the server-validated login session and MTA's `client`; never accept it from a remote client parameter. Ignore callbacks made stale by disconnect, relogin, unlink, a newer refresh, or adapter restart. Track `fetchRemote` request handles; on resource stop/restart invalidate the resource generation and abort outstanding requests with `abortRemoteRequest` where possible. MTA warns that `fetchRemote` won't trigger inside another `fetchRemote` callback, so schedule status-poll → grant-refresh and retry work after the callback returns via a timer/event. Store grants server-side; log outcomes but not codes or credentials.

The adapter resource must request only `function.fetchRemote` through its `<aclrequest>` and the operator must approve that resource-specific right. Do not put it in the Admin group or expose adapter exports with `http="true"`; that metadata enables inbound HTTP calls, not outbound requests. The checked-in ACL snapshot grants `function.fetchRemote` in the Admin ACL while also putting `resource.*` in the Admin group. Reconcile this inherited broad grant with the least-privilege ACL audit tracked by [issue #22](https://github.com/itschase/OwlMTA-2026/issues/22). The checked-in `mtaserver.conf.bak` starts mysql/pool/global/integration before account; it is a template snapshot, not evidence of live configuration. Do not add an API-service health dependency or a hard resource dependency that prevents local-account gameplay from starting.

## Minimal first slice

1. Implement the self-hosted API's per-install authentication and account scoping, registration/login and legacy-link challenge create/redeem/status, unlink/recovery audit, session revocation, and grant-refresh contract. This is the scope of [issue #68](https://github.com/itschase/OwlMTA-2026/issues/68); include ACL approval, installation secret provisioning, and target-release transport/callback lifecycle checks in its acceptance checklist.
2. Add one MTA server adapter for Discord registration/login challenges, one-use ticket redemption, legacy-account linking, session status/revocation, and async grant refresh. The MTA process may boot in setup mode without service credentials; production registration/login must fail closed until the operator configures the authorization service.
3. Configure no role IDs by default. Discord identity authentication can be tested without staff/donor grants; no role-based capability is granted until mapped. Test linking, conflict, expiry, unlink, session revocation, recovery, and API-outage behavior in a disposable server before migrating existing predicates.
4. Inventory admin, supporter, GameMaster, auxiliary staff, faction rank/duty, and MTA ACL predicates. Migrate separately by capability and retain rollback; do not combine donor tiers with staff authority. Capability migration is tracked separately by [issue #3](https://github.com/itschase/OwlMTA-2026/issues/3).

Discord login is part of the target identity flow, while legacy-account linking and role-capability migration remain separately testable stages. [Issue #2](https://github.com/itschase/OwlMTA-2026/issues/2) tracks primary production authentication; [issue #96](https://github.com/itschase/OwlMTA-2026/issues/96) tracks active-session revocation so a revoked Discord authorization cannot leave a player connected indefinitely.

FiveManage media storage and Grafana log search are separate optional adapters described in `API_CONTRACT.md`; neither is required for this first slice.

## Current code evidence and migration caution

The current login handler loads numeric `admin_level`, `supporter_level`, `vct_level`, `mapper_level`, `scripter_level`, and `fmt_level` fields from account data. Integration helpers evaluate numeric admin levels and duty, while supporter helpers evaluate numeric supporter levels. These are legacy server account authorities, not Discord grants, and should not be replaced wholesale. The integration resource exports some permission helpers to clients, so new API-derived authority must remain server-only and use server-side exports/checks. See `mods/deathmatch/resources/account/login-panel/server.lua`, `mods/deathmatch/resources/integration/g_staff.lua`, and `mods/deathmatch/resources/integration/meta.xml`.

The existing forum helper demonstrates asynchronous `fetchRemote` but puts a configured key in the URL and targets a hard-coded Owl forum host. Do not copy that credential or endpoint pattern into the new adapter; see `mods/deathmatch/resources/integration/s_forums.lua`.

This remains a proposed design, not an implemented or tested Discord integration. Source anchors: `mods/deathmatch/resources/account/login-panel/server.lua` validates credentials then sets the local account session; `mods/deathmatch/resources/account/meta.xml` has no API adapter dependency; `mods/deathmatch/resources/integration/meta.xml` has no `function.fetchRemote` ACL request; `mods/deathmatch/mtaserver.conf.bak` lists startup order; `mods/deathmatch/acl.xml` contains the broad resource grant noted above. The actual per-server configuration and target MTA build still require operator confirmation. MTA references: [fetchRemote](https://wiki.multitheftauto.com/wiki/FetchRemote), [meta.xml ACL requests](https://wiki.multitheftauto.com/wiki/Meta.xml), [abortRemoteRequest](https://wiki.multitheftauto.com/wiki/AbortRemoteRequest).
