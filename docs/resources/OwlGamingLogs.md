# `OwlGamingLogs`

## Status and evidence

- Resource path: `mods/deathmatch/resources/OwlGamingLogs`.
- Source review: manifest and client logger reviewed with F10 account settings and phone log producer/consumer callers.
- Runtime: unverified. MTA was not started; actual local file creation, persistence, and log rotation are unverified.
- Startup snapshot: enabled in `mtaserver.conf.bak`; this is not proof of live configuration.
- GitHub record: individual Script Resource Discussion pending; phone-content privacy work tracked by [Issue #465](https://github.com/itschase/OwlMTA-2026/issues/465), assigned to [Milestone #7](https://github.com/itschase/OwlMTA-2026/milestone/7). The separate 911 history access policy is tracked by [Issue #340](https://github.com/itschase/OwlMTA-2026/issues/340).

## Purpose in everyday terms

This client-side resource writes the player's visible chatbox messages to local HTML files and phone call/SMS transcripts to local text files. It provides an information dialog explaining phone transcript logging. It does not provide staff log search, central server log storage, webhooks, Grafana integration, or a server-side log viewer.

## Player guide

- In F10 Game Settings, `Enable client logging of chatbox` controls the local chat transcript.
- In F10 Game Settings or phone settings, `Enable client logging of calls & SMS` controls whether the phone system collects and writes local transcripts.
- Phone call/SMS entries are accumulated on the server while the relevant setting is not `0`. The `/writephonelogs` command asks the server to send the current character/line's buffered conversation entries back to that same player; the client then writes them locally. It is a session buffer/export flow, not a query of the persistent SMS database.
- The client file paths constructed by the script are `Chatbox/YYYY-MM-DD/HH.html` and `Cellphone/<character name>/From <number>/<Calls or SMS>/To <number>.txt`, relative to this resource's local files.
- These files contain personal conversation content. Players should know which records are kept, how to disable logging, and how to delete their local copies. Current source has no in-game deletion/retention UI.

## What the code currently does

| File or caller | Responsibility |
|---|---|
| `c_log.lua` | Opens an hourly HTML log, receives `onClientChatMessage`, formats message/time/color nodes, writes phone transcript text, and shows/closes the logging information box. |
| `meta.xml` | Loads `c_log.lua` client-side and exports the three client functions used by account/phone UI. |
| `account/f10-settings/c_f10_settings.lua` | Exposes chat and phone logging toggles. The checkbox is considered enabled whenever the stored setting is not exactly `0`. |
| `account/f10-settings/s_f10_settings.lua` | Accepts these account setting keys; the allowlist marks them as supported booleans. |
| `phone/phone_logs_s.lua` | Buffers call/SMS transcript lines by character and phone number, then sends the requesting player's current buffered transcript to their client for local writing. |
| `phone/phone_logs_c.lua` | Accepts the server's transcript event only when its event source is the local player and passes each line to `OwlGamingLogs` for local writing. |

The source-level effective behavior is opt-out: the phone producer tests `cellphone_log ~= "0"`, and the chat recorder checks `graphic_logs == "0"` as the disabled case. Missing settings therefore do not disable these paths. Confirm defaults for new and existing accounts against the database/settings load path before changing migrations.

## Staff and server-operator notes

There are no staff commands, server scripts, server exports, or server-side search tools in this resource. The resource itself writes local client files. However, `phone/phone_logs_s.lua` also sends each message-bearing log line through `outputDebugString`; this places private phone text into shared server debug output when phone logging is active. Issue #465 tracks redacting that content, clarifying opt-in behavior, and reviewing retention. Treat deployed server logs and any later log sinks as potentially containing private text until this is fixed and older logs are addressed.

This finding is separate from [Issue #340](https://github.com/itschase/OwlMTA-2026/issues/340), which concerns authorization to read in-memory emergency/911 records. Do not treat local transcript settings as staff permissions or Discord capabilities.

## Discord, APIs, and future logging adapters

Discord roles should not grant access to player transcripts by default. If staff audit/search is later introduced, define explicit purpose, actor authorization, access auditing, minimization, retention, and player notice first. A Discord webhook, Grafana/Loki pipeline, or other external sink must receive redacted event metadata by default, not chat/SMS bodies. No such external delivery exists in this resource today.

## Follow-up

1. Resolve [Issue #465](https://github.com/itschase/OwlMTA-2026/issues/465): remove phone text from server debug output; determine a consent-safe default; close active client files and stop writes immediately when disabled.
2. Decide transcript retention/deletion behavior and document the file location and contents in the player guide.
3. Review all phone log triggers and settings-load paths, including what happens when a character/account changes during a call.
4. Check file-handle creation failures and date/hour transitions; measure behavior only in an approved disposable MTA client after safe-start preparation.
5. Keep 911 history authorization and transcript privacy as separate policies/issues.

No runtime behavior or external log sink is claimed as verified.
