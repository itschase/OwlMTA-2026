# `sfxbrowser` resource

**Review state:** Full manifest, GUI workflow, data catalog, and playback lifecycle reviewed. Audio availability and client performance remain runtime-unverified.

## Purpose and player/staff use

`sfxbrowser` is a client-only developer utility for browsing and previewing the GTA:SA sound-effect banks with `playSFX`. The `/sfxbrowser` command opens or closes a local GUI containing container, bank, and sound lists, a loop option, playback/progress controls, and a generated Lua snippet showing the selected `playSFX` call. The bundled data file is a catalog of sound indexes and descriptive labels; it does not play sounds automatically or change server state.

The resource declares no server scripts, remote events, exports, SQL access, or staff permission checks. Any connected player with the resource available can invoke the local command; document it as a client utility rather than a privileged server control. The generated snippet is informational text; selecting it does not execute code.

## Dependencies and operation

The manifest loads `sfxBrowser.lua` and `sfxBrowser_data.lua` client-side and requires MTA client 1.3.4. Playback depends on the player's local GTA audio assets under `GTASA\Audio\SFX`; missing files produce an in-game warning. The GUI stops the current sound when closed or playback is replaced, and progress is polled by a timer. Verify the timer and sound element are always cleaned up after resource stop or failed playback.

## Future considerations

This is an optional developer/audio-reference resource, not a roleplay mechanic. Keep it out of ordinary player-facing help unless operators intentionally expose it. If retained for staff sound design, add permission only if the sound catalog itself should be restricted; do not attach Discord staff or donor roles to a client-only preview without a concrete need. A future in-game sound design panel should reuse the existing sound API and provide a visible preview/stop action.

## Runtime verification

On a disposable client, verify command toggling, each list selection, loop behavior, missing SFX files, progress updates, rapid selection changes, resource stop, and whether playback remains local. No MTA server or tests were run.
