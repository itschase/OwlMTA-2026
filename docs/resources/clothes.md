# `clothes`

## Status

- Active resource with three server-only scripts, three client-only scripts, one shared script, and one client shader file in the manifest. `manager_c.lua` exists in the directory but is not manifest-loaded and is not part of the active resource.
- Full manifest, direct-caller, inventory, duty, persistence, upload, purchase, and texture-streaming review completed from source.
- The checked-in backup server configuration is evidence of intended startup ordering, not proof of deployment. No compiled or backup copy of the resource was found.
- Findings below are source-confirmed unless explicitly marked proposed. No MTA server, database, HTTP provider, or gameplay test was run; runtime behavior remains unverified.

## Player workflows

### Shops, outfit items, and wearing clothes

Clothing-shop NPCs route item `16` selections to the `clothes` client UI. The UI previews ordinary GTA skins and matching public custom designs, then requests a purchase. The server creates an item `16` value as either a base skin ID or `skin:clothingId`, charges cash, and may consume business supplies and credit shop profit.

Using item `16` is handled by `item-system`. Ordinary skins are checked against gender/race fitting lists; custom values apply the encoded model and `clothing:id`. The selected model and custom-clothing ID are stored on the character and hydrated by `account` on spawn. If the worn outfit item is later removed, `item-system` clears the custom-clothing ID and restores a default model. The `clothes` client downloads the design texture when needed and applies it with `tex.fx` to streamed players or peds.

Direct callers and consumers include:

- `npc/c_generalshop_system.lua`, which opens the clothing browser from shop type 5;
- `item-system/s_item_system.lua` and `s_world_items.lua`, which wear outfits and recover appearance when an outfit disappears;
- `account/s_characters.lua`, which restores `characters.clothingid`;
- `duty/s_duty.lua`, which applies and removes custom duty uniforms;
- `gatekeepers-system/c_ped_rightclick.lua`, which opens the Dupont designer UI; and
- `factions/c_faction_system.lua`, which requests faction duty-skin choices.

### Dupont design, manufacture, and distribution

The client-created Melina Dupont ped exposes personal designs, eligible faction designs, and a custom-upload wizard. The client currently checks for fifteen played hours and displays a `$25` submission cost. A submission includes a URL, description, base skin, and optional faction-behalf choice. Server code downloads the image, creates a `clothing` record, stores a local texture file, and records personal or faction ownership.

Personal drafts can be edited, deleted, manufactured, copied, or sold to Dupont. Manufacture changes a draft to a private design after a file-size-derived delay; an instant option spends donor GameCoins. An owner can obtain successive copies at `2^sold`, or sell the design for `$200`, which changes it to public distribution. The client presents a global-distribution option, but that path is explicitly marked under construction.

Faction uploads require the current duty faction to have `free_custom_skins` and the member to have `modify_duty_settings`. Authorized faction designs are stored with a negative faction ID and distribution `5`.

## Staff and faction workflows

There is no active server moderation command or manifest-loaded clothes-manager UI. The shared `isModerator` helper maps to scripter status, but the active upload client takes the same path for moderators and ordinary players, and the server does not implement a moderator cost exemption. `manager_c.lua` must be treated as inactive residue.

Faction duty settings request uniform designs through `clothes:duty:fetchFactionSkins`. This handler is fixed in source: it uses trusted MTA `client`, requires a logged-in character, checks actual faction membership and `modify_duty_settings`, and returns only eligible faction-owned designs to the requester. This is the scoped remediation associated with [Issue #82](https://github.com/itschase/OwlMTA-2026/issues/82); it has not been runtime-verified.

Player-local utility commands are `/getclothingtexture`, `/skininfo` (also `/gskin` and `/getskin`), and `/flushskins`. `/flushskins` clears and reloads only the invoking client's currently visible texture cache; it is not a server moderation operation.

## Operator workflow, dependencies, and startup

The resource requires the MTA setting `imgurClient` for one upload path, outbound `fetchRemote` access, writable resource-local `cache/` and `uploads/` paths, and the `clothing` schema. Direct runtime dependencies include `mysql`, `pool`, `global`, `npc`, `datetime`, `factions`, `integration`, `interior_system`, `item-system`, `logs`, `donators`, `hud`, `announcement`, `anticheat`, `account`, and `duty`.

`mtaserver.conf.bak` starts those principal providers before `clothes`, but it is only a backup snapshot. The manifest declares no dependency/readiness contract. `savedClothing` is populated asynchronously on resource start, yet list, purchase, manufacture, and stream events have no ready-state gate. The resource inventory/catalog counts also do not reflect all active manifest scripts and shared execution.

## Persistence and lifecycle

The MyISAM `clothing` table stores design ID, base skin, URL, description, price, creator, sale expiry, distribution, manufacture time, and sold count. `characters.clothingid` stores the currently worn custom design and `characters.max_clothes` stores the personal manufacture quota. Outfit instances are item `16` rows; design-deletion checks also inspect `worlditems` and `shop_products`.

The live `savedClothing` table is an in-memory projection loaded from SQL. Negative `creator_char` values represent faction ownership. Texture bytes are cached as resource-local files rather than in the database. Manufacture-completion scheduling is an in-memory timer that later creates an `announcement` notification; an orderly or failed restart has no persisted outbox/cursor for an unsent timer.

## Event and export surface

The manifest exports client `openClothesWizard` and shared `getSkinBasicInfo`. Remote client-to-server events include:

- texture and duty support: `clothing:stream`, `clothes:duty:fetchFactionSkins`, `clothes:tempfix`;
- shop/design mutation: `clothes:list`, `clothing:buy`, `clothing:save`, `clothing:delete`;
- Dupont interaction: `clothes:pedSay`, `clothes:wizard2Result`, `clothes:manufacture`, `clothes:getProduct`, `clothes:sellProduct`, and `clothes:deleteMyClothes`.

The duty lookup and the personal manufacture/copy/sale ownership comparisons use `client` meaningfully. Several other events trust event `source`, a client-supplied design table, URL, ID, player element, ped name, or world/shop context. Client UI checks are presentation, not an authorization boundary.

## Source-confirmed defects and tracking

1. **Any client can restart the resource.** `clothes:tempfix` unconditionally calls `restartResource` with no staff capability, login, rate, or recovery check. The normal UI invokes it after one preview condition, but the remote endpoint is directly callable. This belongs under [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) until a dedicated resource-lifecycle issue is created.
2. **Design create, update, and delete are not authorized.** `clothing:save` accepts a client-provided table and optional player element without checking owner, faction authority, allowed fields, valid state transitions, base skin, price, description, or URL. A caller can create an arbitrary owner/distribution or overwrite a known ID. `clothing:delete` accepts any known design ID without ownership, capability, or dependency checks. The player-facing wiki already marks custom-design save/delete authority as unresolved. General remote ownership remains [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1); inventory consequences overlap [Issues #213 and #214](https://github.com/itschase/OwlMTA-2026/issues/214).
3. **The deletion preflight is bypassable and does not verify its requester.** `clothes:deleteMyClothes` checks item, world-item, and shop-product references but does not prove personal ownership or faction authority. It then asks the client to call the unprotected delete event. Direct deletion skips the preflight. The delete handler clears memory/file state before confirming SQL deletion, uses `table.remove` on the sparse ID-keyed cache, and does not invalidate other clients' cached texture.
4. **One upload starts two independent pipelines.** `wizard2Result` launches an Imgur metadata/download branch and a second direct-download branch. Both can succeed: the first charges `$200`, the second charges `$25`, and each can create a row/file and callback. This conflicts with the client-advertised `$25` price and can duplicate designs and charges.
5. **Upload authority and fetch bounds are incomplete.** The fifteen-hour/perk check exists only on the client. The server does not require a Dupont interaction session, validate login/base-skin/restriction/description, rate-limit a player, or robustly validate the URL. The direct path downloads and writes the complete response before enforcing 100 KB, so repeated arbitrary URLs can consume outbound network, memory, and disk. Charges occur before durable row-and-file success with no refund, and an unauthorized faction request silently becomes a personal design. This is concrete gameplay work adjacent to the proposed configurable media-provider boundary, not evidence that such a provider exists.
6. **Purchases are not bound to a server-owned shop/product context.** `clothing:buy` trusts event `source` for dimension, business, and profit attribution and has no server-side shop session, ped, proximity, or same-world check. Any negative client ID becomes a positive base-skin item for `$50`, bypassing the NPC's fitting/restricted catalog. The insufficient-funds message for this branch dereferences an undefined `clothing`. Custom purchases use server-cached price/sale state, but item grant, cash debit, supply decrement, and business profit are separate unchecked legs. Transactional remediation overlaps [Issue #6](https://github.com/itschase/OwlMTA-2026/issues/6), [Issue #209](https://github.com/itschase/OwlMTA-2026/issues/209), and item transaction [Issue #214](https://github.com/itschase/OwlMTA-2026/issues/214).
7. **Manufacture, copy, and sale are not recoverable settlements.** Instant manufacture spends GameCoins before unchecked design persistence; copy debits cash before granting the item and increments `sold` even if delivery fails; sale mutates memory, asynchronously updates SQL, and grants `$200` without one durable transaction. A failed write followed by restart can restore a sellable state after payout. The exponential copy price is not bounded. GameCoin settlement is adjacent to [Issue #222](https://github.com/itschase/OwlMTA-2026/issues/222); general financial and transaction foundations remain [Issues #6 and #209](https://github.com/itschase/OwlMTA-2026/issues/209).
8. **Texture cache delivery has correctness and abuse gaps.** Any client can repeatedly request any known design file without a per-player budget. Cache-miss completion refers to undefined `data` instead of the loaded design, so pending clients are not notified after a fetch. A transient remote response equal to `ERROR` destructively deletes the design instead of quarantining/retrying it. The client invalid-texture branch sends an undefined `clothing` variable rather than the received ID.
9. **List and ped speech paths trust client presentation state.** Personal/faction list branches use event `source` instead of authenticated `client`, allowing substituted-player requests and forced response UI. `clothes:pedSay` trusts the source element, ped name, and arbitrary unknown conversation text without proving the registered Dupont ped, distance, or an active interaction.
10. **Schema and cache lifecycle are weakly linked.** The MyISAM design table has no foreign keys to character/faction ownership or worn/item/shop references. Character `clothingid`, duty settings, item values, texture files, and client caches can outlive a deleted or failed design. Loader/database failures are mostly silent and there is no explicit loaded/error/degraded state. Schema/readiness concerns overlap [Issue #121](https://github.com/itschase/OwlMTA-2026/issues/121) and export/readiness contract [Issue #208](https://github.com/itschase/OwlMTA-2026/issues/208).

## Existing tracker ownership

- **#58 — [Validate clothing design ownership and staff authorization](https://github.com/itschase/OwlMTA-2026/issues/58)** remains the owner for create/update/delete ownership and staff-capability checks. This audit does not duplicate it.
- **#320 — [Restrict remote clothes resource restarts](https://github.com/itschase/OwlMTA-2026/issues/320)** owns the `clothes:tempfix` remotely callable whole-resource restart and rate/state validation.
- **#321 — [Bind clothing lists and Dupont dialogue to server interaction state](https://github.com/itschase/OwlMTA-2026/issues/321)** owns requester-bound personal/faction list responses and server-validated NPC dialogue context.
- **#312 — [Replace duplicate uploads with one bounded intake pipeline](https://github.com/itschase/OwlMTA-2026/issues/312)** owns upload idempotency, provider restrictions, bounded fetch, and one-charge/one-design settlement.
- **#313 — [Bind clothing purchases to shop context and settle grants](https://github.com/itschase/OwlMTA-2026/issues/313)** owns the NPC/shop session, catalog validation, outfit purchase, supply, and business-profit settlement.
- **#314 — [Make manufacture, copies, and resale recoverable](https://github.com/itschase/OwlMTA-2026/issues/314)** owns durable design transitions and idempotent cash/GameCoin/item settlement.
- **#315 — [Bound texture delivery and cache failure handling](https://github.com/itschase/OwlMTA-2026/issues/315)** owns provider fetch bounds, pending-client notification, validation, retry/quarantine, and cache cleanup.

- [Issue #82](https://github.com/itschase/OwlMTA-2026/issues/82): faction duty-skin lookup authorization; fixed in source, runtime-unverified.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1): parent remote-event authorization audit, including restart and unbound mutation endpoints.
- [Issue #6](https://github.com/itschase/OwlMTA-2026/issues/6): transaction/idempotency foundation for purchases, uploads, manufacture, copy, and sale.
- [Issue #149](https://github.com/itschase/OwlMTA-2026/issues/149) and [Issue #209](https://github.com/itschase/OwlMTA-2026/issues/209): typed financial ownership and ledger-backed money settlement.
- [Issue #213](https://github.com/itschase/OwlMTA-2026/issues/213) and [Issue #214](https://github.com/itschase/OwlMTA-2026/issues/214): inventory mutation authority and atomic/recoverable item movement.
- [Issue #220](https://github.com/itschase/OwlMTA-2026/issues/220): duty issuance/provenance and appearance lifecycle.
- [Issue #222](https://github.com/itschase/OwlMTA-2026/issues/222): atomic, auditable, recoverable GameCoin purchases.
- [Issue #121](https://github.com/itschase/OwlMTA-2026/issues/121): schema/bootstrap reproducibility.
- [Issue #208](https://github.com/itschase/OwlMTA-2026/issues/208): shared export/readiness contracts.
- [Issue #95](https://github.com/itschase/OwlMTA-2026/issues/95): resource discussion/documentation coverage.

These shared issues do not fully own the concrete clothes defects. Dedicated implementation units should cover design mutation/resource restart, bounded uploads, authoritative shop purchases, recoverable manufacture/distribution, and texture-cache lifecycle rather than treating the parent issues as complete remediation.

## Proposed modernization direction

Use one server-owned clothing-design aggregate with immutable design identity, typed personal/faction ownership, explicit draft/manufacturing/private/public/faction/archive transitions, revision checks, and audit events. Create/update/delete must derive the actor from `client`, allowlist mutable fields, enforce existing faction permissions, and commit SQL before changing cache/files/clients.

Replace both URL-download branches with one configurable media-storage boundary. Apply server-side eligibility, provider/URL policy, content signature, dimensions, size, rate, concurrency, timeout, and idempotency before committing or charging; compensate every failed leg and reject rather than downgrade unauthorized faction submissions.

Bind browsing/purchase/manufacture/distribution to short-lived server interaction contexts. Derive shop, product, skin, price, discount, supply, owner, payer, and faction on the server. Use idempotent, recoverable settlement for item, cash/GameCoin, supply, profit, design state, sold count, file, and notification changes. Keep faction duty permission separate from donor entitlement and staff capability.

## Runtime verification still required

In a disposable environment after safe-start approval, test every remote with forged source/player/design/owner/faction/state; direct resource restart; create/update/delete and dependent-reference races; malformed, redirected, private-network, oversized, wrong-format, slow, and concurrent uploads; double callbacks/charges; disconnect and provider/DB/file failures; ordinary/restricted/custom skin purchases from outside a shop; funds, supplies, profit, and full-inventory failures; concurrent manufacture/copy/sale and restart recovery; quota/GC boundaries; cold start before cache readiness; cache miss/corruption/outage; duty uniform selection; item removal and character reload. None of these checks has been run.
