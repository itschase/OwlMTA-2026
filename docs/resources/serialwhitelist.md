# `serialwhitelist`

## Status

- Tree/startup state: active and present in the tracked startup snapshot after `account`; live startup unverified.
- Evidence: full manifest-script source review.
- Runtime: unverified.

## What it does

`serialwhitelist` is a legacy second-device/serial gate for selected privileged account categories during login. Ordinary accounts without whitelist records pass; an ordinary account with an active whitelist history and selected legacy staff/support roles require a matching active account/serial row.

## Player, staff, and operator experience

The check is invisible until denial, which directs the user to a missing UCP. Source contains add, delete, and list functions intended for `/addserialwl`, `/delserialwl`, and `/whitelists`, but their handlers are commented out and the functions are not exported. There is therefore no working local management flow.

The policy mixes supporters into a staff-device restriction while omitting some specialty teams. Discord identity and roles should not replace device trust; a future device check is an optional, separately authorized step-up mechanism.

## Technical map

- Manifest: [`mods/deathmatch/resources/serialwhitelist/meta.xml`](../../mods/deathmatch/resources/serialwhitelist/meta.xml)
- Implementation: [`script.lua`](../../mods/deathmatch/resources/serialwhitelist/script.lua)
- Export: `check`.
- Dependencies: `mysql`, `integration`, `global`, account element data, and the `mta.serial_whitelist` table.
- Rows contain account, raw serial, last IP/date, and status; the table has no account/serial uniqueness or foreign-key constraint and defaults new rows inactive.

## Known risks and work

- [Issue #158](https://github.com/itschase/OwlMTA-2026/issues/158) moves this gate before authenticated session/rank state is committed and adds audited enrollment/revocation without a UCP.
- Current denial occurs after `account:loggedin`, identity, email, and legacy ranks are attached and does not fully roll them back or disconnect.
- Database failure behavior and owner recovery are undefined; add/delete would be unaudited direct mutation if merely re-enabled.
- Raw serial/IP values are exposed too broadly, and the disabled add flow queries the wrong database for `accounts` after the schema split.

Runtime verification must cover ordinary and each privileged category, matching/mismatching/inactive/duplicate records, changed device, management capability, DB outage, startup order, partial-session rollback, concurrent login, redaction, Discord revocation, and operator recovery.
