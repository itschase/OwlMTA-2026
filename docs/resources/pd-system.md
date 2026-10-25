# `pd-system`

## Status

- Active startup resource; full manifest-script/source-caller review; runtime unverified.
- Discussion: [Script Resource: pd-system](https://github.com/itschase/OwlMTA-2026/discussions/236).

## Current behavior

`pd-system` is a loose public-safety toolkit: dispatch/backup, sirens/lights, radio codes, citations, legacy APB, less-lethal modes, lobby help, snake camera, K9, helicopter exterior seats/fast-rope, laser, speed radar, ANPR, and related UI. It is not the canonical justice, custody, evidence, MDC, or fixed speed-camera domain.

Existing Issues [#84](https://github.com/itschase/OwlMTA-2026/issues/84)-[#86](https://github.com/itschase/OwlMTA-2026/issues/86) and [#89](https://github.com/itschase/OwlMTA-2026/issues/89) own citations/payment, dispatch/help, less-lethal authority, and APB. Issue #153 is future evidence architecture only.

## Additional source-confirmed risks

- K9 roster mutation is remote and unauthenticated. [Issue #224](https://github.com/itschase/OwlMTA-2026/issues/224).
- Fast-rope/exterior-seat requests trust actor, vehicle, seat, coordinates, and ground state. [#225](https://github.com/itschase/OwlMTA-2026/issues/225).
- A client script is declared server-side and an exported jail function is not manifest-loaded. [#226](https://github.com/itschase/OwlMTA-2026/issues/226).
- Snakecam, siren, radar, and ANPR contain actor/driver/precedence/nil validation defects. [#227](https://github.com/itschase/OwlMTA-2026/issues/227).

The target is one server-authoritative public-safety capability layer derived from active organization/duty, with hard-coded IDs removed, client actor/target ignored, operations separated from evidence, typed citations/alerts, transactional payment, lifecycle readiness and coercive-action audit. Runtime tests must cover all roles/duty, every direct event, payment failure/replay, tool/weapon/vehicle/world state, K9/APB/config persistence, and resource/dependency restart.
