# `social`

## Status

- Tree state: active resource tree; obsolete/backup scripts on disk are not manifest-loaded.
- Tracked startup snapshot: enabled; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified.

## What it does

`social` combines account-level friends and presence, character appearance descriptions, the player right-click interaction menu, and physical roleplay actions such as frisking, restraints, blindfolds, and stabilization. It also supplies cursor, friendship, notification, and time-formatting helpers.

## Player use

`/friends` opens the account friends list. `/addfriend` or the right-click action sends a request; acceptance requires a server-tracked pending request. Friends receive online/offline, character-spawn, and status updates and can remove the relationship.

`/look` displays a character's description and visible badges, masks, and bags. `/editlook` changes the player's stored description. The right-click UI presents looking, friend management, frisking, restraining/unrestraining, blindfold, and stabilization actions when its client-side prerequisites appear satisfied. Those checks are not an authoritative security boundary; several actions still need the server-side actor, proximity, state, and item validation tracked in Issue #132.

## Staff and operator use

On-duty administrators can edit another character's appearance through the current legacy admin route, with logging and visible/hidden feedback. Most physical actions are ordinary player mechanics, making server-side item/proximity/state validation essential.

Primary state includes `friends`, `account_details.friendsmessage`, character description/weight/height, and persisted cuff/restraint/blindfold fields. Pending friend requests and presence are in memory. Important connections include `mysql`, `datetime`, `global`, `item-system`, `artifacts`, `anticheat`, `logs`, `cache`, `rightclick`, `weather`, inventory events, and account/character lifecycle events.

## Technical map

- Manifest: [`mods/deathmatch/resources/social/meta.xml`](../../mods/deathmatch/resources/social/meta.xml)
- Friend, look/description, right-click, restraint, blindfold, frisk, and stabilization scripts are manifest-active.
- Exports include cursor helpers, friendship checks/notifications, time formatting, and the client friends list.

## Known risks and next work

- [Issue #132](https://github.com/itschase/OwlMTA-2026/issues/132) covers server `client`/target binding, proximity/state, allowed item/key ownership, stored restraint reconciliation, one-use item return, invalid elements, and persistence failure.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) remains the parent remote-event audit; [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3) owns staff capability migration.
- Friend status messages need a documented length/content policy even though identity is derived from the caller.

Runtime verification must cover friend request/accept/remove/presence/status, description self/staff editing, every physical action in/out of range and dimension, required/wrong/missing items, restraint keys/state, disconnect/replay, and database failure.
