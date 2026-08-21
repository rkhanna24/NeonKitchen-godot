---
type: working-report
display-name: Asset Icon Shortlist
status: draft
phase: phase-3
source-decision: "DEC-039, DEC-052, DEC-053, DEC-054, DEC-055, DEC-056"
---

# Asset Icon Shortlist

The distilled output of AS-01, AS-02 and AS-03 — **which glyph, for which
`content_id`, in which fill state**. Kitchen Lead's summary; the reasoning is in
`asset-coverage-probe.md` (Pass A) and `asset-coverage-verified.md` (Pass B).

This file exists so nobody has to re-run three search passes to recover twelve
filenames. Nothing here is purchased or committed — per DEC-052 sourced art is
git-ignored, so **this text is the durable record and the PNGs are not.**

## Scope, per DEC-054

Ingredient identity only. Containers, worktop, shelf and vessels are **built from
theme tokens, not sourced**. Do not search for kitchen furniture.

## The set

Source: **game-icons.net**, CC BY 3.0 — one uniform licence for every row.
Embedding and modification clauses are quoted in `asset-coverage-probe.md` §3.

| `content_id` | Slug | Fill state (DEC-056) | Notes |
|---|---|---|---|
| `thick_wheat_noodles` | `delapouite/noodles` | *none fits* | Faked as scatter. Neither scattered, poured nor spooned — may need a fourth state |
| `chickpeas` | — | scattered solid | **No candidate.** Peanut, jelly-beans and coffee-beans all rejected by sight |
| `soy_broth` | — | poured liquid | No glyph by design. Teapot and wine-bottle both rejected by the human |
| `coconut_milk` | `rihlsul/milk-carton` | poured liquid | **Contested — see open questions.** Bull motif must be removed |
| `chili_crisp` | `delapouite/honey-jar` | spooned paste | Wide-mouth drizzle-top jar |
| `citrus_chili_paste` | `lorc/honeypot` | spooned paste | **A mortar and pestle, not a jar.** AS-02 misdescribed it; sight corrected it |
| `kimchi` | — | spooned paste | **No candidate.** Survived every pass and every treatment |
| `rooftop_lettuce` | `caro-asercion/bok-choy` | scattered solid | Rotate off native diagonal |
| `mushrooms` | `delapouite/mushrooms` | scattered solid | The **cluster**, not `sliced-mushroom` — sight showed that one is two whole caps |
| `pickled_cucumber` | `delapouite/pickle` | scattered solid | Rotate |
| `smoked_fish` | `delapouite/canned-fish` | scattered solid | **Weakest surviving claim** — a can standing in for a fillet |
| `citrus_herbs` | `delapouite/herbs-bundle` | scattered solid | Rotate |

**Ten of twelve.** `chickpeas` and `kimchi` stay shape-and-type, which brief §8
permits and DEC-039 priced in.

## Regenerating the files

Sourced art is git-ignored, so fetch rather than look for it in the tree.

```sh
# transparent SVG, recolourable via fill
curl -o <name>.svg "https://game-icons.net/icons/000000/transparent/1x1/<slug>.svg"
# white-on-black PNG, 512×512
curl -o <name>.png "https://game-icons.net/icons/ffffff/000000/1x1/<slug>.png"
```

The transparent SVG is a single `<path>` with no background rect, so it tints
with `fill` and needs no masking.

## Attribution — required, CC BY 3.0

Must land in a committed `CREDITS` file before any of this ships. Text commits
normally; only the art is ignored.

> Icons made by **delapouite**, **lorc**, **caro-asercion** and **rihlsul**.
> Available on https://game-icons.net — CC BY 3.0.

Modification is permitted and expected (recolour, rotate, remove the milk
carton's bull motif). CC BY 3.0 §3(b) requires that changes be identified.

## Open questions

1. **Does `coconut_milk` need a glyph at all?** The human liked the milk carton,
   but DEC-056 gives liquids a surface and *no glyph*. Either the carton becomes
   a body stencil rather than pan contents, or it is dropped. **Unresolved — this
   is a genuine conflict between a stated preference and a ratified decision.**
2. **`kimchi` — search once more, or accept the gap?** Heat & ferment needs a
   third distinct squat form; only two exist. Filling the gap by recolouring one
   of the others would breach Visual Language rule 1.
3. **Does `thick_wheat_noodles` need a fourth fill state?**
4. **Is rotation acceptable in the pipeline?** Three rows need it.
