# `data`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: starts immediately after `mysql`; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified.

## What it does

`data` is an in-memory state handoff and JSON-file utility. Despite its manifest description, it is not the main SQL database. It stores arbitrary Lua values by access key, supports one-use destructive reads, preserves selected state through an orderly resource restart using root element data, maintains report and faction-purchase-log tables in memory, and provides JSON/base64 conversion and file helpers.

## Player and staff use

There is no direct player workflow. Other resources use it to carry state across resource restarts. A one-second timestamp on the root element is also exposed through a shared getter.

## Operator use

Generic in-memory data does not survive a process crash or full server restart. Stored element references may be stale after dependent resources restart. JSON helpers use `JSON_FILES/*.json` and private client `@JSON_FILES/*.json` paths; the current save path deletes the old file before proving the replacement can be written.

Operators should treat `data` as ephemeral coordination state, never as an authoritative database or backup.

## Technical map

- Manifest: [`mods/deathmatch/resources/data/meta.xml`](../../mods/deathmatch/resources/data/meta.xml)
- Handoff/state helpers: [`general.lua`](../../mods/deathmatch/resources/data/general.lua)
- JSON helpers: [`json.lua`](../../mods/deathmatch/resources/data/json.lua)
- Important exports include shared `save`/`load`, JSON file and conversion helpers, report/purchase-log state, and the timestamp getter.
- No remotely triggered server event or HTTP export was found.

## Known risks and next work

- [Issue #119](https://github.com/itschase/OwlMTA-2026/issues/119) covers namespaces, lifetime/version rules, stale state rejection, explicit restart support, readiness, and failure-safe JSON replacement with the linked `pool` contract.
- Keys currently have no ownership namespace, expiry, version, or collision protection; `load` consumes the value.

Runtime verification must cover orderly resource restart, full process restart, stale elements, duplicate keys, destructive reads, report/log handoff, JSON write failure, and recovery without treating volatile state as persisted truth.
