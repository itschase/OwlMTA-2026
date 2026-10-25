# `chat-system`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified.

## What it does

`chat-system` turns MTA chat and commands into the roleplay communication layer: local speech, emotes, OOC channels, private messages, radios, faction/government/department and business channels, interview/news flows, staff channels and monitoring, chat bubbles/icons, restricted frequencies, and a small set of money-transfer commands.

## Player use

Normal chat becomes nearby in-character speech; action chat becomes `/me`; radio chat uses the active radio. Player commands include `/me`, `/do`, `/ame`, `/ado`, `/status`, `/b`, `/ooc`, `/district`, `/pm`, reply, `/r`, `/radio`, `/rlow`, numbered radio slots, `/tuneradio`, `/toggleradio`, faction channels, `/dep`, `/med`, `/air`, public-address commands, ignores, and channel toggles.

Radio access uses inventory items and faction membership for protected frequencies. Other manifest-active surfaces include business chat, interview/news controls, pay/charity, and staff big-ears/focus monitoring. Most messages are immediate and sent to the central log rather than stored as an inbox.

## Staff use

The resource includes admin, lead-admin, GameMaster, scripter, vehicle-consultant, mapping, faction-management, and government channels. Many checks combine legacy integration roles and duty state. Staff monitoring can receive PM traffic, and possible PM advertisement language produces an administrator notice.

These checks must move to action-specific named capabilities; supporter/donor status must not imply chat moderation authority.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/chat-system/meta.xml`](../../mods/deathmatch/resources/chat-system/meta.xml)
- Important direct connections include `global`, `logs`, `integration`, `factions`, `item-system`, language handling, `donators`, `help`, `freecam-tv`, `vehicle`, `cache`, `pool`, `mysql`, `social`, `anticheat`, `hud`, `interior_system`, and `sfia`. The active chat script also calls the archive-only `business` resource, so business-chat startup and behavior are an explicit dependency gap until that contract is restored or retired.
- Restricted frequencies persist in `restricted_freqs`; most channel state/preferences are account or element data owned elsewhere.
- The resource exports local/district speech, shout, department/general radio, language lookup, and truncation helpers.

## Known risks and next work

- [Issue #129](https://github.com/itschase/OwlMTA-2026/issues/129) covers remote restricted-frequency actor binding, staff capability, bounds, persistence, rate limits, and audit.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) remains the parent remote-event audit.
- A shared message-rate and abuse-control policy is not apparent across the command surface.

A voice-first design is a new transport layer, not current behavior. It should preserve text fallbacks, language/emote/faction policy, logging metadata, moderation, accessibility, and configurable text-RP disablement while adding server-authorized proximity, whisper/normal/shout, radio, phone, and staff-monitor routing. Runtime verification must cover range/dimension/interior audiences, every channel permission, ignores, rate limits, radio inventory/factions, staff duty, and logs.
