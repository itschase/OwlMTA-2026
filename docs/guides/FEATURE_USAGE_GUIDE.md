# Feature usage guide (working draft)

This guide records how features are reached and used from the code, not a claim that they have been validated in a running server. It is being built alongside the architecture guide. Each entry should eventually cover player entry point, prerequisites, server authorization, visible result, persistence, related systems and known failure modes.

## Account and character

### Log in or register

- **Entry point:** the login panel in `account/login-panel/client.lua`.
- **Player action:** enter an account username and password, or use the registration form. When a compatible `mta-discord-identity` resource is running, a separate **Sign in with Discord (linked accounts)** button requests a challenge, displays the normal-browser URL/code, and accepts the one-time returned ticket. The player never enters an account ID or Discord ID into the game.
- **Account effect:** password proof enters the local admission path directly. A successful bound Discord ticket instead stages the account, runs local checks, activates a bounded server-held identity session, then reloads Core and repeats activation/ban/device/account-details checks before establishing `account:id` / `account:loggedin`, loading legacy ranks, and showing character selection.
- **Current integration limits:** Discord login is existing-link-only and hidden when the adapter is absent. A server-only Owl capability facade, confirmed-revocation disconnect, full-account logout, and selected non-granting shadow comparisons exist in source; Discord capability results still cannot grant actions. New-account Discord registration, durable identity storage and leases, broad per-action cutover, production policy, and runtime validation remain incomplete. Legacy registration still calls a missing localhost activation-mail API, and forum linking depends on an unimplemented export.
- **Source status:** the shared admission path, optional bridge, and ticket UI are fixed in source only. No MTA server, Discord application, identity service, database, or GUI runtime validation has occurred.

### Select, create, or switch character

- **Entry point:** the character-selection UI after account login.
- **Player action:** select an owned character to spawn, create a character through the form, or return to selection using the character-change flow.
- **Creation fields:** roleplay name, appearance, height, weight, age, language, birth date and arrival location. The client currently displays several arrival choices, but its own source says the selector is temporarily disabled and automatically submits the default bus-stop location.
- **Server effect:** `account/s_characters.lua` restores the selected row's saved state; `account/s_create_character.lua` inserts a new character and starter items. General character persistence is handled by `saveplayer-system`, with other resources saving their owned state on the shared save event.
- **Source status:** creation now checks that an account is authenticated, validates scalar inputs and the birth date, checks the character quota on the server, ignores client-supplied coordinates, and emits tagged debug messages. The client still receives the existing generic error-code UI. Runtime validation remains open.
- **Important boundary:** the target `account:id` must own the character row. A client-provided account or spawn coordinate must never select the row/location.

## Staff operations

### Staff manager

- **Entry point:** `/staffs` opens the staff manager window (`admin-system/staff_manager/staff_manager_c.lua`). Search by account username, then use the staff/team/changelog tabs.
- **Visible operations:** view a player's assigned admin, Supporter/donor and specialty-team ranks; authorized staff can edit ranks and review staff lists/changelogs.
- **Server boundary:** the manager fetch/edit events are remotely triggered by the client. The server must independently authenticate and authorize each request. Current hardening adds server permission checks, validates rank inputs and logs denials. Donator status alone is not staff-manager access.
- **Migration note:** displayed legacy `supporter` rank means donor tier. The replacement must not expose it as moderation authority. See [DISCORD_AUTH_DESIGN.md](../architecture/DISCORD_AUTH_DESIGN.md) for the planned capability model.

### Faction manager

- **Entry point:** `/showfactions` or `/factions` opens the list. `/showfactionplayers <faction id>` requests a member roster. `makefaction`, `renamefaction`, and `delfaction` are aliases that open the same manager UI.
- **Editing:** the UI exposes faction creation, edit, delete and member-list actions. The current intended mutation rule in the UI is Lead Admin or FMT Leader; the server now enforces the same check. Read access is limited to approved staff/team levels. A donor role by itself no longer grants access.
- **Data affected:** faction type/limits/perks, faction ranks, team element data, member roster, and linked faction vehicles/interiors/MDC/duty state. Deletion has broad downstream effects and must be treated as a destructive staff action.
- **Diagnostics:** rejected or failed manager operations write `[FACTION][SECURITY]` messages to the server debug log without recording credentials.

## Item inventories and storage

- **Entry point:** open a nearby vehicle inventory from its right-click menu; a property mailbox from the interior menu; a keyed safe from its context menu; or a fridge, shelf, container, workbench, machine, oven, dumpster, bin, or other storage item through object interaction. The inventory window shows carried weight on the player side and capacity on the container side; double-clicking moves an item.
- **Player requirements:** the character must be logged in, alive, in the correct interior and dimension, and close to the target. A vehicle inventory requires the driver, a vehicle-key holder, or a member of its owning organization; a locked vehicle can be opened only by its current driver, and an impounded vehicle requires its key. Property mailboxes and safes require the applicable key, on-duty administrator override, or the existing government-organization rule for government property. Storage objects also apply their item-world `use` policy, such as owner, placer, character, organization, or key-holder access.
- **Server effect:** opening a supported container creates a short-lived server-held session bound to the account, character, and element. Character change/logout or expiry clears it, and container updates recheck session/access before they are sent. A pickup rechecks the same session, proximity/access, item slot and immutable row index, destination capacity, protected-item policy, and item-specific restrictions. Client visibility or a direct event call is not authority.
- **Weapons and ammunition:** the client may preview weapon capacity, but the server derives the actual grant from current ped ammunition and the stored item. It conditionally changes exactly one expected database row before applying the live weapon and attempts restoration if the live grant fails.
- **Source status and failure boundary:** this `moveFromElement` weapon-pickup slice and direct subscription wiring are fixed in source. The remaining item mutation/read surfaces, durable operation identity, MyISAM crash recovery, concurrent moves, compensation failures, and all vehicle/interior/safe/world-storage runtime cases remain open under Issues [#15](https://github.com/itschase/OwlMTA-2026/issues/15), [#213](https://github.com/itschase/OwlMTA-2026/issues/213), and [#214](https://github.com/itschase/OwlMTA-2026/issues/214). No MTA or database runtime has validated this flow.

## Banking and ATMs

- **Entry point:** interact with a bank teller/ped for the general bank UI. The resource also opens ATM UI after interacting with an ATM object and completing card/PIN checks.
- **Personal actions:** view balance/history, deposit cash, withdraw cash, transfer to another character or eligible recipient. ATM card services include apply, lock/unlock, recover/cancel, PIN validation and PIN change.
- **Faction actions:** business balance/history and finance actions are available only for factions where the player's in-game faction rank grants `manage_finance`. This is an in-game faction permission, independent of Discord admin roles.
- **Persistence:** character bank balances are stored in `characters.bankmoney`; faction balances are stored in `factions.bankbalance`; transaction history is written to `wiretransfers`.
- **Source status:** server handlers validate positive amounts and repeat faction-finance checks. Transfers attempt compensation if delivery fails. The client-triggerable ledger writer was removed; trusted resources use the server export. The storage model still spans MyISAM and element data, so compensation cannot provide full transactional guarantees. Runtime validation remains open.
- **Diagnostics:** `[BANK]` debug messages identify rejected operations and failed compensation/history writes without including account secrets.

## Feature guide coverage still needed

Next entries to map from their UI and server handlers: world-item drops and placement; vehicle purchase/ownership/fuel/impound/insurance; faction duty and ranks; jobs; properties/interiors; payday/economy; police, medical and prison workflows; player reports and admin enforcement. For each, record exact entry commands/buttons, required state, permissions, database effects and failure messages before writing player-facing instructions.

## MTA API use while documenting features

Follow the MTA `meta.xml` to establish which scripts run client-side and server-side. Trace each UI action from `triggerServerEvent` into the server handler, then inspect validation and the targeted `triggerClientEvent` response. The [MTA script security guide](https://wiki.multitheftauto.com/wiki/Script_security) explains why the server should use its `client` variable to identify the player who triggered a remote event; `source` is supplied by the caller and is not a permission check. Review the [triggerServerEvent](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) API whenever a feature's client/server boundary is unclear.
