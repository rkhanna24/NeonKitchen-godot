# The GER loop

A **G**enerate → **E**valuate → **R**efine loop with a circuit breaker, used to
add ingredients and customers to *Neon Kitchen* without breaking the puzzle.

```bash
./tools/ger_loop.sh --brief "An ingredient that gives night_courier a second
                             satisfying dish not built on chili_crisp"

./tools/ger/selftest.sh          # 17 checks, no API key and no Godot
```

## Pre-Build Declaration

The crew this loop wraps predates the assignment; declared here is what it added
— the bounded loop, the breaker, and the constraint rule.

**1. What content type does your game currently generate manually,
inconsistently, or not at all?**

Ingredients and customers. A crew already generates them, but nothing bounded its
refine loop — a human decided when to stop. One run took three revision rounds
where each fix produced a new violation, and it ended because someone noticed.

**2. What specific rule from your GDD must every piece of that content satisfy?**

GDD §2.4: "Each customer must have at least three satisfying combinations,
including at least two that do not depend on the same central ingredient. No
single recipe should satisfy more than half of the customer roster."

**3. What does a failure look like — concretely, in your game's terms?**

A customer sits down and no dish in the twelve-ingredient pantry reaches
SATISFIED. The player can only fail them. Or one recipe satisfies five of eight
customers, and the pantry stops being a puzzle and becomes a lookup table.

## Why this exists

`docs/crew/README.md` describes a four-agent crew that already generates content:
the Pantry Keeper proposes, the Recipe-Space Analyst judges, and a `REVISE` edge
sends the defect back. What it did not have was anything **outside itself**
deciding when to stop.

`docs/crew/ASSIGNMENT-4.md` records what that costs. One run took three revision
rounds in which each fix "produced another", and it ended because a human
noticed — not because the pipeline concluded anything. Local fixes to a global
constraint cycle, and a loop with no bound will cycle for as long as you let it.

The loop is the bound. The crew is still the generator.

## The two hooks

`ger_loop.sh` knows nothing about ingredients, customers, or Godot. Everything
game-shaped lives behind two commands, so the same driver can refine content,
prose, or documents by swapping them.

```
GENERATOR <brief-file> <defect-file> <attempt>   0 = continue, non-zero = hard stop
EVALUATOR <defect-output-file>                   0 PASS, 1 REVISE, >=2 ERROR
```

**The generator** produces or revises the candidate in the working tree. On
attempt 1 the defect file exists and is empty; on every later attempt it holds
the evaluator's report from the previous round. That file is the whole mechanism
of refinement — the generator is told *what specifically was wrong*, not that it
failed.

**The evaluator** judges what is in the working tree and writes its findings to
the file it is given. Its exit code is a three-state verdict, and the third state
is the point.

### Why ERROR is not REVISE

A crashed evaluator that reported `REVISE` would send the generator chasing a
defect nobody measured. Three rounds later the escalation would blame the
content, and the actual fault — a broken judge — would not appear anywhere in
the report. Separating the states means the loop refuses to refine against a
tool it cannot trust, and says so.

This is not hypothetical; see "A green that meant nothing" below.

## The circuit breaker

Three independent trips, because "ran out of attempts" is only one of the ways a
self-correcting loop fails to self-correct.

| Trip | When | Why it is separate |
|---|---|---|
| **Budget** | `--max-attempts` rounds elapsed, default 3 | the ordinary case |
| **Oscillation** | a defect signature repeats | the loop is cycling, not converging |
| **Hard error** | the generator failed, or the evaluator could not judge | retrying a broken tool is not refinement |

Signatures are normalised — whitespace collapsed, blank lines dropped, lines
sorted — before hashing, so reporting the same three failures in a different
order is correctly recognised as *not having moved*.

Oscillation trips on the **repeat**, not at the end of the budget. A loop that
has demonstrably stopped converging should not be given another turn on the
strength of hope, and spending the remaining attempts would reach the same
conclusion more slowly. Repeats do not have to be consecutive: a defect seen two
rounds ago still counts.

Every trip writes `content/staging/escalation.md` with the brief, every round's
verdict, the signature history, and what a human now has to decide. The loop does
not decide what to do about a defect it could not fix — that is the human's call,
and the escalation exists to make the call answerable.

## Safety

The generator writes into the working tree, so `ger_loop.sh` **refuses to start
on a dirty one**. That guard is what makes every run revertible with
`git checkout . && git clean -fd`, and it is the reason a generator that shells
out to an agent under bypassed permissions is defensible here. `--allow-dirty`
exists for the self-test, which runs entirely on fixtures and never asks a
generator to touch tracked content.

Exit codes: `0` PASS, `1` breaker tripped, `2` usage error, `3` a precondition
failed.

## The shipped hooks

### `generate_via_crew.sh`

Dispatches `pantry-keeper` (proposal) then `health-inspector` (`.tres` and locale
rows). It deliberately does **not** dispatch `recipe-space-analyst`: that role is
the loop's evaluator now, and running it inside the generate step would put the
check inside the thing being checked — the same collapse `docs/crew/README.md`
warns about on the `REVISE` edge. The Pantry Keeper still holds no `Bash`, so it
cannot score its own proposal before the evaluator sees it.

It fails if `health-inspector` leaves `content/base` unchanged. A generator that
reported success while changing nothing would send an unchanged candidate round
the loop until the oscillation trip caught it; failing here names the cause.

### `evaluate_recipe_space.sh`

Enforces the game's own balance rule by reading the verdict out of
`bootstrap/audit_recipe_space.gd`, which enumerates every legal dish against
every customer through the real `Evaluator` — 298 dishes and 2,384 evaluations at
twelve ingredients and eight customers. **It does not reimplement the rule.** A
second implementation would be a second thing to keep in agreement with the game,
and the audit exists precisely to stop having those.

| Rule | Source |
|---|---|
| ≥3 satisfying dishes, ≥2 distinct central ingredients | GDD §2.4 |
| no dish satisfies more than half the roster | GDD §2.4 |
| no ingredient required by more than half the roster | GDD §5 |
| every constraint changes some outcome | ADR 0004 §5 |
| content loads at all | `ContentValidator` |

It regenerates `docs/design/Recipe Space Audit.md` rather than checking it. That
is correct inside the loop: the content just changed, so the committed report is
*supposed* to be stale, and a regenerated report is the measurement.
`scripts/check.sh` runs the same audit in `--check` mode for the opposite purpose
— catching content that moved without the report following.

## Keeping it honest

```bash
./tools/ger/selftest.sh
```

Seventeen checks over the loop's control flow, on scripted generators and
evaluators: no API key, no Godot, no content touched. The breaker is the part
that is hard to demonstrate honestly on real content — you would have to author
content bad enough to fail three times in a specific pattern — and scripted
verdicts make each trip reproducible in a second. It covers accepting on the
first attempt, refining once then passing, the defect actually reaching the
generator, all three trips, non-consecutive repeats, and signature normalisation.

The evaluator was checked in the failing direction against real content:

- **Viability.** Forbidding `vegan` on `block_boss` (11 of 12 ingredients carry
  the tag) drops him to **0 satisfying dishes**, best reachable
  `40 MIXED — smoked_fish`. The evaluator returns `1` naming him. Reverted; it
  returns `0` on committed content.
- **Inert constraints.** Authoring `FORBID_TAG(smoked)` alongside
  `FORBID_INGREDIENT(smoked_fish)` — the only ingredient carrying that tag —
  passes `ContentValidator` and reports both as inert, 67 dishes engaged and 0
  bands changed each, since removal is marginal and either one covers the other.
  Reverted.
- **Evaluator error.** Pointed at an audit script that will not parse, it returns
  `2`, not `1` and not `0`.

The two concentration rules were verified against the audit's exact `printf`
formats rather than end to end. Inducing a dominant dish needs several customers
rewritten, which would have meant testing the evaluator against content authored
to make it pass. Stated here rather than left for someone to discover.

### A green that meant nothing

**Godot exits 0 when a GDScript fails to parse.** On a fresh clone with no
`.godot/global_script_class_cache.cfg`, every type in the audit fails to resolve,
the script never loads, and the engine still exits 0.

The first version of this evaluator trusted that exit code, read the *stale
committed report*, and returned `PASS` for content that fails the rule. It now
imports first when the cache is absent, greps for `SCRIPT ERROR`, and requires
the report's mtime to advance before reading a verdict out of it. Fractional
mtime where the platform offers it: whole seconds compare equal for two writes in
the same second, which reads as "the audit did not run" and would trip the
breaker on a healthy run.

`scripts/check.sh` had a narrower version of the same shape. The fresh-clone case
was already covered there — the headless import step builds the class cache and
the type-and-warning step greps every `.gd` file for `SCRIPT ERROR` — but the
audit step itself inferred "the comparison happened" from a zero exit, with no
positive evidence it ran, so a *runtime* failure after load was caught by
neither. The audit now prints `CHECK_OK_MARKER` on a successful comparison and
the gate requires that line. Proven by replacing the audit with a stub that exits
0 having compared nothing:

```
==> Recipe space audit (committed report matches content)
    FAIL  the audit exited 0 without comparing anything; it did not run
```

## Files

| Path | What it is |
|---|---|
| `tools/ger_loop.sh` | the driver; the circuit breaker lives here |
| `tools/ger/evaluate_recipe_space.sh` | the Evaluator |
| `tools/ger/generate_via_crew.sh` | the Generator |
| `tools/ger/selftest.sh` | 17 checks over the loop's control flow |
| `bootstrap/audit_recipe_space.gd` | the enumeration the Evaluator reads |
| `docs/crew/README.md` | the crew the loop wraps |
| `docs/crew/ASSIGNMENT-6.md` | the assignment write-up |
