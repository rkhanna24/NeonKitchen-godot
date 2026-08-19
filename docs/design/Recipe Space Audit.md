# Recipe Space Audit

**Generated file. Do not edit by hand.** Regenerate with:

```
godot --headless --path . -s bootstrap/audit_recipe_space.gd
```

`scripts/check.sh` regenerates this in memory and fails if it differs from the committed copy, so it cannot quietly go stale when content changes. The gate fails on drift only — a `REVISE` verdict below is a design finding for the human, not a broken build.

Every number comes from `Evaluator.evaluate()`, the same entry point the game uses. Nothing here reimplements the scoring formula.

## Scope

12 ingredients, 8 customers, 298 legal dishes, 2384 evaluations.

Pantry: `chickpeas`, `chili_crisp`, `citrus_chili_paste`, `citrus_herbs`, `coconut_milk`, `kimchi`, `mushrooms`, `pickled_cucumber`, `rooftop_lettuce`, `smoked_fish`, `soy_broth`, `thick_wheat_noodles`

Roster: `block_boss`, `late_shift_medic`, `night_courier`, `office_worker`, `old_local`, `rig_partner`, `scrap_trader`, `solar_tech`

## Viability per customer

GDD section 2.4: each customer needs at least 3 satisfying dishes, including at least 2 that do not share a central ingredient.

| Customer | Best | Satisfying dishes | Distinct centres | Rule |
| --- | --- | --- | --- | --- |
| `block_boss` | 92 DELIGHTED — chili_crisp + kimchi + mushrooms | 40 | 3 | PASS |
| `late_shift_medic` | 100 DELIGHTED — citrus_herbs + mushrooms + rooftop_lettuce | 95 | 4 | PASS |
| `night_courier` | 91 DELIGHTED — chickpeas + chili_crisp + thick_wheat_noodles | 37 | 3 | PASS |
| `office_worker` | 100 DELIGHTED — citrus_chili_paste + citrus_herbs + rooftop_lettuce | 57 | 2 | PASS |
| `old_local` | 100 DELIGHTED — chickpeas + chili_crisp + mushrooms | 78 | 7 | PASS |
| `rig_partner` | 100 DELIGHTED — citrus_chili_paste + kimchi + rooftop_lettuce | 40 | 2 | PASS |
| `scrap_trader` | 100 DELIGHTED — chickpeas + kimchi + mushrooms | 105 | 5 | PASS |
| `solar_tech` | 100 DELIGHTED — chickpeas + coconut_milk + mushrooms | 92 | 5 | PASS |

Every customer satisfies the viability rule.

## Band coverage

How many dishes land in each band, per customer.

| Customer | DELIGHTED | SATISFIED | MIXED | DISSATISFIED |
| --- | --- | --- | --- | --- |
| `block_boss` | 2 | 38 | 96 | 162 |
| `late_shift_medic` | 14 | 81 | 127 | 76 |
| `night_courier` | 3 | 34 | 77 | 184 |
| `office_worker` | 4 | 53 | 83 | 158 |
| `old_local` | 30 | 48 | 90 | 130 |
| `rig_partner` | 11 | 29 | 78 | 180 |
| `scrap_trader` | 39 | 66 | 88 | 105 |
| `solar_tech` | 37 | 55 | 102 | 104 |

Every customer can reach DELIGHTED.

## Concentration

**Dominant dishes** — one recipe satisfying more than half the roster (more than 4 of 8) would make the pantry a lookup table.

No dish satisfies more than 4 of 8 customers.

**Load-bearing ingredients** — an ingredient present in *every* satisfying dish for a customer is one that customer cannot be served without. More than 4 of 8 customers depending on the same ingredient is the illusory-choice risk in GDD section 5.

No ingredient is required by any customer's whole satisfying set.

## Constraint integrity

A constraint is load-bearing when removing it changes some dish's band. One that changes nothing is flavour text in a mechanic's clothes: it reads as a boundary, and the player can never cross it.

| Customer | Constraint | Dishes engaging it | Bands changed | Rule |
| --- | --- | --- | --- | --- |
| `block_boss` | FORBID_TAG `smoked` | 67 | 67 | PASS |
| `night_courier` | FORBID_TAG `fermented` | 123 | 68 | PASS |
| `old_local` | FORBID_TAG `held` | 67 | 58 | PASS |
| `scrap_trader` | FORBID_TAG `soy` | 67 | 67 | PASS |

Every constraint changes at least one outcome.

## Definitions

**Satisfying** — a dish scoring in DELIGHTED or SATISFIED, so at least 65. A constraint violation caps the score at 39, so a satisfying dish always also respects the customer's boundaries.

**Central ingredient** — the ingredient in a dish with the largest `sum(customer weight × ingredient value)` across the flavour dimensions, ties going to the lowest `content_id`. The GDD requires two satisfying dishes with different central ingredients but never defined central, so the rule was uncheckable until this audit fixed a definition. It is customer-relative on purpose: an ingredient can carry a dish for one customer and be incidental for another.

## Appendix: every dish

Cells are `score BAND`. A trailing `!` marks a constraint violation.

| Dish | block_boss | late_shift_medic | night_courier | office_worker | old_local | rig_partner | scrap_trader | solar_tech |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| chickpeas | 14 DIS | 54 MIX | 29 DIS | 0 DIS | 68 SAT | 0 DIS | 70 SAT | 39 DIS |
| chickpeas + chili_crisp | 57 MIX | 40 MIX | 48 MIX | 0 DIS | 84 SAT | 30 DIS | 70 SAT | 58 MIX |
| chickpeas + chili_crisp + citrus_chili_paste | 66 SAT | 30 DIS | 39 DIS! | 31 DIS | 60 MIX | 55 MIX | 40 MIX | 58 MIX |
| chickpeas + chili_crisp + citrus_herbs | 57 MIX | 50 MIX | 48 MIX | 31 DIS | 60 MIX | 40 MIX | 70 SAT | 58 MIX |
| chickpeas + chili_crisp + coconut_milk | 57 MIX | 27 DIS | 77 SAT | 9 DIS | 72 SAT | 30 DIS | 70 SAT | 86 DEL |
| chickpeas + chili_crisp + kimchi | 79 SAT | 34 DIS | 39 DIS! | 27 DIS | 56 MIX | 45 MIX | 60 MIX | 48 MIX |
| chickpeas + chili_crisp + mushrooms | 83 SAT | 34 DIS | 62 MIX | 0 DIS | 100 DEL | 30 DIS | 90 DEL | 53 MIX |
| chickpeas + chili_crisp + pickled_cucumber | 57 MIX | 60 MIX | 48 MIX | 35 DIS | 72 SAT | 50 MIX | 70 SAT | 58 MIX |
| chickpeas + chili_crisp + rooftop_lettuce | 57 MIX | 70 SAT | 48 MIX | 40 MIX | 84 SAT | 60 MIX | 70 SAT | 58 MIX |
| chickpeas + chili_crisp + smoked_fish | 39 DIS! | 34 DIS | 62 MIX | 0 DIS | 100 DEL | 30 DIS | 90 DEL | 53 MIX |
| chickpeas + chili_crisp + soy_broth | 83 SAT | 27 DIS | 77 SAT | 0 DIS | 100 DEL | 30 DIS | 39 DIS! | 67 SAT |
| chickpeas + chili_crisp + thick_wheat_noodles | 70 SAT | 20 DIS | 91 DEL | 0 DIS | 39 DIS! | 30 DIS | 50 MIX | 91 DEL |
| chickpeas + citrus_chili_paste | 40 MIX | 44 MIX | 39 DIS! | 31 DIS | 44 MIX | 55 MIX | 60 MIX | 39 DIS |
| chickpeas + citrus_chili_paste + citrus_herbs | 40 MIX | 54 MIX | 39 DIS! | 61 MIX | 20 DIS | 65 SAT | 60 MIX | 39 DIS |
| chickpeas + citrus_chili_paste + coconut_milk | 40 MIX | 30 DIS | 39 DIS! | 40 MIX | 32 DIS | 55 MIX | 60 MIX | 67 SAT |
| chickpeas + citrus_chili_paste + kimchi | 61 MIX | 37 DIS | 39 DIS! | 40 MIX | 16 DIS | 70 SAT | 50 MIX | 48 MIX |
| chickpeas + citrus_chili_paste + mushrooms | 66 SAT | 37 DIS | 39 DIS! | 31 DIS | 60 MIX | 55 MIX | 80 SAT | 72 SAT |
| chickpeas + citrus_chili_paste + pickled_cucumber | 40 MIX | 64 MIX | 39 DIS! | 66 SAT | 32 DIS | 75 SAT | 60 MIX | 39 DIS |
| chickpeas + citrus_chili_paste + rooftop_lettuce | 40 MIX | 74 SAT | 39 DIS! | 70 SAT | 44 MIX | 85 DEL | 60 MIX | 39 DIS |
| chickpeas + citrus_chili_paste + smoked_fish | 39 DIS! | 37 DIS | 39 DIS! | 31 DIS | 68 SAT | 55 MIX | 80 SAT | 62 MIX |
| chickpeas + citrus_chili_paste + soy_broth | 66 SAT | 30 DIS | 39 DIS! | 31 DIS | 60 MIX | 55 MIX | 39 DIS! | 86 DEL |
| chickpeas + citrus_chili_paste + thick_wheat_noodles | 53 MIX | 24 DIS | 39 DIS! | 31 DIS | 39 DIS! | 55 MIX | 40 MIX | 91 DEL |
| chickpeas + citrus_herbs | 14 DIS | 64 MIX | 29 DIS | 31 DIS | 44 MIX | 10 DIS | 70 SAT | 39 DIS |
| chickpeas + citrus_herbs + coconut_milk | 14 DIS | 50 MIX | 58 MIX | 40 MIX | 32 DIS | 10 DIS | 70 SAT | 67 SAT |
| chickpeas + citrus_herbs + kimchi | 35 DIS | 57 MIX | 39 DIS! | 40 MIX | 16 DIS | 25 DIS | 80 SAT | 48 MIX |
| chickpeas + citrus_herbs + mushrooms | 40 MIX | 57 MIX | 43 MIX | 31 DIS | 60 MIX | 10 DIS | 90 DEL | 72 SAT |
| chickpeas + citrus_herbs + pickled_cucumber | 14 DIS | 84 SAT | 29 DIS | 66 SAT | 32 DIS | 30 DIS | 70 SAT | 39 DIS |
| chickpeas + citrus_herbs + rooftop_lettuce | 14 DIS | 94 DEL | 29 DIS | 70 SAT | 44 MIX | 40 MIX | 70 SAT | 39 DIS |
| chickpeas + citrus_herbs + smoked_fish | 39 DIS! | 57 MIX | 43 MIX | 31 DIS | 68 SAT | 10 DIS | 90 DEL | 62 MIX |
| chickpeas + citrus_herbs + soy_broth | 40 MIX | 50 MIX | 58 MIX | 31 DIS | 60 MIX | 10 DIS | 39 DIS! | 86 DEL |
| chickpeas + citrus_herbs + thick_wheat_noodles | 27 DIS | 44 MIX | 72 SAT | 31 DIS | 39 DIS! | 10 DIS | 50 MIX | 91 DEL |
| chickpeas + coconut_milk | 14 DIS | 40 MIX | 58 MIX | 9 DIS | 56 MIX | 0 DIS | 70 SAT | 67 SAT |
| chickpeas + coconut_milk + kimchi | 35 DIS | 34 DIS | 39 DIS! | 35 DIS | 28 DIS | 15 DIS | 80 SAT | 77 SAT |
| chickpeas + coconut_milk + mushrooms | 40 MIX | 34 DIS | 72 SAT | 9 DIS | 72 SAT | 0 DIS | 50 MIX | 100 DEL |
| chickpeas + coconut_milk + pickled_cucumber | 14 DIS | 60 MIX | 58 MIX | 44 MIX | 44 MIX | 20 DIS | 70 SAT | 67 SAT |
| chickpeas + coconut_milk + rooftop_lettuce | 14 DIS | 70 SAT | 58 MIX | 48 MIX | 56 MIX | 30 DIS | 70 SAT | 67 SAT |
| chickpeas + coconut_milk + smoked_fish | 39 DIS! | 34 DIS | 72 SAT | 9 DIS | 80 SAT | 0 DIS | 50 MIX | 91 DEL |
| chickpeas + coconut_milk + soy_broth | 40 MIX | 34 DIS | 72 SAT | 9 DIS | 72 SAT | 0 DIS | 39 DIS! | 100 DEL |
| chickpeas + coconut_milk + thick_wheat_noodles | 27 DIS | 34 DIS | 72 SAT | 9 DIS | 39 DIS! | 0 DIS | 50 MIX | 91 DEL |
| chickpeas + kimchi | 35 DIS | 47 MIX | 39 DIS! | 27 DIS | 40 MIX | 15 DIS | 80 SAT | 48 MIX |
| chickpeas + kimchi + mushrooms | 61 MIX | 40 MIX | 39 DIS! | 27 DIS | 56 MIX | 15 DIS | 100 DEL | 62 MIX |
| chickpeas + kimchi + pickled_cucumber | 35 DIS | 67 SAT | 39 DIS! | 61 MIX | 28 DIS | 35 DIS | 80 SAT | 48 MIX |
| chickpeas + kimchi + rooftop_lettuce | 35 DIS | 77 SAT | 39 DIS! | 66 SAT | 40 MIX | 45 MIX | 80 SAT | 48 MIX |
| chickpeas + kimchi + smoked_fish | 39 DIS! | 40 MIX | 39 DIS! | 27 DIS | 64 MIX | 15 DIS | 100 DEL | 53 MIX |
| chickpeas + kimchi + soy_broth | 61 MIX | 34 DIS | 39 DIS! | 27 DIS | 56 MIX | 15 DIS | 39 DIS! | 77 SAT |
| chickpeas + kimchi + thick_wheat_noodles | 48 MIX | 27 DIS | 39 DIS! | 27 DIS | 39 DIS! | 15 DIS | 60 MIX | 100 DEL |
| chickpeas + mushrooms | 40 MIX | 47 MIX | 43 MIX | 0 DIS | 84 SAT | 0 DIS | 90 DEL | 72 SAT |
| chickpeas + mushrooms + pickled_cucumber | 40 MIX | 67 SAT | 43 MIX | 35 DIS | 72 SAT | 20 DIS | 90 DEL | 72 SAT |
| chickpeas + mushrooms + rooftop_lettuce | 40 MIX | 77 SAT | 43 MIX | 40 MIX | 84 SAT | 30 DIS | 90 DEL | 72 SAT |
| chickpeas + mushrooms + smoked_fish | 39 DIS! | 40 MIX | 58 MIX | 0 DIS | 100 DEL | 0 DIS | 70 SAT | 67 SAT |
| chickpeas + mushrooms + soy_broth | 66 SAT | 34 DIS | 72 SAT | 0 DIS | 100 DEL | 0 DIS | 39 DIS! | 81 SAT |
| chickpeas + mushrooms + thick_wheat_noodles | 53 MIX | 34 DIS | 72 SAT | 0 DIS | 39 DIS! | 0 DIS | 50 MIX | 91 DEL |
| chickpeas + pickled_cucumber | 14 DIS | 74 SAT | 29 DIS | 35 DIS | 56 MIX | 20 DIS | 70 SAT | 39 DIS |
| chickpeas + pickled_cucumber + rooftop_lettuce | 14 DIS | 84 SAT | 29 DIS | 74 SAT | 56 MIX | 30 DIS | 70 SAT | 39 DIS |
| chickpeas + pickled_cucumber + smoked_fish | 39 DIS! | 67 SAT | 43 MIX | 35 DIS | 80 SAT | 20 DIS | 90 DEL | 62 MIX |
| chickpeas + pickled_cucumber + soy_broth | 40 MIX | 60 MIX | 58 MIX | 35 DIS | 72 SAT | 20 DIS | 39 DIS! | 86 DEL |
| chickpeas + pickled_cucumber + thick_wheat_noodles | 27 DIS | 54 MIX | 72 SAT | 35 DIS | 39 DIS! | 20 DIS | 50 MIX | 91 DEL |
| chickpeas + rooftop_lettuce | 14 DIS | 84 SAT | 29 DIS | 40 MIX | 68 SAT | 30 DIS | 70 SAT | 39 DIS |
| chickpeas + rooftop_lettuce + smoked_fish | 39 DIS! | 77 SAT | 43 MIX | 40 MIX | 92 DEL | 30 DIS | 90 DEL | 62 MIX |
| chickpeas + rooftop_lettuce + soy_broth | 40 MIX | 70 SAT | 58 MIX | 40 MIX | 84 SAT | 30 DIS | 39 DIS! | 86 DEL |
| chickpeas + rooftop_lettuce + thick_wheat_noodles | 27 DIS | 64 MIX | 72 SAT | 40 MIX | 39 DIS! | 30 DIS | 50 MIX | 91 DEL |
| chickpeas + smoked_fish | 39 DIS! | 47 MIX | 43 MIX | 0 DIS | 92 DEL | 0 DIS | 90 DEL | 62 MIX |
| chickpeas + smoked_fish + soy_broth | 39 DIS! | 34 DIS | 72 SAT | 0 DIS | 100 DEL | 0 DIS | 39 DIS! | 81 SAT |
| chickpeas + smoked_fish + thick_wheat_noodles | 39 DIS! | 34 DIS | 72 SAT | 0 DIS | 39 DIS! | 0 DIS | 50 MIX | 81 SAT |
| chickpeas + soy_broth | 40 MIX | 40 MIX | 58 MIX | 0 DIS | 84 SAT | 0 DIS | 39 DIS! | 86 DEL |
| chickpeas + soy_broth + thick_wheat_noodles | 53 MIX | 34 DIS | 72 SAT | 0 DIS | 39 DIS! | 0 DIS | 39 DIS! | 91 DEL |
| chickpeas + thick_wheat_noodles | 27 DIS | 34 DIS | 72 SAT | 0 DIS | 39 DIS! | 0 DIS | 50 MIX | 91 DEL |
| chili_crisp | 44 MIX | 40 MIX | 20 DIS | 0 DIS | 76 SAT | 30 DIS | 30 DIS | 20 DIS |
| chili_crisp + citrus_chili_paste | 53 MIX | 30 DIS | 10 DIS! | 31 DIS | 52 MIX | 55 MIX | 0 DIS | 20 DIS |
| chili_crisp + citrus_chili_paste + citrus_herbs | 53 MIX | 40 MIX | 10 DIS! | 61 MIX | 28 DIS | 65 SAT | 0 DIS | 20 DIS |
| chili_crisp + citrus_chili_paste + coconut_milk | 53 MIX | 30 DIS | 39 DIS! | 40 MIX | 40 MIX | 55 MIX | 40 MIX | 48 MIX |
| chili_crisp + citrus_chili_paste + kimchi | 66 SAT | 30 DIS | 10 DIS! | 40 MIX | 24 DIS | 55 MIX | 0 DIS | 29 DIS |
| chili_crisp + citrus_chili_paste + mushrooms | 79 SAT | 37 DIS | 24 DIS! | 31 DIS | 68 SAT | 55 MIX | 20 DIS | 34 DIS |
| chili_crisp + citrus_chili_paste + pickled_cucumber | 53 MIX | 50 MIX | 10 DIS! | 66 SAT | 40 MIX | 75 SAT | 0 DIS | 20 DIS |
| chili_crisp + citrus_chili_paste + rooftop_lettuce | 53 MIX | 60 MIX | 10 DIS! | 70 SAT | 52 MIX | 85 DEL | 0 DIS | 20 DIS |
| chili_crisp + citrus_chili_paste + smoked_fish | 39 DIS! | 37 DIS | 24 DIS! | 31 DIS | 76 SAT | 55 MIX | 20 DIS | 24 DIS |
| chili_crisp + citrus_chili_paste + soy_broth | 79 SAT | 30 DIS | 39 DIS! | 31 DIS | 68 SAT | 55 MIX | 39 DIS! | 48 MIX |
| chili_crisp + citrus_chili_paste + thick_wheat_noodles | 66 SAT | 24 DIS | 39 DIS! | 31 DIS | 39 DIS! | 55 MIX | 60 MIX | 72 SAT |
| chili_crisp + citrus_herbs | 44 MIX | 50 MIX | 20 DIS | 31 DIS | 52 MIX | 40 MIX | 30 DIS | 20 DIS |
| chili_crisp + citrus_herbs + coconut_milk | 44 MIX | 50 MIX | 48 MIX | 40 MIX | 40 MIX | 40 MIX | 70 SAT | 48 MIX |
| chili_crisp + citrus_herbs + kimchi | 66 SAT | 44 MIX | 29 DIS! | 40 MIX | 24 DIS | 55 MIX | 20 DIS | 29 DIS |
| chili_crisp + citrus_herbs + mushrooms | 70 SAT | 57 MIX | 34 DIS | 31 DIS | 68 SAT | 40 MIX | 50 MIX | 34 DIS |
| chili_crisp + citrus_herbs + pickled_cucumber | 44 MIX | 70 SAT | 20 DIS | 66 SAT | 40 MIX | 60 MIX | 30 DIS | 20 DIS |
| chili_crisp + citrus_herbs + rooftop_lettuce | 44 MIX | 80 SAT | 20 DIS | 70 SAT | 52 MIX | 70 SAT | 30 DIS | 20 DIS |
| chili_crisp + citrus_herbs + smoked_fish | 39 DIS! | 57 MIX | 34 DIS | 31 DIS | 76 SAT | 40 MIX | 50 MIX | 24 DIS |
| chili_crisp + citrus_herbs + soy_broth | 70 SAT | 50 MIX | 48 MIX | 31 DIS | 68 SAT | 40 MIX | 39 DIS! | 48 MIX |
| chili_crisp + citrus_herbs + thick_wheat_noodles | 57 MIX | 44 MIX | 62 MIX | 31 DIS | 39 DIS! | 40 MIX | 90 DEL | 72 SAT |
| chili_crisp + coconut_milk | 44 MIX | 40 MIX | 48 MIX | 9 DIS | 64 MIX | 30 DIS | 70 SAT | 48 MIX |
| chili_crisp + coconut_milk + kimchi | 66 SAT | 34 DIS | 39 DIS! | 35 DIS | 36 DIS | 45 MIX | 60 MIX | 58 MIX |
| chili_crisp + coconut_milk + mushrooms | 70 SAT | 34 DIS | 62 MIX | 9 DIS | 80 SAT | 30 DIS | 90 DEL | 62 MIX |
| chili_crisp + coconut_milk + pickled_cucumber | 44 MIX | 60 MIX | 48 MIX | 44 MIX | 52 MIX | 50 MIX | 70 SAT | 48 MIX |
| chili_crisp + coconut_milk + rooftop_lettuce | 44 MIX | 70 SAT | 48 MIX | 48 MIX | 64 MIX | 60 MIX | 70 SAT | 48 MIX |
| chili_crisp + coconut_milk + smoked_fish | 39 DIS! | 34 DIS | 62 MIX | 9 DIS | 88 DEL | 30 DIS | 90 DEL | 53 MIX |
| chili_crisp + coconut_milk + soy_broth | 70 SAT | 27 DIS | 77 SAT | 9 DIS | 80 SAT | 30 DIS | 39 DIS! | 77 SAT |
| chili_crisp + coconut_milk + thick_wheat_noodles | 57 MIX | 20 DIS | 91 DEL | 9 DIS | 39 DIS! | 30 DIS | 50 MIX | 100 DEL |
| chili_crisp + kimchi | 66 SAT | 34 DIS | 29 DIS! | 27 DIS | 48 MIX | 45 MIX | 20 DIS | 29 DIS |
| chili_crisp + kimchi + mushrooms | 92 DEL | 40 MIX | 39 DIS! | 27 DIS | 64 MIX | 45 MIX | 40 MIX | 24 DIS |
| chili_crisp + kimchi + pickled_cucumber | 66 SAT | 54 MIX | 29 DIS! | 61 MIX | 36 DIS | 65 SAT | 20 DIS | 29 DIS |
| chili_crisp + kimchi + rooftop_lettuce | 66 SAT | 64 MIX | 29 DIS! | 66 SAT | 48 MIX | 75 SAT | 20 DIS | 29 DIS |
| chili_crisp + kimchi + smoked_fish | 39 DIS! | 40 MIX | 39 DIS! | 27 DIS | 64 MIX | 45 MIX | 40 MIX | 24 DIS |
| chili_crisp + kimchi + soy_broth | 92 DEL | 34 DIS | 39 DIS! | 27 DIS | 64 MIX | 45 MIX | 39 DIS! | 39 DIS |
| chili_crisp + kimchi + thick_wheat_noodles | 79 SAT | 27 DIS | 39 DIS! | 27 DIS | 39 DIS! | 45 MIX | 80 SAT | 62 MIX |
| chili_crisp + mushrooms | 70 SAT | 47 MIX | 34 DIS | 0 DIS | 92 DEL | 30 DIS | 50 MIX | 34 DIS |
| chili_crisp + mushrooms + pickled_cucumber | 70 SAT | 67 SAT | 34 DIS | 35 DIS | 80 SAT | 50 MIX | 50 MIX | 34 DIS |
| chili_crisp + mushrooms + rooftop_lettuce | 70 SAT | 77 SAT | 34 DIS | 40 MIX | 92 DEL | 60 MIX | 50 MIX | 34 DIS |
| chili_crisp + mushrooms + smoked_fish | 39 DIS! | 40 MIX | 48 MIX | 0 DIS | 100 DEL | 30 DIS | 70 SAT | 39 DIS |
| chili_crisp + mushrooms + soy_broth | 83 SAT | 34 DIS | 62 MIX | 0 DIS | 100 DEL | 30 DIS | 39 DIS! | 53 MIX |
| chili_crisp + mushrooms + thick_wheat_noodles | 83 SAT | 27 DIS | 77 SAT | 0 DIS | 39 DIS! | 30 DIS | 70 SAT | 67 SAT |
| chili_crisp + pickled_cucumber | 44 MIX | 60 MIX | 20 DIS | 35 DIS | 64 MIX | 50 MIX | 30 DIS | 20 DIS |
| chili_crisp + pickled_cucumber + rooftop_lettuce | 44 MIX | 70 SAT | 20 DIS | 74 SAT | 64 MIX | 60 MIX | 30 DIS | 20 DIS |
| chili_crisp + pickled_cucumber + smoked_fish | 39 DIS! | 67 SAT | 34 DIS | 35 DIS | 88 DEL | 50 MIX | 50 MIX | 24 DIS |
| chili_crisp + pickled_cucumber + soy_broth | 70 SAT | 60 MIX | 48 MIX | 35 DIS | 80 SAT | 50 MIX | 39 DIS! | 48 MIX |
| chili_crisp + pickled_cucumber + thick_wheat_noodles | 57 MIX | 54 MIX | 62 MIX | 35 DIS | 39 DIS! | 50 MIX | 90 DEL | 72 SAT |
| chili_crisp + rooftop_lettuce | 44 MIX | 70 SAT | 20 DIS | 40 MIX | 76 SAT | 60 MIX | 30 DIS | 20 DIS |
| chili_crisp + rooftop_lettuce + smoked_fish | 39 DIS! | 77 SAT | 34 DIS | 40 MIX | 100 DEL | 60 MIX | 50 MIX | 24 DIS |
| chili_crisp + rooftop_lettuce + soy_broth | 70 SAT | 70 SAT | 48 MIX | 40 MIX | 92 DEL | 60 MIX | 39 DIS! | 48 MIX |
| chili_crisp + rooftop_lettuce + thick_wheat_noodles | 57 MIX | 64 MIX | 62 MIX | 40 MIX | 39 DIS! | 60 MIX | 90 DEL | 72 SAT |
| chili_crisp + smoked_fish | 39 DIS! | 47 MIX | 34 DIS | 0 DIS | 100 DEL | 30 DIS | 50 MIX | 24 DIS |
| chili_crisp + smoked_fish + soy_broth | 39 DIS! | 34 DIS | 62 MIX | 0 DIS | 100 DEL | 30 DIS | 39 DIS! | 53 MIX |
| chili_crisp + smoked_fish + thick_wheat_noodles | 39 DIS! | 27 DIS | 77 SAT | 0 DIS | 39 DIS! | 30 DIS | 70 SAT | 67 SAT |
| chili_crisp + soy_broth | 70 SAT | 40 MIX | 48 MIX | 0 DIS | 92 DEL | 30 DIS | 39 DIS! | 48 MIX |
| chili_crisp + soy_broth + thick_wheat_noodles | 83 SAT | 20 DIS | 91 DEL | 0 DIS | 39 DIS! | 30 DIS | 39 DIS! | 81 SAT |
| chili_crisp + thick_wheat_noodles | 57 MIX | 34 DIS | 62 MIX | 0 DIS | 39 DIS! | 30 DIS | 90 DEL | 72 SAT |
| citrus_chili_paste | 27 DIS | 44 MIX | 29 DIS! | 31 DIS | 36 DIS | 55 MIX | 20 DIS | 0 DIS |
| citrus_chili_paste + citrus_herbs | 27 DIS | 54 MIX | 29 DIS! | 61 MIX | 12 DIS | 65 SAT | 20 DIS | 0 DIS |
| citrus_chili_paste + citrus_herbs + coconut_milk | 27 DIS | 54 MIX | 39 DIS! | 53 MIX | 0 DIS | 65 SAT | 60 MIX | 29 DIS |
| citrus_chili_paste + citrus_herbs + kimchi | 48 MIX | 47 MIX | 20 DIS! | 53 MIX | 8 DIS | 80 SAT | 10 DIS | 10 DIS |
| citrus_chili_paste + citrus_herbs + mushrooms | 53 MIX | 60 MIX | 39 DIS! | 61 MIX | 28 DIS | 65 SAT | 40 MIX | 34 DIS |
| citrus_chili_paste + citrus_herbs + pickled_cucumber | 27 DIS | 74 SAT | 29 DIS! | 79 SAT | 0 DIS | 85 DEL | 20 DIS | 0 DIS |
| citrus_chili_paste + citrus_herbs + rooftop_lettuce | 27 DIS | 64 MIX | 29 DIS! | 100 DEL | 12 DIS | 75 SAT | 20 DIS | 0 DIS |
| citrus_chili_paste + citrus_herbs + smoked_fish | 39 DIS! | 60 MIX | 39 DIS! | 61 MIX | 36 DIS | 65 SAT | 40 MIX | 43 MIX |
| citrus_chili_paste + citrus_herbs + soy_broth | 53 MIX | 54 MIX | 39 DIS! | 61 MIX | 28 DIS | 65 SAT | 39 DIS! | 48 MIX |
| citrus_chili_paste + citrus_herbs + thick_wheat_noodles | 40 MIX | 47 MIX | 39 DIS! | 61 MIX | 20 DIS! | 65 SAT | 80 SAT | 53 MIX |
| citrus_chili_paste + coconut_milk | 27 DIS | 44 MIX | 39 DIS! | 40 MIX | 24 DIS | 55 MIX | 60 MIX | 29 DIS |
| citrus_chili_paste + coconut_milk + kimchi | 48 MIX | 37 DIS | 39 DIS! | 40 MIX | 8 DIS | 70 SAT | 50 MIX | 39 DIS |
| citrus_chili_paste + coconut_milk + mushrooms | 53 MIX | 37 DIS | 39 DIS! | 40 MIX | 40 MIX | 55 MIX | 80 SAT | 62 MIX |
| citrus_chili_paste + coconut_milk + pickled_cucumber | 27 DIS | 64 MIX | 39 DIS! | 74 SAT | 12 DIS | 75 SAT | 60 MIX | 29 DIS |
| citrus_chili_paste + coconut_milk + rooftop_lettuce | 27 DIS | 74 SAT | 39 DIS! | 79 SAT | 24 DIS | 85 DEL | 60 MIX | 29 DIS |
| citrus_chili_paste + coconut_milk + smoked_fish | 39 DIS! | 37 DIS | 39 DIS! | 40 MIX | 48 MIX | 55 MIX | 80 SAT | 72 SAT |
| citrus_chili_paste + coconut_milk + soy_broth | 53 MIX | 30 DIS | 39 DIS! | 40 MIX | 40 MIX | 55 MIX | 39 DIS! | 77 SAT |
| citrus_chili_paste + coconut_milk + thick_wheat_noodles | 40 MIX | 24 DIS | 39 DIS! | 40 MIX | 32 DIS! | 55 MIX | 40 MIX | 81 SAT |
| citrus_chili_paste + kimchi | 48 MIX | 37 DIS | 20 DIS! | 40 MIX | 8 DIS | 70 SAT | 10 DIS | 10 DIS |
| citrus_chili_paste + kimchi + mushrooms | 74 SAT | 44 MIX | 34 DIS! | 40 MIX | 24 DIS | 70 SAT | 30 DIS | 43 MIX |
| citrus_chili_paste + kimchi + pickled_cucumber | 48 MIX | 57 MIX | 20 DIS! | 66 SAT | 8 DIS | 90 DEL | 10 DIS | 10 DIS |
| citrus_chili_paste + kimchi + rooftop_lettuce | 48 MIX | 67 SAT | 20 DIS! | 79 SAT | 8 DIS | 100 DEL | 10 DIS | 10 DIS |
| citrus_chili_paste + kimchi + smoked_fish | 39 DIS! | 44 MIX | 34 DIS! | 40 MIX | 32 DIS | 70 SAT | 30 DIS | 34 DIS |
| citrus_chili_paste + kimchi + soy_broth | 74 SAT | 37 DIS | 39 DIS! | 40 MIX | 24 DIS | 70 SAT | 39 DIS! | 58 MIX |
| citrus_chili_paste + kimchi + thick_wheat_noodles | 61 MIX | 30 DIS | 39 DIS! | 40 MIX | 16 DIS! | 70 SAT | 70 SAT | 62 MIX |
| citrus_chili_paste + mushrooms | 53 MIX | 50 MIX | 39 DIS! | 31 DIS | 52 MIX | 55 MIX | 40 MIX | 34 DIS |
| citrus_chili_paste + mushrooms + pickled_cucumber | 53 MIX | 70 SAT | 39 DIS! | 66 SAT | 40 MIX | 75 SAT | 40 MIX | 34 DIS |
| citrus_chili_paste + mushrooms + rooftop_lettuce | 53 MIX | 80 SAT | 39 DIS! | 70 SAT | 52 MIX | 85 DEL | 40 MIX | 34 DIS |
| citrus_chili_paste + mushrooms + smoked_fish | 39 DIS! | 44 MIX | 39 DIS! | 31 DIS | 76 SAT | 55 MIX | 60 MIX | 39 DIS |
| citrus_chili_paste + mushrooms + soy_broth | 79 SAT | 37 DIS | 39 DIS! | 31 DIS | 68 SAT | 55 MIX | 39 DIS! | 62 MIX |
| citrus_chili_paste + mushrooms + thick_wheat_noodles | 66 SAT | 30 DIS | 39 DIS! | 31 DIS | 39 DIS! | 55 MIX | 60 MIX | 86 DEL |
| citrus_chili_paste + pickled_cucumber | 27 DIS | 64 MIX | 29 DIS! | 66 SAT | 24 DIS | 75 SAT | 20 DIS | 0 DIS |
| citrus_chili_paste + pickled_cucumber + rooftop_lettuce | 27 DIS | 64 MIX | 29 DIS! | 92 DEL | 24 DIS | 75 SAT | 20 DIS | 0 DIS |
| citrus_chili_paste + pickled_cucumber + smoked_fish | 39 DIS! | 70 SAT | 39 DIS! | 66 SAT | 48 MIX | 75 SAT | 40 MIX | 43 MIX |
| citrus_chili_paste + pickled_cucumber + soy_broth | 53 MIX | 64 MIX | 39 DIS! | 66 SAT | 40 MIX | 75 SAT | 39 DIS! | 48 MIX |
| citrus_chili_paste + pickled_cucumber + thick_wheat_noodles | 40 MIX | 57 MIX | 39 DIS! | 66 SAT | 32 DIS! | 75 SAT | 80 SAT | 53 MIX |
| citrus_chili_paste + rooftop_lettuce | 27 DIS | 74 SAT | 29 DIS! | 70 SAT | 36 DIS | 85 DEL | 20 DIS | 0 DIS |
| citrus_chili_paste + rooftop_lettuce + smoked_fish | 39 DIS! | 80 SAT | 39 DIS! | 70 SAT | 60 MIX | 85 DEL | 40 MIX | 43 MIX |
| citrus_chili_paste + rooftop_lettuce + soy_broth | 53 MIX | 74 SAT | 39 DIS! | 70 SAT | 52 MIX | 85 DEL | 39 DIS! | 48 MIX |
| citrus_chili_paste + rooftop_lettuce + thick_wheat_noodles | 40 MIX | 67 SAT | 39 DIS! | 70 SAT | 39 DIS! | 85 DEL | 80 SAT | 53 MIX |
| citrus_chili_paste + smoked_fish | 39 DIS! | 50 MIX | 39 DIS! | 31 DIS | 60 MIX | 55 MIX | 40 MIX | 43 MIX |
| citrus_chili_paste + smoked_fish + soy_broth | 39 DIS! | 37 DIS | 39 DIS! | 31 DIS | 76 SAT | 55 MIX | 39 DIS! | 53 MIX |
| citrus_chili_paste + smoked_fish + thick_wheat_noodles | 39 DIS! | 30 DIS | 39 DIS! | 31 DIS | 39 DIS! | 55 MIX | 60 MIX | 77 SAT |
| citrus_chili_paste + soy_broth | 53 MIX | 44 MIX | 39 DIS! | 31 DIS | 52 MIX | 55 MIX | 39 DIS! | 48 MIX |
| citrus_chili_paste + soy_broth + thick_wheat_noodles | 66 SAT | 24 DIS | 39 DIS! | 31 DIS | 39 DIS! | 55 MIX | 39 DIS! | 100 DEL |
| citrus_chili_paste + thick_wheat_noodles | 40 MIX | 37 DIS | 39 DIS! | 31 DIS | 39 DIS! | 55 MIX | 80 SAT | 53 MIX |
| citrus_herbs | 0 DIS | 64 MIX | 0 DIS | 31 DIS | 36 DIS | 10 DIS | 30 DIS | 0 DIS |
| citrus_herbs + coconut_milk | 0 DIS | 64 MIX | 29 DIS | 40 MIX | 24 DIS | 10 DIS | 70 SAT | 29 DIS |
| citrus_herbs + coconut_milk + kimchi | 22 DIS | 57 MIX | 39 DIS! | 40 MIX | 8 DIS | 25 DIS | 80 SAT | 39 DIS |
| citrus_herbs + coconut_milk + mushrooms | 27 DIS | 57 MIX | 43 MIX | 40 MIX | 40 MIX | 10 DIS | 90 DEL | 62 MIX |
| citrus_herbs + coconut_milk + pickled_cucumber | 0 DIS | 84 SAT | 29 DIS | 74 SAT | 12 DIS | 30 DIS | 70 SAT | 29 DIS |
| citrus_herbs + coconut_milk + rooftop_lettuce | 0 DIS | 94 DEL | 29 DIS | 79 SAT | 24 DIS | 40 MIX | 70 SAT | 29 DIS |
| citrus_herbs + coconut_milk + smoked_fish | 39 DIS! | 57 MIX | 43 MIX | 40 MIX | 48 MIX | 10 DIS | 90 DEL | 72 SAT |
| citrus_herbs + coconut_milk + soy_broth | 27 DIS | 50 MIX | 58 MIX | 40 MIX | 40 MIX | 10 DIS | 39 DIS! | 77 SAT |
| citrus_herbs + coconut_milk + thick_wheat_noodles | 14 DIS | 44 MIX | 72 SAT | 40 MIX | 32 DIS! | 10 DIS | 50 MIX | 81 SAT |
| citrus_herbs + kimchi | 22 DIS | 57 MIX | 10 DIS! | 40 MIX | 8 DIS | 25 DIS | 40 MIX | 10 DIS |
| citrus_herbs + kimchi + mushrooms | 48 MIX | 64 MIX | 24 DIS! | 40 MIX | 24 DIS | 25 DIS | 60 MIX | 43 MIX |
| citrus_herbs + kimchi + pickled_cucumber | 22 DIS | 77 SAT | 10 DIS! | 66 SAT | 8 DIS | 45 MIX | 40 MIX | 10 DIS |
| citrus_herbs + kimchi + rooftop_lettuce | 22 DIS | 87 DEL | 10 DIS! | 79 SAT | 8 DIS | 55 MIX | 40 MIX | 10 DIS |
| citrus_herbs + kimchi + smoked_fish | 39 DIS! | 64 MIX | 24 DIS! | 40 MIX | 32 DIS | 25 DIS | 60 MIX | 34 DIS |
| citrus_herbs + kimchi + soy_broth | 48 MIX | 57 MIX | 39 DIS! | 40 MIX | 24 DIS | 25 DIS | 39 DIS! | 58 MIX |
| citrus_herbs + kimchi + thick_wheat_noodles | 35 DIS | 50 MIX | 39 DIS! | 40 MIX | 16 DIS! | 25 DIS | 100 DEL | 62 MIX |
| citrus_herbs + mushrooms | 27 DIS | 70 SAT | 15 DIS | 31 DIS | 52 MIX | 10 DIS | 50 MIX | 34 DIS |
| citrus_herbs + mushrooms + pickled_cucumber | 27 DIS | 90 DEL | 15 DIS | 66 SAT | 40 MIX | 30 DIS | 50 MIX | 34 DIS |
| citrus_herbs + mushrooms + rooftop_lettuce | 27 DIS | 100 DEL | 15 DIS | 70 SAT | 52 MIX | 40 MIX | 50 MIX | 34 DIS |
| citrus_herbs + mushrooms + smoked_fish | 39 DIS! | 64 MIX | 29 DIS | 31 DIS | 76 SAT | 10 DIS | 70 SAT | 39 DIS |
| citrus_herbs + mushrooms + soy_broth | 53 MIX | 57 MIX | 43 MIX | 31 DIS | 68 SAT | 10 DIS | 39 DIS! | 62 MIX |
| citrus_herbs + mushrooms + thick_wheat_noodles | 40 MIX | 50 MIX | 58 MIX | 31 DIS | 39 DIS! | 10 DIS | 70 SAT | 86 DEL |
| citrus_herbs + pickled_cucumber | 0 DIS | 84 SAT | 0 DIS | 66 SAT | 24 DIS | 30 DIS | 30 DIS | 0 DIS |
| citrus_herbs + pickled_cucumber + rooftop_lettuce | 0 DIS | 84 SAT | 0 DIS | 92 DEL | 24 DIS | 30 DIS | 30 DIS | 0 DIS |
| citrus_herbs + pickled_cucumber + smoked_fish | 39 DIS! | 90 DEL | 15 DIS | 66 SAT | 48 MIX | 30 DIS | 50 MIX | 43 MIX |
| citrus_herbs + pickled_cucumber + soy_broth | 27 DIS | 84 SAT | 29 DIS | 66 SAT | 40 MIX | 30 DIS | 39 DIS! | 48 MIX |
| citrus_herbs + pickled_cucumber + thick_wheat_noodles | 14 DIS | 77 SAT | 43 MIX | 66 SAT | 32 DIS! | 30 DIS | 90 DEL | 53 MIX |
| citrus_herbs + rooftop_lettuce | 0 DIS | 94 DEL | 0 DIS | 70 SAT | 36 DIS | 40 MIX | 30 DIS | 0 DIS |
| citrus_herbs + rooftop_lettuce + smoked_fish | 39 DIS! | 100 DEL | 15 DIS | 70 SAT | 60 MIX | 40 MIX | 50 MIX | 43 MIX |
| citrus_herbs + rooftop_lettuce + soy_broth | 27 DIS | 94 DEL | 29 DIS | 70 SAT | 52 MIX | 40 MIX | 39 DIS! | 48 MIX |
| citrus_herbs + rooftop_lettuce + thick_wheat_noodles | 14 DIS | 87 DEL | 43 MIX | 70 SAT | 39 DIS! | 40 MIX | 90 DEL | 53 MIX |
| citrus_herbs + smoked_fish | 39 DIS! | 70 SAT | 15 DIS | 31 DIS | 60 MIX | 10 DIS | 50 MIX | 43 MIX |
| citrus_herbs + smoked_fish + soy_broth | 39 DIS! | 57 MIX | 43 MIX | 31 DIS | 76 SAT | 10 DIS | 39 DIS! | 53 MIX |
| citrus_herbs + smoked_fish + thick_wheat_noodles | 39 DIS! | 50 MIX | 58 MIX | 31 DIS | 39 DIS! | 10 DIS | 70 SAT | 77 SAT |
| citrus_herbs + soy_broth | 27 DIS | 64 MIX | 29 DIS | 31 DIS | 52 MIX | 10 DIS | 39 DIS! | 48 MIX |
| citrus_herbs + soy_broth + thick_wheat_noodles | 40 MIX | 44 MIX | 72 SAT | 31 DIS | 39 DIS! | 10 DIS | 39 DIS! | 100 DEL |
| citrus_herbs + thick_wheat_noodles | 14 DIS | 57 MIX | 43 MIX | 31 DIS | 39 DIS! | 10 DIS | 90 DEL | 53 MIX |
| coconut_milk | 0 DIS | 54 MIX | 29 DIS | 9 DIS | 48 MIX | 0 DIS | 70 SAT | 29 DIS |
| coconut_milk + kimchi | 22 DIS | 47 MIX | 39 DIS! | 35 DIS | 20 DIS | 15 DIS | 80 SAT | 39 DIS |
| coconut_milk + kimchi + mushrooms | 48 MIX | 40 MIX | 39 DIS! | 35 DIS | 36 DIS | 15 DIS | 100 DEL | 72 SAT |
| coconut_milk + kimchi + pickled_cucumber | 22 DIS | 67 SAT | 39 DIS! | 53 MIX | 8 DIS | 35 DIS | 80 SAT | 39 DIS |
| coconut_milk + kimchi + rooftop_lettuce | 22 DIS | 77 SAT | 39 DIS! | 74 SAT | 20 DIS | 45 MIX | 80 SAT | 39 DIS |
| coconut_milk + kimchi + smoked_fish | 39 DIS! | 40 MIX | 39 DIS! | 35 DIS | 44 MIX | 15 DIS | 100 DEL | 62 MIX |
| coconut_milk + kimchi + soy_broth | 48 MIX | 34 DIS | 39 DIS! | 35 DIS | 36 DIS | 15 DIS | 39 DIS! | 86 DEL |
| coconut_milk + kimchi + thick_wheat_noodles | 35 DIS | 27 DIS | 39 DIS! | 35 DIS | 28 DIS! | 15 DIS | 60 MIX | 91 DEL |
| coconut_milk + mushrooms | 27 DIS | 47 MIX | 43 MIX | 9 DIS | 64 MIX | 0 DIS | 90 DEL | 62 MIX |
| coconut_milk + mushrooms + pickled_cucumber | 27 DIS | 67 SAT | 43 MIX | 44 MIX | 52 MIX | 20 DIS | 90 DEL | 62 MIX |
| coconut_milk + mushrooms + rooftop_lettuce | 27 DIS | 77 SAT | 43 MIX | 48 MIX | 64 MIX | 30 DIS | 90 DEL | 62 MIX |
| coconut_milk + mushrooms + smoked_fish | 39 DIS! | 40 MIX | 58 MIX | 9 DIS | 88 DEL | 0 DIS | 70 SAT | 67 SAT |
| coconut_milk + mushrooms + soy_broth | 53 MIX | 34 DIS | 72 SAT | 9 DIS | 80 SAT | 0 DIS | 39 DIS! | 91 DEL |
| coconut_milk + mushrooms + thick_wheat_noodles | 40 MIX | 34 DIS | 72 SAT | 9 DIS | 39 DIS! | 0 DIS | 50 MIX | 100 DEL |
| coconut_milk + pickled_cucumber | 0 DIS | 74 SAT | 29 DIS | 44 MIX | 36 DIS | 20 DIS | 70 SAT | 29 DIS |
| coconut_milk + pickled_cucumber + rooftop_lettuce | 0 DIS | 84 SAT | 29 DIS | 83 SAT | 36 DIS | 30 DIS | 70 SAT | 29 DIS |
| coconut_milk + pickled_cucumber + smoked_fish | 39 DIS! | 67 SAT | 43 MIX | 44 MIX | 60 MIX | 20 DIS | 90 DEL | 72 SAT |
| coconut_milk + pickled_cucumber + soy_broth | 27 DIS | 60 MIX | 58 MIX | 44 MIX | 52 MIX | 20 DIS | 39 DIS! | 77 SAT |
| coconut_milk + pickled_cucumber + thick_wheat_noodles | 14 DIS | 54 MIX | 72 SAT | 44 MIX | 39 DIS! | 20 DIS | 50 MIX | 81 SAT |
| coconut_milk + rooftop_lettuce | 0 DIS | 84 SAT | 29 DIS | 48 MIX | 48 MIX | 30 DIS | 70 SAT | 29 DIS |
| coconut_milk + rooftop_lettuce + smoked_fish | 39 DIS! | 77 SAT | 43 MIX | 48 MIX | 72 SAT | 30 DIS | 90 DEL | 72 SAT |
| coconut_milk + rooftop_lettuce + soy_broth | 27 DIS | 70 SAT | 58 MIX | 48 MIX | 64 MIX | 30 DIS | 39 DIS! | 77 SAT |
| coconut_milk + rooftop_lettuce + thick_wheat_noodles | 14 DIS | 64 MIX | 72 SAT | 48 MIX | 39 DIS! | 30 DIS | 50 MIX | 81 SAT |
| coconut_milk + smoked_fish | 39 DIS! | 47 MIX | 43 MIX | 9 DIS | 72 SAT | 0 DIS | 90 DEL | 72 SAT |
| coconut_milk + smoked_fish + soy_broth | 39 DIS! | 34 DIS | 72 SAT | 9 DIS | 88 DEL | 0 DIS | 39 DIS! | 81 SAT |
| coconut_milk + smoked_fish + thick_wheat_noodles | 39 DIS! | 34 DIS | 72 SAT | 9 DIS | 39 DIS! | 0 DIS | 50 MIX | 91 DEL |
| coconut_milk + soy_broth | 27 DIS | 40 MIX | 58 MIX | 9 DIS | 64 MIX | 0 DIS | 39 DIS! | 77 SAT |
| coconut_milk + soy_broth + thick_wheat_noodles | 40 MIX | 34 DIS | 72 SAT | 9 DIS | 39 DIS! | 0 DIS | 39 DIS! | 100 DEL |
| coconut_milk + thick_wheat_noodles | 14 DIS | 34 DIS | 72 SAT | 9 DIS | 39 DIS! | 0 DIS | 50 MIX | 81 SAT |
| kimchi | 22 DIS | 47 MIX | 10 DIS! | 27 DIS | 32 DIS | 15 DIS | 40 MIX | 10 DIS |
| kimchi + mushrooms | 48 MIX | 54 MIX | 24 DIS! | 27 DIS | 48 MIX | 15 DIS | 60 MIX | 43 MIX |
| kimchi + mushrooms + pickled_cucumber | 48 MIX | 74 SAT | 24 DIS! | 61 MIX | 36 DIS | 35 DIS | 60 MIX | 43 MIX |
| kimchi + mushrooms + rooftop_lettuce | 48 MIX | 84 SAT | 24 DIS! | 66 SAT | 48 MIX | 45 MIX | 60 MIX | 43 MIX |
| kimchi + mushrooms + smoked_fish | 39 DIS! | 47 MIX | 39 DIS! | 27 DIS | 64 MIX | 15 DIS | 80 SAT | 39 DIS |
| kimchi + mushrooms + soy_broth | 74 SAT | 40 MIX | 39 DIS! | 27 DIS | 64 MIX | 15 DIS | 39 DIS! | 53 MIX |
| kimchi + mushrooms + thick_wheat_noodles | 61 MIX | 34 DIS | 39 DIS! | 27 DIS | 39 DIS! | 15 DIS | 80 SAT | 77 SAT |
| kimchi + pickled_cucumber | 22 DIS | 67 SAT | 10 DIS! | 61 MIX | 20 DIS | 35 DIS | 40 MIX | 10 DIS |
| kimchi + pickled_cucumber + rooftop_lettuce | 22 DIS | 77 SAT | 10 DIS! | 100 DEL | 20 DIS | 45 MIX | 40 MIX | 10 DIS |
| kimchi + pickled_cucumber + smoked_fish | 39 DIS! | 74 SAT | 24 DIS! | 61 MIX | 44 MIX | 35 DIS | 60 MIX | 34 DIS |
| kimchi + pickled_cucumber + soy_broth | 48 MIX | 67 SAT | 39 DIS! | 61 MIX | 36 DIS | 35 DIS | 39 DIS! | 58 MIX |
| kimchi + pickled_cucumber + thick_wheat_noodles | 35 DIS | 60 MIX | 39 DIS! | 61 MIX | 28 DIS! | 35 DIS | 100 DEL | 62 MIX |
| kimchi + rooftop_lettuce | 22 DIS | 77 SAT | 10 DIS! | 66 SAT | 32 DIS | 45 MIX | 40 MIX | 10 DIS |
| kimchi + rooftop_lettuce + smoked_fish | 39 DIS! | 84 SAT | 24 DIS! | 66 SAT | 56 MIX | 45 MIX | 60 MIX | 34 DIS |
| kimchi + rooftop_lettuce + soy_broth | 48 MIX | 77 SAT | 39 DIS! | 66 SAT | 48 MIX | 45 MIX | 39 DIS! | 58 MIX |
| kimchi + rooftop_lettuce + thick_wheat_noodles | 35 DIS | 70 SAT | 39 DIS! | 66 SAT | 39 DIS! | 45 MIX | 100 DEL | 62 MIX |
| kimchi + smoked_fish | 39 DIS! | 54 MIX | 24 DIS! | 27 DIS | 56 MIX | 15 DIS | 60 MIX | 34 DIS |
| kimchi + smoked_fish + soy_broth | 39 DIS! | 40 MIX | 39 DIS! | 27 DIS | 64 MIX | 15 DIS | 39 DIS! | 53 MIX |
| kimchi + smoked_fish + thick_wheat_noodles | 39 DIS! | 34 DIS | 39 DIS! | 27 DIS | 39 DIS! | 15 DIS | 80 SAT | 67 SAT |
| kimchi + soy_broth | 48 MIX | 47 MIX | 39 DIS! | 27 DIS | 48 MIX | 15 DIS | 39 DIS! | 58 MIX |
| kimchi + soy_broth + thick_wheat_noodles | 61 MIX | 27 DIS | 39 DIS! | 27 DIS | 39 DIS! | 15 DIS | 39 DIS! | 91 DEL |
| kimchi + thick_wheat_noodles | 35 DIS | 40 MIX | 39 DIS! | 27 DIS | 39 DIS! | 15 DIS | 100 DEL | 62 MIX |
| mushrooms | 27 DIS | 60 MIX | 15 DIS | 0 DIS | 76 SAT | 0 DIS | 50 MIX | 34 DIS |
| mushrooms + pickled_cucumber | 27 DIS | 80 SAT | 15 DIS | 35 DIS | 64 MIX | 20 DIS | 50 MIX | 34 DIS |
| mushrooms + pickled_cucumber + rooftop_lettuce | 27 DIS | 90 DEL | 15 DIS | 74 SAT | 64 MIX | 30 DIS | 50 MIX | 34 DIS |
| mushrooms + pickled_cucumber + smoked_fish | 39 DIS! | 74 SAT | 29 DIS | 35 DIS | 88 DEL | 20 DIS | 70 SAT | 39 DIS |
| mushrooms + pickled_cucumber + soy_broth | 53 MIX | 67 SAT | 43 MIX | 35 DIS | 80 SAT | 20 DIS | 39 DIS! | 62 MIX |
| mushrooms + pickled_cucumber + thick_wheat_noodles | 40 MIX | 60 MIX | 58 MIX | 35 DIS | 39 DIS! | 20 DIS | 70 SAT | 86 DEL |
| mushrooms + rooftop_lettuce | 27 DIS | 90 DEL | 15 DIS | 40 MIX | 76 SAT | 30 DIS | 50 MIX | 34 DIS |
| mushrooms + rooftop_lettuce + smoked_fish | 39 DIS! | 84 SAT | 29 DIS | 40 MIX | 100 DEL | 30 DIS | 70 SAT | 39 DIS |
| mushrooms + rooftop_lettuce + soy_broth | 53 MIX | 77 SAT | 43 MIX | 40 MIX | 92 DEL | 30 DIS | 39 DIS! | 62 MIX |
| mushrooms + rooftop_lettuce + thick_wheat_noodles | 40 MIX | 70 SAT | 58 MIX | 40 MIX | 39 DIS! | 30 DIS | 70 SAT | 86 DEL |
| mushrooms + smoked_fish | 39 DIS! | 54 MIX | 29 DIS | 0 DIS | 100 DEL | 0 DIS | 70 SAT | 39 DIS |
| mushrooms + smoked_fish + soy_broth | 39 DIS! | 40 MIX | 58 MIX | 0 DIS | 100 DEL | 0 DIS | 39 DIS! | 67 SAT |
| mushrooms + smoked_fish + thick_wheat_noodles | 39 DIS! | 34 DIS | 72 SAT | 0 DIS | 39 DIS! | 0 DIS | 50 MIX | 81 SAT |
| mushrooms + soy_broth | 53 MIX | 47 MIX | 43 MIX | 0 DIS | 92 DEL | 0 DIS | 39 DIS! | 62 MIX |
| mushrooms + soy_broth + thick_wheat_noodles | 66 SAT | 34 DIS | 72 SAT | 0 DIS | 39 DIS! | 0 DIS | 39 DIS! | 81 SAT |
| mushrooms + thick_wheat_noodles | 40 MIX | 40 MIX | 58 MIX | 0 DIS | 39 DIS! | 0 DIS | 70 SAT | 86 DEL |
| pickled_cucumber | 0 DIS | 74 SAT | 0 DIS | 35 DIS | 48 MIX | 20 DIS | 30 DIS | 0 DIS |
| pickled_cucumber + rooftop_lettuce | 0 DIS | 84 SAT | 0 DIS | 74 SAT | 48 MIX | 30 DIS | 30 DIS | 0 DIS |
| pickled_cucumber + rooftop_lettuce + smoked_fish | 39 DIS! | 90 DEL | 15 DIS | 74 SAT | 72 SAT | 30 DIS | 50 MIX | 43 MIX |
| pickled_cucumber + rooftop_lettuce + soy_broth | 27 DIS | 84 SAT | 29 DIS | 74 SAT | 64 MIX | 30 DIS | 39 DIS! | 48 MIX |
| pickled_cucumber + rooftop_lettuce + thick_wheat_noodles | 14 DIS | 77 SAT | 43 MIX | 74 SAT | 39 DIS! | 30 DIS | 90 DEL | 53 MIX |
| pickled_cucumber + smoked_fish | 39 DIS! | 80 SAT | 15 DIS | 35 DIS | 72 SAT | 20 DIS | 50 MIX | 43 MIX |
| pickled_cucumber + smoked_fish + soy_broth | 39 DIS! | 67 SAT | 43 MIX | 35 DIS | 88 DEL | 20 DIS | 39 DIS! | 53 MIX |
| pickled_cucumber + smoked_fish + thick_wheat_noodles | 39 DIS! | 60 MIX | 58 MIX | 35 DIS | 39 DIS! | 20 DIS | 70 SAT | 77 SAT |
| pickled_cucumber + soy_broth | 27 DIS | 74 SAT | 29 DIS | 35 DIS | 64 MIX | 20 DIS | 39 DIS! | 48 MIX |
| pickled_cucumber + soy_broth + thick_wheat_noodles | 40 MIX | 54 MIX | 72 SAT | 35 DIS | 39 DIS! | 20 DIS | 39 DIS! | 100 DEL |
| pickled_cucumber + thick_wheat_noodles | 14 DIS | 67 SAT | 43 MIX | 35 DIS | 39 DIS! | 20 DIS | 90 DEL | 53 MIX |
| rooftop_lettuce | 0 DIS | 84 SAT | 0 DIS | 40 MIX | 60 MIX | 30 DIS | 30 DIS | 0 DIS |
| rooftop_lettuce + smoked_fish | 39 DIS! | 90 DEL | 15 DIS | 40 MIX | 84 SAT | 30 DIS | 50 MIX | 43 MIX |
| rooftop_lettuce + smoked_fish + soy_broth | 39 DIS! | 77 SAT | 43 MIX | 40 MIX | 100 DEL | 30 DIS | 39 DIS! | 53 MIX |
| rooftop_lettuce + smoked_fish + thick_wheat_noodles | 39 DIS! | 70 SAT | 58 MIX | 40 MIX | 39 DIS! | 30 DIS | 70 SAT | 77 SAT |
| rooftop_lettuce + soy_broth | 27 DIS | 84 SAT | 29 DIS | 40 MIX | 76 SAT | 30 DIS | 39 DIS! | 48 MIX |
| rooftop_lettuce + soy_broth + thick_wheat_noodles | 40 MIX | 64 MIX | 72 SAT | 40 MIX | 39 DIS! | 30 DIS | 39 DIS! | 100 DEL |
| rooftop_lettuce + thick_wheat_noodles | 14 DIS | 77 SAT | 43 MIX | 40 MIX | 39 DIS! | 30 DIS | 90 DEL | 53 MIX |
| smoked_fish | 39 DIS! | 60 MIX | 15 DIS | 0 DIS | 84 SAT | 0 DIS | 50 MIX | 43 MIX |
| smoked_fish + soy_broth | 39 DIS! | 47 MIX | 43 MIX | 0 DIS | 100 DEL | 0 DIS | 39 DIS! | 53 MIX |
| smoked_fish + soy_broth + thick_wheat_noodles | 39 DIS! | 34 DIS | 72 SAT | 0 DIS | 39 DIS! | 0 DIS | 39 DIS! | 81 SAT |
| smoked_fish + thick_wheat_noodles | 39 DIS! | 40 MIX | 58 MIX | 0 DIS | 39 DIS! | 0 DIS | 70 SAT | 77 SAT |
| soy_broth | 27 DIS | 54 MIX | 29 DIS | 0 DIS | 76 SAT | 0 DIS | 39 DIS! | 48 MIX |
| soy_broth + thick_wheat_noodles | 40 MIX | 34 DIS | 72 SAT | 0 DIS | 39 DIS! | 0 DIS | 39 DIS! | 100 DEL |
| thick_wheat_noodles | 14 DIS | 47 MIX | 43 MIX | 0 DIS | 39 DIS! | 0 DIS | 90 DEL | 53 MIX |
