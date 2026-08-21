---
type: design-guidance
display-name: Art Asset Brief
status: active
phase: phase-3
version: 1.6
updated: 2026-08-21
governed-by: "[[Neon Kitchen - Game Design Document]]"
tags:
  - neon-kitchen
  - art
  - assets
---

# Art Asset Brief

The context packet for sourcing art, per DEC-039 (licensed asset packs) and #43.

GDD §4.2 is specific about why this document exists rather than a search box:

> The Asset Scout therefore never searches from a generic phrase such as
> "cyberpunk food truck." It receives the relevant world context, visual
> contrast, character facts, palette direction, required size, license policy,
> and forbidden motifs.

So that is what follows, in that order. Everything in the size tables is read
off the shipping screen rather than proposed, so a candidate can be judged
against the game that exists rather than against an intention.

**The Asset Scout is defined in GDD §4.1 and was activated on 2026-08-18.** Its
role definition is [[Asset Scout]], dispatched from `.claude/agents/asset-scout.md`,
and this brief is its context packet — it is handed this document in full rather
than a summary of it. A person can still read it directly; it was written as a
packet either way.

---

## 0. Standing method, and the current round

This document is the Asset Scout's context packet. Most of it is **standing
method** — true of any asset search for this game, and reusable unchanged for the
next batch of ingredients, and later for customers and scenery:

| Section | Standing |
|---|---|
| §1 World context, §2 visual contrast, §3 palette | The game does not change between rounds |
| §5 register | DEC-055. Decide it per round, before searching |
| §5 coverage states | The four-state rubric applies to any asset class |
| §6 licence policy | DEC-052. The embedding test is not ingredient-specific |
| §7 forbidden motifs | DEC-053 |
| §8 sourcing rule | DEC-039 |
| §10 what a finished shortlist looks like | The output contract |

**Round-specific** is §4's size tables, §5's list of twelve, §5's register
answer, and §9's open decisions. A future round swaps those and keeps everything
else.

**Scope, per DEC-054.** This brief covers **ingredient identity only**. The
containers, worktop, shelf and vessels are *built* from theme tokens, not
sourced — three passes established that stock supplies objects and cannot supply
a room. Do not search for kitchen furniture, containers, or set dressing.
[[Kitchen Screen Visual Production Plan]] is the whole-screen inventory; this
brief remains the narrower sourcing packet and should not absorb constructed or
custom-drawn work.

The per-round scope — which slots, which `content_id`s, which question the round
exists to answer — lives on the **GitHub issue**, per DEC-014. The Kitchen Lead
assembles a dispatch packet by combining this document with that issue; neither
is authored twice, so neither can drift.

**This is a seam, not a framework.** It is marked because the ingredient round is
about to prove which parts genuinely generalise. Splitting this into a method
document and per-round packets before that evidence exists would be abstracting
over exactly one real case. The customer and scenery rounds are expected to
reshape §4 and §9 substantially, and that reshaping is the input to any split.

---

## 1. World context

A nomad food truck in a cyberpunk city. The player cooks for people who come to
the window, one at a time, across one night's service.

The organising fact, from GDD Art Direction: **the city is dark, industrial, and
lit by corporate neon; the truck uses warm lighting, repaired technology,
reclaimed materials, exposed cables, solar panels, hand-painted signs, and small
planters.** Solarpunk at community scale, inside cyberpunk at city scale.

The player is *inside* the truck looking out. That is the framing the whole
screen is built on, and it decides what any purchased asset has to be a picture
of: the interior is the room you are in, and the city is what is visible past it.

### The screen is phased, and every slot belongs to one view

DEC-038 superseded the continuous workspace with **two views, one active at a
time inside the same truck**. `kitchen_screen.gd` carries them as two containers
and four `ScreenState` values — `REQUEST`, `PREPARATION`, `RESULT`, `ENDED`; the
first two are the ones that introduce distinct art slots.

| View | What the player sees | Slots sourced for it |
|---|---|---|
| `REQUEST` | The customer at the window, the street past them | The customer (§4), the city strip (§4) |
| `PREPARATION` | The worktop and its four stations | The twelve ingredient blocks (§4, §5) |
| `RESULT`, `ENDED` | Reaction and end of service | None. Text, per §4's *not needed* |

Continuity comes from **the ticket carrying the request across the cut**, not
from both regions sharing the frame — which is what makes the ticket load-bearing
rather than a convenience, and is the reason DEC-044 split the recall test per
view.

Two consequences for sourcing, and they are why a round can be scoped to one
slot at a time:

**The slots are never on screen together.** Ingredient art and the customer are
in different views, so they must cohere in *style* but never have to compose into
a single image. A pack that dresses the worktop well is not weakened by having
nothing for the window.

**So the views can be sourced independently, in any order.** This round covers
`PREPARATION` only. `REQUEST` waits on §9's unanswered casting question, and
nothing about that blocks the worktop.

## 2. The visual contrast to buy for

One hypothesis, and it is the thing to evaluate a pack against:

> **Hostile city on one side of the window, community care on the other.**

An asset that only delivers "cyberpunk" makes the whole screen the city, which
loses the contrast entirely. The truck interior is the more important half, and
it is the half a generic cyberpunk pack will not contain.

## 3. Palette direction

The active theme is *Solarpunk, tempered* (DEC-033), ratified in
[Visual Language](Visual%20Language.md). Sourced art has to sit inside it:

| Token | Value | Role |
|---|---|---|
| `background` | `#12140F` | The worktop; the street beyond the window |
| `surface` | `#1E2219` | Panels, stations, ingredient blocks |
| `text_primary` | `#EDE8D9` | Body text |
| `text_muted` | `#8E9482` | Block borders, group headings |
| `accent` | `#C08A47` | Sodium. The one available primary action, and hover/focus |
| `signal` | `#9DB4A0` | Sage |
| `disabled_surface` | `#343A2C` | Panel borders; inactive fills |
| `disabled_text` | `#6B7360` | Inactive text |

Two rules from that document bind anything purchased:

**Rule 3 — the food is the most saturated thing on screen.** This is the
strongest constraint on set dressing and the easiest to violate by accident:
most cyberpunk art is saturated everywhere. Backgrounds, the city strip, and the
truck interior must all sit *below* the ingredients in saturation. A pack whose
selling point is glowing signage will fight this on every frame.

**Rule 1 — colour is never the only carrier of meaning.** Nothing bought may be
the only thing distinguishing one state from another.

## 4. Required sizes

Read off `adapters/godot_ui/kitchen_screen.gd`. All figures at the recorded
minimum window of **1280×720** (`HYPOTHESIS_MIN_SIZE`); source at 2× for
headroom, since the window is resizable and nothing here is pixel-locked.

### Ingredient art — twelve slots, for the current roster

Twelve is what ships today, not a layout limit: #24 triples the pantry, and
stations wrap and scroll rather than capping what they hold
([[Kitchen Screen]] §2). Source for this order; expect to source again.

Blocks are sized per station. These are *minimums*: a station's container may
stretch a block, and each block already spends 12px horizontal and 8px vertical
on content margin plus a 2px border.

| Station | Block minimum | Usable interior | Count |
|---|---|---|---|
| `staple` | 180×56 | ~152×36 | 2 |
| `broth_and_fat` | 112×96 | ~84×76 | 2 |
| `heat_and_ferment` | 124×64 | ~96×44 | 3 |
| `fresh_and_cured` | 152×48 | ~124×28 | 5 |

**The name stays visible on every block.** That is not negotiable — it is
Pekoe's don't-borrow note and the reason the interaction floor exists. So art
here is not a replacement for the label; it shares the block with it, or sits
behind it. A pack of 128×128 square item icons does not fit these shapes without
being cropped or letterboxed, which is worth checking before falling in love
with one.

**A consequence worth stating plainly, because it widens the search enormously:
the label carries identity, so the art does not have to.** Nothing needs to be a
literal picture of citrus chili paste. A red jar is a correct answer. At ~124×28
with a name across it, the art is a visual anchor — form, vessel, colour,
texture — and the word beside it does the identifying. Search for a *vocabulary
of forms* (jars, bowls, bottles, bundles, piles, fillets, leaves) that can be
stretched across twelve, not for twelve specific foods.

This raises the value of **modification rights**: if a pack may be recoloured and
adjusted, its usable coverage is far larger than its literal coverage. See §6.

### The customer — one slot, reused eight times

`307×288` at 1280×720 (the `_build_placeholder_block` zone, currently a grey
rectangle reading `CUSTOMER`). Source at ~614×576.

### The city strip — one slot

`1280×115` at the minimum window, full width, top 16% of the request view.
Source at ~2560×230. It is a **strip**, not a scene: a horizontal slice of
street seen past the service window. Most cyberpunk backgrounds are 16:9 scenes
and will read as a random crop at 11:1.

### Not needed

- Worktop or station textures. The stations are lit surfaces on a dark ground
  and that reads; texture is a Week 5 nicety, not a sourcing requirement.
- Container art. Issue #52 proved the first vessel can be constructed from
  themed layers. A future hand-drawn pan texture is an optional authored
  replacement through the same seam, not an Asset Scout target.
- Icons for UI actions. Serve is a labelled button and should stay one.
- Audio. Deferred by GDD §5.1.

## 5. The twelve ingredients, with what they actually are

Search these descriptions, not the ids. The descriptions were written to say
what the thing *is* — its temperature, texture, and where it came from — which
is exactly what a search needs. Bracketed text is the station shape it has to
fit.

| `content_id` | What it is | Station |
|---|---|---|
| `thick_wheat_noodles` | Thick wheat noodles kept warm under a cheap heat lamp, going softer every hour | staple, wide/low |
| `chickpeas` | Dried chickpeas soaked overnight, simmered until they mash between two fingers | staple, wide/low |
| `soy_broth` | Stock simmered overnight until it coats a spoon, dark and salt-heavy | broth, tall |
| `coconut_milk` | Grated coconut soaked and squeezed through cloth, rich and pale, thick enough to slow a boil | broth, tall |
| `chili_crisp` | Dried chilies and shallots fried brittle in oil, spooned out still warm | heat, squat |
| `citrus_chili_paste` | Fermented chilies pounded with citrus peel, sharp at the back of the throat | heat, squat |
| `kimchi` | Napa cabbage packed in chili paste, soured in a sealed jar until the lid won't stay quiet | heat, squat |
| `rooftop_lettuce` | Lettuce from the truck's rooftop planter — crisp, cool, the closest thing to fresh air on this block | fresh, wide/flat |
| `mushrooms` | Wild mushrooms sliced thick, sweated slow until they give up their own dark liquid | fresh, wide/flat |
| `pickled_cucumber` | Cucumbers sliced thin in vinegar brine, translucent, snapping clean in half | fresh, wide/flat |
| `smoked_fish` | Fillets salt-cured then hung over smouldering wood until deep glossy amber | fresh, wide/flat |
| `citrus_herbs` | A fistful of soft herbs torn over citrus zest, bruised to let the oils out | fresh, wide/flat |

### Register — decide this before searching (DEC-055)

**What is the art a picture *of*?** Three answers, and they are three different
searches with almost no overlap:

| Register | Example | Where it is found |
|---|---|---|
| **The ingredient** | a pile of kimchi | Almost nothing licence-clean at these shapes |
| **The vessel** | the jar kimchi lives in | Most of what stock actually contains |
| **The symbol** | the kimchi glyph | Icon sets — correct as signage, wrong as an object on a worktop |

This was missing from v1.0–v1.4, and its absence cost three search passes. §5's
descriptions describe *the ingredient*, so a search told to "search the
descriptions" will match on subject and never notice it is returning symbols. A
coverage table can be correct in every cell while the whole set is in the wrong
language.

**Register is a per-round property.** It belongs in the packet, decided by the
human, before searching begins — like §9's casting question and for the same
reason.

Current answer for the twelve, per DEC-054 and DEC-056: the **containers are
built, not sourced**, and sourced art supplies **symbols** used as ingredient
identity *inside* those containers — repeated to read as a quantity, not placed
singly as a portrait.

**Coverage is reported per `content_id`, never as a percentage.** "Ten of twelve,
missing `kimchi` and `citrus_chili_paste`" is a usable answer. "83%" is not — the
next question is always *which two*, and a percentage has deleted exactly that.
It also stops meaning anything the moment the roster grows.

A pack that is **extensible** — a style with a broad catalogue, or one whose
look could be matched by a later purchase — is worth more than a marginally
better-fitting closed set, for the same reason.

Coverage is judged in four states, per `content_id` per source. §4 is why
`adaptable` rather than `direct` is the expected currency:

| State | Meaning |
|---|---|
| `direct` | The thing itself, recognisably |
| `adaptable` | A plausible anchor at block size. **Must name the adaptation** — recolour, crop, scale, material swap. An adaptation you cannot name is not one |
| `absent` | Nothing in the source's vocabulary of forms serves |
| `excluded` | Present, but performs cuisine as aesthetic (§7), or the licence forbids the modification the match needs (§6) |

Report `direct` and `adaptable` as a split, never as one total.

## 6. Licence policy — read this before shortlisting

**Sourced art is never committed.** It lives locally under `assets/sprites/`,
which is git-ignored, and reaches players inside the exported binary. The
repository carries the licence text, the attribution, and a register naming
every file — the provenance, not the pixels.

That decision changes the question you ask of a licence:

| | Old test (superseded) | **Current test** |
|---|---|---|
| Question | May I redistribute the **source files**? | **May I embed this in a distributed binary?** |
| Because | The repo is public and carried the art | The repo carries no art; the export does |

The old test closed nearly every commercial marketplace, since their standard
clause permits shipping art inside a built game while forbidding distribution of
the source files. **That clause is now satisfied rather than violated** — an
exported `.pck` is exactly the embedded case those licences are written for.

So the disqualifications in `asset-licence-survey.md` §3 were correct against the
old test and are **superseded**. That survey remains the record of which sources
carry which terms; it is no longer the record of which are usable.

### Acceptable

| Licence | Notes |
|---|---|
| CC0 / public domain | No attribution required; record the source anyway |
| CC-BY | Fine. Attribution lands in the committed `CREDITS` — text, not art, so it commits normally |
| OFL (fonts) | Fine, and fonts **are** committed, with the licence file alongside — OFL permits redistribution outright |
| Commercial, embedding permitted | Now the largest category. **Record the tier**, not just the price |

### Not acceptable

| Licence | Why |
|---|---|
| CC-BY-SA | Share-alike is arguably viral on a game that embeds it. Not worth the argument |
| CC-BY-ND | **No derivatives.** Permits embedding, forbids the recolouring and adaptation §4 depends on. Plausible on exactly the free art worth adapting, so check for it deliberately |
| CC-BY-NC | Fine for coursework, a landmine the day the game is sold. The repo goes private after the class; the licence lasts longer |
| Forbids embedding in a distributed product | The one clause that still eliminates outright. Rare |
| Unclear or absent licence | An unstated licence is a refusal. Unchanged, and still the most common failure |

**Paid is a price, not a licence.** Kenney charges pay-what-you-want for CC0; the
two are orthogonal. What paid marketplaces do have is **tiers** — Regular /
Extended / Enterprise, Standard / Extended — and the tier governs seat count and
commercial scope, not redistribution. A candidate recorded as "paid, $18" has not
been recorded; the tier name is the part that binds.

**Modification rights are a first-class field, not a footnote.** §4 establishes
that art is adapted rather than found literally, so a licence permitting
embedding but forbidding derivatives is much less useful than its coverage
suggests. Quote the modification clause separately from the embedding clause —
they are different permissions and a licence may grant one without the other.

Record for every candidate: **source URL, licence name, licence tier, licence
text location, the quoted clause bearing on embedding, the quoted clause bearing
on modification, attribution requirement, and price.** A shortlist without those
is not a shortlist.

## 7. Forbidden motifs

- **Real brands, logos, or trade dress.** The city is corporate; the
  corporations are invented.
- **Anything more saturated than the food.** Rule 3. Glowing signage as the
  dominant visual is a direct conflict.
- **Cuisine treated as an aesthetic.** GDD §5.5 carries "ingredient values
  encode stereotypes" as a live risk. The pantry is specific food from specific
  places; art that renders it as generic neon-Asian set dressing fails the same
  test the descriptions were written to pass.
- **Anything that states an ingredient's flavour role.** Art is subject to
  Content Voice rule 1 as much as prose: a picture that says "this is the
  comforting one" has done the player's discovery for them.
- **Weapons, combat, and vehicles.** Deferred scope, and they will be in every
  cyberpunk pack.
- **Cluttered detail at these sizes.** A `152×48` block does not hold an
  illustration.

**Substitution is not the same as cuisine-as-aesthetic, and only the second is
forbidden.** A neutral vessel standing in for a specific ingredient — a plain red
jar for `citrus_chili_paste` — is fine, expected, and what §4 asks for. A generic
vessel makes no cultural claim at all, which is if anything *safer* than art that
tries to depict the specific thing and gets it wrong.

What fails is art that **performs** a cuisine: lanterns, neon kanji as decor,
chopstick-and-takeout-carton shorthand, a pack whose whole selling point is
"Asian street food vibes." That is set dressing standing in for specificity, and
it is the failure the ingredient descriptions were written to avoid.

The test: does the art make a claim about a culture, or is it just a container?
Containers are fine.

## 8. The sourcing rule

From #43, and it is a selection constraint rather than a preference:

> **Prefer one pack covering most of the twelve over several packs each covering
> a few.** A consistent style with gaps reads better than a complete set in four
> styles.

A shortlist of five packs that jointly cover everything is a **worse** result
than one pack covering eight of twelve. The gaps are cheap: shape-and-type
presentation is already how every block renders today, so anything unfound
simply stays as it is. Nothing can block the build for want of a picture.

## 9. Open decisions — the human's, before searching

### What represents the customer?

`307×288` of frame, currently a grey rectangle. #38 closed on its structural
criteria, but this question was never answered, and **the search cannot judge a
pack without it.**

| Option | What it asks of the art |
|---|---|
| Portrait bust | Eight consistent character portraits. Hardest to source coherently; strongest for "someone at the window" |
| Silhouette against the city | Eight silhouettes, or one with variation. Cheap, on-theme, and Red Strings Club's own move |
| Full figure at the counter | Eight figures. Most expensive, most physical |
| Hands and what they carry | No faces. A courier's gloves, a medic's cuff. Unusual, cheap, and characterful |
| No figure at all | The window shows only the street; the person is voice and ticket. Costs nothing and gives up the most |

No recommendation offered. This is tone and casting, and the human owns both.

### Is the city strip a bought asset or a made one?

At `1280×115` it may be cheaper to compose from a handful of small elements —
signage, silhouetted structures, rain — than to find a strip that crops well.
Worth deciding before searching for a background, since they are different
searches.

[[Kitchen Screen Visual Production Plan]] now recommends a bespoke drawn strip:
the `11:1` frame is the wrong shape for a normal background, and the ingredient
round already showed that stock objects do not assemble into a coherent room.
That recommendation is **not yet a human decision**.

## 10. What a finished shortlist looks like

- Three to five candidates, each with source, licence, licence text location,
  attribution requirement, price, format, and resolution
- Coverage stated **per `content_id`**, with the gaps named
- One recommendation, with the reason it beat the others
- The failure modes of the recommendation stated plainly

Purchase, licence acceptance, and any subjective style call go to the human.
GDD §4.1: the Asset Scout "reports candidates to the Kitchen Lead; does not
contact the human directly, purchase assets, approve licenses, or prepare
files."
