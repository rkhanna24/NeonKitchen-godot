# Neon Kitchen Coding Agent Guide

This file is the operational contract for agents that create or modify code in
this repository. It applies to the entire repository unless a more specific
`AGENTS.md` exists in a subdirectory.

## Read Before Coding

Read:

1. the task context and acceptance criteria;
2. [Technical architecture](docs/technical_architecture.md);
3. any accepted decision in `docs/adr/` that affects the task;
4. the relevant section of
   [the game design document](docs/design/Neon%20Kitchen%20-%20Game%20Design%20Document.md).

Consult `docs/worklogs/Kitchen Lead Worklog.md` when planning, resolving a
conflict, or handing off material work. Do not treat historical worklog entries
as more authoritative than a current approved decision.

## Current Phase

Phase 1 is a primitive headless Godot 4.x prototype written in statically typed
GDScript. Its purpose is to determine whether composing recipes for customer
preferences is understandable and enjoyable.

The terminal runner is an adapter, not the final game. The capstone target is a
Godot desktop game with a player-facing UI.

## Authority

Use this order when instructions conflict:

1. explicit human direction;
2. the game design document;
3. accepted ADRs;
4. the technical architecture;
5. the current task context;
6. implementation convenience.

Stop and surface a conflict rather than silently choosing a lower authority.

## Non-Negotiable Architecture Rules

1. Keep domain rules independent from `Node`, scenes, input, localization,
   assets, filesystem paths, RPCs, peer IDs, and 2D/3D coordinates.
2. Send player and system intent through typed commands. Report accepted facts
   through ordered domain events.
3. Keep authoritative game state outside presentation nodes.
4. Inject time and randomness. A recorded seed and command sequence must be
   reproducible.
5. Author game content as typed custom `.tres` Resources with stable,
   namespaced `content_id` values.
6. Never use a translated name, resource path, Resource UID, node name, or
   array index as gameplay identity.
7. Treat content Resources as immutable definitions at runtime. Validate them
   before the domain consumes them.
8. Add content through definitions and registries. Do not add
   ingredient/customer-specific branches to the general evaluator.
9. Put technology behind focused ports. Adapters depend inward; domain code
   never imports adapters.
10. Prefer feature-local scenes, scripts, tests, and assets. Put something in
    `shared/` only when multiple real consumers exist.

The following require an accepted ADR:

- a persistent Autoload;
- a project-wide ECS or global event bus;
- C# or another implementation language;
- a new canonical content format;
- a new domain dependency;
- an incompatible command, event, save, replay, or content-schema change.

## Godot Scene Rules

- Reusable scenes must work in isolation with injected inputs or documented
  defaults.
- Parents coordinate siblings.
- Children signal facts upward; parents call methods downward.
- Do not discover dependencies through absolute node paths.
- Use `Resource` for editor-authored definitions, `RefCounted` for lightweight
  runtime objects, and `Node` only when scene-tree behavior is required.
- Godot signals are for scene-local or engine-facing notification. Domain
  events are typed application facts. Do not create an untyped global bus.

## GDScript Standards

- Follow the official Godot GDScript style guide.
- Use static types for public parameters, return values, production members,
  and non-obvious locals.
- Use `snake_case` for files, folders, functions, variables, and signals.
- Use `PascalCase` for named classes and nodes.
- Use `CONSTANT_CASE` for constants and enum values.
- Name signals as past-tense facts, such as `dish_evaluated`.
- Target 80 characters per line; do not exceed 100 without a strong reason.
- Document public contracts with `##` comments.
- Use guard clauses and explicit result/error types for expected failures.
- Do not use `assert` for recoverable content or player errors.
- Suppress a warning only at the narrowest scope and explain why.

## Expected Change Boundaries

| Change | Normally add | Normally do not change |
|---|---|---|
| Ingredient | `.tres`, locale keys, presentation mapping, test fixture | general evaluator |
| Customer/character | `.tres`, request/dialogue keys, visuals, test fixture | unrelated scenes |
| Recipe pattern | `.tres` and golden cases | evaluator unless a new rule primitive is needed |
| Level | definition, encounters, presentation scene | recipe policy |
| Cooking minigame | port implementation, scene/assets, contract tests | dish/customer state directly |
| Visual style or dimension | visual profile, scenes, assets | domain and application rules |

If a routine content addition touches domain, presentation, persistence, and
networking code, stop and request an architecture review.

## Verification

Run every repository-provided check relevant to the change. The bootstrap
target is:

```text
gdformat --check .
gdlint .
godot --headless --path . --import
<repository headless test command>
<repository content-validation command>
```

The exact test commands must be recorded here when the test harness is chosen.
Do not invent a passing result or omit a failed check from the handoff.

At minimum:

- code format and lint pass;
- changed content validates;
- affected domain unit and golden tests pass;
- affected port contract tests pass;
- the project imports headlessly when scenes, scripts, or Resources change.

## Definition of Done

A change is complete when:

- it satisfies the task’s acceptance criteria;
- it respects the dependency and content boundaries above;
- it includes focused tests or fixtures;
- it passes all applicable checks;
- it does not contain unrelated cleanup;
- intentional schema or replay changes are documented;
- the handoff lists changed files, evidence, assumptions, and limitations.

Do not declare that a mechanic is fun based on automated tests. Fun and clarity
require human playtesting.

## Escalate Instead of Guessing

Escalate when:

- an authoritative artifact conflicts with the task;
- a stable ID or schema must change incompatibly;
- a new global service, language, framework, or architecture pattern appears
  necessary;
- implementation would expand the approved player experience or phase scope;
- acceptance requires a subjective design or lore decision.

## Handoff

Report:

- result;
- files changed;
- checks run and their outcomes;
- assumptions;
- known limitations;
- decisions or follow-up work still needed.

Keep the handoff concise. Update durable design or architecture memory through
the Kitchen Lead rather than embedding project history in code comments.
