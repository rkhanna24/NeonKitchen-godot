# Assignment 6 — A GER Pipeline for Neon Kitchen

**Game:** *Neon Kitchen*, a Godot 4.7.1 recipe-composition puzzle in a nomad food
truck. Players combine up to three ingredients for a customer with a hidden
flavour preference.

**Content generated:** ingredients and customers — the `.tres` resources that
*are* the puzzle. Twelve ingredients and eight customers make 298 dishes and
2,384 evaluations, which is why no human eyeballs the effect of adding one.

## Pre-Build Declaration

The crew this wraps predates the assignment; declared here is what it added — the
bounded loop, the breaker, and the constraint rule.

**1. What content is generated manually, inconsistently, or not at all?**
Ingredients and customers. A crew already generates them, but nothing bounded its
refine loop — a human decided when to stop. One run took three revision rounds
where each fix produced a new violation, and it ended because someone noticed.

**2. What GDD rule must every piece satisfy?**
GDD §2.4: "Each customer must have at least three satisfying combinations,
including at least two that do not depend on the same central ingredient. No
single recipe should satisfy more than half of the customer roster."

**3. What does failure look like, concretely?**
A customer sits down and no dish in the twelve-ingredient pantry reaches
SATISFIED. The player can only fail them. Or one recipe satisfies five of eight
customers, and the pantry stops being a puzzle and becomes a lookup table.

## The loop

`tools/ger_loop.sh` is generic over two hooks and knows nothing about Godot
([full documentation](https://github.com/rkhanna24/NeonKitchen-godot/blob/content/ger-pipeline/tools/ger/README.md)):

```
GENERATOR <brief> <defect> <attempt>   0 = continue, non-zero = hard stop
EVALUATOR <defect-output>              0 PASS, 1 REVISE, >=2 ERROR
```

**Generator** — `pantry-keeper` then `health-inspector`, holding no `Bash`, so it
cannot score its own proposal. **Refiner** — the defect file carries the
evaluator's report verbatim, so the generator is told *what* was wrong, not that
it failed. **Circuit breaker** — three trips: budget, oscillation (a normalised
defect signature repeats), and hard error. Separating ERROR from REVISE stops the
loop refining against a broken judge. Every trip writes an escalation.

`tools/ger/selftest.sh` proves it: **17 checks, no API key, no Godot**.

## What the Evaluator enforces

`evaluate_recipe_space.sh` reads its verdict from `audit_recipe_space.gd`, which
enumerates every dish through the real `Evaluator` — GDD §2.4 above, plus ADR
0004 §5's requirement that a constraint actually constrain. The rule is not
reimplemented.

Proven both ways: forbidding `vegan` on `block_boss` (11 of 12 ingredients carry
it) drops him to **0 satisfying dishes** and returns REVISE naming him; on
committed content, PASS.

## What it caught that I would have missed

1. **A green that meant nothing.** Godot exits 0 when a GDScript fails to parse,
   so the evaluator read a *stale* report and returned PASS for content that
   fails the rule. It now requires the report's mtime to advance — and the
   project gate had a narrower version of the same bug, now fixed.

2. **A number that did not match its claim.** `block_boss`'s old
   `FORBID_TAG(raw)` measures **123 dishes engaged, 64 bands changed** —
   load-bearing. ASSIGNMENT-4.md calls it "0 of 120 — inert", a contribution test
   rather than an outcome test.

3. **A gap in the validator.** `ContentValidator` misses two differently-worded
   constraints with identical reach: `FORBID_TAG(smoked)` plus
   `FORBID_INGREDIENT(smoked_fish)` passes, and both are dead weight.

## Files

Branch [`content/ger-pipeline`](https://github.com/rkhanna24/NeonKitchen-godot/tree/content/ger-pipeline).

| Artifact | Role |
|---|---|
| [`tools/ger/README.md`](https://github.com/rkhanna24/NeonKitchen-godot/blob/content/ger-pipeline/tools/ger/README.md) | **how the pipeline works** |
| [`tools/ger_loop.sh`](https://github.com/rkhanna24/NeonKitchen-godot/blob/content/ger-pipeline/tools/ger_loop.sh) | driver + circuit breaker |
| [`tools/ger/evaluate_recipe_space.sh`](https://github.com/rkhanna24/NeonKitchen-godot/blob/content/ger-pipeline/tools/ger/evaluate_recipe_space.sh) | Evaluator |
| [`tools/ger/generate_via_crew.sh`](https://github.com/rkhanna24/NeonKitchen-godot/blob/content/ger-pipeline/tools/ger/generate_via_crew.sh) | Generator |
| [`tools/ger/selftest.sh`](https://github.com/rkhanna24/NeonKitchen-godot/blob/content/ger-pipeline/tools/ger/selftest.sh) | 17 breaker checks |
| [`bootstrap/audit_recipe_space.gd`](https://github.com/rkhanna24/NeonKitchen-godot/blob/content/ger-pipeline/bootstrap/audit_recipe_space.gd) | the rule, enumerated |
