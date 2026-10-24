# Player guide (in-game)

This is a plain-language guide to the intended player experience. It describes current source paths, not a promise that each feature has been runtime-verified. The gamemode is designed to function in-game without a website or UCP.

## Getting started

1. Join the MTA server and use the in-game account screen to register or sign in.
2. Create or choose a character. Account credentials belong to the account; money, inventory, faction, vehicles, licenses, and most roleplay state belong to a character.
3. Complete the tutorial/rules steps that are enabled on the server.
4. Spawn into the world. If a feature says an external website is required, report it: that is a known portability gap, not a desired core requirement.

The current registration source still calls a legacy local activation-mail service. Until replaced, a clean install may be unable to complete registration when that service is absent. See GitHub Issue #13.

## Playing your character

### Chat and communication

The chat system provides local in-character speech, shouting, district chat, private messages, out-of-character chat, faction communication, radios, and staff/game-master channels. The exact commands and access rules vary; faction channels can depend on faction membership or duty. Donor chat, GameMaster chat, and staff channels are distinct concepts even though legacy checks overlap. Do not assume a supporter/donor tier is staff authority.

Phone, SMS, contacts, social friends/status, and advertisements are separate in-game systems. Phones are inventory-connected. A server-side privacy review is open for SMS/contact ownership checks.

### Money, jobs, and shops

Characters earn and spend cash through jobs, payday, shops, businesses, and banking. A job selection updates the active character’s job; payday and job resources then affect recurring income. General shops sell inventory items. Business storefronts also track supply and profit. Banks, ATMs, faction finance, and transfers are handled by banking resources.

Never treat a UI price or event argument as authoritative. The server should resolve price, ownership, proximity, inventory, and permissions itself. Several such checks are being audited; see Issues #16, #47, and #48.

### Items, clothes, and vehicles

Items are the shared inventory layer for cash-adjacent objects, phones, weapons, clothing, keys, and other systems. Clothing can be browsed and purchased; custom-design save/delete authority needs review. Vehicles are shared among ownership, shops, fuel, interiors, registration, insurance, impound, and staff tools. Vehicle data persists separately from the live MTA vehicle element.

### Home and travel

Interiors/properties connect purchase, keys, locks, elevators, furniture/objects, and business notes. The elevator system can select destinations within buildings. Vehicle interiors are separate from property interiors and have their own enter/knock/window interactions.

#### Finding interiors and objects

- To look up official interior IDs and names, use `/listints [From ID] [To ID]` or `/listinteriors [From ID] [To ID]`. The result is printed in chat, and the command copies the full illustrated interior reference link to your clipboard. A listing is a reference; it does not teleport you into an interior or grant access to a property.
- To browse object models, use `/objbrowser` or `/obj`. Select an entry to see its model ID and a rotating preview. Close the browser to remove the preview and return the camera to your character. The browser is for viewing models; it does not place objects into the world or save a map.
- Interior catalog changes and interior administration are staff/operator work. The separate `interior-manager` tool is staff-gated (see [Issue #64](https://github.com/itschase/OwlMTA-2026/issues/64)). Exterior map additions use a separate request and review flow; see [Issue #62](https://github.com/itschase/OwlMTA-2026/issues/62). Property purchase and keypad authorization are handled separately; see [Issue #46](https://github.com/itschase/OwlMTA-2026/issues/46).

These commands and behaviors are confirmed in resource source only; they have not been runtime-verified.

### Factions and public services

Factions group characters into organizations with ranks, membership, permissions, duty, vehicles, equipment, phones, and finance. Public-safety resources add police/MDC, medical treatment, prison, licensing, and airport/aviation workflows. These are roleplay features; join a faction through its in-game process and follow its procedures. Source review found authorization gaps under active investigation; avoid relying on UI gating as a security guarantee.

### Activities and optional content

Activities and event resources include sports and other events. Some source folders are not loaded by the active resource manifest; for example BMX/Easter entries are commented out in `event-system/meta.xml`. A file existing in the repository does not necessarily mean its feature is running.

## Discord account linking (planned)

Discord will be an optional identity link at first. The game account remains usable if Discord is down or not configured. A player may pair their authenticated game account with a Discord account using a short-lived one-time code and a bot/authorized interaction. The server must verify the resulting Discord user ID through a trusted service and must never accept role IDs supplied by the client. Role-gated gameplay access will be explicit and server-authoritative; sensitive permissions fail closed when verification is unavailable.

## Known limitations

- No UCP or website is required by the target design; some legacy links and integrations remain in source.
- Features described here are source-mapped, not runtime-tested.
- Donor/supporter tiers are separate from moderation and game-master authority in the target permission design.
- Detailed staff actions and server setup are documented separately in `STAFF_ADMIN_GUIDE.md` and `SERVER_OPERATOR_GUIDE.md`.
