# `official-interiors`

## Status

- Active resource under `mods/deathmatch/resources/[interior]/official-interiors`.
- Full manifest, loaded/dormant file, direct-caller, persistence, and workflow review completed from source.
- The tracked backup startup configuration enables it; live configuration, startup, rendering, and performance remain unverified.
- No MTA server, client, or database was started, and no tests were run for this review.
- No exact implementation issue currently owns the custom-geometry defects described below; existing issue ownership and non-duplicate candidates are separated explicitly.

## What it does

This resource is the authoritative source-defined catalog of 174 selectable interior templates. Each entry maps an official interior ID to a GTA interior world, entry position, facing angle, and display name. It also distributes client-only object layouts for many custom interiors and exposes the catalog to `interior_system` through the server export `getInteriorsList`.

The resource does not own property access, purchase, keys, rent, or property persistence. `interior_system` uses catalog entries when staff create or change persistent properties. The additional client scripts provide only local geometry and presentation for custom entries.

## Player use

Players can run `/listints [From ID] [To ID]` or `/listinteriors [From ID] [To ID]`. The server validates numeric bounds, prints IDs and names from the requested contiguous range, then sends a client event that copies the hard-coded illustrated-reference URL to the clipboard (`s_interior_map.lua:194-223`; `c_interior_map.lua:1-5`). Listing an interior does not teleport the player, create a property, or grant access.

When a player enters a property that uses a custom catalog entry, the intended client workflow is automatic: the relevant layout objects begin hidden in dimension `65535`, a local activation volume detects the player, and an `onClientRender` watcher moves the objects into the player's property dimension. The source has world-context defects in this activation design, so actual visibility is runtime-unverified.

## Staff and mapping use

The resource itself has no privileged commands. Its direct consumer, `interior_system`, provides the staff workflow:

- `/setinteriorid` and `/setintid` require the legacy Admin or Mapping Team predicate, validate the selected official ID, persist copied catalog coordinates/world data, reload the property, relocate occupants, announce the action, and log it (`interior_system/s_interior_admin.lua:165-225`).
- `/addinterior` and `/addnewint` require Trial Admin or Mapping Team membership and copy the selected catalog record into a new persistent property (`interior_system/s_interior_admin.lua:784-867`).
- `/getinteriorid` and `/getintid` show the current catalog ID and, when it is absent, infer and persist one from the caller's location (`interior_system/s_interior_admin.lua:344-372`). This repair path lacks the staff/mapping authorization used by the mutation commands and is a source-confirmed defect.

These are current legacy authorization predicates, not a proposed Discord policy. Donor/supporter status must not be treated as mapping or property-administration authority.

## Server-operator view

The manifest loads one server script, one core client script, the client `createObject` compatibility wrapper, 59 additional interior scripts, two collision files, and one shader/texture pair (`meta.xml:4-74`). It declares one server export and no settings, ACL requests, `<include>` dependencies, database schema, feature flags, or readiness/version contract.

Seven Lua files are present but not manifest-loaded: `DirectImportsOffice.lua`, `fdinterior.lua`, `lspdosointerior.lua`, `lsprison.lua`, `RaimiRealty1.lua`, `RaimiRealty2.lua`, and `sanninterior.lua`. They are dormant in this resource as checked in; their intended archived, optional, or accidentally omitted status is undocumented.

Adding or changing an official interior currently requires coordinated source edits:

- add or update the positional catalog row in `s_interior_map.lua`;
- add and declare the custom geometry script where needed;
- declare every collision, shader, and texture asset in `meta.xml`;
- keep catalog world/position data aligned with the client layout's objects and activation volume;
- plan migration for existing `interiors` rows, because the consumer copies catalog values into SQL rather than dynamically referencing the catalog.

Stopping this resource removes the export and client-local geometry. Existing property rows remain durable, but custom layouts are unavailable until the client resource is running again.

## Technical map

- Manifest and loaded scope: [`meta.xml`](../../mods/deathmatch/resources/%5Binterior%5D/official-interiors/meta.xml)
- Catalog, commands, and export: [`s_interior_map.lua`](../../mods/deathmatch/resources/%5Binterior%5D/official-interiors/s_interior_map.lua)
- Clipboard receiver: [`c_interior_map.lua`](../../mods/deathmatch/resources/%5Binterior%5D/official-interiors/c_interior_map.lua)
- Shared client object wrapper: [`additionalInteriors/createObject.lua`](../../mods/deathmatch/resources/%5Binterior%5D/official-interiors/additionalInteriors/createObject.lua)
- Persistent consumer: [`interior_system/s_interior_admin.lua`](../../mods/deathmatch/resources/%5Binterior%5D/interior_system/s_interior_admin.lua)
- Startup evidence: [`mtaserver.conf.bak`](../../mods/deathmatch/mtaserver.conf.bak)

## Commands, event, export, and callers

- Commands: `/listints` and `/listinteriors` (`s_interior_map.lua:222-223`).
- Server export: `getInteriorsList()` returns the source-defined catalog (`s_interior_map.lua:190-192`).
- Server-to-client event: `official-interiors:copytoclipboard` (`s_interior_map.lua:219`; `c_interior_map.lua:4-5`).
- No remotely callable server event or mutation handler exists in this resource.
- The only readable direct export caller is `interior_system`, at `s_interior_admin.lua:167`, `:353`, and `:823`.

The tracked startup snapshot starts `interior_system` at `mtaserver.conf.bak:157` and its catalog provider at `:211`. The reviewed export calls are command-time rather than resource-start calls, but neither resource declares the dependency or handles provider startup/restart readiness.

## Persistence and lifecycle

The official catalog is Lua source and has no runtime write path. Additional objects, colshapes, shaders, textures, collision replacements, dimensions, and render handlers exist only on each client.

Property persistence belongs to `interior_system` and the `interiors` table:

- `/setinteriorid` writes the selected `interior_id`, GTA interior, position, and angle (`s_interior_admin.lua:184`).
- `/getinteriorid` can repair `interior_id` (`:358-359`).
- `/addinterior` copies the selected catalog fields into a new row (`:823-837`).

Changing a catalog record does not migrate existing property rows. There is no catalog revision, property/catalog compatibility marker, object-load result, or startup reconciliation report.

## Source-confirmed findings and existing tracker ownership

- **#307 — [Restrict persistent automatic catalog-ID repair](https://github.com/itschase/OwlMTA-2026/issues/307):** owns authorization, ambiguity, property validation, and audit for `/getinteriorid`.
- **#308 — [Repair custom geometry instancing and invalid catalog entries](https://github.com/itschase/OwlMTA-2026/issues/308):** owns dimension/interior activation, trailer visibility, bad catalog ID 50, and creation/cleanup failures.
- **#309 — [Load custom geometry on demand](https://github.com/itschase/OwlMTA-2026/issues/309):** owns lazy packages, shader/resource cleanup, and measured client-performance improvements.
- **#323 — [Check and restore global collision replacements](https://github.com/itschase/OwlMTA-2026/issues/323):** owns checked loading, shared ownership, and stop/restart lifecycle for the global garage collision overrides.

- **Unauthorized persistent repair in the direct caller.** `getInteriorID` has no Trial Admin or Mapping Team guard, yet it can infer an ID from caller position, update `interiors.interior_id`, and change protected live element data (`interior_system/s_interior_admin.lua:344-372`). It may also pass a nil pool element to `setEld`. [Issue #64](https://github.com/itschase/OwlMTA-2026/issues/64) is limited to `interior-manager` remote events/searches, so it does not own this command path. A focused non-duplicate issue should require named capability, canonical property resolution, explicit/ambiguous-match handling, checked persistence, and audit.
- **Activation volumes lack property world context.** The loaded custom layouts create local colshapes but do not assign those colshapes the catalog GTA interior or property dimension, while their objects begin in dimension `65535`. Representative paths are `additionalInteriors/trailer.lua:51-80`, `ID170-backroom/ID170-backroom.lua:44-75`, `ID173-jetbridge.lua:36-67`, and `ID174-Tent.lua:40-70`. This is source-inconsistent with instanced properties; the exact MTA collision/event effect remains runtime-unverified. No existing issue was found for this path.
- **Trailer geometry remains transparent.** `additionalInteriors/trailer.lua:77-80` sets every object to alpha `0`, while its activation watcher changes only dimension (`:52-61`). No alpha restoration exists in that loaded file. No existing issue was found.
- **Catalog ID 50 is knowingly invalid.** `s_interior_map.lua:62` retains a selectable row whose comment says it has no actual interior and incorrect teleport coordinates. No existing issue was found.
- **The shared object wrapper cannot honor explicit false flags.** `additionalInteriors/createObject.lua:7-27` calls setters without checking native object creation and applies collision/breakability only when their values are truthy. Its documented optional `false` values therefore cannot disable those properties. No existing issue was found.
- **Business-garage shader lifecycle is unbounded and broadly scoped.** `ID24-BusinessGarage.lua:17-35` creates texture/shader elements on qualifying dimension changes and applies the shader by world texture name without an object restriction. Leave handling removes only the render callback and does not remove or destroy shaders/textures (`:49-54`). No existing issue was found.
- **Collision replacement lacks checked lifecycle.** `forrestsgarage.lua:1-12` loads and globally replaces collision models 11391 and 11393 at start, repeats after one second, and does not check results or restore prior collision state on stop. Runtime necessity/effect is unverified.
- **Dependency order is implicit.** The consumer precedes the provider in the tracked startup list and neither manifest declares readiness. Existing [Issue #21](https://github.com/itschase/OwlMTA-2026/issues/21) owns dependency-safe startup ordering; do not open a duplicate startup issue.
- [Issue #46](https://github.com/itschase/OwlMTA-2026/issues/46) owns interior purchase/keypad authorization, [Issue #81](https://github.com/itschase/OwlMTA-2026/issues/81) owns persisted settings hydration, and [Issue #260](https://github.com/itschase/OwlMTA-2026/issues/260) owns `object-system` dimension synchronization. They are related context but do not own this resource's catalog and client-local geometry defects.
- Documentation and one-resource Discussion coverage belong to [Issue #7](https://github.com/itschase/OwlMTA-2026/issues/7), [Issue #69](https://github.com/itschase/OwlMTA-2026/issues/69), and [Issue #95](https://github.com/itschase/OwlMTA-2026/issues/95).

These are static source findings. No exploit, visibility failure, performance limit, or startup failure was demonstrated in a running MTA client/server.

## Scale and modernization direction

The 60 manifest-loaded files under `additionalInteriors` contain approximately 3,348 client `createObject` calls and 61 colshape creations. The source eagerly creates these layouts for every client and parks most objects in dimension `65535`. This establishes a large client download/startup/memory surface, but acceptable or unacceptable performance cannot be concluded without measurement.

Replace the repeated colshape/render scripts with one lifecycle manager driven by the player's authoritative active property and catalog ID. Package geometry per catalog entry, load only the active package, and deterministically unload objects, shaders, textures, collision changes, and handlers. Define a typed/versioned catalog record, validate unique IDs, finite transforms, GTA interior values, asset declarations, helper compatibility, and enabled state, and classify dormant files. Add a migration/reconciliation tool for existing property rows when catalog transforms change.

Recommended non-duplicate implementation units are:

1. authorize and validate `/getinteriorid` repair;
2. repair custom geometry instancing, trailer alpha, and invalid enabled catalog rows;
3. replace eager geometry creation with measured on-demand packages and checked asset lifecycle;
4. add a static catalog/manifest/asset coherence validator.

These are proposals, not implemented behavior.

## Runtime verification still required

After safe-start preparation, use a disposable server/client/database to verify both list commands and clipboard behavior; every enabled custom catalog ID; two simultaneous properties using the same custom layout in different dimensions; direct teleport, normal entry/exit, positive-dimension switches, interior switches, character changes, reconnect, resource stop/restart, and provider outages. Exercise invalid object/model/assets, texture/shader creation failure, collision replacement and restoration, catalog ID 50, trailer visibility, ordinary-player versus mapper/admin repair attempts, ambiguous catalog matches, nil property elements, and database failure.

Record client download size, object/element counts, startup time, memory, frame time, and repeated property-switch behavior on the pinned MTA build. Until that is done, source review is complete but all runtime behavior and performance remain unverified.
