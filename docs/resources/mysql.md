# `mysql`

## Status and evidence

- Resource path: `mods/deathmatch/resources/mysql`.
- Source review: manifest, connection bootstrap, exported legacy query helpers, lazy query writer, migration helper, and daily maintenance script reviewed as an initial API/security pass. Complete call-site and SQL/schema audit is still required.
- Runtime: unverified. No database connection or MTA server was started.
- Startup snapshot: enabled in `mtaserver.conf.bak`; this is not proof of live configuration.
- GitHub record: [Script Resources Discussion #123](https://github.com/itschase/OwlMTA-2026/discussions/123); findings tracked by [Issues #460](https://github.com/itschase/OwlMTA-2026/issues/460)–[#463](https://github.com/itschase/OwlMTA-2026/issues/463), all assigned to [Milestone #7: Resource Audit and Security Baseline](https://github.com/itschase/OwlMTA-2026/milestone/7).

## Purpose in everyday terms

`mysql` is the shared server-side database boundary used by gameplay resources. It reads connection settings from the resource configuration, opens MTA and legacy-module database connections, exports query helpers, provides a migration helper, and includes a daily maintenance timer.

This is a critical dependency: failures here affect account, character, economy, inventory, and world persistence. The current resource exposes both a newer MTA `dbConnect` path and a legacy MySQL module API; callers may use either. Do not migrate or remove either path without a repository-wide caller inventory and representative SQL/data review.

## Manifest and exported API

`meta.xml` loads `mysql.lua`, `lazyquery.lua`, `migrations.lua`, and `mysql_external_module.lua` server-side. It exports `getConn`, `getSmallestID`, `lazyQuery`, legacy query/result helpers, and generic `select`, `insert`, `update`, and `delete` helpers. The legacy module maintains query/result pools and offers `escape_string`; most consumers build SQL strings directly and call these exports.

Five legacy getters exposed the configured database username, password, database name, host, and port. A full repository source search found no caller, so their definitions and exports were removed in commit `TODO`. Any external server resources must be checked for compatibility before deployment. Runtime behavior remains unverified; Issue #460 tracks that compatibility check and confirmation that secret values are no longer exported.

The manifest also declares four forum query exports that have no matching function definitions or forum connection setup in the current resource. The RP help/news path still calls `forum_query_fetch_assoc`. Three other legacy getters return `db`, `host`, and `externalprefix`, while the current connection bootstrap populates `database`, `hostname`, and other differently named settings. Issue #462 tracks deciding whether to restore this legacy integration or retire it with every caller handled.

The generic CRUD helpers quote values through `escape_string`, but table and column identifiers are concatenated into SQL. They should only receive code-owned identifiers; user-controlled identifiers would need strict allowlisting. This dossier is not a complete SQL-injection audit of all call sites.

Legacy query results are exposed as numeric indices into `resultPool` and paired `queryPool`. `free_result` currently removes entries with `table.remove`, which shifts later slots even when a caller still holds the old result ID. Interleaved result lifetimes can therefore address the wrong slot; Issue #463 tracks stable, non-shifting handle storage and a focused reproduction.

## Migration and logging behavior

- `migrations.lua` creates a `migrations` table and applies each resource's ordered migration entry when its index is not present. The helper does not yet provide a documented transaction/rollback or concurrent-run strategy; inspect callers and DB engine/schema before relying on atomicity.
- `lazyquery.lua` appends free-form messages to `/maxime.log`. This is a single local file rather than structured, categorized logs, and needs retention/size/error policy before production use.
- The database wrappers log errors and may keep query strings for diagnostics. Before enabling SQL logging, assess whether statements can contain passwords, personal data, tokens, or other secrets.

## Daily maintenance script: urgent operator boundary

`s_server_global_maintenance.lua` starts a one-minute timer. At a fixed local server hour it broadcasts warnings, later kicks every player, and modifies the server password. On resource startup it also clears an existing password. The source contains a committed literal password; it is not repeated in this public dossier. Treat it as exposed. Issue #461 tracks removing the static credential and password mutation, making maintenance explicitly operator-configured, and validating its safe lifecycle.

The maintenance code is loaded in this database resource, so database startup also changes access control. Separate backup orchestration and server admission policy from the query layer during redesign.

## Discord/API and operator design

Database credentials must remain server-side and must never be returned by an API, Discord bot, client event, or debug log. A future standalone API may request narrow operations using server-derived identity and capability grants, but it should not receive the raw database password or turn this resource into a general SQL proxy. Discord roles can gate named staff actions at the host authorization boundary; local business rules, character ownership, and row-level validation remain in each gameplay resource.

## Follow-up

1. Remove password getters and rotate the committed literal wherever it could have been deployed; resolve #460–#461.
2. Restore or retire the declared forum exports and their remaining callers; resolve #462.
3. Enumerate every exported function caller and classify the newer `db*` API versus legacy module path; resolve result-handle stability in #463.
4. Review `meta.xml` export HTTP flags and current MTA defaults against the target release; do not infer HTTP exposure from omitted attributes.
5. Inspect migration callers, migration indices, transactions, table engines, and startup ordering before changing schema behavior.
6. Review SQL debug/error output for sensitive values and define rotation/retention settings for query logs.
7. Build an isolated database fixture and run connection-loss, migration replay, query failure, and maintenance timer checks only after safe-start preparation.

No database or runtime behavior is claimed as verified.
