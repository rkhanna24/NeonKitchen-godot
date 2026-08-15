---
type: playtest
display-name: Phase 1 Playtest — Run 01
status: closed-partial
phase: phase-1
date: 2026-08-14
issue: 10
governed-by: "[[Neon Kitchen - Game Design Document]]"
protocol: ADR 0004 §12
tags:
  - neon-kitchen
  - playtest
---

# Phase 1 Playtest — Run 01

Two sessions against the shipped twelve-ingredient, eight-customer roster, on the
ADR 0004 §12 protocol. Two participants: the project owner and a second player
new to the game.

**Status: partial.** Point 5 — the Phase 1 design question — is answered. The
advance gate (points 2, 3, 4) was not recorded per encounter and is still open.
See *What is still missing* below.

**The protocol says automated tests may never be cited as evidence that the
puzzle is enjoyable.** 195 passing tests say the arithmetic is right. They say
nothing this document is for.

## Running it

```bash
cd /Users/rokhanna/godot/neon-kitchen
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s bootstrap/main.gd
```

Commands: `start`, `present`, `list`, `select <id>`, `remove <id>`, `submit`, `quit`.
A session is 8 customers in fixed order; `present` advances. Dish size caps at 3.

## Results

Every reported score was replayed through the real evaluator. **All 16 reproduce
exactly, 0 mismatches** — the summaries below are trustworthy and the evaluator
is deterministic across both sessions.

`sm` is the strongest match the game printed; `lm` the largest miss.

### Session 1

| # | Customer | Result | Dish | sm | lm |
|---|---|---|---|---|---|
| 1 | `block_boss` | Satisfied 66 | chickpeas, soy broth, citrus chili paste | spicy | savory |
| 2 | `late_shift_medic` | **Delighted 90** | rooftop lettuce, pickled cucumber, smoked fish | comfort | fresh |
| 3 | `night_courier` | Dissatisfied 39 | noodles, coconut milk, citrus chili paste | comfort | *(none)* |
| 4 | `office_worker` | Dissatisfied 35 | chickpeas, pickled cucumber, chili crisp | adventurous | fresh |
| 5 | `old_local` | Mixed 40 | coconut milk, citrus herbs, mushrooms | savory | adventurous |
| 6 | `rig_partner` | Mixed 60 | noodles, chili crisp, rooftop lettuce | fresh | spicy |
| 7 | `scrap_trader` | **Delighted 90** | chickpeas, chili crisp, smoked fish | comfort | spicy |
| 8 | `solar_tech` | Satisfied 81 | noodles, soy broth, mushrooms | comfort | savory |

Encounter 3 violated `FORBID_TAG(fermented)` — citrus chili paste is fermented.

### Session 2

| # | Customer | Result | Dish | sm | lm |
|---|---|---|---|---|---|
| 1 | `block_boss` | Satisfied 83 | chili crisp, noodles, mushrooms | savory | spicy |
| 2 | `late_shift_medic` | Satisfied 84 | soy broth, pickled cucumber, citrus herbs | comfort | fresh |
| 3 | `night_courier` | Mixed 43 | coconut milk, smoked fish | comfort | spicy |
| 4 | `office_worker` | Mixed 40 | kimchi, mushrooms, citrus chili paste | adventurous | fresh |
| 5 | `old_local` | **Delighted 100** | soy broth, rooftop lettuce, smoked fish | savory | *(none)* |
| 6 | `rig_partner` | Mixed 60 | pickled cucumber, chili crisp, rooftop lettuce | fresh | spicy |
| 7 | `scrap_trader` | Mixed 50 | coconut milk, chili crisp, noodles | spicy | comfort |
| 8 | `solar_tech` | Satisfied 72 | coconut milk, mushrooms, kimchi | savory | comfort |

No constraint violations.

### Distribution

| | Delighted | Satisfied | Mixed | Dissatisfied | mean |
|---|---|---|---|---|---|
| Session 1 | 2 | 2 | 2 | 2 | 62.6 |
| Session 2 | 1 | 3 | 4 | 0 | 66.5 |
| **Both** | **3** | **5** | **6** | **2** | **64.6** |

Both sessions centre just under the `SATISFIED` edge of 65, with the full range
of bands used and neither clustering at a ceiling or a floor. Sixteen encounters
produced sixteen different dishes; no dish was repeated across players.

## Findings

### 1. `office_worker` is an outlier and both players failed it

35 and 40 — the two lowest non-violation scores in the run, from different
players with completely different dishes. Both were told `largest miss: fresh`.
Neither converged.

It is not bad luck. Reachability across all 220 three-ingredient dishes:

| customer | best | dishes scoring 100 | dishes ≥ 85 |
|---|---|---|---|
| `block_boss` | 92 | **0** | 2 |
| `night_courier` | 91 | **0** | 3 |
| `office_worker` | 100 | 2 | **4** |
| `rig_partner` | 100 | 1 | 11 |
| `late_shift_medic` | 100 | 2 | 14 |
| `old_local` | 100 | 16 | 30 |
| `solar_tech` | 100 | 11 | 37 |
| `scrap_trader` | 100 | 8 | 39 |

`office_worker` has 4 delighting dishes; `scrap_trader` has 39. That is a **10×
spread in difficulty presented to the player as identical** — nothing on screen
says one customer is harder than another. `office_worker` wants Fresh 5 and
Adventurous 4, and Fresh 5 can only be reached by stacking (rooftop lettuce 3 +
pickled cucumber 2), which is exactly the concentration the pantry grouping
deliberately does not hint at (DEC-029).

### 2. Two customers cannot be perfected at all

`block_boss` tops out at 92 and `night_courier` at 91 — **zero** dishes reach 100
for either. Nothing communicates this. A player optimising toward a perfect score
on `block_boss` is chasing something that does not exist.

Whether that is a bug or a feature is a design decision, not a code one. It is
defensible that some customers are simply hard to please. It is not defensible by
accident.

### 3. The most interesting feedback moment in the run

Session 1, `night_courier`: **flavour-perfect and capped anyway.** Every weighted
penalty was zero — which is why the game printed *no largest miss at all* — and
the score was still 39, `DISSATISFIED`, because citrus chili paste is fermented
and this customer forbids fermented.

That is the single clearest teaching case the content can produce: the dish was
right and the boundary was wrong, and the feedback said so by reporting a
strongest match, no miss, and a violated constraint. It is also the one encounter
in sixteen that exercises protocol point 3.

### 4. `rig_partner` scored exactly 60 twice, from different dishes

Both players landed `fresh` as strongest match and `spicy` as largest miss, from
dishes sharing only chili crisp and rooftop lettuce. `rig_partner` wants Fresh 4
and Spicy 4; both got the fresh half and missed the spicy half identically. Worth
watching rather than acting on — two samples.

### 5. Constraints are being respected

One violation in sixteen encounters, and it was a genuine trap (fermented, on an
ingredient whose name does not announce it). Constraint text appears to be doing
its job. It also means point 3 has only one data point.

## The design question — point 5

**Answered, unprompted, and positive.** The second player enjoyed it and asked
for more ingredients and customers without being asked whether she wanted to
continue.

That is precisely the signal §12 point 5 specifies and explicitly says no
automated check can settle. It is the strongest evidence in this document, and
the only kind Phase 1 was built to produce.

## What is still missing

The advance gate is points **2, 3, and 4**, recorded per encounter:

- **2.** Can the player explain the result in ingredient and customer terms,
  without being shown the numbers?
- **3.** For the constraint failure, can they say which boundary they crossed and
  why it capped the score?
- **4.** Can they propose a different plausible dish for the same customer?

These were not captured during the sessions. The score summaries show *what*
happened; the gate asks whether the player *understood* it. A run that produced
sixteen sensible dishes is consistent with full understanding and also consistent
with productive guessing, and the distribution alone cannot separate them.

Answering three questions closes it, and points 2 and 3 can still be answered
from memory of the specific encounters named above.

## The decision

- [x] **Advance to the Godot UI**
- [ ] Iterate on Phase 1 content or feedback, then re-run
- [ ] Revise the core mechanic

Decision: **advance**, taken by the human on 2026-08-14 (DEC-030), with points 2–4
still unrecorded. Point 5 is answered positively and the terminal has produced
sixteen sensible dishes across two players, which is enough to justify attaching
a UI to the same core. The reasoning: the gate asks whether a player can explain
a result from what the screen tells them, and the terminal is the weakest
possible screen. A UI that shows the request, the pantry, and the dish together
may settle the question rather than answer it — so re-testing the gate belongs
with the UI, against the interface that ships, not against the one being retired.

**This is a deferral, not a pass.** The gate moves to the Phase 2 playtest, where
GDD §3 already requires a higher bar: at least four of five testers explaining a
result in ingredient terms, and at least four proposing two plausible dishes for
one customer. Run 01 stands as the terminal baseline those are measured against.

Regardless of that outcome, two content findings are actionable now and do not
depend on the gate:

1. The difficulty spread (finding 1) — decide whether `office_worker`'s 4
   delighting dishes against `scrap_trader`'s 39 is intended.
2. The unreachable ceilings (finding 2) — decide whether `block_boss` and
   `night_courier` topping out at 92 and 91 is intended.
