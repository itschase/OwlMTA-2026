# `bone_attach`

## Status

- Active shared runtime library for attaching consumer-owned elements to player or ped bones.
- Full manifest, exported API, lifecycle, synchronization, and direct-consumer static review completed.
- The tracked startup snapshot enables the provider, but several consumers are listed before it and no readiness/version handshake exists.
- No database or file persistence is owned by this resource; attachment state is memory-only.
- Source-confirmed findings, proposals, and runtime-unverified behavior are separated below.
- No MTA server or tests were run.

## Purpose and active scope

The active manifest loads one server synchronization script, one client synchronization/render script, the shared attachment API in both realms, and client-only bone matrix helpers (`mods/deathmatch/resources/bone_attach/meta.xml:3-7`). It declares six attachment functions in both server and client realms plus one client-only bone-position function (`meta.xml:9-21`). There is no player UI, staff command, ACL decision, database table, save file, or durable record.

Server calls create synchronized attachments: the server stores the relationship and broadcasts it to clients. Client calls create local-only attachments, used for previews and client-rendered effects. On every client render frame, the library computes the selected bone matrix and updates the attached element's position and rotation. It also makes the element inherit the ped's interior, dimension, and alpha (`bone_attach_c.lua:52-105`).

## Exported API contract

| Export | Realm | Source-confirmed behavior |
|---|---|---|
| `attachElementToBone(element, ped, bone, x, y, z, rx, ry, rz)` | server/client | Requires valid elements, a `ped` or `player`, and bone 1-20. Offsets are converted with `tonumber` and default to zero. Stores the relationship, disables element collisions, broadcasts when called server-side, and returns `true`; invalid element/ped/bone returns `false` (`attach_func.lua:10-31`). |
| `detachElementFromBone(element)` | server/client | Requires a recorded attachment. Clears the relationship, unconditionally enables collisions, broadcasts when called server-side, and returns `true`; missing input/state returns `false` (`attach_func.lua:33-44`). |
| `isElementAttachedToBone(element)` | server/client | Returns whether the recorded parent still exists (`attach_func.lua:46-49`). |
| `getElementBoneAttachmentDetails(element)` | server/client | Returns `ped, bone, x, y, z, rx, ry, rz`, or `false` (`attach_func.lua:51-56`). The result describes the calling realm's local table. |
| `setElementBonePositionOffset(element, x, y, z)` | server/client | Reads the current details and re-runs attach with the new position offsets and existing rotation (`attach_func.lua:58-62`). |
| `setElementBoneRotationOffset(element, rx, ry, rz)` | server/client | Reads the current details and re-runs attach with existing position offsets and the new rotation (`attach_func.lua:64-68`). |
| `getBonePositionAndRotation(ped, bone)` | client only | Requires a valid, streamed-in player/ped and bone 1-20; returns world position and calculated rotation, otherwise `false` (`attach_func.lua:70-80`). |

The interface does not preserve original collision or alpha state, identify the owning consumer, constrain offset magnitude/rotation, version its schema, or return typed failure reasons. Although the first argument is described generically as an element, the render loop assumes that position, rotation, alpha, interior, dimension, and collision operations are appropriate for the supplied type.

## Synchronization and lifecycle

### Initial and ongoing synchronization

1. On client resource start, the client requests the current attachment tables (`bone_attach_c.lua:1-4`).
2. The server sends the eight server-side tables once per player and records `data_sent[client]` (`bone_attach.lua:4-19`). This path uses MTA's authenticated `client`; the request payload does not select another recipient.
3. The flag is removed on player quit (`bone_attach.lua:21-24`).
4. The client imports each relationship and disables collisions on the attached elements (`bone_attach_c.lua:6-20`).
5. Later server attach/detach operations broadcast `boneAttach_attach` and `boneAttach_detach` to all clients (`attach_func.lua:27-29,40-42`).

### Render behavior

For every recorded attachment, every client frame obtains the ped bone position/matrix, applies local position and rotation offsets, and writes the result to the attached element (`bone_attach_c.lua:60-94`). It then copies the parent interior, dimension, and alpha (`bone_attach_c.lua:96-105`). If the parent is not streamed in, it sets the attached element alpha to zero (`bone_attach_c.lua:106-108`).

### Cleanup

- Destroying the attached element clears its attachment record in the corresponding realm (`attach_func.lua:85-100`).
- A once-per-second coroutine clears records whose parent no longer exists (`attach_func.lua:102-117`).
- The client render path attempts to destroy the attached element when either side of the relationship becomes invalid (`bone_attach_c.lua:109-118`).
- There is no `onResourceStop` cleanup, provider generation, restart handoff, consumer replay, or re-registration mechanism.

Attachment tables are not persistent. If `bone_attach` restarts while a consumer remains running, the provider loses its records while consumer-owned objects and references can remain. The source contains no recovery path. Exact object visibility, collision, streaming, and resynchronization outcomes are runtime-unverified.

## Direct consumers

| Consumer | Realm and pattern | Lifecycle notes |
|---|---|---|
| `artifacts` | Server-created wearable objects attach from configured model/bone/offset data (`artifacts/s_artifacts.lua:47-84`). Property editing gets details, detaches, and reattaches (`:209-287`). | Removal and quit destroy the objects and rely on `onElementDestroy` cleanup (`:19-31,109-168`). The exposed artifact `alpha` property conflicts with the library's per-frame ped-alpha inheritance (`:218-220`). |
| `weapon` | Server creates synchronized weapon models (`weapon/attach/s_attach.lua:20-46`); the client editor creates local preview attachments (`weapon/attach/c_attach.lua:280-368,403-449`). | Character/logout/quit/vehicle/inventory paths destroy models (`s_attach.lua:55-127`). Remote authority and input validation are already tracked in Issue #289. |
| `phone` | Server model 330 is attached for phone animations (`phone/phone_core_s.lua:91-136`). | `destroyPhone` explicitly detaches and destroys (`:185-194`). The `phone_talk` branch contains the concrete typo described below. |
| `activities` snowballs | Server creates a snowball, attaches it to the right hand, detaches it before throwing, and destroys it on melt/change/quit (`activities/snowball/s_snowball.lua:6-82`). | Remote actor/trajectory validation belongs to the activity boundary under Issue #1. |
| `item-system` Christmas bottle | Server creates and attaches a bottle, then destroys it after five seconds (`item-system/s_item_system.lua:840-876`). | Destroy cleanup is relied upon instead of explicit detach; additional bottle cleanup exists at `s_item_system.lua:1289-1299`. |
| `dynamic_lighting_flash` | Client creates local flashlight-body objects for streamed players and attaches them locally (`dynamic_lighting_flash/c_shader_light.lua:54-63`). | It explicitly detaches/destroys during ordinary removal (`:66-75`) but does not rebuild existing `flModel` entries after a provider restart. |

`item-system/briefcase/briefcase_s.lua` also contains export calls, but it is not loaded by `item-system/meta.xml`. Current briefcase item handling routes through `artifacts`; the standalone briefcase script is dormant and must not be described as active.

## Staff and operator view

There are no staff controls. Operators enable/disable the resource as a shared dependency. The tracked `mtaserver.conf.bak` starts `item-system`, `artifacts`, and `phone` before `bone_attach`, then starts `weapon`, `activities`, and `dynamic_lighting_flash` after it (`mtaserver.conf.bak:161-175,216-217,241-243`). The inspected early consumers invoke exports during later player/session actions rather than directly on resource start, but this remains an implicit timing assumption. The backup is not proof of live order.

No consumer manifest declares a provider version/readiness dependency. Only the dormant briefcase code checks resource state. Active consumers generally ignore the boolean result from `attachElementToBone`, so an unavailable provider or rejected attachment can leave a consumer-created object tracked but unattached.

## Source-confirmed findings

1. **Provider restart has no reconciliation path.** No stop cleanup or generation/replay protocol exists. Provider state is memory-only while attached objects belong to consumers.
2. **Detach overwrites collision policy.** Attach forces collisions off and detach always turns them on (`attach_func.lua:24-25,37-39`), even when the element was intentionally non-collidable before attachment.
3. **Stream-out alpha is not restored by detach.** The renderer sets alpha to zero for an unstreamed parent (`bone_attach_c.lua:106-108`), while detach only clears state and enables collisions (`attach_func.lua:33-43`).
4. **Ped-alpha inheritance conflicts with consumer features.** `matchAlphas` overwrites the element alpha every frame (`bone_attach_c.lua:52-58,105`). This defeats artifact alpha customization, changes the flashlight body's requested alpha 254, and can undo weapon-model hiding performed after attachment.
5. **Destroyed-parent cleanup is inconsistent.** The periodic sweep only clears records (`attach_func.lua:102-117`), while the client render path tries to destroy the attached element (`bone_attach_c.lua:109-113`). It does not define whether the library or consumer owns orphan destruction, collision restoration, and cross-client notification.
6. **One client cleanup branch is broken.** `bone_attach_c.lua:114-117` checks `isElement(isElement)`, passing the function rather than `element`; it cannot perform the intended cleanup.
7. **Matrix singularities are not guarded.** Bone matrix calculation divides by vector lengths and `nz3` without zero/finite checks (`bone_pos_rot.lua:18-20,27-34`). Later code searches stringified numbers for the letter `a` as a NaN heuristic (`bone_attach_c.lua:86-94`), which is not a complete finite-number policy.
8. **Phone talk attaches the wrong variable.** The `phone_talk` branch creates `phoneO[source]` but calls `attachElementToBone(phoneO[element], source, ...)` (`phone/phone_core_s.lua:130-136`). `element` is not defined in that scope, so the library receives an invalid element and returns `false`; the caller ignores the result.
9. **Active consumers expose adjacent remote-boundary risks.** Weapon attachment remotes trust caller-selected source/weapon/bone/transforms; artifacts expose remove-all/toggle operations without full entitlement validation; snowball creation/throw trusts caller-selected player and trajectory. These are consumer authorization defects, not reasons to add authority policy inside the geometry library.

## Proposed direction

Define a versioned attachment record containing consumer ownership, supported element type, parent, bone, bounded finite offsets, original collision/alpha state, and explicit inheritance options. Make attach/detach idempotent and return structured failure results. Add a provider readiness/generation contract so consumers can replay attachments after restart or fail visibly and cleanly. Separate transform projection from optional alpha/interior/dimension inheritance rather than forcing every consumer into one visual policy.

Consumer fixes should remain bounded: correct `phoneO[element]` to the source-owned object and check the result; keep weapon authorization in Issue #289; bind artifact and snowball remotes to MTA `client` and validate entitlement/session state under Issue #1. The library itself should not infer inventory, staff, donor, or gameplay authorization.

## Existing tracker overlap

- **#310 — [Define a recoverable attachment lifecycle contract](https://github.com/itschase/OwlMTA-2026/issues/310):** owns provider readiness/restart, attachment cleanup, alpha/collision preservation, and matrix guards.
- **#311 — [Fix phone attachment state](https://github.com/itschase/OwlMTA-2026/issues/311):** owns the phone caller's undefined `element` key when attaching the active phone object.

- [Issue #289](https://github.com/itschase/OwlMTA-2026/issues/289), **Bind weapon attachment and utility remotes to live player state**, exactly owns the weapon consumer's source, inventory, model/bone/transform, rate, cleanup, and dependency-failure work.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1), **Audit and secure every remotely triggered server event**, is the umbrella for artifact and snowball caller binding. No focused `bone_attach`, artifact-attachment, snowball-attachment, or phone-attachment issue was found during the read-only search.
- [Issue #208](https://github.com/itschase/OwlMTA-2026/issues/208), **Version and test the global export contract**, partially overlaps readiness, deterministic failures, restart behavior, versioning, and contract testing, but its current scope/evidence centers on `global`; a focused attachment-lifecycle implementation slice would not duplicate the concrete findings here.
- [Issue #21](https://github.com/itschase/OwlMTA-2026/issues/21), **Reconcile active resource manifests with startup configuration**, owns dependency-safe startup ordering.
- [Issue #219](https://github.com/itschase/OwlMTA-2026/issues/219), **Restore or remove the missing shared weapon attachment definition**, owns the weapon editor's missing `attachments.xml`, not this library's runtime lifecycle.
- Documentation coverage remains under Issues [#7](https://github.com/itschase/OwlMTA-2026/issues/7) and [#95](https://github.com/itschase/OwlMTA-2026/issues/95).

## Runtime verification still required

On a pinned MTA build with disposable state, verify server/client attach-detach parity; late join; parent and child destruction; detach while the parent is streamed out; original collision/alpha restoration; invisible peds; interior/dimension changes; local versus server-created object destruction; provider stop/restart with every active consumer; phone in/talk/out transitions; artifact alpha and property edits; weapon model hiding; flashlight stream cycling; invalid element types/bones/NaN/Inf/large offsets; degenerate animations/skins; and attachment-count performance. None of these runtime checks was performed during this audit.
