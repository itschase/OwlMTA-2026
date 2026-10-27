# `artifacts` resource

**Review state:** Full manifest-script and direct-caller source review. Runtime, asset, and gameplay behavior remain unverified.

## Purpose and player use

`artifacts` attaches non-clothing objects—such as helmets, gas masks, protective vests, bags, fishing rods, briefcases, shields, and seasonal wearables—to a player model. It is a visual/equipment layer shared by `item-system`, fishing, vehicle-crash realism, character creation, and administration workflows. The resource does not itself own or persist inventory records.

Most players wear or remove these objects by using an inventory item. The fishing job also asks the server to attach a rod when the client begins the activity. `/myartifacts` prints the names and count of objects currently attached. `/removeartifacts` clears all attachments from the caller; it does not remove the corresponding inventory entries.

## Current commands and interaction opportunities

| Command | Current behavior | Audience/use case | Future interface to evaluate |
|---|---|---|---|
| `/myartifacts` | Prints artifact IDs and a count to chat | Player status lookup; useful for confirming what is visually attached | Show readable item names, worn state, and relevant context in an inventory/appearance panel; retain a command/search shortcut |
| `/removeartifacts` | Removes every attached artifact on the caller and prints a count | Player cleanup/recovery shortcut | Provide per-item removal and a clear bulk cleanup control in an appearance panel; preserve the command alias for recovery |

The alternatives are proposals, not implemented UI. Future resource reviews should make the same audience/use-case/interface comparison for every command they find. See [`../planning/COMMAND_AND_INTERACTION_STRATEGY.md`](../planning/COMMAND_AND_INTERACTION_STRATEGY.md).

## Staff and operator use

There is no dedicated staff UI or permission-aware configuration in this resource. The `removeAllOnPlayer` event is called from character lifecycle code and admin recon (`account/s_characters.lua`, `admin-system/Player/s_recon.lua`). These are server-internal workflows. The resource registers that event for remote triggering as well, so its trust boundary must distinguish authenticated internal resource calls from player-originated event calls.

Operators must start `bone_attach` for synchronized attachments and retain the model files declared by this resource's manifest. If `item-texture` is running, artifact texture data is sent through that resource; otherwise ordinary artifact models still attach. No resource settings, database schema, or external service configuration are declared.

## Discord capability classification

Ordinary item wear/removal and fishing-rod presentation should be authorized by the server-owned inventory or active job workflow, not by a global Discord staff role. The account character-switch cleanup is a lifecycle action and should not need Discord. Recon-driven removal is a staff workflow: its capability belongs at the recon/admin action boundary in `admin-system`, then the server may call a trusted internal cleanup function. The artifacts utility itself should not become a general staff authorization service. No artifact-specific donor entitlement was confirmed in this audit; if supporter cosmetics are introduced, use the adapter's separate donor-tier result and keep it distinct from moderation capabilities. Role IDs are not defined in this resource.

The eventual call path should use the reusable [MTA Discord Identity adapter](https://github.com/itschase/mta-discord-identity) through an Owl-side authorization facade. The plugin's server-side `hasCapability` export answers only the global grant question; inventory ownership, job state, player identity, and local authorization still require their own checks. Current Owl source is not integrated with that plugin, and no capability gate is fixed or runtime-verified here.

## Technical map and connections

- Manifest: [`meta.xml`](../../mods/deathmatch/resources/artifacts/meta.xml) loads `s_artifacts.lua`, `g_artifacts.lua`, `c_artifacts.lua`, and `c_replace.lua`; it declares model, shader, and texture files.
- Artifact definitions: `g_artifacts` maps string IDs to model, bone, transform, scale, double-sided, and optional texture data (`g_artifacts.lua`).
- Server lifecycle: `s_artifacts.lua` creates and attaches objects, keeps transient `artifacts[player]` and `artifactsList[player]` tables, cleans up on quit/character change, and exposes query/property functions.
- Attachment provider: the server consumes `bone_attach:attachElementToBone` and related exported functions. See [`bone_attach.md`](bone_attach.md).
- Inventory callers: `item-system/s_item_system.lua` toggles or adds artifacts after item workflows; `item-system/s_world_items.lua` removes artifacts while dropping items. Several call sites pass the owning player and artifact ID through internal `triggerEvent` calls.
- Fishing caller: `job-system/fishing/c_fishing_job.lua` remotely requests `rod` add/remove when starting or stopping the fishing workflow.
- Other callers: `account/s_create_character.lua` equips a briefcase; `account/s_characters.lua` clears artifacts during character change; `admin-system/Player/s_recon.lua` clears a target's attachments; `realism/s_vehicle_crash.lua` changes helmet artifacts around crash/equipment behavior.
- Exports: `getArtifacts`, `countPlayerArtifacts`, `getPlayerArtifacts`, `isPlayerWearingArtifact`, and `setPlayerArtifactProperty` are declared for server use; `getArtifacts` is also declared client-side.

## Persistence and lifecycle

The resource's worn-object maps exist only in server memory; no artifact wearing state is written to a table here. Durable item ownership and item use belong to `item-system` and its schemas/callers. On quit or character change, attached objects are destroyed. The attachment provider separately records and synchronizes the bone relationship.

The server does not check whether `createObject` succeeded before applying scale/flags or attaching the result. The client texture handler creates shaders and textures without checking each returned handle or tracking them for deterministic destruction. These are failure/recovery and resource-lifecycle concerns, not verified runtime leaks.

## Source-confirmed findings and tracking

- **Unbound bulk-removal event.** `artifacts:removeAllOnPlayer` is remotely enabled and passes its payload player directly to `removeAllOnPlayer`; unlike add/remove, it has no `client`-to-target check. The handler destroys every tracked artifact on the supplied player. Runtime event exploit behavior has not been demonstrated. See proposed [Issue #324](https://github.com/itschase/OwlMTA-2026/issues/324).
- **Wear events do not prove an item or job entitlement.** `artifacts:add` restricts a remote caller to its own player, but accepts any defined artifact ID without checking server inventory ownership or a validated job session. The fishing client uses the same remote event to request a rod. This is an authority/workflow defect at the boundary between appearance and inventory/job state. See [Issue #325](https://github.com/itschase/OwlMTA-2026/issues/325).
- **Empty bulk cleanup dereferences a missing list.** `/removeartifacts` evaluates `#artifactsList[player]` before calling cleanup. When the player has no list entry, the expression applies the length operator to `nil`; provide a zero-count path. See [Issue #326](https://github.com/itschase/OwlMTA-2026/issues/326).
- **Creation/texture failure state is not explicit.** `createObject`, attachment exports, client shader creation, and texture creation results are not handled consistently. Add bounded diagnostic records and recoverable no-object/no-texture behavior after the desired degraded behavior is defined. Shared attachment failure contracts overlap [Issue #310](https://github.com/itschase/OwlMTA-2026/issues/310).
- **Client texture handles are not retained for cleanup.** The client creates one shader and texture per requested entry, discards the handles, and has no per-object release path. See [Issue #330](https://github.com/itschase/OwlMTA-2026/issues/330); memory impact remains unmeasured.
- **Wear limit is only a TODO.** Source comments mention limiting artifacts per bone, but the current logic permits any combination not already duplicated by artifact ID. Whether restrictions are desired is a gameplay design decision, not an existing defect.

The calls to `artifacts:add` and `artifacts:remove` are protected against a remote player selecting a different target by `if client and player ~= client then return`. That check does not establish item ownership. Donor, staff, and GameMaster policy does not belong in this cosmetic resource; capabilities should remain separately defined and configured.

## Modernization opportunities

- Define a shared server-owned wear operation that validates item ID, character, inventory ownership/consumption, and job-specific authorization before changing appearance.
- Use a single per-player artifact lifecycle record with idempotent equip, unequip, character-switch, quit, and resource-restart behavior; reconcile visuals from authoritative inventory state after a provider restart if needed.
- Add an appearance/inventory panel that lists owned wearable items, current attachment state, contextual eligibility, and per-item remove action. Offer a guarded emergency clear action and keep `/myartifacts` and `/removeartifacts` aliases until the panel is proven usable.
- Track and destroy client shader/texture handles; handle object/export failure without leaving partial state; provide rate-limited operator diagnostics with resource, artifact ID, and failure stage.
- Define which equipment is cosmetic and which changes gameplay consequences. Keep armor, law-enforcement equipment, job tools, and supporter cosmetics under separate authoritative policies.

## Runtime verification still required

After the static review and safe-start gates, verify item ownership and job eligibility for every remote equip path; unauthorized target removal attempts; empty and non-empty `/removeartifacts`; character switch, quit, recon, crash, item drop/use, and resource restart; unavailable `bone_attach`/`item-texture`; invalid model/texture files; simultaneous equip/unequip requests; and whether client-created texture handles are released. Record the MTA build and distinguish expected legacy behavior from proposed changes. No server or tests were run for this review.
