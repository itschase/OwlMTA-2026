# `item-texture` resource

**Review state:** Partial active manifest, item/artifact/world-item/vehicle persistence and caller review, plus remote stream and vehicle mutation boundary review. The client shader lifecycle and every model/texture lookup path still need a complete file-by-file pass; runtime remains unverified.

## What it does

`item-texture` applies downloaded image textures to item-world objects, artifact elements, and vehicles. The client creates shaders and replaces a named GTA texture on a target element. For cache misses, the server downloads and caches the image and streams bytes to requesting clients. The resource also provides vehicle texture management UI and server exports `addTexture`, `removeTexture`, and `validateFileFromURL` for integration with other resources.

At resource start, the server rebuilds texture registrations from `artifacts`, `item-system`, `item-world`, and the vehicle pool. Vehicle texture definitions are persisted in the `vehicles.textures` field by `vehicle_load` and later restored through the exported `addTexture` call. The manifest marks the shared/client texture scripts protected and declares MTA 1.5.4 r11413 as the minimum version. It does not declare its cross-resource dependencies; the server also calls `pool`, `mysql`, `integration`, and `anticheat` exports.

There are no player chat commands in this resource. The vehicle editor UI is opened by a client event; an in-repository dispatcher was not found in the caller search. Vehicle changes are intended for trial admins or scripters. Ordinary texture application to supported world items/artifacts is driven by server-owned item metadata and caller resources.

## External images and persistence

The shared URL helper recognizes `imgur.com` and `icweb.org`. Server validation calls the respective external image APIs, checks reported dimensions/size, then downloads the image. The Imgur client ID and ICWeb API key are read from server resource settings; ICWeb has a hard-coded fallback string in the source. Remote image bytes are stored under `cache/<md5(url)>.tex`. The implementation should be treated as an optional external media integration, not as a boot or account dependency. Operators need clear settings, network/offline behavior, cache limits, and a policy for long-term availability of remote image URLs.

## Source-confirmed issues

- [Issue #453](https://github.com/itschase/OwlMTA-2026/issues/453): vehicle texture add/remove handlers use client-supplied event `source` as the staff identity. MTA's [Script security guidance](https://wiki.multitheftauto.com/wiki/Script_security) states that client parameters, including `source`, can be faked and that `client` is trusted. The same functions use a type check written as `if not getElementType(theVehicle) == "vehicle"`, which does not express the intended test.
- [Issue #454](https://github.com/itschase/OwlMTA-2026/issues/454): a remote texture-mutation event can bypass the UI's validation sequence and persist a URL that later reaches server-side `fetchRemote`.
- [Issue #455](https://github.com/itschase/OwlMTA-2026/issues/455): the public `item-texture:stream` event accepts a client URL and triggers server-side `fetchRemote` on a cache miss without matching it to a server-registered texture tuple. The official [MTA `fetchRemote` API](https://wiki.multitheftauto.com/wiki/FetchRemote) is an asynchronous server outbound request function; no runtime request was made here.

These findings are static. The effective outbound-network policy and the exact reachability/impact of each request need isolated runtime review. Source registration and authorization should use server-known element/texture records, authenticated callers, strict host/content validation, request and cache limits, and explicit failure cleanup.

## Player, staff, and operator considerations

Texture replacement can make an item, artifact, or vehicle visually distinctive; it does not itself grant ownership, inventory access, vehicle control, or a gameplay permission. Staff texture management belongs behind a named development/staff capability after server-side caller binding. Discord role IDs should remain configurable in the external authorization integration and must never replace element ownership, item entitlement, or texture registration checks.

For future contextual controls, vehicle texture management could move into a vehicle inspection panel available only to authorized staff; regular players should see only the rendered result. A broader asset pipeline could provide a self-hosted media adapter, with optional providers such as Imgur or Fivemanage behind one server-owned interface, validated content, quotas, cache expiry, and durable reference ownership. The default gamemode must still start and run if every external media provider is disabled.

## Runtime verification

No MTA server was started and no tests were run. Before enabling texture uploads, use a disposable server to verify caller permission checks, event source spoof resistance, non-vehicle targets, validation bypass, URL redirects/host resolution, server outbound request policy, maximum size/dimensions, disk-cache quotas, pending request cleanup, client shader lifecycle, artifact/item/vehicle reloads, and behavior with external network access disabled. Confirm the actual startup ordering of the undeclared resource dependencies.
