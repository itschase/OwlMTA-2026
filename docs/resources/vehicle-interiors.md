# `vehicle-interiors`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; live startup is unverified.
- Evidence state: source-confirmed; entry authorization was fixed in source.
- Runtime state: unverified.

## What it does

`vehicle-interiors` creates enterable interior spaces for supported large vehicles and connects their exterior entrances and interior exits. It handles player transitions and, for the supported transport cases, moving a driven vehicle with its occupants into the linked interior dimension.

## Player use

A player approaches the physical entrance attached to a supported vehicle and uses the visible prompt or right-click entry action. Locked vehicles reject entry. Entry on foot moves the player through `interior_system`; the special Andromada and trailer flow can move a driver and occupied vehicle. The resource also provides the linked exit behavior inside the vehicle interior.

## Staff and operator use

The resource exports `add` and `isNearExit` for registration and proximity checks. It depends on `interior_system` for player transitions and `anticheat` for protected vehicle state. It packages texture files for the supported aircraft interiors.

The source now derives the actor from MTA's server-side `client`, confirms that the supplied vehicle is live and registered, requires matching interior/dimension and presence inside the attached entrance colshape, checks supported occupancy rules, and rejects locked vehicles. This is fixed-in-source evidence, not a runtime claim.

## Technical map

- Manifest: [`mods/deathmatch/resources/[vehicle]/vehicle-interiors/meta.xml`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle-interiors/meta.xml)
- Server registration and transitions: [`s_vehicle_interiors.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle-interiors/s_vehicle_interiors.lua)
- Client prompts and textures: [`c_vehicle_interiors.lua`](../../mods/deathmatch/resources/%5Bvehicle%5D/vehicle-interiors/c_vehicle_interiors.lua)
- Important connections include `vehicle`, `interior_system`, `anticheat`, and the right-click system.

## Known risks and next work

- [Issue #94](https://github.com/itschase/OwlMTA-2026/issues/94) tracks the entry-proximity correction and remains open until its acceptance path is runtime verified.
- Operators need a documented list of supported models, their interior templates, exit placement, and recovery behavior when an attached entrance or exit is missing.
- Runtime verification should cover foot entry, locked rejection, wrong dimension, remote/stale vehicle requests, supported driven-vehicle entry, passenger transition, exit, resource restart, and texture changes.
