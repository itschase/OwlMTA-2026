# `animation-system` resource

**Review state:** Full manifest-script and direct-caller source review. Runtime behavior, animation validity, synchronization load, and MTA-version compatibility remain unverified.

## Purpose and player use

`animation-system` provides ordinary roleplay emotes, an animation browser, custom OWL animation loading, cancellation controls, and synchronization of custom animation state to other clients. General animation application is delegated to `global:applyAnimation`; the resource also has a direct server `AnimationSet` path for the client browser.

Players can browse animation groups in the client GUI, start a selected animation, choose whether it repeats, and maintain a client-side favourites list in `favourite.xml`. `/animselect` opens or closes the browser. `/anim <shortcut>` uses shortcuts in `animations.xml`. The server command family also exposes individual emotes.

## Commands and interface opportunities

Every command currently registered in the reviewed scripts is grouped below by use case. These are player actions; the review found no staff-only animation command. Names in parentheses are aliases.

| Audience/use case | Commands | Current and future interface |
|---|---|---|
| Find and browse emotes | `/animlist` (`/animhelp`, `/anims`, `/animations`), `/animselect`, `/anim <shortcut>` | The GUI already provides grouped browsing, favourites, repeat, and start controls. Improve search, readable group labels, preview/confirmation, and clear cancellation feedback. Keep command search and shortcuts available for keyboard users. |
| Cancel or recover from an animation | `/stopanim` (`/stopani`), `/animstop`, Space key | Keep a visible cancel control and consistent key hint in the animation panel; ensure forced/cinematic and gameplay-locked states remain authoritative. |
| Common social, posture, and expression emotes | `/beg`, `/cheer`, `/cry`, `/dance`, `/daps`, `/handshake`, `/laugh`, `/lay`, `/lean`, `/mourn`, `/shocked`, `/sit`, `/tired`, `/wait`, `/what`, `/win` | Offer searchable emote categories and context presets; retain direct commands as quick access. |
| Movement, gesture, and performance emotes | `/aim`, `/bat`, `/bitchslap`, `/crack`, `/dive`, `/fall`, `/fallfront`, `/fu`, `/gsign`, `/heil`, `/kickballs`, `/kiss`, `/puke`, `/rap`, `/scratch`, `/shake`, `/shocked`, `/shove`, `/strip`, `/think`, `/walk`, `/walk2`, `/wank` | Improve labels, argument/range guidance and animation-state feedback in the browser. Review consent, RP rules, and any gameplay restrictions before adding contextual menus. |
| Situational, service, and vehicle emotes | `/carchat`, `/copaway`, `/copcome`, `/copleft`, `/copstop`, `/cover`, `/cpr`, `/drink`, `/drag`, `/grabbottle`, `/hailtaxi`, `/handsup`, `/idle`, `/lightup`, `/piss`, `/slapass`, `/smoke`, `/smokelean`, `/startrace` | Use context only where a validated situation makes the action relevant (for example, a vehicle interaction or medical workflow). A contextual UI must call the owning gameplay service for eligibility and state; a menu itself is not authority. |

The legacy `/animlist` help currently advertises `/fixcar`, but its handler registration is commented out. The animation exists as a function but is not a command in this resource; the help output was corrected in source during this review. A centralized command catalog should eventually report actual registrations instead of maintaining a second hand-written list.

## Staff, operator, and Discord authorization

No staff/admin command or staff-only control is registered here, so ordinary emotes, browsing, favourites, and animation cancellation should not require a Discord role or capability. Current command handlers generally rely on `global:applyAnimation` and login state, with some local `loggedin` checks; their exact cross-resource restrictions require runtime verification.

If a future staff interface adds forced animation, moderation, or animation policy management, check the named staff capability at that authoritative action boundary through the shared Owl authorization facade and reusable Discord identity plugin. Keep the actor, target, character lifecycle, state, and local moderation policy checks in the gamemode. Donor/supporter tiers are not staff permissions. No role IDs, credentials, or direct Discord API logic belong in this resource. The plugin is not integrated into Owl yet.

## Technical map and connections

- `meta.xml` loads server animation functions, client browser/animation code, `animations.xml`, and `sync_animations_server.lua`; it packages `custom/owl.ifp`.
- `s_animation_system.lua` registers the emote commands, binds Space to stop eligible animations, and exposes forced-animation marker and key binding events.
- `s_list.lua` handles the remotely triggerable `AnimationSet` event and applies the server animation to event `source`; it rejects three animation names using a local denylist.
- `c_list.lua` builds the GUI and client favourites file; `/anim` maps XML shortcuts to animations. It sends remote events for ordinary/custom animation changes, stopping, and initial sync.
- `sync_animations_server.lua` stores transient current/replaced custom-animation state and broadcasts it to registered synchronization clients. Its remote handlers accept player elements in their arguments.
- `global/s_animation_globals.lua` calls `bindAnimationStopKey` and updates the forced-animation marker for gameplay animation flows. `global/c_animation_globals.lua` calls the exposed `forcedanim` and `unforcedanim` events. These are internal integrations that must remain separate from player-remote calls.
- The `phone` resource reads the forced-animation marker while deciding whether to play a phone animation; `superman` updates a similarly named element-data value in its own workflow.

## Persistence and diagnostics

Custom synchronization state is held in memory and cleared for quitting players. Client favourites are stored in a resource-local XML file rather than account/database state. The server records no animation history. IFP load failure calls `outputDebugString`, but most rejected or failed remote animation paths have no structured diagnostic record. The sync subscriber list is a plain array and remote sync requests can append entries without deduplication.

## Source-confirmed findings and tracking

- **Remote animation/sync handlers accept supplied player elements.** The custom sync handlers update/broadcast for the payload player, and the sync request appends that player to a subscriber list without verifying that it is the authenticated MTA `client`. Repeated requests can also create duplicate subscriptions. See [Issue #335](https://github.com/itschase/OwlMTA-2026/issues/335). This is a source-confirmed trust-boundary finding, not a demonstrated runtime exploit. MTA's [Script security guidance](https://wiki.multitheftauto.com/Script_security) and [`triggerServerEvent`](https://wiki.multitheftauto.com/TriggerServerEvent) documentation say to use server-provided `client` for remote caller identity and validate payloads.
- **The ordinary `AnimationSet` event trusts animation values.** It uses `source` as the ped target, which is client-supplied for remote event calls, and only rejects three names; it does not validate the block/name against the client catalogue or constrain argument types/rate. Include this boundary in Issue #335's audit and fix plan.
- **Help output advertised a disabled command.** `/fixcar` was listed in `/animlist` despite its command registration being commented out. The inaccurate help entry has been removed from source; no runtime verification has been performed.
- **Animation catalog loops and invalid names need systematic validation.** XML names are accepted from a client event boundary in the ordinary path. Validate against server-owned allowed animation definitions and preserve intentional gameplay restrictions before application.

## Modernization opportunities

- Unify commands, browser selection, shortcuts, and contextual actions behind a server-owned animation request API with a single animation allowlist and consistent state/lock checks.
- Make remote animations self-targeting by deriving the actor from `client`; provide a separate trusted server-only API for gameplay systems that need to animate another player.
- Deduplicate synchronization subscriptions, validate element lifecycle and custom IFP indices, bound event frequency/state size, and make join/resource restart reconciliation explicit.
- Retain favourites as client preference unless account-linked cross-device synchronization is deliberately added; avoid turning favourites into gameplay authority.
- Add bounded debug events for rejected values, failed animation application, IFP load state, and sync lifecycle. Avoid emitting a log line for every animation frame or routine emote.

## Runtime verification still required

In a disposable MTA test environment, verify every command, XML shortcut, GUI selection, loop/cancel flow, login state, banned-animation rule, gameplay forced animation, custom IFP loading, join-in-progress state sync, repeat sync requests, player quit, resource stop/restart, and invalid/oversized event arguments. Confirm current MTA client/server API behavior and measure latent sync traffic. No server or tests were run for this review.
