# `weaponcap`

## Status

- Active resource at `mods/deathmatch/resources/weaponcap`; enabled in the tracked `mtaserver.conf.bak` startup snapshot.
- Full manifest, both loaded scripts, exported helpers, and the only direct in-tree consumer were reviewed from source.
- Source fix in this change set rejects invalid weapon/ped inputs, clamps total free ammunition at zero, restores the missing server `getFreeAmmo` export, and records each invalid server-input reason at most once per resource run.
- Issues: [#549](https://github.com/itschase/OwlMTA-2026/issues/549) owns invalid-input robustness; [#550](https://github.com/itschase/OwlMTA-2026/issues/550) owns the unresolved donor-bonus policy; [#213](https://github.com/itschase/OwlMTA-2026/issues/213) owns the client-declared inventory transfer boundary.
- Script Resource Discussion: [#569](https://github.com/itschase/OwlMTA-2026/discussions/569).
- Fixed-in-source checkpoint: [`7a331bf`](https://github.com/itschase/OwlMTA-2026/commit/7a331bf); Issue updates [#549](https://github.com/itschase/OwlMTA-2026/issues/549#issuecomment-6517284837), [#550](https://github.com/itschase/OwlMTA-2026/issues/550#issuecomment-6517284871), and [#213](https://github.com/itschase/OwlMTA-2026/issues/213#issuecomment-6517284782).
- Runtime: unverified. No MTA server/client or inventory workflow was run.

## What it does

`weaponcap` is a small shared calculation resource. It defines a maximum combined ammunition count of 2,000 across weapon slots 2–9 and per-slot caps such as 250 handgun rounds, 200 shotgun shells, 1,200 assault-rifle rounds, and 12 projectiles. Client and server helpers calculate current ammunition, remaining combined capacity, and the amount available for a particular weapon. A separate server table returns GTA clip-size-like limits for selected weapon IDs.

The resource does not grant weapons, move inventory, persist data, register commands, expose remote events, or decide who may possess a weapon. Those actions belong to `item-system`, `weapon`, and their server-side policy. Capacity calculations must therefore be treated as a rule helper, never as proof that an inventory mutation is authorized.

## Player experience

The only direct active-tree consumer is the client inventory container screen in `item-system/c_move_items.lua`. When a stored weapon item is selected, that screen asks `weaponcap` how many rounds appear to fit. It uses the result to show one of three messages: total carrying capacity is full, another weapon occupies the slot, or that weapon's slot cap is full. Otherwise it sends the calculated amount with the pickup request.

There is no player command or standalone window. In normal play, the resource is visible only through inventory pickup limits and messages. A future inventory UI should display total/slot capacity directly and explain conflicting weapon slots without requiring command usage.

## Staff and operator use

There is no staff command or moderation permission in this resource. Supporter/donor tiers are not staff authority. The cap tables contain an unused second number described by a legacy comment as “ammo per donator level,” but neither loaded script reads it or `supporter_level`; Issue #550 deliberately requires a policy decision rather than inventing a perk.

Operators can change caps only by editing both Lua tables. The client and server copies must remain identical until a single server-owned configuration/export replaces them. No database table, setting, API, Discord role ID, secret, or external service is used. The tracked startup entry shows intended ordering but does not prove deployment.

## Manifest and interfaces

`meta.xml` loads `c_weapon_cap.lua` for clients and `s_weapon_cap.lua` for the server. It exports:

- Client: `getAmmoCap(weaponID)` and `getFreeAmmo([weaponID])`.
- Server: `getAmmoCap(ped, weaponID)`, `getFreeAmmo(ped[, weaponID])`, and `getGTACap(weaponID)`.

The manifest previously declared the server `getAmmoCap` export twice and omitted `getFreeAmmo`; this change set corrects that metadata. No in-tree server caller currently uses these exports, so external-resource compatibility remains unverified.

The helpers depend on MTA's [`getSlotFromWeapon`](https://wiki.multitheftauto.com/wiki/GetSlotFromWeapon), [`getPedWeapon`](https://wiki.multitheftauto.com/wiki/GetPedWeapon), and [`getPedTotalAmmo`](https://wiki.multitheftauto.com/wiki/GetPedTotalAmmo) behavior. The source fix checks weapon IDs before indexing the slot table, validates server ped/player elements, returns zero for rejected inputs, and clamps an over-cap total to zero remaining. Server rejection diagnostics contain only a bounded reason code and are emitted once per reason per resource run.

## Connections and authority boundary

1. `item-system` renders a container's weapon item client-side.
2. The client `weaponcap` export reads the local ped's current GTA weapon/ammunition state and calculates a presentation amount.
3. `item-system` sends that client-calculated amount to remote `moveFromElement`.
4. The current server handler uses the submitted `ammo` value when splitting the stored weapon item and granting live ammunition. It does not call the server `weaponcap` export to derive the amount.

Step 4 means this resource does **not** enforce ammunition capacity for the inventory transaction. A modified client can submit a different amount, and the broader handler still identifies the actor through event `source` rather than binding MTA `client`. This is existing [Issue #213](https://github.com/itschase/OwlMTA-2026/issues/213), not a reason to duplicate the tracker. The correct fix belongs at the server mutation boundary: bind the actor to `client`, resolve the item/container from server state, recompute a safe grant, validate access/proximity/state, and settle the split atomically or through recoverable staging.

`weapon` owns a separate loaded-ammunition synchronization/reload/unload flow tracked in [Issue #287](https://github.com/itschase/OwlMTA-2026/issues/287). Do not confuse that with this inventory-container cap preview.

## Source-confirmed follow-up

- **Invalid IDs and negative remaining capacity — fixed in source, runtime open.** [Issue #549](https://github.com/itschase/OwlMTA-2026/issues/549) can be closed only after the fixed source is published and its remaining disposable-runtime matrix is recorded.
- **Dormant donor fields — policy open.** [Issue #550](https://github.com/itschase/OwlMTA-2026/issues/550) must resolve whether the second table values are obsolete or an intended entitlement. If retained, the server must read authoritative supporter entitlement; a client value must never increase a grant.
- **Inventory pickup remains client-declared — unresolved.** Reuse [Issue #213](https://github.com/itschase/OwlMTA-2026/issues/213) for caller, ownership, proximity, capacity, grant, and settlement hardening. The client helper remains presentation only.
- **Duplicated policy.** Client/server cap tables can drift. Move them to one server-owned configuration/domain service with a minimal client presentation snapshot after the authoritative inventory path is designed.
- **No command modernization needed.** The resource has no commands. Its future UI contribution is an inventory capacity indicator and contextual pickup feedback.

## Runtime verification still required

In a disposable environment, test every valid weapon slot; invalid, fractional, string, nil, and out-of-range weapon IDs; invalid/destroyed ped elements; exact, below, and above combined cap; same-slot weapon conflicts; server export availability; item-container pickup with partial stacks; forged negative/oversized/NaN-like client payloads at the `item-system` boundary; resource restart; and client/server table parity. No runtime behavior has been validated.
