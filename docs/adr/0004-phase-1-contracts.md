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

#### Why 3 and 5

These constants come from the GDD, which states them without derivation. They
are not arbitrary in effect, and the relationships below are what must be
preserved if either is ever changed:

**`max_ingredient_value < max_target`.** A single ingredient reaches at most 3,
so any target of **4 or 5 is unreachable with one ingredient**. This is the
mechanic that forces combination — it is the puzzle. Raising the ingredient
range to 5 would let one ingredient satisfy any customer and the game would
collapse.

**`cap < max_dish_size × max_ingredient_value`.** With three ingredients the
theoretical maximum is 9, so a cap of 5 means surplus is discarded: 35% of
three-ingredient value combinations exceed it. That waste is what makes the
third ingredient a real decision rather than a free bonus, and it is why "more
ingredients" is not automatically better — a risk the GDD names directly.

Both hold for any cap in `4..6`. A cap of 3 would let one ingredient max a
dimension; a cap of 9 would remove clamping entirely and make stacking always
correct. **5 is a sound choice within a valid window, not a derived value** —
worth knowing before anyone "tidies" it.

Dish size is the safer tuning knob. Raising it does not widen the reachable
range, because the cap already binds at two ingredients; what it changes is that
**low targets get harder**, since more ingredients contribute more incidental
flavour. Changing the per-ingredient range instead re-scales the meaning of
every authored ingredient.

### 2. Customer targets

Per dimension a customer declares a `target` (`0..5`) and an integer `weight`
(`0..5`).

**A weight of 0 means the dimension is ignored entirely** — not "wants zero".
This is the primary tuning lever: a customer weighting two dimensions leaves the
player free on the other three, which is how the GDD's "at least three
satisfying combinations" is achieved without making targets vague.

Content validation must reject a customer whose:

- weights are **all zero** — there would be nothing to score against; or
- `weight` falls outside `0..5`, or `target` outside `0..5`.

> **Gap closed 2026-08-01, before publication.** The range was stated in prose
> but only the all-zero rule was listed as enforceable, so a **negative weight**
> would have passed validation and reached the formula. It inverts the
> arithmetic — penalty becomes a reward for being wrong — and can drive
> `sum(max_penalty)` to zero or below, making the division undefined. Verified
> against an executable model of this contract: weight `-5` produced
> `max_penalty = -10`.

**Negative weights are not a way to express dislike, and are not permitted.**
Dislike is a low target with a high weight: "definitely not spicy" is
`target 0, weight 5`. Verified against the same model — that customer served a
maximally spicy dish scores 38, `DISSATISFIED`, largest miss Spicy, with no hard
constraint involved.

This is the deliberate two-tier design. A strong *preference* against something
is a flavour target and can still be outweighed by the rest of the dish. A
*boundary* — an allergen, a dietary rule, an ingredient the customer refuses —
is a `FORBID_*` constraint under §5 and caps the score at 39 regardless of how
good the flavour match is.

#### The default customer profile

A new `CustomerDefinition` defaults to **`COMFORT` weight 1, target 3**, with
every other dimension at weight 0.

Two properties of the model make this the right shape, both found by using the
explorer rather than by reading the formula:

**Weight is purely relative.** When only one dimension is weighted, its weight
cancels in the normalisation — weights 1 and 5 produce identical scores across
every dish. A weight only means anything next to another weight. So the default
weight value is arbitrary; it just has to be non-zero, since all-zero weights are
invalid content.

**The default's meaning lives in the target.** A target of 0 is the trap: "all
weights 1, all targets 0" reads as a customer with no opinion, but scores an
empty plate at 100 and falls monotonically to 0 as any flavour is added. It is a
customer who wants nothing served. Target 3 instead gives a curve peaking
mid-range, which matches "most people want some comfort".

An unauthored default is deliberately **valid but bland**, not invalid. The
protection against shipping bland customers is not validation but the §11 audit:
the GDD requires that no single recipe satisfies more than half the roster, and a
customer satisfied by almost anything fails that check.

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

### 3a. Dish quality — contract recorded, not implemented

Cooking challenges will produce a dish **quality**, already anticipated by the
`CookingChallengePort` result in technical architecture §9. Phase 1 does not
implement it and no quality field exists in `Evaluation`. The contract is
recorded here because its shape is constrained by decisions already made, and
getting it wrong later would be expensive.

**Quality is an integer percentage, `0..100`. It is never a float.** A `1.0`
multiplier would break ADR 0002 rule 13 and reintroduce exactly the
cross-platform determinism risk this contract was built to avoid — with band
edges at 40, 65 and 85, a float quality would put macOS and Linux back in
disagreement at the boundaries.

When implemented:

```text
score = flavour_score * quality / 100      # a SECOND deliberate truncation
score = min(score, 39) if any constraint violated
```

Two things must be decided at implementation time, not assumed:

- **Order matters and is fixed above.** Quality scales the flavour score; the
  constraint cap applies last. A boundary violation must cap the result no
  matter how well the dish was cooked.
- **A second truncation interacts with the band edges.** The single truncation
  in §3 was analysed against 40, 65 and 85; a second one has not been. That
  analysis is a precondition of implementing quality.

No placeholder field is added now. An always-100 field would invite code to
multiply by it and would prove nothing — the same reasoning that keeps the
cooking-challenge command vocabulary reserved but undefined under ADR 0002 §3.

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

**A customer may not carry two constraints with the same `subject` on the same
side of the identity/tag divide.** `ContentValidator` rejects the content set if
one does. Two identical `FORBID_TAG(soy)` constraints are not a richer boundary,
they are the same boundary authored twice, and they make a violation report
ambiguous for no benefit. An ingredient `content_id` and a tag may share text
without conflict, because they are different things — that pair is permitted, and
§9's `ViolatedConstraint` records `kind` so a report can still distinguish them.

This rule is what makes a boundary identifiable without inventing an authored id
field. With duplicates unauthorable, `subject` plus `kind` is unique within a
customer by construction.

**A stated boundary is absolute regardless of the reason given for it.** "No
soy" means no soy, whether the customer describes an allergy, an intolerance, or
a dislike. The engine cannot distinguish them and does not try to: the reason
lives in the explanation text and carries no mechanical weight. This is why
dietary and allergen rules are one mechanism rather than two.

A consequence worth stating for content authors: a constraint may put a target
out of reach. If the only strong Comfort partner is forbidden, the customer
cannot be fully satisfied on Comfort, and that is the intended shape of the
puzzle rather than a content defect. The player works within the boundary.
Transforming an ingredient so it no longer carries a tag is a cooking-technique
idea and is deferred.

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

### 7a. Session phases (added 2026-08-06)

Five phases. A command issued in a phase that does not list it is rejected with
`INVALID_PHASE` (§10) and emits no event.

| Phase | Command | Emits, in order | On success |
|---|---|---|---|
| `NOT_STARTED` | `StartSession` | `SessionStarted` | → `AWAITING_CUSTOMER` |
| `AWAITING_CUSTOMER` | `PresentCustomer` | `CustomerPresented`, or `SessionEnded` when the roster is exhausted | → `BUILDING_DISH`, or → `ENDED` |
| `BUILDING_DISH` | `SelectIngredient` | `IngredientSelected` | phase unchanged |
| `BUILDING_DISH` | `RemoveIngredient` | `IngredientRemoved` | phase unchanged |
| `BUILDING_DISH` | `SubmitDish` | `DishSubmitted`, `DishEvaluated`, `CustomerReacted` | → `SHOWING_RESULT` |
| `SHOWING_RESULT` | `PresentCustomer` | `CustomerPresented`, or `SessionEnded` when the roster is exhausted | → `BUILDING_DISH`, or → `ENDED` |
| `ENDED` | none | — | — |

The mapping was previously derivable but unwritten, which left the one command
that emits more than one event unspecified. `SubmitDish`'s three events are
ordered by causality: the dish is submitted, that submission is evaluated, and
the customer reacts to that evaluation. Golden cases (#6) pin event sequences, so
this order is contract, not convention.

**`sequence` starts at 1 and increments per event, not per command.** A
`SubmitDish` that emits three events consumes three numbers. It is unique and
monotonic within one session and never reused, so a gap in the numbering means an
event was lost rather than that a command was rejected — rejections emit nothing
and consume nothing.

**`CustomerPresented.index` is 0-based into the roster** given to `StartSession`,
so it indexes that array directly.

**The dish is cleared on `PresentCustomer`, not on `SubmitDish`.** During
`SHOWING_RESULT` the dish that was just served is still readable, which is what
lets a presenter show what the reaction was to. Clearing on submit would erase it
at the moment it becomes worth displaying.

`SessionEnded` is emitted on the transition into `ENDED`, which happens when
`PresentCustomer` is issued with no customer remaining. The session does not end
on its own after the last submit: ending is an accepted fact caused by a command,
like every other event.

`AWAITING_CUSTOMER` and `SHOWING_RESULT` accept the same single command, and that
redundancy is deliberate. They differ in what a presenter should be showing —
an empty counter versus the previous customer's reaction — and collapsing them
would force a presenter to infer "have I already served someone?" from state
outside the phase. `AWAITING_CUSTOMER` is entered once, immediately after
`StartSession`; every later wait is a `SHOWING_RESULT`.

> This section resolves a contract gap rather than adding a feature. §10 has
> specified `INVALID_PHASE` since the original ADR, while no document defined
> what a phase was or which commands belonged to one — an error code with no
> contract behind it. Found while decomposing #5, before any application-layer
> code existed. DEC-022.

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

`EncounterResult` (defined 2026-08-06, DEC-022) is one served encounter, recorded
so an end-of-session summary needs no re-evaluation:

| Field | Type |
|---|---|
| `customer_id` | `StringName` |
| `ingredient_ids` | `Array[StringName]` — the dish as served |
| `score` | `int`, 0–100 |
| `band` | `RatingBand` |
| `constraint_satisfied` | `bool` |

It carries the dish rather than only the outcome, so a summary can say *what* was
served to whom — which the first playtest (§12, #10) needs in order to discuss a
specific encounter rather than a score.

It is a **value copy**, not an `Evaluation` reference, for the same reason
`per_dimension` and `violated_constraints` are copies (§9). It deliberately omits
`per_dimension` and `violated_constraints`: `DishEvaluated` already carried those
at the moment they were computed, and duplicating them into the session summary
would make `SessionEnded` the heaviest event in the system for no reader that
needs it. An encounter that must be re-examined in that much detail should be
replayed from its events.

> `EncounterResult` was referenced by `SessionEnded` from the original ADR with
> its fields never specified — the only type in this document named but not
> defined. Found while decomposing #5.

### 8a. Reaction key resolution

`CustomerReacted` carries one resolved key. `CustomerDefinition.reaction_key` is
a **prefix**, not a complete key, and the most specific available key wins:

```text
<prefix>.<band>.<qualifier>   most specific — deferred, not authored in Phase 1
<prefix>.<band>               authored in Phase 1, one per band
<prefix>                      fallback
```

Phase 1 authors four lines per customer, one per rating band. A single static
reaction would praise a dish that scored `DISSATISFIED`, which the GDD's worked
example in §2.2 shows it must not.

The qualifier level exists so a reaction can later respond to a specific
ingredient or cooking technique without changing this schema, this contract, or
the `CustomerReacted` event. It is deliberately unimplemented.

Selection is a domain concern — the band and the dish are both domain facts —
but it belongs with whatever emits `CustomerReacted`, not with the evaluator.

### 9. Evaluation is three concerns behind one entry point

```text
composition:      Array[IngredientDefinition]              -> FlavorProfile
flavour scoring:  FlavorProfile + CustomerDefinition       -> flavour result
constraint check: Array[IngredientDefinition] + CustomerDefinition -> constraint result
evaluation:       Array[IngredientDefinition] + CustomerDefinition -> Evaluation
```

`evaluation` is the only entry point callers use; it orchestrates the other
three. Its inputs and output are unchanged from the original two-stage wording.

> **Corrected 2026-08-02.** This section previously read
> `scoring: FlavorProfile + CustomerDefinition -> Evaluation`, which is
> impossible: `Evaluation` carries `constraint_satisfied` and
> `violated_constraint_ids`, §5 requires constraints to be evaluated against
> ingredient identity and tags, and a `FlavorProfile` carries five integers and
> nothing else. The formula in §3 had been verified against five vectors; the
> **signature** had not been checked against the output it was required to
> produce. Found by a Systems Cook at the propose-and-stop step, before any code
> was written.
>
> Splitting constraints out rather than passing the dish to the scorer follows
> this section's own rationale: a change to constraint rules should no more
> touch flavour scoring than a change to composition does.

Phase 1 ships exactly **one** composer, `SumAndClamp`, implementing §1: sum each
dimension across the dish and clamp to `0..5`. No other composer is built.

The split exists because composition is the part most likely to change. A
recipe pattern with synergies, an ingredient that suppresses another, or a
technique that transforms flavour all change *how ingredients combine* — none of
them change how a profile is scored against a customer. With the seam in place,
such a change swaps the composer and leaves scoring, feedback selection, rating
bands, and constraints untouched, and each stage can be pinned by golden cases
independently.

Which composer runs is selected by the **ruleset**, optionally informed by a
matched `RecipePatternDefinition` (technical architecture §4.3). It is
deliberately *not* a property the content itself chooses — otherwise an
ingredient could silently change the rules of the game.

This is a boundary, not an implementation. Adding a second composer requires an
ADR.

Both stages touch no repository, clock, or randomness.

Output — `Evaluation`:

| Field | Type |
|---|---|
| `score` | `int`, 0–100 |
| `band` | `RatingBand` |
| `constraint_satisfied` | `bool` |
| `violated_constraints` | `ViolatedConstraint` for each violated boundary |
| `strongest_match` | `Dimension` or absent |
| `largest_miss` | `Dimension` or absent |
| `per_dimension` | target, actual, weight, penalty for each weighted dimension |

`per_dimension` exists so tests and a future debug view can show the arithmetic
without the evaluator formatting anything. It carries no display strings.

`violated_constraints` carries a **value copy** of each violated boundary — its
`kind`, `subject`, and `explanation_key` — not a reference to the authored
`CustomerConstraint`. A copy for the same reason `per_dimension` is one: the
evaluation is a statement about a moment, and content Resources are shared and
must be treated as immutable at runtime (`AGENTS.md` rule 7).

> **Amended 2026-08-05, superseding `violated_constraint_ids: Array[StringName]`.**
> That field carried each violated constraint's `subject`, which cannot identify a
> boundary. Measured on 4.7.1:
>
> ```text
> two identical FORBID_TAG(soy)                 -> [&"soy", &"soy"]   validator: []
> REQUIRE_INGREDIENT(soy) plus FORBID_TAG(soy)  -> [&"soy", &"soy"]
> ```
>
> In the second case **both constraints genuinely fire** — the require fails
> because no ingredient has that `content_id`, the forbid fails because the dish
> carries the tag. Two identical entries stating opposite things: "you left soy
> out" and "you put soy in". A presenter cannot tell them apart, cannot reach the
> `explanation_key` holding the player-facing reason, and cannot distinguish
> require from forbid.
>
> The `subject` was also documented as "already namespaced content identity",
> which is false: `ContentValidator` applies `ID_PATTERN` to `content_id` only,
> and a tag is checked for non-emptiness alone. Shipped tags are `soy`, `vegan`,
> `gluten`, `fermented` — none namespaced. The docstring was corrected in
> `688a337`; this amendment fixes the contract underneath it.
>
> §5 gains the duplicate-rejection rule that makes the remaining identity
> question moot.

### 10. Invalid actions

Rejected commands return an explicit result and **emit no event**. Events are
accepted facts; a rejection is not one. This is a contract property, not an
implementation detail — replays must not contain rejected input.

| Condition | Error |
|---|---|
| Unknown customer id in a `StartSession` roster | `UNKNOWN_CUSTOMER` |
| Empty `StartSession` roster | `EMPTY_ROSTER` |
| Unknown ingredient id | `UNKNOWN_INGREDIENT` |
| Ingredient already selected | `DUPLICATE_INGREDIENT` |
| Dish already holds three | `DISH_FULL` |
| Removing an unselected ingredient | `NOT_SELECTED` |
| Submitting an empty dish | `EMPTY_DISH` |
| Any command in the wrong phase | `INVALID_PHASE` |

Per AGENTS.md, these are recoverable player errors and must not use `assert`.

**A repeated customer id in a roster is legal.** The same customer visiting twice
in one shift is a plausible day, not an authoring mistake, and forbidding it would
foreclose a design option that has not been considered yet. This differs
deliberately from DEC-021's stance on duplicate *constraints*, which are rejected:
two identical boundaries on one customer are the same boundary written twice and
say nothing new, whereas two visits are two encounters with their own dishes and
their own `EncounterResult`.

`UNKNOWN_CUSTOMER` and `EMPTY_ROSTER` were added in DEC-023. `StartSession`
receives its roster from the caller rather than from validated content, so the
handler cannot assume the ids resolve — `ContentValidator` never sees this input.

### 11. Minimal fixture set (resolves Q-001)

**Three ingredients and two customers**, matching the GDD's Week 1 milestone,
and explicitly **evaluator contract fixtures rather than a playable slice**.

They must exercise all four bands, a two-dimension weighted customer, a
constrained customer, a hard violation capping at 39, and both feedback fields.
Seven dishes are possible, so golden cases can enumerate the space exhaustively.

**Solvability is a property of the session, not of each customer.** A customer
may be hard, or even impossible, to fully satisfy with the pantry available; what
must hold is that the day as a whole is completable and that each encounter
teaches the player something. Per-customer band reachability is explicitly not a
requirement, so a reaction line authored for a band that customer cannot reach is
correct content rather than dead weight — the pantry may change around them.

Two consequences. Golden cases (#6) cover bands across the session rather than
per customer. And a customer whose best available dish lands in `MIXED` is a
legitimate encounter, not a balance defect.

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

**Composing and scoring in one function.** Simpler today. Rejected because
composition is the part most likely to change — synergies, suppressions,
techniques — and fusing it to scoring would mean every such change touches
feedback, bands, and constraints too. The seam costs one type and no code.

**Letting a dish or ingredient select its own flavour model.** Rejected:
content would then be able to change the rules of the game, which inverts the
data-driven boundary in AGENTS.md rule 8. The ruleset selects the composer.

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

- Content validation rejects a customer with all-zero weights, and rejects any
  `target` or `weight` outside `0..5`.
- The evaluator is implemented as two functions with `FlavorProfile` between
  them, not one. Adding a second composer requires an ADR.
- The constant relationships in §1 — a single ingredient cannot reach the
  highest targets, and the cap discards surplus — must survive any change to
  those numbers.
- **Adding a flavour dimension appends to §1; it never inserts.** Existing
  customers omit the new dimension, so its weight defaults to 0 and their scores
  are unchanged — verified against the executable model. Inserting mid-list
  instead would shift the index used as the final feedback tie-break and could
  silently flip `strongest_match` or `largest_miss` in existing golden cases. A
  new dimension also changes the GDD, which names five, so it needs a GDD
  revision and a superseding ADR, not just a content edit.
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
