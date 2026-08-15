---
type: design-guidance
display-name: Visual Language
status: active
phase: phase-3
version: 1.0
updated: 2026-08-14
governed-by: "[[Neon Kitchen - Game Design Document]]"
tags:
  - neon-kitchen
  - ui
  - visual
---

# Visual Language

The palette and the rules that govern how it is used. Ratified in DEC-033 from a
five-way comparison rendered in the real screen layout.

The human owns art direction. This document records a decision already made; it
does not authorise anyone to make new ones. It is the companion to
[[Content Voice]] — that governs the words, this governs everything else.

Anything under `adapters/godot_ui/` styles against these tokens. **No hex value
appears anywhere but the theme resource.**

## Two halves, and only one of them is settled

**The rules bind every theme.** They are the four below, and they apply to
palettes nobody has written yet.

**The active theme is provisional.** The values in the next table are one
resource in `assets/themes/`, chosen against typographic mocks and expected to be
re-tried once real art exists. Swapping it is a path change, not a rewrite:
themes are named for their palette rather than for the game, exactly one place
names the active one, and no screen edits when it changes (ADR 0002 §6, DEC-034).

A new theme may choose different values. It may not break a rule. A theme whose
disabled text lands at 1.38:1 is wrong however it looks, because the contrast
floor is a rule and the hex is not.

## The active theme

*Solarpunk, tempered* — `assets/themes/solarpunk_tempered.tres`. Dark green-grey
grounds, warm cream text, one warm signal held back.

| Token | Value | What it is |
|---|---|---|
| `background` | `#12140F` | the block outside the truck |
| `surface` | `#1E2219` | any panel the player reads from |
| `text_primary` | `#EDE8D9` | warm cream, the truck's own light |
| `text_muted` | `#8E9482` | secondary information |
| `accent` | `#C08A47` | sodium street light; the primary action |
| `signal` | `#9DB4A0` | muted sage; selection and rating band |
| `disabled_surface` | `#343A2C` | fills and borders of inactive controls |
| `disabled_text` | `#6B7360` | text on inactive controls |

### Names are roles, not colours

`accent`, not `sodium_orange`. A token named for its appearance has to be
renamed to be re-skinned, and Week 5 re-skins. This is the difference between
changing a palette in one file and sweeping the codebase.

## Four rules

### 1. Colour is never the only carrier of meaning

GDD Art Direction states this for Phase 1 and it carries forward without
amendment. Three things must survive desaturation: which ingredients are
**selected**, which are **unavailable**, and what the **rating band** says.

So each carries a non-colour marker as well as a colour: selection takes a mark
and a border, unavailability takes a mark and a weight change, the band takes
size and weight. Remove the hue and all three still read.

This was tested at specimen stage rather than assumed. The palettes stayed
legible in greyscale **because of the markers, not the colours** — strip the
markers and every candidate fails equally, including this one.

### 2. Surfaces are overlays, not fills

`surface` is authored with defined alpha over an arbitrary backdrop, and must
hold its contrast floor whether what sits behind it is a flat token or an
illustration.

An opaque panel looks correct today because the background is a flat colour. The
moment a painted background lands — GDD Art Direction names exposed cables,
solar panels, hand-painted signs, planters — a fill that read on `#12140F` need
not read on a lit sign, and every panel in the game needs rework at once.

Acceptance: the customer panel and the feedback panel stay legible with an
arbitrary mid-tone image placed behind the screen.

### 3. The food is the most saturated thing on screen

This palette deliberately holds chroma in reserve. Ingredient art will be warm
and vivid — chili crisp, smoked fish, kimchi, coconut milk — and an interface
that has already spent its warmth competes with the thing the player is meant to
be looking at.

That is the whole difference between this palette and the more saturated variant
it was chosen over: identical grounds and text, sodium pulled from `#E8A33D` to
`#C08A47`, signal green from `#7FD1A8` to `#9DB4A0`. Same world, warmth lent
rather than spent.

**No UI element may be more saturated than `accent`.** New colours are proposed
against this rule, not added beside it.

### 4. Disabled means unreadable-looking, not unreadable

An unavailable ingredient must still be identifiable. `block_boss` forbids
anything smoked, and the player needs to see that **Smoked Fish exists and is
excluded** — an ingredient that fades into the panel teaches nothing, and the
constraint mechanic depends on the player noticing what they cannot use.

This is why `disabled_surface` and `disabled_text` are separate tokens. Using the
surface tone for text measures **1.38:1**, which is not dim, it is invisible.

## Measured contrast

Computed, not estimated. Any change to these values re-runs this table.

| Pair | Ratio | |
|---|---|---|
| `text_primary` on `background` | 15.14:1 | AA |
| `text_primary` on `surface` | 13.21:1 | AA |
| `text_muted` on `surface` | 5.17:1 | AA |
| `signal` on `surface` | 7.30:1 | AA |
| `background` on `accent` — the Serve button | 6.15:1 | AA |
| `disabled_text` on `surface` | 3.27:1 | AA-large |

`disabled_text` sits at AA-large deliberately: legible enough to identify,
clearly inactive. It is used at label size or above, never for body copy.

## What was rejected

Four other candidates, all rendered in the real layout before choosing:

- **Cold city, warm truck** — near-black blue, amber, cyan. The only candidate
  where warm and cold did opposing work. Rejected in favour of the solarpunk
  half of the brief, which nothing else made visible.
- **Neon forward** — purple-black, magenta, cyan. Most immediately genre-legible;
  left the truck no way to read as refuge.
- **Solarpunk** (untempered) — this palette's grounds with fuller saturation.
  Rejected under rule 3: no headroom once food art arrives.
- **Worn steel** — desaturated blue-grey with a single warm signal. The
  restraint survives here; the world did not.

## The test

A screen passes when it reads correctly in greyscale, when every panel would
still be legible over an illustration, and when nothing in the interface is more
saturated than the food.
