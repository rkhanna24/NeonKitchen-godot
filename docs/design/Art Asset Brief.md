---
type: design-guidance
display-name: Art Asset Brief
status: active
phase: phase-3
version: 1.0
updated: 2026-08-17
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

**Coverage is reported per `content_id`, never as a percentage.** "Ten of twelve,
missing `kimchi` and `citrus_chili_paste`" is a usable answer. "83%" is not — and
it stops meaning anything the moment the roster grows.

A pack that is **extensible** — a style with a broad catalogue, or one whose
look could be matched by a later purchase — is worth more than a marginally
better-fitting closed set, for the same reason.

## 6. Licence policy — read this before shortlisting

**This repository is public.** That constraint eliminates more packs than
quality does, and it is the first filter, not the last.

Many commercial asset licences permit shipping art inside a *built game* while
forbidding redistribution of the source files. Committing those PNGs to a public
GitHub repository violates that, even though shipping the same bytes inside an
exported binary would not.

| Acceptable | Notes |
|---|---|
| CC0 / public domain | No attribution required; still record the source |
| CC-BY | Fine. Attribution must land in-repo, not in a submission form |
| OFL (fonts) | Fine, with the licence file committed alongside |
| Commercial, redistribution permitted | Read the actual text, not the store's summary |

| Not acceptable | Why |
|---|---|
| "Cannot be redistributed in source form" | The repo is public |
| CC-BY-NC | This is coursework, but the licence is a legal constraint and the repo is open |
| CC-BY-SA | Viral terms against a repo that is not licensed to match |
| Unclear or absent licence | An unstated licence is a refusal |

Record for every candidate: **source URL, licence name, licence text location,
attribution requirement, and price.** A shortlist without those is not a
shortlist.

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
