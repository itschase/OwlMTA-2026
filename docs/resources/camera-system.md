# `camera-system`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded script, schema, and MDC consumer.
- Runtime: unverified. The server has not been started.

## What it does

`camera-system` implements traffic speed cameras only. Configured colshapes sample vehicle velocity, notify eligible on-duty police, and store a vehicle speeding observation for MDC history. It does not provide CCTV footage, replay, continuous surveillance, scene evidence, or chain of custody.

Drivers trigger an enabled camera by entering its area above the configured threshold. Police with the legacy faction/duty/item prerequisites receive a radio-style warning. Administrators use `/addspeedcam`, `/setradius`, `/delspeedcam`, and `/nearbyspeedcams`; law members have `/togglespeedcam`.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/camera-system/meta.xml`](../../mods/deathmatch/resources/camera-system/meta.xml)
- Detection: [`s_camera_detection.lua`](../../mods/deathmatch/resources/camera-system/s_camera_detection.lua)
- Persistence/management: [`s_camera_management.lua`](../../mods/deathmatch/resources/camera-system/s_camera_management.lua)
- Police command: [`s_camera_pd_commands.lua`](../../mods/deathmatch/resources/camera-system/s_camera_pd_commands.lua)
- Persistence: `speedcams` and `speedingviolations`; MDC reads violation history by vehicle.
- Dependencies: `mysql`, `pool`, `anticheat`, `integration`, `global`, `factions`, `item-system`, `vehicle`, and `mdc`.
- Detection speed and occupant state are server-derived, but exact driver identity is inferred rather than established as forensic evidence.

## Source-confirmed risks

- `/togglespeedcam` is broken: a later-loaded script overwrites the management function with a command function, whose attempted call recurses into the wrong signature and never performs the toggle.
- The overwritten management function also persists an undefined `newStatus`, so its DB branch would not match runtime state.
- Intended faction-45 and vehicle-331 exemptions convert boolean comparisons with `tonumber`, so they never match.
- A single timer handle per player makes overlapping cameras, rapid entry/exit, occupant changes, and element destruction race-prone.
- Delayed direction/warning logic does not reliably revalidate the vehicle and driver.
- Creation allows radius zero, lacks a sane upper/integer speed bound, and can finish in a different interior/dimension from where staging began.
- Create/delete/toggle and violation persistence do not consistently wait for or handle DB success; startup has no readiness signal.
- Exact visible-driver character IDs are stored indefinitely and shown through MDC without a documented access, retention, confidence, contest, or correction policy.

## Tracked work and target direction

[Issue #191](https://github.com/itschase/OwlMTA-2026/issues/191) covers toggle and lifecycle persistence; [#192](https://github.com/itschase/OwlMTA-2026/issues/192) covers deterministic sampling and privacy. They cross-reference MDC authority [Issues #41](https://github.com/itschase/OwlMTA-2026/issues/41) and [#52](https://github.com/itschase/OwlMTA-2026/issues/52), organization policy [#147](https://github.com/itschase/OwlMTA-2026/issues/147), and the future evidence boundary [#153](https://github.com/itschase/OwlMTA-2026/issues/153).

The target supports configured thresholds, radii, recipients, health and signage policy; durable and observable lifecycle changes; per-camera/vehicle sampling sessions; deduplication/cooldowns; and observations with bounded retention and explicit confidence. General CCTV should be a separate authorized subsystem with ownership, field of view, storage, access, and chain of custody.

Runtime verification must cover startup and DB failure, every create/edit/delete/toggle bound, all roles and duties, threshold/exemption/registration/visibility combinations, overlapping cameras, occupant and element changes, heading semantics, duplicate recipients/violations, restart persistence, MDC access, retention, contest/correction, and the explicit absence of CCTV behavior.
