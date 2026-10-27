# `prison-system`

## Evidence status

- Source state: reviewed from the current checkout, including the `s_prison.lua` hardening committed in `3d4fcc4`; runtime verification remains open.
- Loaded surface: `meta.xml` loads `s_gates.lua`, `c_gates.lua`, `c_prison.lua`, `s_prison.lua`, and shared `g_prison.lua`; it exports server function `checkForRelease`.
- Runtime state: unverified. MTA was not started and no tests were run.
- Startup state: any tracked startup configuration is static evidence only, not proof that the resource is live.

## Purpose and boundaries

`prison-system` manages criminal custody: the prisoner roster, booking and sentence changes, configured processing zones and cells, online/offline sentence clocks, fines, prison appearance, gates, intercom messages, and release. It does not own court findings, evidence, or a general staff-sanction model. Administrator jail and the separate PD jail path remain distinct systems.

The client GUI is only an input and display surface. The server owns actor identity, authority decisions, prisoner identity, authoritative record lookup, sentence calculations, persistence, and custody state changes. Client notifications and GUI refresh events do not confer authority.

## Player workflow

1. A booked player receives live custody data (`jailed`, `jail_time`, `jail_time_online`, `jail:id`, and `jail:cell`), is moved to the server-selected configured cell, and receives the prison appearance.
2. `/jailtime` displays the remaining offline and online portions of the sentence. If both have expired, it uses the trusted internal release path, clears custody state, restores appearance, and moves the player to the configured release location unless administrator jail still applies.
3. Login and character-selection flows call the exported `checkForRelease(player, firstLogin)` function. It either restores custody from the persisted record or performs an expired-sentence release.
4. A five-minute server sweep also releases online prisoners whose offline and online sentence portions have both expired.

There is no separate loaded player GUI command for sentence status: `/jailtime` is the loaded interface. Login reconciliation and timed release are non-command alternatives invoked by server code.

## Law and staff workflow

### Open and review the roster

- `/arrest` calls server handler `startGUI`.
- The remotely registered `startPrisonGUI` event calls the same handler; when invoked by a client, `startGUI` binds the player to MTA `client` and can open only that caller's UI.
- The server sends the current in-memory roster through `PrisonGUI`. This event is a view response, not mutation authority.

### Book a prisoner

- The GUI calls the server `addPrisoner` event handler.
- For an online booking, the server requires a logged-in player element, derives the character name and ID from that element, rechecks the actor, requires the processing area, validates cell, integer sentence, charges, fine, and configured hour limit, then writes custody state.
- For an offline booking, the server normalizes the submitted name and resolves it against `characters`; it rejects a matching online character. Offline booking is disabled by the current `pd_offline_jail = false` configuration for non-admin law actors.
- Successful online booking can add an MDC crime, issue the fine, remove restraints, activate custody, and notify relevant law factions.

### Change a sentence

- The GUI calls the server `changePrisoner` event handler.
- The server resolves the roster row from the jail record ID, requires the submitted name to match that row, independently resolves whether the prisoner is online, rechecks actor authority and proximity, validates the replacement cell, sentence, and charges, and updates persistence and live custody.

### Release a prisoner

- The GUI calls the server `removePrisoner` event handler. Its client-supplied `fromGUI` value is not authority.
- The server resolves the roster record, rechecks actor authority and online proximity, removes the database and in-memory record through local `removePrisonRecord`, clears `characters.pdjail`, and cleans up the online prisoner's live state.
- Expiry paths call `removePrisonRecord` directly rather than routing trusted server work through the remotely callable handler.

### Prison intercom and gates

- `/intercom [message]` is available only to faction 1 members within configured prison interiors/dimensions or within 100 metres of the courtyard speaker point. There is no loaded GUI alternative for composing intercom messages.
- The prison GUI calls `triggerAGate` and `triggerAllGates`. These gate handlers currently accept client events without server-side actor, duty, or location authorization; the client-side dimension check is not authoritative.

## Commands and non-command entry points

| Interface | Loaded handler | Non-command alternative |
| --- | --- | --- |
| `/arrest` | `startGUI` in `s_prison.lua` | Remote `startPrisonGUI` event calls the same handler; no caller exists inside this resource. |
| `/jailtime` | Anonymous command handler in `s_prison.lua` | `checkForRelease` export, login/character flow, and periodic server sweep reconcile or release custody. |
| `/intercom` | `processSpeakerMessage` in `s_prison.lua` | None loaded. |
| Prisoner add/change/remove | `addPrisoner`, `changePrisoner`, and `removePrisoner` server event handlers | Add/change have no internal callers in this resource; automatic release uses local `removePrisonRecord`. |
| Gate controls | `triggerAGate` and `triggerAllGates` in `s_gates.lua` | Prison GUI buttons emit the corresponding server events. |

## Permission boundaries

- Trial administrators are the existing global staff authority for prisoner mutations.
- Non-admin online add/change/release requires a logged-in, on-duty law actor: faction type 2 or faction 81.
- Online change/release also requires the actor to be within 30 metres and in the same dimension as the prisoner. Trial administrators and members of configured faction `pd_update_access` retain the existing proximity bypass.
- Offline add requires `pd_offline_jail = true` plus on-duty law authority; the tracked configuration sets it to `false`.
- Offline change/release requires an on-duty member of configured faction `pd_update_access` (currently faction 59) or a trial administrator.
- `/intercom` retains its local faction 1 and location policy.
- No donor or supporter level grants prison authority.
- Gate event authorization is unresolved and must be enforced server-side before those controls can be treated as protected.

The roster-open expression is broader than the mutation policy because of its current boolean grouping: faction-type-2 members can reach the view without the duty condition that applies to faction 81. Mutation handlers still perform their own stricter checks. Whether off-duty roster access is intended remains a policy decision.

## Data ownership and side effects

| Data or effect | Authoritative owner in this resource |
| --- | --- |
| Jail record ID, character ID/name, sentence timestamps, online minutes, charges, cell, fine, updater | Server-loaded `jailed` rows and server database queries; the in-memory `t` table mirrors them. |
| Character existence and online state | Server `characters` lookup plus logged-in player `dbid`/name resolution. |
| Actor identity | MTA `client` for remote events; command player for commands; explicit player argument only for trusted exported/internal flows. |
| Law/admin authority and duty | Server exports from `integration` and `factions`, plus server element duty state. |
| Valid cells, processing zones, release positions, ratios, and sentence limit | Shared server-loaded configuration in `g_prison.lua`. |
| Custody persistence | `jailed` and `characters.pdjail`; online time is flushed on quit/resource stop and reconciled on login/startup. |
| Money and audit side effects | Character bank balance, faction/government balances, `wiretransfers`, MDC crime records, and log exports. |
| Live custody | Server player element data, position/interior/dimension, timer, restraints/items, weapons, and appearance fields. |

Booking and release still span several non-transactional database and world-state changes. A partial dependency or query failure can leave those stores inconsistent; no operation ID or reconciliation ledger is present.

## Discord capability proposal

Discord-derived authorization should be optional and server-side. It must resolve a linked game account to short-lived named capabilities; it must not send Discord role IDs to MTA, accept capability names from the client, or translate donor/supporter status into authority.

Keep ordinary custody policy local: on-duty law faction checks, configured offline-manager faction membership, processing zones, proximity, record identity, and field validation remain mandatory and are not replaced by Discord. A Discord capability is appropriate only as an alternative global-staff grant where the code currently recognizes a trial administrator.

Proposed checks at the exact server entry points:

| Server handler | Proposed global-staff capability | Required local behavior retained |
| --- | --- | --- |
| `startGUI` (`startPrisonGUI` and `/arrest`) | `prison.staff.view` | Bind remote actor to `client`; roster privacy policy remains server-owned. |
| `addPrisoner` event handler | `prison.staff.book` | Server-resolve target; validate cell/sentence/charges/fine; preserve processing-zone checks. |
| `changePrisoner` event handler | `prison.staff.update` | Server-resolve jail row and online target; validate fields; preserve normal law/offline-manager paths and online proximity. |
| `removePrisoner` event handler | `prison.staff.release` | Server-resolve jail row and target; preserve normal law/offline-manager paths and online proximity. |

The capability decision should be made inside `getPrisonActorAccess(actor)` or an adjacent server-only helper using the bound actor's linked account. Each mutation handler must still perform its target, state, location, and input checks after that decision. `removePrisonRecord`, `checkForRelease`, `/jailtime`, and the timer sweep are trusted lifecycle paths and should not require Discord capability checks. `/intercom` remains faction/location-based. Gate events need their own local server authorization design; they should not inherit global prison-staff capabilities by default.

## Current source findings

- The committed source hardening binds remote mutations to MTA `client`, re-resolves targets and records, validates server-owned fields, enforces existing law/admin/offline-manager policy, and separates automatic release from the remote release handler. Runtime verification remains open.
- Offline-manager membership now uses the faction export rather than treating faction element data as a scalar ID.
- The booking restraint return and `/jailtime` timer lookup now use the correct acting/player variables.
- Gate events remain remotely callable without authoritative server permission or location checks.
- Roster visibility duty policy remains ambiguous and broader than mutation policy.
- Duplicate detection returns after the first roster row, and some login/timed release paths still assume configured cell data exists.
- Fine debit, faction distribution, wire transfer, MDC logging, custody persistence, appearance, and item changes are not atomic.

All findings above are static source observations. Database schema behavior, dependency availability, intended off-duty policy, Discord integration, and live MTA behavior remain unverified.
