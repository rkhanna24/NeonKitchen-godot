# Assignment 5 — Goal-Oriented Coding Agent

*Neon Kitchen* — a recipe-composition puzzle in Godot 4.7.1.
Branch: `tools/gap-scanner` · Gate green at **186 tests**.

The agent reads the project's ratified design documents, inventories what exists
in the codebase, reports the difference, and picks one thing to build. Then a
second agent built it.

The interesting part is not the diff. It is that **most of the difference between
the documents and the code is not a gap** — it is work the documents themselves
deliberately deferred. An agent that cannot tell those apart reports 27 findings,
26 of them wrong, and is worse than useless. This one reports one.

---

## The three required answers

### (a) What feature did the agent build?

**[`tests/golden/test_golden_scenarios.gd`](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/tests/golden/test_golden_scenarios.gd)** — seven golden
scenarios pinning `Evaluator.evaluate()` against the shipped twelve-ingredient,
eight-customer content. 335 lines. Each case pins score, band, constraint outcome,
and the feedback fields.

```
test_delighted_dish_with_no_largest_miss_because_every_penalty_is_zero
test_mixed_band_edge_at_the_lower_boundary_of_forty
test_dissatisfied_dish_from_an_empty_plate
test_dissatisfied_band_edge_at_thirty_nine_without_any_constraint_violation
test_constraint_violation_caps_at_thirty_nine_but_reports_the_flavour_score
test_satisfied_band_edge_at_the_lower_boundary_of_sixty_five
test_delighted_band_edge_at_the_lower_boundary_of_eighty_five
```

The cases were not picked for being easy to assert. Each holds a shape that is
easy to break silently: three sit exactly on a band edge; one is the constraint
cap, checking that a violated dish still *reports* its flavour score rather than
zeroing it; one is the configuration where `largest_miss` is absent.

That last case is the one that had to be reasoned about rather than observed.
ADR 0004 §6 gives two routes to an absent largest miss — *"reported as absent when
every penalty is zero"*, and DEC-025's *"reported as absent when no candidate
remains"* — but the second collapses into the first, because a dimension is only
excluded when its target and actual are both 0, which is a zero penalty. So
absence requires every weighted penalty to be zero, and §3's formula then forces
the score to exactly 100. A case asserting an absent largest miss at any other
score would be unwritable.

### (b) Why did it select that feature?

It did not select it by ranking severity. It selected it by **elimination** — it
was the only candidate that survived the filter.

ADR 0002 §6 lists `tests/golden/` in the ratified repository layout. Its
neighbours `tests/integration/` and `tests/smoke/` are also listed and also absent
— but those two appear in that same section's "Deferred folders" paragraph, and
`tests/golden/` does not. Nothing in the ratified documents licensed its absence.

Same story on the other side of the report: seven of the eight ports in ADR 0002
§5 are unbuilt, and every one carries its own deferral in the table's own words
— *"Interface only"*, *"Not created — commands are the input contract"*. The
scanner quotes the sentence that excused each one rather than asserting it is
fine.

```
=== Ports (ADR 0002 §5) ===
  [BUILT     ] ContentRepository        core/ports/content_repository.gd
  [DEFERRED  ] RandomPort               ADR 0002 §5: "Interface only"
  [DEFERRED  ] PlayerInputPort          ADR 0002 §5: "Not created — commands are the input contract"
  [DEFERRED  ] PresentationPort         ADR 0002 §5: "Not created — events are the output contract"
  ...
```

That is the whole design. **A gap is a declaration with no implementation *and no
sentence excusing it*.** Deferral is detected by three rules, in
[`_search_deferral`](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/tools/gap_scan.py):
the declaring row carries deferral language; or the declaring heading does; or
some sentence in the section both carries deferral language **and names the
declaration's exact identifier**.

That last clause is the one that matters, and it was tightened after a false
negative. A section can be *about* deferral in general — a paragraph explaining
that persistence is out of scope sits a few lines from an unrelated declaration
and, under a looser rule, silently excuses it. Requiring the exact identifier in
the same sentence is what keeps proximity from reading as permission.

### (c) Did it run in the game?

Yes — and in a stronger sense than "the tests pass."

Every expected value in the suite was produced by **running the real `Evaluator`
against the real `content/base/`**, not by hand arithmetic and not against a mock.
The suite loads the shipped `.tres` content through the actual repository, so a
change to an ingredient's flavour values or a customer's weights turns it red. It
exercises the same code path the terminal runner does when a human plays.

Each value was then re-derived by hand from ADR 0004 §3's formula as an
independent second check. Both agree. The per-case comments show that second
derivation, so a reader can audit any number without re-running the engine.

The full gate is green at **186 tests**, up from 179.

And the loop closes on itself — re-running the scanner after the build:

```
=== Repository layout (ADR 0002 §6) ===
  [BUILT     ] tests/golden/            tests/golden/

=== Gaps requiring action ===
  None found.
```

The agent that chose the target now reports the target met. Nobody told it the
answer changed.

---

## Requirements

| Requirement | Where |
|---|---|
| Read the design document | [`gap_scan.py`](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/tools/gap_scan.py) parses declarations from ADR 0002 §5/§6 and ADR 0004 §7/§7a/§8, via [`heading_sections.py`](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/tools/heading_sections.py) |
| Scan the codebase | directory walk plus a `class_name` inventory, reported as two independent facts |
| Detect gaps | declared-minus-implemented, then filtered by the documents' own deferral language |
| Prioritize | regressions outrank fresh gaps; output names the item with the citation that justifies it |
| Generate code for a missing feature | [`tests/golden/`](https://github.com/rkhanna24/NeonKitchen-godot/tree/tools/gap-scanner/tests/golden) — built by the [Systems Cook](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/.claude/agents/systems-cook.md) |

Two agents, deliberately: the scanner has no authority to write game code, and
the Systems Cook has no authority to decide what is worth building. The handoff
between them is the prioritized finding, with its citation.

---

## What went wrong, and what that exposed

The building agent **hit its session limit mid-task**. Its last line before dying:

> "Let's also prove the suite catches a band-edge regression, not just a content
> regression, since the header comment claims both were tested."

It had noticed, and said aloud, that its own file header was making a claim its
evidence did not yet support. It ran out of budget in the gap between the two.

The suite itself was complete and green. Finishing the proof meant moving the
`MIXED` edge from 40 to 41 and confirming the borderline case flips:

```
[Failed]: [3] expected to equal [2]:   →  DISSATISFIED where MIXED was expected
```

**Doing that exposed a second, smaller version of the same defect.** The header
promised failures would name *the changed field, not just "assertion failed"* —
but the band assertions carried no message, so the first run printed two bare
integers. `[3] expected to equal [2]` does not tell a reader what `3` and `2` are.
Seven assertions now say `"band must be MIXED"`.

A comment claiming more than the code delivers, found in the docstring of the
suite whose entire purpose is to catch exactly that. Worth keeping in the record
rather than quietly fixing: the failure mode this assignment is about — a
plausible claim with nothing behind it — showed up in the artifact built to
prevent it.

---

## Running it

```bash
python3 tools/gap_scan.py        # stdlib only; no network, no API key
./scripts/check.sh               # full gate — 186 tests
```

| Artifact | |
|---|---|
| [`tools/gap_scan.py`](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/tools/gap_scan.py) | the scanner — 961 lines |
| [`tools/heading_sections.py`](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/tools/heading_sections.py) | shared markdown sectioning |
| [`tests/golden/test_golden_scenarios.gd`](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/tests/golden/test_golden_scenarios.gd) | the generated feature |
| [`.claude/agents/systems-cook.md`](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/.claude/agents/systems-cook.md) | the building agent's charter and tool grants |
| [`docs/adr/0002-phase-1-structural-foundation.md`](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/docs/adr/0002-phase-1-structural-foundation.md) | §5 ports, §6 layout — the source of truth read |
| [`docs/adr/0004-phase-1-contracts.md`](https://github.com/rkhanna24/NeonKitchen-godot/blob/tools/gap-scanner/docs/adr/0004-phase-1-contracts.md) | §3 scoring, §7 commands, §8 events |
