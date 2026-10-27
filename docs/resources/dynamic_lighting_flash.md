# `dynamic_lighting_flash` resource

**Review state:** Full manifest-script and direct-caller review. Network caller binding, inventory persistence, and flashlight rendering remain runtime-unverified.

## Player workflow

This resource makes inventory flashlight item type `145` usable as a rendered flashlight. While holding it on foot with weapon slot 0 active, a player toggles it with **L**. A client-side light is attached/rendered through `bone_attach` and `dynamic_lighting`, and the HUD reports flashlight state. Dropping the item and character-selection transitions turn it off.

Battery value is stored on the inventory item through `item-system`; the client requests a one-point drain every ten seconds. This resource does not own a separate SQL table or staff command.

## Connected resources and permissions

The server uses `realism` to force/clear walk style 57. Client lighting uses `bone_attach`, `dynamic_lighting`, and `pool`; player feedback uses `hud`; inventory interactions come from `item-system`. The normal feature is player equipment and should not require Discord staff or supporter roles. The server must still derive actor identity from the authenticated MTA event caller and validate the current item/value before persistence.

## Source-confirmed trust-boundary findings

- **Flashlight network handlers use event `source` as the actor and accept a client recipient list.** The remote `onSwitchLight` and `flashlight:enable` handlers use `source` to set state and force walk style; `flashlight:enable` also iterates `nearbyPlayers` supplied by the event caller. The normal client sends local state from a player source, but the server should bind to MTA's server-derived `client`, derive recipients itself, and validate inventory/state. See [Issue #384](https://github.com/itschase/OwlMTA-2026/issues/384). This is a static trust-boundary concern, not a runtime-tested exploit claim.
- **Battery drain accepts a client-provided value.** The handler takes `batt` and `dbid`, locates the inventory item in the caller's inventory, and writes the supplied value without checking numeric type, bounds, monotonic decrement, or drain timing. The normal client requests a one-point decrement every ten seconds. See [Issue #385](https://github.com/itschase/OwlMTA-2026/issues/385).
- `onPlayerGetInter` is remotely registered but no caller was found during repository source search. Confirm whether it is obsolete before removing or retaining it.
- `functions_c.lua` passes misspelled `flase` to the light export, but the current callee's false-like branch means this is not established as a behavior bug.

## Future interaction and diagnostics

The flashlight is a contextual inventory item, not a staff action. A future interaction layer can expose toggle/battery status, but the server should verify possession and derive depletion. Add bounded logs for rejected caller/item/value state and resource failures without flooding per-frame render paths.

## Runtime verification

On a disposable server/database, verify the item-use event, item removal/drop, character switch, battery persistence/rate, forged actor and recipient payload rejection, walk-style cleanup, attached light and streamed-player lifecycle, and resource restart. No server or tests were run.

## MTA references

- [Script security](https://wiki.multitheftauto.com/Script_security) says client event parameters and `source` can be faked while server-side `client` is trusted for remotely triggered events. Use it as the review baseline for the two event boundaries tracked above.
- [triggerServerEvent](https://wiki.multitheftauto.com/TriggerServerEvent) explains event delivery and directs server handlers to use `client` rather than a client-supplied actor value.
