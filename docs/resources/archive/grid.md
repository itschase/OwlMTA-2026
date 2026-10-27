# `grid` resource (archived crossing and map system)

**Review state:** Archived manifest and file inventory compared with the distinct active `grid` resource. This legacy implementation is not a player-available feature while stored in `mods/deathmatch/resource-archive/`. Runtime and historical deployment are unverified.

## Source identity and separation

- Archived manifest: `mods/deathmatch/resource-archive/grid/meta.xml`
- Active counterpart: `mods/deathmatch/resources/grid/meta.xml`, documented separately in [`../grid.md`](../grid.md).
- The active resource contains only `g_grid.lua` and exports shared simulation-dimension helpers.
- The archive has fourteen files and contains client/server border-crossing logic, loading and mapping interfaces, image assets, and two maps.
- The only shared relative file is `meta.xml`, and its content differs.

These are distinct systems with a reused resource name. The archived crossing/map behavior must not be inferred from the active helper library; active exports must not be projected onto the archive.

## Audiences and future use

The archive appears to represent a broader region-crossing and map-loading experience. Its player flows, configuration, server events, and exact map lifecycle require a separate source audit before proposing operation or reuse. No current staff dashboard, Discord capability, or active player command is inferred from its presence in the archive.

If revived, treat region travel, map loading, and boundary transitions as gameplay operations owned by this resource. Future third-eye or map UI should call validated server operations and preserve destination, dimension, interior, and player-state checks. Staff controls should be separately authorized and logged; ordinary region travel should not depend on staff or supporter roles.

## Documentation boundary

This is an identity and source-tree comparison, not a complete feature or security review. Archived event behavior, external callers, required maps/assets, and compatibility with current MTA remain open questions. Do not start it alongside the active same-named resource.
