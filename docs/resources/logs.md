# `logs`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review.
- Runtime state: unverified; no log file was created or rotated in this rebuild.

## What it does

`logs` is the central local gameplay audit writer. Despite the legacy `dbLog` naming, it writes JSON-lines files rather than a database. Records include an action ID, origin, caller-supplied content, and relevant account, character, vehicle, interior, phone, faction, and object IDs.

## Player and staff use

Players do not directly operate it. Gameplay and staff resources call `dbLog` or `dbLogDetectTypeSource` to record state-changing or administrative actions. Staff-facing search is not implemented by this resource; the future operator search layer can forward or ingest these records through an optional adapter.

## Operator use

Files are written under `logs/log-<yearday>.log` and buffered for up to approximately one second. Retention currently attempts to remove one filename around three days old. The source does not guarantee catch-up cleanup, year-safe names, independent backup, forwarding, or recovery after file-operation failure.

Caller-supplied content can contain personal or sensitive gameplay data and has no shared redaction/size policy here. Optional Grafana support requires a separate log backend/collector such as Loki/Alloy; Grafana itself is not a storage engine and must remain optional.

## Technical map

- Logger: [`mods/deathmatch/resources/logs/s_logs.lua`](../../mods/deathmatch/resources/logs/s_logs.lua)
- Server exports: `dbLog` and `dbLogDetectTypeSource`.
- No remote event or HTTP export was found.
- The tracked ACL grants `resource.logs` `general.ModifyOtherObjects`; the reviewed writer did not show a need for that broad right.

## Known risks and next work

- [Issue #120](https://github.com/itschase/OwlMTA-2026/issues/120) covers year-safe rotation, retention catch-up, write/flush failure, redaction/limits, ACL reduction, backup, and optional forwarding.
- [Issue #22](https://github.com/itschase/OwlMTA-2026/issues/22) remains the broader effective-ACL audit.
- [Discussion #105](https://github.com/itschase/OwlMTA-2026/discussions/105) describes structured logs, metrics, Grafana/Loki, and optional adapters.

Runtime verification must cover normal writes, flush, restart, rotation, year rollover, missed-retention catch-up, unwritable/full disk, oversized/redacted content, ACL reduction, and external collector outage.
