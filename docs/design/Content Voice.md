---
type: design-guidance
display-name: Content Voice
status: active
phase: phase-1
version: 1.1
updated: 2026-08-17
governed-by: "[[Neon Kitchen - Game Design Document]]"
tags:
  - neon-kitchen
  - content
  - voice
---

# Content Voice

How ingredient descriptions, customer requests, and reaction lines are written.
Ratified in DEC-026, from the human's reading of the first four shipped
ingredients during the first hands-on session.

The human owns tone and canon. This document records decisions already made; it
does not authorise anyone to make new ones.

## What worked

> Thick wheat noodles kept warm under a cheap heat lamp

> crisp, cool, and the closest thing to fresh air on this block

Both describe **the thing** — its temperature, its texture, where it came from.
Neither says what the ingredient is *for*. The setting arrives through a cheap
heat lamp and a block worth escaping, not through a sentence about the setting.

## What did not

| Line | Why |
|---|---|
| "the most reliably comforting thing in the pantry" | States its mechanical role, and makes a claim about the *rest of the pantry* |
| "for anyone chasing something adventurous" | Names a flavour dimension outright |
| "but not for anyone avoiding soy" | Restates the constraint the constraint already states |
| "I want to feel human again" | Reaches for the emotional register before earning it |

Rule 5 below is the general form of that last row. The line itself survived into
`solar_tech`'s shipped request and, since 2026-08-17, onto their ticket — see
rule 7. The judgement here was that it cannot be the register *every* customer
arrives in, not that no customer may ever say it.

## Seven rules

**1. Describe the thing, not its role.** The player infers what an ingredient is
for from what it *is*. A description that explains its function has done the
player's discovery for them, and discovery is the only progression Phase 1 has
(GDD §2.4).

**2. Never name a flavour dimension — in an ingredient description.**
*Savory, spicy, fresh, comfort, adventurous* are the evaluator's words. A
description saying an ingredient is "comforting" is reading the number aloud. Say
what makes it so — warmth, weight, starch, a heat lamp — and let the number stay
the game's business.

**A customer request is the exception, and it is not a loophole.** GDD §1:
*"Customers do not order exact menu items. They describe what they want through
qualities such as comforting, spicy, fresh, savory, or adventurous."* That is the
game's signal channel. A customer who says "something with real weight to it"
instead of "savory" has not been subtle, they have been unclear — and ADR 0004
§12's advance gate asks whether a tester can state, **before serving**, what the
customer wants.

The three shipped customers do this correctly: *"Something hearty and savory"*,
*"comforting with just a little kick"*, *"Something fresh and light"*. Match them.

Reaction lines sit with descriptions, not requests. A reaction reports how it
went and can do that in the customer's own terms without naming a dimension.

**3. Never make a claim relative to the rest of the pantry.** "The most
comforting thing here" is true of four ingredients and false of twelve. This is
not only taste: **#24 triples the pantry**, and any comparative claim written
today becomes a lie then, silently, with no check able to catch it.

**4. Do not restate a constraint in a description.** `FORBID_TAG(soy)` already
carries an `explanation_key` in the customer's own voice. An ingredient that also
announces it is unsuitable for soy-avoiders removes the inference the constraint
mechanic exists to create. Tag it `soy` and describe the stock.

**5. Ration the emotional register.** Exhaustion, loneliness, and quiet despair
land once. If every customer arrives depleted, none of them read as depleted —
they read as a tone setting. Reserve the heavy notes for the encounters meant to
carry them, and let most customers simply be hungry, specific, and in a hurry.

**6. Names are plain; descriptions carry the world.** An ingredient is called
what it is — *thick wheat noodles*, *soy broth*, *rooftop lettuce*. A modifier is
fine when it says something true about the thing (rooftop, pickled, smoked,
citrus); a modifier that supplies atmosphere is not. "Neon Noodles" and "Ember
Chili Paste" put the setting in the name, which front-loads theme before the
player has read anything and leaves the description with nothing to do.

This is rule 1 one level up, and it has a second benefit: **a plain name can make
a constraint legible without any prose telegraphing it.** `soy_broth` announces
its own tag, so its description no longer has to say "not for anyone avoiding
soy" — the inference the constraint mechanic exists to create survives intact.

The GDD's own provisional twelve are all plain: noodles, tofu, mushrooms, kimchi,
pepper paste, chili crisp, coconut milk, pickled cucumber, chickpeas, flatbread,
citrus herbs, smoked fish. Modifier plus noun, no atmosphere.

**7. A ticket condenses what the customer *said*. It never translates what they
*meant*.** The ticket carries the request into the preparation view, so it is
allowed to be terse and it inherits rule 2's exemption — naming a quality is the
game's signal channel and `Savory with real heat` is correct ticket text.

What it may not do is finish the player's thinking. Working out that *"I want to
feel human again"* means comfort is **the puzzle**, and a ticket reading
`deeply comforting` has solved it on the player's behalf and simplified the game.
The line stays *"Wants to feel human again"*, and translating it remains the
player's job.

The practical test is mechanical: **every quality word on a ticket should already
appear in that customer's own request.** Seven of the eight shipped tickets pass
that on the first draft; the eighth was `solar_tech`, whose request signals
comfort only through the feeling, and it was the only one that needed correcting.

A corollary: a ticket cannot warn about something the request never mentions.
`late_shift_medic` carries a real dislike of spice that they never speak aloud, and
no honest ticket can surface it — writing it in would rewrite the request through
the back door. That gap is content work, or a repeat-customer mechanic where the
quirk is something the player *discovers*, not a ticket defect.

Evaluator vocabulary is still banned outright. `Savory 5, weight 2` is the answer
key, and `tests/content/test_customer_ticket.gd` fails on any digit or on the
words *dimension*, *weight*, *target*, *score*, and *penalty*.

## The test

A description passes when a player who reads it can guess what the ingredient
might be good for **without being told**, and would still be right after the
pantry doubles.

A name passes when it would look unremarkable on a real menu.

A ticket passes when a player who reads only it — never the full request — can
state what the customer wants and what they must avoid, **and still has to do the
translating themselves.**

## Why this exists

From the first hands-on session of the terminal runner:

> "I didn't really think about how to get the highest score, but things that I
> wanted to eat as a person."

That is ADR 0004 §12 point 5 — curiosity, unprompted — which the ADR says no
automated check can settle. Play driven by appetite rather than arithmetic is the
outcome Phase 1 exists to produce, and prose that names the mechanics invites the
opposite. The voice is load-bearing, not decoration.
