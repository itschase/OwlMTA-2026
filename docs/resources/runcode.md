# `runcode` resource

**Review state:** Manifest, command/UI path, server remotes, exports, and ACL resource identity reviewed. Runtime behavior remains unverified.

## Purpose and operator workflow

This developer utility opens a GUI with `/runcode` for players recognized by `integration:isPlayerLeadScripter`. The operator can execute Lua on the client or server and view return/error text. Client execution runs locally; server execution sends the code text to the server. Both sides call `loadstring` and `pcall`. The server logs submitted code through debug output and the server log. The resource exports `runString` on both sides for resource callers.

## Security boundary

The command checks Lead Scripter status only when opening the panel. The server event `GUIRuncode:runServerCode` is remotely triggerable and executes its supplied code without validating `client`, actor identity, or Lead Scripter permission. A client can therefore bypass the GUI and request arbitrary server-side Lua execution. This source-confirmed critical boundary defect is tracked in [Issue #443](https://github.com/itschase/OwlMTA-2026/issues/443). The separate `GUIRuncode:outputLogs` remote accepts caller-supplied player, code, and execution-side fields and writes them to logs without validation, so audit attribution is also forgeable.

The manifest exports `runString` to other resources. These are resource-to-resource code-execution capabilities; review every future caller and MTA ACL grant before enabling. `acl.xml` contains a `resource.runcode` ACL object, but this source review did not establish an effective grant path for the live server configuration.

## Dependencies and operations

The only declared scripts are client and server Lua; the server command calls Owl's `integration:isPlayerLeadScripter`. No explicit dependency is declared. The file contains an `ACL = 'Admin'` variable that is unused; it must not be mistaken for an enforced ACL check. Operators should treat the resource as privileged developer tooling, keep it disabled or unavailable to ordinary gameplay identities, and audit any exports or ACL changes before startup.

## Future direction and verification

Do not expose arbitrary Lua execution as a Discord capability or general staff dashboard action. If retained for development, separate server/client execution, bind remote callers with MTA's server-side `client`, recheck the existing Lead Scripter policy at execution, validate and audit attribution, and keep resource export callers explicitly trusted. On a disposable server verify unauthorized direct remote invocation, authorized execution, client/server separation, log attribution, ACL grants, and resource restart behavior. No MTA server or tests were run.
