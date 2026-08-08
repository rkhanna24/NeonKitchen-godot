# Proposal — Run B: the remaining five customers

Pantry Keeper proposal only. Nothing here is canon; the Health Inspector turns
what the human keeps into `.tres`, and the Recipe-Space Analyst checks the
viability and overlap claims made qualitatively below.

No new ingredients are proposed. The twelve-ingredient pantry shipped in Run A
is complete and is used as-is; this run is customers and their reaction lines
only.

---

## 1. Ingredients

None proposed. See above.

---

## 2. Customers

Reference pantry (content_id: savory/spicy/fresh/comfort/adventurous, tags):

```
chickpeas              1 0 0 2 0  legume, vegan
chili_crisp            2 2 0 0 0  vegan
citrus_chili_paste     0 3 1 0 2  fermented, vegan
citrus_herbs           0 0 1 0 2  raw, vegan
coconut_milk           0 0 0 2 1  vegan
kimchi                 1 1 0 0 3  fermented, vegan
mushrooms              2 0 0 1 0  vegan
pickled_cucumber       0 0 2 0 1  pickled, vegan
rooftop_lettuce        0 0 3 0 0  raw, vegan
smoked_fish            3 0 0 1 0  fish, smoked
soy_broth              2 0 0 2 0  soy, vegan
thick_wheat_noodles    1 0 0 3 0  gluten, vegan
```

### 2.1 `customer.rig_partner` — Rig Partner

*"A colleague of the Solar Rig Tech, on a contract with them to fix up the
North Tower rooftop. The work is contracted and shared, not solitary."*

| Dimension | Target | Weight |
|---|---|---|
| Savory | 3 | 2 |
| Spicy | 0 | 0 |
| Fresh | 0 | 0 |
| Comfort | 0 | 0 |
| Adventurous | 4 | 3 |

Constraints: none.

`name_key`: `customer.rig_partner.name` · `request_key`:
`customer.rig_partner.request` · `reaction_key`: `customer.rig_partner.reaction`

**Rationale.** The Solar Rig Tech already owns savory-plus-comfort — the
straightforward "feed me after a hard shift" read. A colleague on the same
contract shouldn't be a reskin of that customer, so this one keeps the same
grounded savory floor but pairs it with a genuine adventurous target, which
needs at least two ingredients to reach. It reads as someone doing the same
physical work but more open to trying something odd on the side — plausible
for two people sharing a job rather than one person alone with it, without
inventing anything about their relationship beyond what the brief states.

### 2.2 `customer.office_worker` — Office Worker

*"Slipped out of stuffy corporate catering to find something interesting.
Their reason for standing at the truck is an appetite the provided food does
not meet."*

| Dimension | Target | Weight |
|---|---|---|
| Savory | 0 | 0 |
| Spicy | 0 | 0 |
| Fresh | 4 | 2 |
| Comfort | 0 | 0 |
| Adventurous | 4 | 3 |

Constraints: none.

`name_key`: `customer.office_worker.name` · `request_key`:
`customer.office_worker.request` · `reaction_key`:
`customer.office_worker.reaction`

**Rationale.** "An appetite the provided food does not meet" reads as boredom
with something bland and probably heavy (catering trays), not hunger or
hardship. Fresh and Adventurous both set at 4 means neither is reachable from
a single ingredient in isolation, and the pantry's few double-duty
fresh-plus-adventurous ingredients (pickled cucumber, citrus chili paste)
become genuinely valuable rather than a single obvious answer — pure Fresh
(rooftop lettuce) or pure Adventurous (kimchi) alone will not be enough.

### 2.3 `customer.night_courier` — Night Courier

*"Between deliveries. Establishes GDD §2.2's worked-example voice as a shipped
customer."*

| Dimension | Target | Weight |
|---|---|---|
| Savory | 0 | 0 |
| Spicy | 2 | 1 |
| Fresh | 0 | 0 |
| Comfort | 4 | 3 |
| Adventurous | 0 | 0 |

Constraints: `FORBID_TAG(fermented)` — explanation key
`customer.night_courier.constraint.fermented`.

`name_key`: `customer.night_courier.name` · `request_key`:
`customer.night_courier.request` · `reaction_key`:
`customer.night_courier.reaction`

**Rationale.** Comfort is the dominant, real need — something that holds
through the rest of a route — with a light, low-weight preference for heat on
top. Per DEC-027 these targets are authored on their own merits, not to
reproduce the GDD's worked-example score; the one deliberate callback is the
`fermented` boundary, which is the courier's own established line ("my
stomach is already arguing with me") rather than a number chosen to match a
narrated dish. Because `fermented` removes both citrus chili paste and kimchi,
the pantry's only remaining source of real spice is chili crisp — but Comfort
is carried by several unrelated ingredients (noodles, chickpeas, coconut
milk, soy broth), so the customer does not collapse into "always add chili
crisp." Comfort alone, built two different ways, already satisfies this
customer; chili crisp is a bonus route, not the only one.

### 2.4 `customer.block_boss` — Block Boss

*"His gang controls the block the truck is parked on, and the truck needed
their approval to be there safely. In his own neighbourhood he is relaxed and
off watch — but always on guard."*

| Dimension | Target | Weight |
|---|---|---|
| Savory | 5 | 3 |
| Spicy | 0 | 0 |
| Fresh | 0 | 0 |
| Comfort | 2 | 2 |
| Adventurous | 0 | 0 |

Constraints: `FORBID_TAG(raw)` — explanation key
`customer.block_boss.constraint.raw`.

`name_key`: `customer.block_boss.name` · `request_key`:
`customer.block_boss.request` · `reaction_key`: `customer.block_boss.reaction`

**Rationale.** "Block Boss" names only his personal role at the counter, not
the gang itself — the gang's name is one of the Lore Bible's still-open
questions and this proposal does not answer it. A savory target of 5 forces a
real two-ingredient combination (no single savory ingredient reaches it), and
a low-moderate Comfort target reads as "something with weight to it, not
something soft" — distinct from the customers who want a lot of Comfort.
`FORBID_TAG(raw)` is read here as caution rather than diet: someone "always on
guard" wanting everything visibly cooked through, not a claim about any real
dietary practice. It costs the player the pantry's two raw-tagged ingredients
(citrus herbs, rooftop lettuce) — a real but not crippling boundary, and one
that happens not to overlap with anything this customer would otherwise want.

### 2.5 `customer.old_local` — Old Local

*"Lives around the block and has seen the city go through everything."*

| Dimension | Target | Weight |
|---|---|---|
| Savory | 3 | 2 |
| Spicy | 0 | 0 |
| Fresh | 0 | 0 |
| Comfort | 0 | 0 |
| Adventurous | 0 | 3 |

Constraints: none.

`name_key`: `customer.old_local.name` · `request_key`:
`customer.old_local.request` · `reaction_key`: `customer.old_local.reaction`

**Rationale.** "Seen the city go through everything" reads as someone
unimpressed by novelty rather than someone deprived or in need — the opposite
shape from the Rig Partner and Office Worker, who both carry real Adventurous
weight toward a high target. Here Adventurous is weighted at 3 with a target
of 0: a strong, real dislike, not "no preference." Combined with a moderate
Savory want, most of the pantry's plainer ingredients satisfy this customer
easily — the puzzle for the player is restraint, not discovery: the interest
is in noticing that the exciting-looking ingredients are exactly the ones to
leave out, which is a different kind of lesson than any other customer in the
roster teaches.

---

## 3. Localisation values

```
customer.rig_partner.name,Rig Partner
customer.rig_partner.request,"We've been up on the north tower together since sunup — get me something with some real weight to it, and don't be shy trying something odd on the side. I'm not picky tonight."
customer.rig_partner.reaction.delighted,"Now that's worth climbing back up for. Save the recipe — my partner's going to want to know."
customer.rig_partner.reaction.satisfied,"Solid. This'll carry both of us through the rest of the shift."
customer.rig_partner.reaction.mixed,"It's alright. Was hoping for something with a bit more to it, honestly."
customer.rig_partner.reaction.dissatisfied,"My partner's going to laugh when I hear what I paid for this."

customer.office_worker.name,Office Worker
customer.office_worker.request,"Compliance ran out of the good trays hours ago and I still needed lunch. Surprise me with something I couldn't get in that conference room — something bright, not another sad sandwich."
customer.office_worker.reaction.delighted,"This is exactly what that conference room lunch could never be. Worth the walk."
customer.office_worker.reaction.satisfied,"Better than anything on the catering cart. I might even make it back before the meeting starts."
customer.office_worker.reaction.mixed,"It's a step up from the break room, at least."
customer.office_worker.reaction.dissatisfied,"I skipped a meeting for this? I should have just eaten the sad sandwich."

customer.night_courier.name,Night Courier
customer.night_courier.request,"Route's got two more stops before the timer runs out. Give me something with a real kick, something that'll stick with me till the next drop — just keep anything fermented off my plate, my stomach's already had a rough night."
customer.night_courier.reaction.delighted,"Now that's fuel. I'm already thinking about the next drop."
customer.night_courier.reaction.satisfied,"That'll hold me to the last stop. Good call."
customer.night_courier.reaction.mixed,"It'll do. Was hoping it'd hit harder, though."
customer.night_courier.reaction.dissatisfied,"This isn't getting me through the rest of the route."
customer.night_courier.constraint.fermented,"Nothing sour or fermented tonight — my stomach's already arguing with me on this route."

customer.block_boss.name,Block Boss
customer.block_boss.request,"This corner's mine, so for once I get to sit and actually eat instead of just watching it. Load me up with something that actually tastes like something — no mush — and cook it all the way through. I don't trust anything on my plate that still looks alive."
customer.block_boss.reaction.delighted,"Now this is why I let you park on my corner."
customer.block_boss.reaction.satisfied,"Not bad. You can stay another night."
customer.block_boss.reaction.mixed,"It's fine. Don't get comfortable."
customer.block_boss.reaction.dissatisfied,"This corner's mine, and even I wouldn't serve this."
customer.block_boss.constraint.raw,"Cook it all the way through. I don't trust anything on my plate that still looks alive."

customer.old_local.name,Old Local
customer.old_local.request,"I've watched trucks come and go off this corner for years, and eaten off plenty of them. Don't get fancy with me — just make it taste like something I'd actually recognize, with some real weight behind it."
customer.old_local.reaction.delighted,"Now that's a plate. Tastes like something this block used to make, before everyone forgot how."
customer.old_local.reaction.satisfied,"Good, honest food. Can't complain about that."
customer.old_local.reaction.mixed,"It's fine. I've had better off carts that don't exist anymore."
customer.old_local.reaction.dissatisfied,"I've outlasted worse than you on this corner, and this still isn't it."
```

---

## 4. Design intent

**Rig Partner** — expected satisfying dishes come from at least two genuinely
different routes to a high Adventurous with a moderate Savory floor: a
savory-anchored route (mushrooms or smoked fish paired with kimchi, which
alone supplies most of the Adventurous target) and a citrus route (citrus
chili paste with citrus herbs, which reaches a comparable Adventurous total
with no savory contribution at all and relies on the Savory target's own
weight tolerating the miss). These are not the same puzzle wearing different
ingredients — one leans on a single big Adventurous source plus an unrelated
Savory anchor, the other builds Adventurous additively from two ingredients
that contribute nothing to Savory. A player who only ever reaches for kimchi
will not notice the second route exists.

**Office Worker** — the interesting tension is that no single ingredient
supplies both Fresh and Adventurous at a useful level on its own: rooftop
lettuce is pure Fresh, kimchi is pure Adventurous, and pickled cucumber and
citrus chili paste each split the difference. The puzzle is recognising that
the split-difference ingredients are more valuable here than the pure ones,
which is the opposite lesson the Rig Partner teaches with the same
Adventurous target — a good sign the two customers are not interchangeable
despite sharing a number.

**Night Courier** — the puzzle is that `FORBID_TAG(fermented)` removes both
of the pantry's big Adventurous-and-Spicy ingredients at once (kimchi, citrus
chili paste), leaving chili crisp as the only real source of heat. A player
who has learned "reach for kimchi or citrus chili paste when you need an edge"
from the other customers has to unlearn it here. But because the dominant
target is Comfort, not Spicy, the encounter is still solvable comfortably
without chili crisp at all — noodles-plus-legume or noodles-plus-coconut-milk
routes exist that never touch the forbidden tag or its one remaining
alternative, so the constraint narrows one dimension without making the whole
customer depend on a single ingredient.

**Block Boss** — the puzzle is combining two real savory contributors to
clear a target no single ingredient reaches, while `FORBID_TAG(raw)` quietly
removes an option that would otherwise be irrelevant to this customer anyway
(neither raw-tagged ingredient carries Savory), so the boundary reads as
characterisation rather than a mechanical trap. The more interesting tension
is the Comfort target sitting low: a player defaulting to "add something
starchy for Comfort" will overshoot a target this customer does not actually
want overshot, on top of everyone else's Comfort-seeking profiles.

**Old Local** — deliberately the easiest customer to satisfy and the easiest
to ruin. A wide range of plain, Savory-leaning, zero-Adventurous combinations
clear the target comfortably, including a single ingredient on its own. The
puzzle is not finding a solution but resisting the instinct — trained by
every other customer in this batch — to reach for something with an
Adventurous kick, since that instinct is exactly wrong here. This customer is
the deliberate counterweight to the Rig Partner and Office Worker's shared
appetite for novelty.

---

## 5. Open questions

1. **Voice rule 2 versus the three shipped customers.** All three shipped
   requests name a flavour dimension outright — the Solar Rig Tech asks for
   "something hearty and savory," the Late-Shift Medic for "something fresh
   and light," the Scrap-Market Trader for "something comforting." Content
   Voice rule 2 ("never name a flavour dimension") is stated to govern
   customer requests as well as ingredient descriptions, and this run's brief
   said all six rules bind on the five new requests and twenty reaction
   lines. I wrote the five new customers to comply with rule 2 strictly,
   which means they now read in a noticeably different register from the
   three already shipped — "give me something with a real kick" rather than
   "something with just a little kick." I did not resolve this by bending
   either set of text to match the other. A human call is needed: should the
   three shipped requests be revised for consistency, or does shipped
   precedent mean rule 2 was never meant to bind requests this literally?

2. **"Block Boss" as a title.** It names only this character's personal role,
   not the gang controlling the block — the gang's name is explicitly one of
   the Lore Bible's still-open questions, and I did not invent one. But it is
   still a naming choice touching that unnamed area, and I'd rather have it
   checked than assumed acceptable.

3. **Block Boss's register.** The Lore Bible is explicit that the arrangement
   is "not antagonistic" and that he is "relaxed... but always on guard." I
   aimed for dry and wary rather than threatening (his dissatisfied line is a
   joke at his own expense, not a warning), but tone is the human's call per
   Content Voice's own ownership statement, and this is the one customer in
   the batch where a small wording shift could read as more menacing than
   intended.

4. **Office Worker's implied workplace.** "Compliance," "conference room," and
   "catering cart" are generic corporate-office texture, not a named company
   or department, and I did not tie them to the Lore Bible's proposed
   (unnamed) "Corporate Power" faction shape. Flagging only because that
   faction shape exists in draft and a human may want this customer to gesture
   toward it more, or less, deliberately.

5. **Night Courier's phrasing overlap with GDD §2.2.** DEC-027 says not to
   reverse-engineer targets or weights to reproduce the worked example's
   score, and I did not — this customer's targets and weights are original.
   But the request text deliberately reuses the established line "my stomach
   is already arguing with me" and the `fermented` boundary itself, because
   the brief frames this customer as establishing that worked-example voice.
   Flagging so a human can confirm that reading — voice may carry over,
   numbers may not — is the intended boundary, since it's a judgment call I
   made rather than one stated outright.

6. **Old Local's implied history.** "I've watched trucks come and go off this
   corner for years" is meant to describe other vendors in general, not this
   truck's own ownership history — the Cook's identity and the truck's
   history are both still open (Lore Bible, open question 7). I tried to
   phrase it to avoid implying anything about this truck specifically, but
   asking a human to check that reading landed as intended rather than
   quietly answering a question I'm not positioned to answer.
