# Optional integration API contract

## Purpose and boundary

The MTA gamemode remains playable with its local account system and in-game management flows. A self-hosted, optional service provides a narrow, versioned API for Discord linking, server-side role mapping, and future website clients. MTA never listens publicly for website or Discord management calls. MTA handlers remain responsible for enforcing game rules; the API supplies bounded identity and grant data, not a replacement for gameplay authorization logic.

This is the proposed v1 contract, not an implemented service. No Owl-hosted endpoint, domain, Discord guild, role ID, or secret is shipped. If the service is disabled or unavailable, local login and ordinary gameplay continue.

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

## v1 routes

| Method and path | Caller | Contract |
|---|---|---|
| `POST /api/v1/game/link-challenges` | Authenticated MTA | Body: `{ "account_id": 123 }`. Response: `{ "challenge_id": "opaque-id", "code": "one-time-code", "redeem_via": "bot", "expires_at": "RFC3339", "poll_after_seconds": 3 }`. Code is shown only to the authenticated player by MTA. |
| `POST /api/v1/discord/redeem` | Trusted bot/service | Body: `{ "code": "one-time-code" }`. Discord user identity comes from the authenticated Discord interaction, not the request body. Response: `{ "status": "redeemed" }`. |
| `GET /api/v1/game/link-challenges/{challenge_id}` | Authenticated MTA | Response: `{ "status": "pending|redeemed|expired|cancelled", "expires_at": "RFC3339", "discord_user_id": "immutable-id-or-null" }`. The ID is opaque and status is visible only to its owning installation and account. |
| `DELETE /api/v1/game/link-challenges/{challenge_id}` | Authenticated MTA | Cancels an unredeemed challenge owned by this installation. Idempotent for already-cancelled or expired challenges; cannot undo a redeemed link. |
| `POST /api/v1/game/accounts/{account_id}/unlink` | Authenticated MTA | MTA calls only after verifying the logged-in account owner explicitly confirmed in-game. Body: `{ "confirmation": true }`. Response: `{ "status": "unlinked", "policy_revision": "..." }`. Idempotent when already unlinked. |
| `POST /api/v1/game/accounts/{account_id}/grants:refresh` | Authenticated MTA | Body: `{}`. Resolves current service-side guild membership and role mapping; never accepts a role list. Returns the grant shape below. |
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

Grant lifetime is at most 10 minutes. MTA may use a cached grant only until its `expires_at`; refresh after link completion and asynchronously on login or near expiry. High-impact actions require a fresh grant within that same TTL. Once expired, API-derived sensitive actions fail closed until a successful refresh. API outage never blocks local login or ordinary gameplay. Unlink clears the local grant immediately; service-side unlink invalidates subsequent refreshes. Role removal takes effect no later than grant expiry, with earlier effect on a successful refresh.

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
- Use HTTPS, disable redirects for authenticated API calls (`maxRedirects = 0` where supported), and handle transport failures—including DNS, certificate, and disallowed-destination errors—as an optional-service outage. `fetchRemote` exposes no documented TLS-verification toggle; validate certificate-chain behavior, CA availability, HTTPS options, redirect behavior, and the target server build before release. Restrict outbound network access to the configured API host where the operator's firewall permits.
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
