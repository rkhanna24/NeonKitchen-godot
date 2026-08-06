# Recipe-Space Analysis — Late-Shift Medic proposal (re-review after correction)

**This is a rewrite, not a diff.** A prior pass on an earlier draft of
`content/staging/proposal.md` issued **REVISE**, because that draft's §4
"check against existing customers" stated `scrap_trader`'s best existing dish
was `ember_chili_paste + neon_noodles` (score 80), when the true best was
`neon_noodles` alone (score 90, DELIGHTED). The Pantry Keeper has since
corrected §4's rationale and added an open question (§5.6), changing **no**
number in §1 or §2. This report re-verifies the corrected proposal from
scratch and stands alone as the gate artifact — it does not assume anything
from the earlier pass without re-deriving it here.

## Method

Ran the **real evaluator** headlessly, twice independently across this task
(once to reproduce the full pantry × roster enumeration, once as a targeted
fresh probe for the specific claims re-review step 3/4 asked me to isolate):

```
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s /tmp/probe.gd
```

The probe built `IngredientDefinition.new()` / `CustomerDefinition.new()` /
`CustomerConstraint.new()` in code from the exact numbers in
`content/base/ingredients/*.tres`, `content/base/customers/*.tres`, and
`content/staging/proposal.md` §1–§2, enumerated every 1-, 2-, and
3-ingredient distinct combination, and called `Evaluator.evaluate()` for
each (dish, customer) pair. It lived only at `/tmp/probe.gd` and has been
deleted (confirmed at the end of this report).

Bands per ADR 0004 §4: `DELIGHTED` 85–100, `SATISFIED` 65–84, `MIXED` 40–64,
`DISSATISFIED` 0–39. Solvability definition applied throughout: **per
ADR 0004 §11, solvability is a property of the session, not of each
customer.** A hard or even impossible-to-fully-satisfy customer is not
itself a defect; what is checked is whether the day is completable and
whether some real choice exists.

---

## 0. Step 1 — confirming the numbers are actually unchanged

Read `content/staging/proposal.md` §1 and §2 directly (not from memory of any
prior pass):

- `ingredient.rooftop_greens`: `savory 0, spicy 0, fresh 3, comfort 0,
  adventurous 0`, tags `raw`, `vegan`. **Unchanged.**
- `customer.late_shift_medic`: `Fresh target 4 weight 3`, `Comfort target 1
  weight 2`, all other targets/weights 0, constraints **none**.
  **Unchanged.**

Since neither changed, the enumeration space (dish profiles × customer
targets) is identical to before. I re-ran the real evaluator anyway rather
than reusing cached numbers uncritically — see §2 below, and every number
matches what a fresh run produces (I show the fresh command output, not an
assertion that it must still hold).

**§3 localisation** — read directly: `ingredient.rooftop_greens.name`,
`ingredient.rooftop_greens.description`, `customer.late_shift_medic.name`,
`customer.late_shift_medic.request`, and the four
`customer.late_shift_medic.reaction.{delighted,satisfied,mixed,dissatisfied}`
lines are all present, in the pattern `content/base/localization/en.csv`
already uses for `solar_tech`/`scrap_trader` (name/description for
ingredients; name/request/four reaction lines for customers). **Unchanged**
in content and shape from what §3 of the corrected proposal specifies.

**§4/§5 diff** — the only substantive changes I can identify versus the
scoped correction are exactly the two the human authorized: (a) the
`scrap_trader` paragraph in §4 now says the true pre-change best is
`neon_noodles` alone at 90/DELIGHTED (not 80), and re-derives the
post-change check against that corrected baseline; (b) a new open question
§5.6 flagging that both of the medic's Delighted dishes require
`ember_chili_paste`. I found no other content, ingredient, customer,
constraint, or number changed. Nothing here needed a fresh enumeration —
the ingredient and customer definitions that drive the evaluator are
byte-for-byte the same as what a prior pass would have scored.

---

## 1. Full dish enumeration — real evaluator output

### 1a. Pre-change baseline (3 base ingredients × 2 existing customers) — regression reference

```
=== STEP 3: scrap_trader pre-change (3 ingredients) ===
--- customer: scrap_trader (pre-change) ---
ember_chili_paste                          score= 20 band=DISSATISFIED constraint_ok=true violated=[]
neon_noodles                               score= 90 band=DELIGHTED    constraint_ok=true violated=[]
umami_broth                                score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
ember_chili_paste+neon_noodles             score= 80 band=SATISFIED    constraint_ok=true violated=[]
ember_chili_paste+umami_broth              score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
neon_noodles+umami_broth                   score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
ember_chili_paste+neon_noodles+umami_broth score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
BEST for scrap_trader (pre-change): score=90 dishes=["neon_noodles"]
Band counts for scrap_trader (pre-change): { "DELIGHTED": 1, "SATISFIED": 1, "MIXED": 0, "DISSATISFIED": 5 }

=== STEP: solar_tech pre-change (3 ingredients) ===
--- customer: solar_tech (pre-change) ---
ember_chili_paste                          score=  0 band=DISSATISFIED constraint_ok=true violated=[]
neon_noodles                               score= 53 band=MIXED        constraint_ok=true violated=[]
umami_broth                                score= 48 band=MIXED        constraint_ok=true violated=[]
ember_chili_paste+neon_noodles             score= 53 band=MIXED        constraint_ok=true violated=[]
ember_chili_paste+umami_broth              score= 48 band=MIXED        constraint_ok=true violated=[]
neon_noodles+umami_broth                   score=100 band=DELIGHTED    constraint_ok=true violated=[]
ember_chili_paste+neon_noodles+umami_broth score=100 band=DELIGHTED    constraint_ok=true violated=[]
BEST for solar_tech (pre-change): score=100 dishes=["neon_noodles+umami_broth", "ember_chili_paste+neon_noodles+umami_broth"]
Band counts for solar_tech (pre-change): { "DELIGHTED": 2, "SATISFIED": 0, "MIXED": 4, "DISSATISFIED": 1 }
```

**Confirms the corrected proposal's central factual claim exactly:**
`scrap_trader`'s true pre-change best is **`neon_noodles` alone, score 90,
DELIGHTED** — not the 80/Satisfied an earlier draft claimed. Hand check:
spicy target 1 weight 1, comfort target 3 weight 2 (default, not overridden
in `scrap_trader.tres`). `neon_noodles` profile: savory 1, comfort 3, all
else 0. Spicy error `|0-1|=1` → penalty `1*1=1` (max_error
`max(1,5-1)=4`, max_penalty 4). Comfort error `|3-3|=0` → penalty 0
(max_error `max(3,5-3)=3`, max_penalty 6). `sum(penalty)=1`,
`sum(max_penalty)=10`. `score = 100 - 100/10 = 90`. Matches the evaluator
exactly.

### 1b. Post-change — full pantry (4 ingredients) × every customer (3) — 14 dishes each, 42 rows

```
=== STEP 3: scrap_trader post-change (4 ingredients) ===
--- customer: scrap_trader (post-change) ---
ember_chili_paste                          score= 20 band=DISSATISFIED constraint_ok=true violated=[]
neon_noodles                               score= 90 band=DELIGHTED    constraint_ok=true violated=[]
umami_broth                                score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
rooftop_greens                             score= 30 band=DISSATISFIED constraint_ok=true violated=[]
ember_chili_paste+neon_noodles             score= 80 band=SATISFIED    constraint_ok=true violated=[]
ember_chili_paste+umami_broth              score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
ember_chili_paste+rooftop_greens           score= 20 band=DISSATISFIED constraint_ok=true violated=[]
neon_noodles+umami_broth                   score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
neon_noodles+rooftop_greens                score= 90 band=DELIGHTED    constraint_ok=true violated=[]
umami_broth+rooftop_greens                 score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
ember_chili_paste+neon_noodles+umami_broth score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
ember_chili_paste+neon_noodles+rooftop_greens score= 80 band=SATISFIED    constraint_ok=true violated=[]
ember_chili_paste+umami_broth+rooftop_greens score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
neon_noodles+umami_broth+rooftop_greens    score= 39 band=DISSATISFIED constraint_ok=false violated=[&"soy"]
BEST for scrap_trader (post-change): score=90 dishes=["neon_noodles", "neon_noodles+rooftop_greens"]
Band counts for scrap_trader (post-change): { "DELIGHTED": 2, "SATISFIED": 2, "MIXED": 0, "DISSATISFIED": 10 }

=== STEP: solar_tech regression check (4 ingredients) ===
--- customer: solar_tech ---
ember_chili_paste                          score=  0 band=DISSATISFIED constraint_ok=true violated=[]
neon_noodles                               score= 53 band=MIXED        constraint_ok=true violated=[]
umami_broth                                score= 48 band=MIXED        constraint_ok=true violated=[]
rooftop_greens                             score=  0 band=DISSATISFIED constraint_ok=true violated=[]
ember_chili_paste+neon_noodles             score= 53 band=MIXED        constraint_ok=true violated=[]
ember_chili_paste+umami_broth              score= 48 band=MIXED        constraint_ok=true violated=[]
ember_chili_paste+rooftop_greens           score=  0 band=DISSATISFIED constraint_ok=true violated=[]
neon_noodles+umami_broth                   score=100 band=DELIGHTED    constraint_ok=true violated=[]
neon_noodles+rooftop_greens                score= 53 band=MIXED        constraint_ok=true violated=[]
umami_broth+rooftop_greens                 score= 48 band=MIXED        constraint_ok=true violated=[]
ember_chili_paste+neon_noodles+umami_broth score=100 band=DELIGHTED    constraint_ok=true violated=[]
ember_chili_paste+neon_noodles+rooftop_greens score= 53 band=MIXED        constraint_ok=true violated=[]
ember_chili_paste+umami_broth+rooftop_greens score= 48 band=MIXED        constraint_ok=true violated=[]
neon_noodles+umami_broth+rooftop_greens    score=100 band=DELIGHTED    constraint_ok=true violated=[]
BEST for solar_tech: score=100 dishes=["neon_noodles+umami_broth", "ember_chili_paste+neon_noodles+umami_broth", "neon_noodles+umami_broth+rooftop_greens"]
Band counts for solar_tech: { "DELIGHTED": 3, "SATISFIED": 0, "MIXED": 8, "DISSATISFIED": 3 }

=== STEP 4: late_shift_medic full enumeration (4 ingredients) ===
--- customer: late_shift_medic ---
ember_chili_paste                          score= 45 band=MIXED        constraint_ok=true violated=[]
neon_noodles                               score= 20 band=DISSATISFIED constraint_ok=true violated=[]
umami_broth                                score= 30 band=DISSATISFIED constraint_ok=true violated=[]
rooftop_greens                             score= 75 band=SATISFIED    constraint_ok=true violated=[]
ember_chili_paste+neon_noodles             score= 35 band=DISSATISFIED constraint_ok=true violated=[]
ember_chili_paste+umami_broth              score= 45 band=MIXED        constraint_ok=true violated=[]
ember_chili_paste+rooftop_greens           score= 90 band=DELIGHTED    constraint_ok=true violated=[]
neon_noodles+umami_broth                   score=  0 band=DISSATISFIED constraint_ok=true violated=[]
neon_noodles+rooftop_greens                score= 65 band=SATISFIED    constraint_ok=true violated=[]
umami_broth+rooftop_greens                 score= 75 band=SATISFIED    constraint_ok=true violated=[]
ember_chili_paste+neon_noodles+umami_broth score= 15 band=DISSATISFIED constraint_ok=true violated=[]
ember_chili_paste+neon_noodles+rooftop_greens score= 80 band=SATISFIED    constraint_ok=true violated=[]
ember_chili_paste+umami_broth+rooftop_greens score= 90 band=DELIGHTED    constraint_ok=true violated=[]
neon_noodles+umami_broth+rooftop_greens    score= 45 band=MIXED        constraint_ok=true violated=[]
BEST for late_shift_medic: score=90 dishes=["ember_chili_paste+rooftop_greens", "ember_chili_paste+umami_broth+rooftop_greens"]
Band counts for late_shift_medic: { "DELIGHTED": 2, "SATISFIED": 4, "MIXED": 3, "DISSATISFIED": 5 }
```

And the one dish singled out by re-review step 3, run in isolation as an
extra check (also appears above, inline, inside the `scrap_trader
post-change` block as `ember_chili_paste+rooftop_greens`):

```
=== STEP 3: specific dish chili+greens for scrap_trader ===
chili+greens score=20 band=DISSATISFIED constraint_ok=true violated=[]
```

---

## 2. Step 3 — re-deriving the corrected §4 `scrap_trader` paragraph

The corrected proposal's §4 now claims, for `scrap_trader` (Spicy target 1
weight 1, Comfort target 3 weight 2 default, forbids tag `soy`):

| Claim | Verdict | Evidence |
|---|---|---|
| Pre-change best is `neon_noodles` alone, 90, DELIGHTED | **Confirmed** | Real evaluator, §1a above: `neon_noodles` = 90 DELIGHTED, strictly the maximum of the 7 pre-change dishes. Hand-derivation matches: `100 - 100/10 = 90`. |
| Post-change best is still 90, now tied by `neon_noodles + rooftop_greens` | **Confirmed** | Real evaluator, §1b: both `neon_noodles` and `neon_noodles+rooftop_greens` score 90, and no post-change dish exceeds 90 (the next-highest are the two 80/SATISFIED dishes containing `ember_chili_paste+neon_noodles`). Hand check: `neon_noodles+rooftop_greens` profile is savory 1, fresh 3, comfort 3 — spicy and comfort (the only weighted dimensions) are unchanged from `neon_noodles` alone because `rooftop_greens` contributes 0 to both, so the score is identical by construction, not coincidence. |
| `ember_chili_paste + rooftop_greens` ("chili + greens") scores 20, DISSATISFIED | **Confirmed** | Real evaluator: 20, DISSATISFIED (no constraint violated — this is a flavour miss, not a boundary hit). Hand check: spicy error `|3-1|=2` → penalty 2 (max 4); comfort error `|0-3|=3` → penalty 6 (max 6); `sum(penalty)=8`, `sum(max_penalty)=10`; `score = 100 - 800/10 = 20`. Matches exactly. |

All three numbers the corrected proposal now states for `scrap_trader` are
factually right against the real evaluator, independently re-derived by
hand as well as by a fresh headless run. This closes the specific defect
that caused the prior REVISE.

---

## 3. Step 4 — re-deriving open question §5.6

The new open question claims: both of the medic's Delighted dishes require
`ember_chili_paste` (score 90 via `ember_chili_paste+rooftop_greens` and via
`ember_chili_paste+umami_broth+rooftop_greens`), and the chili-free ceiling
is 75, SATISFIED.

From the real-evaluator enumeration in §1b (`late_shift_medic`, 14 dishes):

- The only two dishes scoring ≥85 (DELIGHTED) are `ember_chili_paste +
  rooftop_greens` (90) and `ember_chili_paste + umami_broth + rooftop_greens`
  (90) — both contain `ember_chili_paste`, and no other dish reaches
  DELIGHTED. **Confirmed.**
- Every dish that omits `ember_chili_paste`: `neon_noodles` (20),
  `umami_broth` (30), `rooftop_greens` (75), `neon_noodles+umami_broth` (0),
  `neon_noodles+rooftop_greens` (65), `umami_broth+rooftop_greens` (75),
  `neon_noodles+umami_broth+rooftop_greens` (45). The maximum among these is
  **75, SATISFIED**, achieved by two dishes (`rooftop_greens` alone and
  `umami_broth+rooftop_greens`). **Confirmed** — matches the open
  question's stated ceiling exactly.

Hand check on the two 90s, both landing on the same arithmetic because
`rooftop_greens` contributes fresh 3 and `umami_broth` contributes comfort 2
but the *comfort error* is identical either way:

`ember_chili_paste+rooftop_greens`: savory 0, spicy 3, fresh 4, comfort 0,
adventurous 2. Fresh error 0 → penalty 0 (max 12). Comfort error `|0-1|=1` →
penalty 2 (max 8). `sum(penalty)=2`, `sum(max_penalty)=20`,
`score=100-200/20=90`.

`ember_chili_paste+umami_broth+rooftop_greens`: savory 2, spicy 3, fresh 4,
comfort 2, adventurous 2. Fresh error 0 → penalty 0. Comfort error
`|2-1|=1` → penalty 2 (max 8). Same totals, same 90.

`rooftop_greens` alone: fresh 3, comfort 0. Fresh error 1 → penalty 3 (max
12). Comfort error 1 → penalty 2 (max 8). `sum(penalty)=5`,
`sum(max_penalty)=20`, `score=100-500/20=75`.

Both numbers in the open question are correct. It is, as framed, a genuine
open design/tone question for the human (is it acceptable that delighting a
"fresh and light" customer requires the spiciest ingredient in the pantry)
and not a mechanical defect — no rule is violated, since the medic's Spicy
weight is 0 and therefore ignored, not disliked.

---

## 4. Every dish enumerated, all customers — summary table

### `solar_tech` (Savory target 3 w2, Comfort target 5 w3)

| Dish | Score | Band | Constraint |
|---|---|---|---|
| chili | 0 | DISSATISFIED | ok |
| noodles | 53 | MIXED | ok |
| broth | 48 | MIXED | ok |
| greens | 0 | DISSATISFIED | ok |
| chili+noodles | 53 | MIXED | ok |
| chili+broth | 48 | MIXED | ok |
| chili+greens | 0 | DISSATISFIED | ok |
| noodles+broth | 100 | DELIGHTED | ok |
| noodles+greens | 53 | MIXED | ok |
| broth+greens | 48 | MIXED | ok |
| chili+noodles+broth | 100 | DELIGHTED | ok |
| chili+noodles+greens | 53 | MIXED | ok |
| chili+broth+greens | 48 | MIXED | ok |
| noodles+broth+greens | 100 | DELIGHTED | ok |

Best 100/DELIGHTED, three tied dishes, unchanged pre- vs. post-change.

### `scrap_trader` (Spicy target 1 w1, Comfort target 3 w2 default, forbids tag `soy`)

| Dish | Score | Band | Constraint |
|---|---|---|---|
| chili | 20 | DISSATISFIED | ok |
| noodles | 90 | DELIGHTED | ok |
| broth | 39 | DISSATISFIED | **violated (soy)** |
| greens | 30 | DISSATISFIED | ok |
| chili+noodles | 80 | SATISFIED | ok |
| chili+broth | 39 | DISSATISFIED | **violated (soy)** |
| chili+greens | 20 | DISSATISFIED | ok |
| noodles+broth | 39 | DISSATISFIED | **violated (soy)** |
| noodles+greens | 90 | DELIGHTED | ok |
| broth+greens | 39 | DISSATISFIED | **violated (soy)** |
| chili+noodles+broth | 39 | DISSATISFIED | **violated (soy)** |
| chili+noodles+greens | 80 | SATISFIED | ok |
| chili+broth+greens | 39 | DISSATISFIED | **violated (soy)** |
| noodles+broth+greens | 39 | DISSATISFIED | **violated (soy)** |

Best 90/DELIGHTED, two tied dishes (`noodles` alone, `noodles+greens`), same
score pre- and post-change — no regression, and this is the corrected
baseline the proposal now states.

### `late_shift_medic` (Fresh target 4 w3, Comfort target 1 w2, no constraint)

| Dish | Score | Band | Constraint |
|---|---|---|---|
| chili | 45 | MIXED | ok |
| noodles | 20 | DISSATISFIED | ok |
| broth | 30 | DISSATISFIED | ok |
| greens | 75 | SATISFIED | ok |
| chili+noodles | 35 | DISSATISFIED | ok |
| chili+broth | 45 | MIXED | ok |
| chili+greens | 90 | DELIGHTED | ok |
| noodles+broth | 0 | DISSATISFIED | ok |
| noodles+greens | 65 | SATISFIED | ok |
| broth+greens | 75 | SATISFIED | ok |
| chili+noodles+broth | 15 | DISSATISFIED | ok |
| chili+noodles+greens | 80 | SATISFIED | ok |
| chili+broth+greens | 90 | DELIGHTED | ok |
| noodles+broth+greens | 45 | MIXED | ok |

Best 90/DELIGHTED via two tied dishes, four distinct SATISFIED dishes below
that, real spread across all four bands — a genuine puzzle with graded
difficulty, not a single lookup cell.

---

## 5. Band coverage

Pooling all three customers post-change: `DELIGHTED` (e.g. `solar_tech` /
`noodles+broth`, 100), `SATISFIED` (e.g. `scrap_trader` / `chili+noodles`,
80), `MIXED` (e.g. `solar_tech` / `noodles`, 53), `DISSATISFIED` (e.g.
`solar_tech` / `chili`, 0) are all reached. All four bands are reachable
across the session, satisfying ADR 0004 §11's band-coverage requirement
(a session property, not a per-customer one).

---

## 6. Dominant ingredients

**Strict test — does any ingredient, served alone, satisfy (≥65) more than
half (i.e. ≥2 of 3) of the roster, or sit in the intersection of every
customer's best-dish set?**

Each ingredient served alone: `chili` alone satisfies 0/3 customers (0, 20,
45 — none ≥65); `noodles` alone satisfies 1/3 (90 for `scrap_trader` only;
53 and 20 elsewhere); `broth` alone satisfies 0/3 (48, 39-violated, 30);
`greens` alone satisfies 1/3 (75 for the medic only; 0 and 30 elsewhere). No
ingredient's own single-ingredient dish satisfies more than one customer.
Best-dish-set intersection across all three customers is empty (see §7
below). **No ingredient fails the strict test.**

**Softer, informational pooled check** (as flagged in the prior pass, redone
here with corrected arithmetic): counting every (customer, dish) pair
scoring ≥65 across the whole post-change session — `solar_tech` contributes
3 such dishes (`noodles+broth`, `chili+noodles+broth`,
`noodles+broth+greens`), `scrap_trader` contributes 4
(`noodles`, `chili+noodles`, `noodles+greens`, `chili+noodles+greens`), and
`late_shift_medic` contributes 6 (`greens`, `chili+greens`, `noodles+greens`,
`broth+greens`, `chili+noodles+greens`, `chili+broth+greens`) — 13 pooled
satisfying dishes total. Counting ingredient membership across those 13:
`neon_noodles` appears in 9 (3+4+2), `rooftop_greens` appears in 9 (1+2+6),
`ember_chili_paste` in 6 (1+2+3), `umami_broth` in 5 (3+0+2).

**Correction to the prior pass's own arithmetic:** the previous report
stated `neon_noodles` at 8/13 (62%); recounting by hand here, the correct
figure is **9/13 (≈69%)**, identical to `rooftop_greens`'s share, not lower
than it. I flag this because it surprised me and I did not round toward the
figure I expected to see. Both `neon_noodles` and `rooftop_greens` sit above
the "half" line in this pooled, informational count.

I do not treat this as the "dominant ingredient" REVISE ground, for three
reasons: (1) the REVISE criterion as specified is about a *single ingredient
satisfying more than half the roster* — a per-customer/per-dish property the
strict test above checks directly and clears; the pooled figure instead
counts *dish-membership inside an already-filtered satisfying set*, which is
a different and much noisier statistic. (2) Both ingredients are near-tied
(9 vs. 9) rather than one alone dominating, and each is inert or actively
harmful for at least one customer (`neon_noodles` triggers the soy-adjacent
umami_broth-based DISSATISFIED band for nobody, but contributes 0 to the
medic's only-weighted dimension pairing productively only via combination;
`rooftop_greens` contributes 0 to `solar_tech`'s and is a flavour-miss-only
20/DISSATISFIED for `scrap_trader` when paired with chili). (3) ADR 0004
§11 states explicitly that the "no recipe satisfies more than half the
roster" audit is binding for the twelve-ingredient roster (§6, 298 dishes),
not this four-ingredient/three-customer fixture set — this pooled number is
reported for transparency, not as a gate.

---

## 7. Degenerate dish check

Best-dish sets: `solar_tech` = `{noodles+broth, chili+noodles+broth,
noodles+broth+greens}`; `scrap_trader` = `{noodles, noodles+greens}`;
`late_shift_medic` = `{chili+greens, chili+broth+greens}`. Pairwise and
three-way intersection is empty — no single dish is best-or-tied for every
customer.

---

## 8. Unsolvable customers

None. Every customer's best dish clears `DELIGHTED` (≥85): `solar_tech`
100, `scrap_trader` 90, `late_shift_medic` 90 — all far above the
`DISSATISFIED` ceiling of 39 that would trigger this check. The medic in
particular, despite being explicitly the "hard" customer the new ingredient
was designed for, is comfortably solvable on its own and has internal
choice at every band (four distinct dishes reach SATISFIED, two distinct
dishes reach DELIGHTED).

---

## 9. Choice check (not a single-dish lookup)

- `solar_tech`: 3 tied best dishes.
- `scrap_trader`: 2 tied best dishes (`noodles` alone, `noodles+greens`),
  plus 2 further dishes tied at SATISFIED (80).
- `late_shift_medic`: 2 tied best dishes, plus 4 further dishes at SATISFIED
  built from different ingredient sets (`greens` alone 75, `noodles+greens`
  65, `broth+greens` 75, `chili+noodles+greens` 80).

No customer is satisfiable only by a single dish where the brief implied
choice.

---

## 10. Scope-creep scan (re-review step 5)

Comparing the corrected proposal against what the human authorized (fix the
`scrap_trader` rationale in §4 only, change no §1/§2 numbers): I found
exactly two substantive edits — the corrected §4 `scrap_trader` paragraph,
and the new §5.6 open question — and nothing else. §1, §2, and §3 read
identically to what the numbers above assume. No new ingredient, customer,
constraint, or localisation key was added or removed. No unauthorized
change found.

---

## 11. Verdict

**PASS.**

The specific defect that caused the prior REVISE — the proposal's §4
claiming `scrap_trader`'s best existing dish was `ember_chili_paste +
neon_noodles` at 80/SATISFIED — is now corrected. The corrected text states
the true pre-change best is `neon_noodles` alone at 90/DELIGHTED, and the
post-change best is still 90, now tied by `neon_noodles + rooftop_greens`.
Both figures, plus the `chili+greens` = 20/DISSATISFIED figure the
correction also cites, are confirmed by a fresh real-evaluator run and by
independent hand arithmetic in §2 of this report.

The new open question §5.6's two numeric claims (both of the medic's
Delighted dishes require `ember_chili_paste`; the chili-free ceiling is
75/SATISFIED) are also confirmed by the same fresh run and by hand
arithmetic in §3. It is correctly framed as an open design question, not a
defect, and does not change the verdict either way.

No other REVISE ground was found: no unsolvable customer (§8), no dominant
ingredient by the strict test (§6), no degenerate dish (§7), no customer
reducible to a single forced dish (§9), and no unauthorized change beyond
the two the human scoped (§10). All four bands are reachable across the
session (§5). `solar_tech`'s and `scrap_trader`'s scores are both unchanged
by the new ingredient — no regression.

One number is flagged for transparency though it does not change the
verdict: the pooled, informational "ingredient appears in N of 13
satisfying dishes" count now shows `neon_noodles` at 9/13, not the 8/13 a
prior pass reported — a correction to that pass's own arithmetic, caught
by recomputing rather than reusing it. This does not trigger REVISE because
the applicable strict test (§6) is clean and because ADR 0004 §11 scopes
that audit to the twelve-ingredient roster, not this fixture set.

---

## 12. Repository state

Probe script lived only at `/tmp/probe.gd` and has been deleted (`rm -f
/tmp/probe.gd`, confirmed). This task did not modify
`content/staging/proposal.md` or anything under `content/base/`,
`content/schemas/`, `core/`, `adapters/`, `tests/`, `docs/`, or `scripts/`,
and generated no `.tres` files. `git status --porcelain` at the end of this
task shows only: this file (`content/staging/balance.md`, rewritten by this
task), plus `content/staging/proposal.md`, `docs/crew/`,
`docs/worklogs/crew-runs/`, and a modified `README.md` — all four of which
were already present/untracked/modified before this task started and were
not touched by it.
