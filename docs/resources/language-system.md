# `language-system` resource

**Review state:** Full active manifest, language inventory flows, player UI/events, persistence fields, and chat/phone/admin/item/donor callers reviewed. Language rendering and character-switch behavior remain runtime-unverified.

## Player experience

Players can view learned languages with F6, choose a current language, unlearn a language, and speak through language-specific chat commands generated from the language catalog (including `/en`, `/fre`, and `/ws` aliases). Characters can know up to three languages, each with a skill value. When speakers and listeners have different skill levels, chat and some phone/interior communication paths can obfuscate part of the message and increase the listener's language skill through roleplay.

Players can learn languages from inventory items. Donator purchase flows can grant a language or restore a previous skill level. Admin commands also add or remove character languages. These are distinct entry points: the player event must not be allowed to call the privileged server exports on another player's character.

## Persistence and connected systems

Language IDs, three language slots, per-slot skills, and the current language slot are stored in character fields (`lang1`–`lang3`, `lang1skill`–`lang3skill`, and `currLang`) and mirrored to element data. `mysql` persists these fields; `anticheat` updates protected element data. `chat-system`, `phone`, and `interior_system` use `applyLanguage`; `item-system`, `donators`, and `admin-system` call language-management exports. The language catalog and display names are supplied by shared scripts/data.

Ordinary language use and learning are gameplay features and require no Discord staff role. Any future API or Discord account association must use trusted account/character identity, not the session ID or language slot.

## Source findings

- The remotely callable `useLanguage` and `unlearnLanguage` handlers operate on event `source` without binding the actor to server-side `client`; they can update a different player's element data and character fields. See [Issue #437](https://github.com/itschase/OwlMTA-2026/issues/437).
- `getNextLanguageSlot` returns `1` whenever any language slot is occupied, even if slot 1 is empty. `unlearnLanguage` uses it to select the current slot after a language is removed, so removing the first language while retaining another can leave `currLang` pointing to an empty slot. See [Issue #438](https://github.com/itschase/OwlMTA-2026/issues/438).

These are source-confirmed observations; no live exploit or runtime failure was tested.

## Future interaction and operations

A language panel can combine learned-language inventory, skill progress, current-language selection, and item-based learning without making `/F6` or speech aliases the only entry point. Preserve the character-owned data model and expose one server operation for each owner action. Admin/donor item grants should retain their distinct existing policies and audit logs.

Before enabling, verify all character columns exist in the imported schema and that `mysql`, `anticheat`, `pool`, `chat-system`, and the direct language-management callers are available. The manifest lists the shared language catalog as both server and client code, so treat it as client-visible rather than secret.

## Runtime verification

On a disposable instance, verify learning by item/admin/donor flow, three-slot limits, skill progression, speaking and listener obfuscation, current slot selection after removing each slot, forged-source events, character changes, database failures, and reconnect persistence. No MTA server or tests were run.
