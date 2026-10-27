# `dancer-system` resource

**Review state:** Full manifest and direct-caller source review with schema and property-cleanup tracing. Ped recreation and database failure behavior remain runtime-unverified.

## Purpose and player use

`dancer-system` places persistent animated NPC dancers or strippers in interiors. Players can encounter the ambient peds; there is no player command or direct player-operated interface. The server rotates through animation states on a timer and clients cancel damage to these peds.

## Staff and operator workflows

- `/adddancer [type] [skin] [offset]` creates a dancer at the invoking administrator's current position, interior, and dimension. It is gated by `integration:isPlayerAdmin`, with per-dimension limits and a lead-admin exception.
- `/nearbydancers` lists nearby mapped peds and is gated by Trial Admin.
- `/deldancer [ID]` removes a persisted dancer by database ID and is gated by Admin.
- `/updatedancers` forces an animation update and is gated by Trial Admin.

These are local staff predicates, not Discord roles. In a future Discord bridge, map a named staff capability at the server authorization boundary; donator/supporter levels have no role in ambient dancer management.

## Persistence and connected resources

The `dancers` table stores location, rotation, skin, type, animation offset, interior, and dimension. The resource loads those rows at start and keeps a private `peds` map for live elements. It uses MySQL for persistence, `integration` for staff levels, `global:getNearbyElements` for nearby listing, and protected element-data helpers for ped metadata.

`interior_system` removes dancer rows and peds during property cleanup for a dimension. The dancer resource's periodic animation update later prunes invalid element references from its own map. Verify shared-dimension behavior carefully because cleanup currently targets dimension.

## Source-confirmed findings

- **Ped recreation drops its animation metadata and uses the interior as dimension.** The death handler removes the old map entry, then stores an undefined `options` value for the replacement; it also sets dimension from `getElementInterior(source)`. The replacement is therefore not retained with the original `{type, offset}` and the dimension assignment is inconsistent with the source dimension. See [Issue #374](https://github.com/itschase/OwlMTA-2026/issues/374). Actual event delivery and observed gameplay need runtime confirmation.
- **Delete success is reported without checking the SQL result.** `/deldancer` removes the live ped after issuing the delete and reports success without checking whether persistence succeeded. A failed delete can allow the row to reappear after restart. See [Issue #375](https://github.com/itschase/OwlMTA-2026/issues/375).
- Add limits count by dimension although the message describes a per-interior limit. Whether two interiors share a dimension in intended deployment is a configuration-dependent question; document and test the limit policy before changing it.
- Startup assumes database results and ped creation are valid. Add bounded diagnostics and failure handling after confirming the MySQL wrapper contract.

## Future interaction and operations

Ambient dancers should remain world content rather than command-driven player features. Staff dashboards can provide a map/list view, placement preview, safe delete, and animation/skin settings while preserving local staff checks or future Discord staff capabilities. Commands should remain documented until an equivalent interface is available. Operator tools should display interior and dimension separately and preserve data if a create/delete operation fails.

## Runtime verification

Use a disposable DB to verify startup row loading, all dancer types/offsets, death and respawn, interior/dimension preservation, nearby/delete commands, SQL delete failure, per-interior limits, and property cleanup with multiple interiors sharing a dimension. No server or tests were run for this review.
