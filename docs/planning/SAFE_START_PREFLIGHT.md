# Static safe-start preflight

## Status and boundary

This is a source-only preflight for a future disposable OwlMTA-2026 bring-up. Docker, MTA, and the databases have not been executed. The current repository is **not safe to start against live data or a public network**. A constrained disposable run becomes appropriate only after the static gates below are satisfied.

## Confirmed inherited flow

The Docker image uses a mutable Debian base, installs native dependencies, downloads the unpinned latest Linux MTA x64 archive, copies the deathmatch tree, installs bundled native libraries, switches to an unprivileged `mtasa` user, and launches `docker-entrypoint.sh`.

The entrypoint performs sequential text substitution from `mtaserver.conf.bak` and `settings.xml.bak`, changes module filenames for Linux, moves modules into the runtime directory, and starts `mta-server64`. It does not first validate required variables, XML, database reachability/schema, native module ABI, resource dependencies, file permissions, or secrets.

The tracked MTA config starts `mysql`, then shared providers and roughly 136 unique gameplay resources. The list is hand-maintained, contains duplicate starts, and omits some active-tree manifests. Startup order is the only dependency contract for many exports.

## Configuration and prerequisites

- Linux x64 container/runtime and outbound HTTPS during image build.
- A pinned compatible MTA server artifact and native `mta_mysql`/bcrypt modules.
- Writable runtime configuration, log, cache, and data locations.
- Reachable MySQL/MariaDB with separate Core and MTA schemas.
- Environment values for server/broadcast/owner settings, Core and MTA database connections, production mode, and legacy optional services.
- Explicit protocol validation for game, HTTP, and ASE ports. Docker `EXPOSE` does not publish them, and the historical README mappings are not sufficient evidence of correct MTA protocol exposure.

## Static blockers

1. **Unpinned supply chain.** The Debian base and MTA “latest” archive lack fixed versions and artifact hashes. Issue #71 owns target MTA compatibility; Issues #6/#121 own reproducible database/bootstrap behavior.
2. **Unsafe configuration rendering.** Empty or special-character values can silently corrupt generated XML or substitution. Required/optional variables, safe XML rendering, schema validation, secret-file support, redacted diagnostics, and fail-before-MTA behavior are required.
3. **Secret and database privilege scope.** Generated configuration contains credentials readable by the game process. Use secret mounts, restrictive permissions, separate least-privilege runtime identities for both schemas, and a separate migration/bootstrap identity where practical.
4. **Public HTTP/legacy surfaces.** Built-in HTTP is enabled while legacy UCP/website/forum/HTTP-callable exports and ACLs remain under review. Disable or private-bind by default; publish only explicitly required protocols.
5. **Destructive first-start work.** Inactivity scanners and deletion/eviction jobs are enabled in inherited settings. Disable them until backup, data provenance, clock behavior, and synthetic test records are validated.
6. **No dependency readiness gate.** Provider failure can coexist with consumers starting and later assuming exports or tables exist. A static preflight and provider-ready report must fail closed.
7. **Native module/library drift.** Module movement and system-library copying have no version/ABI manifest or integrity verification.
8. **Privileged developer code execution.** The `[dev]/runcode` manifest is not in the tracked startup snapshot. The working-tree source now checks the server-side `client` and Lead Scripter permission for execution/log events, bounds payload size, removes unused `runString` exports, and omits submitted code from audit logs. This has not been committed or runtime-verified. Keep the resource disabled and verify the deployed startup/ACL state and the authorization matrix before any shared test; track the remaining work in [Issue #443](https://github.com/itschase/OwlMTA-2026/issues/443).

## Database bootstrap boundary

For a new disposable database, the source-indicated import order is:

1. `core.sql`
2. `mta.sql`
3. `data.sql` (seed/settings data, not a third schema)

This is not an upgrade procedure. The dumps mix engines and character sets, disable foreign-key checks, and are not uniformly re-importable. Never import them over production. Use throwaway databases and verify a restore of both schemas before any server process starts.

Runtime migrations create `mta.migrations` and accept positional migration arrays from selected resources. The runner compares array position with row count, executes DDL separately from the marker insert, and has no checksum, global dependency order, lock, Core-schema runner, or reliable failure reconciliation. Resolve this under Issues #6/#121 before treating restart as safe.

## Proposed disposable environment

- Pin the base image digest, MTA version/archive hash, native modules, and required library versions.
- Use an isolated container network and disposable MariaDB/MySQL matching the legacy baseline first.
- Create separate least-privilege Core/MTA runtime users and a bounded bootstrap/migration user.
- Import sanitized data only: no real credentials, emails, IPs, serials, forum data, tokens, or player records.
- Generate configuration into a restrictive temporary/secret-backed path; use a read-only root filesystem where feasible and explicit writable log/cache/config volumes.
- Run non-root with dropped capabilities, `no-new-privileges`, and CPU/memory/PID limits.
- Disable scanners, broadcast, public HTTP/ASE, UCP/forum/media integrations, and other outbound services initially. Deny egress, then allowlist one optional adapter at a time.
- Snapshot both schemas and writable volumes before every migration or smoke-test phase.

## Ordered gate

1. Pin and verify MTA/base/module artifacts, licenses, hashes, and ABI.
2. Build sanitized disposable databases; import Core → MTA → data and verify expected schema/charset/table counts.
3. Inventory and redesign migration ordering/recovery; snapshot before any resource start.
4. Provision least-privilege identities and secrets; safely render and validate XML with scanners/broadcast/HTTP/integrations off.
5. Reconcile the startup list against active manifests, duplicates, providers, archives, and optional/development resources; explicitly verify `[dev]/runcode` remains disabled and cannot be invoked through a resource caller or ACL grant, then exercise its authorization matrix only in the disposable environment.
6. Verify native modules, case-sensitive paths, file ownership, and writable locations.
7. Constrain network/egress and publish only confirmed protocols.
8. Produce a passing static preflight report with both databases reachable and no placeholders or secrets in output.
9. Only then start MTA in the disposable environment and capture resource/module/migration results without real users.
10. Run the smoke/failure matrix and a full restore. Production remains blocked until identity/session, authorization, privacy, and backup/recovery gates close.

## Later smoke and failure matrix

- Reproducible image build, artifact/hash mismatch, offline build cache, and native module load.
- Every missing/empty/malformed/special-character setting; XML validation; permission and redaction checks.
- Clean import, expected repeated-import rejection, charset/collation, least privilege, each schema independently unavailable, migration failure/retry/concurrency/checksum drift, and restore.
- Game/HTTP/ASE bind and protocol behavior, broadcast off/on, no unintended public listener, and HTTP ACL probes.
- Exact resource order, duplicate/missing manifests/exports, provider stop/restart, and consumer fail-closed behavior.
- Connect → ban/device gate → registration/login → character list/create/spawn/change/logout plus one audited owner recovery route.
- Every forum/UCP/media/Owl endpoint disabled, unreachable, slow, or malformed without breaking core startup; future production Discord absence must fail login policy explicitly, never silently enable local password login.
- Scanners disabled first, then exercised only on synthetic aged rows; log/cache persistence, graceful stop, crash recovery, and restored snapshot verification.
