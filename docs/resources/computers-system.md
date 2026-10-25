# `computers-system`

## Status

- Active resource under `mods/deathmatch/resources/computers-system`; listed for startup in the tracked backup server configuration.
- Full manifest, player-caller, persistence, and cross-resource review completed from source.
- Live startup and all runtime behavior remain unverified; no MTA server/database was started.
- [Discussion #283](https://github.com/itschase/OwlMTA-2026/discussions/283).

## What players use

The resource creates an in-game computer desktop with a CEF browser, a separate email application, and local service pages. Players can open it from supported computer world objects, a computer item, and selected object-interaction entries. `/ctl+alt+del` closes a stuck desktop/browser UI.

The desktop includes local pages for MDC, banking, aviation flight planning/airline management, and legacy InvestPlace content, plus external links such as Google, Linkbook, YouTube, and the old `findbook.owlgaming.net` service. The browser can also open arbitrary HTTP/HTTPS destinations after the client-side domain consent step. External web content runs in the player client; this is not a server-side API or account-authentication boundary.

The email app supports registering a separate mailbox, logging in, reading inbox/outbox, sending messages, and deleting mailbox copies. The IPPC pages support pilot and airline data, NOTAMs, rosters, and flight plans. Some page controls are hidden by client-side role checks; the server must independently authorize each remote operation.

## Staff and operator use

There are no dedicated staff/operator commands in the manifest-loaded code. Staff-facing MDC presentation is delegated to the owning `mdc` resource; banking launch delegates to `bank`. The computer surface should not become a parallel permission system.

Operators need the `emailaccounts`, `emails`, `ippc_airlines`, `ippc_airline_pilots`, `ippc_flights`, and `pilot_notams` tables from the legacy `mta` schema, plus the database, faction, cache, MDC, bank, phone, item, object-interaction, airport-gate, and date/time dependencies. The email and aviation tables use legacy MyISAM/text structures without the uniqueness and foreign-key guarantees expected from modern transactional flows.

## Technical map

- Manifest: [`meta.xml`](../../mods/deathmatch/resources/computers-system/meta.xml)
- Shared page/domain registry: [`g_domains.lua`](../../mods/deathmatch/resources/computers-system/g_domains.lua)
- Desktop/browser client: [`c_computers.lua`](../../mods/deathmatch/resources/computers-system/c_computers.lua) and [`c_browser.lua`](../../mods/deathmatch/resources/computers-system/c_browser.lua)
- Desktop world-object routes: [`c_internetcafe.lua`](../../mods/deathmatch/resources/computers-system/c_internetcafe.lua) and [`s_internetcafe.lua`](../../mods/deathmatch/resources/computers-system/s_internetcafe.lua)
- Email client/server: [`c_mail.lua`](../../mods/deathmatch/resources/computers-system/c_mail.lua) and [`s_mail.lua`](../../mods/deathmatch/resources/computers-system/s_mail.lua)
- IPPC client/server: [`websites/ippc.lua`](../../mods/deathmatch/resources/computers-system/websites/ippc.lua) and [`websites/ippc_s.lua`](../../mods/deathmatch/resources/computers-system/websites/ippc_s.lua)
- Banking launcher: [`websites/banking.lua`](../../mods/deathmatch/resources/computers-system/websites/banking.lua)
- Schema: [`mta.sql`](../../mods/deathmatch/data/mta.sql)

Client exports are `openBrowser` and `closeBrowser`. Server events cover computer interaction, email registration/login/read/send/delete, and IPPC sessions, NOTAMs, airline administration, pilot rosters, leadership, and flight-plan submission. No server HTTP API is provided by this resource.

## Integrations and authority boundaries

- The desktop is presented through computer objects/items and object interaction. Client-side distance/model checks only control presentation; they are not server authorization.
- The computer MDC page dispatches to MDC login UI. MDC access decisions belong to `mdc`, not this presentation layer.
- The online banking launcher derives the remote actor from MTA `client` and only includes factions for which the actor has `manage_finance`; transfer authorization and settlement belong to `bank`.
- Phone uses the exported browser/UI path, but phone-number/call authority remains in `phone`.
- Email authentication currently checks a supplied account/password with unsalted MD5, then later inbox/outbox/send/delete calls trust client-supplied account names and row IDs without a server-owned authenticated mailbox session. [Issue #273](https://github.com/itschase/OwlMTA-2026/issues/273) tracks ownership/session enforcement; [#274](https://github.com/itschase/OwlMTA-2026/issues/274) tracks credential migration and rate limits.
- IPPC server events do not enforce FAA/airline authority for NOTAM writes, airline changes, roster/leader changes, or flight-plan creation, while read APIs return rosters and flight data without an explicit scope policy. [Issue #275](https://github.com/itschase/OwlMTA-2026/issues/275).
- Email/IPPC code often reports success or mutates in-memory caches without confirming durable database success; the legacy tables are not transaction-ready. [Issue #276](https://github.com/itschase/OwlMTA-2026/issues/276) owns operation ordering/cache reconciliation; schema engine and transaction migration remain under [Issue #6](https://github.com/itschase/OwlMTA-2026/issues/6).
- The IPPC future-flight classifier returns true for timestamps at or before now. [Issue #277](https://github.com/itschase/OwlMTA-2026/issues/277).
- The old upstream Findbook domain is part of the broader hard-coded website/portability inventory in [Issue #44](https://github.com/itschase/OwlMTA-2026/issues/44).

## Modernization direction

Treat the desktop as a presentation shell over independently authorized game services. Replace mailbox credentials with a server-owned identity/session path, or migrate the separate mailbox secret safely; scope every read and mutation to that session. Model aviation permissions as named capabilities checked by the server for each airline, pilot, and regulator scope. Derive aircraft, character, payment, and actor data from authoritative server state. Have databases report success before updating UI/cache, and reconcile caches after restart. Replace dynamic local-page dispatch with an explicit page registry, document external browser privacy/consent behavior, and retire dead upstream links. Keep CEF optional and independent from the future Discord OAuth/API trust boundary.

## Runtime verification still required

Use a disposable environment after safe-start readiness. Verify: computer item/world/object entry and invalid distances; email registration, login, session expiry, mailbox isolation, cross-account row IDs, credential migration, and database failures; FAA/airline member/leader/civilian event boundaries; airline/flight cache updates after database errors/restart; past/current/future and timezone schedule boundaries; banking/MDC delegation; external URL consent/redirect/HTTP/TLS failures; CEF unavailable; and dependency stop/restart. These findings are source-confirmed only; no exploit or runtime behavior was tested.
