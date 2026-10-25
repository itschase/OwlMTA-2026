# `usercontrolpanel`

## Status

- Tree/startup state: active and enabled in the tracked startup snapshot; live startup unverified.
- Evidence: full review of every manifest-loaded script, the HTTP exports, tracked ACL and server settings, and direct resource dependencies.
- Runtime: unverified. No HTTP request or MTA server was started.
- Discussion: [Script Resource: usercontrolpanel](https://github.com/itschase/OwlMTA-2026/discussions/247).

## What it does

`usercontrolpanel` is a legacy server-side bridge for a missing OwlGaming website. It is not a web application. It exposes nine functions through MTA's built-in HTTP interface: reload donor perks, test whether an account is online, react to an externally completed stat transfer, globally delete matching items, retrieve weapon details, send a message to administrators, read server statistics, kick an account, and list donor perks.

The resource creates an MTA account named `website` when it starts if that account does not already exist. The password comes from `@usercontrolpanel.website_pass`. The tracked ACL places that identity in a broad group inheriting the Admin, RPC, and Website ACLs and a wildcard resource object. The tracked server configuration enables the HTTP server. This is current source behavior; it is not the proposed optional API design.

There is no player interface or normal staff command. Operators must currently supply the shared website password even though the corresponding UCP application is absent. Stat transfer assumes an external system has already changed database ownership, then reloads affected live vehicles and interiors and kicks the selected account.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/usercontrolpanel/meta.xml`](../../mods/deathmatch/resources/usercontrolpanel/meta.xml)
- Server implementation: [`s_main.lua`](../../mods/deathmatch/resources/usercontrolpanel/s_main.lua)
- HTTP exports: `reloadUserPerks`, `isPlayerOnline`, `statTransfer`, `deleteItem`, `retrieveWeaponDetails`, `sendMessageToAdmins`, `getServerStats`, `kickPlayerByUserId`, and `getPerks`.
- Dependencies: MTA accounts, ACL and HTTP; `pool`, `donators`, `item-system`, `cache`, `global`, `vehicle`, and `interior_system`.
- Configuration: `@usercontrolpanel.website_pass`, generated from `WEBSITE_PASSWORD` by the Docker entrypoint.
- Persistence: no resource-owned SQL table. It mutates the MTA account/ACL surface and delegates item, donor, vehicle, interior, weapon, player, and messaging changes to other resources.

## Source-confirmed risks

- One reusable password reaches a broadly privileged ACL identity and every HTTP export. The functions perform no per-operation capability, request, target, nonce, replay, rate, or purpose validation.
- Startup converts a missing setting to a string-like value and does not reject a blank, placeholder, or weak password. It creates the account only when absent, so a configuration change does not rotate or reconcile an existing credential.
- `deleteItem` can delete every item matching an arbitrary ID/value pair. The kick functions accept an arbitrary account ID, and the admin-message function can inject text carrying a trusted `[UCP]` label.
- `statTransfer` does not verify that the supplied user owns either character or that the external transfer committed successfully. Vehicle/interior reload and kick results are ignored, partial completion is not repaired, and missing character or interior data can cause errors.
- Online presence, server details, donor data, and weapon details are returned through the same legacy identity without field-level privacy policy or an immutable request/result audit.
- No runtime health, retry, idempotency, reconciliation, or safe offline behavior is implemented.

## Tracked work and target direction

- [Issue #4](https://github.com/itschase/OwlMTA-2026/issues/4) owns website-free in-game management and retirement of unsafe legacy UCP access.
- [Issue #22](https://github.com/itschase/OwlMTA-2026/issues/22) owns the website ACL identity and its privilege boundary.
- [Issue #44](https://github.com/itschase/OwlMTA-2026/issues/44) removes old website links elsewhere; no website URL is implemented in this resource itself.
- [Issue #122](https://github.com/itschase/OwlMTA-2026/issues/122) covers the separate legacy forum bridge, not these UCP RPCs.

The website-free target is proposed, not implemented: remove this resource from default startup, remove the shared website account and broad ACL membership, and keep routine operation available through authenticated in-game workflows. Any future optional API should be outside the MTA HTTP export surface and use TLS, short-lived service identity, narrow named capabilities, typed requests, idempotency, rate limits, immutable audit, and bounded server jobs. It must not become a startup dependency.

Runtime verification must cover missing, blank, placeholder, changed, and stale passwords; absent, existing, disabled, and over-privileged website accounts; private and public HTTP exposure; every export with malformed, foreign, duplicate, replayed, and concurrent requests; provider failure and restart; audit/redaction; and successful account, character, donor, vehicle, interior, item, and staff operation with the UCP disabled.
