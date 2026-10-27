# `cards` resource

**Review state:** Full manifest-script and direct-caller source review. Runtime behavior, GUI synchronization, and current MTA compatibility remain unverified.

## Purpose and player use

`cards` opens a shared, temporary card table when a player uses inventory item type `77` (a card deck). The player who opens it is the dealer/host. The host can invite another player from the social right-click menu, deal cards face up or face down to each seat, shuffle, and clear all hands to begin a new game. Any participant can leave; a player can reveal their own hidden cards. The interface is a pair of client GUI windows, not a command workflow.

The visible invite flow is in `social/c_player_rightclick.lua`; it appears when the local player has the client-side `cards:host` element-data marker. The card resource independently checks that the authenticated caller hosts a session, so the UI marker is not the permission boundary. At present, however, the server joins the selected target immediately and does not request the target's consent or verify proximity/world placement.

There are no card-game rules, bets, or account balances in this resource. It is a lightweight shared prop/activity for roleplay; the host manually controls the deal. A standard 52-card set is built for item value `1` and as the fallback. The manifest also loads two other deck definition files; `g_demo.lua` replaces `decks[1]` with the same standard set during initialization, while `g_decks.lua` defines a small demo deck under the string key `demo`.

## Player workflow and interface opportunities

1. Obtain a physical card-deck inventory item and use it through the item system.
2. The resulting session opens a local table UI; the opening player is dealer.
3. Use the social player menu to select and invite participants; participants receive the table UI automatically under current behavior.
4. The dealer chooses a seat and deals face-up or face-down cards. Each hand is limited to five cards.
5. Players may reveal one card or their full hand. The dealer can shuffle or clear all hands for a new round.
6. Leave with the session button. The host leaving closes the entire session.

The current buttons cover the short, repetitive actions well. A future contextual/third-eye action could open a deck or present a player invitation, while preserving the existing key/command-free GUI. The server must still validate inventory, actor, session, target, state, and range; the contextual interface must not become authority.

## Staff, operator, and Discord authorization

No staff, administrative, GameMaster, faction, donor, or operator command is registered here. Ordinary card play should not require Discord authorization. Any future global moderation action would need its own named staff capability at the server-side action boundary; it must not be inferred from a Supporter/donor tier. No role IDs or Discord credentials belong in this resource.

The resource has no resource-specific configuration, database table, external endpoint, or persistent match record. Sessions and card piles are held in server memory and disappear on resource/server restart. Operators should ensure `item-system` and `social` are started with the core resource set; the manifest declares no inter-resource dependency tags, even though those direct integrations exist. Card assets are packaged in `meta.xml`.

## Technical map and connections

- `meta.xml` loads `g_defs.lua` as shared, three server deck-definition files, `s_sessions.lua` on the server, and `c_session.lua` on clients; it exports server-side `openCardDeck`.
- `item-system/s_item_system.lua:553-554` calls the export when item type `77` is used. The export counts matching inventory decks to determine `deck_count`, builds/shuffles a fresh virtual pile, and opens the session. It does not consume the physical deck.
- `social/c_player_rightclick.lua:64-68` exposes the host's invite control and calls `cards:invite_player`.
- `s_sessions.lua` owns host, membership, seats, hands, draw pile, card limit, shuffle, deal, reveal, and close behavior. It accepts the client events `cards:leave_session`, `cards:invite_player`, `cards:shuffle`, `cards:deal_card`, `cards:new_game`, and `cards:reveal`.
- `c_session.lua` creates the session/table windows, updates dealt hands, card backs, labels, buttons, and close/rebuild behavior. Session events are client presentation and synchronization.
- `account/s_characters.lua:550` triggers session leave during character selection. `onPlayerQuit` also leaves. `item-system/s_world_items.lua:577-578` asks cards to close a hosted session after dropping the last matching deck.
- `/` commands: none. Keybinds: none. Persistence: none. Logs: no card-specific durable log stream.

## Source-confirmed findings and tracking

- **Face-down identities are broadcast.** `s_sessions.lua:188-195` stores the real card object with `shown=false` and broadcasts that full object to every participant. `c_session.lua:246-263` displays a card back for other players, but the identity is already present in each client's event payload. See [Issue #353](https://github.com/itschase/OwlMTA-2026/issues/353). Keep hidden card identities server-side and send audience-appropriate payloads.
- **Invitations join targets immediately.** `s_sessions.lua:72-90` confirms the caller hosts a session and checks that the target is an element, then calls `joinSession` directly. It does not verify target player type, proximity, dimension/interior, or target acceptance. The client right-click menu is not a server-side proximity check. See [Issue #354](https://github.com/itschase/OwlMTA-2026/issues/354).
- **Debug output is suppressed.** `g_defs.lua:3-5` replaces `outputDebugString` with a no-op, so the client lifecycle call at `c_session.lua:17-20` and any future resource diagnostics are dropped. See [Issue #355](https://github.com/itschase/OwlMTA-2026/issues/355).
- **Session cleanup needs regression coverage.** The host leaving closes all members; participant leaving removes their entries. Character selection and dropping the last deck have cross-resource hooks. MTA resource stop/restart and simultaneous lifecycle paths have not been exercised.

## Modernization opportunities

- Send private hand state only to the owner; publish card identity to the table only when shown, and send hidden-card counts/placeholders to other participants.
- Turn invitations into expiring accept/decline requests and validate target player, server-derived actor, distance, dimension, interior, and active session on acceptance.
- Preserve debug output and add low-volume, structured session lifecycle diagnostics. Never log hidden card identities.
- Add explicit session teardown on resource stop and validate stale player/session elements before broadcasts.
- Reconcile deck definitions and item-value handling so each configured deck type has a single authoritative definition; decide whether the demo deck is supported or should be removed.
- Keep match/pile state ephemeral unless a future game design explicitly adds wagering or persistence; any such feature would require a separate transaction, policy, and audit design.

## Runtime verification still required

Using a disposable MTA server and test accounts, verify deck item use with one and multiple physical decks, supported/fallback item values, host/guest GUI synchronization, five-card boundaries, face-up/down privacy after the protocol is corrected, invite accept/decline/range/world checks, reveal, shuffle, new game, player quit, character switch, host deck drop, host exit, resource stop/restart, and debug output. No MTA server or automated tests were run for this review.
