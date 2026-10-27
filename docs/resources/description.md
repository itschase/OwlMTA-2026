# `description`

## Status and evidence

- Resource path: `mods/deathmatch/resources/description`.
- Tree/startup state: active and enabled in the tracked startup snapshot; live deployment state unverified.
- Source review: all four manifest-loaded scripts and the settings/vehicle-loader paths that connect to them reviewed.
- Runtime: unverified. The MTA server has not been started for this review.
- Individual GitHub Discussion: pending publication with the standardized title `Script Resource: description`.
- Follow-up: [Issue #350](https://github.com/itschase/OwlMTA-2026/issues/350) tracks admin-field server authorization and payload validation; [Issue #351](https://github.com/itschase/OwlMTA-2026/issues/351) tracks a corrected vehicle-owner activity display.

## What it does

`description` draws world-space overlays for nearby vehicles, property/interior entrances, and readable note items. It is a presentation resource: vehicle ownership, interior status, permissions, prices, and item values come from other systems. It also provides the vehicle-description editor and persists up to five public description lines plus a separate administrative description.

## Player experience

- Hold Left Alt to show nearby vehicle/property overlays and text on nearby note items. Right Alt pins or unpins the vehicle/property overlay; the note overlay also supports right Alt to toggle its display.
- Vehicle overlays can show vehicle model/year/brand, player-authored description lines, plate/VIN according to the vehicle's show settings, and (for dealership stock) purchase price and taxes. Owner/staff presentation can include ownership, shop, and activity/inactivity information.
- Property overlays show the entrance name, exterior address, sale or lease price when available, business note, and context-dependent protection/activity or interior ID information.
- Note overlays read the text stored on item ID 72 objects.
- F10 graphic settings control the global and per-type overlay toggles, fonts, and visual preferences. Settings are stored and loaded by the account settings resource; this resource reads the resulting player element data.
- `/ed` and `/editdescription` open the vehicle description editor while seated in a vehicle. The interface has five regular lines and an admin line intended for trial admins. Saving is performed by a server event.

## Staff, donor, and Discord boundary

The resource contains no Discord integration and no staff-management command. Its overlay presentation reads local staff/on-duty information to decide whether to display selected vehicle/interior details. The vehicle edit path accepts vehicle key/item, owner, faction-membership, or trial-admin access according to existing source rules.

Supporter/donor status is not staff authority. In particular, an element-data flag such as `duty_supporter` is used by the client presentation to show hidden VIN text when the vehicle has `show_vin == 0`; this is display behavior, not a permission grant. Any future Discord role mapping should grant only named server-side capabilities at action boundaries. The server must retain vehicle ownership/key/faction association, staff status, vehicle state, and field-specific authorization checks. A client-side hidden/disabled control is never authorization.

## Technical map and connections

| File | Runtime | Responsibility |
|---|---|---|
| [`meta.xml`](../../mods/deathmatch/resources/description/meta.xml) | Manifest | Loads the client vehicle/property/note overlays and the server vehicle-description saver; distributes `BizNote.ttf`. No exports are declared. |
| [`c_vehicle_descriptions.lua`](../../mods/deathmatch/resources/description/c_vehicle_descriptions.lua) | Client | Left/Right Alt controls, vehicle overlay rendering, `/ed` and `/editdescription`, local editor, and `saveDescriptions` request. |
| [`s_vehicle_descriptions.lua`](../../mods/deathmatch/resources/description/s_vehicle_descriptions.lua) | Server | Checks vehicle-description eligibility, persists description fields in `vehicles`, and updates protected vehicle element data. |
| [`c_property_descriptions.lua`](../../mods/deathmatch/resources/description/c_property_descriptions.lua) | Client | Finds nearby interior entrance elements and draws price, address, business, ownership/status, and interior-ID overlays. |
| [`c_note_descriptions.lua`](../../mods/deathmatch/resources/description/c_note_descriptions.lua) | Client | Finds nearby objects with item ID 72 and draws their `itemValue` as a readable note. |

Important connections:

- `account/f10-settings` supplies persistent per-player overlay options and font settings. A local `description:updateOwnView` event updates whether the vehicle overlay hides the player's own vehicle in pinned mode.
- `[vehicle]/vehicle_load/load_s.lua` hydrates vehicle description fields from the vehicle record into protected element data.
- `vehicles.description1`–`description5` and `descriptionadmin` are the persistent vehicle fields. The tracked `mta.sql` schema declares the fields as `varchar(300)`.
- `vehicle` supplies impound/activity/protection helpers and `datetime` supplies relative-time formatting. `interior_system` supplies protection/activity and interior-ID visibility checks.
- `global`, `factions`, `integration`, `cache`, `pool`, `mysql`, `anticheat`, and `hud` provide nearby-element, ownership/key, staff/faction, name-cache, database, protected-data, and notification services.
- Item-system object element data supplies note object identity and note text; this resource only renders the item value.

## Source-confirmed findings and fixes

- The vehicle overlay's active-state owner branch used undefined `powner` despite defining `vowner`. It now compares the player's character ID to `vowner`. [Issue #351](https://github.com/itschase/OwlMTA-2026/issues/351) remains open for runtime visibility verification.
- The client disables the sixth editor field for non-trial-admins, but the remotely callable server event previously accepted `descriptions[6]` from any caller eligible to edit ordinary vehicle descriptions. It now binds the event to authenticated `client`, requires `source == client`, derives the occupied vehicle server-side and checks it matches the requested vehicle, validates table/string types and the 300-character schema limit, and rejects the admin field unless the caller is a trial admin. This is fixed in source only; [Issue #350](https://github.com/itschase/OwlMTA-2026/issues/350) tracks runtime checks and remaining persistence consistency review.
- The client draws `description:admin` as part of the vehicle overlay without a client-side staff visibility condition. The field is staff-authored, but the current implementation does not make it private to staff. Confirm intended audience before changing display policy; do not store confidential notes there.
- `c_property_descriptions.lua` assumes interior elements provide structured `status` and `entrance` element data. Those values are initialized by the interior system; startup/partial-load behavior remains to be verified.
- Overlay lists are gathered when shown and refreshed by timers while pinned. Note text is cached when its overlay activates, so updates to an existing note while the display remains active may not appear until it is toggled or refreshed; confirm behavior in runtime before changing this lifecycle.

## Discord and API boundary

No role is required to read public vehicle/property/note overlays. Vehicle-description changes are a local gameplay action and should not require a Discord call. A future global staff capability may gate the administrative description field, but the server should query that capability only for a verified staff action and keep the local account/vehicle checks. Donor/Supporter levels remain independent of staff roles.

## Validation plan (not yet run)

After the static safe-start gate, verify Left/Right Alt and pinned behavior for all three overlay types; F10 preferences across logout/relogin; vehicle/property visibility across dimensions and interiors; item-note refresh and line wrapping; public/admin description authorization with forged event source and target; database errors and oversized/malformed values; and correct activity display for owner, staff, and unrelated players. Confirm whether administrative description text is intentionally public. Keep these runtime results separate from source review.
