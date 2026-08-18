---
type: design-guidance
display-name: Kitchen Screen
status: active
phase: phase-3
version: 1.0
updated: 2026-08-17
governed-by: "[[Neon Kitchen - Game Design Document]]"
tags:
  - neon-kitchen
  - ui
  - screen
---

# Kitchen Screen

The game's screen. One encounter across two player-facing views inside the same
food truck, locked as the shipping interface in DEC-043.

This document exists because the reasoning behind it previously lived in a
72-line class comment in `adapters/godot_ui/kitchen_screen.gd`, which is the
wrong place for it: architecture that only survives while a file survives is not
a system of record. The class doc remains, and is still worth reading for the
line-level why; this is the account that outlives the file.

**Read this before [[Art Asset Brief]]**, and before pointing any agent at the
UI. The two documents under `references/` are research inputs, superseded on
layout — see [Where the design came from](#where-the-design-came-from).

## The one-sentence version

The player is inside a food truck: a customer comes to the window and says what
they want, that request condenses into a ticket, the truck's worktop takes the
frame while the player composes a dish from stations around a central surface,
and serving returns to the window for the reaction.

## 1. Two views, one place

`View` is a four-state presentation enum: `REQUEST`, `PREPARATION`, `RESULT`,
`ENDED`. Exactly one view is visible at a time.

| View | What owns the frame | Player can |
|---|---|---|
| `REQUEST` | The customer, a slice of city outside, their spoken request and constraints | Confirm, and move on |
| `PREPARATION` | The worktop: ticket, inspection, four stations, the pass | Select, remove, inspect, re-read the request, serve |
| `RESULT` | The customer again, with the served dish and their reaction | Advance to the next customer |
| `ENDED` | The service summary | Nothing |

They are **distinct player-facing screens, not regions of one layout.** That
distinction is the whole of DEC-038, and it was arrived at by building the
opposite first: a continuous workspace (DEC-037) that reproduced the column
split it was meant to escape, because two `EXPAND_FILL` children of an
`HBoxContainer` *is* a split whatever it is called.

Continuity comes from the encounter staying inside the same truck and from the
**ticket carrying the request across the cut** — not from both halves sharing
the frame.

### The views are presentation-only

The domain has no idea there are two of them.

`SessionState.Phase.BUILDING_DISH` covers both `REQUEST` and `PREPARATION`:
`PresentCustomer` leaves the session in `BUILDING_DISH` the moment a customer
is presented, before the player has read anything. The request-to-preparation
moment is therefore a **substate the screen alone tracks**, and confirming the
request calls no command at all.

`SHOWING_RESULT` and `ENDED` map one-to-one onto `RESULT` and `ENDED`.

This matters because it is the constraint on every future change to the flow:
**a new view is free; a new phase is an ADR 0004 §7a amendment.** If a
presentation idea seems to need a domain phase, the idea is usually wrong.

## 2. The worktop is a place, not a stack

The preparation view is a **centre with a perimeter** — the one structure shared
by all four preparation references in the frame notes: Good Pizza's bins
surrounding the dish, Galaxy Burger's bins around a central assembly surface,
Potion Craft's tools around one primary object with inventory at the edge,
Pekoe's shelves with category markers.

```
┌──────────┬─────────────────────┬────────────────────┐
│  TICKET  │      Staples        │  Broths and fats   │
│          ├─────────────────────┴──────────┬─────────┤
├──────────┤                                │ Heat &  │
│          │          THE PASS              │ ferment │
│ INSPECT  │      ▢     ▢     ▢             │         │
│          │      ─── Serve ───             │         │
├──────────┼────────────────────────────────┴─────────┤
│          │         Fresh and cured                  │
└──────────┴──────────────────────────────────────────┘
```

The version this replaced was three stacked bands — inspection text, a wrapping
pantry, a tray row with Serve on the end. The owner's read was exact: *"the
workspace screen doesn't represent an actual workspace, it's just an
abstraction."* A worktop has locations; that had rows, and painting art onto it
would only have painted the rows.

### Groups became places

DEC-029 shipped `IngredientDefinition.group` as **presentation-only** data —
`staple`, `broth_and_fat`, `heat_and_ferment`, `fresh_and_cured` — and the first
worktop ignored it, because an `HFlowContainer` renders a category heading as
just another block.

Each group is now a **station**: a panel in its own position with its own
heading. Their sizes are deliberately unequal — 2, 2, 3 and 5 ingredients —
because equal stations read as cells and unequal ones read as places.

The group remains presentation-only. Nothing scores it, no rule rewards taking
one from each, and the audit measured why: one-from-each-group is worth 1.9
points of mean score and costs up to 30 points of reachable best.

### Varied to look at, uniform to hit

Blocks take a silhouette per station — wide and low for a tray of staples, tall
for a carton, squat for a jar, flat for something on a board — and every one
stays above a 44px interaction floor with its name always visible.

That pairing is Pekoe's don't-borrow note followed rather than admired:
*"relying on silhouette alone, tiny unequal click targets"* is how a shelf of
varied objects stops being a readable pantry.

The floor is **not clamped in code**, on purpose. A clamp would make the test
that asserts it incapable of failing.

### The pass

The dish surface is the largest single region of the view, with Serve attached
beneath it. It is the record of every choice the player has made, and in the
version this replaced it was the least prominent thing on screen — three small
labels reading `(empty)`.

An unused place now renders **empty rather than saying so**. A place that
announces its own emptiness is a form field.

## 3. The ticket

The spoken request condenses into a ticket that persists through preparation.
This is load-bearing rather than decorative: `old_local`'s request is 319
characters against a 68-character ticket, and Good Pizza's named failure mode is
a large speech bubble being the only durable record of a nuanced request.

Two rules govern it, and they pull in opposite directions on purpose:

**It condenses what the customer said; it never translates what they meant**
(DEC-042, [[Content Voice]] rule 7). Working out that *"I want to feel human
again"* means comfort **is the puzzle**. A ticket reading `deeply comforting`
has solved it on the player's behalf.

**It is a reminder, not a replacement** (DEC-044). The brief originally made a
five-second recall of the preparation view the load-bearing exit test — could a
player state the whole order from the ticket alone. That premise was rejected:
speed was never the goal, moving between views is fine, and **some of what a
customer says will never condense at all** — a standing love of noodles is not a
flavour target and does not fit on a docket.

So *Read the full request* returns to the request view at any time during
preparation, and the tray survives the trip. A player who loses two chosen
ingredients by looking something up will stop looking things up.

## 4. What the screen may not do

The screen renders **only what `DomainEvent` and `CommandResult` carry.**

- It imports no `Evaluator`, `FlavourScorer`, or `ConstraintChecker`. Enforced
  by a source scan in `tests/unit/test_kitchen_screen.gd`, not by good intentions.
- It reads **no flavour value** for display — not `FlavorProfile`, not
  `IngredientSelected.dish_profile`, not `IngredientRemoved.dish_profile`. Ruled
  out on #35: per-ingredient intensity puts the flavour model on screen and
  turns composition into arithmetic.
- It sets **no inline theme property**. Every colour comes from the theme
  resource, so the palette stays swappable (DEC-034). Also source-scanned.
- It never writes `SessionState`. `CommandHandler` is the only thing permitted
  to, and the screen holds a read-only reference so its rendering cannot go
  stale against a second copy.

Everything it may do goes through `KitchenSession` — `start`, `present`,
`select`, `remove`, `submit`, plus `state()` and `content()` for reading. That
seam returns `CommandResult`, never anything drawable: *choosing what a panel
shows belongs to the screen; deciding what happened belongs to the domain.*

## 5. Layout mechanics

**Anchors for zones, containers inside them.** Each view's top-level children
are positioned by fractional anchors through `_zone` / `_zone_rect` — they are
large spatial regions, and a `VBoxContainer` wrapping a whole view would make
them a stack again. Containers do the arranging *within* a zone.

Every zone rectangle is a `Rect2` constant at the top of the file, so the
proportions can be judged and changed in one pass rather than hunted through
construction code.

**Both views paint a ground, and not the same one.** The preparation view is
`background` so the `surface` panels standing on it have something to stand
against; the customer view keeps a `surface` interior, because that framing
looks out through the service window and the warm inside has to read against the
darker street. Painting a ground the same token as its panels is exactly how the
first render ended up with no visible boundaries anywhere (DEC-045).

**Focus neighbours are explicit**, chained in pantry order and closing into a
loop through Serve and *Read the full request*. Godot's automatic guess is
geometric, and with four stations around a centre it hops in an order matching
nothing on screen.

## 6. What is still a placeholder

- **The customer** is a `307×288` grey rectangle labelled `CUSTOMER`. What
  belongs there is the open decision in [[Art Asset Brief]] §9, and the art
  search cannot proceed without it.
- **The city** is a flat `1280×115` strip of `background`. The brief's cheap
  city hypothesis — visible exterior, cold/warm contrast — is expressed by
  colour alone today.
- **Ingredients** are typographic blocks. Shape-and-type is also the permanent
  fallback for anything the art search cannot cover, so no ingredient can block
  the build for want of a picture.
- **Feedback** still leads with the number rather than the reaction, and prints
  `Largest miss: Spicy` in the evaluator's vocabulary rather than the
  customer's. #39 owns both.

## 7. Where the design came from

The layout was derived from the human's own reference research, not proposed
cold. Two documents under `references/` hold it:

- **[Frame notes and first greybox brief](references/frame-notes-and-greybox-brief.md)**
  — Borrow / Don't borrow / Test notes on Good Pizza, Galaxy Burger, Red Strings
  Club, Pekoe and Potion Craft. Still the best account of *why* the structure is
  what it is.
- **[Godot greybox implementation ideas](references/godot-greybox-ideas.md)** —
  the implementation hypothesis: scene tree, input actions, motion, cheap tests.

**Both are superseded on layout and status.** They describe a time-boxed
experiment beside an older screen; the experiment was adopted (DEC-043) and the
older screen deleted (DEC-046). Read them as research inputs and design
reasoning, never as the current state of the screen.

## 8. The decision trail

Read in order, in [[Kitchen Lead Worklog]]. The reversals are the useful part.

| | |
|---|---|
| DEC-029 | Ingredient groups, presentation-only |
| DEC-033 | The palette, and its four rules |
| DEC-034 | `assets/` licensed; themes plural by construction |
| DEC-037 | One continuous workspace — **superseded** |
| DEC-038 | Two phased views, because the continuous workspace rebuilt the split |
| DEC-042 | A ticket condenses what was said, never translates what was meant |
| DEC-043 | This screen is the game's screen |
| DEC-044 | The ticket is a reminder; the recall test is withdrawn |
| DEC-045 | Every surface carries a border; a ground is never its panels' token |
| DEC-046 | The old screen deleted, the greybox name dropped |

Related contracts: ADR 0002 §2 (dependency direction), ADR 0004 §7a (the phase
contract this screen must not amend), and GDD Art Direction §1 (information
priorities bind; layout does not).

## 9. Tests

- `tests/unit/test_kitchen_screen.gd` — 16 tests. The flow: the scene launches,
  each view shows what it must, the ticket survives the cut, rejections are
  shown rather than swallowed, a constraint violation is visible before and
  after serving, the longest shipped strings render, the night ends. Plus the
  two source scans in §4.
- `tests/unit/test_worktop_layout.gd` — 8 tests. The geometry: the interaction
  floor, one distinct silhouette per station, every ingredient inside its own
  station, the pass being the largest region, the focus chain closing, no two
  zones overlapping, none escaping the view, and the project launching this
  screen.

What no test can settle is whether it reads as a workspace. That took a person
looking at it, and it always will.
