# `freecam-tv` resource

**Review state:** Full manifest, player TV flow, item-system caller, faction commands, camera export, and faction payout source review. TV timing, audience calculation, and recovery remain runtime-unverified.

## Player experience

Players use `/tv` or the TV inventory item (item ID `104`) to watch a running faction TV show. The server moves the viewer into the configured TV interior/dimension and the client follows the broadcast camera. The player must have the TV item, already be in an interior dimension, or already be using the TV camera; a show must be running and the player's camera target must be their own player before entering. `/tv` also exits the TV camera.

## Broadcaster and staff workflow

Members of faction ID `20` can use `/movetv` to place the broadcast camera where they are standing, `/starttv` and `/endtv` to manage a show, and `/watchers` to view audience and earnings totals. Ending a show pays the accumulated earnings to faction 20's bank account and logs the result. The server export `add(affectedPlayers)` calculates current viewers from server state and adds earnings while the show is live.

## Connections and authority

- `item-system` calls the server-side `useTV` event when a player uses item 104.
- `global` checks item ownership, formats money, and credits the faction; `factions` owns faction membership and account lookup.
- `logs` records show start/stop; `bank` records the faction transaction.
- `freecamTV:state` and saved TV world context connect server movement with client camera/collision behavior.
- Faction membership and the TV item are local gameplay policy. Discord roles should not grant faction membership or bypass item/world checks.

## Source finding and future improvements

The remotely enabled `useTV` handler accepts a client-supplied `player` parameter and operates on it, while the valid item-system caller is a server-internal `triggerEvent`. This lets a forged event try to control another player's viewing state. Tracked in [Issue #436](https://github.com/itschase/OwlMTA-2026/issues/436). Split remote player requests from trusted internal calls and restore each player's saved world/camera state on disconnect, character change, resource stop, and failed start.

A player media menu could show show status, consent to enter/leave, and a local view of the camera feed. A faction dashboard could show camera location, viewers, and earnings. Keep the current faction 20 checks on broadcaster operations and use a recoverable, auditable payout path.

## Runtime verification

On a disposable server, verify item and dimension eligibility, forged targets, faction-only controls, marker and show state, viewer changes, earnings calculation, bank payout idempotency, resource restart, and cleanup of position/interior/dimension/alpha/camera state. No MTA server or tests were run.
