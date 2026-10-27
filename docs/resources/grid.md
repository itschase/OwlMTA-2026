# `grid` resource

**Review state:** The active two-file manifest and exported simulation helpers were reviewed against their direct source references. Caller behavior and runtime are unverified. Archived `grid` is a separate implementation documented in [`archive/grid.md`](archive/grid.md).

## What the active resource does

The active resource is a shared Lua utility for relating San Andreas world dimensions, property interiors, and vehicle interiors to a larger set of simulated regions. Its manifest exports `isSimDimension`, `getElementCurrentSim`, `isSimCrossingRequiredForTeleport`, and `getSimName`. It does not load the archived crossing GUI, map browser, maps, or border-crossing scripts.

## How it connects

- `getElementCurrentSim` reads an element's interior and dimension. Outside-world elements in a recognized simulation dimension map directly to that region.
- Property interiors are resolved through `interior_system:findProperty` and parent-interior relationships.
- Vehicle interiors are resolved through `pool:getElement("vehicle", vin)` and then through the vehicle's world/property context.
- The manifest declares no explicit resource dependencies, even though these helper functions call `interior_system` and `pool` exports. Operators should confirm those resources are available before any caller invokes the related paths.
- The repository search found no direct `exports.grid` caller in the active resource tree. The exported API may still be used dynamically or by external resources; the search result does not establish that the resource is unused.

## Player, staff, and operator use

There is no direct player interface, command, database table, or staff workflow in this resource. It supplies shared location-context helpers to other scripts. Future staff dashboards or interaction controls that cross simulation regions must still use the destination and actor checks owned by the calling feature.

Discord roles should not grant region membership or bypass an individual feature's teleport, ownership, duty, or access checks. The helper itself contains no staff authorization policy.

## Source-confirmed issue

In `isSimCrossingRequiredForTeleport(source, target)`, the element-target branch checks `isElement(target)` but calls `getElementCurrentSim(element)`. `element` is undefined in that function; the parameter is `target`. This is tracked by [Issue #390](https://github.com/itschase/OwlMTA-2026/issues/390). The precise runtime failure and caller impact have not been verified on MTA.

## Future interface and diagnostics

Teleport and contextual-interaction screens can use this helper to explain the current region and whether travel crosses a simulation boundary. They should call one server-side domain operation that validates the destination and preserves the owning system's rules. Add bounded diagnostics at the caller for unresolved interiors, missing vehicle mappings, and invalid targets; avoid logging every routine helper call.

## Runtime verification

On a disposable server, validate dimension boundaries, property-parent resolution, vehicle-interior lookup, missing-export behavior, and the element/numeric/invalid target cases in `isSimCrossingRequiredForTeleport`. Resource start order and caller expectations remain unverified. No server or tests were run for this dossier.
