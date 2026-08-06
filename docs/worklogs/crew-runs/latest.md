# Crew run

## Brief

> A late-shift medic who wants something fresh and light, nothing heavy. Add whatever single ingredient makes that request solvable against the existing pantry.

## Kitchen Lead transcript

```
Done. Committed to `content/late-shift-medic` (not pushed), gate green at 110 tests.

## What shipped

- **`ingredient.rooftop_greens`** — Fresh 3, everything else 0, tags `raw`/`vegan`
- **`customer.late_shift_medic`** — Fresh target 4 / weight 3, Comfort target 1 / weight 2, no constraints
- 8 locale rows, and the content test updated

The medic was genuinely unsolvable before: the only Fresh source was the chili paste at 1, capping them at 45/Mixed. Fresh 4 sits above the per-ingredient cap of 3, so it forces a combination rather than a lookup.

## The pipeline took two round-trips

**Analyst caught a false claim.** The proposal said `scrap_trader`'s best dish was chili+noodles at 80. Real best is `neon_noodles` alone at **90**. The 80 was correct arithmetic for a strictly dominated dish, labelled "best" — the project's signature defect shape. I re-derived it myself before routing it back.

**The Health Inspector twice refused, correctly.** First because `balance.md` still read `REVISE` — I'd decided PASS in conversation but never recorded it in the gate artifact. It was right to reject my say-so; I re-ran the Analyst rather than forging a verdict I didn't author. Second on a genuine gate failure in `tests/`, which is outside its boundary.

## What my own verification caught

Two things a delegated claim would have missed:

- **`_dishes()` was enumerating illegal dishes.** With three ingredients the full power set was *coincidentally* all legal. The fourth makes 4-ingredient subsets reachable, which ADR 0004 §1 forbids. Capped it and proved the guard fails in both directions.
- **A false alarm I nearly reported.** All eight locale keys returned `MISSING` via `TranslationServer`. The control — pre-existing keys — returned `MISSING` too: `project.godot` registers no translations at all. The Inspector's claim was accurate; my instrument was wrong. Worth checking the control before accusing.

I also caught my own bug: I put Fresh 3 in the spicy slot in a new assertion, and the test failed on me.

## Needs you

1. **Tone call I won't make:** both of the medic's Delighted dishes require `ember_chili_paste`. The only way to delight someone asking for "fresh and light, nothing heavy" is fiery fermented chili paste. Mechanically fine (Spicy weight 0 = ignored), but is that the intended puzzle? I deliberately did *not* resolve it by re-weighting Spicy.
2. Role-based id vs. personal name — the schema docstring suggests `customer.mina_afterhours`-style names; base content uses roles.
3. **Uncommitted files of unknown provenance:** `README.md` is modified and `docs/crew/`, `docs/worklogs/crew-runs/latest.md` are untracked. They weren't in my pre-flight `git status` but appeared during the run. The Pantry Keeper denies writing them and has no shell to check. I left all three uncommitted — please confirm they're yours.
4. **Pre-existing defect, not fixed:** `test_phase_1_content.gd` asserts chili+noodles is "the intended solution" for `scrap_trader` at 80 — same false-claim shape the Analyst caught, since noodles alone scores 90. Left as unrelated cleanup; deserves its own change.
```
