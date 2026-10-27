# `id-system` resource

**Review state:** Full active manifest and direct ID lifecycle source review. Slot allocation, reconnect, pool restart, and exhaustion behavior remain runtime-unverified.

## What a player ID means

This server-side resource assigns each connected player a temporary session ID from 1 through 5000. The number is assigned on join, stored in the resource's in-memory table, exposed as protected `playerid` element data, and released on quit. On resource start it reconstructs assignments from the player pool. The identifier may be reused after disconnect or restart; it is not a permanent character, account, or Discord identity.

There is no database table, player-facing command, or declared export in the active manifest. `pool` uses this identifier as its in-memory player index key, and the value is referenced by the scoreboard and many gameplay/staff resources.

## Staff behavior

The `/fakeme` command in `admin-system` is lead-admin restricted. It changes the fake name and triggers a server-local `fakemyid` event that refreshes the player's session ID. The ID resource registers that event as server-only; the event is not a remote client permission grant.

No staff authority is represented by possessing a lower/higher session ID. Discord authorization should resolve a trusted account/character identity through the separate identity integration; it must never treat `playerid` as an authentication credential or persistent identity.

## Dependencies and operator notes

- `pool` indexes player elements using the session ID and can be rebuilt during resource start.
- `admin-system` invokes the fake-ID refresh path for the lead-admin `/fakeme` command.
- Other resources use `playerid` for display, lookup, and temporary session references. Audit any future persistence consumer before assuming the value is stable across reconnects.
- The active allocator has no explicit handling when all 5000 slots are occupied. This is a capacity boundary, not evidence of a current production failure; document the configured maximum and fail safely if the server is ever operated at that scale.

## Future design

Keep three identifiers distinct in APIs, logs, and UI: connection/session ID (`playerid`), durable game account/character ID, and external Discord user ID. A staff dashboard may display the session ID for in-game lookup, but durable records and Discord authorization must use the corresponding trusted stable identity.

## Runtime verification

Verify allocation and reuse across join/quit, resource restart while players are connected, `/fakeme`, pool rebuild ordering, clean handling when slot capacity is exhausted, and the many consumers that display or index `playerid`. No tests or server were run.
