# `global`

## Status

- Tree/startup state: active and enabled near the beginning of the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded server, client, and shared script plus representative consumers and schema.
- Runtime: unverified. The server has not been started.
- Discussion: [Script Resource: global](https://github.com/itschase/OwlMTA-2026/discussions/73).

## What it does

`global` is the inherited shared standard library and mutable authority facade. It exports chat/audience, identity and staff predicates, money/tax, inventory wrappers, animation, nametag, sound/fade/tip, vehicle/interior capacity, country/zone/date/string, account lookup, weapon serial, resource, SQL, ID-allocation, benchmark, and utility functions. It has no single player menu, but its behavior appears throughout the gamemode.

Its blast radius is exceptional: roughly 370 Lua files call `global`. Frequently used exports include money formatting, staff messages, inventory predicates, player lookup, animations, local text, item grants, and money mutation. Any export or authority change requires a compatibility plan.

## Player, staff, and operator use

- Players encounter money and item mirror changes, local chat/emotes, animation/control state, identity display, sound/fade/tips, nametags, country/zone formatting, and many downstream features.
- Staff systems use shared administrator, supporter, GameMaster, title, duty, identity, and audience helpers. Client predicates are presentation only; donor/supporter status must never imply staff authority.
- Operators depend on implicit startup order across `mysql`, `anticheat`, `item-system`, `pool`, `integration`, `report`, `freecam-tv`, `donators`, `interior_system`, and `cache`. Tax settings and some ephemeral caches are reloaded at resource start, but no version/readiness handshake exists.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/global/meta.xml`](../../mods/deathmatch/resources/global/meta.xml)
- Money facade: [`s_money_globals.lua`](../../mods/deathmatch/resources/global/s_money_globals.lua)
- Chat helpers: [`g_chat_globals.lua`](../../mods/deathmatch/resources/global/g_chat_globals.lua)
- Item facade and general helpers are split across manifest-loaded server/shared/client files; consult the manifest before changing realm or return shape.
- Persistence includes `characters.money`, `factions.bankbalance`, `settings`, and the cash item 134 mirror. Authority and presentation also rely on protected live element data and in-memory caches.
- Several staff-message exports are HTTP-callable, making effective ACL and input scope part of the public attack surface.

## Source-confirmed risks

- Money exports perform SQL, cash-item rebuild, protected element data, and effects separately, ignore some outcomes, and require no actor/reason/correlation/idempotency. [Issue #209](https://github.com/itschase/OwlMTA-2026/issues/209).
- Inventory wrappers are untyped passthrough calls with no dependency readiness or normalized failure contract.
- Local text, me/do action, and 3D-sound remote events trust caller-selected actor/source, range/audience, message/media, and volume. [Issue #210](https://github.com/itschase/OwlMTA-2026/issues/210).
- The server `getGameMasters()` helper previously returned every supporter; it now requires a logged-in player with an explicit positive `account:gmlevel`. Donor status alone no longer places a player in server-side GameMaster lists/report routing. The durable grant/assignment path and several manifest-declared GameMaster exports remain unresolved under Issues #3, #14, #23, and #68.
- Export realm, input/output/error contracts, restart behavior, and compatibility are undocumented across hundreds of callers. [Issue #208](https://github.com/itschase/OwlMTA-2026/issues/208).
- The legacy ban facade is inactive/broken and should defer to `bans`, not become parallel authority.
- Account-result cleanup, smallest-ID allocation, element guards, item-space slot selection, sound-volume application, country parsing, and century leap-year handling contain source-confirmed correctness risks.
- Weapon serial and string “encryption” helpers are reversible/custom and must not protect identity tickets, Discord sessions, passwords, or secrets.

## Target direction

Split the resource behind compatibility wrappers into narrow, versioned modules: pure utilities, identity/display, capabilities, notifications/audiences, economy ledger client, inventory facade, world/zone, and animation/media. Publish explicit readiness/version contracts and typed errors. Keep client helpers non-authoritative, remove unnecessary HTTP exports, and stage consumer migration rather than renaming or removing shared exports in one step.

Runtime verification must check every declared export and realm; provider/consumer cold start and restart; player/organization money plus failure reconciliation; item dependency loss; chat/emote source/range/content abuse; sound path/range/volume/rate abuse; HTTP ACL and injection; every legacy staff/supporter/GameMaster combination and Discord lease state; ban facade behavior; account lookup/result lifecycle; capacity helpers; animation recovery; nametag policy; country/zone/weapon-serial edge cases; and utility nil/type/fuzz parity across client/server.
