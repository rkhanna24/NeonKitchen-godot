---
type: working-report
display-name: Asset Coverage Probe
status: draft
phase: phase-3
task: AS-02
source-decision: "DEC-039, DEC-052, DEC-053, #51 (parent #43)"
---

# Asset Coverage Probe

Task AS-02. Question asked: does either modality — flat 2D, or 3D rendered
in-house — contain a vocabulary of forms that can dress the twelve
`PREPARATION`-view ingredient blocks (brief §5), reported side by side so the
production-path decision can be made from evidence. Scope is the twelve
ingredient slots only; the customer and city strip are out of `REQUEST`-view
scope this round and were not searched.

## 0. Tooling limitation — read this before anything below

**No art was directly viewed in this round, for every candidate, and that is
the single fact that most limits what follows.** This was tested, not assumed:

- `Read` cannot fetch a remote URL. Given an image URL directly
  (`https://game-icons.net/.../noodles.svg`) it returns "File does not exist" —
  it only reads the local filesystem, and nothing sourced can be downloaded to
  it (Asset Scout has no shell).
- `WebFetch` converts a page to text/markdown and processes it with a
  non-visual model. Tested on two adjacent icon pages with the identical
  prompt: one (`delapouite/noodles.html`) correctly answered "the actual visual
  details... are not described in the text... you would need to view the SVG
  or PNG files directly"; the other (`lorc/mushroom.html`) returned a
  confident, specific-sounding visual description ("rounded cap and a thin
  stem") for the same style of question. That inconsistency means the second
  answer cannot be trusted as a real observation — it reads like pattern
  completion from the word "mushroom," not a report of pixels or vectors seen.

**Consequence: every `direct` and `adaptable` judgement in this report rests on
listing text — creator-written item descriptions, site tag names, or
third-party model-name manifests — never on art actually viewed.** Per the
packet's own acceptance criterion ("every `direct`/`adaptable` claim rests on
art actually viewed; anything else marked `listing text only, art not seen`"),
every cell in every table below carries that flag. It is stated once here
rather than in 130 individual cells, but it applies to all of them without
exception. Where a source gave an unusually strong form of listing text — a
name-by-name model manifest rather than marketing copy — that is noted, because
it is stronger evidence than a blurb even though it still is not a picture.

This is the load-bearing finding of the round, not a footnote: the headline
pair below is a read of *names*, not a confirmed coverage result. Treat it as
"where to look next," not as "what to pick."

## 1. Verdict, in three sentences

Both modalities can plausibly dress most of the pantry going by item names and
tags alone — the best 2D source found, game-icons.net (CC-BY 3.0), tags a
plausible anchor for 11 of 12 `content_id`s, and the best 3D source found,
Kenney's Food Kit (CC0), names one for 8 of 12, with 2D ahead mainly because a
single icon convention's jars, bottles, bundles, and sliced forms stretch
further across the block shapes than a 3D catalogue built around finished
dishes does. Neither number is visually confirmed — §0 applies to both in
full — so this is a ranking of *names found*, and it should be re-run by
someone who can open the preview pages before either pack is chosen. Packs
built from finished dishes rather than components (ramen bowls, sushi rolls)
covered close to none of the twelve regardless of price or licence, which
confirms the packet's component-vs-dish concern was the right thing to test.

## 2. What was searched

Searched and read directly (licence and/or item-listing pages fetched, not
just search snippets): game-icons.net (food tag page, two individual icon
pages, the CC BY 3.0 legal code directly), OpenGameArt.org ("CC0 Food Icons"
item page), CraftPix.net (the "Crops, Food and Drinks Pixel Art RPG Icon Pack"
product page, and `craftpix.net/file-licenses/` for the general licence text),
Kenney's Food Kit (kenney.nl, the itch.io mirror, OpenGameArt's mirror, and —
for an item manifest, since none of Kenney's own pages listed individual
models — the Poly Pizza bundle re-list of the same CC0 pack), Freepik /
Magnific (`magnific.com/legal/terms-of-use`, after `freepik.com/legal/terms-of-use`
redirected there), NewLua Studios' "Stylized Asian Food" itch.io page,
3dmodelscc0.itch.io's "Free CC0 Food & Drinks," ToffeeHazel's three itch.io
icon packs, Poly Pizza's own "jar" search, Quaternius's itch.io profile and
site.

Searched via web search only, and not promoted to the candidate table:
GameDev Market and Envato Elements — both returned the same primary-page fetch
failure AS-01 recorded (HTTP 403), so their status is unchanged and not
re-litigated here.

**Negative results, named so the next round doesn't re-search them:**

- Quaternius's "Ultimate LowPoly Food Pack" (CC0, real, cited by name in three
  independent secondary sources including Quaternius's own Patreon) could not
  be found at a stable, fetchable URL this pass — `quaternius.com/packs/food.html`
  404s, and it is absent from the current `quaternius.itch.io` storefront
  listing, which shows villages, sci-fi, nature, and animals but no food kit
  today. It may be Patreon-gated now. Worth a direct re-check by someone with
  Patreon access; not scored here because its licence page could not be read.
- ToffeeHazel's three icon packs (`japanese-cuisine-icons`, `foods-and-ingredients-32x32-icons`,
  `kitchentoolsandingredientsicons`) each gate their actual licence terms
  behind an external Google Doc linked from the product page rather than
  stating terms on the page itself; the doc was not reachable through search or
  fetch. Promising vocabulary (a *kitchen tools and ingredients* pack is
  exactly the vocabulary breadth this round wants), unusable licence status —
  see §7.
- Poly Pizza's own "jar" search returned eighteen individual models, and every
  one of them showed "License: Not specified" in the fetch — the site's
  per-item licensing (already flagged in AS-01 §2) means existence of jar
  models there is confirmed, clearance to use any specific one is not.

## 3. Candidates — licence, tier, both clauses quoted

Every candidate below survived the licence gate before any coverage work was
done, per rule 1. Candidates eliminated *at* the licence gate are in §7, not
here.

| # | Candidate | Modality | Licence | Tier | Price | Format | Native aspect ratio |
|---|---|---|---|---|---|---|---|
| 1 | [game-icons.net](https://game-icons.net) — food tag | 2D, flat SVG/PNG pictograms | CC BY 3.0 | n/a (uniform, free) | Free | SVG, PNG | Square (1:1), every icon |
| 2 | [OpenGameArt.org — "CC0 Food Icons"](https://opengameart.org/content/cc0-food-icons) | 2D, flat pixel icons | CC0 1.0 | n/a | Free | PNG | Square, 16×16 / 24×24 / 32×32 |
| 3 | [CraftPix.net — "Crops, Food and Drinks Pixel Art RPG Icon Pack"](https://craftpix.net/product/crops-food-and-drinks-pixel-art-rpg-icon-pack/) | 2D, flat pixel icons | CraftPix Premium licence (site-wide text) | Premium (membership-gated; standalone $ price not shown on the product page itself — see below) | Unconfirmed exact $ | PNG | Square, 16×16 / 32×32 / 64×64 |
| 4 | [Kenney — "Food Kit"](https://kenney.nl/assets/food-kit) | **3D**, OBJ/FBX/glTF | CC0 1.0 | n/a | Pay-what-you-want (incl. $0) | OBJ, FBX, glTF | n/a — ratio set at render time |
| 5 | [NewLua Studios — "Stylized Asian Food - Lowpoly Culinary Pack"](https://newlua-studios.itch.io/stylized-asian-food) | **3D**, Blender/GLB/FBX/Unity/Roblox | CC BY 4.0 | n/a | $5.00+ ($7+ for the Blender/GLB/FBX tier) | GLB, FBX, Blender, Unity package | n/a — ratio set at render time |
| 6 | [3dmodelscc0 — "Free CC0 Food & Drinks"](https://3dmodelscc0.itch.io/free-cc0-food-drinks) | **3D**, format inside a RAR | CC0 | n/a | Pay-what-you-want | Unstated inside the RAR | n/a |

Quoted clauses:

**game-icons.net — CC BY 3.0.** Embedding: the legal code
(https://creativecommons.org/licenses/by/3.0/legalcode) §3(a) grants the right
*"to Reproduce the Work, to incorporate the Work into one or more Collections,
and to Reproduce the Work as incorporated in the Collections"* and *"to
Distribute and Publicly Perform the Work including as incorporated in
Collections."* Modification: §3(b) grants the right *"to create and Reproduce
Adaptations provided that any such Adaptation... takes reasonable steps to
clearly label, demarcate or otherwise identify that changes were made to the
original Work."* Attribution: site convention *"Icons made by {author}.
Available on https://game-icons.net."* — text, lands in `CREDITS`. **No CC-BY-ND
anywhere in this pack** — checked deliberately per DEC-053.

**OpenGameArt.org "CC0 Food Icons" — CC0 1.0.** Embedding and modification are
the same waiver: https://creativecommons.org/publicdomain/zero/1.0/legalcode
§2 *"Affirmer hereby overtly, fully, permanently, irrevocably and
unconditionally waives, abandons, and surrenders all of Affirmer's Copyright
and Related Rights,"* covering *"the right to reproduce, adapt, distribute,
perform, display, communicate, and translate a Work"* for *"any purpose
whatsoever, including without limitation commercial, advertising or
promotional purposes."* No attribution required.

**CraftPix.net — Premium licence.** Fetched directly from
https://craftpix.net/file-licenses/. Embedding: *"You can sell and distribute
games with our assets."* Modification: *"You can use, copy, adapt, modify,
prepare derivative works based upon all purchased assets."* Source-file resale
(the old, superseded test, recorded for completeness, not as a filter):
*"You can NOT resell the source files (PNG, JPG, EPS, Adobe Illustrator,
etc.)."* Neither clause blocks our use under the current test. **Tier caveat:**
the product page shows this specific pack as "Exclusive for Premium users"
behind a membership paywall and never states a standalone $ price — the tier
name is confirmed, the price is not, and that gap is recorded rather than
guessed at.

**Kenney "Food Kit" — CC0 1.0.** Same CC0 legal-code waiver quoted above.
Kenney's own site statement: *"You're allowed to use these game assets in any
project including commercial ones."* Attribution: *"not required, but if you
choose to give credit... mentioning 'Kenney.'"*

**NewLua Studios "Stylized Asian Food" — CC BY 4.0.** Fetched from
https://creativecommons.org/licenses/by/4.0/legalcode §2(a)(1). Embedding:
*"reproduce and Share the Licensed Material, in whole or in part."*
Modification: *"produce, reproduce, and Share Adapted Material."* Attribution
required per CC-BY. No ND. **Licence is clean — this candidate is eliminated
on coverage, in §5/§7, not on licence.**

**3dmodelscc0 "Free CC0 Food & Drinks" — CC0 1.0.** Same waiver as above,
confirmed on the item page directly. **Eliminated on vocabulary breadth, not
licence — see §7.**

## 4. The two mismatches, tested explicitly

**Cuisine adaptability.** Per DEC-053, none of the surviving candidates need to
contain literal `kimchi` or `citrus_chili_paste` to be useful — a jar or bottle
recoloured is a correct answer. Both headline sources supply that jar/bottle
vocabulary (honey jars, ketchup/mustard bottles, a soy bottle, a "pickle" icon)
rather than anything culturally specific, which is the right shape of match per
§4 and does not trip §7's cuisine-as-aesthetic motif — these are containers,
not lanterns or neon kanji.

**Component vs. dish.** Tested directly against NewLua's "Stylized Asian Food"
pack, which is licensed cleanly (CC-BY 4.0, embedding and modification both
explicit) and was found specifically because "Asian food" sounded promising.
Its item list — Ramen, Pho, Kimchi Jjigae, Curry, Tom Yum, Sushi Nigiri, Sushi
Rolls, Onigiri, Gyoza, Baozi, Tonkatsu, Tempura Shrimp, Corndog, Dango,
Taiyaki, sake bottles, chopsticks, plates and bowls — is almost entirely
**finished, plated dishes**, exactly the packet's predicted failure mode. Its
"Kimchi Jjigae" is a filled stew bowl, not the jarred raw ingredient our
`kimchi` slot needs, and no adaptation turns a bowl of stew into a squat sealed
jar without discarding the model's whole reason for existing. Coverage result:
0 `direct`, at most 1 weak `adaptable` (a sake bottle, recoloured, standing in
for a bottled condiment) — the only content_id it plausibly touches at all.
**This is the clean, priced, cleanly-licensed counter-example the packet asked
for: licence and price solved nothing here, shape of the source did.**

## 5. Per-`content_id` matrix, per source (never a union)

Every `adaptable` names its adaptation. Every cell is `listing text only, art
not seen` per §0, stated here once rather than in each cell. Sources that
failed the licence gate (§7) are not scored — a candidate that fails licence is
not evaluated further, per rule 1.

**game-icons.net** (2D, CC-BY 3.0) — **11 of 12**, direct 4 / adaptable 7:

| `content_id` | State | Anchor found (by tag/name) | Adaptation needed |
|---|---|---|---|
| `thick_wheat_noodles` | `direct` | "Noodles" icon (tagged: pasta eaten with chopsticks) | Scale/crop square icon into the 180×56 wide/low block |
| `chickpeas` | `absent` | Only "Peanut" found; a single peanut icon does not read as a pile of legumes | — |
| `soy_broth` | `adaptable` | "Wine bottle" / "Brandy bottle" | Recolour dark; crop square icon into the 112×96 tall block |
| `coconut_milk` | `adaptable` | "Soda bottle" (reused bottle form, different icon) | Recolour pale; crop into tall block |
| `chili_crisp` | `adaptable` | "Honeypot" / "Honey jar" | Recolour red-brown; crop into the 124×64 squat block |
| `citrus_chili_paste` | `adaptable` | Same jar form as above, distinct icon instance | Recolour orange-red; crop into squat block |
| `kimchi` | `adaptable` | Same jar form again, distinct instance, to avoid reusing identical art on adjacent blocks | Recolour deep red; crop into squat block |
| `rooftop_lettuce` | `adaptable` | "Bok choy" / "Cabbage" | Crop square into the 152×48 wide/flat block; light recolour if needed |
| `mushrooms` | `direct` | "Sliced mushroom" | Crop into wide/flat block — a flat cross-section slice fits this ratio unusually well |
| `pickled_cucumber` | `direct` | "Pickle" | Crop into wide/flat block |
| `smoked_fish` | `adaptable` | "Canned fish" (nearest fish-adjacent icon; no plain fillet icon found) | Recolour amber/glossy; crop into wide/flat block; **weak fit — a can shape stands in for a fillet shape** |
| `citrus_herbs` | `direct` | "Herbs bundle" | Crop into wide/flat block |

Structural caveat applying to every row above: **every icon is a square
canvas**, and none of the four block ratios is square, so every row's
"adaptation" also includes a crop or letterbox regardless of what's listed —
stated once here per brief §4's own warning rather than repeated twelve times.

**Kenney "Food Kit"** (3D, CC0) — **8 of 12**, direct 1 / adaptable 7. Coverage
here rests on an item-name **manifest**, not Kenney's own page (which never
enumerates models) but a third-party re-listing of the same CC0 pack at
https://poly.pizza/bundle/Food-Kit-vOc58LJ0ge — a stronger form of listing
text than marketing copy, since it is a name-by-name inventory rather than
promotional prose, but still a name, not a picture:

| `content_id` | State | Anchor found (by model name) | Adaptation needed |
|---|---|---|---|
| `thick_wheat_noodles` | `absent` | No noodle-named model in the manifest | — |
| `chickpeas` | `absent` | No bean/legume-named model in the manifest | — |
| `soy_broth` | `adaptable` | "Bowl Broth" or "Soy" (bottle) | Render at the tall 112×96 ratio; recolour dark if using the bottle |
| `coconut_milk` | `adaptable` | "Carton" / "Carton Small" | Render at tall ratio; recolour pale |
| `chili_crisp` | `adaptable` | "Honey" or "Peanut Butter" jar | Render at squat 124×64 ratio; recolour |
| `citrus_chili_paste` | `adaptable` | "Bottle Ketchup" / "Bottle Musterd" | Render at squat ratio; recolour red-orange |
| `kimchi` | `adaptable` | "Honey" jar model reused, or "Cabbage" | Render at squat ratio; recolour deep red if using the jar |
| `rooftop_lettuce` | `adaptable` | "Cabbage" or "Salad" | Render at wide/flat 152×48 ratio |
| `mushrooms` | `direct` | "Mushroom" / "Mushroom Half" | Render at wide/flat ratio |
| `pickled_cucumber` | `absent` | No cucumber or pickle-named model in the manifest | — |
| `smoked_fish` | `adaptable` | "Fish" / "Fish Bones" | Render at wide/flat ratio; recolour amber-glossy, material swap to matte/smoked finish |
| `citrus_herbs` | `absent` | No herb-named model; "Leek" is the nearest green stalk but is not a herb-bundle form | — |

For every 3D row: the ratio is chosen free at render time (the packet's own
point), but the render step itself is a production cost the licence survey
cannot price, and it depends on modification rights — which CC0 grants without
qualification, so there is no licence blocker to that render step here.

**OpenGameArt.org "CC0 Food Icons"** (2D, CC0) — **6 of 12**, direct 0 /
adaptable 6. Scored because it fills a gap the two headline picks don't:

| `content_id` | State | Anchor found | Adaptation needed |
|---|---|---|---|
| `thick_wheat_noodles` | `absent` | No noodle item confirmed | — |
| `chickpeas` | `adaptable` | **"Pinto beans"** | Recolour/scale within the same legume vocabulary — the closest single-item match found anywhere this round |
| `soy_broth` | `adaptable` | "Soup" (bowl) | Recolour dark; crop/reshape a round bowl icon into the tall block — shape mismatch beyond simple crop |
| `coconut_milk` | `adaptable` | "Dairy"/"Drink" tag (unnamed specific item) | Recolour pale; crop into tall block |
| `chili_crisp` | `adaptable` | "Habanero"/"Jalapeño peppers" | Recolour/pile into squat block |
| `citrus_chili_paste` | `adaptable` | Peppers, reused | Recolour into squat block |
| `kimchi` | `absent` | No jar or cabbage item confirmed on this page | — |
| `rooftop_lettuce` | `adaptable` | "Vegetable" tag (unnamed specific item) | Weak — no specific leafy item confirmed |
| `mushrooms` | `absent` | Not confirmed present on this specific item page | — |
| `pickled_cucumber` | `absent` | Not confirmed | — |
| `smoked_fish` | `absent` | "Sushi" exists but is a finished dish, not a fillet — the same component-vs-dish problem as §4 | — |
| `citrus_herbs` | `absent` | "Tea" is the nearest tag; tea leaves are not soft herbs | — |

**CraftPix "Crops, Food and Drinks Pixel Art RPG Icon Pack"** (2D, Premium
tier) — **8 of 12 by category name only**, direct 1 / adaptable 7 — flagged as
the *weakest* evidence in this report: the product page's preview thumbnails
never loaded content for the fetch tool (lazy-loaded placeholders), so this
row is built from one sentence of category text (*"fish, pork, beef, chicken,
vegetables, fruits, soups, drinks, sandwiches, fried ribs, mushrooms and
more"*) rather than any item name list. `mushrooms` → `direct` (named
explicitly); `soy_broth`/`coconut_milk`/`chili_crisp`/`citrus_chili_paste`/`kimchi` →
`adaptable` via "soups" (bowl) or "drinks" (bottles/jars); `rooftop_lettuce` →
`adaptable` via generic "vegetables"; `smoked_fish` → `adaptable` via "fish";
`thick_wheat_noodles`, `chickpeas`, `pickled_cucumber`, `citrus_herbs` →
`absent`, nothing in the one sentence names them. **Do not weight this number
against the other three rows — it rests on a single blurb, not even a tag
list or a manifest.**

**NewLua "Stylized Asian Food"** (3D, CC-BY 4.0) — see §4. 0 direct / 1 weak
adaptable (sake bottle → a bottled-condiment stand-in). Recorded to show the
dish-shaped failure mode, not as a real candidate.

**3dmodelscc0 "Free CC0 Food & Drinks"** (3D, CC0) — 10 items total (baked
pizza, canned foods, canned tuna, coffee, frozen pizza, hamburger, hot dog, ice
cream, milk, sushi), overwhelmingly Western dishes. Only plausible hit:
`smoked_fish` ← "canned tuna," `adaptable`, weak (a can, not a fillet). Every
other `content_id`: `absent`. Eliminated on vocabulary breadth in §7, not
licence.

## 6. Headline pair

> **Best single 2D source covers 11 of 12, named: game-icons.net** (direct 4 —
> `thick_wheat_noodles`, `mushrooms`, `pickled_cucumber`, `citrus_herbs`;
> adaptable 7 — `soy_broth`, `coconut_milk`, `chili_crisp`,
> `citrus_chili_paste`, `kimchi`, `rooftop_lettuce`, `smoked_fish`; missing
> `chickpeas`). **Best single 3D source covers 8 of 12, named: Kenney's Food
> Kit** (direct 1 — `mushrooms`; adaptable 7 — `soy_broth`, `coconut_milk`,
> `chili_crisp`, `citrus_chili_paste`, `kimchi`, `rooftop_lettuce`,
> `smoked_fish`; missing `thick_wheat_noodles`, `chickpeas`,
> `pickled_cucumber`, `citrus_herbs`).

Both numbers are read from names and manifests only — §0 applies to both in
full — and neither has been visually confirmed. **This pair is what the human
asked for, and it is not yet a shortlist.**

## 7. Eliminated candidates

| Candidate | Stage eliminated | Reason |
|---|---|---|
| Freepik / Magnific "Condiments icon set" and Freepik generally | Licence (rule 1) | `magnific.com/legal/terms-of-use`, fetched directly this round (unlike AS-01, where the page 403'd): *"Does not use the Magnific Content in printed or electronic items (e.g. ... videogames ... ) aimed to be resold."* Videogames are named explicitly among the forbidden embedding contexts. This is brief §6's rare case — "forbids embedding in a distributed product" — not silence, an actual clause. Eliminated outright despite genuinely strong jar/bottle vocabulary (mayonnaise jar, mustard bottle, honey jar, soy sauce, "Asian sauce," sriracha squeeze bottle were all named in search results) — the licence filter runs first, and it stopped this one regardless of fit. |
| ToffeeHazel — "Pixel Japanese Cuisine," "Pixel Foods and Ingredients," "Pixel Kitchen Tools and Ingredients" (all 32×32, itch.io) | Licence (rule 1) | Terms are gated behind an external Google Doc linked from the product page; neither search nor fetch could reach it. Per brief §6, *"unclear or absent licence — an unstated licence is a refusal."* The doc may say anything; it was not read, so it is not promoted. Named specifically because "Kitchen Tools and Ingredients" is exactly the vocabulary breadth this round wants — worth a direct re-check by someone who can open the doc. |
| NewLua Studios "Stylized Asian Food" | Coverage (step 5) | Licence is clean (CC-BY 4.0, both clauses quoted in §3). Eliminated because the pack is dish-shaped, not ingredient-shaped — see §4. 0 direct / 1 weak adaptable. |
| 3dmodelscc0 "Free CC0 Food & Drinks" | Coverage (step 5) | Licence is clean (CC0). Only 10 items, all Western finished dishes or drinks; at most one weak adaptable hit. |
| Poly Pizza (as a general per-item source) | Licence, unresolved | 18 "jar"-search results returned, every one showing "License: Not specified" in the fetch. Existence of the vocabulary confirmed; clearance to use any specific model is not. Not scored. |
| Quaternius "Ultimate LowPoly Food Pack" | Unresolved, not licence-failed | Real pack, cited CC0 by secondary sources, but no longer at a stable URL found this pass (site 404, absent from the current itch.io storefront). Not read directly, so not promoted. |
| GameDev Market, Envato Elements | Unresolved (unchanged from AS-01) | Primary licence pages still return HTTP 403 to the fetch tool. Not re-promoted; not re-disqualified beyond AS-01's recorded position. |

## 8. Gaps, and what is absent from *everything* checked

No `content_id` is absent from every single source surveyed this round —
`chickpeas` is missing from both headline picks but shows up as `adaptable`
("pinto beans") at OpenGameArt; `thick_wheat_noodles`, `pickled_cucumber`, and
`citrus_herbs` are missing from the 3D headline pick but present at
game-icons.net. **That is not an actionable finding under the sourcing rule**
(brief §8): "prefer one pack over several" means gaps are read per chosen
source, not filled by mixing sources, so it is reported here only so the human
knows the gap is a property of *which single source gets picked*, not a hole
in the terrain as a whole.

Within the one-pack constraint, the honest gap list is:

- **If game-icons.net is the pick:** one gap, `chickpeas`. Fallback:
  shape-and-type presentation, unchanged, per brief §8 — "gaps are cheap."
- **If Kenney's Food Kit is the pick:** four gaps, `thick_wheat_noodles`,
  `chickpeas`, `pickled_cucumber`, `citrus_herbs`. Same fallback for each.

## 9. Open questions for the Kitchen Lead / human

1. **Nobody has looked at any of this art.** §0 is the load-bearing finding of
   the round: the Asset Scout's tools this round could search and read text but
   not view a single image. The headline pair is a ranking of names, and the
   very next step — before any purchase, before any production-path decision —
   has to be a human (or an agent with actual image access) opening
   game-icons.net's food tag page and Kenney's Food Kit preview directly. Until
   that happens, treat both numbers in §6 as a hypothesis, not a result.
2. **The 2D lead is a monochrome pictogram set, not an illustration style.**
   Every icon on game-icons.net is, by the site's own convention, a flat single
   colour glyph on a square canvas (confirmed in AS-01, not re-verified by
   sight this round). That is a specific visual register — closer to a symbol
   than to food art — and whether that register sits inside the Solarpunk,
   tempered palette (Visual Language rule 3: food must be the most saturated
   thing on screen) is a style call belonging to the human, not this report.
   A pictogram is trivially recolourable to sit *below* the palette's chroma
   ceiling, which cuts the other way from most illustrated packs — worth
   naming as a property of the format, not a recommendation.
3. **CraftPix's own product page could not confirm a standalone price or
   preview content** for the one CraftPix candidate scored — its row in §5 is
   the weakest evidence in this report and should not be treated as
   comparable to the other three.
4. **Ratification of the production-path decision is explicitly out of this
   report's authority** — per the packet, this document is the table the human
   chooses from, not the choice.
5. **The customer slot and city strip remain untouched**, exactly as gated by
   brief §9 and excluded by this round's scope — nothing here should be read as
   progress on either.

## 10. Escalation

Both modalities can, on paper, dress most of this pantry — neither modality
fails outright, so the twelve do not have to stay shape-and-type by default.
But the evidence for that claim is entirely textual, and the packet's own rule
("never describe art you have not seen") means this report cannot certify
either number as more than a lead. If the Kitchen Lead needs a decision this
round rather than a lead, the honest position is: **not enough was verifiable
with the tools available to this dispatch to make either the coverage numbers
or the production-path table actionable without one more pass that can
actually see the art** — a constraint worth raising rather than working
around, per the brief's own instruction to escalate rather than take the
reading that lets the task finish.
