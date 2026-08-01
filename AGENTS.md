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

Phase 1 is a primitive headless prototype on **Godot 4.7.1** (standard, non-.NET)
written in statically typed GDScript. Its purpose is to determine whether
composing recipes for customer preferences is understandable and enjoyable.

The terminal runner is an adapter, not the final game. The capstone target is a
Godot desktop game with a player-facing UI.

## Authority

Use this order when instructions conflict:

1. explicit human direction;
2. the game design document;
3. accepted ADRs;
4. approved decisions in the Kitchen Lead Worklog;
5. the current task context;
6. guidance in [Technical architecture](docs/technical_architecture.md);
7. implementation convenience.

The technical architecture is **guidance, not authority**, except where an
accepted ADR adopts a part of it. Stop and surface a conflict rather than
silently choosing a lower authority.

## Non-Negotiable Architecture Rules

Every rule below cites the authority that makes it binding.

1. Keep domain rules independent from `Node`, scenes, input, localization,
   assets, filesystem paths, RPCs, peer IDs, and 2D/3D coordinates.
   *(GDD §5.1; ADR 0002)*
2. Send player and system intent through typed commands. Report accepted facts
   through ordered domain events. *(ADR 0002 §3)*
3. Keep authoritative game state outside presentation nodes. *(GDD §5.1;
   ADR 0002)*
4. The domain contains no randomness and no wall-clock time. Any future
   randomness arrives through `RandomPort`. *(GDD §2.3; ADR 0002 §4)*
5. Author game content as typed custom `.tres` Resources with stable,
   namespaced `content_id` values. *(DEC-010)*
6. Never use a translated name, resource path, Resource UID, node name, or
   array index as gameplay identity. *(DEC-010)*
7. Treat content Resources as immutable definitions at runtime. Godot shares
   Resources by reference — `load()` returns a cached instance and an exported
   Resource is shared across every scene instance — so mutating one mutates
   every consumer. Never write to a loaded definition; take an explicit
   `duplicate()` or convert to a separate runtime value object. Validate
   definitions before the domain consumes them. *(DEC-010; ADR 0002 §8)*
8. Add content through definitions and registries. Do not add
   ingredient/customer-specific branches to the general evaluator. *(GDD
   Pillar 1, §2.3, §5.4)*
9. Adapters depend inward; domain code never imports adapters. Put technology
   behind a focused port only when a real consumer exists. *(GDD §5.1;
   ADR 0002 §5)*
10. Do not create a folder with no file in it. Do not add anything to `shared/`
    until two real consumers exist. *(ADR 0002 §7)*
11. Commit Godot's `.uid` sidecar files. They are engine-internal reference
    plumbing, not generated output. Never delete one to tidy the tree.
    *(ADR 0002 §8)*
12. A custom `Resource` must load with no constructor arguments. Give it a
    parameterless `_init()` or default every parameter. *(ADR 0002 §8)*
13. Keep flavor and scoring arithmetic in integers. Godot does not guarantee
    deterministic float math across platforms. If a float is unavoidable in a
    rule, define its rounding explicitly and compare with a tolerance.
    *(ADR 0001 platform matrix; ADR 0002 §8)*

Ports in scope for Phase 1: `ContentRepository` is built; `RandomPort` and
`CookingChallengePort` are declared as interfaces only. Do not create other
ports without an ADR. *(ADR 0002 §5)*

The following require an accepted ADR:

- a persistent Autoload *(ADR 0002 §9)*;
- a project-wide ECS *(DEC-011)* or a global event bus *(ADR 0002 §9)*;
- C# or another implementation language *(ADR 0001; DEC-002)*;
- a new canonical content format *(DEC-010)*;
- a new domain dependency *(ADR 0002 §9)*;
- an incompatible command, event, save, or replay change *(ADR 0002 §9)*, or an
  incompatible content-schema change *(DEC-010)*.

## Conventions

Guidance, not binding rules. Use judgment.

- Prefer feature-local scenes, scripts, tests, and assets. Keep a feature
  understandable without searching the whole repository.
- Prefer `load()` over `preload()` across layer boundaries. GDScript raises
  cyclic reference errors when scripts preload each other, and `class_name`
  participates in those cycles. Treat a cyclic error as evidence the layering is
  wrong rather than something to work around.

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
  and non-obvious locals. Static typing is enforced by `project.godot` warning
  settings and CI, not by convention. Do not lower a warning level to make code
  pass; fix the code, or justify a narrow-scope suppression.
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

Run the project gate. It is one command, and CI runs the identical script:

```bash
./scripts/check.sh
```

It exits nonzero if any check fails. It covers, in order: the pinned engine
version, `gdformat --check`, `gdlint`, headless import, GDScript type and
warning checks, domain purity, and the test suite.

First-time setup for the linter and formatter:

```bash
python3 -m venv .venv
.venv/bin/pip install -r requirements-dev.txt
```

The engine binary is resolved from `$GODOT_BIN`, then `godot` on `PATH`, then
the macOS default bundle. The bundle name carries no version, so the gate
asserts the expected version string rather than trusting the path.

Two Godot behaviours make the wrapper necessary rather than cosmetic, so do not
substitute the raw commands for it:

- `godot --headless --path . --import` exits 0 and reports nothing when a
  script has type or warning violations. It verifies import only.
- `godot --headless --check-only -s <file>` *reports* violations but still
  exits 0, so its output must be inspected rather than its exit code trusted.

**After changing `project.godot`, open the project in the editor once.** No
headless invocation validates project configuration. An invalid `config/features`
tag, for example, imports cleanly and is reported only by the editor GUI. The
gate cannot cover this; a human must.

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
