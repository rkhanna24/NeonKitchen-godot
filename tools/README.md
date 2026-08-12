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

The split itself — `split_sections()`, fence-aware, returning
`(heading_text, start_line, end_line, body_lines)` — lives in
`heading_sections.py`, factored out during issue #30 so `gap_scan.py` could
locate an ADR section ("5. Ports", "7. Commands", ...) by heading substring
without duplicating this logic. Verified not to regress this tool: all
`--verify-probes` probes passed unchanged after the move (see "Keeping it
honest" below). The paragraph-level fallback below it — `_split_paragraphs`,
`_nearest_subheading`, the bare-label merge — stays local to this file, since
`gap_scan.py` only ever needs a whole section, never a paragraph inside one.

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

## `gap_scan.py`

Reads the ADRs, inventories the codebase, and reports what the documents
require but the code does not have — distinguishing "not built yet" from
"deliberately not built" using the documents' own words. See issue #30 for
the goal and the approved design this implements.

```bash
python3 tools/gap_scan.py                  # offline: no network, no gh
python3 tools/gap_scan.py --check-backlog  # + gh issue list (read-only)
python3 tools/gap_scan.py --file-issues    # + gh issue create (mutating)
```

**A naive diff would be wrong here.** ADR 0002 §5 declares seven ports;
`core/ports/` holds one file. A diff of declared-versus-present reports six
gaps, and only one — `tests/golden/` in §6's layout — is real. The other six
are ports the ADR marks "Interface only" or "Not created", with the reason
recorded right there. The work is telling those apart, not diffing.

### What "the codebase contains X" means

Two independent facts, both reported, never collapsed into one boolean:
whether a `class_name` declaration exists **anywhere** under the repo root,
and whether it exists **at its ratified path** (`core/domain/commands/`,
`core/domain/events/`, or `core/ports/`, per ADR 0002 §6, filename
`snake_case(ClassName).gd`). On the current tree the two facts agree for
every command, event, and port — so a disagreement is real but otherwise
unexercised, and `MISLOCATED` exists to report it when it happens:

```
BUILT       both facts true, at the ratified path
MISLOCATED  class_name found, but not at its ratified path
DEFERRED    found nowhere, but a document licenses the absence
GAP         found nowhere, and nothing licenses the absence
```

Proven by construction, then reverted (issue #30's approval required this
before shipping `MISLOCATED` at all — "a status that has never been observed
firing is the same defect as a test never seen to fail"): moving
`start_session.gd` from `core/domain/commands/` to `core/domain/rules/`
made `gap_scan.py` report `StartSession` as `MISLOCATED` — not `BUILT`, not
`GAP` — quoting both the wrong and the ratified path. Reverted; the tree
returned to reporting it `BUILT`.

Session phases (ADR 0004 §7a) are a fifth category with only *one* "contains"
fact: enum-member presence anywhere in the codebase, not tied to a specific
enum name or file. This was a judgement call, not something the ADR
specifies — confirmed as the working definition during approval — and it
means `MISLOCATED` cannot occur for a phase by construction: a single fact
has nothing to disagree with itself.

### The deferral rule

Applied only once a declaration is found nowhere in the code. Search in
order, stop at first match:

- **(a) another cell in the same table row states status or reason.** Only
  the port table (ADR 0002 §5) has a status column, so this rule is
  port-table-specific; the commands and events tables have a "Fields"
  column, which is not a status. Whatever the cell says *is* the citation —
  no vocabulary-hunting needed. An **empty** status cell is not a citation
  of anything, though, and is reported `GAP` rather than a hollow
  `DEFERRED: ""`: caught by deliberately blanking a status cell during
  self-review, before this guard existed.
- **(b) the declaring heading itself** carries deferral vocabulary
  (`deferred`, `interface only`, `reserved but undefined`, `deliberately
  unimplemented`, `contract recorded, not implemented`, `requires an ADR` —
  measured across `docs/adr/` in issue #30's scope comment).
- **(c) a sentence in the section body that names the declaration by its
  exact identifier** and carries the same vocabulary.

No match → `GAP`, never inferred from a section merely being *about*
deferral. The identifier requirement is the load-bearing part, and
`tests/golden/` is its proof, though not through rule (c) itself —
directories go through `scan_layout`'s own exact-membership check against
"Deferred folders", the structural analogue of rule (c) for a path rather
than a class identifier. `tests/golden/` sits in the very ADR 0002 §6
section whose body contains that paragraph, but the paragraph never names
`tests/golden/` by its exact path — so it is reported `GAP`, not swallowed
by a section that happens to discuss deferral for *other* paths. Rule (c)
proper (`_search_deferral` in `gap_scan.py`) applies only to command, event,
and phase identifiers, and has no live case to exercise it in the current
tree, since none of the twelve declarations extracted from ADR 0004 is
deferred.

Rule (c) proper *was* exercised — and found wrong — during the constructed
spike for the ranking tie-break below: table rows were being fed into the
same sentence-splitter as prose, and an unrelated intro sentence about the
four cooking-challenge command terms falsely matched `RemoveIngredient`
(present three cells away, in the table). Fixed by stripping table rows
before sentence-splitting; see `_strip_table_lines` in `gap_scan.py`.

### Ranking

Regressions outrank fresh gaps (proven-lost work over merely-undone work),
then unscheduled before scheduled (name something nobody is already
tracking), then earlier ADR position as a foundational-ness proxy, then the
matched issue number — or, absent one, the declaration's own name — as a
final deterministic tie-break. The output states which tier decided the
order rather than presenting a bare list.

Proven by construction, then reverted (also required before shipping,
alongside `MISLOCATED`: today's tree has exactly one real gap, so ranking
never has to choose): moving `remove_ingredient.gd` out of the repository
entirely (not just to a wrong path — a true absence, unlike the `MISLOCATED`
spike above) created a second live gap.

- **Offline** (no `--check-backlog`): ranked `tests/golden/` (ADR 0002 §6)
  ahead of `RemoveIngredient` (ADR 0004 §7), reason `"earlier in the
  decision record (ADR 0002 §6) than the alternative(s)"` — the ADR-position
  tier deciding, since neither had a known backlog state.
- **With `--check-backlog`** (read-only `gh issue list`): the order flipped.
  `RemoveIngredient` matched **closed** issue #22, which originally built it
  — a genuine regression, not a contrived one, since the spike had just
  deleted what #22 shipped — and ranked first with reason `"a regression:
  closed issue #22 ... covered this, and it has reappeared"`.
  `tests/golden/` matched **open** issue #6 and was reported `scheduled`.

Both runs reverted; the tree returned to reporting the single real gap.

### Dedupe against the backlog

`--check-backlog` and `--file-issues` are the only network-touching paths;
plain analysis needs neither `gh` nor credentials, for the same reason
`lore_query.py` needs none — a grader must be able to run the reasoning
without an authenticated session.

Matching is **title-first, whole-word, case-insensitive**, against the
declaration's own identifier (`RandomPort`) or a directory's final path
segment (`tests/golden/` → `golden`, since a full path never appears
verbatim in issue prose). A title match on an **open** issue is reported
`SCHEDULED` (confident); a match found only in an issue's **body** is
reported `POSSIBLE — verify`, never silently folded into `SCHEDULED`; a
match on a **closed** issue is reported `REGRESSION`. `--file-issues` is
more conservative than reporting: it skips filing on *any* match at all,
title or body, open or closed, printing why it skipped. Erring toward
duplicates is deliberate — a duplicate costs a human ten seconds to close; a
gap suppressed by a false match is invisible until someone re-discovers it
by hand.

**Known limitation, not resolved by construction.** Unlike `MISLOCATED` and
the ranking tie-break above, this is a judgement about text matching, not
machinery with a clean pass/fail to prove. On the current tree it correctly
matched `tests/golden/` → `golden` against open issue #6 ("golden-case
coverage"), and — during the ranking spike, incidentally, on a temporarily
constructed second gap — correctly matched `RemoveIngredient` against
**closed** issue #22, which had in fact originally built it. Both are real
positives, not contrived ones, but neither is a counter-example: nothing in
the current tree exercises a *false* match. A generic final path segment
(e.g. a directory literally named `core/`) would produce a weak,
high-false-positive search term; nothing in this tool detects that case
specially.

### Keeping it honest

```bash
python3 tools/gap_scan.py
```

Checked in both directions against the live corpus, then reverted:

- Blanking `RandomPort`'s status cell in ADR 0002 §5 made it report
  `GAP` instead of `DEFERRED` (before the empty-cell guard existed, it
  reported `DEFERRED: ""` — a hollow citation, itself a bug found and fixed
  during this work). Restoring the cell returned it to `DEFERRED`.
- Adding `` `tests/golden/` `` to ADR 0002 §6's "Deferred folders" paragraph
  made it report `DEFERRED` instead of `GAP`. Removing it again returned it
  to `GAP`.
- The `MISLOCATED` and ranking-tie-break spikes above are the same kind of
  proof applied to the two pieces of machinery that had no live case in the
  current tree to exercise them.
