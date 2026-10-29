# Feature usage guide (working draft)

This guide records how features are reached and used from the code, not a claim that they have been validated in a running server. It is being built alongside the architecture guide. Each entry should eventually cover player entry point, prerequisites, server authorization, visible result, persistence, related systems and known failure modes.

## Account and character

### Log in or register

- **Entry point:** the login panel in `account/login-panel/client.lua`.
- **Player action:** enter an account username and password, or use the registration form. When a compatible `mta-discord-identity` resource is running, a separate **Sign in with Discord (linked accounts)** button requests a challenge, displays the normal-browser URL/code, and accepts the one-time returned ticket. The player never enters an account ID or Discord ID into the game.
- **Account effect:** both password proof and a successful bound Discord ticket enter the same server admission path. It loads the Core account by server-derived ID, then checks activation, current ban state, serial/device policy, MTA account details, and an existing session before establishing `account:id` / `account:loggedin`, loading legacy ranks, and showing character selection.
- **Current integration limits:** Discord login is existing-link-only and hidden when the adapter is absent. New-account Discord registration, durable identity storage, post-admission named capabilities, revocation disconnects, and production cutover policy are not implemented. Legacy registration still calls a missing localhost activation-mail API, and forum linking depends on an unimplemented export.
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

## Banking and ATMs

- **Entry point:** interact with a bank teller/ped for the general bank UI. The resource also opens ATM UI after interacting with an ATM object and completing card/PIN checks.
- **Personal actions:** view balance/history, deposit cash, withdraw cash, transfer to another character or eligible recipient. ATM card services include apply, lock/unlock, recover/cancel, PIN validation and PIN change.
- **Faction actions:** business balance/history and finance actions are available only for factions where the player's in-game faction rank grants `manage_finance`. This is an in-game faction permission, independent of Discord admin roles.
- **Persistence:** character bank balances are stored in `characters.bankmoney`; faction balances are stored in `factions.bankbalance`; transaction history is written to `wiretransfers`.
- **Source status:** server handlers validate positive amounts and repeat faction-finance checks. Transfers attempt compensation if delivery fails. The client-triggerable ledger writer was removed; trusted resources use the server export. The storage model still spans MyISAM and element data, so compensation cannot provide full transactional guarantees. Runtime validation remains open.
- **Diagnostics:** `[BANK]` debug messages identify rejected operations and failed compensation/history writes without including account secrets.

## Feature guide coverage still needed

Next entries to map from their UI and server handlers: item inventory and world drops; vehicle purchase/ownership/fuel/impound/insurance; faction duty and ranks; jobs; properties/interiors; payday/economy; police, medical and prison workflows; player reports and admin enforcement. For each, record exact entry commands/buttons, required state, permissions, database effects and failure messages before writing player-facing instructions.

## MTA API use while documenting features

Follow the MTA `meta.xml` to establish which scripts run client-side and server-side. Trace each UI action from `triggerServerEvent` into the server handler, then inspect validation and the targeted `triggerClientEvent` response. The [MTA script security guide](https://wiki.multitheftauto.com/wiki/Script_security) explains why the server should use its `client` variable to identify the player who triggered a remote event; `source` is supplied by the caller and is not a permission check. Review the [triggerServerEvent](https://wiki.multitheftauto.com/wiki/TriggerServerEvent) API whenever a feature's client/server boundary is unclear.
