# `selfck-system` resource

**Review state:** Full manifest, paired player UI, server request/approval/cancellation flow, commands, and direct character-death integration review. Live account transitions and database behavior remain runtime-unverified.

## Player workflow

Players use `/selfck` to open a confirmation interface, enter a reason, and submit a request. The intended flow is a request for permanent character death, reviewed by online administrators; the player can use `/cancelck` while a request is pending. The UI tells the player to wait for staff and blocks a second request based on local element data.

The client-side UI sends `sendCKRequest` with its local player element and reason. Client arguments are not authoritative. The server handler currently accepts an arbitrary target player and text, then stores request data on that target without binding the request to server-side `client`. A forged target could appear to have asked for character death; repeated calls also have no server-side rate bound. This source finding is tracked in [Issue #429](https://github.com/itschase/OwlMTA-2026/issues/429).

## Staff workflow and character effects

Trial Admins use `/cka <player>` to approve and `/ckd <player>` to decline. The approval flow writes `cked`, `ck_info`, and `death_date` on the active character row, records the action through `logs`, and calls `realism:addCharacterKillBody` to preserve the death scene. These actions are consequential and must remain subject to the existing Trial Admin policy; donor/supporter or future Discord roles must not grant character-death approval.

The unlogged-player branch of `/cka` references an undefined `value` when decrementing request counters. Terminal paths also need consistent clearing of the request's character binding, and target lookup results need to be handled before element-data reads. The counter-path defect is tracked in [Issue #431](https://github.com/itschase/OwlMTA-2026/issues/431).

## State and connected resources

Pending request state (`ckstatus`, `ckreason`, and `ckchar`) is held as player element data. There is no dedicated database table declared by this resource; character-death persistence is written to the `characters` table. The resource uses `mysql`, `global`, `integration`, `logs`, and `realism` exports for persistence, player lookup, staff authorization, audit logging, and death-scene creation. It also sends counter updates to administrator clients.

The manifest lists both server and client scripts but does not declare explicit dependencies. Operators should verify the connected resources and character columns before enabling the workflow. Startup configuration currently lists `selfck-system` twice in the inspected backup snapshot; reconcile this with [Issue #21](https://github.com/itschase/OwlMTA-2026/issues/21), rather than assuming the duplicate is intentional.

## Future interaction and recovery

A player dashboard could make the request status, reason, and cancel action clearer, while a staff queue could show requester and active-character identity with a complete audit trail. Keep commands available while any interface migration is underway. Bind the request to the player and character at submission, invalidate it on character switch/disconnect, and make every approve/decline/cancel path update server state and counters exactly once.

## Runtime verification

On a disposable instance, verify normal request/cancel, invalid and oversized reason, rapid duplicate submission, forged target, character switch, logout, player disconnect, missing target, unlogged player approval, decline, database failure, and staff counter reconciliation. No MTA server or tests were run during this review.
