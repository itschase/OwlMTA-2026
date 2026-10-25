# Criminal Roleplay Framework

## Status and design intent

This document is a proposed product and technical design. It does not describe features as implemented unless a source-backed current-state note says so. Runtime behavior is unverified.

Criminal roleplay should emerge from relationships, opportunity, preparation, risk, evidence, markets, and consequences. It should not be a menu of repeatable payouts, a permanent map-color war, or a privileged feature reserved for staff-created factions. Solo characters, informal crews, registered organizations, front businesses, victims, investigators, courts, medical services, journalists, and ordinary residents should all have meaningful agency.

Real-world harmful instructions are out of scope. Illicit production and contraband use abstract, fictional recipes and game systems.

## Current source boundary

The legacy organization system labels type `0` as Gang and type `1` as Mafia, but primarily gives those groups the same roster, ranks, chat, assets, interiors, vehicles, and finance container used by lawful organizations. Duty-oriented permissions are suppressed for those types. The static review has not found one coherent criminal progression, discovery, territory, supply, laundering, evidence, diplomacy, or lifecycle framework.

This means the rebuild should preserve useful group state while designing the missing criminal ecosystem deliberately.

## Design principles

- **Roleplay before rewards:** actions should create relationships, scenes, evidence, debts, rumors, obligations, and consequences—not only currency.
- **Information is gameplay:** characters learn opportunities through people, observation, records, contacts, reputation, and investigation rather than global markers.
- **Preparation matters:** plans, tools, access, timing, transport, storage, scouting, and collaborators change outcomes.
- **Counterplay exists:** victims, businesses, security, law enforcement, rivals, courts, and staff each have fair responses.
- **Failure creates stories:** partial success, lost goods, injuries, witnesses, debts, damaged trust, arrests, and contested evidence are preferable to binary win/lose resets.
- **Server authority:** outcomes, prices, inventory, ownership, evidence, witnesses, cooldowns, and eligibility are calculated and persisted server-side.
- **No omniscience:** law enforcement receives observations and evidence, not magical actor identity; criminals do not see invisible investigation state.
- **No grind monopoly:** time investment helps, but exclusive knowledge, off-hours play, or repetitive farming cannot permanently lock a domain.
- **Configurable tone:** operators control severity, frequency, rewards, evidence, required population, cooldowns, injury, and permanent-consequence policy.
- **Consent and boundaries:** sensitive scenes need clear server rules, opt-outs where appropriate, staff review paths, and protections against targeted harassment.

## Participation layers

Characters can participate without immediately creating a formal organization:

1. **Independent:** one character, personal contacts, low-complexity opportunities, and limited trust.
2. **Informal crew:** temporary shared plan, invitations, split agreement, shared scene log, and expiration.
3. **Persistent crew:** a named private group with roles, hideouts, relationships, and collective reputation.
4. **Organization:** durable governance, assets, finance, diplomacy, applications, and a complete audit trail.
5. **Network:** several organizations, suppliers, fronts, affiliates, contractors, informants, and corrupt relationships connected through explicit agreements.

Progression is not a mandatory ladder. A skilled independent fixer, fence, lawyer, driver, broker, or informant may remain intentionally unaffiliated.

## Trust, reputation, and discovery

Use several scoped reputations instead of one criminal level:

- Reliability: completed agreements and honored splits
- Discretion: avoided unnecessary witnesses, exposure, or public attention
- Capability: demonstrated competence in a particular discipline
- Violence: perceived willingness to escalate, which opens some doors and closes others
- Heat: recent institutional attention tied to observable incidents and evidence
- Debt: favors, loans, unpaid shares, and obligations
- Standing: relationship-specific trust with one contact, organization, neighborhood, or market

Reputation is not fully visible. Players receive qualitative signals, rumors, contact behavior, and history they personally know. Staff can inspect a privacy-filtered diagnostic view with source events and override audit.

Contacts can be people, businesses, organizations, locations, communication channels, or recurring NPC roles. Access may require introduction, shared history, a reference, proof of capability, payment, a favor, a location, a time window, or another verifiable condition.

## Opportunity framework

Build reusable opportunity definitions rather than bespoke robbery resources. An opportunity describes:

- Eligibility and discovery rules
- Required and optional roles
- Location, time, population, world-state, and prerequisite conditions
- Preparation steps and optional intelligence
- Tools, vehicles, disguises, access, and consumables
- Server-owned state machine and timeout/recovery behavior
- Branches, complications, witnesses, alarms, and partial outcomes
- Loot or objective generation and provenance
- Evidence emissions and forensic quality
- Injury, property, reputation, relationship, and economic effects
- Cooldowns, anti-farming, concurrency, and global scarcity
- Staff observation and intervention policy
- Structured audit events and replay-resistant settlement

Example opportunity families:

- Opportunistic theft, burglary, lock bypass, shoplifting, and stolen-property handling
- Vehicle theft, cloning, stripping, export, chop-shop, and recovery
- Cargo interception, warehouse diversion, smuggling, and high-value transport
- Store, business, residence, armored transport, convoy, and institution robberies
- Counterfeit goods, forged documents, fraud, identity misuse, and financial schemes
- Underground racing, betting, fighting, card rooms, and illegal events
- Protection, intimidation, debt collection, extortion, and negotiated illicit services
- Contraband sourcing, transport, storage, packaging, and distribution
- Information theft, blackmail, surveillance, and insider access
- Contract work such as driving, scouting, lookout, recovery, fencing, or brokering

Each family should produce roleplay before, during, and after the mechanical event.

## Contraband and fictional production

Use a general recipe and supply-chain framework:

- Operator-defined fictional materials, intermediates, tools, stations, recipes, hazards, quality, and yield
- Abstract processes rather than real manufacturing instructions
- Location and equipment suitability
- Batch identity and provenance
- Quality, contamination, packaging, concealment, and degradation
- Supply scarcity, market demand, contact preferences, and regional price variation
- Waste, failed batches, injury risk, odor/noise/utility signals, and discoverable evidence
- Storage conditions and property/container ownership
- Distribution relationships, samples, credit, consignment, and debt
- Configurable player-health effects, tolerance abstractions, treatment, and policy

The same framework can power lawful crafting, food production, medicine, manufacturing, repair, and agriculture, allowing criminal content to reuse tested infrastructure.

## Markets, fronts, and laundering

Illicit value should not become clean money instantly.

- Every valuable item has provenance: lawful purchase, production batch, theft, seizure release, evidence hold, or unknown source.
- Fences and buyers have category preferences, capacity, risk tolerance, price curves, relationships, and cooldowns.
- Market demand changes by region, time, world events, enforcement pressure, and recent supply.
- Front businesses accept only configured transaction types and have throughput tied to believable operation.
- Laundering has cost, delay, capacity, documentation, counterparty, and detection risk.
- Large unusual transactions can create review signals without automatically proving wrongdoing.
- Money and assets move through a typed double-entry ledger, not client-supplied balance changes.
- Staff can trace provenance and correction events without exposing hidden investigative data to ordinary players.

## Territory as influence

Avoid permanent colored zones controlled only by kill counts. Model several local influence dimensions:

- Social support and fear
- Market access and supplier relationships
- Physical presence and safe locations
- Information and lookout coverage
- Business and institutional relationships
- Law-enforcement attention
- Rival activity and unresolved incidents

Influence changes through sustained roleplay, services, business, events, negotiations, intimidation, visible disorder, investigations, and community response. It decays and can be contested without mandatory combat. A neighborhood may simultaneously trust one group, fear another, buy from a third, and cooperate with a public institution.

## Evidence and investigation

Use an evidence event pipeline shared across crimes:

- Evidence has type, origin event, collection location/time, quality, contamination state, custody history, visibility, retention, and related entities.
- Potential evidence includes witnesses, camera observations, fingerprints, DNA abstractions, casings, tool marks, footprints, fibers, damaged locks, device records, phone records, vehicle traces, transaction signals, stolen-item provenance, and scene photographs.
- Not every action emits every evidence type. Gloves, masks, weather, fire, cleanup, time, handling, and scene disturbance affect quality through game abstractions.
- Witnesses record observations such as clothing, voice, vehicle, direction, and behavior rather than an account or character ID.
- Cameras have owner, field, quality, health, storage, retention, and access policy.
- Collection requires location, authorization, inventory capacity, and training where configured.
- Transfers append chain-of-custody entries; they never rewrite history.
- Labs produce probabilistic or quality-bounded results according to operator policy.
- Courts and staff can see why a result exists. Players see only information their character is authorized to know.

Investigation workspaces can link incidents, people, organizations, vehicles, properties, evidence, warrants, interviews, reports, and timelines without automatically asserting guilt.

## Heat, suspicion, and response

Separate three concepts:

- **Incident alert:** something was reported or detected and may need response.
- **Investigative suspicion:** authorized characters have accumulated observations or evidence connecting a subject.
- **Operational heat:** recent patterns change patrols, contact behavior, prices, security, or opportunity availability.

No global wanted marker should reveal identity without an in-world basis. Dispatch information may be incomplete, delayed, contradictory, or updated. Losing sight should matter. Warrants, alerts, and BOLOs have authors, scope, reason, evidence references, approval, expiration, and audit.

## Justice and corrections

Criminal mechanics require equally deep consequence systems:

- Reports, citations, arrests, booking, property/evidence intake, charges, counsel, bail, hearings, plea, trial, sentencing, appeal, expungement, and release
- Configurable thresholds for automated, player-led, and staff-assisted procedures
- Court calendars and asynchronous case progress so every case does not require all roles online simultaneously
- Clear separation among allegation, charge, conviction, staff sanction, and server ban
- Sentence objectives beyond waiting: work, education, treatment, visitation, legal consultation, recreation, organization activity, and release planning
- Prison contraband, influence, investigations, and staff safety with strong anti-harassment rules
- Probation/parole conditions and documented violation review
- Record visibility, sealing, expungement, and public-information policy

## Victim and civilian agency

Crime cannot exist only for offenders and police. Provide:

- Property and vehicle security choices with visible tradeoffs
- Insurance, recovery, replacement, repair, documentation, and fraud investigation
- Witness reporting, anonymous tips, statements, lineups, and later corrections
- Business panic/security controls, staff training, cash-management policy, and alarm contracts
- Neighborhood alerts, community meetings, journalism, advocacy, and political response
- Restitution, mediation, civil claims, and negotiated resolution where appropriate
- Scene consent guidance and clear escape from harassment disguised as roleplay

## Organization-specific criminal capabilities

Criminal organizations reuse the general Organizations Framework. Optional capabilities may include:

- Manage cells or crews without exposing the entire membership
- Assign safe locations, fronts, storage, vehicles, and communication channels
- Maintain internal debts, shares, favors, and role-scoped knowledge
- Approve high-risk plans, suppliers, alliances, or retaliation under server rules
- Run legitimate business operations without making criminal status visible
- Record agreements and distributions while keeping sensitive data capability-filtered
- Establish diplomacy, tribute, protection, supplier, and non-aggression relationships
- Archive members and assets without erasing audit history

The server must not display a character's criminal organization merely because a row exists. Visibility is contextual and policy-driven.

## User experience

Reduce command memorization through contextual, state-aware interfaces:

- Third-eye interactions on doors, vehicles, containers, terminals, evidence, and people
- Planning boards for roles, objectives, routes, equipment, shares, and contingency notes
- Contact and rumor journal showing what the character actually knows
- Secure message threads and dead-drop abstractions
- Stash/container views with provenance, access history, concealment, and capacity
- Opportunity dashboards that show prerequisites without revealing undiscovered content
- Investigation and case workspaces for authorized justice roles
- Scene history and receipts for disputes without exposing hidden server logic

All contextual actions come from a server-owned action registry. Commands remain as accessible aliases and operational fallbacks until usage and accessibility goals support retirement.

## Balancing and anti-farming

- Use dynamic supply, buyer capacity, local demand, risk, and diminishing returns rather than arbitrary daily limits alone.
- Separate personal cooldowns, organization cooldowns, location recovery, global scarcity, and narrative availability.
- Require varied inputs and relationships, not repetitive clicks.
- Detect impossible speed, duplicate settlement, replay, collusion patterns, and self-dealing as review signals rather than automatic guilt.
- Preserve legitimate late-night or low-population play through scalable alternatives.
- Make rewards cover preparation, collaborator shares, loss risk, laundering, replacement, and time—not just headline payout.
- Measure money creation, item creation/destruction, opportunity completion/failure, injury, evidence, enforcement response, and market concentration.

## Staff and operator controls

Operators configure content and risk without editing Lua:

- Feature flags and staged rollout population
- Opportunity definitions, locations, schedules, required population, cooldowns, and concurrency
- Recipe/material definitions and abstract hazards
- Market demand, capacity, price bounds, and sinks
- Evidence types, emission chances, quality rules, retention, and lab behavior
- Response, dispatch, warrant, court, sentence, and record policies
- Consent restrictions, prohibited scenes, safe zones, and escalation limits
- Audit retention, privacy, redaction, and external logging adapters

Staff tools should allow observation, freeze, rollback, correction, and annotated intervention. They should not offer invisible outcome manipulation without an immutable record.

## Domain event model

Representative events include:

- `opportunity.discovered`, `planned`, `started`, `branched`, `failed`, `completed`, `settled`
- `contraband.batch.created`, `transformed`, `split`, `transferred`, `consumed`, `destroyed`, `seized`
- `asset.provenance.changed`
- `relationship.introduction.created`, `trust.changed`, `debt.created`, `debt.settled`
- `incident.reported`, `response.dispatched`, `scene.secured`
- `evidence.emitted`, `collected`, `transferred`, `analyzed`, `contested`, `released`, `destroyed`
- `case.opened`, `subject.linked`, `warrant.requested`, `warrant.decided`, `charge.filed`, `case.resolved`
- `organization.operation.created`, `participant.assigned`, `share.agreed`, `share.settled`

Events carry a correlation ID, actor/caller classification, relevant character/account/organization/asset IDs, source resource, outcome, policy version, and redacted structured metadata. Sensitive information is access-controlled at query time.

## Delivery slices

### Slice 1: shared foundations

- Typed ledger transaction API
- Item provenance and container access history
- Server-owned contextual action registry
- Correlated audit events
- Informal crew and shared-plan state
- One small theft-to-fence opportunity with evidence and a victim recovery path

### Slice 2: investigation loop

- Incident reports, witness observations, scene evidence, chain of custody, case workspace, and one warrant type
- Dispatch and responding-role UX
- Staff diagnostics and rollback

### Slice 3: market and production

- Abstract recipe framework, batch provenance, one fictional contraband chain, dynamic buyer demand, and one configurable front-business conversion path

### Slice 4: organization operations

- Persistent criminal organization profile, cells/units, scoped knowledge, assets, finance, relationships, and operation planning

### Slice 5: justice and corrections

- Booking-to-resolution workflow, evidence presentation, sentencing policy, meaningful custody activities, and release conditions

Every slice requires failure recovery, privacy review, exploit review, operator documentation, player/staff guidance, telemetry, and disposable runtime validation before production enablement.

## Success measures

- Players can enter criminal roleplay through relationships and small opportunities without joining a formal organization.
- Criminal organizations create scenes and dependencies rather than only accumulating assets.
- Civilians, businesses, journalists, attorneys, medical staff, public services, and investigators receive meaningful connected gameplay.
- Investigations rely on evidence and authorized information, not omniscient UI.
- Economy telemetry can explain where value was created, transferred, cleaned, seized, destroyed, or corrected.
- Staff can resolve disputes from structured evidence without becoming routine game masters for every outcome.
- Operators can tune or disable each domain without code edits or external website dependency.
