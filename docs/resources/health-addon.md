# `health-addon` resource

**Review state:** Partial source review of the manifest, injury command/consent flow, diagnosis request/response path, schema, and remotely registered treatment/ped events. Treatment transaction and all caller authorization semantics remain under review; runtime is unverified.

## Gameplay purpose and player workflows

`health-addon` models external and internal injuries by body region, stores diagnosis flags in a `health_diagnose` table keyed by character ID, and provides nearby diagnosis, injury, and treatment flows. `/injure` selects a sharp or blunt injury, a body region or named part, and light/heavy severity, then asks the target to accept or decline through `/irespond`. `/diagnose` lets a player inspect their own medical record or request permission to inspect a nearby player's record. `/treat` is used by a player at the hospital or a member of faction 2 to request treatment of themselves or another player. The exact treatment authority, price, and settlement flow still require caller-by-caller review.

The bundled SQL file defines `uniqueID`, `int_diagnose`, and `ext_diagnose`; this is character-linked medical history, not Discord identity or a staff permission store. The manifest loads shared definitions on both sides, client injury/diagnosis UI, and client ped behavior. It declares no exports or explicit resource dependencies.

## Source finding: diagnosis consent binding

The `/diagnose` command checks distance and sends a client consent prompt. However, the remotely triggerable `disp_diagnose` event directly invokes the diagnosis handler with client-provided patient, character ID, and recipient parameters. The handler queries the supplied character ID and can send the result to the supplied player without deriving the responding patient from MTA `client` or proving a matching server-held pending consent request. This is tracked in [Issue #444](https://github.com/itschase/OwlMTA-2026/issues/444). Treat unauthorized disclosure as a source risk; no live exploit or runtime behavior was tested.

Other remotely registered server events include `send_response_data`, `init_treat_bodypart`, `init_treat_all`, `init_treat_response`, `send_info`, and `ped_treat`. The treatment trace confirms that the body-part/all-clear events write by a supplied character ID without an authorization check; `init_treat_response` trusts client-provided patient ID, payer, name, and price and clears injuries after `hasMoney` without deducting funds in that handler; `ped_treat` also trusts its payment and character parameters. These source findings are tracked in [Issue #445](https://github.com/itschase/OwlMTA-2026/issues/445). Runtime and economic impact remain unverified. `send_info` and `send_response_data` still need complete source/caller review.

## Staff, medical roleplay, and Discord boundary

Medical roleplay uses local faction membership and player consent. Discord staff roles should not grant access to a character's diagnosis or allow a medical treatment, and donor/supporter tiers should not imply medical authority. Any future Discord capability must complement the existing faction/character/consent checks and remain outside patient-data disclosure rules.

## Operator notes and next audit

Before enabling this feature, verify the `health_diagnose` schema and migration/import order, character-ID uniqueness, database failure behavior, loaded callers, and resource start dependencies. Continue tracing every remote event to its player UI and server-internal callers. Deduplicate issue candidates for treatment payer/price authority, body-part state changes, diagnosis retrieval (`send_info`), and ped billing before filing. No MTA server or tests were run.

## Runtime verification

After static review and safe-start preparation, test self-diagnosis, consent/refusal, spoofed patient/recipient/character IDs, character changes, injury accept/decline, faction-2 treatment, hospital self-treatment, ped treatment, payment failure, duplicate response, reconnect, and database errors on a disposable server.
