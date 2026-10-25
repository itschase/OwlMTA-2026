# `map_manager`

## Status

- Active resource; full manifest/client/server caller review completed; runtime unverified.
- Discussion: [Script Resource: map_manager](https://github.com/itschase/OwlMTA-2026/discussions/266).
- Source contains meaningful authorization fixes; those are not runtime-verified.

## What it does

`map_manager` provides `/maps` for player map submissions and status tracking, a reviewer interface for testing/approving/declining/implementing maps, and operator tools for exporting or converting legacy map files. `map_load` owns actual deployment and client rendering.

## Human workflows and persistence

- A player submits XML-derived map metadata/objects; normal contributors are intended to have a pending exterior-request limit.
- Uploaders may edit/delete only their own eligible pending/disabled requests.
- Reviewers test, accept/decline with a note, and implement/disable maps.
- Operators can export interior/exterior maps or convert legacy XML files.
- `maps` stores request/lifecycle metadata; `maps_objects` stores object/removal descriptors. Both are MyISAM without parent-child foreign keys.
- Client validates XML size/children and world consistency before sending an object table; server stores the request and calls `map_load` for deployment.

## Source-confirmed findings

- Current server code binds remote actors to `client`, scopes personal lists and edits, checks IDs/metadata lengths, re-fetches records before review/deploy, and uses conditional state changes. These are fixed-in-source safeguards, not runtime proof.
- Initial submission only verifies logged-in account and table type. Size/count/world/field/model/coordinate and object validation remain client-only; a direct event can bypass them.
- Pending quota uses check-then-insert and can race. Parent/child persistence is separate; insert/delete failures can yield partial requests or orphan children.
- Deployment updates enabled/reviewer/audit notes before calling `map_load`; failure only rolls back enabled state. An empty map result may still be truthy and appear deployed.
- Management read access exposes uploader/reviewer identities and internal notes to supporters/trial admins; action policy is based on broad legacy roles rather than named capabilities.
- `processMapContent` ignores its `max_objects` argument; conversion can hit the normal lower cap. Export is not round-trippable: exterior world fields/collision/LOD/removal data are lost, and “Save to file” assumes a directory not created on a fresh client.

## Tracked work and target direction

- [Issue #62](https://github.com/itschase/OwlMTA-2026/issues/62) owns map request/review and deployment flow.
- Issues #1/#3/#6 own general remote authorization, named capabilities, and schema/transaction modernization.

Proposed direction: revalidate a normalized allow-listed XML/object schema on the server; safely reserve quotas; stage and verify complete parent/child datasets before publishing; use durable immutable review/deployment records; and report activation only after loader success. Split queue, test, approve, deploy, export, and legacy import grants. Make export/import round-trip.

## Runtime verification matrix

All runtime behavior remains unverified. Test oversized/malformed/mixed-world submissions, concurrent quota use, object insert/delete failure, uploader boundaries, reviewer/self-review roles, stale concurrent decisions, empty or failed activation, export/import round-trip, file-save path, and schema/provider readiness.
