# Assignment 6 — A GER Pipeline for Neon Kitchen

**Game:** *Neon Kitchen* — a Godot 4.7.1 recipe-composition puzzle set in a nomad
food truck. The player combines up to three ingredients for a customer with a
hidden flavour preference; the dish is scored and the customer reacts.

**Content type:** ingredients and customers — the `.tres` resources that *are*
the puzzle. Twelve ingredients and eight customers make 298 legal dishes and
2,384 evaluations, which is why no human eyeballs the effect of adding one.

**Rule enforced:** GDD §2.4, quoted below, plus ADR 0004 §5's requirement that a
constraint actually constrain.

---

## Pre-Build Declaration

Full text with the timing note: [`ASSIGNMENT-6-PRE-BUILD.md`](ASSIGNMENT-6-PRE-BUILD.md).

**1. What content does your game generate manually, inconsistently, or not at all?**
Ingredients and customers. A crew already generates them, but nothing bounded
its refine loop — a human decided when to stop. One run took three revision
rounds where each fix produced a new violation, and it ended because someone
noticed.

**2. What specific rule from your GDD must every piece satisfy?**
GDD §2.4: "Each customer must have at least three satisfying combinations,
including at least two that do not depend on the same central ingredient. No
single recipe should satisfy more than half of the customer roster."

**3. What does a failure look like, concretely?**
A customer sits down and no dish in the twelve-ingredient pantry reaches
SATISFIED. The player can only fail them. Or one recipe satisfies five of eight
customers, and the pantry stops being a puzzle and becomes a lookup table.

---

## The loop

```
                    ┌──────────────────────────────────────┐
                    │                                      │
   brief ──> Generator ──> candidate .tres ──> Evaluator ──┤
             (pantry-keeper +                  (the audit) │
              health-inspector)                            │
                    ▲                                      │
                    │        0 PASS ──> accept ────────────┘
                    │        1 REVISE ─┐
                    │                  │
                    └── specific defect┘        >=2 ERROR ──> breaker
                              │
                              └──> repeated? budget spent? ──> breaker
                                                                 │
                                                     content/staging/escalation.md
```

`tools/ger_loop.sh` is generic over two hooks and knows nothing about
ingredients, customers, or Godot:

```
GENERATOR <brief-file> <defect-file> <attempt>   0 = continue, non-zero = hard stop
EVALUATOR <defect-output-file>                   0 PASS, 1 REVISE, >=2 ERROR
```

**The three-state verdict is the load-bearing part.** Separating ERROR from
REVISE is what stops the loop refining against a broken judge. A crashed
evaluator reporting REVISE would send the generator chasing a defect nobody
measured, and three rounds later the escalation would blame the content.

### Refiner

The defect file is the refinement channel. On attempt 2 and later it holds the
evaluator's report verbatim, and the generator is told *what specifically was
wrong* rather than that it failed. The Pantry Keeper still holds no `Bash`, so it
cannot score its own proposal before the evaluator sees it — and the generator
adapter deliberately does **not** dispatch the `recipe-space-analyst`, because
that role is the evaluator now and running it inside the generate step would put
the check inside the thing being checked.

### Circuit breaker

Three independent trips, because "ran out of attempts" is only one of the ways a
self-correcting loop fails to self-correct:

| Trip | When | Why it is separate |
|---|---|---|
| **Budget** | `--max-attempts` rounds, default 3 | the ordinary case |
| **Oscillation** | a defect signature repeats | local fixes to a global constraint cycle; ASSIGNMENT-4 records three rounds where each fix "produced another" and a human ended it |
| **Hard error** | generator failed, or evaluator could not judge | retrying a broken tool is not refinement |

Signatures are normalised before hashing, so reporting the same three failures in
a different order is correctly recognised as *not having moved*. Oscillation
trips on the repeat rather than spending the remaining budget to reach the same
conclusion — verified: with a PASS scripted for attempt 3, the loop still stops
at attempt 2.

Every trip writes `content/staging/escalation.md` with the brief, every round,
the signature history, and what a human now has to decide.

`tools/ger/selftest.sh` proves all of it with scripted hooks — **17 checks, no
API key and no Godot**, so each breaker path is reproducible in a second.

## What the Evaluator enforces

`tools/ger/evaluate_recipe_space.sh` reads its verdict out of
`bootstrap/audit_recipe_space.gd`, which enumerates every dish through the real
`Evaluator`. It does not reimplement the rule; a second implementation would be a
second thing to keep in agreement with the game.

| Rule | Source | Verdict |
|---|---|---|
| ≥3 satisfying dishes, ≥2 distinct central ingredients | GDD §2.4 | REVISE, naming the customers |
| no dish satisfies more than half the roster | GDD §2.4 | REVISE, naming the dishes |
| no ingredient required by more than half the roster | GDD §5 | REVISE, naming the ingredient |
| every constraint changes some outcome | ADR 0004 §5 | REVISE, naming the constraint |
| content loads at all | `ContentValidator` | REVISE, naming the field |

**How far each row is verified**, since a table is a claim. The viability rule,
the constraint rule, and the `ContentValidator` path were each driven end to end
against deliberately broken content and produced the REVISE shown. The two
concentration rows were verified against the audit's exact `printf` formats
rather than end to end — inducing a dominant dish needs several customers
rewritten, which would have meant testing the evaluator against content authored
to make it pass.

Proven in both directions. Forbidding `vegan` on `block_boss` — 11 of 12
ingredients carry that tag — drops him to **0 satisfying dishes**, best reachable
`40 MIXED — smoked_fish`, and the evaluator returns REVISE naming him. On
committed content it returns PASS.

## What the pipeline caught that I would have missed

### 1. A green that meant nothing

Breaking `block_boss` on purpose, the evaluator returned **PASS**.

**Godot exits 0 when a GDScript fails to parse.** On a fresh clone with no
`.godot/global_script_class_cache.cfg`, every type in the audit fails to resolve,
the script never loads, and the engine still exits 0. The evaluator trusted that
exit code, read the *stale committed report*, and reported PASS for content that
fails the rule.

It now imports first when the cache is absent, greps for `SCRIPT ERROR`, and
requires the report's mtime to advance before reading a verdict out of it.

**The same blind spot is live in `scripts/check.sh:329`**, where the gate treats
exit 0 as "report is current". On a fresh clone that step reports PASS for a run
that never happened. Left alone deliberately — changing the gate is a separate
change with its own risk — and recorded here rather than quietly fixed.

This is the project's documented failure shape exactly: *the code was defensible
and the claim about it was false.*

### 2. A number that did not match its claim

The constraint-integrity rule measures inertness **behaviourally** — remove the
constraint, re-evaluate every dish, count band changes.

The obvious alternative, "does the subject contribute to a dimension this
customer weights", gets the mechanism backwards. Constraints never read flavour
values (§5), and `SumAndClampComposer` means an ingredient contributing 0 to
every weighted dimension leaves the score *untouched* — so it rides along in an
otherwise satisfying dish, and forbidding its tag caps that dish from SATISFIED
to DISSATISFIED.

Measured rather than argued. Restoring `block_boss`'s old `FORBID_TAG(raw)`:

```
FORBID_TAG(raw)    123 dishes engaged    64 bands changed    load-bearing
```

[ASSIGNMENT-4.md](ASSIGNMENT-4.md) reports that same constraint as **"0 of 120
dishes changed — inert"**, which is the contribution test, not the outcome test.
The correction it justified may still have been right for other reasons —
`block_boss` weighted savory/comfort then and weights savory/spicy now — but the
number and the claim attached to it do not match.

### 3. A gap in the validator

`ContentValidator` rejects a constraint naming a tag no ingredient carries, and
an exact duplicate of an existing boundary. It does not catch **two
differently-expressed constraints with identical reach**. Authoring
`FORBID_TAG(smoked)` alongside `FORBID_INGREDIENT(smoked_fish)` — the only
ingredient carrying that tag — passes validation, and the audit reports both as
inert: 67 dishes engaged, 0 bands changed, each redundant given the other.

All four shipped constraints are load-bearing:

```
block_boss     FORBID_TAG smoked      67 engaged   67 changed
night_courier  FORBID_TAG fermented  123 engaged   68 changed
old_local      FORBID_TAG held        67 engaged   58 changed
scrap_trader   FORBID_TAG soy         67 engaged   67 changed
```

## Running it

```bash
./tools/ger/selftest.sh                       # 17 checks, no API key, no Godot

./tools/ger_loop.sh --brief "An ingredient that gives night_courier a second
                             satisfying dish not built on chili_crisp"

./scripts/check.sh                            # the project gate, 228 tests
```

The loop refuses to start on a dirty working tree, so every run is revertible
with `git checkout . && git clean -fd`.

## Files

| Path | What it is |
|---|---|
| `tools/ger_loop.sh` | the driver — generic over its two hooks; the breaker lives here |
| `tools/ger/evaluate_recipe_space.sh` | the Evaluator — GDD §2.4 and ADR 0004 §5 |
| `tools/ger/generate_via_crew.sh` | the Generator — pantry-keeper then health-inspector |
| `tools/ger/selftest.sh` | 17 scripted checks over every breaker path |
| `bootstrap/audit_recipe_space.gd` | the enumeration the Evaluator reads |
| `docs/design/Recipe Space Audit.md` | its report, drift-checked by the gate |
| `docs/crew/README.md` | the crew the loop wraps |
