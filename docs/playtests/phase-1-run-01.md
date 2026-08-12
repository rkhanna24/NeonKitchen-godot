---
type: playtest
display-name: Phase 1 Playtest — Run 01
status: in-progress
phase: phase-1
date: 2026-08-12
issue: 10
governed-by: "[[Neon Kitchen - Game Design Document]]"
protocol: ADR 0004 §12
tags:
  - neon-kitchen
  - playtest
---

# Phase 1 Playtest — Run 01

The ADR 0004 §12 protocol against the shipped twelve-ingredient, eight-customer
roster. This is the run that decides whether Phase 1 advances to the Godot UI.

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

## Ground rules

1. **Record points 1 and 4 before typing `submit`.** Afterwards you know the
   answer and cannot un-know it, and the two points that matter most are exactly
   the ones hindsight destroys.
2. **Do not open `content/base/` during the run.** You authored these numbers. You
   cannot unsee them, so the honest question is not "did you guess right" but
   *"would the screen alone have told you?"* Answer as if reading it fresh.
3. **Observation and interpretation go in different columns.** "I typed submit
   twice" is an observation. "The submit confirmation is unclear" is an
   interpretation. The ACs require them separated.
4. Write down confusion **when it happens**, not once you have resolved it. The
   resolution is what makes it invisible in a summary.

## What changed since the last session

Attend to these — they are new since the eight-customer playtest and both change
what you read on screen.

**Feedback selection (#29, DEC-028).** A dimension can no longer be reported as
both the strongest match and the largest miss. Ties between equally-penalised
dimensions now break toward the larger raw error for the miss. This changed which
dimensions are named on **149 of 2384** dish-customer pairs — no score moved.
Watch for: does the miss line now point at something you would call the actual
problem?

**Pantry grouping (#28, DEC-029).** `list` prints under four headings —
*Staples*, *Broths and fats*, *Heat and ferment*, *Fresh and cured* — instead of
alphabetically. Deliberately **no composition rule**: taking one from each group
is measurably *worse* for six of the eight customers, so nothing hints at it.
Watch for: does the grouping help you find things, and does it wrongly imply a
"one from each" recipe anyway?

Known rough edge, already logged: *Fresh and cured* holds 5 of the 12 and is a
grab-bag — mushrooms and smoked fish sit beside lettuce and herbs on no principle
except not being in the other three. If that reads badly on screen, say so here
and it becomes the concrete next decision.

## Per encounter

Points **2, 3, and 4 are the advance gate**. Point 5 is the Phase 1 design
question and no automated check can settle it.

Copy this block for each of the eight.

---

### Encounter N — `customer_id`

**Before serving**

- **1. Can you state what they want?** (yes / partly / no) —
- **4. Can you name a *different* plausible dish for them?** —
- Dish you served: —

**After serving**

- Result line as printed: —
- **2. Can you explain the result in ingredient and customer terms, without the
  numbers?** (yes / partly / no) —
- **3. If a constraint failed: which boundary, and why did it cap the score?**
  (n/a if none) —
- **5. Do you *want* to try another combination?** (unprompted curiosity —
  yes / no) —

**Observations** (what happened, no interpretation)

-

**Interpretation** (what you think it means)

-

---

## The eight

In presentation order. Constraints listed because §2.3 requires them visible
before choosing — this is not a spoiler, it is what the screen already tells you.

| # | Customer | Constraint |
|---|---|---|
| 1 | `block_boss` | skip anything `smoked` |
| 2 | `late_shift_medic` | — |
| 3 | `night_courier` | skip anything `fermented` |
| 4 | `office_worker` | — |
| 5 | `old_local` | skip anything `held` |
| 6 | `rig_partner` | — |
| 7 | `scrap_trader` | skip anything `soy` |
| 8 | `solar_tech` | — |

## Tally

Fill in after all eight.

| Point | Gate? | yes | partly | no |
|---|---|---|---|---|
| 1. States the want before serving | | | | |
| 2. Explains the result in ingredient terms | **gate** | | | |
| 3. Names the boundary crossed (4 constraint customers) | **gate** | | | |
| 4. Proposes a different plausible dish | **gate** | | | |
| 5. Wants to try another combination | design question | | | |

## Findings

Confusing actions and feedback:

-

Evidence of planning and experimentation:

-

Desire or reluctance to try another recipe:

-

## The decision

The GDD's advance gate: the evaluator is deterministic, golden cases pass,
customers have multiple viable recipes, **and internal testers can explain
constraint outcomes.** The first three are already evidenced in the repository.
This run decides the fourth.

Pick one and say why:

- [ ] **Advance to the Godot UI.** Points 2–4 hold across the roster.
- [ ] **Iterate on Phase 1 content or feedback**, then re-run this protocol.
      Name what changes.
- [ ] **Revise the core mechanic.** The puzzle does not communicate, and no
      amount of content fixes it.

Decision:

Reasoning:

Concrete next issue(s) to open:
