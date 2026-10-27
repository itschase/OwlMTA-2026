# `death`

## Status and evidence

- Resource path: `mods/deathmatch/resources/death`.
- Tree/startup state: active and enabled in the tracked startup snapshot; live deployment state unverified.
- Source review: all manifest-loaded scripts and direct CK/cemetery event callers reviewed.
- Runtime: unverified. The MTA server has not been started for this review.
- Individual GitHub Discussion: pending publication using the standard title `Script Resource: death`.
- Implementation tracking: [Issue #345](https://github.com/itschase/OwlMTA-2026/issues/345); broader event security is tracked by [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1).

## What it does

`death` is a small client/server resource with two player-facing features: death/character-kill presentation and a cemetery memorial display. It does not decide whether a character should be killed or whether the player is authorized to perform a CK. Those decisions live in other resources; `death` displays effects or the result of a server-authorized decision.

## Player use

- On player death, the client plays `deathFX/wasted.mp3` and slows local game speed. Player spawn stops the sound and restores game speed.
- When the server tells a player their character was CK-ed, the client requests a character-list refresh, logs out after a short delay, displays the permanent-death explanation, and returns the player to character selection.
- At the cemetery, holding Left Alt displays memorial plates for the configured tomb positions that have loaded character records. Plates show character name, date of birth, death date, and a default “Rest In Peace” inscription. The client refreshes its public cemetery cache on resource start and every 30 minutes.

The memorial cache includes character names and birth/death dates for CK-ed characters with a recorded death date. The source treats these as public cemetery information; privacy policy and retention should be reviewed before exposing additional character fields.

## Staff and operator use

This resource registers no commands. Character-kill authority, staff command checks, and burial/restore commands are implemented by `admin-system/Player/s_ck.lua` and `selfck-system/s_selfck.lua`. Audit those controls where they are defined; do not assign the `death` resource a separate permission policy for visual effects.

Future Discord authorization belongs at the staff action boundary in the CK command owner, through the Owl host authorization facade and a named global staff capability. It must not be implemented as a client-side display check or replace local CK target/state validation. Ordinary death effects and reading public cemetery plates require no Discord role. Donor/supporter tier must not imply CK authority.

## Technical map and connections

| File | Runtime | Responsibility |
|---|---|---|
| [`meta.xml`](../../mods/deathmatch/resources/death/meta.xml) | Manifest | Loads cemetery, shared tomb-position data, and death effects; distributes font and audio assets. |
| [`graveyard/graveyard_s.lua`](../../mods/deathmatch/resources/death/graveyard/graveyard_s.lua) | Server | Queries CK-ed character names and dates into an in-memory cemetery cache and answers client cache requests. |
| [`graveyard/graveyard_c.lua`](../../mods/deathmatch/resources/death/graveyard/graveyard_c.lua) | Client | Requests and renders cemetery plates while Left Alt is held. |
| [`graveyard/tombs_g.lua`](../../mods/deathmatch/resources/death/graveyard/tombs_g.lua) | Shared data loaded on server and client | Provides the ordered tomb-position list used to map the newest CK records to memorial locations. |
| [`deathFX/deathFX_c.lua`](../../mods/deathmatch/resources/death/deathFX/deathFX_c.lua) | Client | Plays death audio, slows/restores local game speed, and displays the CK result dialog. |

Important cross-resource paths:

- `admin-system/Player/s_ck.lua` and `selfck-system/s_selfck.lua` trigger `showCkWindow` after a CK decision.
- `account/s_characters.lua` handles the `updateCharacters` request and character-selection data; the CK dialog invokes this before returning to character selection.
- `characters.cked` distinguishes normal/CK-ed/buried character states; `characters.death_date`, `date_of_birth`, and `charactername` supply the cemetery cache.
- `resources` supplies shared fonts/window assets; the `death` resource distributes its own tombstone font and audio files.

## Events and security boundary

- Client request: `sendburiedCharactersToClient` asks the server for the cached public memorial list.
- Server response: `receiveBuriedCharactersFromServer` is targeted at the requesting local player.
- CK presentation event: `showCkWindow` is client-registered for `localPlayer`; its server-side callers are in the CK command resources.
- MTA's [script security guide](https://wiki.multitheftauto.com/wiki/Script_security) and [`triggerServerEvent`](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) warn that client-supplied event source/arguments can be forged; server handlers should bind the caller to MTA's server-side `client` and independently validate arguments.

The cemetery responder previously reassigned `client` from the remote event's `source`. It now validates the authenticated player and requires the event source to match that caller before sending the list to that caller. This is fixed in source only; [Issue #345](https://github.com/itschase/OwlMTA-2026/issues/345) remains open for two-client runtime verification and request-rate review. The returned cemetery fields are public, so the observed impact was recipient spoofing/unwanted response delivery rather than disclosure of private account or staff data.

## Source-confirmed notes and follow-up

- `graveyard_s.lua` refreshes its in-memory SQL result every five hours; the client requests it on resource start and every thirty minutes. These intervals are independent and should be documented/tuned as operator settings if the resource grows.
- The server cache selects only `charactername`, formatted `death_date`, and formatted `date_of_birth`; it limits rows to the configured number of tomb positions. The client renders no more rows than there are configured tombs.
- The shared tomb-position data currently contains only coordinates. The client has a fallback for a `tomb_text` field, but the server query does not populate one, so the displayed inscription is the default.
- `getMonthShortName` in the server file contains misspelled variable references for months 2–12. It has no references elsewhere in the audited resource tree and appears unused; remove or repair it only when a caller is introduced or a targeted cleanup is planned.
- The remote cemetery request returns an in-memory public list, not a fresh SQL query per request. Add a measured per-player interval if request volume becomes material; do not create noisy per-request logs for normal public reads.

## Validation plan (not yet run)

After the static safe-start gate, verify death audio/game-speed restoration, CK dialog and logout/character-selection flow, CK and burial state transitions, cemetery cache query/restart behavior, position-to-record ordering, valid and forged event sources, correct response recipient, two-client isolation, repeated requests, and failure behavior when the database is unavailable. Keep source inspection and disposable runtime results reported separately.
