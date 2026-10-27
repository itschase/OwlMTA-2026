# `help` resource

**Review state:** Full manifest-script and direct-caller source review. Runtime GUI, database, and permission behavior remain unverified.

## Player purpose and use

`help` is the legacy in-game onboarding and command-discovery surface. It includes a short Q&A window, an F1 help center with roleplay/rules content and a categorized command directory, a report form, static world-location blips, and a private-message URL-copy prompt. It does not provide a website or Discord login.

| Entry point | Current player use | Future interface to evaluate |
|---|---|---|
| `/helpme` | Opens a short FAQ with answers about command discovery, chat appearance, vehicle controls, key bindings, contacting staff, roleplay basics, commands failing, and where to seek help | Keep concise and searchable; link directly into the relevant help panel or contextual control |
| F1 key | Opens the Help Center after login, with local roleplay/rules/how-to XML, the categorized command directory, and Report Center | Add command search, filters, permission labels, copyable usage syntax, and links to relevant gameplay panels. The GUI and command index are the current alternatives to asking staff for routine guidance. |
| `/report` | Opens the Help Center/report workflow; player can choose a report type, enter details, and optionally select a player | Keep an accessible report panel and provide actionable status/receipt; detailed submission and staff queue behavior belongs to the `report` resource |
| PM containing a URL | `chat-system` calls the exported `startUrlSender`; recipient receives a read-only URL prompt to copy or dismiss. Current helper applies a per-sender/per-recipient three-second cooldown and checks that the target is logged in. | Retain as an explicit user-initiated clipboard action; validate URL scheme/length and ensure PM restrictions and filtering remain authoritative in `chat-system` |
| Map blips | Client sees static help-resource blips for public locations such as hospital, LSPD, City Hall, airport, DMV, and bank | Consolidate locations into configurable, named map points with availability and current service links rather than hard-coded coordinates |

The `commands/commands_help_c.lua` file contains `/help`, `/cmds`, and `/helpcmds`, but it is commented out of `meta.xml`; those are not active commands from this resource. The manifest loads `commands/help_c.lua` instead. Do not document dormant files as active behavior.

## Staff and command catalog

The dynamic command directory reads the `commands` table in the MTA database. It stores command label, hotkey, explanation, category, and a numeric visibility/required-rank field. The Help Center filters which rows a player sees using local integration predicates. These rows are documentation and visibility metadata; they do not enforce whether the actual gameplay command is authorized. Each command-owning resource must continue enforcing its own server-side access policy.

Staff edit the command directory through controls in the F1 UI; this resource registers no dedicated edit command. The server currently authorizes `saveCommand` and `deleteCommand` only for a Trial Admin using `client`. The client editor predicate previously also exposed controls to Supporters; that misleading donor-to-staff implication was removed in source during this review. The server check remains authoritative.

Current help visibility groups numeric permission values into broad classes: admin levels 0–10, supporters 11–20, VCT 21–30, mappers 31–40, and scripters 41–50. Supporter values share a single `isPlayerSupporter` decision rather than being distinguished by donor level. The client-side filter is a presentation decision, not a security boundary. A future Discord model should store named visibility capabilities and separate donor-tier requirements; do not let a Supporter grant command-catalog edit, moderation, or unrelated staff authority.

## Discord capability classification

Ordinary FAQ, help browsing, command search, reports, static map help, and receipt of a PM link do not need a Discord capability. Command-catalog editing is an existing staff-only operation and should remain bound to the current local Trial Admin permission until a reviewed capability migration replaces it. In the future, the action boundary may check a named capability through the Owl authorization facade and reusable Discord identity plugin, while validating submitted catalog data and preserving audit logs. Donor level remains a separate entitlement for visibility or supporter features. No role IDs or Discord requests belong in this resource; the external plugin is not integrated into Owl yet.

## Technical map and connections

- `meta.xml` loads `c_help.lua`, `c_blips.lua`, `url_sender/url_sender_c.lua`, `url_sender/url_sender_s.lua`, `commands/help_c.lua`, and `commands/help_s.lua`; it packages eight help XML files and the animation/image assets. `s_infopoints.lua` is an effectively empty placeholder. `commands/commands_help_c.lua` is not loaded.
- `commands/help_c.lua` binds F1, requests the command catalog on client resource start, builds Help Center/Report Center UI, displays local content, filters directory rows, and sends report/editor UI requests.
- `commands/help_s.lua` caches rows from the `commands` table and exposes a remotely triggerable list-refresh event. Save/delete handlers use the trusted `client` for Trial Admin authorization and SQL placeholders, but accept loosely validated field payloads and update the cache before checking `dbExec` success. Their follow-up call to `sendCmdsHelpToClient()` also runs inside the remote event context, so its use of ambient `source` must not be treated as a trusted broadcast recipient.
- The `commands` table is defined in [`mta.sql`](../../mods/deathmatch/data/mta.sql); it uses MyISAM in the checked-in schema. Persistence and transaction guarantees therefore depend on the actual server database engine/configuration and are not verified here.
- `commands/help_c.lua` sends report submissions through `clientSendReport`, handled by the separate `report` resource. See [`report`](report.md) for the authoritative submission/staff workflow.
- `chat-system/s_chat_system.lua` invokes the server export `help:startUrlSender` when it detects a URL in a private message. The helper's direct `/link` and `/url` command registrations are commented out, with a source comment explaining the PM-blocker bypass concern.
- The resource's static map blips duplicate location knowledge that may also be owned by dedicated service/map resources; coordinates and current relevance need an in-game review.

## Source-confirmed findings and tracking

- **Command editor has a donor/staff presentation mismatch.** The server correctly checks Trial Admin for save/delete. The client also showed edit controls to Supporters; that client predicate is now Trial Admin-only in source. No runtime/UI validation was performed. Issue [#337](https://github.com/itschase/OwlMTA-2026/issues/337) remains open for server-side payload/schema validation and cache/error handling.
- **Catalog refresh can select a client-supplied recipient.** The remotely triggerable `sendCmdsHelpToClient` handler selects `player or source or root`; for client-originated calls, both the argument and event `source` are untrusted. Save/delete handlers also call this helper while still inside that remote event context, so the comment claiming to send to all players does not establish a trusted broadcast. Split the remote request path (recipient derived from `client`) from a server-internal refresh/broadcast path with explicit recipients. See [Issue #338](https://github.com/itschase/OwlMTA-2026/issues/338). This is a source-level recipient/flooding concern; command help data appears intended for players, and no confidential-data exposure is claimed.
- **Command metadata is not fully validated before persistence.** SQL parameters reduce injection risk, but category, permission range, field types/lengths, update IDs, and database result/cache coherence need explicit validation. See [Issue #337](https://github.com/itschase/OwlMTA-2026/issues/337).
- **Permission visibility is a legacy presentation mapping.** It uses numeric ranges and coarse predicates rather than named capabilities, and supporter tiers collapse to a boolean. Preserve the distinction between command documentation visibility and actual authorization; migrate only with the broader authority plan tracked by [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3).
- **The command editor mutates a MyISAM-backed catalog.** The checked-in schema gives no transactional rollback guarantee for synchronized database/cache updates; verify production DB engine and use deliberate update/reload semantics.

## Modernization opportunities

- Replace the manually edited command rows over time with a generated registry from command registration metadata, including canonical usage, audience, category, named capability, donor tier if relevant, and non-command UI route.
- Provide contextual help from the dashboard and third-eye/action menus, but keep commands and keyboard-accessible search available.
- Make routine support discovery self-service: searchable Q&A, permission-aware command results, guides attached to features, and in-game links to current report/service panels.
- Treat catalog editing as structured staff content management with schema validation, preview, audit event, post-save database confirmation, atomic refresh semantics, and operator-configurable categories.
- Reconcile static blips with a shared location registry and document operator options rather than baking duplicate coordinates into unrelated help UI.
- Keep URL forwarding tied to the PM policy owner; constrain safe schemes and clearly show who sent the link before offering clipboard copy.

## Runtime verification still required

After static review and safe-start preparation, verify `/helpme`, F1 pre/post-login behavior, every content tab, command permissions/visibility including distinct supporter levels, editor controls for Trial Admin versus Supporter, save/update/delete and cache refresh failure, report submission and receipt through `report`, PM URL copy/dismiss/cooldown/unlogged target, F1/UI input teardown, and all static blips against the current map. Confirm the deployed `commands` schema and engine. No server or tests were run for this review.

## MTA references

- [MTA event system](https://wiki.multitheftauto.com/wiki/Event): on the server, `client` identifies the player who triggered a remote event and is absent for server-internal event calls; event `source` is distinct from that trusted caller identity.
- [MTA script security](https://wiki.multitheftauto.com/wiki/Script_security): client-triggered event parameters and source elements should be treated as modifiable; derive the actor from `client`.
- [MTA `triggerLatentClientEvent`](https://wiki.multitheftauto.com/wiki/TriggerLatentClientEvent): the first argument controls recipients, while the event source element is a separate argument; avoid broad/root delivery where a specific player or resource scope is intended.
