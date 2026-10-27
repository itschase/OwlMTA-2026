# `fonts` resource

**Review state:** Manifest, bundled asset, and direct client-call references reviewed. Client cache/download behavior remains runtime-unverified.

## Purpose and use

`fonts` is a shared client asset resource. Its manifest registers `helveticastrong.ttf` as a downloadable file so other resources can use MTA's cross-resource file path (for example, `guiCreateFont(":fonts/helveticastrong.ttf", size)`) instead of bundling another copy. The manifest contains no Lua scripts, commands, events, exports, database access, or player controls.

The current repository search found direct uses in `computers-system/websites/ippc.lua`, where the custom font styles IPPC website headings and labels. This resource is an asset dependency, not an authority or gameplay resource. Confirm that client font creation occurs after the asset resource is available and handle `guiCreateFont` failure with a fallback font.

## Operations and future considerations

Operators should retain the font file and start/load the resource for client consumers. If the asset changes, check every consumer for readability and font-element cleanup. Future UI work can centralize custom fonts here, but should keep client-visible assets public and avoid assuming they contain secrets. No Discord permission is relevant.

## Runtime verification

On a disposable client, verify resource availability, cross-resource font loading, download/cache behavior, fallback when the font is missing, resolution/scaling, and cleanup of created font elements. No MTA server or tests were run.
