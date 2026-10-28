# `guied` resource

**Review state:** Active manifest, documented player/developer workflows, startup inventory, remote server-event surface, and declared ACL requests reviewed. The editor contains many client modules; individual GUI creation, code-generation, and parser paths still need a deeper function-level audit. No MTA runtime test was run.

**GitHub record:** [Script Resource Discussion #543](https://github.com/itschase/OwlMTA-2026/discussions/543); [Issue #450](https://github.com/itschase/OwlMTA-2026/issues/450) tracks the remote output-file allowlist.

## Purpose and use

`guied` is a developer tool for assembling and adjusting MTA GUI elements in-game, then generating Lua code to copy into a resource or save under the editor's output directory. The in-game help documents `/guied` and Shift+G for toggling it. The editor supports menus, property editing, move/resize, snapping, undo/redo, tutorials, image/font selection, code loading/output, local generated-file browsing, and consent-based sharing with another connected player. It is not a player-facing roleplay interface framework and does not provide a general server management dashboard.

The manifest loads a client-heavy editor with one server support script and many shipped fonts/images/help assets. It declares no resource dependencies or gameplay exports. The checked-in startup inventory marks it not startup-listed. The server helper scans resource manifests for font and image assets, subject to an ACL permission check.

## Server capabilities and ACL

The resource requests `general.ModifyOtherObjects` and `function.callRemote`. The first is used to enumerate other resources' declared image/font files and also enables cross-resource file access under MTA's ACL model. This is a powerful capability for an optional development tool and should not be granted to a broad player-facing identity. The update checker uses `callRemote` to contact the MTA Community endpoint when the client setting is enabled; that setting defaults to enabled when no local preference overrides it.

Remote events use `source == client` checks for several transfer operations, which binds their event source to the sending player. That check does not constrain which file the requesting player may read. `guieditor:server_getOutputFile` passes client-supplied `filename` to `getFileContents`, which directly attempts `fileExists` and `fileOpen`, then returns file contents to the client. It does not first verify the requested path against the saved-output list. See [Issue #450](https://github.com/itschase/OwlMTA-2026/issues/450). The impact depends on the effective ACL grants and MTA's file-protection configuration; confirm the exact access in an isolated server before making broader claims.

Other server events collect generated code in chunks, write files to the resource, list saved outputs, and share a sender's generated GUI with a selected recipient. The request code includes a five-second chunk-assembly timeout but does not visibly cap chunk count, payload size, or total in-memory transfer size. Treat these as follow-up hardening questions for the deeper event audit, not as runtime-confirmed denial-of-service behavior.

## Operator guidance and future direction

Keep this resource stopped or restricted to a development environment unless an operator needs it. Review effective ACL grants rather than assuming the manifest's request is harmless. The project should decide whether to retain this upstream tool, isolate it in a developer-only package, or build a smaller UI authoring workflow aligned with the future in-game UI framework. If retained, restrict remote file reads to generated output files, bound chunk transfers, make external update checks explicitly configurable, and log any server-side file writes.

Discord role authorization is not a substitute for the MTA ACL requirement and should not turn general players into GUI Editor operators. If the tool is ever exposed through a dashboard, access must be limited to a named development capability at the server action boundary, while file/ACL controls remain server-owned.

## Runtime verification

No MTA server was started and no runtime behavior was exercised. Before enabling in a disposable environment, confirm the effective ACL grants for both requested rights; test font/image discovery; verify allowed and denied cross-resource file reads; check generated output path confinement, listing, sharing, chunk limits, cleanup on disconnect/restart, and update-check behavior with the network disabled. The resource remains outside the startup snapshot.
