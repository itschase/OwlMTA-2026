# Server operator guide

Source-based operational notes for a clean import. This is not yet a validated deployment procedure. No game server was started as part of the current audit.

## Operating model

- The core roleplay gamemode should run and be managed in-game without an Owl website or UCP.
- Discord authorization is the planned production identity source for registration and login. The MTA process may start before the authorization API is configured, but production users cannot register or log in without successful verification. Use an explicit, audited operator bootstrap/recovery flow during setup and outages.
- A future website is optional and must not be required for server startup, character management, routine staff work, or gameplay operations. Discord OAuth may use a browser authorization page served by the API; this is not a UCP.
- MTA ACL remains the engine-level boundary. Game roles are application policy and should not be written into broad MTA ACL groups.

## Current packaging and configuration

The Docker build copies the MTA server and resource tree; `docker-entrypoint.sh` generates config XML from `.bak` templates using environment substitutions. The server archive download is unpinned. Entrypoint values are not comprehensively validated/escaped. README currently omits `WEBSITE_PASSWORD` although a template consumes it; the target clean install should remove this legacy website account requirement rather than introduce a credential.

The server startup list is manually maintained and contains duplicate resource entries (`event-system`, `selfck-system`) in the reviewed template. Startup ordering is a list, not a verified dependency graph. Eight active manifests were absent from the startup list in the previously counted snapshot. Reconcile rather than blindly starting every resource: archived, development, optional, and incomplete resources need explicit policy.

## Database bootstrap and migration

- **Configuration files:** the tracked files are `mods/deathmatch/settings.xml.bak` and `mods/deathmatch/mtaserver.conf.bak`, not active local server configuration. The settings backup contains placeholders such as `MTA_DATABASE_PASSWORD` and `CORE_DATABASE_PASSWORD`; supply real values through the local deployment config or environment used to generate `settings.xml`, and do not commit credentials. The backup's socket setting is a Unix socket path, so configure it for the target OS. Inspect the actual generated settings and server configuration before starting a deployment.
- **Connection names:** `mysql.lua` reads `@mysql.hostname`, `@mysql.username`, `@mysql.password`, `@mysql.database`, and `@mysql.port` for the main `mta` connection, plus corresponding `@mysql.core_*` settings for `core`. The `mta` connection opens on resource start; `core` is opened lazily by `getConn("core")`. Use database names `mta` and `core` unless the SQL dumps are changed with them. Required values have no safe defaults or preflight validation; missing values may fail while the connection string is assembled.
- **Two MySQL APIs:** server resources use native MTA `dbQuery`/`dbExec` through `exports.mysql:getConn("mta")` or `exports.mysql:getConn("core")`. The resource also opens a legacy `mysql_connect` connection and exports older query helpers. The tracked `mtaserver.conf.bak` loads `mta_mysql.dll` and comments on `mta_mysql.so` for Linux. Confirm the matching module and native library dependencies for the host OS and architecture; native `dbConnect` alone does not replace the legacy API used by existing resources.
- **Schema inputs:** `mods/deathmatch/data/core.sql`, `mta.sql`, and `data.sql` are SQL dump files, not three database schemas. In this checkout, `core.sql` creates/uses `core`, `mta.sql` creates/uses `mta`, and `data.sql` creates those same two databases and seeds `mta.settings`. A separate `data` schema is not defined in these files.
- **Empty local database import order:** import `core.sql`, then `mta.sql`, then `data.sql`. The first two establish the schemas and tables; the last supplies settings rows. `core.sql` declares a UTF-8 database default, while `data.sql` also creates `core` with a Latin-1 default. Importing `data.sql` first can therefore leave the database default as Latin-1 because the later `CREATE DATABASE IF NOT EXISTS` does not revise it. Treat this as a source-based order for an empty development database, not as a verified production upgrade procedure. `mta.sql` contains a `CREATE TABLE faction_ranks` statement without `IF NOT EXISTS`, so the dump is not wholly safe to re-import.
- **Runtime migrations:** the MySQL resource creates `mta.migrations` after the `mta` connection succeeds. `vehicle_manager`, `interior_system`, `npc`, and `mdc` call `createMigrations` during their resource startup. The runner applies each resource's migration array through the `mta` connection; no separate Core migration runner or global migration dependency order was found. It compares array positions with the number of recorded rows, so do not treat it as a general schema-version or reconciliation tool.
- **Startup order:** the tracked server-config backup starts `mysql` before `data`, `pool`, `global`, and `cache`. The mysql resource metadata does not declare dependency includes, so retain a compatible resource startup order and check provider resources before starting consumers.
- **Legacy integrations:** the mysql metadata advertises forum query exports, and repository resources call them, but no matching `forum_*` implementations or forum connection setup were found in the mysql Lua sources. The legacy `getMySQLDBName`, `getMySQLHost`, and `getForumsPrefix` getters also return globals not populated by the current connection settings. Confirm or repair these paths before enabling forum-dependent features.
- Tables use mixed storage engines and cross-database writes exist. Registration can partially provision an account across `core` and `mta`; do not assume one transaction spans both. The source-based schema inventory, migration redesign, preflight, conversion, and transaction-boundary work is tracked in [issue #6](https://github.com/itschase/OwlMTA-2026/issues/6).
- Back up both databases and define a restore-tested procedure before production use. The tracked MTA server config disables built-in backups, and no replacement backup job is defined in this repo.
- MTA config disables built-in backups (`backup_interval=0`, `backup_copies=0`). No replacement backup job is defined in this repo. Require an operator-selected backup plan before production.

## Logging and diagnostics

- MTA server/auth/DB/script log locations and levels are set in `mtaserver.conf.bak`. Script debug log level is zero in the reviewed config, which may hide useful diagnostics.
- The `logs` resource writes gameplay audit files below `resources/logs/logs`; README suggests Filebeat/Elasticsearch.
- `mysql/lazyquery.lua` writes to `/maxime.log`, a separate log path that must be included in retention and volume planning.
- Startup diagnostics should report resource state, missing exports, DB connectivity, schema version, loaded configs, and Discord adapter state without leaking secrets.
- Use structured levels and correlation IDs; avoid logging credentials, OAuth tokens, full personal identifiers, or raw request headers.

### Optional Grafana log search

The repository should not require Grafana or transmit logs to a hosted service by default. Operators may enable an observability stack independently. A practical Grafana path is file logs → Grafana Alloy collector → Loki → Grafana Explore/dashboards. Alloy can tail log files and forward to Loki; Loki stores compressed log chunks and indexes stream labels rather than the full log body. Keep labels low-cardinality (environment, resource, severity, server instance); put request/correlation IDs and player/account references in structured log fields instead of labels. See [Grafana Loki overview](https://grafana.com/docs/loki/latest/get-started/overview/) and [Alloy log collection](https://grafana.com/docs/grafana-cloud/send-data/logs/collect-logs-with-alloy/).

Collect only logs the operator is entitled to retain. Scrub secrets, auth tokens, passwords, session codes, raw IPs, serials, and sensitive player data before forwarding; define retention and access controls. Include MTA server/auth/script/DB logs, gameplay `logs` resource output, MySQL lazy-query log path, and collector/service health in the source inventory. The existing repository does not yet provide a verified Alloy/Loki config or structured logging guarantee, so this is an optional deployment enhancement, not current support.

## External services

Inventory all integrations before enabling them: activation email, legacy forum API, Owl URLs, image providers, MTA external HTTP endpoints, and future Discord service. For each, specify endpoint, data sent, secret location, timeout/retry behavior, rate limits, offline fallback, and whether core gameplay blocks. Keep disabled integrations absent by default.

## MTA and Discord connectivity

MTA's server-side `fetchRemote` supports outbound HTTP(S) request options and invokes a callback asynchronously. Therefore resource code must not block a join/login handler waiting for Discord. Use a short-lived challenge and one-use ticket for registration/login; perform Discord exchange and role resolution asynchronously. New logins fail closed without a verified result. Track session leases and a revocation feed/status check so an authorization revoke ends the linked session within a documented bound. Store Discord bot credentials only on the trusted service or protected server configuration, never in client files or source.

Current source provides an optional linked-account adapter boundary, post-local-gate session activation, a server-only capability facade, confirmed-revocation disconnect, and lifecycle clearing. It does not provide a validated deployment: no real Discord application, HTTPS service, MTA runtime, database, outage, lease-expiry, reconnect, or recovery test has been run. Legacy password and forum paths remain, so operators must not advertise this checkout as Discord-primary or enable production access based only on source presence.

The preferred topology is:

```text
MTA client -> in-game login challenge -> trusted identity/authorization service
Discord account -> browser OAuth -> trusted service -> linked/provisioned account
MTA server <- one-use login ticket, grants, revocation state over HTTPS <- service
```

Do not call Discord's privileged APIs directly from clients. A narrow adapter avoids leaking bot tokens and decouples core gamemode uptime from Discord API changes. The service must bind game-account ID to immutable Discord user ID, validate guild membership, resolve configured role IDs, return a bounded grant result, and support active-session revocation/audit. Blank role IDs grant no staff/donor capabilities. The exact MTA 1.6 compatibility and network/ACL request settings must be confirmed in a disposable deployment.

## Minimum pre-production checklist

- Pin an MTA release artifact and document an update procedure.
- Validate required environment variables and XML escaping before starting MTA.
- Remove legacy website account, website ACL, and HTTP-callable exports from the default configuration.
- Reconcile every startup resource with manifest/dependency/export data; detect duplicates and missing providers.
- Provision separate least-privilege DB users and verify both schemas/migration state.
- Configure and restore-test backups; set log retention/rotation.
- Use a disposable database and test clean install, upgrade, rollback, resource start/stop, account/character, staff actions, and external service offline cases.
- Keep Discord unconfigured mode usable; role-gated actions must deny safely without breaking ordinary account play.
- Publish example configuration with blank IDs/placeholders and no real credentials.
