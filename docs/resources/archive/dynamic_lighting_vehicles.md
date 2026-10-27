# `dynamic_lighting_vehicles` resource (archived copy)

**Review state:** Archived source compared with the active resource. No MTA runtime or deployment behavior is verified.

## Source identity

- Archived manifest: `mods/deathmatch/resource-archive/dynamic_lighting_vehicles/meta.xml`
- Active counterpart: `mods/deathmatch/resources/dynamic_lighting_vehicles/meta.xml`
- Both copies contain three corresponding files and share the same manifest and shader asset. `c_vehicleLight.lua` is the only differing file.

## Difference from the active resource

The active vehicle-light script narrows its resource-change trigger condition by removing checks for its own resource name and a legacy nighttime-light resource. The archived version retains those checks. This comparison establishes source differences only; it does not establish which version was deployed or whether either branch is compatible with the current MTA release.

## Intended role and audiences

The resource is a client-side vehicle-light integration with no identified player command, staff console, or persistent data in its small manifest. Any future contextual control should be presented by the vehicle/lighting owner and retain that feature's server-side ownership and state checks. Ordinary visual behavior does not need Discord authorization.

## Documentation boundary

This dossier documents the archived copy's identity and the exact changed file. It is not a full review of all shader behavior, external callers, or deployment configuration. Do not treat this archive as interchangeable with the active resource or run both under the same MTA resource name.
