# Content Proposal — Late-Shift Medic

Status: **candidate only**. Nothing here is canon. One new ingredient, one new
customer, exactly as scoped. All arithmetic below was computed by hand against
`core/domain/rules/flavour_scorer.gd` and `ADR 0004` §3; the Recipe-Space
Analyst should re-verify independently before anything is accepted.

## 1. Ingredients

### `ingredient.rooftop_greens`

| Field | Value |
|---|---|
| `content_id` | `ingredient.rooftop_greens` |
| `savory` | 0 |
| `spicy` | 0 |
| `fresh` | 3 |
| `comfort` | 0 |
| `adventurous` | 0 |
| `tags` | `raw`, `vegan` |

**Rationale.** The existing three-ingredient pantry (`neon_noodles`,
`umami_broth`, `ember_chili_paste`) has exactly one source of Fresh
(`ember_chili_paste`, fresh 1) and no ingredient with Fresh above 1. A
"fresh and light" customer needs a second, larger Fresh source that does not
also add Comfort — otherwise "light" is undercut by the same ingredient. A
plain hydroponic green, grown in the truck's own rooftop planter (an object
the GDD already names as part of the truck's visual identity), is the
smallest addition that fills that gap without touching any other dimension,
so it cannot quietly become a better version of an existing ingredient for
unrelated customers. See §4 for the arithmetic proof and the check against
`solar_tech` / `scrap_trader`.

## 2. Customers

### `customer.late_shift_medic`

| Dimension | Target | Weight |
|---|---|---|
| Savory | 0 | 0 |
| Spicy | 0 | 0 |
| Fresh | 4 | 3 |
| Comfort | 1 | 2 |
| Adventurous | 0 | 0 |

Constraints: **none.** The brief describes a flavour preference ("fresh and
light, nothing heavy"), not a stated boundary (allergy, ingredient refusal,
dietary rule). Per ADR 0004 §5, a boundary is a `FORBID_*` constraint; a
preference — including a strong dislike — is a weighted target. "Nothing
heavy" is modelled as a *low* Comfort target with a *non-zero* weight
(dislike, not indifference), matching the ADR's explicit rule that weight 0
means "ignored," never "wants zero." I did not invent a dietary boundary that
the brief never stated — see Open Questions §1 if the human wants one added.

**Rationale for the two-dimension shape.** Both existing customers
(`solar_tech`, `scrap_trader`) weight exactly two dimensions, leaving three
free for the player. This customer follows the same shape: Fresh 4 (weight 3)
is the request itself, Comfort 1 (weight 2) is "nothing heavy" as an active
dislike rather than silence. Fresh 4 cannot be reached by any single
ingredient in the pantry (cap 3), so it forces a two-ingredient combination —
this is the required puzzle shape, not a lookup.

## 3. Localisation values

```csv
ingredient.rooftop_greens.name,Rooftop Greens
ingredient.rooftop_greens.description,"Leafy greens pulled straight from the truck's rooftop planter — crisp, cool, and the closest thing to fresh air on this block."
customer.late_shift_medic.name,Late-Shift Medic
customer.late_shift_medic.request,"Something fresh and light, please — nothing heavy. I've been elbow-deep in triage since second shift and my stomach won't forgive anything rich right now."
customer.late_shift_medic.reaction.delighted,"Light, clean, and exactly what my stomach needed after a shift like that."
customer.late_shift_medic.reaction.satisfied,"Good and light — I can actually feel human again."
customer.late_shift_medic.reaction.mixed,"It's alright, but heavier than I wanted after tonight."
customer.late_shift_medic.reaction.dissatisfied,"This is way too heavy. My stomach's not going to forgive either of us for this."
```

Every key follows the existing pattern in `content/base/localization/en.csv`:
`<content_id>.name`, `<content_id>.description` for ingredients;
`<content_id>.name`, `<content_id>.request`, and
`<reaction_key_prefix>.<band>` (four lines: `.delighted`/`.satisfied`/
`.mixed`/`.dissatisfied`) for customers. I confirmed this by reading
`docs/adr/0004-phase-1-contracts.md` §8a: `reaction_key` on
`CustomerDefinition` is a **prefix**, and `CustomerReacted` resolves the most
specific of `<prefix>.<band>.<qualifier>` (deferred), `<prefix>.<band>`
(what Phase 1 authors), or `<prefix>` (fallback) — so I authored exactly the
four `<prefix>.<band>` lines and nothing else, matching what `solar_tech` and
`scrap_trader` already do in `en.csv`. This customer has no constraints, so
no `constraint.*` key is needed.

## 4. Design intent and worked arithmetic

Formula, from `core/domain/rules/flavour_scorer.gd` (ADR 0004 §3), for each
weighted dimension:

```text
error       = |actual - target|
max_error   = max(target, 5 - target)
penalty     = weight * error
max_penalty = weight * max_error
score       = 100 - (sum(penalty) * 100) / sum(max_penalty)
```

Bands: Delighted 85–100, Satisfied 65–84, Mixed 40–64, Dissatisfied 0–39
(ADR 0004 §4).

**Proof the medic is unsolvable on the existing three-ingredient pantry.** I
enumerated every 1-, 2-, and 3-ingredient combination of `neon_noodles`,
`umami_broth`, and `ember_chili_paste` against Fresh target 4 (w3) / Comfort
target 1 (w2):

| Dish | Fresh | Comfort | Score | Band |
|---|---|---|---|---|
| chili alone | 1 | 0 | 45 | Mixed |
| chili + broth | 1 | 2 | 45 | Mixed |
| chili + noodles | 1 | 3 | 35 | Dissatisfied |
| noodles alone | 0 | 3 | 20 | Dissatisfied |
| broth alone | 0 | 2 | 30 | Dissatisfied |
| noodles + broth | 0 | 5 | 0 | Dissatisfied |
| chili + noodles + broth | 1 | 5 | 15 | Dissatisfied |

Best achievable without a new ingredient: **45, Mixed.** The request is
genuinely unsolvable to Satisfied or better on the current pantry, which is
exactly the failure the brief asks the new ingredient to fix.

**With `ingredient.rooftop_greens` (fresh 3, comfort 0, all else 0):**

Dish = `ember_chili_paste` (spicy 3, fresh 1, adventurous 2) +
`ingredient.rooftop_greens` (fresh 3) → profile Savory 0, Spicy 3, Fresh 4,
Comfort 0, Adventurous 2.

| Dimension | Target | Actual | Weight | Error | Penalty | Max error | Max penalty |
|---|---|---|---|---|---|---|---|
| Fresh | 4 | 4 | 3 | 0 | 0 | 4 | 12 |
| Comfort | 1 | 0 | 2 | 1 | 2 | 4 | 8 |

`sum(penalty) = 2`, `sum(max_penalty) = 20`.
`score = 100 - (2 * 100) / 20 = 90` → **Delighted.**
Strongest match: Fresh (penalty 0). Largest miss: Comfort (penalty 2, > 0
so reported).

A second good dish exists — `ember_chili_paste` + `rooftop_greens` +
`umami_broth` (adds Savory 2, Comfort 2, unchanged Fresh 4): Comfort error is
still 1 (`|2-1|`), so the arithmetic is identical and this also scores 90,
Delighted. A weaker but still viable dish is `rooftop_greens` alone (Fresh 3,
Comfort 0): Fresh error 1, penalty 3; Comfort error 1, penalty 2; score
`100 - 500/20 = 75`, Satisfied. Adding `neon_noodles` to that (Fresh 3,
Comfort 3) drags it back down to exactly 65, Satisfied at the boundary —
demonstrating the "more ingredients is not automatically better" property
ADR 0004 §1 names directly, using this same customer.

**Why this is a puzzle, not a lookup.** The obvious move — serve the new
fresh ingredient alone — only reaches Satisfied (75), because Fresh alone
tops out at 3 and a single ingredient can never reach the target of 4 (ADR
0004 §1). The ingredient that actually unlocks Delighted is
`ember_chili_paste`, which is filed in the pantry as "the spicy one" and
carries a secondary Fresh value (1) that is easy to overlook. Recognising
that a spicy/adventurous ingredient is also the pantry's second Fresh source,
and that it carries zero Comfort so it does not undercut "light," is the
actual insight the player has to find. `umami_broth` is a safe third slot
(same Comfort error either way); `neon_noodles` is a trap third slot (too
much Comfort). See Open Questions §6 for the tone question this raises.

**Check against existing customers (not a universal solvent).**

- `customer.solar_tech` (Savory target 3 w2, Comfort target 5 w3): its best
  existing dish, `umami_broth` + `neon_noodles` (Savory 3, Comfort 5), already
  scores 100. `rooftop_greens` contributes 0 to both weighted dimensions, so
  adding it as a third ingredient leaves Savory and Comfort unchanged
  (Comfort is already clamped at 5) — the score stays 100. It cannot improve
  an already-perfect dish and it cannot replace either comforting ingredient
  without lowering the score, so it does not change this customer's puzzle.
- `customer.scrap_trader` (Spicy target 1 w1, Comfort target 3 w2 [default —
  not overridden in the `.tres`], forbids tag `soy`): **correction.** An
  earlier draft of this section named `ember_chili_paste + neon_noodles`
  (score 80, Satisfied) as this customer's best existing dish. That arithmetic
  was real but the dish was not the best — it is strictly dominated. The
  true best existing (pre-change) dish is **`neon_noodles` alone: Spicy
  error `|0-1|=1` → penalty `1*1=1` (max 4); Comfort error `|3-3|=0` → penalty
  0 (max 6); `score = 100 - 100/10 = 90`, Delighted.** `neon_noodles` alone
  beats `ember_chili_paste + neon_noodles` on every axis that matters here —
  same Comfort penalty, a lower Spicy penalty (chili's Spicy 3 pushes the
  error from 1 to 2), and one fewer ingredient — so adding chili to that dish
  can only ever hurt this customer, never help.
  Redoing the "not a universal solvent" check against the corrected baseline
  of 90: does `rooftop_greens` let this customer beat 90, or dodge the soy
  constraint? Substituting greens for noodles (`chili + greens`: Spicy 3,
  Comfort 0) scores `100 - 800/10 = 20`, Dissatisfied — far worse, because
  greens contributes nothing to Comfort. Adding greens to the existing best
  (`neon_noodles + rooftop_greens`: Spicy 0, Comfort 3 — unchanged from
  `neon_noodles` alone, since greens carries Spicy 0 and Comfort 0) scores
  the same 90 — a tie, not an improvement, because greens is inert on both of
  this customer's weighted dimensions. So post-change the best is still 90,
  now achieved by two tied dishes (`neon_noodles` alone, `neon_noodles +
  rooftop_greens`) instead of one — no regression, and `rooftop_greens` still
  does not help this customer dodge the soy constraint or exceed their
  pre-existing ceiling.

Both checks confirm `rooftop_greens` only fills the one hole it was designed
for (Fresh, without Comfort) and does not quietly improve unrelated
customers.

## 5. Open questions

1. **No stated dietary/allergen boundary.** The brief describes a flavour
   preference only. I deliberately did not invent a `FORBID_*` constraint
   (e.g., a clinical "no stimulants" or similar) because ADR 0004 §5 treats a
   boundary as an absolute, and manufacturing one for a medic based on
   profession-stereotype rather than the brief would be a tone/canon decision
   I'm not authorized to make. If the human or Worldkeeper wants this
   customer to carry a constraint, that's a decision for them, not a default
   I should have picked.
2. **Scope of "light."** I read "nothing heavy" as targeting Comfort only,
   leaving Savory, Spicy, and Adventurous unweighted (free for the player).
   An alternative reading treats "light" as also implying low Spicy or low
   Savory. I did not add those because the brief's own wording ("fresh and
   light") maps most directly to Fresh/Comfort, and widening the weighted set
   would need re-checking solvability from scratch. Flagging this as a
   tone call, not a mechanical one.
3. **Role-based identifier vs. a personal name.** `solar_tech` and
   `scrap_trader` are both role-based ids, which `customer.late_shift_medic`
   follows for consistency. `customer_definition.gd`'s own doc comment,
   however, illustrates the field with a personal name
   (`customer.mina_afterhours`), suggesting the canon direction may prefer
   named characters once the Worldkeeper is active. I stayed with the
   established base-content convention rather than guess at a name, but flag
   this in case the human wants a name attached now.
4. **Setting/canon fit for "rooftop greens."** The GDD names rooftop
   planters as part of the truck's visual identity, so I used that as the
   ingredient's origin story rather than inventing a new location. Whether
   this specific ingredient should instead tie to a named garden, supplier,
   or neighbourhood the Worldkeeper already has in mind is a canon call I
   can't make from the documents I was given.
5. **Medic's workplace/faction.** "Late-shift medic" has no established home
   in the documents I read — no clinic, ward, or faction is named anywhere in
   `docs/design/`. Portrait, exact voice, and any backstory beyond the one
   request/four reaction lines above are left for the Worldkeeper and human,
   per the GDD's own division of labour (Pantry Keeper proposes flavour and
   mechanics; Worldkeeper stewards lore; the human decides canon).
6. **Delighting the medic requires the pantry's spiciest, most fermented
   ingredient.** Both of the medic's Delighted dishes —
   `ember_chili_paste + rooftop_greens` and
   `ember_chili_paste + umami_broth + rooftop_greens`, each scoring 90 —
   require `ember_chili_paste`. Fresh 4 is reachable only as greens(3) +
   chili(1); no other ingredient in the four-item pantry has Fresh above 1,
   so chili is mandatory for the top band. The best chili-free dish
   (`rooftop_greens` alone or `umami_broth + rooftop_greens`) scores 75,
   Satisfied — a full band lower. This is mechanically legal: the medic's
   Spicy weight is 0, so Spicy is ignored, not disliked, and nothing in the
   scoring model is violated. But it means the only way to delight a
   customer who explicitly asked for "fresh and light, nothing heavy" is to
   add fiery, fermented chili paste. §4 frames this as the puzzle's intended
   insight (the pantry's "spicy one" is secretly its second Fresh source).
   I am flagging, not resolving, whether that reads to a player as the
   intended puzzle or as the model quietly contradicting its own fiction.
   Numbers for the human to weigh: Delighted = 90 via chili+greens or
   chili+broth+greens (both require chili); chili-free ceiling = 75 via
   greens alone or broth+greens (Satisfied, one band lower). I have not
   re-weighted Spicy or added a constraint to soften this — either would be
   a tone call the human owns, and would invalidate the enumeration the
   Recipe-Space Analyst already ran against the numbers as authored.
