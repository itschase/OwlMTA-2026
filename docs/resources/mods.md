# `mods`

## Status and evidence

- Resource path: `mods/deathmatch/resources/mods`.
- Source review: both client scripts, manifest, and Verona Mall server script reviewed; model callers, collision/visual behavior, and runtime are not verified.
- Runtime: unverified. The MTA server has not been started for this review.
- Startup snapshot: enabled in `mtaserver.conf.bak`; snapshot only.
- GitHub record: Script Resources Discussion pending; FPS state defect tracked by [Issue #459](https://github.com/itschase/OwlMTA-2026/issues/459), assigned to [Milestone #7: Resource Audit and Security Baseline](https://github.com/itschase/OwlMTA-2026/milestone/7).

## Purpose in everyday terms

`mods` is a bundle of client-side replacements for GTA models, textures, and collision data, plus `/showfps`, a client FPS overlay. Its assets affect the shared look of the world and vehicles, while the FPS command also currently changes a gameplay setting at low frame rates. A server script contains Verona Mall world edits, but its activation hook is commented out.

## Player and operator use

- Model/texture/collision replacements apply automatically when the client resource starts. The manifest includes vehicles (including emergency vehicles), objects/walls, items, map parts, textures, and a few disabled/commented legacy assets.
- `/showfps` toggles a local FPS counter.
- Below 20 FPS, the FPS sampler disables the local ped's ability to be knocked off a bike. When the display is switched off during this override, the timer is killed without restoring that setting. Issue #459 tracks removing or safely separating this gameplay side effect.
- The Verona Mall server script defines world-model removal and replacement object creation at a map coordinate, but both the `doMallMapping` wrapper and its `onResourceStart` registration are commented. Those edits do not run from the current script as written.

The displayed FPS is approximate: `countFPS` increments once per render frame, while a one-second timer copies and resets the count. It draws the previous sample, so initial output and transition timing need live-client verification.

## Resource and data flow

| File | Role |
|---|---|
| `c_mods_system.lua` | Loads and applies model, TXD and COL replacements on client resource start. |
| `c_show_fps.lua` | Registers `/showfps`, attaches/removes a render handler, and runs a one-second sample timer. |
| `s_mall.lua` | Defines Verona Mall world-model removal and object creation, but has no active startup call. |
| `meta.xml` | Declares two client scripts, the server script, and downloadable assets. |

`applyMods()` is called immediately and again once after one second. Both invocations traverse the full large replacement list. The reason is not documented. It creates a redundant second load/replace pass and should be checked against the target MTA build before retaining or removing it; no runtime conclusion is asserted here.

The client loader does not check most `engineLoad*`, `engineReplace*`, `engineImportTXD`, or `engineSetModelLODDistance` results and has no structured per-asset diagnostics. Use the model-system dossier and Issue #458 as the related diagnostic pattern, while tracking this resource's larger asset list separately if implementation is scheduled.

## Discord, authority, and future interaction

There is no staff authorization surface in the active client loader. Discord roles should not govern client model presentation. Server-operator configuration for enabling/disabling replacement groups belongs in a validated local configuration layer, with client delivery still mediated by resource manifests. A future contextual interface should call the owning gameplay resource for a vehicle, item, or world interaction; it should not grant actions through this asset bundle.

## Follow-up

1. Resolve Issue #459 and test bike knock-off state across low/high FPS, toggle-off, and resource stop.
2. Verify whether the delayed second `applyMods()` pass is still required; consolidate to one controlled load pass if not.
3. Audit each active model/TXD/COL pairing against its consuming systems and verify overlapping replacement ownership (including `model-system`).
4. Decide whether the commented Verona Mall mapping should remain dormant, be restored intentionally, or be removed after map-owner confirmation.
5. Add per-asset load/replace diagnostics and validate manifest/file correspondence.
6. Exercise resource start/stop/restart and collision/model appearance in a controlled client/server session after safe-start preparation.

No runtime behavior is claimed as verified.
