# `clubtec` resource

**Review state:** Full manifest-script and direct-caller source review. MTA item, shader, GUI, and restart behavior remain runtime-unverified.

## Purpose and player use

`clubtec` implements a world-placeable VS1000-style video player (item type `166`) that can contain video-disc items (type `165`). A player uses the world-object right-click menu to open **Control** or **Eject disc**. The control panel can switch power and edit texture/shader values. `fakevideo` consumes the saved player/disc state to render the screen texture for clients.

The server currently exposes all adjustment controls in the client panel; the former `isClubtecGuy` UI guard is commented out. The exact intended audience for advanced adjustments is not established in active source, so do not infer a technician-only rule. Disc insertion/storage and player item persistence are delegated to `item-system` and `item-world`.

## Commands, staff, and Discord authorization

`/tempvsspawn` is the only command in the reviewed server script. It grants a video-player item to a logged-in local scripter through `integration:isPlayerScripter`; command registration also uses the restricted ACL option. This appears to be a developer/operator spawn helper, not a normal player or global staff command. The `clubTecChars` name table is unused in the current predicate.

Ordinary player interaction with a video player should follow local world-item and gameplay rules, not Discord staff roles. The temporary spawn helper should retain its explicit local operator/scripter boundary unless a separate design intentionally replaces it. Supporter/donor entitlement is not relevant. No direct Discord client, role ID, or external API exists here.

## Technical map and connections

- `meta.xml` loads shared item definitions into both client and server contexts, a protected client GUI, and `s_clubtec.lua`. It exports helper functions for current disc, item types, and scripter checks; declares minimum MTA version `1.3.0-9.05000`.
- `g_clubtec.lua` defines item IDs and default shader settings. `isVideoPlayer` checks that an element is an item-world object with item ID `166`; `isVideoDisc` tests item IDs against the disc set.
- `object-interaction/c_objects_rightclick.lua` supplies the normal **Control** and **Eject disc** UI for item ID `166` and triggers ClubTec network events.
- `s_clubtec.lua` reads the inserted disc via `item-system`, loads GUI data, moves ejected discs, toggles the persisted power flag, and writes texture/shader settings through `item-world` exports.
- `c_clubtec.lua` builds the panel and sends power/eject/settings requests. Its current settings UI includes texture, brightness, speed, offsets, scaling, rotation, alpha, grayscale, and RGB adjustment fields.
- `fakevideo/s_fakevideo.lua` scans world video players in a dimension, reads the current disc/texture/shader values, and prepares animated-texture state for clients.
- ClubTec owns no explicit SQL query, dedicated table, or external endpoint. Persisted item state belongs to the connected world-item/item systems. Exact schema and restart behavior should be verified against those resources and the current database import.

## Source-confirmed findings and tracking

- **Remote item actions lack consistent caller/target checks.** `s_clubtec.lua:39-63` accepts a target element for disc ejection, reads its contents, and moves a disc to the authenticated caller without checking actor/target association, distance, dimension/interior, or current interaction eligibility. Power, GUI, and update handlers also trust a supplied target element without a complete authorization path. See [Issue #367](https://github.com/itschase/OwlMTA-2026/issues/367). This is a source trust-boundary finding, not a demonstrated live-server exploit.
- **Settings payloads are not schema-validated.** `s_clubtec.lua:80-144` assumes a table, consumes client values, and can persist texture/shader settings without explicit type, range, or size checks. See [Issue #368](https://github.com/itschase/OwlMTA-2026/issues/368). Determine supported shader ranges and texture identifiers before implementing the schema.
- **Temporary spawning is tied to current local scripter policy.** `g_clubtec.lua:21-25` checks login and `integration:isPlayerScripter`; do not infer a Discord role mapping from the old `clubTecChars` list or from command visibility.

## Modernization opportunities

- Centralize validation for all ClubTec server events: actor, target type/ID, active world-item state, nearby interaction scope, dimension/interior, disc ownership, and current power/session state.
- Define a strict schema for texture identifiers and every numeric setting; validate before writes and before broadcasts.
- Clarify whether advanced shader adjustments are unrestricted gameplay, a local mechanic role action, or a staff tool before adding any permission gate.
- Replace the developer spawn command with a documented local operator workflow or bounded staff UI only if there is a demonstrated operational need. Keep routine object use contextual and accessible.
- Add useful debug output for rejected interactions, malformed settings, item metadata failures, and fakevideo update failures without logging unbounded client data.

## Runtime verification still required

On a disposable MTA instance and database, verify item creation/insertion/ejection, valid and invalid remote target operations, player distance/dimension/interior changes, all shader ranges, texture identifier behavior, power transitions, fakevideo rendering to all clients in a dimension, item metadata persistence/reload, resource start order, and the restricted `/tempvsspawn` workflow. No server or tests were run for this review.
