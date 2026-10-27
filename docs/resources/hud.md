# `hud` resource

**Review state:** Full active manifest, player/staff command inventory, client/server display paths, and direct integration review. Render, blur, resource-restart, and GUI behavior are runtime-unverified.

## Player experience

The HUD includes the main screen presentation, nametags, achievement popups, top-right/bottom-center overlays, loading preview, blur, and basic player statistics. Player commands include `/togglehud`, `/limitfps`, and `/stats`; client overlay toggles are also used by Help Center/account options. HUD is called by phone, jobs, vehicles, admin tools, licensing, inventory, and other resources.

`/stats` shows a character summary including licenses, vehicle/property IDs, carried weight, cash, bank balance, and GameCoins. Treat that output as private account information; do not route it to clients other than the authorized requester.

## Staff and operator controls

The active server command surface includes `/admins`, `/gms`, `/staff`, `/toggleOverlay`, and `/togOverlay`. A staff-list section is named “Support Team” and uses `isPlayerSupporter`, `supporter_level`, and `duty_supporter`; this is donor/supporter status and must remain distinct from admin/GameMaster authority. The HUD also exposes supporter-specific display toggles.

The manifest declares client and server notification exports and a client `isActive` helper. Many resources depend on these notifications, so operators should validate provider start/restart behavior with consumers. The HUD has no owned SQL table.

## Source-confirmed issues and portability

- Remotely callable `showStats` uses a client-supplied player argument as the subject/requester and as the authorization basis for cross-player lookup. It should bind the caller to MTA `client`, make the self-service path explicit, and only allow authorized staff lookup. See [Issue #410](https://github.com/itschase/OwlMTA-2026/issues/410).
- The blur module declares local `forced` but tests `force` at the forced-state guards and assigns the global typo on timeout. Ordinary menu blur-off requests can therefore ignore the actual forced state. See [Issue #411](https://github.com/itschase/OwlMTA-2026/issues/411).
- Achievement popups use one global window handle while multiple fade timers may overlap; an older timer can destroy the newest popup. See [Issue #412](https://github.com/itschase/OwlMTA-2026/issues/412).
- The manifest loads `c_interface.luac`; a plaintext `c_interface.lua` is present but not loaded. Its parity and reproducible build path are unknown, which is a public-importability and maintenance blocker. See [Issue #413](https://github.com/itschase/OwlMTA-2026/issues/413).

These observations are source-grounded; client rendering and end-user impact remain unverified. `/stats` also refreshes `owner_last_login` on each listed vehicle/interior while assembling the view. Confirm intended inactivity semantics before changing that side effect.

## Connected resources and future UI

The stats/overlay path interacts with `integration`, `global`, `mdc`, `pool`, `anticheat`, `datetime`, `interior_system`, `language-system`, `job-system`, and `item-system`. Command bar and panels connect to `integration`, `donators`, `factions`, `vehicle`, `mdc`, `item-system`, `realism`, and `chat-system`. The manifest does not declare these dependencies explicitly.

A future dashboard should consolidate player-facing panels and staff summaries behind searchable commands/actions while retaining privacy, recipient binding, and local staff permissions. UI must not become the source of authority. Discord capabilities may supplement an authorized staff stats request but must not expose another player's financial/property details to ordinary clients. Supporter display access remains donor entitlement, not moderation authority.

## Runtime verification

Verify `/stats` self and staff-target paths, recipient privacy, overlay toggles, supporters vs staff lists, overlapping achievements, forced login blur followed by menu close, exported notifications during provider restart, and plaintext/compiled interface parity. No server or tests were run.

## MTA reference

- [MTA Script security](https://wiki.multitheftauto.com/wiki/Script_security) describes the trust boundary for remotely triggered events and the server-side `client` variable.
- [MTA `triggerServerEvent`](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) documents client-to-server invocation.
