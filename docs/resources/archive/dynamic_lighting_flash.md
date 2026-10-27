# `dynamic_lighting_flash` resource (archived copy)

**Review state:** Archived manifest and shared-file comparison against the active resource. The archived resource is not a live player feature while under `mods/deathmatch/resource-archive/`; no runtime behavior is verified.

## Source identity

- Archived manifest: `mods/deathmatch/resource-archive/dynamic_lighting_flash/meta.xml`
- Active counterpart: `mods/deathmatch/resources/dynamic_lighting_flash/meta.xml`
- The archive has fifteen files versus twelve in the active copy. It retains `readme.txt` and flashlight TXD/DFF assets that are absent from the active tree.
- Shared `c_shader_light.lua` and `meta.xml` differ.

## Difference from the active resource

The archived client shader contains a different implementation, and the old manifest declares/downloads flashlight model assets. The active copy removes engine model-replacement calls and no longer uses the legacy `dynamic_lighting_nighttime_only` toggle condition. Consult [`../dynamic_lighting_flash.md`](../dynamic_lighting_flash.md) for the active player's flashlight workflow; do not assume the archived model and rendering behavior matches it.

## Intended role and audiences

This is historical client/server flashlight code with shaders, battery scripts, and a light-switch sound. The compared manifest indicates a player equipment feature, not a staff tool. No archival-only database or staff control was established by this comparison.

The current identity design keeps ordinary flashlight use independent of Discord staff and supporter roles. Any future moderation action should use a narrowly named staff capability and preserve item ownership, actor, and world-state validation.

## Documentation boundary

This is an archive comparison, not a complete caller, schema, or compatibility review. Archived deployment and MTA runtime behavior are unknown. Do not run both same-named implementations together.
