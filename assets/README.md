# assets/

Authored presentation resources — themes, fonts, sprites. Licensed by ADR 0002
§6 (DEC-034).

## Not `content/`, not `adapters/`

`content/` is the game's **data**: ingredients, customers, the localisation
source. It is validated at load by `ContentValidator`, governed by ADR 0004, and
a failure there is a failure to start. Nothing in `assets/` is validated that
way — a missing sprite is a presentation defect, not invalid content.

`adapters/` is **code**. This is not.

The practical test: if changing it can change a score, a constraint, or what a
customer says, it belongs in `content/`. If it can only change how something
looks, it belongs here.

## Shape

```text
assets/
├── themes/                      one Theme resource per palette
│   └── <palette_name>.tres
├── fonts/                       deferred
└── sprites/                     deferred
    ├── ingredients/
    ├── customers/
    └── backgrounds/
```

`sprites/` is git-ignored in full and will never appear in the repository at all
— sourced art lives there locally and ships inside the export. What is committed
in its place is the licence text, the attribution, and the register naming every
file. `fonts/` is committed normally: OFL permits redistribution outright.

Other deferred folders are created when their first real file exists — the same rule
ADR 0002 §6 applies everywhere else, and `scripts/check.sh` fails on an empty
directory, so creating them early is not merely untidy but red.

## Themes are plural on purpose

`assets/themes/` holds **one resource per palette**, named for the palette and
never for the game. `solarpunk_tempered.tres`, not `kitchen_theme.tres`.

The palette in `docs/design/Visual Language.md` is provisional and expected to be
re-tried against real art. A theme named for the game is the one you edit in
place; a theme named for its palette is one of several you switch between. Only
the second makes "try a different theme" a path change rather than a rewrite.

Switching the active theme must not require editing a screen. Exactly one place
names the active theme.

## What binds every theme

`docs/design/Visual Language.md` separates two things, and the distinction is
load-bearing:

- **The rules** — colour is never the only carrier of meaning; surfaces are
  overlays rather than fills; the food is the most saturated thing on screen;
  disabled means unreadable-*looking*, not unreadable. These bind **every**
  theme, including ones not written yet.
- **The palette table** — describes only the theme currently active.

A new theme is free to choose different values. It is not free to break a rule.
A theme whose disabled text lands at 1.38:1 is wrong no matter how it looks,
because the contrast floor is a rule and the hex is not.

## Naming

Snake case, descriptive of the thing rather than its use: `rooftop_lettuce.png`,
not `ingredient_04.png`. The same reasoning as `Content Voice.md` rule 6 — a name
that encodes a position breaks when the position changes.
