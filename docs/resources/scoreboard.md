# `scoreboard` resource

**Review state:** Full active manifest and client/server display-source review. Player data visibility and rendering behavior remain runtime-unverified.

## Player use

Holding Tab opens a custom scoreboard showing connected player IDs, names, play hours, and ping. The view is rendered client-side and uses cached player elements, with paging and scroll controls for larger player counts. The server creates a small `scoreboard` element containing the server name and an `allow` flag; it removes that element on resource stop. The manifest exports client-side `isVisible` for other UI to query scoreboard visibility.

## Staff and supporter display rules

When the local viewer is staff on duty, the row renderer may include account usernames. Players with the relevant donor perk are hidden from viewers who are not staff on duty. The scoreboard also colors rows for some login, nametag-perk, and admin-level states. These are presentation rules, not permission grants: a supporter perk does not make a player staff, and a displayed admin level does not authorize an action in another resource.

## Connections and operations

The client consumes `global` for formatted player names and staff-on-duty status, `donators` for the hide-from-scoreboard perk, and shared player element data for session ID, hours, login state, username, and display flags. `id-system` owns temporary session IDs; it is not a durable account or Discord identity. The server obtains the server version string from `global`.

The manifest loads one client and one server script and declares no database table or remote gameplay mutation. It does not declare explicit dependencies; operators should ensure `global`, `donators`, and the ID/data providers are available when the scoreboard renders.

## Future interface direction

Keep the lightweight at-a-glance scoreboard as a player utility. If a future staff dashboard adds search or moderation actions, those actions must route through their owning server-side resources rather than turning the scoreboard into an authorization surface. Any change to username visibility or donor concealment should be an explicit privacy-policy decision and tested with ordinary players and on-duty staff.

## Runtime verification

On a disposable server, verify key binding, paging, player join/quit cache updates, UI coexistence, local visibility export, logged-in/out rendering, donor concealment, on-duty username visibility, and missing dependency behavior. No MTA server or tests were run during this review.
