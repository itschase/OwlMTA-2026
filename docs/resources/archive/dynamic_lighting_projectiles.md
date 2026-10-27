# `dynamic_lighting_projectiles` resource (archived)

**Review state:** Archived client script and manifest reviewed. This resource has no active-tree counterpart and no direct caller was found. It is not a current gameplay feature while stored under `mods/deathmatch/resource-archive/`; any runtime behavior is unverified.

## What the archived resource describes

The manifest loads one client script, `c_projectileLight.lua`, and declares no exports. Its README describes visual light effects for firing weapons, thrown molotovs, and vehicle explosions, using the separate `dynamic_lighting` client API. It notes limitations for minigun and flamethrower effects. No player command, account persistence, or staff tool is declared.

## Source connections and operation

- It is intended as a client-side visual consumer of `dynamic_lighting`.
- No active-tree caller or same-named active resource was found during repository search.
- The archive includes a historical README and version 1.0.5 manifest. Neither proves that it was ever deployed or remains compatible with current MTA.
- If revived, it should be treated as optional presentation. Discord staff or supporter roles should not gate ordinary projectile effects.

## Source-confirmed cleanup defects

- The resource-stop cleanup path calls `destroyLight(...)` directly, but the archived source does not define that function. The light provider is a separate resource; teardown should use its corresponding export and handle provider-unavailable behavior.
- The player-quit handler indexes `shotLiTable[this]` even though the event handler's player is `source`; `this` is not the event actor in this code path.

These defects are tracked as archive-revival requirements in [Issue #391](https://github.com/itschase/OwlMTA-2026/issues/391). They are findings in archived code, not claims that current players are affected.

## Revival checklist

Before reusing the resource, identify current event semantics for projectile creation/destruction, map every created light to its owner/projectile, clean up on player quit/resource stop/provider stop, bound per-player effect counts, and verify consumer start order. Test weapon, thrown-object, explosion, reconnect, and resource-restart cases on a disposable MTA server. No runtime test was run.
