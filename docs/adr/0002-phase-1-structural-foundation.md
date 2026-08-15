# ADR 0002: Phase 1 structural foundation

- Status: Accepted
- Date: 2026-07-31
- Deciders: Rohan Khanna (human authority); Kitchen Lead (audit and recommendation)
- Supersedes: DEC-009 (proposed)

## Context

Root `AGENTS.md` presents ten "Non-Negotiable Architecture Rules" and six
ADR triggers. A traceability audit performed on 2026-07-31
([issue #14](https://github.com/rkhanna24/NeonKitchen-godot/issues/14))
mapped each one to the game design document, an approved worklog decision, or
an accepted ADR, treating `docs/technical_architecture.md` as **not**
authoritative because it carries `status: proposed`.

The audit found **6 authorized, 4 partial, and 6 orphaned** rules. Every orphan
traced to DEC-009 or to the proposed architecture document, so the apparent
sprawl was one unratified decision presented in many places.

It also found two structural defects:

- **A1.** The `AGENTS.md` Authority section ranked "the technical architecture"
  fourth, above task context — granting binding authority to a document whose
  own status is *proposed*.
- **A2.** `AGENTS.md` still described the phase as "Godot 4.x", superseded by
  ADR 0001 and DEC-015.

Separately, an independent review against current Godot practice identified six
gaps, four of which are correctness hazards rather than style preferences.

Phase 1 must not become speculative infrastructure — a risk the GDD names
directly and which `docs/technical_architecture.md` §3.9 states as "design
seams, not imaginary implementations." The decisions below apply that principle
to the document itself.

## Decision

### 1. DEC-009 is superseded by this ADR

Its content is accepted in narrowed form. The following are binding for Phase 1.

### 2. Interface independence and dependency direction (rules 1, 3, 9b)

Binding as written. The domain core does not depend on `Node`, scenes, input,
localization, assets, filesystem paths, RPCs, peer IDs, or 2D/3D coordinates.
Authoritative state lives outside presentation nodes. Adapters depend inward;
domain code never imports adapters.

This is the half of the architecture with direct GDD authority: §5.1 requires
that "the evaluator must be callable without either interface" and that neither
the terminal nor the UI "contain scoring or constraint logic."

The extended prohibitions (RPCs, peer IDs, 3D coordinates, localization) are
retained because they forbid rather than build. They cost nothing and preserve
the routes the project intends to keep open.

### 3. Commands and events (rule 2)

Binding, with the **full proposed vocabulary** reserved:

| Commands (7) | Events (10) |
|---|---|
| `StartSession` | `SessionStarted` |
| `PresentCustomer` | `CustomerPresented` |
| `SelectIngredient` | `IngredientSelected` |
| `RemoveIngredient` | `IngredientRemoved` |
| `SubmitDish` | `DishSubmitted` |
| `StartCookingChallenge` | `CookingChallengeRequested` |
| `ResolveCookingChallenge` | `CookingChallengeResolved` |
| | `DishEvaluated` |
| | `CustomerReacted` |
| | `SessionEnded` |

The cooking-challenge terms are retained deliberately. The GDD lists "cooking
techniques that transform flavor" among its five candidate post-capstone
systems, and the human identifies cooking minigames as the first intended
stretch target. Reserving the vocabulary is roadmap, not speculation.

**Guardrail.** Phase 1 must not give `StartCookingChallenge`,
`ResolveCookingChallenge`, `CookingChallengeRequested`, or
`CookingChallengeResolved` field-level definitions, and must never emit them.
Phase 1 lacks the information to design those fields well. Issue #4 locks
field-level detail for the remaining five commands and eight events only.

### 4. Determinism, time, and randomness (rule 4)

The Phase 1 domain contains **no randomness and no wall-clock time**. No
`randf()`, `randi()`, `Time.*`, or `OS.get_ticks_*` under `core/domain/`. This
is checkable by grep and should become a CI check.

`RandomPort` is **declared as an interface only**. No adapter is built until a
real consumer exists. Any future domain randomness must arrive through it.

`ClockPort` is **not created**. A time-based cooking minigame does not require
one: per `docs/technical_architecture.md` §9, the challenge adapter owns its own
timing and returns timing accuracy and duration to the domain as plain data.

This is stricter than the superseded rule, which required injection. A blanket
prohibition is both simpler and harder to violate accidentally, and it builds
nothing that lacks a consumer.

### 5. Ports (rule 9a)

| Port | Phase 1 status |
|---|---|
| `ContentRepository` | **Built** — `.tres` adapter, in-memory test adapter, port contract suite |
| `RandomPort` | Interface only |
| `CookingChallengePort` | Interface only |
| `PlayerInputPort` | Not created — commands are the input contract |
| `PresentationPort` | Not created — events are the output contract |
| `SaveRepository` | Not created — §20 defers persistence beyond test fixtures |
| `LocalizationPort` | Not created — Phase 1 requires localization *keys*, not the adapter |
| `ClockPort` | Not created — see §4 above |

`ContentRepository` is the only port with a real Phase 1 consumer; DEC-010
already requires validated `.tres` loading before the domain sees content.
`CookingChallengePort` is declared because §3.9 uses it as the canonical example
of a seam worth defining without implementing.

### 6. Repository layout (resolves Q-004)

Create only folders that will hold files during Phase 1:

```text
neon-kitchen/
├── project.godot
├── AGENTS.md
├── bootstrap/                      composition root
├── core/
│   ├── domain/{commands,events,rules,state}/
│   ├── application/
│   └── ports/
├── adapters/{content,terminal}/
├── content/
│   ├── schemas/
│   ├── base/{ingredients,customers}/
│   └── test_fixtures/
├── assets/                         authored presentation resources (Phase 3)
│   └── themes/                     one Theme per palette; swappable
├── tests/{unit,content,contract,golden}/
├── addons/                         created when #7 selects a framework
└── docs/
```

`docs/technical_architecture.md` §6 remains the recorded **target shape**.
Deferred folders — `features/`,
`adapters/{localization,persistence,networking}/`,
`content/base/{recipe_patterns,levels}/`,
`tests/integration/`,
`assets/{fonts,sprites}/`, `assets/sprites/{ingredients,customers,backgrounds}/`
— are created when their first real file exists. Layer names are stable, so
growth is additive and requires no restructuring.

> **Amended 2026-08-14 (DEC-034).** `assets/` is new, and the deferred list above
> is trimmed to what is still deferred: `shared/`, `adapters/godot_ui/`,
> `content/base/localization/`, `tests/{smoke,golden}/` and
> `core/domain/value_objects/` have all since been created and are no longer
> pending. Leaving built folders on a deferred list makes the list describe the
> repository as it was rather than as it is, which is how `tools/gap_scan.py`
> came to report a folder as licensed-absent while it sat in the tree.
>
> `assets/` holds **authored presentation resources** — themes, fonts, sprites.
> It is not `content/`: content is the game's data, validated at load and
> governed by ADR 0004, and a Theme that failed to load would not make a customer
> invalid. Nor is it `adapters/`, which is code.
>
> **Themes are plural by construction.** `assets/themes/` holds one resource per
> palette, named for the palette rather than for the game, so trying a different
> one is a path change and not a rewrite. `docs/design/Visual Language.md` §Rules
> are theme-independent and bind every theme; the palette table in that document
> describes only the currently active one.
>
> Audio is deliberately absent. GDD §5.1 defers an original soundtrack and the
> shipping list names no audio, so a folder for it would be a folder for
> something out of scope.

### 7. Layout constraint (rule 10, split)

**Binding:** do not create a folder with no file in it. Do not add anything to
`shared/` until two real consumers exist.

**Guidance, not binding:** prefer feature-local scenes, scripts, tests, and
assets; keep a feature understandable without searching the whole repository.

The first is mechanically checkable and guards a real failure mode — agents
reliably manufacture `utils/` and `shared/` dumping grounds, and code rarely
migrates back out. The second is a judgment-dependent preference and does not
belong under a "non-negotiable" heading.

### 8. Godot-specific correctness rules

Added to `AGENTS.md`:

- **Resource reference-sharing.** Godot shares Resources by reference: `load()`
  returns a cached instance and an exported Resource is shared across every
  scene instance, so mutating one mutates every consumer. Never write to a
  loaded definition. Use an explicit `duplicate()` or a separate runtime value
  object when a mutable copy is required.
- **`.uid` files.** Commit them. They are engine-internal reference plumbing,
  not generated output. Never delete one to tidy the tree, and never use a UID
  as gameplay identity.
- **Parameterless `_init()`.** A custom `Resource` must load with no constructor
  arguments, or it fails to load and becomes `null` at runtime.
- **Integer arithmetic.** Flavor and scoring arithmetic stays in integers. Godot
  does not guarantee deterministic float math across platforms, and float→int
  rounding is inconsistent at edge cases.
- **Warning enforcement.** Static typing is enforced by `project.godot` warning
  settings and CI, not by convention. Issue #2 selects and records exact levels.
- **`preload` cycles.** Prefer `load()` across layer boundaries. Treat a cyclic
  reference error as evidence of wrong layering, not an obstacle to work around.

The integer-arithmetic rule constrains issue #4: customer target weights must be
integers. With the rating bands at 40, 65, and 85, a float score computing to
84.9997 on one platform and 85.0001 on another would land in different bands and
break golden parity across the macOS, Windows, and Linux CI matrix pinned by
ADR 0001.

### 9. ADR triggers

All six retained. `AGENTS.md` cites authority for each: ECS (DEC-011), C# or
another language (ADR 0001, DEC-002), canonical content format and incompatible
content-schema change (DEC-010), and — newly authorized by this ADR — persistent
Autoload, global event bus, new domain dependency, and incompatible
command/event/save/replay change.

### 10. Document status corrections

- `AGENTS.md` Authority order no longer ranks the proposed architecture document
  above task context. It cites the GDD, accepted ADRs, and approved decisions as
  binding, and the architecture document as guidance (fixes **A1**).
- `AGENTS.md` names Godot 4.7.1 per ADR 0001 instead of "Godot 4.x" (fixes
  **A2**).
- `docs/technical_architecture.md` marks which Phase 1 constraints this ADR
  accepts and which content remains proposed long-term guidance.

## Alternatives Considered

**Ratify the whole architecture document as accepted.** Rejected: it specifies
multiplayer, localization, 3D presentation, C# interop, and rhythm minigames for
a five-week solo capstone whose Phase 1 is twelve ingredients and eight
customers. Its own §3.9 argues against this.

**Reject DEC-009 and let #4 choose freely.** Rejected: #2 and #4 would each make
structural decisions implicitly while building, which is the drift #14 exists to
stop.

**Cut the cooking-challenge vocabulary.** Recommended by the audit, rejected by
the human on the grounds that the GDD lists cooking techniques as a stretch
candidate and minigames are the intended first extension. The guardrail in §3
preserves the cost saving without closing the route.

**Build `ClockPort` and `RandomPort` adapters now.** Rejected: neither has a
Phase 1 consumer, and §9 shows minigame timing does not require a domain clock.

**Create the full §6 tree with `.gitkeep` files.** Rejected: it would violate
§7's no-empty-folders rule on the day it was created.

**Keep rule 10 wholly binding, or demote it wholly.** Both rejected in favour of
the split; the rule mixes a checkable constraint with an unenforceable
preference.

## Consequences

**Enabled**

- Every binding rule in `AGENTS.md` cites the GDD, an approved decision, or an
  accepted ADR. A coding agent can trace any rule to its authority.
- Issues #2 and #4 proceed without making structural decisions implicitly.
- Q-004 and Q-007 are resolved.

**Required**

- Issue #2 scaffolds only the §6 layout above, selects and records the exact
  `project.godot` warning levels, and adds the no-randomness grep check.
- Issue #4 locks fields for five commands and eight events only, and must use
  **integer** customer target weights.
- Issue #7's framework choice creates `addons/`.

**Deferred**

- Field-level design of the cooking-challenge vocabulary.
- All ports not listed as built or declared in §5.
- The `features/`, `shared/`, and deferred adapter folders.

## Verification

- Each binding rule in `AGENTS.md` cites its authority inline; no rule cites the
  proposed architecture document alone.
- `AGENTS.md` contains no unqualified "Godot 4.x" reference.
- After #2, no folder in the repository is empty, and `shared/` does not exist.
- After #4, no challenge command or event has field-level definition.
- A grep for `randf|randi|Time\.|OS.get_ticks` under `core/domain/` returns
  nothing.
- Worklog Q-004 and Q-007 are marked resolved.
