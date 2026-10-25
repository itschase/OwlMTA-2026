# `announcement`

## Status

- Tree state: active resource tree.
- Tracked startup snapshot: enabled; live startup is unverified.
- Evidence state: source-confirmed, full manifest-script review; several notification mutations are fixed in source.
- Runtime state: unverified.

## What it does

`announcement` provides live staff banners, persisted audience-targeted MOTDs, stored account notifications, offline private messages, and notification popups used by other resources.

## Player use

Players receive live banners immediately. Login or character spawn loads unread matching MOTDs and up to fifteen stored notifications. The UI allows players to dismiss MOTDs presented as dismissible, view/mark/delete/clear notifications, and send a stored offline private message with `/opm username message`. Server-side dismissal eligibility and audience authorization remain part of Issue #133.

The notification drawer is a client UI, while durable records and audience decisions are server-side responsibilities.

## Staff use

Trial administrators and supporters can use `/ann` under the current legacy policy; the action is logged and attributed. The MOTD manager is intended for trial administrators, supporters, scripters, and vehicle consultants. A shared access helper exists on both client and server and the client gates opening the manager, but server list/save/delete handlers do not consistently invoke that authorization boundary.

## Operator and technical map

- Manifest: [`mods/deathmatch/resources/announcement/meta.xml`](../../mods/deathmatch/resources/announcement/meta.xml)
- Tables: `motds`, `motd_read`, and `notifications`.
- Important connections include `mysql`, `integration`, `pool`, `global`, `logs`, `cache`, and `donators`.
- Server export `makePlayerNotification` is marked HTTP-callable and is used by resources including vehicle auctions; its inbound ACL and caller contract require explicit review.
- `canPlayerAccessMotdManager` is exported on server and client.

## Known risks and next work

- [Issue #65](https://github.com/itschase/OwlMTA-2026/issues/65) covers notification ID/account scoping. `readNoti`, `deleteNoti`, and `clearNotis` are fixed in current source and await runtime verification.
- [Issue #133](https://github.com/itschase/OwlMTA-2026/issues/133) covers server MOTD-manager permission, `client` binding for MOTD/dismiss/refresh flows, validation, parameterization, and account scoping.
- [Issue #134](https://github.com/itschase/OwlMTA-2026/issues/134) covers server-derived offline-PM pricing, donor/staff exemptions, message/recipient validation, rate limits, and failure-safe charge/persistence.
- [Issue #1](https://github.com/itschase/OwlMTA-2026/issues/1) remains the parent remote-event audit; [Issue #3](https://github.com/itschase/OwlMTA-2026/issues/3) owns staff/supporter capability separation.

Runtime verification must cover banner authority/logging, MOTD audiences/manager/dismissal/expiry, notification reads/deletes/clear/receipts, offline-PM price/exemptions/unread guard, persistence failure, login/spawn delivery, and inbound notification export ACL.
