# `model-system`

## Status and evidence

- Resource path: `mods/deathmatch/resources/model-system`.
- Source review: complete for the one client script and manifest assets; external model-ID callers and visual behavior still need runtime verification.
- Runtime: unverified. The MTA server has not been started for this review.
- Startup snapshot: enabled in the tracked `mtaserver.conf.bak`; this is not proof of live configuration.
- GitHub record: Script Resources Discussion pending; loader diagnostics tracked by [Issue #458](https://github.com/itschase/OwlMTA-2026/issues/458).

## Purpose in everyday terms

This resource changes selected GTA object models on each client. It loads replacement textures (TXD) and geometry (DFF), then assigns them to existing GTA model IDs. It does not create objects or decide who may use them; gameplay resources create/use the IDs, while this resource supplies their appearance.

## Active replacements

The resource-start handler in `replace.lua` currently attempts these replacements:

| Model ID | Loaded texture | Loaded model | Source comment/use hint |
|---:|---|---|---|
| 1575 | `cocaine.txd` | `cocaine.dff` | Cocaine bag/object asset |
| 1579 | `cocaine.txd` | `cocaine.dff` | Cocaine bag/object asset |
| 3044 | `mari.txd` | `cocaine.dff` | Texture/model pairing needs visual confirmation |
| 1576 | `pill.txd` | `pill.dff` | Drug pill |
| 2886 | `laptop.txd` | `laptop.dff` | Laptop |
| 300 | `dog.txd` | `dog.dff` | Comment identifies PD dog |
| 2351 | `labrador.txd` | `labrador.dff` | Comment identifies player dog |
| 433 | `enterable-barracks.txd` | `enterable-barracks.dff` | Barracks object |

The comments identify intended themes but do not prove which gameplay systems instantiate each ID. The `3044` texture/model pairing may be intentional; confirm in-game and with model previews before changing it.

## Resource and data flow

`meta.xml` starts `replace.lua` client-side and declares the active TXD/DFF files for download. On `onClientResourceStart` for this resource, the script loads each TXD, imports it for an ID, loads the DFF, and calls `engineReplaceModel`. There are no server scripts, commands, remote events, database writes, or declared dependencies. The client replacement is presentation; authority and object creation belong to the consuming gameplay resources.

Several replacement blocks (sniper, suitcase, ATM, TV, cellphone) are commented out, and their manifest file entries are also commented. `horse.dff` and `horse.txd` are present in the folder but are not declared in the manifest or referenced by the active script. Treat these as dormant/unintegrated assets, not active features.

## Operator and development notes

- Keep the resource started before dependent gameplay resources need these visuals; confirm actual startup ordering in the live server configuration.
- The handler does not check whether `engineLoadTXD`, `engineImportTXD`, `engineLoadDFF`, or `engineReplaceModel` succeeds and emits no resource-specific diagnostic. A missing/corrupt asset or invalid ID can therefore leave an incomplete replacement without a useful local log. Issue #458 tracks adding per-ID load/import/replace checks and actionable debug output.
- MTA documents that `engineReplaceModel` returns a boolean and that `engineRestoreModel` restores a model's default visual DFF. Explicit stop/reload cleanup and interaction with other model-replacement resources should be settled during implementation and runtime validation; current source contains no cleanup handler.
- Preserve the declared downloadable assets when editing the manifest. Remove dormant files only after confirming no deployment packaging or external resource depends on them.
- Future model additions should be data-driven, validate manifest/file correspondence, and log model ID plus asset name on failure. Avoid changing model IDs based only on filenames.

## Discord, commands, and contextual interaction

There is no permission surface in this resource, so Discord roles should not authorize model replacement here. Any future operator model-management UI should invoke a narrow local server/operator capability and validate the configured model/asset catalog; player access to objects remains governed by the resource that owns the gameplay action. A third-eye interaction might expose the laptop, drug-package, dog, or barracks actions provided by their owning systems, but those options and permissions do not belong in this visual asset loader.

## Validation still required

1. Confirm each active ID's intended asset using model preview or an isolated client session.
2. Check TXD/DFF load, import, replace, and resource-stop/restart behavior on the target MTA build.
3. Trace active IDs to their object creation/use callers and test ordering with the actual startup configuration.
4. Decide whether dormant assets should be restored, removed, or retained as documented archive material.

No runtime behavior is claimed as verified.
