# `cargo`

## Status

- Active resource manifest loads a compiled client artifact (`c_forklift.luac`), `s_forklift.lua`, `c_cargo.lua`, and `s_ship.lua`.
- `c_forklift.lua` exists as readable source but is not loaded; source/artifact parity is unknown, so its UI behavior is intended-source evidence only.
- Full server workflow, manifest, item-system callers, persistence, and startup review completed from source.
- No MTA server/database was started; behavior is runtime-unverified.
- [Discussion #304](https://github.com/itschase/OwlMTA-2026/discussions/304).

## Player and staff workflows

### Forklift cargo

The intended client flow lets a driver of model 530 select items from a supported vehicle or item-world shelf, load them onto the forklift, then unload them at another supported destination. The server calls `item-system:moveItem` to durably change the item's owner. A visual box and `cargo.forklift.carrying` are runtime projections. There is no source-side job, faction, license, ownership, key, or staff prerequisite.

The server remote handlers accept event `source` as carrier plus caller-selected inventory, slot, and destination. They do not establish authenticated `client`, current seat/control, live forklift model, proximity/world, ownership/lock policy, item type, or interaction state. Unload hardcodes carrier slot 1 although `moveItem` appends the item. This can move arbitrary items and select the wrong row.

### Shipping and ship operator

`/shipping` opens a client UI after checking hard-coded leader faction IDs 74/104 client-side. The interface has a “New Order” button with no handler; order loading is commented out. A ped attempts local event `cargo:shippingOrderGUI`, for which no active server/client registration was found. There is no order/payment/fulfillment persistence or server workflow.

A server-recognized scripter can run `/sailship 1|2`. The resource creates a ship at a fixed LS terminal and runs hard-coded movement timers/routes. There is no route-progress persistence or operator status/recovery command.

## Persistence and dependencies

The item-system `items` record is the durable owner/type for cargo; `cargo` keeps its carrier map, slot mapping, visual box, ship position/route, and timers only in memory. Resource stop only attempts cleanup of element data; it does not reconcile durably forklift-owned items. Restart can strand items on a vehicle element, lose the carrier-to-item map, and make a later slot-1 unload act on the wrong item. Provider dependencies are implicit: item-system, factions, integration, item-world, computers-system assets, and possibly the compiled forklift UI.

## Source-confirmed findings and issues

1. **Arbitrary transfer remotes:** `cargo:loadForklift` and `cargo:unloadForklift` accept untrusted event source and caller-selected item/destination, then call durable `moveItem`. Tracked in [Issue #292](https://github.com/itschase/OwlMTA-2026/issues/292), linked to existing [#1](https://github.com/itschase/OwlMTA-2026/issues/1) and [#213](https://github.com/itschase/OwlMTA-2026/issues/213).
2. **Restart recovery and stable item identity:** volatile cargo mapping conflicts with durable item owner; record recovery as an explicit cargo case under existing [Issue #214](https://github.com/itschase/OwlMTA-2026/issues/214), rather than creating a competing transaction umbrella.
3. **Shipping is incomplete:** no server order handler/persistence; UI is inert and the ped event is missing. Tracked in [Issue #294](https://github.com/itschase/OwlMTA-2026/issues/294).
4. **Opaque client artifact:** manifest loads `.luac`, not the readable source; parity/build process is not reproducible from the repository. Tracked in [Issue #295](https://github.com/itschase/OwlMTA-2026/issues/295).
5. **Intended-source-only lifecycle defects:** readable `c_forklift.lua` uses suspicious vehicle-exit event casing, leaves Space action bound, does not clear destroyed shape handles, and does not discover newly spawned targets until re-entry. Verify compiled parity before asserting these affect the shipped code.

Existing [#208 export contracts](https://github.com/itschase/OwlMTA-2026/issues/208), [#254 trucker freight sessions](https://github.com/itschase/OwlMTA-2026/issues/254), and [#67 admin generic cargo creation](https://github.com/itschase/OwlMTA-2026/issues/67) are adjacent, not duplicate owners.

## Modernization direction

Create a server-owned transfer session keyed by authenticated player, live forklift, exact item ID/revision, source, destination, and world context; make it short-lived and one-use. Treat visual box and client UI as projections. Persist carried-state identity or quarantine/reconcile existing forklift-owned items on all stop/restart/destruction paths. Replace hard-coded shipping faction policy with explicit operator configuration and one durable order service shared by command and ped entry points. Make the loaded client source reproducible or remove the opaque binary in favor of reviewed source.

## Runtime verification still required

Exercise forged source/client/target/slot, wrong driver, wrong forklift, locked/remote/wrong-world container, item ID substitution, duplicate transfer, full inventory, resource stop/restart, vehicle destruction, item-system restart, every order entry point, ship timer interruption, and manifest client artifact parity after safe-start preparation. None was run.
