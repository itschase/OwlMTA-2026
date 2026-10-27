# `datetime`

## Status and evidence

- Resource path: `mods/deathmatch/resources/datetime`.
- Tree/startup state: active and enabled in the tracked startup snapshot; live deployment state unverified.
- Source review: all manifest-loaded files and representative direct consumers reviewed; the call graph is broad and the stored-value audit remains incomplete.
- Runtime: unverified. The MTA server has not been started for this review.
- Individual GitHub Discussion: pending publication with the standardized title `Script Resource: datetime`.
- Implementation tracker: [Issue #346](https://github.com/itschase/OwlMTA-2026/issues/346) for timestamp contract and IPPC classification.

## What it does

`datetime` is a shared time utility. It initializes a server clock value from MySQL, provides a client-side approximation of that value, formats elapsed/future intervals, converts date strings to numeric timestamps, and exports those functions to other resources.

The library is a common dependency for player-facing “last seen” text, item and vehicle timestamps, clothing distribution windows, property/interior activity, notifications, phone history, payday, and the in-game airline/flight board. A change to its epoch or timezone rules can affect many features and stored values.

## Player use

Players generally see its output indirectly: “Just now,” elapsed/future intervals, clothing arrival/distribution periods, activity history, phone timestamps, and the IPPC flight board's past/future filters. The resource also registers a `/now` debug command on both client and server; it prints raw server/client diagnostic values and is not a normal gameplay command.

No Discord identity or role is needed to format or view time. Any moderation decision based on a time window belongs to its owning feature and must remain server-authoritative; a client-readable clock is presentation data, not proof for permissions or settlement.

## Operator and developer guide

- Manifest: [`meta.xml`](../../mods/deathmatch/resources/datetime/meta.xml).
- Shared implementations: `datetime_g.lua` is loaded in server and client contexts; side-specific clock synchronization is in `datetime_s.lua` and `datetime_c.lua`.
- The server reads `TO_SECONDS(NOW())` on resource start, stores it with an MTA Unix timestamp, then advances it by elapsed seconds.
- A client requests the server clock on resource start and advances the received value with its own MTA Unix timestamp. This is a display/utility approximation; drift and reconnect behavior need runtime measurement.
- Exports available on both sides include `formatTimeInterval`, `formatFutureTimeInterval`, `formatSeconds`, `now`, `getTimestamp`, and `datetimeToTimestamp`.
- `minutesToDays` is defined in shared code but is not declared as a manifest export. Its formula currently divides minutes by `minutes * 60 * 24`, returning zero for ordinary positive values; no callers were found in the audited resource trees.

## Timestamp contract and important defect

The current source has incompatible timestamp bases:

1. `now()` starts from MySQL `TO_SECONDS(NOW())`, which MySQL defines as seconds since year 0, then adds elapsed seconds.
2. `getTimestamp()` and `datetimeToTimestamp()` construct Unix-epoch seconds (seconds since 1970) through a manual calendar conversion and fixed GMT/DST adjustments.
3. `computers-system/websites/ippc.lua` compares `datetimeToTimestamp(eta/etd)` against `datetime:now()`. The values are not the same scale. The predicate then treats `eta <= now` as a future flight, reversing the comparison too.

The combined source logic can classify past and future flights incorrectly. Do not change `now()` to Unix seconds as a local cleanup: multiple resources persist or compare its current numeric values, so a migration and compatibility review are required. Choose one documented epoch/timezone contract for server values, client formatting, SQL dates, and persisted numeric columns before changing behavior.

MTA documents `getRealTime().timestamp` as Unix seconds since 1970 and its `localTime` argument as timezone adjustment. MySQL documents `TO_SECONDS()` as seconds since year 0 and `UNIX_TIMESTAMP()` as Unix time; these are not interchangeable.

## Resource connections

Direct callers include:

- `computers-system/websites/ippc.lua` — reads the current clock and converts SQL date-time strings to classify flight times.
- `[vehicle]/vehicle`, `vehicle_manager`, `description`, `interior_system`, and `elevator-system` — record or display last-use and owner-login times.
- `clothes` — creates/compares distribution and arrival timestamps; its decisions are server-side, while formatting may be shown client-side.
- `announcement`, `phone`, `social`, and `item-world` — display event, message, login, or item timestamps.
- `payday` and jail UI — format durations rather than absolute dates.

Search and audit consumers before changing the common contract. `now()` is persisted in element data or resource-owned records in multiple systems; all writes, readers, sorting, filters, and legacy rows must be included in any migration plan.

## Source-confirmed notes and follow-up

- [Issue #346](https://github.com/itschase/OwlMTA-2026/issues/346) tracks the epoch mismatch, reversed IPPC future/past predicate, invalid date handling, and the unused `minutesToDays` helper.
- Startup initialization indexes the MySQL result's `timesec` field without an explicit local nil/error guard. Confirm the MySQL export's failure contract and define whether this resource should fail clearly or expose degraded clock state during database outage.
- `getServerCurrentTimeSec` previously responded to the request event's `source`. It now binds the caller to MTA's authenticated `client`, requires source equality, and targets the response to that caller. This is fixed in source only; [Issue #349](https://github.com/itschase/OwlMTA-2026/issues/349) tracks client-routing verification and review of related remote events.
- The manual timestamp helper subtracts fixed timezone offsets using the current `isdst` flag. Review it against MTA's `getRealTime` behavior for historical dates and daylight-saving transitions before replacing it with SQL or another canonical conversion.
- MTA's [getRealTime](https://wiki.multitheftauto.com/wiki/GetRealTime) reference documents Unix timestamps and local-time adjustment. MySQL's [date and time functions](https://dev.mysql.com/doc/refman/8.0/en/date-and-time-functions.html) distinguish `TO_SECONDS` from `UNIX_TIMESTAMP`.

## Discord and API boundary

No command or export in this resource grants staff or donor authority. Time formatting and synchronization should remain a utility service. If a feature uses time to gate an administrative action, that feature must check its own server-side named Discord capability through the Owl facade, then retain its local target, state, and persisted-time validation. The clock value itself must never grant authority.

## Validation plan (not yet run)

In a disposable supported MTA/database environment, verify server/client clock synchronization and drift; absolute epoch values; timezone and daylight-saving boundaries; valid/invalid date parsing; elapsed/future formatting; IPPC future and past ETA/ETD at the exact boundary; stored timestamps from existing records; resource restart/database failure behavior; and representative callers across vehicles, interiors, clothing, phone, and announcements. For any epoch migration, test old-row conversion, rollback, and mixed-version compatibility. Keep source evidence distinct from runtime results.
