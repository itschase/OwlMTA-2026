# `dynamic_lighting` resource (archived copy)

**Review state:** Archived manifest and file-level comparison against the active resource. This is not a player-available feature while stored under `mods/deathmatch/resource-archive/`. Runtime and historical deployment are unverified.

## Source identity

- Archived manifest: `mods/deathmatch/resource-archive/dynamic_lighting/meta.xml`
- Active counterpart: `mods/deathmatch/resources/dynamic_lighting/meta.xml`
- The archive has nine files versus eight in the active copy. The archive includes `readme.txt` and `debug_g.lua`; the active manifest does not load the archived debug script.
- Five shared files differ: `c_main.lua`, `c_helper_functions.lua`, `c_exported_functions.lua`, `meta.xml`, and `shaders/common.txt`.

## Difference from the active resource

The archived manifest identifies version 1.5.3; the active manifest identifies 1.5.8. The active copy adds dimension/interior-aware lighting behavior and expanded dimension/interior getter/setter exports. Do not use the active dossier as proof that the archived copy supports those features, or merge the two implementations without a compatibility review.

## Intended role and audiences

The source is a client-side dynamic-lighting provider built around shader resources and exported helpers. Any player-visible effects are rendered locally through client resources. No player command, account persistence, or staff authority was identified in the compared manifest. Operators should treat this as historical code pending a full archive-specific manifest and caller audit; do not start it alongside the active resource under the same resource name.

Discord roles should not control ordinary visual rendering. If future staff tooling exposes lighting diagnostics, gate that action through the appropriate server-side capability and retain local target/state checks.

## Documentation boundary

This dossier records the archive identity and differences only. It does not claim a complete audit of every archived script, original deployment configuration, or current compatibility with MTA. The active resource's behavior is documented separately at [`../dynamic_lighting.md`](../dynamic_lighting.md) when available.
