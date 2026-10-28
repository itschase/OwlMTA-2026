# `LSFD` resource

**Review state:** Full manifest, alarm, random-incident generation, faction/admin entry points, and resource lifecycle reviewed statically. Live dispatch, sound, fire-model behavior, and restart cleanup remain unverified.

## Player and staff experience

`LSFD` bundles a staff-triggered random fire incident and a fire-department pager/alarm. A trial administrator can use `/randomfire` to pick a location from the in-resource incident table. Online faction ID 2 members receive radio-style chat with incident details; selected entries can create and explode a vehicle, special incidents create several decorative fire objects, all incidents create a map blip and object/colshape, and clients receive an event that plays the alarm and later creates a local fire. A 15-minute `isFireOn` gate prevents another incident from being started while the current incident is marked active.

`/cancelfire` is also trial-admin-gated and restarts the entire `LSFD` resource to clear the active sequence. The checked-in startup inventory marks this resource active. The `/alarm` command is available to faction ID 2 members and sends a station-area alarm to nearby players plus pager notices/sounds for faction members holding item 217. The help/policy intent of this station bell should be confirmed; a five-unit station proximity check is present only as commented-out code.

## Dependencies and operations

The manifest loads the fire incident server/client pair, pager server/client pair, sound assets, and fire model asset. It declares no resource dependencies, but server code calls `factions`, `integration`, and `global` exports. Confirm those resources start first. There is no database persistence or Discord integration in this resource; organization membership and staff command access come from current faction/integration predicates. Future Discord role grants should not substitute for fire-service membership on `/alarm`; the trial-admin incident trigger should migrate as a named staff capability after its policy is decided.

## Source-confirmed findings and limits

- [Issue #456](https://github.com/itschase/OwlMTA-2026/issues/456): the `special` fire branch creates `fireElem2` through `fireElem6` but passes an out-of-scope `fireElem` to each collision setter. The first error can abort the remainder of incident setup before the base fire object, cleanup timer, client alarm event, and blip are created. Runtime behavior is not tested.
- [Issue #457](https://github.com/itschase/OwlMTA-2026/issues/457): `/alarm` has no cooldown, and its explicit station-distance check is commented out. Decide whether it is a physical station bell or remote dispatcher pager; apply the corresponding proximity/world and rate-limit rules.

The incident list includes repeated location entries and hard-coded faction IDs/coordinates. The command state is an in-memory boolean, not a durable incident record or dispatch queue. Fire and cleanup logic is split between client and server, so cancelling/restarting a resource may not provide a clear audit trail or recovery contract.

## Future direction

Replace the random single-incident boolean with a small server-owned incident lifecycle: create an incident ID, dispatch it to eligible fire personnel, let the crew acknowledge/respond/arrive/clear, track scene objects and timers for cleanup, and record actor/outcome. An in-game fire/EMS operations panel can expose that lifecycle without requiring website management. The same interface can later support staff-created scenarios with an audit trail. Keep configurable dispatch policy, duty state, and organization membership separate from Discord identity, and route logs through an optional server logging adapter.

## Runtime verification

No MTA server was started and no test was run. In a disposable environment, verify `/randomfire` authorization, response eligibility, each special and regular scene, vehicle spawn/explosion cleanup, location blip lifetime, sound radius, delayed fire creation, repeated-trigger gating, `/cancelfire` cleanup, `/alarm` faction behavior, station proximity and world/dimension routing, beeper item distribution, and resource restart behavior. Also verify dependency start order and operator visibility of failures.
