# MTA server event and outbound request notes

Last reviewed against the official Multi Theft Auto wiki: 2026-10-26. This is a practical project reference, not a substitute for the current API page or a runtime compatibility check against the selected server build.

## Remote client events

The server-side `client` variable identifies the player that triggered a remote event. Client-supplied event `source` and all ordinary arguments are untrusted, including elements, account identifiers, inventory IDs, money amounts, destination coordinates, role claims, and state flags. A valid caller identity does not make the supplied target or operation valid: derive targets and mutable state from server-owned account/session/domain records, then validate ownership, permission, duty, proximity, dimension/interior, amount, lifecycle state, and replay/rate bounds as the operation requires.

Register client-callable events only when necessary. `addEvent(name, false)` disables remote triggering. Keep server-internal calls on local functions or non-remote events; do not let an internal caller's event `source` masquerade as an authenticated player. If a handler must serve both remote and internal paths, route them through distinct wrappers and pass an explicit server-owned actor context only from the internal wrapper.

Official references:

- [Script security](https://wiki.multitheftauto.com/wiki/Script_security) — client trust boundaries, server-only events, parameter validation, and element-data cautions.
- [triggerServerEvent](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) — event source is a client argument; use server-side `client` for remote requester identity.
- [Event](https://wiki.multitheftauto.com/wiki/Event) — event variables, including `client`, `source`, `this`, and event propagation.
- [addEvent](https://wiki.multitheftauto.com/wiki/AddEvent) — whether an event can be triggered remotely.

## Element data and client state

Synchronized element data is visible to clients and can be abused when server handlers treat it as authority. Keep permissions, balances, ownership, inventory settlement, session generations, and Discord-derived grants in server-side state or durable records. Client-side element data may support presentation, but the server must re-derive sensitive state. Where element data is needed for presentation, evaluate whether synchronization is necessary and use suitable sync/subscriber options; never treat that as a replacement for authorization checks.

## Outbound HTTP with `fetchRemote`

`fetchRemote` is asynchronous and returns through a callback. Do not block join, login, or gameplay handlers awaiting a response. Bound concurrency, connection attempts, timeout, queueing, payload/response size, and retry policy. Requests sharing one queue name are processed serially, one at a time; an overloaded shared queue can delay independent flows. The documented `fetchRemote` implementation cannot be called from inside its own callback, so defer follow-up work to a timer/event after that callback returns.

Track the returned request handle where available. On resource stop or identity/session change, invalidate the request generation, abort requests where possible, and reject callbacks whose player, account, operation, or generation is stale. Do not extend an expired authorization lease during retries. Store API credentials server-side and send them in headers; never put secrets in a query string, client Lua, downloadable files, or synchronized element data.

Official references:

- [fetchRemote](https://wiki.multitheftauto.com/wiki/FetchRemote) — callback behavior, queue ordering, options, timeout/retry defaults, redirect limit, and callback restrictions.
- [abortRemoteRequest](https://wiki.multitheftauto.com/wiki/AbortRemoteRequest) — request cancellation.
- [getRemoteRequestInfo](https://wiki.multitheftauto.com/wiki/GetRemoteRequestInfo) and [getRemoteRequests](https://wiki.multitheftauto.com/wiki/GetRemoteRequests) — request inspection.

## How this maps to OwlMTA

These rules inform the resource audit playbook and the proposed [API contract](../architecture/API_CONTRACT.md). The identity-service integration is optional at process boot, but Discord-first production registration/login and API-derived sensitive capabilities remain fail-closed at their defined boundaries. An API grant supplements existing game-domain checks; it never replaces account ownership, faction membership/rank, duty, item, money, or target-state validation.

During static audits, classify each endpoint as one of:

1. **Remote player request:** use `client`; derive account/character from the authenticated server session.
2. **Server-internal operation:** call a local service function or non-remote event with explicit trusted context.
3. **Client presentation request:** may select UI/presentation behavior only; never mutate durable or cross-player state without a separate authorized server operation.
4. **Outbound service callback:** correlate by request ID, operation, and session generation; verify the session is still current before applying results.

All conclusions in resource dossiers remain source-confirmed until validated against a disposable MTA runtime. API availability, queue behavior, TLS/certificate behavior, ACL approval, callback cancellation, event replay, and restart recovery all require targeted runtime evidence before release.
