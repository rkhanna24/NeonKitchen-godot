---
type: design-guidance
display-name: Content Voice
status: active
phase: phase-1
version: 1.0
updated: 2026-08-07
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

## Five rules

**1. Describe the thing, not its role.** The player infers what an ingredient is
for from what it *is*. A description that explains its function has done the
player's discovery for them, and discovery is the only progression Phase 1 has
(GDD §2.4).

**2. Never name a flavour dimension.** *Savory, spicy, fresh, comfort,
adventurous* are the evaluator's words. A description saying an ingredient is
"comforting" is reading the number aloud. Say what makes it so — warmth, weight,
starch, a heat lamp — and let the number stay the game's business.

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

## The test

A description passes when a player who reads it can guess what the ingredient
might be good for **without being told**, and would still be right after the
pantry doubles.

A name passes when it would look unremarkable on a real menu.

## Why this exists

From the first hands-on session of the terminal runner:

> "I didn't really think about how to get the highest score, but things that I
> wanted to eat as a person."

That is ADR 0004 §12 point 5 — curiosity, unprompted — which the ADR says no
automated check can settle. Play driven by appetite rather than arithmetic is the
outcome Phase 1 exists to produce, and prose that names the mechanics invites the
opposite. The voice is load-bearing, not decoration.
