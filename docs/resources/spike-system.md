# `spike-system`

**Purpose:** Create temporary law-enforcement spike strips and apply wheel damage when a vehicle passes through a marked collision shape.

**Evidence state:** Manifest, scripts, and the direct roadblock-system connection reviewed. Runtime wheel-state synchronization, collision alignment, and cleanup have not been verified in MTA.

## Player use

Players in faction type `2` can deploy a strip with `/throwspikes`. The server places model `2892` about five world units ahead of the player, rotates the object to the player's heading, and limits this resource to 15 tracked strips. `/removespikes [ID]` removes a strip when the caller is within 10 world units of its object. The deployment and retrieval paths emit roleplay emotes and database log entries.

The client listens for `onClientColShapeHit`. When the entering element is a vehicle, the local player is its controller, the dimensions match, and the hit colshape carries element data `type="spikes"`, each wheel has a separate 3-in-4 random chance to be set flat. The code calls the shared MTA `setVehicleWheelStates` function. Whether client-side changes are consistently authoritative in a live server has not been verified.

## Staff use

`/aremovespikes` is restricted by the existing Trial Admin integration predicate and clears strips tracked in this resource. It is a separate cleanup path from roadblock-system's own object/shape management; it should not be assumed to remove roadblock-created strips.

The current removal action logs the text “Spawned spike ID …” after removing a strip. This source-confirmed audit-label mismatch is tracked in [Issue #524](https://github.com/itschase/OwlMTA-2026/issues/524).

## How the resources connect

- `factions` provides the faction-type eligibility check for deployment and player retrieval.
- `pool` allocates the created strip object and collision shapes.
- `anticheat` writes the protected `type="spikes"` element data consumed by the client collision handler.
- `logs` records deployments and removals; `global` provides the `sendAme` emote event.
- `roadblock-system` independently places a spikestrip model (1593) and marks its collision shape `type="spikes"`. Because this resource's client handler is attached to the root element and checks that marker, both systems feed the same wheel-damage behavior while retaining separate placement, ownership, and cleanup state. See [`roadblock-system`](roadblock-system.md).

## Operator and implementation notes

- Strip count and IDs are held in resource-local Lua tables. No database persistence is declared; strips are therefore session/runtime objects, not durable player inventory.
- The visible object rotates with the player's heading, but this resource's two `createColRectangle` areas use fixed XY offsets. MTA's rectangle constructor takes XY, width, and height without a rotation parameter. At non-axis-aligned headings, trigger geometry can diverge from the visible object. Track this in [Issue #523](https://github.com/itschase/OwlMTA-2026/issues/523).
- The script does not explicitly copy the deploying player's interior or dimension to the created object and shapes. Confirm whether deployment is restricted to the main world; otherwise, align all generated elements to the deployment context.
- Client-side wheel-state changes and colshape visibility should be verified against MTA's current synchronization behavior. The MTA references are [createColRectangle](https://wiki.multitheftauto.com/wiki/CreateColRectangle), [onClientColShapeHit](https://wiki.multitheftauto.com/wiki/OnClientColShapeHit), and [setVehicleWheelStates](https://wiki.multitheftauto.com/wiki/SetVehicleWheelStates).
- Keep existing commands while exploring a third-eye/context interaction for deployment and nearby authorized removal. The interaction must retain law-faction membership for police deployment; a future Discord staff capability must not grant police gameplay authority. Discord authorization is not implemented here.

## Source map

- `meta.xml` — loads one client script and one server script.
- `s_spikes.lua` — deployment, faction checks, local strip registry, proximity removal, and Trial Admin cleanup.
- `c_spikes.lua` — client collision response for any root-visible colshape carrying the `spikes` marker.
