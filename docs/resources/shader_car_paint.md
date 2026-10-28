# Vehicle Paint Shader

**Resource:** `shader_car_paint`

**Review state:** Active manifest, client script, effect files, F10 setting flow, and direct caller reviewed statically. Runtime and graphics-device behavior are unverified.
**Tracking:** Issues [#509](https://github.com/itschase/OwlMTA-2026/issues/509)–[#510](https://github.com/itschase/OwlMTA-2026/issues/510), assigned to `itschase` in [Milestone #7](https://github.com/itschase/OwlMTA-2026/milestone/7). Individual resource Discussion: [#511](https://github.com/itschase/OwlMTA-2026/discussions/511).

## Purpose and player use

This optional client graphics resource applies a layered car-paint effect to matching vehicle textures. Players toggle it from **F10 → Graphics → Enable vehicle shader**. The resource does not add a chat command, staff control, in-character permission, or server-side gameplay action.

## Source flow and components

`meta.xml` runs `c_car_paint.lua` client-side and packages `car_paint.fx`, `mta-helper.fx`, `images/smallnoise3d.dds`, and `images/cube_env256.dds`.

On resource start the script calls `update()`. It enables the effect for every local-player setting value other than the string `"0"`. The directly connected caller is `account/f10-settings/c_f10_settings.lua`: `applyGameSettings` sets local element data and triggers the local event `accounts:settings:graphic_shaderveh` both when an account setting is applied and when the F10 checkbox changes. That local event triggers another `update()`.

The enabled path creates a shader from `car_paint.fx`, creates a volume noise texture and cube reflection texture, binds them as `sRandomTexture` and `sReflectionTexture`, and applies the shader to world texture names `vehiclegrunge256` and `?emap*`. It does not pass a target vehicle to `engineApplyShaderToWorldTexture`, so the matching texture replacement is broad within that client's world. The effect has a normal car-paint technique and a plain fallback technique.

There is no schema, server script, resource export, or server permission declaration in this resource manifest. The F10 account settings resource owns preference application and persistence; this shader resource consumes the resulting client-side setting/event. It does not change a vehicle's stored paint, owner, handling, or server state.

## Staff and operator use

No staff-only or GameMaster action is present. An operator should deploy the full manifest-listed script, shader helper, and image assets together. The client graphic preference is independent of Discord or staff roles. Visual appearance, hardware compatibility, failure conditions, resource ordering, and GPU memory usage have not been checked in a running MTA client.

## Findings and follow-up

- [Issue #509](https://github.com/itschase/OwlMTA-2026/issues/509) covers repeated enabled updates creating new shaders, texture elements, and timers while replacing the stored references; it also tracks safe partial-initialization and cleanup behavior.
- [Issue #510](https://github.com/itschase/OwlMTA-2026/issues/510) covers the repeating `getWaterColor()` call that writes to `gVehicleColor`. Neither the active effect nor its helper declares or consumes that parameter, and the return value of `dxSetShaderValue` is ignored. Remove the apparent leftover or define a real consumed effect parameter.

The MTA Wiki describes [`dxSetShaderValue`](https://wiki.multitheftauto.com/wiki/DxSetShaderValue) as setting a named shader parameter and returning whether it succeeded. [`dxCreateTexture`](https://wiki.multitheftauto.com/wiki/DxTexture) creates texture elements that can be supplied to shader parameters. The source has a fallback effect technique, but that alone does not prove the shader compiles or displays correctly on current MTA clients.

## Runtime verification

After the repository's static safe-start review is complete, verify the shader on a disposable server/client and suitable hardware. Exercise persisted setting application, repeated enable calls, disable after successful and partial initialization, resource stop, GPU/resource failures, texture scope on different vehicles, and the effect's visual output. Confirm no timers, textures, or world-texture applications remain after disabling. Do not describe these behaviors as runtime-tested until checked in MTA.
