# Organizations Framework

## Status and purpose

This is a proposed target architecture grounded in the current `factions` source. It is not implemented and has not been runtime-verified. It defines how OwlMTA can evolve from a legacy faction container into a general organization platform without breaking the large number of scripts that already depend on faction IDs, MTA teams, exports, events, element data, commands, or SQL columns.

`Organization` is the intended player-facing term. Existing identifiers such as the `factions` resource, `factions` table, `characters_faction`, `exports.factions`, faction element data, and old commands remain compatibility contracts until each consumer has been inventoried and migrated.

## Source-confirmed baseline

The current implementation is already a generic organization aggregate rather than a narrowly political faction system:

- [`g_faction_exports.lua`](../../mods/deathmatch/resources/factions/g_faction_exports.lua) defines types for Gang, Mafia, Law, Government, Medical, Other, News, and Dealership. The manager UI separately calls type 7 Mechanic, showing that the duplicated numeric taxonomy has already drifted.
- [`s_faction_system.lua`](../../mods/deathmatch/resources/factions/s_faction_system.lua) materializes organizations as MTA team elements and loads many-to-many character memberships.
- [`ranks/s_permissions.lua`](../../mods/deathmatch/resources/factions/ranks/s_permissions.lua) assigns indexed rank permissions for members, ranks, vehicles, interiors, finance, chat, advertisements, MOTD, duty, and other actions. Membership, rank permission, leader state, and active duty are separate concepts.
- `characters_faction`, `faction_ranks`, and `factions` persist membership and organization state in [`mta.sql`](../../mods/deathmatch/data/mta.sql). The current membership table has no unique `(character_id, faction_id)` constraint or foreign-key enforcement.
- Vehicles, interiors, shops, insurance, MDC records, duty packages, phones, banking, and many other systems store faction IDs as implicit ownership or policy references.
- Faction finance overloads negative IDs in `wiretransfers` to mean an organization account. This must be migrated deliberately rather than renamed.
- More than one hundred active Lua files call `exports.factions`; a text replacement would break runtime contracts and could collide with unrelated uses of the word `organization`, including MDC schema fields.
- Active [`business-system`](../../mods/deathmatch/resources/business-system/meta.xml) manages business-interior notes, not organization membership. Active `chat-system` business chat calls exports from the archive-only `business` resource. Business ownership, employment, and organization membership therefore need an explicit domain decision.

## Vocabulary

Use these terms in new UI, API, and documentation:

| Term | Meaning |
|---|---|
| Organization | A durable group with identity, membership, governance, capabilities, relationships, and optionally assets or finance. |
| Organization class | Broad semantic family such as public service, commercial, community, or criminal. It informs defaults but grants no authority by itself. |
| Organization profile | Configurable policies such as discoverability, duty support, wages, asset types, application rules, and audit visibility. |
| Membership | A character's relationship to one organization. It has status, role assignments, dates, and scoped attributes. |
| Role | An organization-defined position. A role grants named organization capabilities rather than a numeric global power level. |
| Unit | A nested division, department, squad, chapter, crew, committee, or team inside one organization. |
| Duty assignment | A temporary active operational state with location, package, equipment, and policy requirements. It is not synonymous with membership. |
| Affiliation | A lighter relationship such as contractor, informant, customer, associate, ally, or affiliate that is not full membership. |
| Network | A relationship graph among organizations, units, characters, businesses, fronts, suppliers, or institutions. |

The word `faction` may remain in compatibility documentation when referring to existing code or data. Player-facing language should use the organization's chosen type: agency, department, company, newsroom, club, union, crew, gang, family, syndicate, network, or another operator-configured label.

## Organization classes and composable policies

Do not replace one hard-coded numeric type list with another. Define operator-managed types whose behavior comes from explicit policy flags and capabilities.

Suggested semantic classes include:

- `public_safety`: police, fire, EMS, corrections, dispatch, and emergency management.
- `government`: executive offices, public works, licensing, transit, courts, and regulatory bodies.
- `commercial`: private companies, dealerships, logistics firms, financial services, and employers.
- `media`: newsrooms, broadcasters, publishers, and event media.
- `community`: clubs, charities, unions, religious groups, neighborhood associations, and sports teams.
- `criminal`: crews, gangs, motorcycle clubs, organized-crime groups, smugglers, and black-market networks.
- `hybrid`: organizations whose legitimate and illicit operations coexist, including front businesses.
- `temporary`: task forces, event teams, investigations, campaign organizations, and project groups.

Independent policies should describe what an organization can support:

- Duty, uniforms, certifications, equipment packages, and callsigns
- Wages, payroll schedules, budgets, expense approvals, and taxable activity
- Vehicles, properties, storage, phones, radio frequencies, uniforms, and other asset classes
- Public directory visibility, hidden membership, pseudonymous units, or covert operation
- Open applications, invitation only, referral required, staff-reviewed, or hidden recruitment
- Multiple simultaneous memberships, conflicting-role rules, exclusivity, and leave-of-absence state
- Leadership election, appointment, succession, ownership recovery, or operator stewardship
- Internal units, chapters, branches, departments, and geographic areas
- Public records, licenses, regulatory duties, or disclosure requirements
- Legal, illegal, mixed, or unknown standing as a mutable in-world fact, not a global authorization shortcut

## Capability model

Organization authority is local to an organization and must remain separate from Discord staff capabilities, donor tiers, MTA ACL, global administration, and GameMaster privileges.

Example organization capabilities:

- `organization.member.invite`, `approve`, `suspend`, `remove`, and `view_history`
- `organization.role.create`, `edit`, `assign`, and `order`
- `organization.unit.create`, `manage`, and `assign`
- `organization.duty.configure`, `begin`, `supervise`, and `override`
- `organization.asset.view`, `assign`, `transfer`, `archive`, and `recover`
- `organization.finance.view`, `pay`, `invoice`, `approve`, `budget`, and `audit`
- `organization.property.access`, `manage`, and `grant_key`
- `organization.vehicle.use`, `manage`, `impound`, and `recover`
- `organization.communication.chat`, `radio`, `announcement`, and `motd`
- `organization.recruitment.publish`, `review`, `interview`, and `decide`
- `organization.relationship.propose`, `approve`, `terminate`, and `view_private`
- `organization.record.create`, `classify`, `disclose`, and `expunge`

A request is allowed only when all relevant boundaries pass: authenticated account, selected character, valid membership, matching organization, role capability, duty or location state where required, valid target and inputs, resource-specific game rules, cooldown/rate policy, and durable mutation success. Discord may grant global staff capabilities, but it must never fabricate organization membership or bypass game-domain rules.

## Target service boundary

Introduce a server-authoritative `organization` service or compatibility facade. New consumers use data-transfer objects and commands rather than raw MTA team elements.

Read contracts might include:

- `getOrganization(organizationId)`
- `listCharacterMemberships(characterId)`
- `getMembership(characterId, organizationId)`
- `hasOrganizationCapability(actor, organizationId, capability, context)`
- `getActiveDutyAssignment(characterId)`
- `listOrganizationUnits(organizationId)`
- `listOrganizationAssets(organizationId, assetType)`
- `listOrganizationRelationships(organizationId, visibility)`

Mutation contracts should be named commands with idempotency and audit context:

- `inviteMember`, `acceptInvitation`, `rejectInvitation`, `removeMember`
- `createRole`, `updateRoleCapabilities`, `assignRole`
- `createUnit`, `assignToUnit`, `archiveUnit`
- `beginDuty`, `endDuty`, `configureDutyPackage`
- `assignAsset`, `transferAsset`, `archiveAsset`
- `createExpense`, `approveExpense`, `transferOrganizationFunds`
- `proposeRelationship`, `approveRelationship`, `terminateRelationship`

Every command derives the actor from MTA's server-side `client` or a trusted server caller. IDs, prices, permissions, owner identities, and state transitions are never accepted as authoritative client facts.

## Compatibility plan

### Phase 1: freeze and observe

- Inventory every `exports.factions` call, faction event, command, element-data key, numeric type check, hard-coded ID, SQL reference, and asset-owner column.
- Add deprecation telemetry without changing behavior.
- Record active/archive provider mismatches and startup-order dependencies.
- Define one canonical mapping for current numeric types, including the type-7 Dealership/Mechanic drift.

### Phase 2: facade

- Add the organization DTO and named-capability read layer over current faction state.
- Keep old exports, events, `/faction`, and related commands as adapters.
- Add `/organization` and new UI terminology while retaining old aliases.
- Prevent external APIs from exposing raw team elements, numeric type assumptions, or legacy column names as permanent public contracts.

### Phase 3: command migration

- Route membership, rank, duty, asset, and finance mutations through audited organization commands.
- Give each mutation a correlation ID, actor, target, before/after summary, outcome, and failure reason.
- Convert consuming resources by domain rather than through a repository-wide rename.

### Phase 4: persistence normalization

- Add unique membership constraints and validate that every membership role belongs to the same organization.
- Introduce typed ledger owners instead of negative faction IDs.
- Normalize organization types, policies, roles, capabilities, units, assets, relationships, invitations, and lifecycle state.
- Produce orphan, duplicate, invalid-rank, missing-owner, and hard-coded-ID reports before enforcing foreign keys.
- Use expand-and-contract migrations, dual-read comparison, backups, and rollback. Do not mutate the only copy of legacy data.

### Phase 5: retire legacy language

- Remove old aliases only after usage telemetry reaches an operator-approved threshold.
- Preserve migration documentation for integrations and forks.
- Keep database compatibility views when they materially reduce migration risk.

## Target persistence model

Names are provisional; migrations require schema review:

- `organizations`: identity, class, profile, lifecycle state, visibility, public metadata, and version.
- `organization_types`: operator-defined type, defaults, allowed policies, and presentation.
- `organization_memberships`: organization, character, status, join/leave dates, source, and version.
- `organization_roles`: organization-local role identity, display name, order, and lifecycle state.
- `organization_role_capabilities`: named capability assignments with optional conditions.
- `organization_membership_roles`: many-to-many role assignment where the organization permits it.
- `organization_units` and `organization_unit_memberships`: nested operational structures.
- `organization_duty_assignments`: active duty, package, callsign, location, start/end, and supervisor.
- `organization_assets`: typed links to vehicles, properties, inventories, phones, frequencies, or future assets.
- `organization_accounts`, `ledger_accounts`, and `ledger_entries`: typed financial ownership and immutable postings.
- `organization_relationships`: alliance, contract, rivalry, parent, affiliate, supplier, regulator, or operator-defined relation.
- `organization_applications` and `organization_invitations`: explicit recruitment workflow and expiry.
- `organization_audit_events`: append-only actor, capability, target, result, correlation ID, and redacted metadata.

Sensitive criminal or covert membership requires explicit visibility rules. Ordinary APIs and dashboards must not leak hidden organization existence, membership, assets, relationships, or investigations.

## Organization lifecycle

Organizations need lifecycle states rather than destructive disappearance:

1. Proposed or informal group
2. Active but unregistered
3. Registered or institutionally recognized
4. Suspended, inactive, dissolved, or archived
5. Operator-held recovery state when leadership is lost

Deletion should normally be archival. Before any destructive action, show a dry-run inventory of members, assets, accounts, properties, vehicles, cases, evidence, duties, applications, relationships, and downstream references. Require an explicit transfer, liquidation, preservation, or archival decision for each category.

## Recruitment and social discovery

Support different social textures instead of one public application form:

- Public listings and applications for ordinary employers or community groups
- Qualification-based applications for licensed roles
- Invitation and interview workflows
- Referral-only or reputation-gated introductions
- In-world recruitment through venues, contacts, events, and mutual relationships
- Anonymous or pseudonymous approaches for risky organizations
- Staff-reviewed exceptional applications without requiring an external website

Applications must be manageable in game. A future website or API client is optional and uses the same server-owned workflow.

## Relationships and diplomacy

Relationships should carry terms and visibility, not just a friendly/hostile flag:

- Service, supply, employment, regulatory, mutual-aid, access, protection, non-aggression, alliance, rivalry, or confidential cooperation
- Proposed, active, disputed, suspended, expired, and terminated states
- Signatories and approval rules
- Start/end times, review dates, obligations, fees, shared access, and breach events
- Public, member-visible, leadership-only, or covert visibility

This supports lawful contracts, interdepartmental operations, business supply chains, criminal networks, informants, fronts, and temporary task forces through one relationship engine.

## Dashboards and interactions

The in-game organization workspace should provide modules according to capability:

- Identity, public profile, directory entry, and contact points
- Membership, roles, units, attendance, activity, and succession
- Applications, invitations, interviews, and onboarding checklists
- Duty roster, schedules, callsigns, certifications, and equipment packages
- Assets on a map with status, assignment, access, maintenance, and history
- Finance with balances, budgets, invoices, payroll, expenses, approvals, and immutable ledger views
- Communications, announcements, policies, forms, and acknowledgements
- Relationships, contracts, suppliers, regulators, and disputes
- Audit timeline and recovery tools

Contextual interaction can open organization-aware actions on a member, vehicle, property, terminal, evidence item, or business. The server returns available actions from a registry based on capability and current state; the client never decides authority.

## Discord and API boundaries

- Discord authenticates the account and may resolve configured global capabilities.
- Organization membership and roles remain game-owned unless an operator explicitly configures a narrow one-way or approval-based synchronization rule.
- No Discord role ID is checked directly in gameplay scripts.
- Revoked identity authorization terminates active sessions according to the session-revocation plan.
- API responses expose stable organization DTOs and capability-filtered views, not legacy tables or MTA elements.
- Website, bot, and dashboard clients call the same audited commands as in-game UI.

## Validation gates

Before enabling the new service in production:

- Build a complete consumer and data-reference inventory.
- Prove adapter parity for representative legal, criminal, commercial, and community organizations.
- Verify multiple memberships, conflicting roles, duty, leadership, assets, finance, applications, and archived organizations.
- Attempt stale, replayed, cross-organization, unauthorized, out-of-range, and malformed requests.
- Verify Discord and API outages do not corrupt organization state.
- Confirm hidden organizations and private relationships do not leak through lists, logs, notifications, or API errors.
- Rehearse organization archival, leadership recovery, asset transfer, and migration rollback using disposable data.

The current server remains unrun; all runtime gates are pending.
