# Authentication and optional integration API contract

## Purpose and boundary

Discord authorization is the planned primary identity path for production registration and login. A self-hosted, versioned service verifies Discord identity, resolves or provisions a game account, maps configured role IDs to capabilities, and supports session revocation. MTA never listens publicly for website or Discord management calls. MTA handlers remain responsible for enforcing game rules; the API supplies bounded identity and grant data, not a replacement for gameplay authorization logic. A website is an optional API client, not a requirement for login management or gameplay.

This file is the **proposed Owl host contract**, not a description of the current standalone service protocol. The private, reusable [`mta-discord-identity`](https://github.com/itschase/mta-discord-identity) project now implements a separate `/v1` link/session API and generic MTA adapter. This document's `/api/v1` login, grant-refresh, and heartbeat routes do not currently match that implementation. OwlMTA has no host adapter, account-login integration, local capability facade, or revocation disconnect handler yet. Treat the route table below as a target design only until the contract is reconciled against the standalone service and a versioned Owl adapter is implemented. See [Issue #68](https://github.com/itschase/OwlMTA-2026/issues/68).

No Discord guild, role ID, or secret is configured in OwlMTA. The MTA process must remain bootable without the service; future production registration/login should fail closed until configured. Existing sessions should use bounded leases, and confirmed authorization revocation should disconnect the linked session once the host integration is implemented. Provide an explicit audited bootstrap/recovery procedure; never silently switch to password-only login.

### Current standalone service snapshot (not Owl-integrated)

The standalone repository currently documents these actual routes:

| Method and path | Current behavior |
|---|---|
| `POST /v1/link-challenges` | Create an account-bound Discord-link challenge. |
| `GET /v1/link-challenges/{id}?accountId=...` | Read challenge status for the owning account. |
| `DELETE /v1/link-challenges/{id}` | Cancel a pending link challenge. |
| `POST /v1/oauth/discord/start` and `GET /v1/oauth/discord/callback` | Start the browser OAuth flow and perform Discord verification with PKCE and current guild-member lookup. |
| `POST /v1/sessions/exchange` | Consume an account-bound one-use ticket and issue a bounded session with named capabilities and a separate donor tier. |
| `POST /v1/sessions/refresh` | Re-evaluate current policy using installation authentication plus the opaque session token; failed refresh requires the adapter to clear grants. |
| `POST /v1/accounts/unlink` | Remove an account link and revoke its sessions. |

The service returns no raw Discord role data to MTA. Its current lifecycle state is process-local; durable multi-instance storage and real MTA-runtime conformance remain future work in the separate repository. This snapshot is sourced from that project's [`docs/API.md`](https://github.com/itschase/mta-discord-identity/blob/main/docs/API.md) and [`docs/ARCHITECTURE.md`](https://github.com/itschase/mta-discord-identity/blob/main/docs/ARCHITECTURE.md). Reconcile route names, request schemas, errors, installation auth, session behavior, and capability refresh before implementing the target contract below.

The generic MTA adapter currently exposes server-side `beginLink(player)`, `exchangeTicket(player, ticket)`, `hasCapability(player, capability)`, `getDonorTier(player)`, and `clearPlayerSession(player)`. Link/exchange work is asynchronous; an export's immediate return is not the final authorization result. The host is expected to answer the server-only `mta-discord-identity:resolve-account(player, reply)` callback synchronously with a non-empty account ID derived from trusted logged-in MTA state. For Owl, the resolver should require a live player element, `account:loggedin == true`, and a positive server-set `account:id`, then return a stable string ID. The adapter emits `mta-discord-identity:link-challenge`, `mta-discord-identity:grants-changed`, and `mta-discord-identity:session-failed` notifications to the host. `clearPlayerSession` only clears adapter-local cache; it does not itself unlink the service identity or revoke the server session. Owl therefore needs its own account-binding facade, lifecycle hooks, action-boundary capability checks, and an explicit service unlink/revocation flow.

## Product and repository boundary

The protocol is intentionally reusable beyond OwlMTA. Implement the identity service/Discord application and a generic MTA adapter as a standalone, versioned project. The standalone project owns installation authentication, Discord verification, role mapping, challenge/ticket/session/revocation behavior, audit, and transport. It must not import Owl database schemas or encode Owl staff/faction rules.

OwlMTA consumes that project through a thin game-specific integration resource. The Owl layer supplies a server-derived internal account reference, handles legacy-account proof and local provisioning, maps generic named capabilities into Owl action checks, and retains all character, organization rank/duty, asset, inventory, commerce, and gameplay authorization. A second MTA gamemode should be able to replace only this host adapter while keeping the service and generic MTA client unchanged.

The standalone distribution should include a stable protocol/schema package, MTA resource/SDK, reference service/bot deployment, example host adapter, threat model, migration/version policy, conformance tests, and disabled-by-default sample configuration. Its license and release process must permit independent server operators to self-host and extend it without receiving any Owl secrets or identifiers.

## Conventions and authentication

- Base path: `/api/v1`. Keep request/response schemas and error codes stable within v1.
- All routes use HTTPS. MTA authenticates with a per-installation credential in a server-only secret/config store. The API maps that credential to `installation_id`; clients cannot choose or override the installation identity.
- Provision the MTA URL and credential per server installation in an operator-managed server-only file or secret facility, excluded from source control and client-downloadable files. Do not put bearer secrets in Lua, `meta.xml`, client settings, resource `<file>` entries, URL query strings, or synchronized element data. Rotate/revoke credentials independently per installation. MTA does not supply a project-level secret manager, so the deployment guide must specify filesystem permissions and the selected storage mechanism.
- Every game account identifier is scoped to that installation. The API verifies account/link ownership on every route; possession of an account ID or challenge ID alone grants no authority.
- Include `X-Request-ID` on every request. State-changing requests also include `Idempotency-Key`. Repeating a key with the same operation returns the original result; reusing it with a different body returns `idempotency_conflict`.
- Discord bot/OAuth credentials and the configured guild/role mapping live only in the API deployment secret/config store. The MTA credential is never used by a browser. Future browser sessions use separate short-lived, scoped credentials and CSRF protection.
- Never accept Discord role IDs or a claimed Discord user ID from an MTA client. Never return raw roles, bot/OAuth credentials, or reusable secrets to MTA or a game client.

## Link challenge lifecycle

1. A logged-in player explicitly requests a link code. The MTA server verifies the player session and obtains the account ID from server-side state.
2. MTA calls `POST /api/v1/game/link-challenges`. The API creates a cryptographically random code with at least 128 bits of entropy, stores only a hash, invalidates any earlier pending challenge for that account, and returns a short expiry (10 minutes maximum). The player redeems the code through the operator's bot interaction; no website is required.
3. The trusted bot/service verifies Discord identity and membership in the API-configured guild, then redeems the code through `POST /api/v1/discord/redeem`. Redemption atomically consumes the code and creates the link. A code is single-use and cannot bind a different Discord identity on retry.
4. MTA polls the authenticated challenge status route until `redeemed`, `expired`, or `cancelled`. Polling is rate-limited and bounded by `expires_at`. On redemption, MTA may refresh grants separately.
5. A Discord identity may link to at most one account per installation; an account may link to at most one Discord identity. Database uniqueness constraints enforce both rules. A conflict never silently replaces an existing link.

Challenge codes, challenge IDs, and Discord IDs are private server data. Store only a hash of the redeemable code. Apply per-installation, per-account, and per-Discord-user rate limits to creation, polling, and redemption. Audit link, unlink, recovery, and conflict outcomes without logging codes or credentials.

## Registration and login challenge lifecycle

1. MTA creates a random challenge bound to the current connection and installation. The challenge contains no client-supplied account ID or Discord identity.
2. The player opens the authorization URL in a normal browser, authenticates with Discord, and confirms the one-time code. The identity service enforces OAuth state, callback, rate limits, and Discord membership policy.
3. For an existing identity link, the API resolves the linked game account. For first-time registration, it provisions a new account only after consent, uniqueness, and operator policy checks.
4. The API issues a short-lived, one-use ticket bound to the challenge. MTA redeems it server-to-server, then runs account status, ban, registration, and character-selection checks.
5. Each active MTA session has a server-held session ID/version and expiry. MTA checks a bounded session-status/revocation feed. When the API reports authorization revoked, MTA clears grants and terminates that session. The maximum propagation delay and outage lease policy must be explicit and tested.

New account login and legacy-account linking are distinct flows: new accounts are created after Discord verification; legacy account linking requires proof of control before the immutable Discord ID is attached.

## v1 routes

| Method and path | Caller | Contract |
|---|---|---|
| `POST /api/v1/game/login-challenges` | Authenticated MTA installation | Creates a challenge bound to the current connection/installation. No account or Discord ID is accepted from the client. Returns an opaque challenge ID, short-lived one-time code, authorization URL, expiry, and poll interval. |
| `GET /api/v1/game/login-challenges/{challenge_id}` | Authenticated MTA installation | Returns `pending|approved|expired|revoked`, expiry, and an opaque ticket reference only after Discord authorization and account resolution/provisioning. Challenge ownership is installation-bound. |
| `POST /api/v1/game/login-challenges/{challenge_id}/redeem` | Authenticated MTA installation | Atomically returns and consumes a one-use, short-lived login ticket after verifying the challenge was approved and remains bound to this connection. |
| `POST /api/v1/game/link-challenges` | Authenticated MTA | Body: `{ "account_id": 123 }`. Response: `{ "challenge_id": "opaque-id", "code": "one-time-code", "redeem_via": "bot", "expires_at": "RFC3339", "poll_after_seconds": 3 }`. Code is shown only to the authenticated player by MTA. |
| `POST /api/v1/discord/redeem` | Trusted bot/service | Body: `{ "code": "one-time-code" }`. Discord user identity comes from the authenticated Discord interaction, not the request body. Response: `{ "status": "redeemed" }`. |
| `GET /api/v1/game/link-challenges/{challenge_id}` | Authenticated MTA | Response: `{ "status": "pending|redeemed|expired|cancelled", "expires_at": "RFC3339", "discord_user_id": "immutable-id-or-null" }`. The ID is opaque and status is visible only to its owning installation and account. |
| `DELETE /api/v1/game/link-challenges/{challenge_id}` | Authenticated MTA | Cancels an unredeemed challenge owned by this installation. Idempotent for already-cancelled or expired challenges; cannot undo a redeemed link. |
| `POST /api/v1/game/accounts/{account_id}/unlink` | Authenticated MTA | MTA calls only after verifying the logged-in account owner explicitly confirmed in-game. Body: `{ "confirmation": true }`. Response: `{ "status": "unlinked", "policy_revision": "..." }`. Idempotent when already unlinked. |
| `POST /api/v1/game/accounts/{account_id}/grants:refresh` | Authenticated MTA | Body: `{}`. Resolves current service-side guild membership and role mapping; never accepts a role list. Returns the grant shape below. |
| `POST /api/v1/game/sessions/{session_id}/heartbeat` | Authenticated MTA installation | Renews a bounded session lease and returns `active|revoked|expired`, session version, and next check interval. If Discord authorization was revoked, MTA clears grants and disconnects the player. |
| `POST /api/v1/game/accounts/{account_id}/sessions:revoke` | Trusted identity service | Marks all or selected sessions revoked after unlink, account authorization loss, or an explicit operator security action. MTA observes revocation through the session heartbeat/feed within the documented bound. |
| `GET /api/v1/health` | Operator monitor | Returns liveness/readiness only; no settings, secrets, or user records. |

Unlink requires an authenticated in-game account session and explicit confirmation. MTA clears that session's cached grants immediately when the player confirms, before the request; if the API is unavailable, keep those grants cleared and retry the idempotent unlink request with its original idempotency key. If Discord access is lost, recovery is an operator-mediated, step-up-authenticated action with audit logging and conflict checks. Recovery must not allow a Discord identity to be attached to multiple accounts.

## Grant response and freshness

```json
{
  "account_id": 123,
  "linked": true,
  "discord_user_id": "immutable-id",
  "capabilities": ["moderation.use", "gamemaster.events"],
  "donor_tier": "supporter.level_1",
  "policy_revision": "7",
  "issued_at": "RFC3339",
  "expires_at": "RFC3339"
}
```

Use only named, configured capabilities and a separate `donor_tier` (`null`, `supporter.level_1`, or `supporter.level_2`). Example initial capabilities may cover moderation, GameMaster event operations, or faction application review. Donor/supporter tiers never imply staff, GameMaster, faction rank, duty, or MTA ACL authority. Return no role IDs or role names.

Grant lifetime is at most 10 minutes. MTA may use a cached grant only until its `expires_at`; refresh asynchronously on login or near expiry. High-impact actions require a fresh grant within that same TTL. Once expired, API-derived sensitive actions fail closed until a successful refresh. New registration/login fails closed during API outages; the process can still boot and existing sessions remain valid only until their bounded session lease expires. Unlink clears local grants and revokes affected sessions; confirmed account authorization revocation disconnects the linked session when observed, within the documented heartbeat/feed bound. Role removal revokes mapped capabilities promptly; whether it also ends the session is an explicit operator policy.

## Errors

All errors use a stable envelope and include the request ID:

```json
{
  "error": {
    "code": "challenge_expired",
    "message": "The link challenge has expired.",
    "retryable": false
  },
  "request_id": "..."
}
```

Minimum v1 codes: `invalid_request`, `unauthorized_installation`, `account_not_found`, `challenge_not_found`, `challenge_expired`, `challenge_used`, `link_conflict`, `idempotency_conflict`, `rate_limited`, `discord_unavailable`, and `temporarily_unavailable`. Use appropriate HTTP status codes. Retry only retryable network/5xx/429 failures with bounded backoff; never retry a non-idempotent action without its original idempotency key. Messages must not expose credentials, raw role data, or provider internals.

## MTA asynchronous request requirements

- Use server-side `fetchRemote` callbacks. Never wait in join, login, or gameplay handlers.
- Set explicit `connectionAttempts` (1 or 2), `connectTimeout` (for example 3000 ms), a bounded in-resource concurrency limit, rate limits, and bounded retry/backoff. Do not use an unbounded request queue.
- MTA serializes requests sharing a `queueName`; separate bounded queues for link polling and grant refresh where needed to avoid one flow delaying the other.
- Use HTTPS, disable redirects for authenticated API calls (`maxRedirects = 0` where supported), and handle transport failures—including DNS, certificate, and disallowed-destination errors—as an identity-service outage. Such failure must not prevent process boot, but new production registration/login fails closed and existing sessions are bounded by their lease. `fetchRemote` exposes no documented TLS-verification toggle; validate certificate-chain behavior, CA availability, HTTPS options, redirect behavior, and the target server build before release. Restrict outbound network access to the configured API host where the operator's firewall permits.
- Declare the narrow `function.fetchRemote` right in the adapter resource's `<aclrequest>` and require an operator to approve that resource-specific request. Do not grant the adapter `Admin`, `general.ModifyOtherObjects`, or a broad HTTP export. The `<export http="true">` attribute enables inbound HTTP calls to an MTA export; it is not needed for outbound API requests.
- Pass callback arguments for `request_id`, `account_id`, player element, operation, and a server-maintained session generation. In the callback, verify the player element still exists, remains logged in to the same account, and the pending request/session generation still matches. Ignore stale callbacks after disconnect, relogin, unlink, a newer refresh, or adapter resource restart.
- Track each returned remote-request handle. On resource stop/restart, invalidate the resource generation, cancel outstanding requests with `abortRemoteRequest` where possible, and reject any callback that still arrives with an old generation. `fetchRemote` cannot be launched from inside another `fetchRemote` callback; defer follow-on calls such as status-poll → grant-refresh through a timer/event after the callback returns.
- Keep new grants in server-side state; do not place API-derived authority in client-synchronized element data. Log request ID, outcome, latency, and grant expiry only; never log codes or credentials.

## Optional provider adapters

Media evidence and optional assets may use an adapter such as `MediaStorageProvider.upload`, `get`, and `delete`, with a local/no-op default. FiveManage is a possible future provider, not an enabled dependency. Keep credentials server-side; if clients upload directly, mint short-lived one-time upload URLs. Validate provider ID/URL, host, content type, size, retention, and deletion behavior. Provider outage or missing configuration must not block ordinary gameplay or moderation; evidence-dependent actions should report upload failure.

Log search is a separate operator observability adapter. Local logs remain the default. Provide structured secret-safe logs and, if claiming first-class Grafana support, an example Alloy → Loki → Grafana collector configuration. Backend URL, credentials, labels, retention, and enable/disable settings belong in operator configuration.

## Minimal first slice

Implement the self-hostable API, per-install authentication, challenge create/redeem/status, unlink, and grant refresh. Add one MTA server adapter for requesting a challenge, polling status, and refreshing grants asynchronously. Keep linking disabled by default, role IDs blank, and existing legacy permission checks unmigrated. Do not make API health or network availability a resource-start or local-login dependency. Confirm `function.fetchRemote` ACL approval, supported request options/callback behavior, HTTPS certificate handling, redirect policy, and stop/restart cancellation on the selected MTA server release before deployment.

## References

- MTA [`fetchRemote`](https://wiki.multitheftauto.com/wiki/FetchRemote): asynchronous callbacks, serial per-queue processing, connection attempts/timeouts, and callback arguments.
- MTA [`meta.xml`](https://wiki.multitheftauto.com/wiki/Meta.xml) and [resource ACL requests](https://wiki.multitheftauto.com/wiki/Meta.xml#aclrequest); `http="true"` on an export controls inbound HTTP calls, not outbound `fetchRemote`.
- MTA [`abortRemoteRequest`](https://wiki.multitheftauto.com/wiki/AbortRemoteRequest) for resource-stop cancellation where supported.
- MTA [`meta.xml`](https://wiki.multitheftauto.com/wiki/Meta.xml) and [script security](https://wiki.multitheftauto.com/wiki/Script_security).
- [FiveManage storage](https://fivemanage.com/storage) and [pricing](https://fivemanage.com/pricing); recheck provider terms, regions, quotas, retention, endpoint format, and pricing before implementation.
