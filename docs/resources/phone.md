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

Commands include `/call`, `/fcall`, `/pickup`, `/sms` and numbered SMS shortcuts, `/phonebook`, `/togglephone`, `/setphonebook`, and phone-log utilities. Radio tuning belongs to `chat-system`, even though players encounter it as part of the broader communication experience.

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

## Known risks and next work

- [Issue #55](https://github.com/itschase/OwlMTA-2026/issues/55) covers remaining owned-phone scoping, contact/settings reads, power state, private-number charging order, recipient validation, and SMS throttling. Several SMS/contact/settings writes are already fixed in source and await runtime verification.
- [Issue #83](https://github.com/itschase/OwlMTA-2026/issues/83) requires server-owned call ID/timestamps, one-time finalization, and failure-safe billing. The client-calculated cost cannot be made authoritative.
- Rejected operations often fail silently, leaving UI state ambiguous.

Voice-first modernization should reuse the phone-number, contacts, call-state, audit, and moderation layers while adding a separate server-authorized voice-routing adapter. Text fallback and accessibility controls remain required. Runtime verification must cover every owned/unowned phone path, calls, hotlines, SMS, contacts, settings, retention, billing, disconnects, and linked-resource failure.
