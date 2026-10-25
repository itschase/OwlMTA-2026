# In-game UI framework plan

## Why centralize the UI layer

The gamemode has hundreds of client files creating standard GUI controls, custom DirectX screens, and a smaller number of browser/CEF views. A repository scan found references to `guiCreateWindow` in 180 Lua files, `dxDraw*` in 88, GUI controls such as edit/button/gridlist/memo in 199, and browser creation in six. These are search-reference counts, not counts of unique screens or runtime use. There are shared building blocks already: `rightclick` exports a reusable menu API, `fonts` and `resources` supply assets, and `guied` is a GUI editor/tool. This suggests a compatibility layer can reduce duplication without replacing each screen at once.

## Goal

Create an internal, versioned UI library that supplies shared behavior and presentation primitives for new/reworked screens while existing screens continue to run. It should not require a website, Discord, an external JS framework, or a new client download beyond the resource already distributed by MTA.

## Recommended structure

1. **Core lifecycle and input service**: create/destroy screen scopes, own event handlers/timers/render callbacks, cursor/keyboard focus, modal stack, Escape handling, and cleanup on hide/resource stop/player state changes.
2. **Theme tokens and layout**: colors, spacing, typography, icons, responsive anchors, safe-area margins, resolution scaling, and a small set of semantic states (normal, hover, focus, disabled, error).
3. **Primitives**: panel, label, button, text input, select/list, checkbox/toggle, tab, modal/confirm, toast/notification, tooltip, progress, and loading/error/empty states.
4. **Data adapter boundary**: screens render input and state; server resources own authoritative records, permissions, and mutations. UI components must not encode security checks as authority.
5. **Migration adapters**: wrappers that can host a native GUI window or a DX panel under one lifecycle/API. Do not force all components onto one renderer before measuring cost, usability, and compatibility.

## Renderer choice

- Prefer MTA's native GUI controls for forms where keyboard input, text editing, lists, and predictable input behavior matter.
- Use DirectX drawing for lightweight visual panels/components that need coherent styling. Centralize render handlers, render only while visible, avoid per-frame database/element scans, and reuse textures/fonts/render targets for static content.
- Use local CEF only for an isolated complex rich interface when it materially improves the user flow and is worth browser initialization, memory, focus/input, local asset, and JS/Lua bridge complexity. Do not use remote CEF for account/management surfaces.
- Keep remote HTTP/Discord pages out of the gameplay UI. The game calls its API from server Lua asynchronously; CEF is not the identity trust boundary.

## Interaction and safety standards

- Every screen has one owner/scope and deterministic cleanup; repeated opens must not add duplicate handlers, render loops, cursors, or binds.
- Make keyboard and mouse paths available. Set clear focus order, input validation feedback, disabled/loading states, and consistent confirmation for destructive actions.
- Keep screen-side validation for usability, but always validate permission and submitted values on the server using MTA's trusted `client` identity.
- Match current game input conventions, avoid trapping chat/console/transfer/debug windows, and make Escape/back behavior predictable.
- Localize strings and avoid hard-coded Owl domains. Respect MTA version/CEF feature availability and graceful fallback.
- Track per-open GPU/CPU/memory costs; MTA warns that `onClientRender` runs every frame and can cause severe lag/crashes if used carelessly. CEF browser lifecycle is asynchronous; destroy hidden/unneeded browsers or pause rendering when retained.

## Rollout

1. Inventory representative UI families and their shared helpers: login/character, inventory/phone, factions, vehicles, banking, reports/staff tools.
2. Establish a small compatibility package and style tokens, then prototype one low-risk panel plus a modal, text input, list, and notification.
3. Compare at multiple resolutions and with MTA chat, console, cursor, and low-performance conditions. Do not migrate high-risk staff/financial screens until server authorization work is complete.
4. Add developer guidance, component examples, and resource manifest dependency. Adopt it for new work, then migrate screens opportunistically.
5. Keep old UI screens working during transition; remove duplicate helpers only after call-site inventory and migration.

## MTA references

- [GUI widgets](https://wiki.multitheftauto.com/wiki/GUI_widgets) are client-side standard controls.
- [DX drawing functions](https://wiki.multitheftauto.com/wiki/Client_Scripting_Functions) provide custom DirectX rendering.
- [MTA scripting tips](https://wiki.multitheftauto.com/wiki/Scripting_Tips#Client_Performance) warn that per-frame render callbacks can be expensive and discuss render targets.
- [CEF tutorial](https://wiki.multitheftauto.com/wiki/CEF_Tutorial) documents asynchronous browser creation, local-vs-remote restrictions, Lua/JavaScript bridge, input/order, and browser lifecycle.
- [onClientBrowserCreated](https://wiki.multitheftauto.com/wiki/OnClientBrowserCreated) documents the asynchronous browser initialization event.

This plan is source-based; there is no UI framework implementation or in-game visual validation yet.
