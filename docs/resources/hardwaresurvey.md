# `hardwaresurvey` resource

**Review state:** Full active manifest, client/server event, JSON persistence, and staff-read path reviewed statically. Runtime behavior and the actual handling of empty files by the installed MTA build remain unverified.

**GitHub record:** [Script Resource Discussion #544](https://github.com/itschase/OwlMTA-2026/discussions/544); [Issues #451](https://github.com/itschase/OwlMTA-2026/issues/451) and [#452](https://github.com/itschase/OwlMTA-2026/issues/452) track JSON initialization and remote sample bounds.

## What it measures

Despite its name, the shipped client reports only the player's screen resolution when this resource starts. It hashes the `resolution//<width>x<height>` pair and creates a private client-side marker file so the same client does not resubmit that exact value on later starts. The server aggregates counts by resolution in `hws.json`; this source does not attach an account, character, serial, IP, or player name to each count. `/hws resolution` lets an administrator view the aggregate table through `integration:isPlayerAdmin`.

The manifest loads one server and one client script, declares no exports or resource dependencies, and the startup inventory marks the resource as not startup-listed. The server script nevertheless calls the `integration` export when the staff command runs. Operators should decide whether this measurement is wanted, disclose its collection/retention policy, and avoid treating the existing client-side hash marker as server-side identity or consent.

## Persistence and issues

The checked-in `hws.json` is zero bytes. `loadJSONData` reads it and passes any truthy result to `fromJSON`; MTA documents that `fromJSON` returns nil for invalid JSON. Lua treats an empty string as truthy, so the fallback object is skipped and the server's `data` may become nil. The later event then indexes `data[key]`. This source finding is recorded in [Issue #451](https://github.com/itschase/OwlMTA-2026/issues/451). Review the MTA contracts for [`fromJSON`](https://wiki.multitheftauto.com/wiki/FromJSON) and [`fileRead`](https://wiki.multitheftauto.com/wiki/FileRead); runtime confirmation has not been performed.

The remotely triggerable `hws` event accepts caller-provided keys and values, writes a count for each accepted value, and serializes the entire JSON table after every event. It has no format/size validation, per-player rate limit, distinct-value cap, or write batching. These gaps can produce malformed data, unbounded distinct values, and excessive synchronous file writes. They are tracked separately in [Issue #452](https://github.com/itschase/OwlMTA-2026/issues/452).

## Authorization and future direction

Reporting a screen resolution is ordinary telemetry and should remain independent of Discord roles, but collection should be explicit, minimal, bounded, and documented. Reading the aggregate with `/hws` is an operator/staff action; the inherited numeric admin check should migrate to a narrowly named capability at the server command boundary. A future stats/observability layer could replace this one-off JSON file with retention and aggregation shared across resources, while preserving privacy and avoiding account-level profiling unless the server operator has a clear, disclosed need.

## Runtime verification

No MTA server was started and no test was run. Before enabling this resource, start it in a disposable environment with the empty file, confirm the fallback/first report behavior, test invalid JSON and file-open/write failures, submit malformed and repeated remote values, inspect file growth and admin visibility, and verify that the client-side marker does not get mistaken for a server identity or consent record.
