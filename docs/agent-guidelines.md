# Agent Operations Guide

## Purpose

This guide lets a human contributor or automation agent resume OwlMTA-2026 from evidence instead of chat memory. It describes the repository's actual workflow; it does not create a separate public "AI" product surface or replace maintained technical documentation.

The root [`AGENTS.md`](../AGENTS.md) is mandatory. Repository Markdown is the source of truth, GitHub Discussions make that material discoverable, Issues own bounded work, and Milestones group delivery outcomes.

## Required read order

Before changing anything:

1. Read [`AGENTS.md`](../AGENTS.md) completely, including the latest activity entries.
2. Run `git status --short --branch` and inspect recent commits. Never assume another agent has stopped editing the shared checkout.
3. Read the current top section of [`planning/NEXT_WORK.md`](planning/NEXT_WORK.md).
4. Read only the relevant parts of:
   - [`planning/REBUILD_PLAN.md`](planning/REBUILD_PLAN.md)
   - [`planning/DOCUMENTATION_PROGRAM.md`](planning/DOCUMENTATION_PROGRAM.md)
   - [`planning/RESOURCE_AUDIT_PLAYBOOK.md`](planning/RESOURCE_AUDIT_PLAYBOOK.md)
   - [`planning/DISCUSSIONS_AND_ISSUES.md`](planning/DISCUSSIONS_AND_ISSUES.md)
5. For resource work, inspect [`resources/README.md`](resources/README.md), `RESOURCE_DOCUMENTATION_STATUS.csv`, the resource's `meta.xml`, every loaded script, and its existing dossier and Discussion.
6. Check the live Issue, Discussion, Milestone, and remote branch state before relying on a recorded number, title, link, or completion claim.

If the checkout changed during orientation, stop and reconcile ownership before editing.

## Shared-checkout protocol

Only one operator may edit a file or publish its tracker update at a time.

- Define one bounded unit and its owned paths before editing.
- Do not start broad autonomous work while another agent is operating in the same checkout.
- Never amend, reset, discard, or overwrite another contributor's work merely because it is uncommitted or unpushed.
- If unexpected commits or changes appear, freeze writes, inspect their exact diff, and reconcile them as user-owned work.
- Parallel research is allowed only when explicitly authorized and must use non-overlapping resources or read-only reports. Shared indexes and planning files are consolidated by the primary operator.
- Do not claim a clean tree, successful push, published tracker, or completed validation without checking the authoritative state immediately before the claim.

## Selecting work

Choose the next bounded unit from current evidence, not convenience:

1. identity, session, character, and remote-event authority;
2. persistence, money, inventory, ownership, and settlement integrity;
3. startup, schema, configuration, secret, and dependency blockers;
4. staff, GameMaster, public-safety, and operator authority;
5. core connected gameplay;
6. user experience, cosmetic, and archived-resource work.

Search open and closed Issues before creating anything. Update an existing Issue when it already owns the outcome. A TODO or FIXME is a review lead, not proof of a defect and not sufficient by itself for a new Issue.

## Code and security rules

- Treat client Lua as presentation. A remote server handler derives the requester from MTA `client`, validates event source/provenance, and independently checks permission, target, ownership, proximity, world, state, value bounds, replay, and rate limits as applicable.
- Preserve trusted server-internal callers when splitting a remote wrapper from an internal event or helper.
- Keep administrator, GameMaster, organization/faction, duty, donor/supporter, specialist-team, and MTA ACL authority distinct.
- Discord roles map to named capabilities through the Owl account facade. Gameplay resources do not call Discord, consume raw role IDs, or treat donor tier as staff authority.
- External identity is optional at process boot. Configured elevated authorization fails closed when unavailable or stale; no outage may silently grant authority.
- Keep secrets, installation IDs, role IDs, tokens, passwords, connection strings, and server-specific values out of source, Issues, Discussions, logs, screenshots, and chat.
- Add bounded, privacy-conscious diagnostics for rejected authority/state combinations and durable failures. Do not log credentials, tokens, raw Discord identity, private payloads, or high-frequency frame data.
- Do not start MTA until the documented static safe-start gate and disposable environment are ready.

## Credentials and external tools

- Never request that a user paste a PAT, OAuth token, password, or private key into an agent conversation.
- Never place a token in a command line, script body, environment dump, generated file, Issue, Discussion, or activity log.
- Use the existing OS credential manager or authenticated GitHub CLI session when available. If required access is missing, report the exact operation and stop; do not broaden scopes or create credentials autonomously.
- Treat a token pasted into any conversation as compromised. Do not reuse or repeat it; instruct the owner to revoke it through the provider.
- Repository settings, credentials, permissions, categories, and automation are not routine implementation details. Change them only under explicit owner direction and verify the result.

## Resource audit and documentation

Follow [`planning/RESOURCE_AUDIT_PLAYBOOK.md`](planning/RESOURCE_AUDIT_PLAYBOOK.md). A resource dossier must distinguish:

- player purpose and workflows;
- staff and GameMaster operations;
- operator setup, storage, dependencies, failure, and recovery;
- manifest-loaded client/shared/server code;
- commands, keybinds, events, exports, timers, callbacks, and callers;
- trusted actor and authorization boundaries;
- persistence tables and data ownership;
- connected resources and optional external providers;
- command-to-dashboard, contextual interaction, guided UI, or keybind opportunities;
- Discord-capability applicability and independent local checks;
- evidence, open Issues, and runtime status.

Use the status vocabulary exactly: `cataloged`, `source-reviewed`, `documented-current`, `documented-target`, `issue-backed`, `discussion-published`, `fixed-in-source`, `runtime-verified`, and `release-ready`. Source presence and static parsing never prove startup or gameplay behavior.

## GitHub records

### Issues

An Issue owns one reproducible defect or bounded outcome. Include status, source evidence, impact, scope/non-goals, dependencies, acceptance conditions, diagnostics/privacy needs, and the runtime matrix still required. Use existing repository labels and Milestones only after confirming them live. Do not invent a naming policy, Project board, automation, label, or Milestone.

### Discussions

Repository documentation remains the detailed reference. Discussions provide an audience-appropriate overview and link back to it.

- Resource topics use `Script Resource: <resource>` in **Script Resources**.
- Archived duplicates append ` (archived)`.
- Player help belongs in **Player Guide & Gameplay Q&A**.
- Staff workflows belong in **Staff & Admin**.
- Operator runbooks belong in **Server Operators**.
- Discord/API architecture belongs in **Discord & API Integration**.
- Cross-resource proposals belong in **Plans & Enhancements**.

Internal agent coordination belongs in this repository, not in a public AI-branded category. Do not paste entire maintained files into Discussions; publish a useful summary with source, status, connections, open work, and links.

### Publication checkpoint

Before publishing:

1. inspect the scoped diff and run proportionate static checks;
2. update the relevant dossier, `NEXT_WORK.md`, and `DISCUSSIONS_AND_ISSUES.md`;
3. commit and push the coherent source/documentation batch;
4. create or update nonduplicate Issues;
5. publish or update Discussions and Milestones where useful;
6. add returned URLs to maintained documentation;
7. commit and push the publication index;
8. verify the local branch equals its remote and the tree is clean.

## Required handoff

Append a concise entry to the root `AGENTS.md` activity log after completing a unit. Include:

- objective and bounded scope;
- exact files and behavior changed;
- source, documentation, and publication commit hashes;
- Issue/Discussion/Milestone URLs actually verified;
- checks performed and results;
- explicit runtime-unverified statement when MTA was not run;
- branch/remote/working-tree status;
- two or three evidence-based next actions.

Never log secrets or copy an agent transcript. The handoff should let the next contributor verify and continue the project without depending on a particular model, product, or conversation.
