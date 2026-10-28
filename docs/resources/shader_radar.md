# Radar Shader

**Resource:** `shader_radar`

**Review state:** Active client manifest, renderer, effect, settings controls, persistence paths, and event callers reviewed statically. Runtime, visual output, memory use, and frame cost are unverified.
**Tracking:** Issues [#514](https://github.com/itschase/OwlMTA-2026/issues/514)–[#516](https://github.com/itschase/OwlMTA-2026/issues/516), assigned to `itschase` in [Milestone #7](https://github.com/itschase/OwlMTA-2026/milestone/7). Individual resource Discussion: [#517](https://github.com/itschase/OwlMTA-2026/discussions/517).

## Purpose and player use

`shader_radar` replaces visible GTA radar-map textures with packaged image frames. Its client render handler finds visible texture names matching `radar??` and `radar???`, uses up to six shader slots, and maps each texture name to an image under the resource's `radar/` directory. The handler returns while the full-screen map is open.

The player can change the effect through two existing settings surfaces:

- The older Graphics options checkbox stores `enable_radar_shader` in the account resource's client XML settings.
- F10 → Graphics → Enable radar shader stores the `graphic_shaderradar` account preference through `account/f10-settings`.

The shader enables only when the saved client option numerically equals `1` and local-player element data `graphic_shaderradar` is not the string `"0"`.

## Implementation and connections

`meta.xml` loads only `c_radar.lua` as a script, includes `radar.fx`, and declares 144 JPEG frames (145 file assets total). The effect is a texture replacement shader with a simple technique. There is no server script, database schema, command, export, staff permission, or GameMaster workflow.

The renderer obtains visible texture names through MTA's `engineGetVisibleTextureNames`, creates each corresponding image with `dxCreateTexture`, sets it on a shader slot as `Tex0`, and applies the shader to that visible texture. It keeps a Lua-side map of shader slots and a texture cache keyed by the visible texture-name string.

The resource reads the legacy preference through the client export `account:loadSavedData`. This is an implicit account-resource dependency; `shader_radar/meta.xml` does not declare it. It reevaluates after a 2.5-second resource-start timer and on the account character-spawn event. The F10 `applyGameSettings` branch for `graphic_shaderradar` has its intended shader event trigger commented out, and the legacy checkbox only writes its saved setting. Source therefore indicates checkbox changes may not refresh the effect until another evaluation.

## Staff and operator guidance

No staff role or Discord authorization should gate this cosmetic client effect. Operators need to deploy the Lua script, shader, and all 144 frame assets. The account resource must be available for its saved-setting export. The code fixes the render slot count at six; whether that covers every MTA client/map state must be checked in-game.

## Source findings

- [Issue #514](https://github.com/itschase/OwlMTA-2026/issues/514) covers immediate refresh from the legacy and F10 settings flows and the interaction between their two stored toggles.
- [Issue #515](https://github.com/itschase/OwlMTA-2026/issues/515) covers cleanup of the name-keyed DX texture cache. The current `ipairs` traversal cannot visit its string keys; the comparison uses an integer index against a texture-name string, and `found` is a non-local that is not reset per cache entry.
- [Issue #516](https://github.com/itschase/OwlMTA-2026/issues/516) covers unchecked shader/texture creation, shader-value assignment, world-texture application, and partial cleanup after failed initialization.

The MTA Wiki states that [`engineGetVisibleTextureNames`](https://wiki.multitheftauto.com/wiki/EngineGetVisibleTextureNames) returns visible world texture names matched by wildcard, [`dxCreateShader`](https://wiki.multitheftauto.com/wiki/DxCreateShader) can fail and returns `false`, and [`engineApplyShaderToWorldTexture`](https://wiki.multitheftauto.com/wiki/EngineApplyShaderToWorldTexture) returns a boolean and applies to all matching textures when no target element is supplied. Those API contracts inform the source findings; they do not establish runtime impact.

## Runtime verification

After the documented static safe-start review, use a disposable MTA client/server to check: both preference controls after login and during a session; resource start/stop and character changes; map open/close; visible radar names and whether six slots cover them; missing/failed shader or image initialization; texture-cache size after moving through the map; GPU memory and frame cost; and cleanup after toggles and resource stop. Do not claim visual or performance results until actually observed.
