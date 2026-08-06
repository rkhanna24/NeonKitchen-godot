# Kitchen Lead acceptance — late-shift medic

Date: 2026-08-05
Brief: *"A late-shift medic who wants something fresh and light, nothing heavy.
Add whatever single ingredient makes that request solvable against the existing
pantry."*

Accepted. Gate green at 110 tests.

## What shipped

| File | Change |
|---|---|
| `content/base/ingredients/rooftop_greens.tres` | new — Fresh 3, all other dimensions 0, tags `raw`,`vegan` |
| `content/base/customers/late_shift_medic.tres` | new — Fresh target 4 / weight 3, Comfort target 1 / weight 2, no constraints |
| `content/base/localization/en.csv` | +8 rows (ingredient name/description; customer name/request; four `reaction.<band>` rows) |
| `tests/content/test_phase_1_content.gd` | catalogue size 3/2 → 4/3; pinning tests for the new content; dish-enumeration size cap |

## Pipeline

Pantry Keeper → Analyst (**REVISE**) → Pantry Keeper → Analyst (**PASS**) →
Health Inspector (**FAIL at gate**) → Kitchen Lead repair → accepted.

Two round-trips, both justified:

1. **Analyst REVISE.** The proposal claimed `scrap_trader`'s best existing dish
   was `ember_chili_paste + neon_noodles` at 80/Satisfied. The real best is
   `neon_noodles` alone at **90/Delighted**. The 80 was correct arithmetic for a
   strictly dominated dish, labelled "best". I re-derived this myself against the
   real `.tres` before routing it back. The design numbers were unaffected; only
   the stated rationale was wrong.

2. **Health Inspector FAIL.** `test_the_set_is_the_approved_size` hard-pinned the
   pre-change catalogue size. It is a deliberate tripwire and `tests/` is outside
   the Inspector's boundary, so refusing was correct. Repair was mine.

The Inspector also refused a first dispatch because `balance.md` still recorded
`REVISE` — I had decided PASS in conversation but never recorded it in the gate
artifact. It was right to reject my say-so. Fixed by re-running the Analyst
against the corrected proposal rather than editing a verdict I did not author.

## Independent verification (Kitchen Lead, not delegated)

Loaded through the real `TresContentRepository`, validated with the real
`ContentValidator`, scored with the real `Evaluator`, from the `.tres` on disk:

- repository: `problems=[] is_loaded=true`, 4 ingredients / 3 customers
- `ContentValidator.validate(...)` → `[]`
- every score matches `balance.md` exactly, including medic 75 / 90 / 65,
  `scrap_trader` best 90, `solar_tech` best 100

Two things this caught that a delegated claim would not have:

- **`_dishes()` was enumerating illegal dishes.** With three ingredients the full
  power set was coincidentally all legal. The fourth makes 4-ingredient subsets
  reachable, which ADR 0004 §1 forbids. Capped, and guarded by a test proven to
  fail in both directions (removed the cap → 15≠14 and a size-4 dish enumerated;
  restored → green).
- **A false alarm I nearly reported.** All eight new locale keys returned
  `MISSING` via `TranslationServer.translate()`. The control test — pre-existing
  keys — returned `MISSING` too. Cause: `project.godot` registers no translations
  at all (`loaded_locales=[]`). The compiled `.en.translation` does contain the
  new keys. The Inspector's claim was accurate; my instrument was wrong.

## Open questions for the human

1. **Delighting the medic requires the chili paste.** Both 90-scoring dishes
   contain `ember_chili_paste`; Fresh 4 is only reachable as greens(3)+chili(1).
   The chili-free ceiling is 75/Satisfied. Mechanically legal — the medic's Spicy
   weight is 0, so Spicy is ignored, not disliked — but the only way to delight
   someone asking for "fresh and light, nothing heavy" is to add fiery fermented
   chili paste. Intended puzzle, or the model contradicting the fiction? **Tone
   call; not mine.** Deliberately not resolved by re-weighting Spicy.
2. **No dietary/allergen constraint** was invented for a medic. Preference, not
   boundary. Confirm.
3. **Role-based id** `customer.late_shift_medic` follows existing base content,
   but `customer_definition.gd`'s docstring illustrates personal names
   (`customer.mina_afterhours`). Which convention is canon?
4. **Canon fit** for "rooftop greens", and the medic's unestablished
   workplace/faction — no clinic or ward is named anywhere in `docs/design/`.

## Pre-existing issues found, deliberately not fixed here

- `tests/content/test_phase_1_content.gd` asserts
  `assert_eq(allowed.score, 80, "the soy-free alternative is the intended
  solution")`. 80 is correct arithmetic, but that dish is **not**
  `scrap_trader`'s best — `neon_noodles` alone scores 90. Same defect shape as
  the one the Analyst caught in the proposal: a true number with a false claim
  attached. Left alone as unrelated cleanup; worth its own change.
- `solar_tech.tres` declares an `ext_resource` for `customer_constraint.gd` that
  it never uses. Not copied into the new customer file.
- No translations are registered in `project.godot`, so `tr()` will silently
  return keys once a UI exists.
