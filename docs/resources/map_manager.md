# `map_manager`

## Status

- Active resource; full manifest, client/server workflow, command, permission, persistence, and direct `map_load` caller review completed.
- [Issue #62](https://github.com/itschase/OwlMTA-2026/issues/62) tracks the source-hardening implementation and remaining compatibility/runtime work.
- Runtime behavior is unverified. MTA was not started and no runtime tests were run for this review.
- Discussion: [Script Resource: map_manager](https://github.com/itschase/OwlMTA-2026/discussions/266).

## What it does

`map_manager` is the request and moderation front end for exterior maps. A mapper submits pasted `.map` XML and supporting metadata, follows the request through review, and can revise or withdraw an eligible request. Reviewers can browse requests, load a temporary client-side preview, record a decision, and implement or disable an accepted map through `map_load`.

Database state and `map_load` runtime state are distinct. Approval records a review decision; implementation is the separate action that loads the map and marks it enabled.

## Mapper workflow

1. Run `/maps` to open the map manager. This is the only loaded general-user command; the remainder of the mapper flow is already in the GUI.
2. Use **Exterior Map Addition Request** to enter the name, preview URL, purpose, affected users, reason, and pasted `.map` XML. The client parses the XML before submitting it.
3. The Issue #62 server path requires an authenticated account and bounded, non-empty metadata. It rejects empty, sparse, non-list, and oversized object collections and validates every field written to `maps_objects`: identifier type; interior/dimension; collision, breakability, and double-sided flags; radius; model/LOD; position/rotation; scale; and alpha. A non-map-admin account remains limited to one pending request.
4. Use **My Requests** to view status and details. The uploader may edit or delete only their own pending, disabled, unloaded request.

Uploader ownership is a local account/database relationship. It is not a global staff permission and must not be replaced by a Discord role.

## Moderator workflow and state model

The **Management** tab is visible under the legacy `canAccessMgmtTab` predicate to Supporters, Trial Admins, Scripters, and Mapping Team members. That provides browse/test access, not map moderation. The Issue #62 state-changing actions use the narrower `canAdminMaps` boundary: Scripter, Mapping Team member, or Head Admin.

| Action | Required local state and authority | Result |
|---|---|---|
| Browse/details | Management-tab access | Reads request metadata, objects, review note, reviewer, and status. |
| Test map | Management-tab access plus the self-review rule | Loads a temporary client preview through `map_load`; the GUI can unload one or all test maps. |
| Edit | Map moderation authority; pending, disabled, unloaded | Updates the request and records reviewer/note audit data. |
| Approve/decline | Map moderation authority; pending, disabled | Sets `approved` to `1` or `2`; it does not implement or delete the map. |
| Implement/disable | Map moderation authority; accepted and in the opposite enabled state | Reserves the new enabled state, changes `map_load` runtime state, then records the audit. Failures attempt checked database/runtime rollback. |
| Delete | Map moderation authority; disabled, unloaded | Deletes an eligible request and objects and writes a staff log, including disabled accepted or declined requests as supported by the GUI. |

An uploader cannot moderate or test-load their own request unless they are a Scripter or Mapping Team Leader. Server checks derive the actor from trusted MTA `client`, reload the target request, and enforce ownership, authority, review state, enabled state, and loaded state rather than trusting client identity or stale GUI state.

Displayed states are Pending (`approved=0`), Declined (`approved=2`), Accepted and Disabled (`approved=1, enabled=0`), and Accepted and Implemented (`approved=1, enabled=1`).

## Commands and GUI alternatives

The manifest loads `functions_g.lua`, `functions_s.lua`, `functions_c.lua`, `main_s.lua`, and `main_c.lua`. It declares no exports, settings, or dependencies.

| Command | Source-confirmed audience and task | GUI alternative |
|---|---|---|
| `/maps` | Authenticated player entry point for submissions, personal requests, and role-gated management. Registered client-side on resource start. | Opens the GUI; no separate non-command launcher is loaded. |
| `/exportinteriormap [Interior ID]` | Senior Admin or Scripter; exports interior objects and logs the action. | No equivalent map-manager GUI control is loaded. |
| `/exportexteriormap [Map ID from /maps]` | Senior Admin, Scripter, or Mapping Team Leader; exports a stored exterior request and logs the action. | The GUI can inspect/test but does not export XML. |
| `/convert_all_map_files` | Scripter only; legacy/bulk conversion with staff logging. | No GUI alternative is loaded. The follow-up retains the converter's legacy insert path, validates parsed rows, and honors its explicit higher object limit. |

## Persistence and dependencies

- `maps` stores metadata, uploader, type, upload date, review decision, enabled state, reviewer, and note.
- `maps_objects` stores rows by `map_id`, including placement, interior/dimension, model/LOD, collision/breakability/radius, double-sided state, scale, and alpha.
- The schema uses MyISAM and has no foreign keys. Request/object writes and runtime changes cannot be one atomic transaction.
- The follow-up checks every object-row insert before reporting success. On failure it attempts to delete all child rows and the parent and reports incomplete cleanup distinctly.
- Source calls `mysql`, `map_load`, `integration`, `global`, `cache`, `announcement`, and `logs`; client notification paths also interact with the surrounding HUD/event layer. These are source-observed dependencies, not manifest declarations.

## Source-confirmed residual risks

- Pending quota remains check-then-insert, so concurrent submissions can race.
- MyISAM prevents atomic parent/child persistence and atomic database/runtime deployment. Cleanup and rollback are checked and failures surfaced, but a recovery write failure can still require operator repair.
- `map_load:loadMap` treats an empty object result table as loaded, while `unloadMap` returns success even if no runtime map existed. These return values do not prove that clients rendered objects.
- Management read access exposes uploader/reviewer identities and internal notes to Supporters and Trial Admins under the legacy predicate.
- Export is not demonstrably round-trippable for every stored world/removal field, and the client save path assumes its target directory exists.

## Discord authorization boundary

No Discord authorization is implemented. A future global grant such as `maps.moderate` could adapt to `canAdminMaps`, but must remain separate from local uploader ownership, request state, loaded state, and self-review exceptions.

A donor or Supporter role must not imply moderation. Source allows Supporters through the browse/test predicate but excludes them from approval, decline, edit, implement, disable, and moderator delete. Future view/test and moderation grants should remain separate, with all local checks still enforced by the MTA server.

## Issue #62 evidence and remaining verification

The current source changes bind remote events to `client`, validate persisted object fields, reject sparse/oversized collections, separate uploader and moderator operations, recheck request and runtime state, parameterize remote SQL paths, check each object insert, preserve converter entry points, record review audit context, log moderator deletion, and check cleanup/rollback outcomes. They remain runtime-unverified.

This is static source and diff evidence only. Runtime verification remains outstanding for role and self-review boundaries; malformed, sparse, oversized, and optional-field submissions; concurrent quotas and stale actions; forced parent/child/cleanup failures; approval transitions; empty-object load results; deployment rollback; staff logging; converter throughput; export/import round trip; and restart consistency.
