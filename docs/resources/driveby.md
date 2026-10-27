# `driveby` resource

**Review state:** Full manifest/client/server/export review. Parsed settings and multiplayer behavior remain runtime-unverified.

## Player workflow

`driveby` enables the configured weapon set for eligible vehicle occupants. The client checks local vehicle model, seat, weapons/ammunition, and configured options; players use mouse and Q/E controls to toggle and cycle through eligible weapons. These are client behavior gates, not server-side authorization or anti-cheat guarantees.

## Configuration and API

The server loads driver/passenger weapon lists, per-weapon shot delays, blocked vehicle models, steering options, and auto-equip from resource settings. A client handshake returns the settings table to the requesting player. Ten client exports change/read weapon lists, delays, steering, and auto-equip; no direct external resource callers were found. Export calls must use the client side and should wait until settings have been received.

There is no database, player persistence, command, staff workflow, or Discord authorization in this resource. Operators configure it through its MTA settings and resource startup order.

## Source findings and open questions

- **Passenger weapon sanitization edits the driver table.** `driveby_server.lua:20–24` loops through `settings.passenger` but removes invalid entries from `settings.driver`. Invalid passenger IDs remain and driver entries at corresponding indices can be removed. Track as [Issue #383](https://github.com/itschase/OwlMTA-2026/issues/383).
- Server and client weapon-list sanitizers remove from an array while iterating with `ipairs`; adjacent invalid entries may be skipped as indexes shift. This is a source-derived validation risk; include it in the same eventual repair.
- `meta.xml:23` contains `570472` in the blocked vehicle list, while the server fallback has separate `570` and `472` values. The MTA setting parser's handling of this malformed list and resulting blocked models need runtime/config verification; do not claim a confirmed runtime impact.
- Export setters mutate client settings that a later server handshake response can replace. Start ordering and whether a dependent resource calls before the response are runtime questions. `setDrivebySteeringAbility` also lacks a success return unlike sibling setters.

## Discord and future UI

Driveby eligibility is ordinary gameplay and should not depend on staff or supporter roles. Any future vehicle menu can surface available controls, but it should retain local seat/vehicle/weapon rules and not imply server authority based on client UI. Discord staff capabilities are irrelevant unless a separate operator configuration tool is added.

## Runtime verification

On a disposable client/server setup, inspect parsed MTA setting values, driver/passenger list sanitation, adjacent invalid setter entries, handshake/start ordering, each vehicle/seat/weapon restriction, shot delay transitions, resource stop, and multiplayer synchronization. No server or tests were run.
