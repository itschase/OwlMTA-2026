# `parachute`

## Status

- Tree state: active resource tree; manifest and all six active Lua scripts reviewed, with direct callers searched across the active resources.
- Startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; this is not proof of live configuration.
- Source state: full manifest/script and direct-caller source review. The concurrent opening-animation finding is tracked by [Issue #466](https://github.com/itschase/OwlMTA-2026/issues/466), assigned to [Milestone #7: Resource Audit and Security Baseline](https://github.com/itschase/OwlMTA-2026/milestone/7).
- Runtime state: unverified. The MTA server/client were not started.
- Discussion: [Script Resource: parachute #468](https://github.com/itschase/OwlMTA-2026/discussions/468).

## What it does

This resource provides the visible parachute and freefall experience. While a player has parachute weapon ID 46 selected in weapon slot 11 and is falling, the client simulates skydiving, lets the player steer, shows an “Open your parachute!” warning near the ground, and opens a locally created parachute when the player presses fire. The chute slows descent, turns with movement input, and has landing and water animations. Other clients create their own visual prop and replay the player's parachute/skydiving animation from synced element data.

This is presentation and client movement logic, not a server-authoritative fall or landing system. The server script initializes a `parachuting` element-data flag and relays client requests so other clients can create/remove visual parachutes; it does not validate a fall, weapon inventory, landing, or damage outcome.

## Player guide

- The item-system tells players: “Scroll to your parachute while in the air to use it.” The client code detects weapon ID 46 in slot 11 and uses the fire control to open it once the player is high enough above ground.
- Movement controls steer the freefall and canopy. `enter_exit` removes an open parachute; falling into water also ends the local canopy sequence.
- The script temporarily disables next/previous weapon selection during freefall and restores both controls on its handled landing/water/death paths.
- The NPC shop catalog lists a parachute for $400 as item ID 115 with weapon value 46. The item-system resolves parachute items to “Parachute.” Confirm the complete purchase, inventory, weapon grant, and loss flow in those owning resources; this dossier only confirms the catalog and caller references.
- No parachute-specific chat command or staff command is declared by this resource.

## Technical map

| File | Role |
|---|---|
| `meta.xml` | Declares one server script, five active client scripts, one sound asset, minimum MTA versions, and four client exports. `.old` scripts are not loaded by the manifest. |
| `utility.lua` | Shared client helpers scale movement/time by gravity and game speed and read analog movement controls. |
| `parachute.lua` | Sets `parachuting=false` for current players at resource start; accepts `requestAddParachute` and `requestRemoveParachute` from `resourceRoot` and relays visual events to other players. Uses MTA's implicit `client` to identify the request owner. |
| `parachute_cl.lua` | Manages canopy physics and animation, per-client prop tracking, synced animation IDs, landing/water cleanup, and `requestAdd/RemoveParachute` calls. |
| `skydiving_cl.lua` | Detects eligible freefall, simulates steering, displays the low-altitude warning, tracks remote skydivers, and exports `stopSkyDiving` and `isPlayerSkyDiving`. |
| `openChute.lua` | Creates the opening sound/prop animation, attaches and scales the prop, and removes weapon 46 through `exports.weapon:removeWeapon(46)`. |
| `client_anim.lua` | Local animation-phase helper used by canopy open/landing transitions. |
| `parachuteopen.mp3` | 3D sound asset played when a canopy is opened. |

Client exports declared in the manifest are `removeParachute`, `stopSkyDiving`, `isPlayerSkyDiving`, and `isPlayerParachuting`. No server exports or persistence tables are declared. The state is client animation/element data and ephemeral client-side objects; the resource contains no SQL access.

MTA describes `onClientRender` as a per-frame event and cautions against expensive repeated work. This resource attaches both canopy/remote-player work and opening animations to render events, so the work scales with frames and the number of active parachuters/opening objects. Review/profile this during controlled runtime testing. See [MTA `onClientRender`](https://wiki.multitheftauto.com/wiki/OnClientRender).

## Connections to other resources

- `item-system` displays the in-air scroll instruction and maps the parachute item to its name.
- `npc` defines the parachute shop entry: item 115, value 46, price $400.
- `weapon` names weapon 46 and supplies the client `removeWeapon` export used when the canopy opens.
- `pd-system/fastrope/s_fastrope.lua` uses the same parachute animation group for a separate fast-rope flow; that is an animation overlap, not a direct parachute export call.
- `global` owns related shared animation helpers referenced by the fast-rope path; it does not appear as a direct caller of this resource in the search performed.

These references do not establish that the purchase-to-inventory chain works end to end. Follow the shop, item, weapon, and inventory owners when reviewing that workflow.

## Source-confirmed follow-up

- [Issue #466](https://github.com/itschase/OwlMTA-2026/issues/466) tracks a client animation-loop defect: `animateParachuteOpen` iterates `openingChutes` from an `onClientRender` handler but returns from the whole handler while processing an active chute. If multiple props are opening at once, later entries are not advanced in that frame and may wait behind the first active entry. Runtime reproduction and a bounded per-frame update are still needed.
- Both server relay handlers accept any invocation that reaches the registered event and relay it based on `client`; they do not check whether the player is currently skydiving/parachuting or rate-limit requests. This only proves the relay's source behavior. Determine whether repeated forged relay requests can create meaningful client load or visual disruption before filing a security/abuse claim.
- Client code changes movement velocity/rotation and weapon controls. A resource stop, character switch, dimension/interior transition, death, or external animation change can interrupt these flows. The manifest source does not establish cleanup correctness for every transition; cover these cases in runtime checks.
- `openChute.lua` stores the current sound in one shared global `sound` while opening props are tracked per object. Concurrent openings can therefore cause the render loop to reposition only the most recently assigned sound. Confirm whether this is audible/visible enough to warrant a separate issue; it is not included in #466.

## Discord authorization and command modernization

There is no staff permission check, command, or account authorization decision in this resource. Discord roles should not control normal parachute ownership or client animation. The future Discord identity adapter may inform account admission, but this gameplay path should continue to use local inventory/weapon ownership and server-side validation at the item/weapon action boundary. A future contextual UI could expose “open parachute” when the character has the item and is airborne, while preserving the existing scroll/weapon path until parity and accessibility are verified.

## Runtime verification still required

Test purchase and inventory delivery, airborne use at safe and unsafe heights, steering and weapon-slot restoration, landing at high/low fall speeds, water, death, reconnect, character switch, resource stop/restart, interior/dimension change, simultaneous players opening chutes, remote animation updates, and weapon removal. Check server/client debug output and frame cost. Runtime behavior is not claimed as verified.
