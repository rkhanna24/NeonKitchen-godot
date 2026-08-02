# ADR 0004: Phase 1 commands, events, and evaluator contract

- Status: Accepted
- Date: 2026-08-01
- Deciders: Rohan Khanna (human authority); Kitchen Lead (analysis and recommendation)
- Supersedes: —

## Context

[ADR 0002](0002-phase-1-structural-foundation.md) §3 fixed the command and event
*vocabulary* but deliberately left field-level detail to this decision. Issue
[#4](https://github.com/rkhanna24/NeonKitchen-godot/issues/4) must produce the
smallest explicit behavioural contract that implementation (#9) and verification
(#6) can share, and it resolves worklog questions Q-001, Q-003, and Q-005.

Binding inputs: the GDD's five flavour dimensions, 0–3 ingredient values, dish
values capped at 5, one-to-three distinct ingredients, a 0–100 score, four
rating bands, and a hard-violation cap of 39. ADR 0002 rule 13 requires integer
arithmetic throughout.

## Decision

### 1. Flavour model

Five dimensions, fixed order — `SAVORY`, `SPICY`, `FRESH`, `COMFORT`,
`ADVENTUROUS`. The order is part of the contract because it is the final
tie-break for deterministic feedback selection.

- An ingredient contributes `0..3` per dimension.
- A dish sums its ingredients per dimension and clamps to `0..5`.
- A dish holds 1–3 **distinct** ingredients. Order never affects the result.

### 2. Customer targets

Per dimension a customer declares a `target` (`0..5`) and an integer `weight`
(`0..5`).

**A weight of 0 means the dimension is ignored entirely** — not "wants zero".
This is the primary tuning lever: a customer weighting two dimensions leaves the
player free on the other three, which is how the GDD's "at least three
satisfying combinations" is achieved without making targets vague.

Content validation must reject a customer whose weights are all zero.

### 3. Scoring

For each dimension where `weight > 0`:

```text
error       = abs(dish_value - target)
max_error   = max(target, 5 - target)
penalty     = weight * error
max_penalty = weight * max_error
```

Then, with a single deliberate truncation:

```text
score = 100 - (sum(penalty) * 100) / sum(max_penalty)
```

Multiplication precedes division so precision is lost only once. The division
carries `@warning_ignore("integer_division")` and a comment, per AGENTS.md
rule 13. `sum(max_penalty)` is never zero because all-zero weights are invalid
content.

Overshooting is penalised exactly as much as undershooting. This is what stops
"more ingredients" from being universally better, which the GDD requires.

Worked example — the GDD's night courier, targets Comfort 5 (w3), Spicy 4 (w2),
Savory 3 (w1), dish Comfort 5, Spicy 2, Savory 4:

| Dimension | Target | Dish | Error | Penalty | Max |
|---|---|---|---|---|---|
| Comfort | 5 | 5 | 0 | 0 | 15 |
| Spicy | 4 | 2 | 2 | 4 | 8 |
| Savory | 3 | 4 | 1 | 1 | 3 |

`score = 100 - (5 * 100) / 26 = 81` → **Satisfied**, strongest match Comfort,
largest miss Spicy. The GDD narrates this dish as Satisfied 78 with the same
strongest match and largest miss.

### 4. Rating bands

`DELIGHTED` 85–100, `SATISFIED` 65–84, `MIXED` 40–64, `DISSATISFIED` 0–39.

### 5. Constraints

Four kinds, all hard: `REQUIRE_INGREDIENT`, `FORBID_INGREDIENT`, `REQUIRE_TAG`,
`FORBID_TAG`. Dietary and allergen rules are expressed as `FORBID_TAG`; they are
not a separate mechanism. A customer carries 0–2 constraints.

Any violation applies `score = min(score, 39)`, forcing `DISSATISFIED`. The
flavour score is still computed and reported, so feedback can explain both what
the dish tasted like and which boundary it crossed.

Constraints are evaluated against ingredient identity and tags only — never
against flavour values.

### 6. Feedback selection

- **Strongest match** — the weighted dimension with the lowest penalty.
- **Largest miss** — the weighted dimension with the highest penalty. Reported
  as absent when every penalty is zero.
- Unweighted dimensions are never reported; "largest *relevant* miss" means
  relevant to this customer.

Ties break by higher weight first, then by the fixed dimension order in §1.
Both tie-breaks are mandatory: without them, feedback is non-deterministic and
golden cases cannot be stable.

### 7. Commands

Five are active in Phase 1. Field-level design of the four cooking-challenge
terms remains deferred by ADR 0002 §3.

| Command | Fields |
|---|---|
| `StartSession` | `customer_ids: Array[StringName]` |
| `PresentCustomer` | — advances to the next customer in the roster |
| `SelectIngredient` | `ingredient_id: StringName` |
| `RemoveIngredient` | `ingredient_id: StringName` |
| `SubmitDish` | — |

`StartSession` takes an explicit roster rather than reading a global default, so
golden cases pin the exact encounter sequence.

### 8. Events

Eight are active. Every event carries a monotonic `sequence: int` per session,
satisfying ADR 0002 §3's ordering requirement.

| Event | Fields |
|---|---|
| `SessionStarted` | `customer_count: int` |
| `CustomerPresented` | `customer_id: StringName`, `index: int` |
| `IngredientSelected` | `ingredient_id: StringName`, `dish_profile: FlavorProfile` |
| `IngredientRemoved` | `ingredient_id: StringName`, `dish_profile: FlavorProfile` |
| `DishSubmitted` | `ingredient_ids: Array[StringName]` |
| `DishEvaluated` | `evaluation: Evaluation` |
| `CustomerReacted` | `reaction_key: StringName` |
| `SessionEnded` | `results: Array[EncounterResult]` |

`CustomerReacted` carries a **localisation key**, never prose, per ADR 0002.

### 9. Evaluator input and output

Input: a dish (ingredient definitions) and a customer definition. The evaluator
touches no repository, clock, or randomness.

Output — `Evaluation`:

| Field | Type |
|---|---|
| `score` | `int`, 0–100 |
| `band` | `RatingBand` |
| `constraint_satisfied` | `bool` |
| `violated_constraint_ids` | `Array[StringName]` |
| `strongest_match` | `Dimension` or absent |
| `largest_miss` | `Dimension` or absent |
| `per_dimension` | target, actual, weight, penalty for each weighted dimension |

`per_dimension` exists so tests and a future debug view can show the arithmetic
without the evaluator formatting anything. It carries no display strings.

### 10. Invalid actions

Rejected commands return an explicit result and **emit no event**. Events are
accepted facts; a rejection is not one. This is a contract property, not an
implementation detail — replays must not contain rejected input.

| Condition | Error |
|---|---|
| Unknown ingredient id | `UNKNOWN_INGREDIENT` |
| Ingredient already selected | `DUPLICATE_INGREDIENT` |
| Dish already holds three | `DISH_FULL` |
| Removing an unselected ingredient | `NOT_SELECTED` |
| Submitting an empty dish | `EMPTY_DISH` |
| Any command in the wrong phase | `INVALID_PHASE` |

Per AGENTS.md, these are recoverable player errors and must not use `assert`.

### 11. Minimal fixture set (resolves Q-001)

**Three ingredients and two customers**, matching the GDD's Week 1 milestone,
and explicitly **evaluator contract fixtures rather than a playable slice**.

They must exercise all four bands, a two-dimension weighted customer, a
constrained customer, a hard violation capping at 39, and both feedback fields.
Seven dishes are possible, so golden cases can enumerate the space exhaustively.

The GDD's viability rule — three satisfying combinations per customer, two with
different central ingredients — is **not** applied here. Three ingredients admit
only seven dishes, so satisfying it would require targets so generous that the
puzzle loses its teeth. That rule governs the shipped twelve-ingredient roster
and is audited in #6 by enumerating all 298 dishes.

### 12. First internal playtest protocol (resolves Q-005)

The GDD already fixes the advance gate: Phase 1 proceeds to the Godot UI when
the evaluator is deterministic, all golden cases pass, customers have multiple
viable recipes, and internal testers can explain constraint outcomes. This
protocol produces that evidence.

Per encounter, record:

1. whether the tester can state, before serving, what the customer wants;
2. whether they can explain the result afterwards in ingredient and customer
   terms, without being shown the numbers;
3. for a constraint failure, whether they can say which boundary they crossed
   and why it capped the score;
4. whether they can propose a different plausible dish for the same customer;
5. whether they *want* to try another combination — curiosity, unprompted.

Points 2, 3, and 4 are the advance gate. Point 5 is the Phase 1 design question
and cannot be settled by any automated check.

Run it on the twelve-ingredient roster, not these fixtures. Automated tests may
never be cited as evidence that the puzzle is enjoyable.

## Alternatives Considered

**Tolerance of ±1 on each dimension.** More forgiving, more solutions. Rejected:
it scored the GDD's own worked example a full band higher, compressing the top
of the range so a near-miss and a perfect dish read alike.

**Direction-based preferences ("wants more spice") with no target value.**
Simplest to author and narrate. Rejected: it cannot express "spicy, but not too
spicy", and high-weighted preferences reward loading in ingredients — the
dominance failure the GDD's risk table names.

**Five ingredients and three customers.** Large enough to satisfy the viability
rule immediately. Rejected in favour of the GDD's stated Week 1 counts; content
scale-up belongs with the real roster.

**Emitting events for rejected commands.** Rejected: it would put non-facts into
the replay stream and force every presenter to distinguish accepted from
attempted.

## Consequences

**Enabled**

- #9 can implement the evaluator without inventing design.
- #6 can write golden cases directly from §3, §6, and §10.
- #8 knows exactly what content to author and what it must exercise.
- Feedback selection is deterministic, so golden cases are stable.

**Required**

- Content validation rejects a customer with all-zero weights.
- The single integer division carries a narrow suppression and a reason.
- The dimension order in §1 is part of the contract; reordering it changes
  feedback output and requires a superseding ADR.
- Any incompatible change to these commands, events, or the evaluation shape
  requires a superseding ADR, per AGENTS.md.

**Deferred**

- Cooking-challenge command and event fields.
- Balance of the twelve-ingredient roster.
- Session summary presentation.

## Verification

- The GDD's worked example scores 81, band Satisfied, strongest match Comfort,
  largest miss Spicy.
- All seven fixture dishes have recorded golden cases.
- Every rating band is reachable by at least one fixture dish.
- A hard violation caps at 39 while the flavour score remains reported.
- Rejected commands produce no events.
- Reordering a dish's ingredients does not change its evaluation.
