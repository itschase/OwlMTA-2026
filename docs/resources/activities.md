# `activities` resource

**Review state:** Full manifest-script and direct-caller static review. Runtime and shipped-server behavior remain unverified.

## Purpose and active scope

`activities` groups small world activities that are not represented as durable character/job systems. The current manifest actively loads two features: the moving Ferris wheel and snowballs. Surfboarding files exist in the folder but every surfboard manifest entry is inside an XML comment, so those scripts are not part of this resource's active load set. The resource description also mentions skateboarding and ice skating, but those are handled elsewhere or are not active here; do not infer them from the description.

The manifest loads `ferris/ferris_s.lua`, `ferris/data_pos.lua`, and `ferris/ferris_c.lua`; it also loads the server/client snowball scripts and `snowball/snowballhit.wav`. It ships `ferris/fcabin.col`. There are no declared exports or explicit `<include>` dependencies. The snowball server calls `bone_attach:attachElementToBone` and `detachElementFromBone`; startup therefore expects the `bone_attach` export to be available. The tracked startup snapshot lists `activities` enabled, but this does not establish the state of any live server.

## Player workflows

### Ferris wheel

1. On resource start, the server removes two vanilla world models at the fixed LS location, creates ten custom cabin objects, attaches decorative corona markers and colshapes, and starts a repeating seven-second movement timer (`ferris/ferris_s.lua`). The path is a fixed 20-point position list in `ferris/data_pos.lua`.
2. When the client resource starts, it replaces object 3752's collision with `ferris/fcabin.col` and requests the server's cabin colshape list (`ferris/ferris_c.lua`).
3. Entering a cabin's client-observed colshape binds the configured enter key (currently `h`) and disables one camera clipping mode. Pressing the key moves the local player to the cabin position. The client then binds the same configured key for exit; pressing it moves the player to one fixed exit point and restores camera clipping after leaving the colshape or dying.

There is no fare, reservation, seat capacity, owner/operator control, or persisted ride state in this resource. Entry and exit are client-side controls; server acceptance and behavior against MTA position synchronization need runtime verification. The configured key array is `{ 'h', 'h' }`, despite the adjacent comment describing distinct default enter and exit keys.

### Snowballs

1. The social resource adds a local right-click row named “Make snowball.” Selecting it sends `xmas:snowball:make` with `localPlayer` as both event source and a payload argument (`social/c_player_rightclick.lua:44-45,149`).
2. The server waits one second, creates a model-1974 object at the submitted player's position, attaches it to the player's right hand through `bone_attach`, sets `snowball` element data, binds server-side mouse-one input, and emits an emote. The object melts after one minute.
3. A throw request asks that player’s client to raycast ten units ahead. The client sends the target coordinates, optional hit player, and hit flag back to the server. The server detaches and animates the object, then emits a splash and sound; a player hit receives an emote and local sound, not damage.
4. Character changes and player quit call cleanup to destroy the attached snowball object.

The feature has no inventory item, money cost, damage, score, or durable state. Its effects are cosmetic and activity-only in the reviewed source.

## Staff and operator workflows

No staff command, admin panel, permission check, or operator configuration is declared for the active Ferris wheel or snowball features. The ship/operator-facing controls are limited to starting/stopping the whole resource; its world location, path, cabin model, exit point, key bindings, melt timer, and throw animation are source constants. The `/setwave` command belongs to the currently commented-out surfboard server script and is not loaded by this manifest.

## Integration surface

| Surface | Source | Use |
|---|---|---|
| Remote event `client_getCabinsCollision` | `ferris/ferris_s.lua` | Returns the cabin colshape element list to the MTA `client` requester. |
| Remote event `xmas:snowball:make` | `snowball/s_snowball.lua` | Creates/attaches a snowball, currently using the payload player. |
| Remote event `xmas:snow:throw` | `snowball/s_snowball.lua` | Moves and destroys the player's current snowball using client-supplied trajectory/hit data. |
| Internal event `accounts:characters:change` | `snowball/s_snowball.lua` | Cleans up the changing player's attached object. |
| Command | none active | `/setwave` is in a non-manifest-loaded surfboard script. |
| Exports | none declared | Snowball code consumes `bone_attach` exports. |

MTA event handlers receive the authenticated remote `client` separately from the event's source and ordinary payload arguments. The snowball handlers do not use `client` to bind the requested actor. The event/source distinction and client/server boundary are described in the [MTA server boundary reference](../reference/MTA_SERVER_BOUNDARIES.md) and the official [MTA event](https://wiki.multitheftauto.com/wiki/Event) and [addEventHandler](https://wiki.multitheftauto.com/wiki/AddEventHandler) documentation.

## Persistence and lifecycle

- Ferris wheel position and movement state are server memory, recreated at fixed coordinates on resource start. The timer is not explicitly retained or canceled in a resource-stop handler.
- Snowball objects and `snowball` player element data are transient. Timed cleanup checks that the held object still matches the timed object before clearing the player's state.
- Character-change and quit cleanup destroys the current object, but does not explicitly unbind mouse-one in `predeleteBall`; a later binding lifecycle should be verified.
- No database tables, save files, XML, or durable event records are used by the active manifest-loaded scripts.
- Surfboard code appears in the folder and references `item-system` internally, but it is currently excluded by the manifest comment and must not be treated as live functionality without an explicit manifest change.

## Source-confirmed findings

1. **Snowball creation trusts a caller-selected player.** The remotely triggerable `xmas:snowball:make` handler is attached to `root` and directly accepts `thePlayer`; it does not bind the actor to MTA's `client` or verify a live, logged-in caller. A caller can request creation against a different player element. The impact and client synchronization behavior need controlled runtime confirmation; the missing actor binding is source-confirmed.
2. **Snowball throwing trusts client-selected actor and hit payload.** `xmas:snow:throw` is remotely triggerable and receives `thePlayer`, coordinates, `hitElement`, and `hit` from the client call. The handler does not check that the supplied player equals `client`, that the requester owns the active snowball, that the target is valid/nearby, or that the trajectory is bounded. Current consequence in source is object movement plus cosmetic emotes/sounds, not health damage.
3. **Snowball lifecycle can leave stale input bindings.** Character-change/quit cleanup destroys the snowball object but does not unbind the `mouse1` function; the expiration callback does unbind when it clears the matching object. Confirm key-binding behavior on the target MTA build before deciding whether this produces a persistent stale binding.
4. **Ferris wheel entry/exit lacks a server-managed ride session.** Client controls perform the position changes without a matching server-side occupancy/session record. This limits operator visibility and provides no authoritative capacity, cancellation, or recovery path. Whether this breaks normal position synchronization is runtime-unverified.
5. **Ferris client setup trusts one unvalidated response.** `server_sendCabinsCollision` iterates the received table and binds handlers without checking shape, element type, expected cabin count, or duplicate-response state. The current server response is generated from the resource's own cabin list, but the client event is exposed to remote triggers and setup is not explicitly idempotent.
6. **Surfboard behavior is dormant under the current manifest.** Source files exist, but the manifest wraps the scripts and export declaration in a comment. Any change that relies on surfboarding must first resolve its activation and integration design.

## Improvement opportunities

- Bind all snowball remote actions to MTA `client`; derive the player and held object from the authenticated actor's server state.
- Keep target coordinates/effects cosmetic and bounded; validate world, trajectory distance, target type, active object, and interaction timing server-side.
- Make create, throw, melt, character-change, quit, and resource-stop cleanup a single idempotent lifecycle with explicit input unbinding and object cleanup.
- Decide whether activities are individually toggled/configured or kept as one bundle; externalize Ferris coordinates, exit point, key, path interval, and snowball lifetime with safe defaults.
- Add server-side ride occupancy/teleport validation only if the feature needs reliable passenger state, capacity, or staff visibility.
- Either restore surfboard support with an end-to-end manifest/caller review or label/archive it as dormant, rather than letting folder presence imply activation.
- Add structured, rate-limited debug records for rejected create/throw requests and resource lifecycle failures without logging secrets or excessive per-frame activity.

## Tracking and verification

The snowball remote boundary is tracked by [Issue #306](https://github.com/itschase/OwlMTA-2026/issues/306) under the existing [remote-event authorization umbrella, Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1). Inconsistent input unbinding across snowball teardown paths is tracked separately in [Issue #322](https://github.com/itschase/OwlMTA-2026/issues/322). Runtime behavior, position synchronization, event abuse impact, attachment cleanup, and resource start/stop behavior have not been tested.

## MTA references

- [Meta.xml](https://wiki.multitheftauto.com/wiki/Meta) — resource manifest controls which scripts and files load.
- [Event](https://wiki.multitheftauto.com/wiki/Event) and [addEventHandler](https://wiki.multitheftauto.com/wiki/AddEventHandler) — event propagation and the authenticated `client` variable for remote server events.
- Local reference: [MTA server event and outbound request notes](../reference/MTA_SERVER_BOUNDARIES.md).
