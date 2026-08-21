---
type: working-report
display-name: Asset Coverage Verified
status: draft
phase: phase-3
task: AS-03
source-decision: "DEC-039, DEC-052, DEC-053, #51 (parent #43)"
---

# Asset Coverage Verified

Task AS-03, Pass B. AS-02 (Pass A, `asset-coverage-probe.md`) could not see any
art and marked every judgement `listing text only, art not seen`. This pass
`Read` every file in the staged preview directory and reports what actually
survived contact with the pixels. Where AS-02's guess held, that is stated as a
confirmation, not silence. Where it did not, that is flagged first.

Scope, unchanged from AS-02: the twelve `PREPARATION`-view ingredient blocks
only. The customer slot and city strip remain untouched — still gated on §9,
still out of round.

## 1. What changed — up front

In order of importance:

1. **`kimchi` has no candidate at all, and AS-02's "11 of 12" quietly counted it
   as one anyway.** No file in the staged set is offered for `kimchi`; AS-02's
   own text admits it never named an icon ("the same jar form again, distinct
   instance"). Looked at plainly: there is no fifth container icon on the table.
   The honest headline for game-icons.net drops from **11 of 12 to 10 of 12
   confirmed, with `kimchi` a second open gap alongside `chickpeas`** — unless a
   fresh, targeted search (not run this pass) turns up a fifth distinct
   container form.
2. **The "five jars" are not one picture recoloured five times — they are four
   genuinely different silhouettes, and that's better news than the dispatch
   worried about, but it comes with a catch.** Wine bottle (bottle-with-neck +
   a separate wine glass, two objects), brandy bottle (bulbous flask, cork,
   wax-seal medallion label), soda bottle (ribbed base, printed label band,
   carbonation bubbles), honey jar (wide-mouth jar, wavy drizzle-cap, a
   knot/loop glyph on the label) are four distinct shapes, not four recolours
   of one shape. `citrus_chili_paste`'s anchor, `honeypot`, is not a "jar" at
   all — it is a **mortar and pestle**, a structurally different object AS-02
   mis-described as "the same jar form as above, distinct icon instance." That
   is a real correction, not a nuance. See §3 for the full verdict, including
   the catch.
3. **`sliced-mushroom` does not show a cross-section.** AS-02 claimed "the flat
   cross-section fits wide/flat unusually well." By sight, `gi_delapouite_sliced-mushroom.png`
   shows two whole overlapping mushroom caps with stems — no cut face, no
   gills, nothing "sliced" about the silhouette. It is a tall composition, a
   poor fit for a 152×48 strip. The alternative AS-02 did not consider,
   `gi_delapouite_mushrooms.png` (three whole mushrooms of different heights,
   clustered low in the frame), is the better-fitting anchor of the two. This
   is a straight anchor swap, not a coverage loss — `mushrooms` stays
   `adaptable`.
4. **`gi_delapouite_fast-noodles.png` is confirmed by sight to be exactly the
   motif §7 forbids.** It is a to-go cup/carton with two chopsticks sticking
   out of the top — the "chopstick-and-takeout-carton shorthand" named
   explicitly as cuisine-as-aesthetic. AS-02 listed it as "not considered";
   sight moves it straight to `excluded`. It was never a live alternative for
   `thick_wheat_noodles` and shouldn't be treated as one.
5. **`chickpeas` stays absent, confirmed rather than assumed.** Neither
   `jelly-beans` (two glossy, capsule-shaped candies with a shine highlight —
   reads as confectionery, not dried legumes, and there are only two of them,
   not a pile) nor `coffee-beans` (three beans with the characteristic centre
   crease that specifically signals "coffee," not a generic legume) closes the
   gap. This is the one AS-02 claim that survives contact with the image
   unchanged.
6. **The wide/flat station (`rooftop_lettuce`, `mushrooms`, `pickled_cucumber`,
   `smoked_fish`, `citrus_herbs`) is the hardest-fitting shape in the set, and
   AS-02 could not see this because every judgement was text-only.** Every
   source icon is a square or diagonal composition; the block interior is
   ~124×28, a 4.4:1 ratio. Three of the five anchors (`bok-choy`, `pickle`,
   `herbs-bundle`) are drawn on the diagonal and need an actual **rotation**,
   not just a crop, to lie flat in the strip — a bigger transformation than the
   brief's own "every icon needs a crop" caveat implied. `canned-fish` is the
   pleasant surprise: its native content is already landscape-ish inside the
   square (the can's body band, not its rim ellipses), so it crops cleanly.
7. **Kenney Food Kit's number was built entirely on a third-party model-name
   manifest and cannot be confirmed at the resolution of the staged preview.**
   Of AS-02's 8 claimed `content_id`s, sight can confirm 2 cleanly
   (`mushrooms`, `smoked_fish`-weak), 3 are plausible but not resolvable at
   this preview's density (`soy_broth`, `chili_crisp`, `citrus_chili_paste`,
   all via a row of small bottle/jar shapes too small to identify
   individually), and the remaining 7 previously-claimed rows (including 3 of
   the "adaptable" ones — `coconut_milk`, `kimchi`, `rooftop_lettuce`) are
   simply not visible in this image at all. See §4.

## 2. Revised per-`content_id` matrix — game-icons.net (2D, CC BY 3.0)

All twelve source files are confirmed by sight: **512×512, square, white
silhouette on black.** Colour is genuinely absent from the source and would be
added downstream, which matters for the rule 1 finding in §3.

| `content_id` | State (revised) | Anchor (by sight) | Adaptation, named | What changed from AS-02 |
|---|---|---|---|---|
| `thick_wheat_noodles` | `adaptable` (down from `direct`) | `noodles.png` — bowl + rising steam + chopsticks, stacked vertically, filling the square top-to-bottom | Crop is severe: the wide/low block (interior ~152×36, ratio ~4.2:1) cannot hold both the bowl and the chopsticks/steam. Choosing the bowl alone leaves a shallow rim-arc; choosing the upper two-thirds discards the bowl entirely. Name the choice, don't default to "crop." | Downgraded — the crop is a content decision, not routine cropping |
| `chickpeas` | `absent`, confirmed | none | — | AS-02's claim survives: neither `jelly-beans` (2 glossy capsules, candy-coded) nor `coffee-beans` (3 beans, centre-crease reads specifically as coffee) closes it |
| `soy_broth` | `adaptable` | Prefer `brandy-bottle.png` over `wine-bottle.png` — the flask alone fills the frame; the wine-bottle icon is really a **bottle-plus-glass duo** occupying the full square, and cropping to just the bottle recentres an off-axis composition | Recolour dark; crop/recentre if using wine-bottle, straightforward crop if using brandy-bottle | New: brandy-bottle is the better single-object anchor, not previously distinguished |
| `coconut_milk` | `adaptable` | `soda-bottle.png` — straight body, ribbed round base, printed label band, carbonation bubbles drawn inside | Recolour pale/cream; crop into near-square tall block (minimal loss, block interior ~84×76 is close to the icon's own vertical proportions) | Confirmed: visibly distinct silhouette from both bottle candidates above — see §3 |
| `chili_crisp` | `adaptable`, weaker than assumed | `honey-jar.png` — wide-mouth jar, wavy drizzle-cap, a knot/loop glyph on the label band | Squat block (interior ~96×44, ratio ~2.18:1) is much flatter than the jar's own near-square shape. Cropping to fit will cut the drizzle-cap and/or the base, leaving mostly the label band — and the block's own text label has to sit in that same small area, which risks the clutter §7 warns against | New: the crop cost wasn't visible in Pass A |
| `citrus_chili_paste` | `adaptable`, weaker than assumed | `honeypot.png` — **a mortar and pestle**, not a jar: open bowl, pestle handle rising ~40% of the frame height | The squat block will crop off the pestle (the object's most legible feature), leaving a rounded pot/bowl shape that reads ambiguously — closer to a basket than a "paste" container | Correction: AS-02 called this "the same jar form as above, distinct icon instance." It is not a jar at all |
| `kimchi` | **no candidate found** | none staged | — | AS-02 counted this as `adaptable` without naming an icon. Sight confirms there is nothing to point to. This drops the headline number — see §1.1 |
| `rooftop_lettuce` | `adaptable` | `bok-choy.png` (diagonal stalk-to-leaf) or `cabbage.png` (round whole head) | Bok-choy needs a **rotation** (its axis runs corner-to-corner) before any crop; cabbage needs a heavy centre-crop through a round shape, which leaves a band of leaf-vein linework that may read as generic greenery rather than lettuce specifically | New: rotation requirement wasn't visible in Pass A |
| `mushrooms` | `adaptable` (down from `direct`, anchor swapped) | Use `mushrooms.png` (three whole mushrooms, clustered low, varied height), not `sliced-mushroom.png` | Bottom-anchored horizontal crop, discarding empty headroom above the caps | Correction: the "unusually good fit / cross-section" claim does not survive sight — see §1.3 |
| `pickled_cucumber` | `adaptable` (down from `direct`) | `pickle.png` — single elongated pickle, drawn diagonally, two seed/dot details | Needs rotation from diagonal to horizontal, then crop; also note the icon is a **whole pickle**, not the thin translucent brine-slices the content_id describes — an adaptation on content as well as geometry | Downgraded from unqualified `direct`: rotation + content substitution both needed |
| `smoked_fish` | `adaptable`, still flagged weak — confirmed, but shape risk resolved favourably | `canned-fish.png` — a can with a fish silhouette stamped on the front | Content mismatch persists (a sealed can is not a hung, smoked fillet — AS-02's own flag holds). Shape fit is **better than expected**: the can's printed content already sits in a landscape band inside the square, so cropping to the wide/flat block mainly trims the rim ellipses, not the fish glyph | Split finding: content weakness confirmed, shape weakness overturned |
| `citrus_herbs` | `adaptable` (down from `direct`) | `herbs-bundle.png` — tied bouquet, diagonal composition, sprigs fanning corner-to-corner | Needs rotation to lie flat in the wide/flat strip, same as bok-choy and pickle | Downgraded: rotation named, wasn't visible before |

**Excluded, confirmed by sight:** `gi_delapouite_fast-noodles.png` — a to-go
carton with chopsticks. This is §7's cuisine-as-aesthetic motif by name, not a
borderline case. It was never a real second option for `thick_wheat_noodles`.

**Revised split: direct 0 / adaptable 10 / absent 1 (`chickpeas`) / no
candidate found 1 (`kimchi`).** AS-02's "11 of 12, direct 4" does not survive
sight. Every `direct` call downgraded on inspection because every source icon
is square and every block is not — the brief's own warning, now confirmed
rather than assumed. The **coverage count** itself only moves by one
(`kimchi` drops out); what moves more is confidence in the four `direct`
claims, all of which turn out to need a named, sometimes nontrivial,
adaptation.

## 3. The five-jars verdict

**Not one picture recoloured five times.** By sight, four genuinely different
container silhouettes are staged: a necked wine bottle (paired with a
separate glass), a bulbous corked flask, a ribbed carbonated-soda bottle, and
a wide-mouth drizzle-top jar. `citrus_chili_paste`'s candidate is not even a
container in the same family — it's a mortar and pestle. **Shape, not just
colour, already differs across these four**, so a recolour on top of them is
a second differentiator layered on a first, not the only one. That is a
genuine, sight-confirmed answer to the question the dispatch called "the most
important thing to judge" — and it comes out better than AS-02's framing
feared.

**The catch: this resolves four of the five slots, not five.** `heat_and_ferment`
needs three squat icons (`chili_crisp`, `citrus_chili_paste`, `kimchi`); only
two distinct forms are staged (`honey-jar`, `honeypot`/mortar). `kimchi` has no
staged candidate at all. **If production fills that gap by reusing one of the
other four shapes with a different recolour — which is the path of least
resistance once a team has "the jar/bottle vocabulary" in hand — that
specific pairing would violate Visual Language rule 1** (colour as the only
carrier of meaning) for whichever two blocks end up sharing a silhouette. The
rule is not violated by the four sighted forms; it is at risk from the
un-sighted fifth. This is a concrete, actionable warning, not a hypothetical:
it only stays safe if whoever finishes sourcing treats "find a fifth distinct
form for kimchi" as a hard requirement, not a recolour exercise.

## 4. Kenney Food Kit — judged from its own preview, number revised down in confidence

The staged `kenney_foodkit_preview.png` is Kenney's own store flat-lay: roughly
150 small 3D-rendered objects arranged in rows against a mid-grey checkered
ground, CC0 badge visible bottom-left. This is a real improvement over AS-02's
evidence (a third-party Poly Pizza name manifest), but the image is dense
enough that most individual items render at roughly 25–40px on screen, which
limits what can honestly be confirmed.

**Confirmed present by sight:**
- A small cluster of brown mushroom caps → `mushrooms`, plausible `direct`.
- A grey whole-fish/fish-skeleton silhouette → `smoked_fish`, `adaptable`,
  weak (a whole fish or bones, not a smoked fillet — same content gap as the
  2D can).
- A row of distinct small bottles and jars (varied silhouettes, not
  identical) plus a bowl that reads as a filled stew/soup → plausible anchors
  for `soy_broth`, `chili_crisp`, `citrus_chili_paste`, but **the individual
  models cannot be told apart at this resolution** — this is "I see a row of
  jars," not "I see a soy bottle." Treat as plausible, not confirmed.
- Components clearly present and NOT tied to any of the twelve: pots, wooden
  barrels, stacked baskets, cutting board, plates (several empty), a pizza-in-box,
  an assembled burger, a hot dog, a sandwich in a takeout box, cupcakes,
  donuts, cookies, pies, cakes, bacon, a fried egg, a wheel of cheese, bread
  loaves, a pretzel, a croissant, raw vegetables (pumpkin, carrot, corn,
  eggplant, broccoli), and a full set of kitchen utensils.

**Not visible at this resolution — neither confirmed nor ruled out:**
`thick_wheat_noodles`, `chickpeas`, `coconut_milk`, `kimchi`,
`rooftop_lettuce`, `pickled_cucumber`, `citrus_herbs`. None of these has a
shape in this preview that I can point to with confidence. Some may exist
among the ~150 objects and simply be too small to read; that is a real
possibility this single flat-lay cannot settle either way.

**Revised number:** AS-02's "8 of 12" cannot be restated with the same
confidence. By sight this pass: **2 confirmed** (`mushrooms`,
`smoked_fish`-weak), **3 plausible but unresolved** (`soy_broth`,
`chili_crisp`, `citrus_chili_paste` — a bottle/jar row exists, individual
identity doesn't), **7 not visible in this image at all**, three of which
(`coconut_milk`, `kimchi`, `rooftop_lettuce`) AS-02 had scored `adaptable`
from the third-party manifest. This is a genuine drop in confidence, not
necessarily a drop in the pack's true coverage — the kit may well contain all
eight; this preview simply cannot prove it.

**Register.** The kit renders in a cheerful, rounded, saturated low-poly
cartoon style on a mid-grey ground — closer to a mobile cooking game than to
the brief's dark, industrial, warm-lit solarpunk worktop. That is a real
tonal gap worth naming plainly (the packet asked directly whether the
register suits a dark worktop): nothing here reads as gritty or reclaimed:
it reads as toy-bright. Whether that clashes fatally with Visual Language
rule 3 (food as the most saturated thing on screen) is not answerable from a
flat-lay on grey — it would need to be seen composited on the actual
`#12140F` ground, which this pass could not do.

**Components vs. plated dishes, settled by sight:** the kit is genuinely
**mixed**, not dish-shaped like NewLua's pack (AS-02 §4). Raw components
(vegetables, fish, bacon, egg, cheese, bread, mushrooms) sit alongside
finished dishes (burger, hot dog, pizza-in-box, cupcakes) in the same preview.
AS-02's name-only concern that a 3D pack would be all finished dishes does not
hold here — but that mixed inventory still can't be mapped to the twelve with
any precision from this image alone.

## 5. What sight could not settle

- **Kenney's true coverage of 7 of the 12 `content_id`s** — the flat-lay
  preview is too dense to resolve individual small models. Needs either
  Kenney's individual model thumbnails (if published) or the downloaded pack
  itself, neither available to this pass.
- **A fifth distinct container form for `kimchi`** on game-icons.net — this
  pass only sighted the files staged in the manifest; it did not run a fresh
  search. The gap may be closable, but nothing staged closes it.
- **In-engine legibility at actual render size.** `Read` shows a full
  512×512 PNG at full attention; it cannot simulate what a jar cropped to
  96×44px and sitting behind a text label actually reads as on screen. Every
  "the crop will likely lose X" judgement above is a reasoned prediction from
  the full image, not a render test. That test needs the real block, in the
  real theme, at the real size — a step past what sight-of-a-preview can do.
- **Whether Kenney's saturated cartoon register survives compositing against
  `#12140F`** (rule 3) — not answerable from a flat-lay on grey.
- **Every other AS-02 candidate** (OpenGameArt CC0 Food Icons, CraftPix,
  NewLua, 3dmodelscc0) — no images were staged for any of them this pass, so
  their AS-02 scores remain exactly what they were: listing text only, art
  not seen.

## 6. Open questions for the human

1. **`kimchi` has no sighted candidate on either modality.** Does the round
   accept a fresh, narrowly-scoped search for a fifth distinct container form
   on game-icons.net (or elsewhere), or does `kimchi` go shape-and-type — and
   if a fifth form is never found, is reusing one of the four sighted
   container shapes (recoloured) an acceptable rule 1 risk, or a hard no?
2. **Is a rotation (not just a crop) an acceptable production step?** Three of
   the five `fresh_and_cured` anchors (`bok-choy`, `pickle`, `herbs-bundle`)
   need to be rotated off their native diagonal before they fit the wide/flat
   block. That's a bigger edit than "crop," though still permitted under
   CC-BY 3.0's modification clause (quoted in AS-02 §3).
3. **Does Kenney Food Kit's register belong in the pipeline at all**, given
   the tonal gap named in §4, independent of whatever its true coverage
   number turns out to be? This is a style call the human owns.
4. **Is `thick_wheat_noodles`' crop viable**, or does forcing a bowl+chopsticks
   square icon into a 152×36-interior wide/low strip cost more than it's
   worth relative to staying shape-and-type?
5. **The customer slot and city strip remain untouched**, unchanged from
   AS-02 and still gated on brief §9's unanswered casting question. Nothing
   in this pass is progress on either.

No purchase, licence acceptance, or style call is made here. This report
revises what was seen; it does not choose between the two modalities, and it
does not recommend a pack.
