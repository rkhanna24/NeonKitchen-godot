# tools/

Developer tools. Not game code, not shipped, not imported by Godot — the
`.gdignore` here keeps the directory out of the engine's filesystem scan.

## `flavor_explorer.html`

An interactive explorer for the ADR 0004 scoring contract. Open it directly in
a browser; it is self-contained, with no build step and no network access.

Per-dimension target and weight controls, a dish built either directly or from
up to three ingredients, live score and band, the per-dimension penalty table,
and sweep charts showing how the score responds as each dimension moves — with
the 40/65/85 band edges marked.

### What this is not

**It is a model of the contract, not the game.** Once #9 lands, the GDScript
evaluator is the only implementation that decides anything. This applet exists
to build intuition about the scoring curve, not to answer questions about
behaviour in play.

Treat any disagreement between this and the game as a bug in this file until
proven otherwise.

### Keeping it honest

```bash
./tools/verify_flavor_model.sh
```

Extracts the applet's own scoring functions from the HTML and compares them
against an oracle written from ADR 0004, across 7,476 cases including 560 that
land exactly on a rating-band edge. Those edges are the point: JavaScript has no
integer division, and a float implementation diverges from the game precisely
at 40, 65, and 85.

Run it whenever ADR 0004 changes. It is deliberately **not** part of
`scripts/check.sh`, because it needs Node, which is not a declared project
dependency — wiring in a check that silently skips when a tool is missing would
defeat the purpose.

The check is verified in the failing direction: removing the `Math.floor` from
the applet makes it report scores like `33.33333333333333` against the oracle's
`34`, and the script exits nonzero.

**After #9**, replace the oracle inside `verify_flavor_model.sh` with the real
GDScript evaluator. That turns this from a model-to-model comparison into a
genuine parity test, which is the only version that can catch the drift that
actually matters.
