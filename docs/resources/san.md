# `san`

## Status

- Tree state: active resource; manifest, both loaded scripts, and the `gatekeepers-system` interaction path reviewed.
- Startup snapshot: enabled in `mods/deathmatch/mtaserver.conf.bak`; this is a checked-in snapshot, not evidence of a deployed server state.
- Source review: complete for the manifest scripts and direct greeting caller. No MTA runtime or live faction membership was checked.
- GitHub: [Script Resource: san #494](https://github.com/itschase/OwlMTA-2026/discussions/494); Issues [#491](https://github.com/itschase/OwlMTA-2026/issues/491), [#492](https://github.com/itschase/OwlMTA-2026/issues/492), and [#493](https://github.com/itschase/OwlMTA-2026/issues/493) cover this resource's event and recruitment work. Related photographer interaction Issue [#495](https://github.com/itschase/OwlMTA-2026/issues/495) is also assigned to `itschase` in [Milestone #7](https://github.com/itschase/OwlMTA-2026/milestone/7).
- Runtime and deployed-service behavior: unverified; MTA was not started.

## Purpose and player workflow

`san` implements a small front desk for Victoria Greene, an NPC associated with the San Andreas Network faction (faction ID 20). The client creates Victoria at `(1426.1455, 1366.7637, 11.3286)`, interior 3, dimension 1455, freezes her, and tags her with `talk` and `name` element data. The NPC is client-created; this resource does not create a persistent server entity.

The player approaches and uses the right-click interaction supplied by `gatekeepers-system`. That resource recognizes the name `Victoria Greene` and fires the local client event `cSANGreeting`. The SAN menu offers:

- **Contact Someone**: opens a one-line reason field and sends the typed reason to server event `SAN:CU`.
- **Work For Us**: sends `SAN:Job`; the response says there are paid positions and directs the player to a website. This resource contains no in-game application or next-step workflow.

The UI declines to open while another resource marks `exclusiveGUI`, and it prevents opening a second copy while its local `open` flag is set. It displays no command or bind for opening the front desk independently of the NPC.

## Staff and operator workflow

For a nonempty contact reason, the server responds to the caller through `global:sendLocalText`, queries `factions:getPlayersInFaction(20)`, and sends three radio-style chat lines to every returned SAN member. Those lines identify the caller's character name and include the submitted reason. When the returned list is empty, the caller receives a no-one-available response.

These contact requests are not saved as cases, written to a log, or presented in a staff queue. The broadcast is faction-wide rather than proximity-based. `san` defines no staff commands, operator settings, persistence schema, dashboard, or external API.

## Source map and dependencies

| File or resource | Role |
|---|---|
| `san/meta.xml` | Loads `c_victoria.lua` client-side and `s_victoria.lua` server-side. |
| `san/c_victoria.lua` | Creates the local NPC and GUI, gathers the reason, and triggers `SAN:CU` / `SAN:Job`. |
| `san/s_victoria.lua` | Replies to job requests and relays contact requests to faction 20. |
| `gatekeepers-system/c_ped_rightclick.lua` | Calls `cSANGreeting` when the clicked talkable ped's name is `Victoria Greene`. |
| `global` export | `sendLocalText` provides nearby in-character responses. |
| `factions` export | `getPlayersInFaction(20)` supplies SAN staff recipients. |

The SAN manifest declares no explicit dependency metadata for `global` or `factions`. The checked-in startup snapshot lists `global`, `factions`, and `gatekeepers-system` before `san`, but start/stop ordering and export availability have not been tested. Repository search found `cContactBox` registered in the client script with no active caller; the visible contact button calls the form directly.

### Adjacent SAN services

The shared faction identity connects this front desk to separate newsroom and media features, not through direct calls from `san`:

- `phone/s_hotlines.lua` defines the San Andreas Network hotline 7332 for faction 20; see the [`phone` dossier](phone.md).
- `chat-system` contains SAN interview/news commands and uses the newsroom faction; see the [`chat-system` dossier](chat-system.md).
- `job-system/photographer` contains a separate photography/recruitment UI that also uses Victoria's name and faction 20. Its ped setup is commented out, the active `cPhotoOption` event has no caller, and that handler references the commented `victoria` variable. [Issue #495](https://github.com/itschase/OwlMTA-2026/issues/495) tracks this disconnected interaction; [Issue #181](https://github.com/itschase/OwlMTA-2026/issues/181) already covers caller-controlled photo values and faction payout. These are adjacent systems and should not be mistaken for direct dependencies of `san`; see the [`job-system` dossier](job-system.md).

## Security, reliability, and future design

MTA documents that client-supplied event `source` and arguments can be forged and that server variable `client` identifies the caller of a remotely triggered event. `SAN:Job` currently uses `source` as the origin passed to `global:sendLocalText` and trusts the supplied `pedName`; [Issue #491](https://github.com/itschase/OwlMTA-2026/issues/491) tracks binding that reply to the real player and using a server-owned speaker identity.

`SAN:CU` trusts the provided speaker name and calls `string.len(reason)` before checking that the value is a string. It accepts unbounded requests without server-side login, location/world-context, or cooldown checks, then broadcasts to every faction-20 member. [Issue #492](https://github.com/itschase/OwlMTA-2026/issues/492) tracks input validation, server-side interaction checks, and anti-flood controls. This is a source-based risk assessment, not a runtime exploit demonstration.

The website-only response for **Work For Us** is a dead end for a server that has no companion website. [Issue #493](https://github.com/itschase/OwlMTA-2026/issues/493) tracks an in-game recruitment information and application/contact path, while keeping any website/API optional.

Discord integration should not decide in-character SAN membership or job acceptance. A future out-of-character staff capability may support moderation dashboards, but the local faction and recruitment workflow must remain authoritative. Supporter/donor tiers must remain separate from staff authority.

MTA references: [Script security](https://wiki.multitheftauto.com/wiki/Script_security), [triggerServerEvent](https://wiki.multitheftauto.com/wiki/TriggerServerEvent), and [Event](https://wiki.multitheftauto.com/wiki/Event).

## Runtime verification checklist

In a disposable environment, verify the NPC appears only in the intended interior/dimension; test the right-click menu while another exclusive GUI is open; exercise valid/empty contact reasons and the no-staff response; verify the recipients are exactly the intended SAN members; test event payload type/length, forged source/name, repeated calls, and requests outside the front desk; stop dependencies and observe failure behavior; and confirm all user-visible messages and staff alerts. None of these checks has been run.
