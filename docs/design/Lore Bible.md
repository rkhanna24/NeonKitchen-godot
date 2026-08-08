---
type: lore
display-name: Lore Bible
status: draft
phase: phase-1
version: 0.1
updated: 2026-08-07
governed-by: "[[Neon Kitchen - Game Design Document]]"
tags:
  - neon-kitchen
  - lore
  - worldbuilding
---

# Neon Kitchen: Lore Bible

## Status and Authority

Nothing in this document is canon. The Worldkeeper drafts and reviews world
content; the human is the final authority on canon (GDD §4.1, Worldkeeper
boundary). Every claim below is labeled:

- **ESTABLISHED** — traceable to a cited line of the GDD or to a file under
  `content/base/`. These are facts already true of the shipped game.
- **PROPOSED** — invented for this draft, consistent with what is established,
  and not usable as a fact by any other agent or document until a human
  approves it.

Sections are written to stand alone under retrieval. A section pulled out of
context should not require the rest of this document to make sense.

## The City

**ESTABLISHED**

- The game is set inside a cyberpunk city (GDD §1, "The Game").
- The city is dark, industrial, and lit by corporate neon (GDD §1, "Art
  Direction").
- The wider fiction contrasts this hostile environment with community-scale
  solarpunk care and improvisation (GDD §1, "Three Game Design Pillars,"
  Pillar 3: "Community Within a Hostile City").
- The city has no established name. Neither the GDD nor any shipped content
  names it.

**PROPOSED**

- None. Whether to name the city at all is an open question — see "Open
  Questions for the Human" below.

## Corporate Neon Against Community Solarpunk

**ESTABLISHED.** This contrast is the game's central tonal frame, not
background color. The GDD states it as a pillar: "The larger game contrasts a
harsh cyberpunk environment with care, improvisation, and community-scale
solarpunk. Phase 1 expresses this primarily through customer voice and
ingredient descriptions rather than a separate narrative system" (GDD §1,
Pillar 3). The Art Direction section carries the same split into the truck
itself: dark, industrial, corporate-neon city outside; warm lighting, repaired
technology, reclaimed materials, exposed cables, solar panels, hand-painted
signs, and small planters on the truck (GDD §1, "Art Direction").

Any new district, faction, or character proposed in this document should sit
somewhere on that line between corporate and community, the same way the truck
itself does. Nothing below should be written as simply "neutral city
infrastructure" — that would flatten the pillar the rest of the game is built
to express.

## The Truck

**ESTABLISHED.** The player operates a nomad food truck (GDD §1, "The Game").
It is warm where the city is cold: repaired technology, reclaimed materials,
exposed cables, solar panels, hand-painted signs, and small planters (GDD §1,
"Art Direction"). It has its own rooftop planter — the shipped ingredient
Rooftop Greens is described as "pulled straight from the truck's rooftop
planter" (`content/base/ingredients/rooftop_greens.tres`;
`content/base/localization/en.csv`, `ingredient.rooftop_greens.description`).

**PROPOSED.** None needed here; the truck's established facts are sufficient
to write from.

## The Truck's Name

**PROPOSED — needs human decision.** "Neon Kitchen" is established as the
game's title but nothing in the GDD or shipped content confirms it is also
the truck's in-fiction, hand-painted name. It is a reasonable guess given the
truck has hand-painted signs (GDD §1, "Art Direction"), but a guess is all it
is. See "Open Questions for the Human."

## This Block

**ESTABLISHED.** The phrase appears once, in the shipped description of
Rooftop Greens: "the closest thing to fresh air on this block"
(`content/base/localization/en.csv`, `ingredient.rooftop_greens.description`).

**PROPOSED — a constraint on how this phrase is used going forward.** The
truck is nomadic (GDD §1, "The Game"). "This block" should be read as a
floating reference to wherever the truck is currently parked, not as the name
of one fixed neighborhood the truck always returns to. If a future document
invents a permanent, named district called something like "The Block," with
its own residents and history, that would quietly contradict the nomadic
premise unless someone explicitly decides the truck now has a home base. Until
that decision is made, keep "this block" generic and lowercase, describing
wherever the truck happens to be that night — not a place name.

## The North Tower

**ESTABLISHED.** The Solar Rig Tech's request is the only source: "I've been
rewiring solar panels on the north tower all shift and I want to feel human
again" (`content/base/customers/solar_tech.tres`;
`content/base/localization/en.csv`, `customer.solar_tech.request`).

**PROPOSED.** The North Tower is a fixed landmark, unlike "this block" — it
does not move with the truck. Its panels are being "rewired," which reads as
retrofit or repair rather than routine corporate maintenance, and that fits
the truck's own "repaired technology" motif (GDD §1, "Art Direction") rather
than corporate-neon polish. A plausible reading: the North Tower is old
infrastructure — corporate-built or otherwise — that the Solar Rig Tech and
others now keep running by hand, sitting exactly on the seam between
corporate neon and community solarpunk (see "Corporate Neon Against Community
Solarpunk" above). Whether the tower is currently corporate property,
abandoned, or informally reclaimed is not decided. See "Open Questions for the
Human."

## The Scrap Market

**ESTABLISHED.** The customer's shipped name is "Scrap-Market Trader"
(`content/base/customers/scrap_trader.tres`, `content_id` =
`customer.scrap_trader`, `name_key`; `content/base/localization/en.csv`,
`customer.scrap_trader.name`). No dialogue line describes the market itself —
only the trader's name implies it exists.

**PROPOSED.** A market where reclaimed parts and materials change hands. It is
a plausible source for the truck's own "reclaimed materials" (GDD §1, "Art
Direction"), though that connection is inference, not an established fact —
nothing currently says the truck buys from this market specifically. Whether
the Scrap Market is a formal, licensed market or an informal gray-market trade
is undecided. See "Open Questions for the Human."

## Shift Work

**ESTABLISHED.** Two shipped customers describe their lives by shift. The
Solar Rig Tech has been "rewiring solar panels on the north tower all shift"
(`customer.solar_tech.request`). The Late-Shift Medic has been "elbow-deep in
triage since second shift" (`content/base/customers/late_shift_medic.tres`,
`content_id` = `customer.late_shift_medic`;
`content/base/localization/en.csv`, `customer.late_shift_medic.request`). A
third, the Scrap-Market Trader, does not use the word "shift" but frames their
request around timing too — comfort food that won't leave them "miserable by
morning" (`customer.scrap_trader.request`).

**PROPOSED.** Read together, these suggest a city that runs on continuous,
overlapping shift labor, and a truck whose service hours are built around
feeding people between shifts rather than at conventional mealtimes. This is
a synthesis across three data points, not a quoted fact, and should be treated
as a soft framing assumption rather than a rule.

## The Night Courier

**ESTABLISHED — narrative content, not yet shipped as a customer.** GDD §2.2,
"Moment-to-Moment Play," works its central example around a night courier:
"I need something comforting with enough spice to wake me up. Nothing
fermented tonight—my stomach is already arguing with me." This is GDD prose,
not a `content/base/` file — there is no `night_courier.tres`. It establishes
that a night courier exists as a voice in the fiction, available to be
formalized into the eighth-customer roster without inventing a new archetype
from nothing.

## The Late-Shift Medic's Workplace

**ESTABLISHED.** The Late-Shift Medic does "triage" and works "second shift"
(`customer.late_shift_medic.request`, cited above). No org, building, or name
for where this happens is established anywhere.

**PROPOSED — needs human decision.** A name is needed before this customer's
world-context can be written consistently elsewhere. One candidate,
consistent with "this block" already existing as a floating term (see above):
call it the **Block Clinic** — an informal, community-run triage point rather
than a corporate or municipal hospital, which would fit the community-care
side of Pillar 3. This is a proposal, not a decision: whether the medic works
somewhere informal, corporate, or municipal changes what kind of city this is,
and that choice belongs to the human. See "Open Questions for the Human."

## Community Mutual Aid (a Proposed Faction Shape)

**PROPOSED — no faction of any kind is established anywhere in the GDD or
shipped content.** This section proposes a shape, not a name or history: a
loose, informal network of neighbors, off-the-books technicians, and traders
who keep the North Tower's panels running, might staff something like the
Block Clinic, and might supply the Scrap Market. This would be the human
infrastructure behind "community-scale solarpunk" (GDD §1, "Art Direction") —
the reason repair happens at all in a city that otherwise reads as corporate
and hostile (GDD §1, Pillar 3). Whether this network gets a name, a visible
structure, or stays deliberately informal and unnamed is a human decision. See
"Open Questions for the Human."

## Corporate Power (a Proposed Faction Shape)

**PROPOSED — no faction of any kind is established anywhere in the GDD or
shipped content.** This section proposes a shape only: an unnamed corporate
or utility presence that built infrastructure like the North Tower and now
maintains a distant or absent relationship to its upkeep, which is one way to
explain why the tower's panels need informal rewiring rather than a corporate
service crew. Whether corporate power should be a felt threat, an absent
landlord, or simply unaddressed background is undecided. See "Open Questions
for the Human."

## The Remaining Five Customers

**DECIDED by the human, 2026-08-07.** A third label, distinct from ESTABLISHED
and PROPOSED: these are canon by decision rather than by citation. Recorded in
the human's own terms. **No dialogue, constraint, flavour target, or cultural
background is attached here** — those belong to the Pantry Keeper and the
Customer Designer, and inventing them at this stage would put words in a
customer's mouth before anyone decided how they speak.

Three customers already ship: the Solar Rig Tech, the Scrap-Market Trader, and
the Late-Shift Medic. These five complete the eight the GDD plans.

**The second solar panel technician.** A colleague of the Solar Rig Tech, on a
contract with them to fix up the North Tower rooftop. The work is contracted and
shared, not solitary.

**The corporate office worker.** Slipped out of stuffy corporate catering to find
something interesting. Their reason for standing at the truck is an appetite the
provided food does not meet.

**The night courier.** Between deliveries. Establishes GDD §2.2's worked-example
voice as a shipped customer.

**The block's gangster.** His gang controls the block the truck is parked on, and
the truck needed their approval to be there safely. In his own neighbourhood he
is relaxed and off watch — but always on guard.

**The old local.** Lives around the block and has seen the city go through
everything.

## What the Gangster Establishes

**DECIDED by the human, 2026-08-07.** A gang controls the block the truck is
parked on, and the truck operates there by permission rather than by right.

This is the first faction in the setting with a concrete relationship to the
truck, and it is not an antagonistic one: the arrangement has already been made,
and the gangster stands at the counter as a customer. Whether the gang is named,
and whether other blocks work the same way, is not decided.

It also supersedes the earlier concern under "This Block". A nomadic truck and a
block that grants parking permission are not in tension — **permission is what
parking anywhere costs.** The truck moves; each place has someone whose approval
it needs. "This block" stays a floating reference to wherever the truck is
tonight, and the gangster is who it answers to *tonight*.

### The approval is not a mechanic

**DECIDED by the human, 2026-08-07.** The arrangement is **narrative colour and
nothing else.** No command, event, port, constraint, or score depends on it, and
none should in Phase 1 or in the capstone. It exists to explain why the truck is
parked where it is, and it is already settled before the game begins — the player
never negotiates it.

This is written down because the idea invites a mechanic and the decision was to
refuse one for now. Anyone reading "the truck operates by permission" and
reaching for a reputation meter, a protection cost, or a territory system is
going past what was decided.

### Approval as a later system (stretch, post-capstone)

**PROPOSED by the human as an area to explore, 2026-08-07 — not scheduled.** Who
grants a truck permission to trade is a question with more in it than one
gangster. Plausible grantors span the setting's whole power structure:

- a gang leader;
- a corporation;
- mercenaries;
- a community leader.

Two directions are open and both are interesting: permission as a **core mechanic
the player earns**, or as a purely **narrative frame** that colours a location
without being played. Which grantor a block answers to would say a great deal
about that block, either way.

**Deliberately unexplored.** GDD *Stretch Goals* holds the candidates for one
additional pressure system after the Phase 1 gate and the baseline Godot UI, and
constrains that list to **one** addition. If this belongs there, adding it is a
GDD amendment and the human's edit to make — it is recorded here so the idea is
not lost, not to smuggle it into scope.

## The Provisional Twelve-Ingredient Roster

**ESTABLISHED.** GDD §2.3 names the Phase 1 pantry: "noodles, tofu, mushrooms,
kimchi, pepper paste, chili crisp, coconut milk, pickled cucumber, chickpeas,
flatbread, citrus herbs, and smoked fish." The same section flags this roster
as "provisional and must be checked for tag accuracy and distinct gameplay
roles before external playtesting" (GDD §2.3).

**DECIDED by the human, 2026-08-07.** The four shipped ingredients were renamed
to plain culinary nouns matching the GDD's own modifier-plus-noun pattern, and
they count toward the twelve:

| Shipped `content_id` | Display name |
|---|---|
| `ingredient.thick_wheat_noodles` | Thick Wheat Noodles |
| `ingredient.soy_broth` | Soy Broth |
| `ingredient.citrus_chili_paste` | Citrus Chili Paste |
| `ingredient.rooftop_lettuce` | Rooftop Lettuce |

The remaining **eight are drawn from the GDD's provisional list**, which that
section itself invites: it calls the roster "provisional and must be checked for
tag accuracy and distinct gameplay roles."

The rename resolved a question this section previously flagged as open — whether
the shipped four were renames or additions. They are the former, and they are now
named accordingly. `Content Voice.md` rule 6 records the principle: **names are
plain; descriptions carry the world.** "Neon Noodles" put the setting in the name
and left the description with nothing to do.

One consequence worth stating for whoever commissions the eight: `soy_broth`
announces its own tag, so its description does not need to warn anyone away from
soy. A plain name can carry a constraint the prose then does not have to
telegraph.

## Escalation: Cultural Origins of the Provisional Ingredients

**Escalating, not answering.** The GDD's mandate for this document is that
"ingredients and recipes can communicate neighborhoods, migration, family
traditions, trade, scarcity, and relationships" (GDD §1, "Art Direction"). The
twelve named ingredients in GDD §2.3 draw on real, distinct culinary
traditions. Naming those traditions here is descriptive, not an assignment of
any of them to a specific in-fiction person, neighborhood, or migration
history:

- kimchi and pepper paste draw on Korean culinary tradition.
- tofu draws on East Asian culinary tradition broadly.
- coconut milk appears across Southeast Asian, South Asian, Caribbean, and
  West African traditions.
- chickpeas and flatbread appear across Mediterranean, Middle Eastern, and
  South Asian traditions.
- pickled cucumber appears across Eastern and Central European and East
  Asian traditions.
- smoked fish appears across Nordic, Eastern European, Pacific Northwest, and
  Caribbean traditions, among others.
- citrus herbs, mushrooms, and noodles are shared across many traditions with
  no single attribution.

This is exactly the territory the Worldkeeper is not authorized to settle:
"this game's ingredients cross real culinary traditions, and who eats what,
where it came from, and how it is described are exactly the calls the human
reserved" (Worldkeeper role definition). The GDD names the same risk
directly: "Ingredient values encode stereotypes... ground later worldbuilding
in specific people and histories" (GDD §5.5, Risks) and "Flavor values and
food constraints can become reductive or inaccurate... require human review
of descriptions, tags, allergens, and customer framing" (GDD §5.4,
Constraints). Three questions follow, listed in "Open Questions for the
Human" below rather than answered here.

## A Framework for Grounding Future Ingredients (Proposed Process, Not Content)

**PROPOSED — a writing aid, not a mechanic, tag, or rule.** For whoever drafts
the next ingredient descriptions: before writing the sensory description
itself, it may help to privately answer three questions the description
should never state outright, per Content Voice Rule 1 ("Describe the thing,
not its role"):

- Which established place does this plausibly move through — the North
  Tower, the Scrap Market, elsewhere in the city, or the truck's own planter?
- Who in this world might this matter to?
- Does it carry a note of trade, scarcity, or care?

The answers inform the writer. None of them belong in the printed description
— that is what Content Voice Rules 1 through 4 already forbid.

## The Cook (Player Character)

**Thin — flagging explicitly rather than filling in.** No name, appearance,
background, or pronoun for the player character is established anywhere. The
GDD refers only to "the player" throughout. This is one of the least-answered
points in the entire document. See "Open Questions for the Human."

## Open Questions for the Human

Three of the original eleven are resolved. The rest are deferred deliberately:
each binds only if new content *references* it, so none blocks the next content
run. **Content generation may not resolve one by inventing an answer** — a
proposal that needs the medic's workplace named is an escalation, not a licence.

### Resolved

- **Who the remaining five customers are** — decided 2026-08-07. See "The
  Remaining Five Customers".
- **Whether the four shipped ingredients replace or sit alongside the GDD's
  provisional twelve** — decided 2026-08-07. The four keep plain names matching
  the GDD's modifier-plus-noun pattern; the remaining eight are drawn from its
  list. See "The Provisional Twelve-Ingredient Roster".
- **Whether factions exist** — partly. A gang controls the block the truck parks
  on and the truck is there by permission. See "What the Gangster Establishes".
  Whether it is named, and whether mutual aid or corporate power are structured
  factions, is still open.

### Answered by default, reversible

- **Cultural attribution (originally 9 and 10).** The city is written as
  deliberately mixed and diasporic, with **no one-to-one mapping from
  neighbourhood to culinary tradition**, and no real tradition attributed to an
  invented in-fiction group. This is the narrowable direction: a specific,
  human-authored neighbourhood can be added later, whereas un-attributing a
  tradition once written is much harder. The GDD's own word is *migration*, which
  implies mixing. **Reversible on the human's say-so, and only theirs.**

  Confirmed by the human 2026-08-07, with one addition: **historic ethnic ghettos
  are reserved as a later idea to explore, not ruled out.** The default defers
  them rather than foreclosing them — which is exactly why it was chosen over
  writing specific neighbourhood-to-tradition mappings now.

### Still open

1. Should the city itself be named? ("The City")
2. Is "Neon Kitchen" the truck's in-fiction, hand-painted name, or only the
   game's title? ("The Truck's Name")
3. Is the North Tower corporate property, abandoned, or informally reclaimed —
   and is its upkeep official or improvised? Now that two technicians are
   contracted to fix its rooftop, *who is paying them* is the sharper form of
   this question. ("The North Tower")
4. Is the Scrap Market a formal, licensed market or a gray-market trade, and does
   the truck actually source from it? ("The Scrap Market")
5. What should the Late-Shift Medic's workplace be called, and how formal is it?
   ("The Late-Shift Medic's Workplace")
6. Is the block's gang named? Do other blocks work the same way? Are mutual aid
   and corporate power structured factions or unnamed background forces?
7. Who is the Cook — name, background, relationship to the truck — and how much
   should ever surface, given Phase 1 has no narrative system (GDD §1, Pillar 3)?
   Still the thinnest point in the document, and still not blocking: the Cook
   never speaks in Phase 1, and every customer addresses a generic "you".
