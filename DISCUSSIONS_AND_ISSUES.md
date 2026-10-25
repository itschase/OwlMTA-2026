# Issues and Discussions workflow

Use both GitHub Issues and Discussions as the project's public working record. Write in the project's voice. Record source-backed findings and decisions without mentioning the tools or people that produced them.

Keep GitHub surfaces audience-specific: Issues are the actionable defect/security backlog; Discussions are split into resource architecture, simplified player Q&A/wiki, staff/admin operations, server-operator runbooks, Discord/API design, and enhancement planning. Version-controlled Markdown remains the detailed source of truth. Where a category is unavailable, use the closest existing category and label the audience at the top of each post.

## GitHub Issues: actionable work and defect log

Create or update an Issue whenever source review, upstream history, build inspection, or later runtime work identifies a concrete defect, security gap, portability blocker, or required implementation task.

Each Issue should include:

- A short, specific title naming one behavior or outcome.
- Evidence: resource and file paths, relevant event/export/table, and upstream reference when useful.
- Impact and the affected player/operator flow.
- Current status: confirmed in source, suspected, fixed in source, or runtime verified.
- A bounded next step and validation conditions. Do not describe an unrun server test as completed.
- Links to a related Discussion when the issue needs design context, and to sibling Issues when work is split.

Search open and closed Issues before creating one. Keep one implementation unit per Issue when practical; broader tracking Issues may group a family of related event audits. Assign project work to the repository owner when self-assignment is appropriate. Close an Issue only after its acceptance conditions are satisfied and the final change or verification is linked.

## GitHub Discussions: documentation and decisions

Use Discussions for durable explanations that help operators and contributors understand the gamemode, not for a substitute defect backlog. Create or extend topic threads for:

- Architecture and resource/data flows.
- Feature entry points, prerequisites, permissions, persistence, and failure behavior.
- MTA API usage and client/server security boundaries.
- Discord identity linking, role-to-capability mapping, donor tiers, and migration decisions.
- Database, deployment, configuration, and importability decisions.
- Review findings that need discussion before they can be stated as implementation requirements.

Start each thread with a concise scope, evidence links to repository docs/source, the current understanding, open questions, and related Issues. Update the thread when evidence changes. Keep the maintained, detailed operator documentation in versioned Markdown in the repository; Discussions provide an accessible topic index and discussion history.

## Repository documentation

The Markdown files in the root are the maintained reference set. Update them in the same change as a meaningful source fix or design decision. Label observations precisely: source-confirmed, inferred, proposed, fixed in source, or runtime verified. Keep secrets, live Discord role IDs, OAuth credentials, and personal data out of both the repository and Discussions.

## Current records

- [Architecture and source findings](CODEBASE_REVIEW.md)
- [Gamemode and data-flow guide](GAMEMODE_GUIDE.md)
- [Feature usage guide](FEATURE_USAGE_GUIDE.md)
- [Discord identity and capability design](DISCORD_AUTH_DESIGN.md)
- [Rebuild plan](REBUILD_PLAN.md)
- [Player Wiki](PLAYER_WIKI.md)
- [Staff and Admin Guide](STAFF_ADMIN_GUIDE.md)
- [Server Operator Guide](SERVER_OPERATOR_GUIDE.md)
- [Discord integration plan](DISCORD_INTEGRATION_PLAN.md)
- [Enhancement register](ENHANCEMENT_REGISTER.md)
- [Resource and script audit playbook](RESOURCE_AUDIT_PLAYBOOK.md)
- [Resource documentation status ledger](RESOURCE_DOCUMENTATION_STATUS.csv)
- [Resource startup inventory](RESOURCE_INVENTORY.csv)
- [GitHub Issues](https://github.com/itschase/OwlMTA-2026/issues)
- [GitHub Discussions](https://github.com/itschase/OwlMTA-2026/discussions)
- [Milestone: MTA Compatibility & Diagnostics Baseline](https://github.com/itschase/OwlMTA-2026/milestone/5)
- [Issue #71: Source-grounded MTA release compatibility baseline](https://github.com/itschase/OwlMTA-2026/issues/71)
- [Discussion #70: Discord account linking and capability grants](https://github.com/itschase/OwlMTA-2026/discussions/70)
- [Resource Discussion #73: global](https://github.com/itschase/OwlMTA-2026/discussions/73)
- [Discussion #97: Resource audit standard for real users and operators](https://github.com/itschase/OwlMTA-2026/discussions/97)
- [Discussion #98: Discord-first sign-in, legacy account migration, and session revocation](https://github.com/itschase/OwlMTA-2026/discussions/98)
- [Script Resource #99: account](https://github.com/itschase/OwlMTA-2026/discussions/99)
- [Script Resource #100: bank](https://github.com/itschase/OwlMTA-2026/discussions/100)
- [Script Resource #101: factions](https://github.com/itschase/OwlMTA-2026/discussions/101)
- [Script Resource #102: item-system](https://github.com/itschase/OwlMTA-2026/discussions/102)
- [Discussion #103: Contextual interaction and proximity voice](https://github.com/itschase/OwlMTA-2026/discussions/103)
- [Discussion #104: Jobs, businesses, and player production](https://github.com/itschase/OwlMTA-2026/discussions/104)
- [Discussion #105: Operator observability and optional adapters](https://github.com/itschase/OwlMTA-2026/discussions/105)
- [Discussion #106: Staff control center, command discovery, and audit history](https://github.com/itschase/OwlMTA-2026/discussions/106)
- [Script Resource #107: vehicle](https://github.com/itschase/OwlMTA-2026/discussions/107)
- [Script Resource #108: vehicle_fuel](https://github.com/itschase/OwlMTA-2026/discussions/108)
- [Script Resource #109: vehicle-interiors](https://github.com/itschase/OwlMTA-2026/discussions/109)
- [Script Resource #110: vehicle_load](https://github.com/itschase/OwlMTA-2026/discussions/110)
- [Script Resource #111: vehicle_manager](https://github.com/itschase/OwlMTA-2026/discussions/111)

## Issues added 2026-10-24

- [#75: Derive custom-shop purchases from the stored product](https://github.com/itschase/OwlMTA-2026/issues/75)
- [#76: Reject non-positive ATM transaction amounts](https://github.com/itschase/OwlMTA-2026/issues/76)
- [#77: Validate bus-job route progression before paying drivers](https://github.com/itschase/OwlMTA-2026/issues/77)
- [#78: Authorize and validate faction duty allowlist saves](https://github.com/itschase/OwlMTA-2026/issues/78)
- [#79: Restrict remote account and character settings writes](https://github.com/itschase/OwlMTA-2026/issues/79)

Issue #3 was updated with source-confirmed donor-to-moderation command examples to inform the capability migration.
- Issues #2, #4, #7, and #68 were updated to align the production identity target with Discord-first login and the complete resource documentation scope.
- [#80: Require an active tutorial before advancing the account flow](https://github.com/itschase/OwlMTA-2026/issues/80)
- [#81: Restore persisted interior settings when properties load](https://github.com/itschase/OwlMTA-2026/issues/81)
- [#82: Authorize faction duty-skin lookup requests](https://github.com/itschase/OwlMTA-2026/issues/82)
- [#83: Derive phone call charges from server-side call state](https://github.com/itschase/OwlMTA-2026/issues/83)

Issues #52 (MDC) and #55 (phone) were updated with the additional read, mutation, ownership, and authorization paths found in follow-up reviews.
- [#84: Bind PD citations and ticket payments to server-owned records](https://github.com/itschase/OwlMTA-2026/issues/84)
- [#85: Authorize police dispatch and help events](https://github.com/itschase/OwlMTA-2026/issues/85)
- [#86: Validate police weapon events before incapacitating targets](https://github.com/itschase/OwlMTA-2026/issues/86)
- [#87: Validate duty-package contents and location server-side](https://github.com/itschase/OwlMTA-2026/issues/87)
- [#88: Restrict roadblock models and placement requests](https://github.com/itschase/OwlMTA-2026/issues/88)
- [#89: Restore APB creation for authorized factions](https://github.com/itschase/OwlMTA-2026/issues/89)
- [#90: Map SASP booking cell 8 to the correct dimension](https://github.com/itschase/OwlMTA-2026/issues/90)
- [#91: Validate vehicle lock requests against keys and proximity](https://github.com/itschase/OwlMTA-2026/issues/91)
- [#92: Bind engine control and vehicle keys to the caller](https://github.com/itschase/OwlMTA-2026/issues/92)
- [#93: Bind vehicle parking requests to the actual actor](https://github.com/itschase/OwlMTA-2026/issues/93)
- [#94: Require proximity for vehicle interior entry](https://github.com/itschase/OwlMTA-2026/issues/94)
- [#95: Create one Script Resources discussion for each resource](https://github.com/itschase/OwlMTA-2026/issues/95)
- [#96: Revoke and disconnect active MTA sessions after Discord authorization loss](https://github.com/itschase/OwlMTA-2026/issues/96)

