# Issues and Discussions workflow

## Current resource follow-up — `vehicle_fuel`

- Resource guide: [`docs/resources/vehicle_fuel.md`](../resources/vehicle_fuel.md); player/operator notes and MTA API references are consolidated there.
- Existing resource overview: [Script Resource Discussion #108](https://github.com/itschase/OwlMTA-2026/discussions/108).
- [Issue #342](https://github.com/itschase/OwlMTA-2026/issues/342) owns attendant conversation state, delayed settlement, and item/vehicle fuel transaction integrity.
- [Issue #343](https://github.com/itschase/OwlMTA-2026/issues/343) owns POS PIN caller/card binding, safe input/database lookup, throttling, and one-use authorization state.
- A separate source fix normalizes absent fuel-shop links and prevents nil arithmetic in attendant/shop-income paths. It is not runtime verified; Issue #342 remains open for the larger settlement redesign.

## Current authorization follow-up — factions and duty

- Resource guides: [`factions`](../resources/factions.md) and [`duty`](../resources/duty.md).
- [Issue #38](https://github.com/itschase/OwlMTA-2026/issues/38), [#39](https://github.com/itschase/OwlMTA-2026/issues/39), and [#53](https://github.com/itschase/OwlMTA-2026/issues/53) were reconciled against current source and assigned to Milestone #7. Several originally reported missing checks are present in source now; the open bodies specify residual roster privacy, offline membership, duty-package payload, and rank-event caller-boundary work.
- [Issue #344](https://github.com/itschase/OwlMTA-2026/issues/344) tracks the distinct global `dutyAdmin:Save` event authorization and payload-validation gap.
- Discord named capabilities may gate global staff tools through the future Owl host facade. Faction membership/rank/duty permissions remain local game authority; donor tiers remain separate.
- All of these findings are source-only. No MTA runtime has been started.

## Current API contract follow-up

- Owl's [`API_CONTRACT.md`](../architecture/API_CONTRACT.md) is a target proposal; its `/api/v1` routes do not match the standalone identity service's implemented `/v1` routes.
- [Issue #68](https://github.com/itschase/OwlMTA-2026/issues/68) now tracks route/schema reconciliation and the missing Owl host adapter, login integration, capability facade, and revocation handler.
- The separate service's process-local state and unverified MTA adapter runtime are explicit limits. Do not claim end-to-end Discord login or role authorization exists in OwlMTA.

## Current resource follow-up — `death`

- Resource guide: [`docs/resources/death.md`](../resources/death.md); standardized [Script Resource: death Discussion #347](https://github.com/itschase/OwlMTA-2026/discussions/347).
- [Issue #345](https://github.com/itschase/OwlMTA-2026/issues/345) tracks verification of cemetery-cache caller binding and request-rate behavior after the source fix.
- CK authority remains in the admin/self-CK resource paths; Discord named capabilities, if adopted, belong at their global staff action boundary. Death presentation and public cemetery access carry no staff role requirement.
- Runtime remains unverified.

## Current resource follow-up — `datetime`

- Resource guide: [`docs/resources/datetime.md`](../resources/datetime.md); standardized [Script Resource: datetime Discussion #348](https://github.com/itschase/OwlMTA-2026/discussions/348).
- [Issue #346](https://github.com/itschase/OwlMTA-2026/issues/346) tracks the mixed timestamp epochs, reversed IPPC future/past classification, date parsing, and legacy-value migration plan. [Issue #349](https://github.com/itschase/OwlMTA-2026/issues/349) tracks caller-bound clock synchronization and related event review.
- The helper is shared broadly and some `now()` results are persisted; do not change its epoch as a local cleanup. Complete the consumer/value migration audit before implementation.
- Discord grants have no clock-formatting role; any action timed by a feature stays authorized and validated by that feature's server logic.
- Runtime remains unverified.

## Current resource follow-up — `description`

- Resource guide: [`docs/resources/description.md`](../resources/description.md); standardized [Script Resource: description Discussion #352](https://github.com/itschase/OwlMTA-2026/discussions/352).
- [Issue #350](https://github.com/itschase/OwlMTA-2026/issues/350) records the server-side administrative vehicle-description authorization gap; source now checks authenticated caller, requested/occupied vehicle, payload type/length, and trial-admin status for the admin field.
- [Issue #351](https://github.com/itschase/OwlMTA-2026/issues/351) tracks the undefined vehicle-owner variable corrected in the overlay activity branch.
- The resource renders but does not own vehicle/interior/item state. Its vehicle admin description is currently displayed as shared overlay text; don't treat it as confidential.
- Runtime remains unverified.

## Current resource follow-up — `cards`

- Resource guide: [`cards`](../resources/cards.md); standardized [Script Resource Discussion #356](https://github.com/itschase/OwlMTA-2026/discussions/356).
- Player guide Q&A [#357](https://github.com/itschase/OwlMTA-2026/discussions/357), contextual/privacy/consent plan [#358](https://github.com/itschase/OwlMTA-2026/discussions/358), and operator notes [#359](https://github.com/itschase/OwlMTA-2026/discussions/359) document separate audiences and decisions.
- Issues [#353](https://github.com/itschase/OwlMTA-2026/issues/353)–[#355](https://github.com/itschase/OwlMTA-2026/issues/355) track face-down card data disclosure, invite consent/world checks, and disabled debug output.
- Card play is ordinary local gameplay and requires no Discord staff capability or donor tier. Runtime behavior remains unverified.

## Current resource follow-up — `chance-system`

- Resource guide: [`chance-system`](../resources/chance-system.md); standardized [Script Resource Discussion #362](https://github.com/itschase/OwlMTA-2026/discussions/362).
- Issues [#360](https://github.com/itschase/OwlMTA-2026/issues/360) and [#361](https://github.com/itschase/OwlMTA-2026/issues/361) track probability boundary semantics and unchecked `/luck` maximum values.
- All commands are ordinary player OOC utilities; they do not need Discord authorization. Invalid-argument and runtime behavior remain unverified.

## Current resource follow-up — `cockpit`

- Resource guide: [`cockpit`](../resources/cockpit.md); standardized [Script Resource Discussion #365](https://github.com/itschase/OwlMTA-2026/discussions/365).
- [Issue #363](https://github.com/itschase/OwlMTA-2026/issues/363) covers repeated texture allocation from the global client-resource-start subscription; [#364](https://github.com/itschase/OwlMTA-2026/issues/364) covers stopping the variometer sampling timer when the aircraft session ends.
- The HUD is passive client display, not staff authority; no Discord role or database state is involved. Official MTA event/texture guidance is linked in the dossier; runtime remains unverified.

## Current resource follow-up — `colorblender`

- Resource guide: [`colorblender`](../resources/colorblender.md); standardized [Script Resource Discussion #366](https://github.com/itschase/OwlMTA-2026/discussions/366).
- The picker is a client UI helper used by mechanic paint/headlight workflows. It owns no server authority or persistence; mechanic server handlers own eligibility and save behavior.
- No source-confirmed issue was identified in the picker. Multiple-window, cursor, cleanup, and mechanic integration behavior remain runtime-unverified.

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

The organized [`docs/`](../README.md) tree is the maintained reference set; the repository root retains the GitHub entry-point README. Update the relevant document in the same change as a meaningful source fix or design decision. Label observations precisely: source-confirmed, inferred, proposed, fixed in source, or runtime verified. Keep secrets, live Discord role IDs, OAuth credentials, and personal data out of both the repository and Discussions.

## Current records

- [Architecture and source findings](../architecture/CODEBASE_REVIEW.md)
- [Gamemode and data-flow guide](../architecture/GAMEMODE_GUIDE.md)
- [Feature usage guide](../guides/FEATURE_USAGE_GUIDE.md)
- [Discord identity and capability design](../architecture/DISCORD_AUTH_DESIGN.md)
- [Rebuild plan](REBUILD_PLAN.md)
- [Player Wiki](../guides/PLAYER_WIKI.md)
- [Staff and Admin Guide](../guides/STAFF_ADMIN_GUIDE.md)
- [Server Operator Guide](../guides/SERVER_OPERATOR_GUIDE.md)
- [Discord integration plan](../architecture/DISCORD_INTEGRATION_PLAN.md)
- [Enhancement register](ENHANCEMENT_REGISTER.md)
- [Resource and script audit playbook](RESOURCE_AUDIT_PLAYBOOK.md)
- [Resource documentation status ledger](../../RESOURCE_DOCUMENTATION_STATUS.csv)
- [Resource startup inventory](../../RESOURCE_INVENTORY.csv)
- [GitHub Issues](https://github.com/itschase/OwlMTA-2026/issues)
- [GitHub Discussions](https://github.com/itschase/OwlMTA-2026/discussions)
- [Milestone: MTA Compatibility & Diagnostics Baseline](https://github.com/itschase/OwlMTA-2026/milestone/5)
- [Issue #71: Source-grounded MTA release compatibility baseline](https://github.com/itschase/OwlMTA-2026/issues/71)
- [Discussion #70: Discord account linking and capability grants](https://github.com/itschase/OwlMTA-2026/discussions/70)
- [Script Resource #73: global](https://github.com/itschase/OwlMTA-2026/discussions/73)
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
- [Script Resource #115: carradio](https://github.com/itschase/OwlMTA-2026/discussions/115)
- [Script Resource #116: carshop-system](https://github.com/itschase/OwlMTA-2026/discussions/116)
- [Script Resource #117: vehicleplate](https://github.com/itschase/OwlMTA-2026/discussions/117)
- [Script Resource #123: mysql](https://github.com/itschase/OwlMTA-2026/discussions/123)
- [Script Resource #124: data](https://github.com/itschase/OwlMTA-2026/discussions/124)
- [Script Resource #125: pool](https://github.com/itschase/OwlMTA-2026/discussions/125)
- [Script Resource #126: integration](https://github.com/itschase/OwlMTA-2026/discussions/126)
- [Script Resource #127: cache](https://github.com/itschase/OwlMTA-2026/discussions/127)
- [Script Resource #128: logs](https://github.com/itschase/OwlMTA-2026/discussions/128)
- [Script Resource #135: phone](https://github.com/itschase/OwlMTA-2026/discussions/135)
- [Script Resource #136: chat-system](https://github.com/itschase/OwlMTA-2026/discussions/136)
- [Script Resource #137: advertisements](https://github.com/itschase/OwlMTA-2026/discussions/137)
- [Script Resource #138: social](https://github.com/itschase/OwlMTA-2026/discussions/138)
- [Script Resource #139: announcement](https://github.com/itschase/OwlMTA-2026/discussions/139)
- [Discussion #141: Organizations beyond factions](https://github.com/itschase/OwlMTA-2026/discussions/141)
- [Discussion #142: Criminal roleplay ecosystem](https://github.com/itschase/OwlMTA-2026/discussions/142)
- [Discussion #143: Living roleplay platform](https://github.com/itschase/OwlMTA-2026/discussions/143)
- [Discussion #144: Documentation and planning program](https://github.com/itschase/OwlMTA-2026/discussions/144)
- [Player Q&A #145: Can criminal groups use organizations?](https://github.com/itschase/OwlMTA-2026/discussions/145)
- [Discussion #171: Current economy, jobs, payday, and business architecture](https://github.com/itschase/OwlMTA-2026/discussions/171)
- [Discussion #172: Current criminal, investigation, justice, and corrections architecture](https://github.com/itschase/OwlMTA-2026/discussions/172)
- [Discussion #173: Administration system architecture, authority, and recovery](https://github.com/itschase/OwlMTA-2026/discussions/173)
- [Script Resource #174: anticheat](https://github.com/itschase/OwlMTA-2026/discussions/174)
- [Script Resource #175: anti-cmdspam](https://github.com/itschase/OwlMTA-2026/discussions/175)
- [Script Resource #176: serialwhitelist](https://github.com/itschase/OwlMTA-2026/discussions/176)
- [Script Resource #177: bans](https://github.com/itschase/OwlMTA-2026/discussions/177)
- [Script Resource #178: admin-system](https://github.com/itschase/OwlMTA-2026/discussions/178)
- [Script Resource #196: payday](https://github.com/itschase/OwlMTA-2026/discussions/196)
- [Script Resource #197: business-system](https://github.com/itschase/OwlMTA-2026/discussions/197)
- [Script Resource #198: prison-system](https://github.com/itschase/OwlMTA-2026/discussions/198)
- [Script Resource #199: camera-system](https://github.com/itschase/OwlMTA-2026/discussions/199)
- [Script Resource #200: mdc](https://github.com/itschase/OwlMTA-2026/discussions/200)
- [Server Operators #215: Safe-start preflight](https://github.com/itschase/OwlMTA-2026/discussions/215)
- [Script Resource #232: saveplayer-system](https://github.com/itschase/OwlMTA-2026/discussions/232)
- [Script Resource #233: resources](https://github.com/itschase/OwlMTA-2026/discussions/233)
- [Script Resource #234: duty](https://github.com/itschase/OwlMTA-2026/discussions/234)
- [Script Resource #235: donators](https://github.com/itschase/OwlMTA-2026/discussions/235)
- [Script Resource #236: pd-system](https://github.com/itschase/OwlMTA-2026/discussions/236)
- [Script Resource #237: interior_system](https://github.com/itschase/OwlMTA-2026/discussions/237)
- [Discord & API #239: Reusable Discord identity service and generic MTA adapter](https://github.com/itschase/OwlMTA-2026/discussions/239)

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
- [#112: Authorize radio station management and validate radio state requests](https://github.com/itschase/OwlMTA-2026/issues/112)
- [#113: Revalidate vehicle crusher deletion and payout at confirmation](https://github.com/itschase/OwlMTA-2026/issues/113)
- [#114: Bind DMV plate, registration, and sale-paper transactions to the caller](https://github.com/itschase/OwlMTA-2026/issues/114)
- [#118: Secure remotely triggered non-image cache lookups](https://github.com/itschase/OwlMTA-2026/issues/118)
- [#119: Make data and pool restart state explicit and recoverable](https://github.com/itschase/OwlMTA-2026/issues/119)
- [#120: Make audit-log rotation, retention, and write failure safe](https://github.com/itschase/OwlMTA-2026/issues/120)
- [#121: Make MySQL bootstrap and legacy database support reproducible](https://github.com/itschase/OwlMTA-2026/issues/121)
- [#122: Retire or isolate the legacy OwlGaming forum bridge](https://github.com/itschase/OwlMTA-2026/issues/122)

## Issues added 2026-10-25

- [#129: Bind restricted-frequency administration to the server caller](https://github.com/itschase/OwlMTA-2026/issues/129)
- [#130: Validate classified creation and faction attribution](https://github.com/itschase/OwlMTA-2026/issues/130)
- [#131: Make vehicle auction bidding and settlement atomic](https://github.com/itschase/OwlMTA-2026/issues/131)
- [#132: Authorize social physical interactions and item returns](https://github.com/itschase/OwlMTA-2026/issues/132)
- [#133: Enforce MOTD and notification authority server-side](https://github.com/itschase/OwlMTA-2026/issues/133)
- [#134: Derive offline private-message pricing server-side](https://github.com/itschase/OwlMTA-2026/issues/134)
- [#140: Restore or retire the chat-system business dependency](https://github.com/itschase/OwlMTA-2026/issues/140)
- [#146: Add a compatibility organization API over legacy faction state](https://github.com/itschase/OwlMTA-2026/issues/146)
- [#147: Define one canonical organization type and policy registry](https://github.com/itschase/OwlMTA-2026/issues/147)
- [#148: Enforce organization membership and rank referential integrity](https://github.com/itschase/OwlMTA-2026/issues/148)
- [#149: Replace negative faction IDs in wire transfers with typed account ownership](https://github.com/itschase/OwlMTA-2026/issues/149)
- [#150: Make organization asset ownership and archival lifecycle explicit](https://github.com/itschase/OwlMTA-2026/issues/150)
- [#151: Build a server-authoritative contextual action registry](https://github.com/itschase/OwlMTA-2026/issues/151)
- [#152: Create a configurable criminal opportunity state machine](https://github.com/itschase/OwlMTA-2026/issues/152)
- [#153: Define evidence, investigation, and chain-of-custody domains](https://github.com/itschase/OwlMTA-2026/issues/153)
- [#154: Track framework and roleplay-domain publication coverage](https://github.com/itschase/OwlMTA-2026/issues/154)
- [#155: Make anticheat alerts server-derived and abuse-resistant](https://github.com/itschase/OwlMTA-2026/issues/155)
- [#156: Repair or retire the legacy anticheat money scan](https://github.com/itschase/OwlMTA-2026/issues/156)
- [#157: Replace anti-cmdspam inactivity counting with a real rate limiter](https://github.com/itschase/OwlMTA-2026/issues/157)
- [#158: Move serial whitelist before session commit and add audited device enrollment](https://github.com/itschase/OwlMTA-2026/issues/158)
- [#159: Make ban creation atomic and return the persisted ban ID](https://github.com/itschase/OwlMTA-2026/issues/159)
- [#160: Correct serial, IP-range, and account ban enforcement](https://github.com/itschase/OwlMTA-2026/issues/160)
- [#161: Preserve ban history and enforce scoped moderation hierarchy](https://github.com/itschase/OwlMTA-2026/issues/161)
- [#162: Repair and scope ban investigation and alternate-account lookups](https://github.com/itschase/OwlMTA-2026/issues/162)
- [#163: Retire or isolate join-time external proxy screening](https://github.com/itschase/OwlMTA-2026/issues/163)
- [#164: Bind admin-system remote mutations to the authenticated client](https://github.com/itschase/OwlMTA-2026/issues/164)
- [#165: Authorize and make admin-history removal atomic](https://github.com/itschase/OwlMTA-2026/issues/165)
- [#166: Minimize and authorize admin check, history, inventory, monitor, and feedback data](https://github.com/itschase/OwlMTA-2026/issues/166)
- [#167: Validate feedback submission and protect feedback attribution](https://github.com/itschase/OwlMTA-2026/issues/167)
- [#168: Replace recovery-secret disclosure and plaintext server-password broadcast](https://github.com/itschase/OwlMTA-2026/issues/168)
- [#169: Make staff rank and destructive account mutations failure-safe](https://github.com/itschase/OwlMTA-2026/issues/169)
- [#170: Restore admin observation state on stop, restart, and disconnect](https://github.com/itschase/OwlMTA-2026/issues/170)
- [#179: Make hourly payday settlement idempotent and balance-backed](https://github.com/itschase/OwlMTA-2026/issues/179)
- [#180: Make payday maintenance server-only and protect shop wage accrual](https://github.com/itschase/OwlMTA-2026/issues/180)
- [#181: Bind fishing and photography rewards to server-owned work](https://github.com/itschase/OwlMTA-2026/issues/181)
- [#182: Persist truck supply orders as transactional delivery contracts](https://github.com/itschase/OwlMTA-2026/issues/182)
- [#183: Authorize business-note mutation and define the business replacement boundary](https://github.com/itschase/OwlMTA-2026/issues/183)
- [#184: Bind shell-casing creation to authoritative weapon fire](https://github.com/itschase/OwlMTA-2026/issues/184)
- [#185: Make drug transformations server-owned and failure-safe](https://github.com/itschase/OwlMTA-2026/issues/185)
- [#186: Reconcile duplicate custody state and recover booking and release](https://github.com/itschase/OwlMTA-2026/issues/186)
- [#187: Replace boolean wanted status with auditable warrant records](https://github.com/itschase/OwlMTA-2026/issues/187)
- [#188: Consolidate legacy APB models into one incident-alert domain](https://github.com/itschase/OwlMTA-2026/issues/188)
- [#189: Separate allegations, citations, charges, convictions, custody, and staff sanctions](https://github.com/itschase/OwlMTA-2026/issues/189)
- [#190: Replace raw fingerprint disclosure with an in-world identification workflow](https://github.com/itschase/OwlMTA-2026/issues/190)
- [#191: Repair speed-camera toggle and lifecycle persistence](https://github.com/itschase/OwlMTA-2026/issues/191)
- [#192: Make speed-camera sampling deterministic and privacy-scoped](https://github.com/itschase/OwlMTA-2026/issues/192)
- [#193: Correct MDC account level mapping and organization uniqueness](https://github.com/itschase/OwlMTA-2026/issues/193)
- [#194: Repair MDC orphan cleanup and empty permission-cache handling](https://github.com/itschase/OwlMTA-2026/issues/194)
- [#195: Fix MDC search result correctness and DB handle lifecycle](https://github.com/itschase/OwlMTA-2026/issues/195)
- [#201: Remove client-shipped account hash constants and rotate dependent schemes](https://github.com/itschase/OwlMTA-2026/issues/201)
- [#202: Make character creation quota and name allocation atomic](https://github.com/itschase/OwlMTA-2026/issues/202)
- [#203: Stage and recover character spawn hydration](https://github.com/itschase/OwlMTA-2026/issues/203)
- [#204: Derive character spawn correction from server-owned state](https://github.com/itschase/OwlMTA-2026/issues/204)
- [#205: Bind ATM operations to the caller and a server-owned session](https://github.com/itschase/OwlMTA-2026/issues/205)
- [#206: Repair ATM card lifecycle, PIN, limits, and restart safety](https://github.com/itschase/OwlMTA-2026/issues/206)
- [#207: Make ATM and bank settlement idempotent and reconcilable](https://github.com/itschase/OwlMTA-2026/issues/207)
- [#208: Version and test the global export contract](https://github.com/itschase/OwlMTA-2026/issues/208)
- [#209: Replace direct global money mutation with ledger-backed settlement](https://github.com/itschase/OwlMTA-2026/issues/209)
- [#210: Bind and constrain global chat and sound remote events](https://github.com/itschase/OwlMTA-2026/issues/210)
- [#211: Add factions readiness and restart-safe cache hydration](https://github.com/itschase/OwlMTA-2026/issues/211)
- [#212: Make faction finance reads request-scoped and nonblocking](https://github.com/itschase/OwlMTA-2026/issues/212)
- [#213: Bind item-system remote mutations to the authenticated client](https://github.com/itschase/OwlMTA-2026/issues/213)
- [#214: Make item transfers atomic and restart-recoverable](https://github.com/itschase/OwlMTA-2026/issues/214)
- [#216: Bound and deduplicate periodic character saves](https://github.com/itschase/OwlMTA-2026/issues/216)
- [#217: Make character save failures observable and recoverable](https://github.com/itschase/OwlMTA-2026/issues/217)
- [#218: Remove synthetic vehicle-exit side effects from character saving](https://github.com/itschase/OwlMTA-2026/issues/218)
- [#219: Restore or remove the missing shared weapon attachment definition](https://github.com/itschase/OwlMTA-2026/issues/219)
- [#220: Make duty issuance recoverable and provenance-based](https://github.com/itschase/OwlMTA-2026/issues/220)
- [#221: Bind donor remote events and prevent GameCoin minting](https://github.com/itschase/OwlMTA-2026/issues/221)
- [#222: Make GameCoin purchases atomic, auditable, and recoverable](https://github.com/itschase/OwlMTA-2026/issues/222)
- [#223: Normalize donor entitlement identity, duration, and expiry](https://github.com/itschase/OwlMTA-2026/issues/223)
- [#224: Authorize PD K9 roster mutations](https://github.com/itschase/OwlMTA-2026/issues/224)
- [#225: Validate PD tactical mobility and vehicle attachment requests](https://github.com/itschase/OwlMTA-2026/issues/225)
- [#226: Repair PD manifest exports and lifecycle cleanup](https://github.com/itschase/OwlMTA-2026/issues/226)
- [#227: Bind PD equipment and sensor remotes to authoritative operators](https://github.com/itschase/OwlMTA-2026/issues/227)
- [#228: Require proximity and server interaction context for interior entry and preview](https://github.com/itschase/OwlMTA-2026/issues/228)
- [#229: Authorize and validate interior settings writes](https://github.com/itschase/OwlMTA-2026/issues/229)
- [#230: Repair interior eviction bookkeeping for online and offline occupants](https://github.com/itschase/OwlMTA-2026/issues/230)
- [#231: Make property purchase, transfer, sale, and cleanup recoverable](https://github.com/itschase/OwlMTA-2026/issues/231)
- [#238: Package the identity service and MTA adapter as a reusable standalone project](https://github.com/itschase/OwlMTA-2026/issues/238)

## Recent resource documentation and implementation records — 2026-10-27

### Resource coverage continuation

- [Script Resource #369: clubtec](https://github.com/itschase/OwlMTA-2026/discussions/369)
- [Script Resource #376: customblips](https://github.com/itschase/OwlMTA-2026/discussions/376)
- [Operator Notes #377: customblips dependencies and lifecycle](https://github.com/itschase/OwlMTA-2026/discussions/377)
- [Script Resource #378: elections](https://github.com/itschase/OwlMTA-2026/discussions/378)
- [Player Guide Q&A #379: How do I vote in an election?](https://github.com/itschase/OwlMTA-2026/discussions/379)
- [Staff Guide #380: managing in-game elections](https://github.com/itschase/OwlMTA-2026/discussions/380)
- [Script Resource #381: dancer-system](https://github.com/itschase/OwlMTA-2026/discussions/381)
- [Staff Guide #382: placing and maintaining ambient dancers](https://github.com/itschase/OwlMTA-2026/discussions/382)
- [Script Resource #386: driveby](https://github.com/itschase/OwlMTA-2026/discussions/386)
- [Operator Notes #387: driveby settings and client startup](https://github.com/itschase/OwlMTA-2026/discussions/387)
- [Script Resource #388: dynamic_lighting_flash](https://github.com/itschase/OwlMTA-2026/discussions/388)
- [Issue #390: Resolve simulation for the target element in teleport checks](https://github.com/itschase/OwlMTA-2026/issues/390)
- [Issue #391: Repair archived projectile-light cleanup before revival](https://github.com/itschase/OwlMTA-2026/issues/391)
- [Issue #393: Bind license exam completion and issuance to server-owned state](https://github.com/itschase/OwlMTA-2026/issues/393)
- [Issue #394: Derive license recovery items, prices, and payer identity on the server](https://github.com/itschase/OwlMTA-2026/issues/394)
- [Issue #395: Enforce gun-license manager tier rules on the server](https://github.com/itschase/OwlMTA-2026/issues/395)
- [Issue #392: Use the active vehicle light mode for darkness normalization](https://github.com/itschase/OwlMTA-2026/issues/392)

The same-name archived copies have separate source identities. Their archive dossiers are indexed from [`docs/resources/README.md`](../resources/README.md); publish archive-specific Script Resource Discussions with a consistent suffix such as `(archived)` rather than reusing the active resource thread.
- [Player Guide Q&A #389: How do I use and recharge a flashlight?](https://github.com/itschase/OwlMTA-2026/discussions/389)
- [#367: Authorize ClubTec video-player actions against caller and target](https://github.com/itschase/OwlMTA-2026/issues/367)
- [#368: Validate ClubTec texture and shader settings before persistence](https://github.com/itschase/OwlMTA-2026/issues/368)
- [#370: Make customblips widget cleanup decrement the visible counter exactly once](https://github.com/itschase/OwlMTA-2026/issues/370)
- [#371: Handle failed customblips image creation and reject invalid paths](https://github.com/itschase/OwlMTA-2026/issues/371)
- [#372: Enforce election eligibility and one-vote policy on the server](https://github.com/itschase/OwlMTA-2026/issues/372)
- [#373: Validate election candidate selection before updating vote totals](https://github.com/itschase/OwlMTA-2026/issues/373)
- [#374: Preserve dancer metadata and world placement when recreating a ped](https://github.com/itschase/OwlMTA-2026/issues/374)
- [#375: Report dancer database deletion failures](https://github.com/itschase/OwlMTA-2026/issues/375)
- [#383: Sanitize driveby passenger weapons without mutating the driver list](https://github.com/itschase/OwlMTA-2026/issues/383)
- [#384: Bind dynamic flashlight changes to the authenticated player](https://github.com/itschase/OwlMTA-2026/issues/384)
- [#385: Validate flashlight battery drain on the server](https://github.com/itschase/OwlMTA-2026/issues/385)

### Resource Discussions

- [Script Resource #316: activities](https://github.com/itschase/OwlMTA-2026/discussions/316)
- [Script Resource #317: bone_attach](https://github.com/itschase/OwlMTA-2026/discussions/317)
- [Script Resource #318: clothes](https://github.com/itschase/OwlMTA-2026/discussions/318)
- [Script Resource #319: official-interiors](https://github.com/itschase/OwlMTA-2026/discussions/319)
- [Script Resource #328: artifacts](https://github.com/itschase/OwlMTA-2026/discussions/328)
- [Plans & Enhancements #329: Command and interaction alternatives](https://github.com/itschase/OwlMTA-2026/discussions/329)
- [Script Resource #334: gatekeepers-system](https://github.com/itschase/OwlMTA-2026/discussions/334)
- [Script Resource #336: animation-system](https://github.com/itschase/OwlMTA-2026/discussions/336)
- [Script Resource #339: help](https://github.com/itschase/OwlMTA-2026/discussions/339)
- [Discord identity Discussion #239: per-resource capability review](https://github.com/itschase/OwlMTA-2026/discussions/239)

### Recent Issues

- [#41: Bind MDC access to the caller and authorize search/mutation events](https://github.com/itschase/OwlMTA-2026/issues/41)
- [#52: Bind MDC login to the caller's authenticated character](https://github.com/itschase/OwlMTA-2026/issues/52)
- [#55: Scope phone messages and contacts to the caller's owned phone](https://github.com/itschase/OwlMTA-2026/issues/55)
- [#54: Enforce law and duty authorization on prison mutation events](https://github.com/itschase/OwlMTA-2026/issues/54)
- [#62: Authorize map request approval, implementation, update, and deletion](https://github.com/itschase/OwlMTA-2026/issues/62)
- [#63: Secure remotely triggered image-cache lookups and writes](https://github.com/itschase/OwlMTA-2026/issues/63)
- [#64: Review interior-manager permissions and catalog data access](https://github.com/itschase/OwlMTA-2026/issues/64)
- [#306: Bind activities snowball events to the authenticated player](https://github.com/itschase/OwlMTA-2026/issues/306)
- [#307: Restrict persistent automatic official-interiors catalog repair](https://github.com/itschase/OwlMTA-2026/issues/307)
- [#308: Repair official-interiors geometry instancing and invalid catalog entries](https://github.com/itschase/OwlMTA-2026/issues/308)
- [#309: Load official-interiors custom geometry on demand](https://github.com/itschase/OwlMTA-2026/issues/309)
- [#310: Define a recoverable bone attachment lifecycle contract](https://github.com/itschase/OwlMTA-2026/issues/310)
- [#311: Attach the active phone object when entering talk state](https://github.com/itschase/OwlMTA-2026/issues/311)
- [#312: Replace duplicate clothes uploads with one bounded design intake pipeline](https://github.com/itschase/OwlMTA-2026/issues/312)
- [#313: Bind clothes purchases to shop context and settle outfit grants safely](https://github.com/itschase/OwlMTA-2026/issues/313)
- [#314: Make clothes design manufacture, copies, and resale recoverable](https://github.com/itschase/OwlMTA-2026/issues/314)
- [#315: Bound clothes texture delivery and repair cache failure handling](https://github.com/itschase/OwlMTA-2026/issues/315)
- [#320: Restrict remote clothes resource restarts](https://github.com/itschase/OwlMTA-2026/issues/320)
- [#321: Bind clothing lists and Dupont dialogue to server interaction state](https://github.com/itschase/OwlMTA-2026/issues/321)
- [#322: Clear snowball input bindings across every exit path](https://github.com/itschase/OwlMTA-2026/issues/322)
- [#323: Check and restore official-interiors collision replacements](https://github.com/itschase/OwlMTA-2026/issues/323)
- [#324: Bind artifacts bulk cleanup to trusted server callers](https://github.com/itschase/OwlMTA-2026/issues/324)
- [#325: Validate inventory and job entitlement before equipping artifacts](https://github.com/itschase/OwlMTA-2026/issues/325)
- [#326: Handle /removeartifacts when no artifacts are worn](https://github.com/itschase/OwlMTA-2026/issues/326)
- [#327: Inventory commands and map discoverable in-game alternatives](https://github.com/itschase/OwlMTA-2026/issues/327)
- [#330: Track and release artifacts client texture resources](https://github.com/itschase/OwlMTA-2026/issues/330)
- [#331: Make locksmith key duplication server-authoritative](https://github.com/itschase/OwlMTA-2026/issues/331)
- [#332: Return an empty faction-key list for players outside factions](https://github.com/itschase/OwlMTA-2026/issues/332)
- [#333: Scope gatekeepers ped damage protection to intended NPCs](https://github.com/itschase/OwlMTA-2026/issues/333)
- [#335: Bind animation changes and synchronization to the requesting player](https://github.com/itschase/OwlMTA-2026/issues/335)
- [#337: Validate help command catalog writes and align editor visibility with server policy](https://github.com/itschase/OwlMTA-2026/issues/337)
- [#338: Bind help command-list refresh requests to the requesting player](https://github.com/itschase/OwlMTA-2026/issues/338)
- [#340: Separate 911 log access from donor entitlements](https://github.com/itschase/OwlMTA-2026/issues/340)
- [#341: Authorize prison gate controls on the server](https://github.com/itschase/OwlMTA-2026/issues/341)
Milestone [M4 — Organizations & Living Roleplay](https://github.com/itschase/OwlMTA-2026/milestone/6) groups the compatibility-first organization, contextual interaction, criminal opportunity, evidence, and connected-roleplay foundation work. M0/M1 portability and security gates remain prerequisites.

