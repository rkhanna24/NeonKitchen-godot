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

## `lore_query.py`

Answers "what do the design docs say about X" by searching
`docs/design/`, `docs/adr/`, and `docs/technical_architecture.md` for the
passages relevant to a query, so a content agent can retrieve what it needs
instead of reading whole files. Pure standard library — no dependencies, no
network access, and no persisted index. A stale index fails worse than a
blunt query, and every run re-walks the corpus fresh.

```bash
python3 tools/lore_query.py north tower
python3 tools/lore_query.py --top 5 reaction key resolution
python3 tools/lore_query.py --verify-probes
```

`docs/agents/`, `docs/crew/`, `docs/Home.md`, and `docs/worklogs/` are
excluded: process documentation and project log, not design or lore content
a content agent should be retrieving from. Nine files are searched.

### Chunking

The corpus is split on `#`, `##`, and `###` headings (`####` and deeper are
body text of the enclosing chunk). ADR 0004 keeps every numbered contract
section at `###`, so `##` alone would make its entire *Decision* section one
~500-line chunk. A bare `#` is also a split point: the GDD's `# 3.
Development` has no `##` before the next `#`, and without this a naive
scanner would glue its milestone table onto the unrelated `## 2.4
Progression, Failure, and Recovery` section above it.

Heading detection is suspended inside fenced code blocks, so the ADR
template's own example headings inside `docs/adr/README.md`'s ` ```markdown `
fence are never mistaken for real sections.

A section over **40 lines** falls back to returning the matching paragraph
(a blank-line-delimited block, itself fence-aware) with its heading
prepended, so the passage stays labeled and readable instead of dumping
~60–90 lines for one question. 40 is reused from the scope comment's own
reporting threshold ("18 sections exceed 40 lines") rather than a second
invented number, and is load-bearing at both ends: ADR 0004 §8a (39 lines)
stays whole, and ADR 0004 §2 (60 lines) and Content Voice's "Five rules"
(43 lines) fall back to paragraph mode.

When the matching paragraph sits under a `####` (or deeper) heading inside
an oversized section, that heading is prepended to the label as a
breadcrumb rather than being lost:

```
### 2. Customer targets › #### The default customer profile
```

A paragraph that is only a bare label line — `**ESTABLISHED**` alone, as
the Lore Bible's "## The City" uses — is merged forward into the next
paragraph before scoring, so a fallback can never return a claim's bullets
without the `ESTABLISHED` / `PROPOSED` / `DECIDED` label that scopes them.
Not exercised by today's content (no section using that pattern is
currently oversized); load-bearing the moment one is.

**Known limitation.** A paragraph that is itself a large fenced block with
no internal blank lines — `## 4. System Shape`'s mermaid diagram (49 lines)
and `## 6. Proposed Repository Structure`'s directory tree (57 lines) in
`technical_architecture.md` — can exceed the 40-line cap, because it cannot
be split further without breaking the fence. Neither is exercised by any
probe query; flagged rather than silently handled.

### Scoring

BM25 (`k1=1.5`, `b=0.75`), chosen over raw term overlap and naive TF-IDF by
running all three against the probe queries below: raw overlap produced
exact-tied scores that made "north tower" depend on tie-break order rather
than signal, and naive TF-IDF's length normalisation let an incidental
paragraph in `### 8. Events` outrank `### 8a. Reaction key resolution`.
BM25 got every probe right with a clear score margin over the runner-up.

**Heading boost (added in the issue #27 bounded repair).** A chunk whose
own heading contains a query term gets `HEADING_BOOST_WEIGHT` (`0.3`) times
that term's idf added to its score, on top of BM25. Without it, "who is
the Cook" confidently returned `## 4.2 How the Agents Work Together` — the
GDD's agent-coordination diagram, which names "Systems Cook", "Service
Cook", and "Prep Cook" three times in its body — instead of the Lore
Bible's `## The Cook (Player Character)`, which says "Cook" once, in its
own heading. That was a ranking failure: raw term frequency favours the
diagram, and nothing in plain BM25 distinguishes a section *about* something
from one that merely mentions it several times in passing.

`0.3` was measured, not guessed. Binary search puts the exact weight needed
to flip "who is the Cook" at `≈0.155`; raising the weight further was then
pushed until it broke a different probe — at `≈2.6` it flips "who approves
the truck parking" from `## What the Gangster Establishes` to `## The
Truck` (which also names itself in its heading, with less body signal to
close the gap), and separately at `≈3.3` it breaks "can a description name
a flavour dimension". `0.3` sits with roughly 2× headroom above the minimum
that fixes the Cook probe, and better than 8× headroom below the point
where the truck-parking probe regresses. **The trade, stated plainly: this
constant helps exactly one probe (the one it was added for) and, at this
weight, costs none of the other eight** — but the corpus has two headings
each capable of regressing at a higher weight, so it is not free to raise
further without re-checking both.

### "No good match"

A retriever that returns *something* for every query looks like it works.
One gate stands between this tool and confident filler:

- **Term coverage, not a score threshold.** The top-ranked chunk must
  contain at least half of the query's distinct, stopword-filtered terms.
  A fixed BM25 score cutoff has no natural zero point and scales with
  corpus size; "did we find most of what was asked about, together, in one
  place" is structural instead. This is lexical, not semantic — a real
  answer phrased in different vocabulary would be wrongly rejected, and
  there is no automated way to detect that short of trying more queries.

**A `MIN_QUERY_TERMS` gate rejecting single-term queries used to sit here
too, and was removed in the issue #27 bounded repair.** It was added on the
theory that a single word like `cook` can't show terms occurring
*together*, so its sense (player character vs. AI-agent role) would be
whichever the scorer preferred — and it masked the ranking failure above
rather than fixing it. Worse, it rejected every legitimate single-noun
query: `kimchi`, `gangster`, and `solarpunk` all returned "no good match"
purely because they were one word, not because the corpus lacked an
answer. Coverage on a single term is trivially 100% or 0%, which is exactly
why it is a sufficient gate on its own once the heading boost fixes the
underlying ranking: a single term either appears in the top chunk or it
doesn't, and the corpus content decides which chunk that is.

Document frequency was checked as an alternative way to single out `cook`
specifically and rejected: across the corpus's 248 chunks, `cook` appears
in 9, `gangster` in 4 — a 2× spread with no natural gap — and `solarpunk`
and `tower` in 7 each, `noodles` in 10. A threshold meant to gate `cook` as
"too generic" while letting `gangster` through would have to sit between 4
and 9, which also blocks `solarpunk` and `tower`; `noodles`, at 10, is even
*more* frequent than `cook`, so no cutoff separates "generic, don't answer"
from "specific, do answer" at all. There is no frequency-based line here,
so none is drawn.

### Keeping it honest

```bash
python3 tools/lore_query.py --verify-probes
```

Runs the five queries from issue #27's scope comment plus four added in
the bounded repair (`who is the Cook`, `kimchi`, `gangster`, `solarpunk`)
that must each hit a named passage, and adversarial queries that must
return no match: two with no corpus overlap and one
plausible-but-unanswered ("how much does a customer tip after a delighted
rating" — no tip mechanic exists anywhere in the corpus). Exits nonzero if
any probe regresses, printing the coverage figure for both directions so
the margin is visible rather than asserted.

`who is the Cook` used to be an adversarial (must-return-no-match) probe,
on the theory that the Lore Bible establishes nothing about the player
character. That was a misreading of the Lore Bible's own `## The Cook
(Player Character)` section, which exists specifically to report that gap
honestly — the section *is* the correct answer, so a retriever finding it
is working, not failing. It is now a hit probe.

Checked in the failing direction during the bounded repair, then reverted:

- Setting `HEADING_BOOST_WEIGHT` to `0.0` (the old, boost-free behaviour)
  made `who is the Cook` regress to `## 4.2 How the Agents Work Together`
  again, `--verify-probes` reported `[FAIL]` on that probe, and the run
  exited `3`.
- Reinstating a `MIN_QUERY_TERMS = 2` gate made `who is the Cook`,
  `kimchi`, `gangster`, and `solarpunk` all regress to "no match" (`[FAIL]`
  on all four), and the run again exited `3`. The five original probes
  were unaffected by either injected defect.

Checked in the failing direction during the original implementation, then
reverted:

- Lowering `COVERAGE_THRESHOLD` to 0.15 made the second nonsense probe
  ("bicycle mango stock exchange plumbing", 0.20 coverage) and the
  plausible-unanswered probe (0.33 coverage) return a chunk instead of "no
  good match". The first nonsense probe still passed: it shares no term
  with any chunk, so its score is zero regardless of the threshold.

Every defect above made `--verify-probes` fail and exit nonzero; restoring
the constant returned it to all-pass.
