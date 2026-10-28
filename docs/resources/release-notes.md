# `release-notes`

## Status

- Tree state: active resource; manifest, client/server scripts, startup snapshot, and callers reviewed.
- Startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; snapshot only.
- Source review: complete for the resource's data-read and display flow. There is no active player opener or operator publishing workflow in the reviewed tree.
- GitHub tracking: [Issue #484](https://github.com/itschase/OwlMTA-2026/issues/484) tracks the missing in-game entry point; [Issue #485](https://github.com/itschase/OwlMTA-2026/issues/485) tracks missing schema and operator publishing workflow. Both are assigned to [Milestone #7: Resource Audit and Security Baseline](https://github.com/itschase/OwlMTA-2026/milestone/7).
- Discussion: [Script Resource: release-notes #486](https://github.com/itschase/OwlMTA-2026/discussions/486) in `Script Resources`.
- Runtime: unverified; no MTA server/client was started.

## What it is for

`release-notes` is a small, read-only release-history viewer. The server reads up to 500 rows from `ucp_release_notes`, newest first, formats each row as a date and title, and sends the resulting text to a client that opens the panel. The client window is titled “Live Release Notes” and appends the version returned by `global:getScriptVersion()`.

This is separate from `staff_changelogs`, which records staff-rank changes for the staff manager. Do not treat those personnel records as player-facing software release notes.

## Player workflow and current gap

The client script registers `showReleases` as a handler for `debug:releases`. When invoked with no current window, it creates a read-only memo, displays a loading message, and requests the data from the server. The server returns a text block through the same event name. The panel has a Close button.

No active command, key bind, help-panel route, or other caller was found in the resource or active resource tree. The only external `triggerEvent('debug:releases', localPlayer)` reference is commented out in `account/c_main.lua`. Therefore, the source contains the display/request handlers but no active player-facing opener. This is tracked in [Issue #484](https://github.com/itschase/OwlMTA-2026/issues/484). A deployed server could have untracked scripts or customizations; that has not been checked.

The panel still includes a legacy bug-report link to `bugs.owlgaming.net`. It is presentation text only; this resource does not implement or contact that site. The project should replace that dead/legacy reference with the chosen in-game report/help workflow when the UX is established.

## Staff and operator use

The resource contains no staff command, authoring interface, or publish operation. The only declared feature is a public read of stored note titles/dates. The data appears intended to be maintained outside the game, but the current source does not identify the authoring tool or operator procedure. Issue #485 records the need for an in-repository schema/migration and a documented publishing workflow that does not require the missing UCP.

For the future, a small operator-only release-note editor could create, edit, archive, and preview notices in-game, with permission checks and an audit record. Keep publication separate from a full UCP or website; a future API could optionally publish approved notes for a companion website, but must not be required for the MTA panel.

## Data, caching, and dependencies

- Query: `SELECT title, DATE_FORMAT(FROM_UNIXTIME(date),'%b %d, %Y') AS fdate FROM ucp_release_notes ORDER BY date DESC LIMIT 500`.
- `date` is interpreted as Unix seconds using MySQL `FROM_UNIXTIME`; exact SQL column types and constraints are not declared in the checked-in schema.
- The server caches the formatted text for five minutes using `getTickCount`. It refreshes on a later request after expiry; there is no timer-driven refresh.
- The client also has `cache`, `last`, and `releases` variables, but the current implementation relies on server delivery to populate the displayed content and uses `last` to avoid repeated requests while creating the panel.
- `meta.xml` loads only `server.lua` and `client.lua`, and declares no exports. The server calls `mysql:query`, `fetch_assoc`, and `free_result`; the client calls `global:getScriptVersion` and `global:centerWindow`. The checked-in startup snapshot starts `mysql` and `global` before `release-notes`. Those startup lines are evidence of intended order in that snapshot, not runtime proof.
- Repository-wide source and schema search found no `ucp_release_notes` DDL or migration in `mods/deathmatch/data/mta.sql`, `core.sql`, or `data.sql`. A live database may still contain the table. Treat its presence as an external/unverified dependency until the schema is supplied and tested.
- The query is static and accepts no client-supplied SQL fragment. Client requests can trigger a refresh read, but the global five-minute cache bounds repeat database reads from that code path. Query failure/empty-table behavior is not surfaced to the player as a distinct error state in the source.

## Discord, API, and command modernization

There is no permission or identity decision in the current resource, and no Discord/API call. Reading public release notes must remain available to ordinary players after Discord authorization. If an in-game authoring panel is added, gate publishing with a narrowly scoped staff capability (for example, `release_notes.publish`) and log changes; do not grant it through donor/supporter tiers. Keep any future web publication as an optional client of the project's API, not as the storage authority or a required site.

## Source-confirmed issues and follow-up

- [Issue #484](https://github.com/itschase/OwlMTA-2026/issues/484): provide an active, documented in-game route to open the viewer.
- [Issue #485](https://github.com/itschase/OwlMTA-2026/issues/485): add/maintain the table schema, document the operator publishing source, and report missing-storage/query failures clearly.
- The old bug-report URL in the panel needs a project-approved replacement; this is a UX/content decision, not a working integration.
- Audit `global:getScriptVersion` semantics and startup dependency behavior against the target MTA release before treating the title as authoritative.

## Runtime verification still required

After schema and entry-point work, verify resource startup with a fresh schema, empty and populated tables, more than 500 rows, date ordering/formatting, title content, cache expiry and `getTickCount` wrap assumptions, missing-table/database outage behavior, opening/closing the panel, multiple players requesting simultaneously, resource restart, version display, and the proposed operator editor's permission/audit flow. None of this has been runtime-tested.
