# `object-browser`

## Status and evidence

- Resource path: `mods/deathmatch/resources/object-browser`.
- Source review: active manifest, `ob.lua`, `obj.xml`, and in-tree references reviewed; the object list was parsed from source for its entry/group counts.
- GitHub record: [Script Resource Discussion #546](https://github.com/itschase/OwlMTA-2026/discussions/546); [Issue #464](https://github.com/itschase/OwlMTA-2026/issues/464) tracks camera/cursor cleanup.
- Runtime: unverified. The MTA server/client was not started.
- Startup snapshot: not enabled in `mtaserver.conf.bak`; this does not rule out manual operator use.
- Callers: no in-tree resource caller or integration was found; commands are registered inside this resource.
- GitHub record: individual Script Resource Discussion pending; [Issue #464](https://github.com/itschase/OwlMTA-2026/issues/464) tracks camera/cursor cleanup and is assigned to [Milestone #7: Resource Audit and Security Baseline](https://github.com/itschase/OwlMTA-2026/milestone/7).

## Purpose in everyday terms

This is a client-side catalog and 3D preview tool for GTA object models. It presents a categorized list from `obj.xml`, lets the operator select an object ID, and moves the camera around a temporary local preview. It does not create persistent server objects, edit maps, or grant access to gameplay actions.

The catalog contains 7,525 `<object>` entries across nine top-level groups: Beach and Sea, Buildings, Industrial, Interior objects, Land masses, Miscellaneous, Nature, Structures, and Transportation. A first-time load warns that list construction may take several minutes; actual duration and client impact have not been measured.

## User and operator workflow

1. Start the resource manually if it is not running; the checked-in startup snapshot does not enable it.
2. Run `/objbrowser` or `/obj` on the client.
3. Wait while the object list is populated on first use, then select a model entry to create a temporary preview and inspect its radius/camera framing.
4. Use the Close button to remove the preview, hide the cursor, remove the render handler, and return the camera to the local player.

The resource is client-only. It has no staff permission checks, server events, SQL, or database state. Anyone with this resource running can use the local preview utility; there is no server-side mutation to authorize.

## Implementation notes

| File | Role |
|---|---|
| `meta.xml` | Starts `ob.lua` client-side and loads `obj.xml` as a client configuration file. |
| `ob.lua` | Creates the GUI, binds arrow-key browsing, parses the catalog on first open, creates/destroys the local preview object, and manages camera/render state. |
| `obj.xml` | Grouped object ID/name catalog. Source parsing found 7,525 object rows in nine top-level categories. |
| `ob.lua.old` | Unloaded legacy snapshot; not part of the active manifest. |

The preview appears far above and offset from the local player's position. `changeobj()` assumes a selected row contains `ID:name`; it does not explicitly reject group headers or missing selection before parsing. Validate these UI paths during a later client review.

The normal Close button has cleanup for the preview/camera/cursor. The current script has no `onClientResourceStop` cleanup path, so a stop or restart while the browser is open may leave client camera/cursor state inconsistent. Issue #464 tracks a shared idempotent cleanup routine and a target-build check. MTA documents the client resource-stop event as the hook for handling resource shutdown: [OnClientResourceStop](https://wiki.multitheftauto.com/wiki/OnClientResourceStop).

## Discord and future interaction design

Discord roles should not be involved in a local, read-only object preview. If this catalog is later extended to create or edit world objects, route that operation through the owning server-side map/object resource and its existing approval, permission, dimension, collision, and persistence checks. The preview tool must not become an alternate authorization path.

## Follow-up

1. Add shared cleanup for Close and resource stop; verify camera/cursor behavior on the selected client build (#464).
2. Handle no selection and category-header selection explicitly; measure first-load duration with the complete 7,525-entry catalog.
3. Decide whether this remains a manual/developer utility or is operator-enabled in the importable server template; document its dependency and startup impact either way.
4. Keep `ob.lua.old` clearly archival or remove it only after source-history and packaging needs are reviewed.

No runtime behavior or startup availability is claimed as verified.
