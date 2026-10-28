# `phone`

## Status

- Tree state: active resource tree; legacy `s_ads.lua` exists but is not loaded by the manifest.
- Tracked startup snapshot: enabled; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review; several ownership paths are fixed in source.
- Runtime state: unverified.

## What it does

`phone` implements handheld and public phones, calls, SMS, contacts, history, settings, hotlines, phone logs, and small phone applications. Current calls are scripted state plus text/audio cues; this resource does not implement proximity or telephone voice transport.

## Player use

A player opens a cellphone item, currently item type `2`, which requests settings and opens the phone UI. From there the player can call numbers or hotlines, answer/end calls, use loudspeaker, send/read SMS threads, manage contacts, review history, configure power/privacy/directory/ringtones/tones/volume, and open linked browser or online-banking features. Public phones and hotlines provide alternate entry points.

## Commands and interaction opportunities

The active manifest loads the command handlers below. The older advertisement commands in `s_ads.lua` are excluded because that file is commented out in `meta.xml`.

| Command(s) | Current audience and use | Current interaction | Future direction and authorization |
|---|---|---|---|
| `/call [number or contact]`, `/fcall [owned number] [destination]` | Player initiates a call; `/call` uses an owned cellphone or a public-phone location, while `/fcall` selects one of the caller's own lines. | Phone dial screen already supports placing a call; the commands are fast shortcuts into that flow. | Keep both commands, but expose the same owned-line chooser and validated server call operation through the phone UI. Normal calling uses local account, item ownership, call-state, and recipient checks; it needs no Discord staff capability. |
| `/pickup`, `/hangup`, `/loudspeaker` | Player answers/declines or ends a call and toggles speaker mode. | The call window has answer/decline and end controls; the phone UI has a loudspeaker button. | Treat these as keyboard-accessible shortcuts to existing controls. Do not create a second call-state path. The server must continue deriving caller and call state itself. |
| `/p [message]`, `/plow [message]` | Caller sends text roleplay speech through an active call; both names share the same handler. | In-call typed speech is the current communication method. | Keep this text path for accessibility and fallback. A future voice adapter can add whisper/normal/shout distance and push-to-talk while preserving text and the same call, privacy, logging, and disconnect state. No Discord role is needed for ordinary call speech. |
| `/sms [number] [message]`, `/sms2` through `/sms20` | Sends from the caller's first or Nth phone item; the handler enumerates the server inventory and checks that line's power/ownership. | The phone's SMS app already offers recipient/thread selection and message composition. | The phone UI should select a specific owned line rather than requiring twenty memorized aliases. Keep aliases as optional expert shortcuts; use the same owner-checked send function, server phone privacy setting, recipient policy, and rate limit. |
| `/phonebook [partial name or number]` | Searches public directory entries; requires a phonebook item. | A command returns a short result list in chat. | Evaluate a searchable directory view opened from the phonebook item, with the same public-listing and secret-number filters. This is a player lookup and does not use Discord authority. |
| `/togglephone [line, number, or omitted]` | Turns an owned phone on or off; omission selects an available line. | Power controls are available in the phone settings UI. | Keep as a shortcut; route both paths through one server-owned power setting update and explicit result feedback. |
| `/setphonebook`, `/setphonebookname`, `/setpbname` | Changes or removes the caller's public directory listing for an owned line. | A phone settings/directory control is a better discoverable place for a multi-field listing and privacy choice. | Consolidate duplicate aliases in the interface while retaining command compatibility. Check ownership and persist visibility/name together; never let a UI replace those server checks. |
| `/writephonelogs` | Delivers the caller's buffered call/SMS transcript to their client when the per-player log setting permits it. | Command-driven retrieval of a personal record. | Add a call-history action to open the same transcript, preserving the caller-only boundary and retention policy; this is not a staff log-search grant. |
| `/show911` | Trial Admin **or Supporter** prints the most recent 30 in-memory 911 situation messages. | Staff-oriented chat output. | Consider a filtered emergency-log panel with an audit trail. Review the current Supporter predicate because Supporter is donor entitlement and the entries include caller identity and emergency descriptions. A staff capability such as `phone.emergency_logs.read` is a proposal for the external Discord adapter, not an existing integration; a donor tier must not silently grant staff access. See [Issue #340](https://github.com/itschase/OwlMTA-2026/issues/340). |
| `/addphone`, `/nearbyphones`, `/delphone [ID]` | Trial Admin places a public phone at their current position, lists nearby IDs, or deletes a public phone record/colshape. | Direct staff/operator commands. | A map-based public-phone placement tool could preview position/dimension and show existing endpoints. Keep a staff shortcut. A proposed `phone.public_placement.manage` capability would be checked server-side through the Owl adapter boundary, with actor, dimension, target, and persistence checks retained locally. |

These proposals reuse the existing phone UI where it already exists. Discord authorization is not implemented in Owl; role IDs remain operator configuration in the separate identity service. See [`COMMAND_AND_INTERACTION_STRATEGY.md`](../planning/COMMAND_AND_INTERACTION_STRATEGY.md) for the cross-resource review standard and [Issue #327](https://github.com/itschase/OwlMTA-2026/issues/327) for the inventory.

Radio tuning belongs to `chat-system`, even though players encounter it as part of the broader communication experience.

## Staff and operator use

Calls and SMS generate central audit records. Phone directory/call behavior also connects to faction and donor systems. There is no single phone moderation dashboard today. The manifest-disabled advertisement file must not be documented as an active command surface.

Primary tables include `phones`, `phone_contacts`, `phone_sms`, `phone_history`, `mdc_calls`, `publicphones`, and the legacy `phone_settings`; linked character, faction, and banking resources own related state. Source logic removes SMS older than seven days and history older than thirty days.

## Technical map

- Manifest: [`mods/deathmatch/resources/phone/meta.xml`](../../mods/deathmatch/resources/phone/meta.xml)
- Core/UI: [`phone_core_s.lua`](../../mods/deathmatch/resources/phone/phone_core_s.lua) and [`phone_core_c.lua`](../../mods/deathmatch/resources/phone/phone_core_c.lua)
- Calls and billing: [`phone_dial_s.lua`](../../mods/deathmatch/resources/phone/phone_dial_s.lua) and [`phone_dial_c.lua`](../../mods/deathmatch/resources/phone/phone_dial_c.lua)
- SMS and contacts: [`phone_sms_s.lua`](../../mods/deathmatch/resources/phone/phone_sms_s.lua) and [`phone_contacts_details_s.lua`](../../mods/deathmatch/resources/phone/phone_contacts_details_s.lua)
- Settings: [`phone_settings_s.lua`](../../mods/deathmatch/resources/phone/phone_settings_s.lua)
- Important direct connections include `mysql`, `global`, `item-system`, `bank`, `factions`, `donators`, `anticheat`, `bone_attach`, `computers-system`, `logs`, `datetime`, `vehicle`, `pool`, `gps`, `integration`, `OwlGamingLogs`, and emergency/hotline systems.

Phone transcript details are documented in [`OwlGamingLogs`](OwlGamingLogs.md). Source review found that `phone_logs_s.lua` includes private call/SMS message text in `outputDebugString`, while the client transcript setting treats any value other than `0` as enabled. [Issue #465](https://github.com/itschase/OwlMTA-2026/issues/465) tracks redaction, explicit consent/defaults, and retention. This is separate from staff access to 911 history under [Issue #340](https://github.com/itschase/OwlMTA-2026/issues/340).

## Known risks and next work

- [Issue #55](https://github.com/itschase/OwlMTA-2026/issues/55) tracks owned-phone boundaries. In the current source, SMS requester/line ownership, sender privacy state, contact-row ownership, and contact field limits are fixed in source; the contact editor now sends its email field correctly. These changes are static-only and unverified in MTA. Remaining work includes contact/settings reads, power state, private-number charging order, positive/integer recipient policy, SMS throttling, and failure-safe persistence/feedback.
- [Issue #340](https://github.com/itschase/OwlMTA-2026/issues/340) tracks separating 911-log read access from donor/supporter entitlement and defining a named staff capability.
- [Issue #465](https://github.com/itschase/OwlMTA-2026/issues/465) tracks phone transcript privacy, server debug redaction, and explicit local retention controls.
- [Issue #83](https://github.com/itschase/OwlMTA-2026/issues/83) requires server-owned call ID/timestamps, one-time finalization, and failure-safe billing. The client-calculated cost cannot be made authoritative.
- Rejected operations often fail silently, leaving UI state ambiguous.

Voice-first modernization should reuse the phone-number, contacts, call-state, audit, and moderation layers while adding a separate server-authorized voice-routing adapter. Text fallback and accessibility controls remain required. Runtime verification must cover every owned/unowned phone path, calls, hotlines, SMS, contacts, settings, retention, billing, disconnects, and linked-resource failure.
