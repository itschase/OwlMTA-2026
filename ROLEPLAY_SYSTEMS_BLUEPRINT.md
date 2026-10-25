# Living Roleplay Systems Blueprint

## Status

This is a proposed long-range product map, not a statement of implemented behavior. It complements the source-grounded resource dossiers by describing the reusable systems and connected roleplay loops the rebuild can grow toward. Each implementation unit must still receive a source audit, design decision, Issue, security review, operator configuration, documentation, and controlled runtime gate.

## Product goal

Create a world where players can form identities, relationships, institutions, businesses, communities, and conflicts whose effects persist and remain understandable. Depth should come from connected systems and meaningful choices, not command memorization, repetitive meters, or staff-mediated outcomes.

The gamemode should support serious text roleplay, voice-first operation, and a mixed accessibility mode through configuration. It should remain self-hostable and fully operable in game without a website.

## Shared platform primitives

Build these once and let every domain reuse them:

### Identity and authority

- Discord-first account authorization with bounded leases and revocation
- Character identity, aliases, documents, licenses, records, and disclosure rules
- Global named capabilities for staff and specialist teams
- Organization-local membership and capabilities
- Duty, certification, location, ownership, proximity, and target-state requirements
- Delegation and temporary grants with issuer, scope, expiry, and audit

### Interaction and discoverability

- Server-owned contextual action registry for people, vehicles, doors, interiors, items, NPCs, terminals, businesses, and map locations
- Command registry that supplies aliases, examples, prerequisites, capability descriptions, and help search
- Consistent action availability, disabled reasons, confirmations, cancellation, progress, and failure feedback
- Keyboard, mouse, controller, text, and accessibility alternatives
- Deep links among dashboards, map records, entities, notifications, and help entries

### Durable workflows

- Versioned state machines for applications, contracts, purchases, cases, jobs, crafting, treatment, investigations, and approvals
- Idempotency keys and correlation IDs for every high-value mutation
- Explicit pending, accepted, rejected, cancelled, expired, failed, compensated, and completed states
- Recovery queues for partially completed external, database, or cross-resource operations
- Actor-scoped confirmations that expire and revalidate the target record

### Economy and ownership

- Typed accounts and double-entry ledger postings
- Money, item, asset, and entitlement provenance
- Escrow, invoices, contracts, recurring payments, payroll, budgets, taxes, debt, and refunds
- Atomic or compensating transaction boundaries with durable outcome records
- Configurable faucets, sinks, caps, demand, scarcity, and catch-up limits
- Operator dashboards explaining creation, destruction, concentration, and correction of value

### Time and scheduling

- One canonical game/real-time service with time zones and daylight-saving policy
- Appointments, shifts, hearings, deliveries, events, elections, expirations, renewals, and maintenance
- Offline-safe timers stored as deadlines rather than fragile process timers
- Bounded catch-up behavior after restart or extended player absence
- Reminders and notifications that do not require Discord or a website

### Spatial and world state

- Stable entity/location identifiers independent of display names
- Interior, dimension, colshape, distance, line-of-sight, occupancy, and access policies
- Districts, neighborhoods, jurisdictions, service areas, and routes
- Capacity, queues, opening hours, utilities, maintenance, damage, and temporary closure
- World events and modifiers with source, duration, affected area, and rollback

### Information and knowledge

- Character-known facts separated from player-visible system facts
- Public records, private records, classified records, rumors, observations, and disputed claims
- Source, confidence, time, access path, retention, correction, and disclosure for information
- Search views filtered by current authorization rather than sending full data to the client
- News, notices, reports, evidence, case links, and organization knowledge built on shared records

### Audit and observability

- Structured domain events with actor, subject, resource, correlation ID, policy version, result, and redacted metadata
- Separate security, moderation, economy, gameplay, integration, and diagnostic streams
- Local files and database records as the no-dependency baseline
- Optional adapters for Discord webhooks, Grafana-compatible backends, media providers, or other operator-selected services
- Privacy, retention, legal/consent, redaction, export, and deletion policies

## Living-world systems

These systems create continuity between scripted activities:

### Locality and neighborhoods

- Neighborhood profiles containing housing, businesses, services, transit, safety perceptions, community groups, and current events
- Player and organization activity can influence demand, reputation, local news, complaints, security, and public policy
- Influence is multidimensional and decays; it is not permanent color ownership
- Local opportunities respond to population, time, recent incidents, supply, and relationships

### Institutional memory

- Organizations remember applications, employment, qualifications, discipline, contracts, cases, assets, and public decisions
- Characters can correct disputed records through in-world processes
- Destructive staff correction creates an immutable correction record
- Archived organizations and characters retain history without remaining active gameplay entities

### Rumor and social knowledge

- Rumors originate from observable events, witnesses, media, organizations, or deliberate claims
- Information spreads through proximity, relationships, communication channels, publications, and locations
- Accuracy can degrade; confirmation and retraction are gameplay
- Hidden metadata prevents rumors from becoming an exploitative identity oracle

### Dynamic demand and service pressure

- Businesses and jobs respond to player consumption, inventory, orders, location, world events, and unmet services
- Public services see queues, response load, staffing, budgets, and maintenance rather than infinite isolated calls
- Scarcity creates alternatives and opportunities but has operator-enforced safety bounds
- Automated demand never creates unbounded passive income

### Maintenance and decay

- Vehicles, properties, equipment, infrastructure, licenses, and organizations can require maintenance or renewal
- Neglect changes performance, availability, value, appearance, or risk, not arbitrary deletion
- Operators configure minimums and opt out of systems that do not suit their server tone
- Recovery routes prevent absence from erasing months of progress

## Roleplay domain map

### Character life

- Guided creation with background, languages, appearance, accessibility, and starting connections
- Names, aliases, identity documents, signatures, biometrics abstractions, and privacy
- Skills based on meaningful practice, education, certification, and mentorship
- Relationships, households, dependents, emergency contacts, wills, inheritance, and succession
- Personal goals, journals, appointments, reminders, and known-information records
- Character retirement, incapacitation, death, missing status, and carefully governed permanent consequences

### Social and community life

- Friendships, circles, clubs, associations, venues, invitations, and recurring gatherings
- Neighborhood boards, charities, religious/community groups, unions, advocacy, and volunteer work
- Calendars, event creation, ticketing, seating, staffing, vendors, security, media, and post-event records
- Reputation scoped to relationships and communities rather than one universal score
- Consent tools, scene boundaries, accessibility preferences, and harassment reporting

### Housing and property

- Ownership, rental, leases, roommates, keys, access schedules, deposits, utilities, insurance, and maintenance
- Furnishing, storage, deliveries, renovations, damage, alarms, cameras, and service providers
- Property listings, inspections, applications, offers, escrow, closing, tax, foreclosure safeguards, and transfer history
- Multi-unit buildings, associations, landlords, tenants, shared facilities, and dispute workflows
- Commercial, industrial, government, organization, and temporary-event occupancy

### Transportation and vehicles

- Dealerships, private sales, financing, leasing, registration, plates, inspections, insurance, and tax
- Keys, authorized drivers, fleet assignment, logs, maintenance, damage, towing, impound, storage, and recovery
- Fuel, battery, charging/future energy abstractions, wear, parts, workshops, and roadside assistance
- Public transit, taxi, ride dispatch, buses, trucking, aviation, logistics, parking, tolls, and traffic incidents
- Theft, recovery, provenance, forensic traces, salvage, auction, and lawful/criminal resale

### Work and professions

- Employment applications, interviews, contracts, shifts, timesheets, qualifications, supervision, and discipline
- Career ladders that reflect responsibility and skill rather than only grind levels
- Gig work, contracting, temporary shifts, apprenticeships, internships, and volunteer service
- Safety procedures, equipment checkout, service quality, customer feedback, and incident reporting
- Meaningful work for legal, medical, public-service, technical, creative, logistical, and hospitality roles

### Business and industry

- Ownership, investment, shares, governance, staffing, payroll, suppliers, inventory, production, pricing, and sales
- Purchase orders, shipping, receiving, storage, spoilage, quality, returns, warranty, and maintenance
- Customer demand, contracts, bids, invoices, credit, debt, tax, insurance, permits, inspection, and compliance
- Bounded offline/background activity based on stock, staffing, capacity, demand, upkeep, and catch-up limits
- Agriculture, fishing, mining abstractions, manufacturing, construction, utilities, repair, hospitality, retail, media, and professional services
- Business failure, restructuring, sale, succession, receivership, and recovery without silent asset deletion

### Government and civic systems

- Offices, departments, jurisdictions, budgets, procurement, grants, public records, meetings, and service requests
- Elections, candidacy, campaign finance, debates, voting, appointments, recall/term policy, and transition
- Legislation, regulations, executive orders, publication, effective dates, amendment, and repeal
- Licensing, permits, inspections, fees, hearings, appeals, and renewal
- Public works, utilities, zoning, transportation, emergency planning, and community feedback

### Public safety and dispatch

- Unified incident intake with caller information, location confidence, priority, notes, updates, and linked reports
- Dispatch roles, unit status, assignments, mutual aid, jurisdiction, supervisor escalation, and after-action review
- Police patrol, traffic, investigation, warrants, evidence, custody, property, and community interaction
- Fire, rescue, hazards, inspections, alarms, apparatus, water/supply abstractions, and scene command
- EMS triage, treatment, transport, hospital handoff, records, privacy, billing policy, and follow-up
- Search and rescue, aviation, maritime/remote incidents where the map and resources support them

### Health and wellbeing

- Injury states designed for roleplay and recovery rather than opaque punishment
- Examinations, diagnosis abstractions, treatment plans, medication abstractions, procedures, rehabilitation, and discharge
- Clinics, hospitals, pharmacies, records, consent, confidentiality, insurance, and billing
- Mental-health roleplay only with careful operator policy, consent, trained roles, and no involuntary simulation by default
- Occupational health, public-health notices, outbreaks as optional events, and wellness services

### Law, courts, and corrections

- Attorneys, representation, client intake, privilege, contracts, filings, research, and scheduling
- Incidents, evidence, charges, citations, warrants, hearings, plea, trial, orders, judgments, appeal, and expungement
- Civil disputes, contracts, property, employment, licensing, and administrative review
- Booking, custody, bail, visitation, sentencing, prison activity, parole/probation, release, and reintegration
- Clear separation of in-character justice, staff moderation, and account bans

### Media and public information

- Reporting assignments, interviews, source protection, photography, video/media references, editing, publication, and corrections
- Newspapers, broadcasts, emergency alerts, advertisements, classifieds, public notices, and event coverage
- Press credentials, access rules, public-record requests, embargoes, and institution communications
- Audience and distribution abstractions without manipulative engagement grind

### Education and certification

- Schools, academies, courses, instructors, enrollment, attendance, assessment, qualification, and renewal
- Driving, professional, emergency-service, trade, aviation, legal, and operator-defined certifications
- Mentorship and apprenticeship tied to actual supervised activity
- Study materials and practical scenarios available in game without external websites

### Recreation and culture

- Sports leagues, tournaments, gyms, outdoor activities, racing, games, arts, music, venues, nightlife, tourism, and collecting
- Clubs and event organizations with schedules, rosters, rules, standings, prizes, media, and sponsorship
- Player-created cultural content with moderation and asset-provider abstraction
- Seasonal events as configuration packages rather than permanent hard-coded resource forks

### Crime and underground life

- Independent, crew, organization, and network participation
- Contacts, reputation, opportunity, preparation, markets, fictional production, fronts, laundering, evidence, and consequence
- Victim recovery, investigation, justice, medical, media, political, and community connections
- Detailed design lives in [CRIMINAL_ROLEPLAY_FRAMEWORK.md](CRIMINAL_ROLEPLAY_FRAMEWORK.md).

## Advanced possibilities beyond conventional roleplay scripts

### Player-created services as first-class systems

Let characters publish service offers, operating hours, coverage area, price model, qualifications, and booking rules. Other players can request service, negotiate, contract, pay through escrow, review completion, dispute outcomes, and build relationship history. The same framework supports mechanics, attorneys, photographers, transport, security, catering, event staffing, medical practices, construction, consulting, and illicit intermediaries.

### Procedural prompts without procedural outcomes

The server may generate incidents, demand, shortages, contracts, rumors, maintenance needs, or public-service requests. Players decide what happens. Automation creates prompts and records constraints; it does not replace roleplay with invisible success rolls.

### Roleplay continuity packages

A scene or operation can produce a private continuity package: participants, agreed facts, assets transferred, injuries, evidence, debts, appointments, follow-ups, and unresolved questions. This helps players resume stories across sessions without creating omniscient public records.

### Institutional simulation

Budgets, staffing, queues, assets, regulations, and service outcomes can influence one another. A vehicle shortage affects response times; delayed inspections affect business openings; supply problems affect repair costs; public incidents affect policy and news. Every relationship remains operator-bounded to prevent runaway simulation.

### Meaningful bureaucracy

Forms and approvals should create choices, records, accountability, and interaction—not paperwork for its own sake. Reusable form definitions, signatures, attachments, review queues, deadlines, delegation, correction, and appeal can support government, business, organizations, courts, medical care, and staff administration.

### World memory and seasonal history

Major elections, trials, disasters, openings, closures, championships, investigations, and public projects can become searchable in-world history. Operators control retention and privacy. This gives future roleplay context without requiring players to search old forum posts.

### Multi-perspective incident reconstruction

Reports, witness statements, dispatch logs, evidence, media, medical records, and staff audit events can describe the same incident from different authorized perspectives. No single player-facing record is treated as omniscient truth.

### Graceful low-population operation

Critical services can use queues, appointments, asynchronous records, bounded NPC assistance, or operator-defined fallback workflows when a role is unavailable. Fallbacks should create later player follow-up rather than replacing players permanently.

## User-interface architecture

Use one application shell with domain modules rather than a giant universal admin panel:

- Global search and command/action discovery
- Context-sensitive launch from world entities
- Saved filters, recent records, drafts, and notifications
- Map, list, detail, timeline, relationship, ledger, and case views
- Capability-filtered actions and clear disabled reasons
- Optimistic UI only where safe; authoritative result and reconciliation always come from the server
- Small-screen scaling, color/contrast, readable text, focus management, and keyboard navigation
- Consistent confirmation and irreversible-action warnings
- Player, staff, operator, and diagnostic views over the same domain contracts with different disclosure

## Delivery strategy

### One-day documentation/vertical-slice target

For any new domain, document one end-to-end story before broad implementation: entry point, actor, context, authoritative command, state transition, persistence, audit event, notification, failure, recovery, player guide, staff guide, operator config, security cases, and runtime test plan. A minimal prototype should prove this single path with disposable data.

### Production hardening

Production requires concurrency handling, schema migrations, idempotency, rate limits, permissions, privacy, accessibility, failure recovery, observability, configuration validation, rollback, load bounds, and adversarial runtime tests. A successful vertical slice does not satisfy these gates.

### Sequencing

1. Finish static resource inventory and security boundaries.
2. Establish identity, capability, configuration, audit, transaction, and interaction primitives.
3. Migrate one current feature per primitive to prove compatibility.
4. Build connected domain slices rather than broad disconnected feature lists.
5. Publish player, staff, operator, API, and developer documentation with each slice.
6. Run the server only after the documented safe-start prerequisites are complete.

## Documentation rule

Every proposed system becomes a tracked package: maintained repository design, GitHub Discussion, bounded implementation Issues, milestone placement, dependencies, source/current-state notes, security model, rollout slices, and verification state. This blueprint is an index of possibilities; it is not permission to implement unreviewed behavior as one monolithic change.
