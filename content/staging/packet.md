# Task Context — Run B: five customers and twenty reaction lines

- **Task ID:** #24, second of two runs
- **Specialist role:** Pantry Keeper — proposal only
- **Goal:** Complete the eight-customer roster. Five customers, each with four reaction lines.
- **Player-visible outcome:** The encounters the first playtest runs on. #10 is blocked on this.

Run A shipped the twelve-ingredient pantry. This run makes it playable against eight customers.

---

# Retrieval evidence

### Query: `the remaining five customers`

> `docs/design/Lore Bible.md` — the five are **DECIDED by the human**, recorded in their own terms with no dialogue, constraint, flavour target, or cultural background attached. Those are yours to propose.

**The five, verbatim from the Lore Bible:**

- **The second solar panel technician.** A colleague of the Solar Rig Tech, on a contract with them to fix up the North Tower rooftop. The work is contracted and shared, not solitary.
- **The corporate office worker.** Slipped out of stuffy corporate catering to find something interesting. Their reason for standing at the truck is an appetite the provided food does not meet.
- **The night courier.** Between deliveries. Establishes GDD §2.2's worked-example voice as a shipped customer.
- **The block's gangster.** His gang controls the block the truck is parked on, and the truck needed their approval to be there safely. In his own neighbourhood he is relaxed and off watch — but always on guard.
- **The old local.** Lives around the block and has seen the city go through everything.

### Query: `constraints forbid tag`

> ADR 0004 §5 — four kinds, all hard. **A customer carries 0–2 constraints.** Any violation caps at 39. Constraints match ingredient identity and tags only, never flavour values. A customer may not carry two constraints with the same subject on the same side of the identity/tag divide.

### Query: `reaction key resolution`

> ADR 0004 §8a — `reaction_key` is a **prefix**. Phase 1 authors **four lines per customer, one per band**. "A single static reaction would praise a dish that scored `DISSATISFIED`."

---

## The pantry you are writing against

```
ingredient             sav spi fre com adv  tags
chickpeas                1   0   0   2   0  legume, vegan
chili_crisp              2   2   0   0   0  vegan
citrus_chili_paste       0   3   1   0   2  fermented, vegan
citrus_herbs             0   0   1   0   2  raw, vegan
coconut_milk             0   0   0   2   1  vegan
kimchi                   1   1   0   0   3  fermented, vegan
mushrooms                2   0   0   1   0  vegan
pickled_cucumber         0   0   2   0   1  pickled, vegan
rooftop_lettuce          0   0   3   0   0  raw, vegan
smoked_fish              3   0   0   1   0  fish, smoked
soy_broth                2   0   0   2   0  soy, vegan
thick_wheat_noodles      1   0   0   3   0  gluten, vegan
```

**What a `FORBID_TAG` would actually remove** — a constraint is only interesting if it costs the player something real:

```
legume, pickled, fish, smoked, soy, gluten   remove  1/12
fermented, raw                               remove  2/12
vegan                                        removes 11/12
```

`fermented` is the GDD §2.2 case — it removes the pantry's two most characterful spicy and adventurous sources at once, which is why that example is a puzzle. **A `FORBID_TAG(vegan)` would remove eleven of twelve and is not a boundary, it is a wall.**

## The bar this run must clear

GDD §2.3, now binding because the pantry is twelve:

> Each customer must have **at least three satisfying combinations, including at least two that do not depend on the same central ingredient.** No single recipe should satisfy more than half of the customer roster.

The Analyst will enumerate all 298 dishes against all eight customers and check this. **Design for it rather than hoping.** A customer weighting two dimensions leaves three free, which ADR 0004 §2 names as how three satisfying combinations are achieved without vague targets.

## DEC-027 — do not reverse-engineer the worked example

GDD §2.2 narrates the night courier served noodles + mushrooms + chili crisp and reaching Satisfied. With the shipped pantry that dish scores 66. **The human ruled §2.2 illustrative prose, not a specification.** Author the courier on its own merits. Do not pick targets to make a paragraph reproduce, and do not propose changing an ingredient value.

## Voice

`docs/design/Content Voice.md`, all six rules — binding on requests and all twenty reaction lines. A reaction is a customer speaking, so the register rule matters most here: **if every customer arrives exhausted, none of them reads as exhausted.** Five customers is enough to make that visible.

## Acceptance criteria

- [ ] Five customers, each with per-dimension targets and weights, and 0–2 constraints
- [ ] Twenty reaction lines — four bands each, none praising a `DISSATISFIED` dish
- [ ] Every customer has three satisfying combinations, two on different central ingredients
- [ ] No single dish satisfies more than half the eight-customer roster
- [ ] Any `FORBID_TAG` names a tag some ingredient carries, and removes something worth missing
- [ ] Localisation values for every key — name, request, four reactions, and any constraint explanation

## You may not

- Compute or claim scores. The Analyst checks this next.
- Write `.tres`, or touch anything outside `content/staging/`.
- Resolve one of the **seven open lore questions** by inventing an answer. The city has no name, the truck has no in-fiction name, the North Tower's ownership is undecided, the Scrap Market's formality is undecided, the medic's workplace is unnamed, no faction is named, and the Cook has no identity. A customer who needs one of these is an **escalation**.
- Attribute a real culinary tradition to an in-fiction person or neighbourhood. The city is mixed and diasporic by decision.
