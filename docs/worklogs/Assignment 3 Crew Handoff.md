---
type: session-handoff
status: in-progress
created: 2026-08-05
subject: "Assignment 3 — Build an Agent Crew"
repository: "https://github.com/rkhanna24/NeonKitchen-godot"
---

# Assignment 3 — Crew Handoff

Read this first, then `.claude/agents/*.md`. Everything below was true at
handoff; verify rather than assume.

## The assignment

Build a system of 3+ agents that coordinate to produce game-ready output for the
capstone. Orchestration is **Claude Code**, not CrewAI — the course moved to
Claude Code this year. Deadline has passed; the human accepts a lateness penalty
and prefers correctness over speed.

Deliverables and marks:

| Deliverable | Marks | State |
|---|---|---|
| Crew code — runs, 3+ agents, no crash | 3.0 | **specs written, NEVER RUN** |
| Game connection — output is for the capstone | 3.0 | strong by design, unproven |
| Role clarity — each role load-bearing | 2.0 | done, enforced by tool grants |
| Mermaid diagram | 1.0 | **not started** |
| ReadMe | 1.0 | **not started** |

## What exists

Four agent definitions in `.claude/agents/`:

| File | Model | Tools | Output |
|---|---|---|---|
| `kitchen-lead.md` | opus | + `Task` (only one that can spawn) | routing, accept/revise, commits |
| `pantry-keeper.md` | sonnet | `Write` only, **no Bash** | `content/staging/proposal.md` |
| `recipe-space-analyst.md` | sonnet | + `Bash` | `content/staging/balance.md`, PASS/REVISE |
| `health-inspector.md` | sonnet | + `Edit` | `.tres` files + `content/staging/verification.md` |

`content/staging/` exists with a `.gdignore`. Staging is **not** under `tools/`
because the Analyst must load `res://` paths and a `.gdignore`d directory cannot
serve them.

## The pipeline

```
brief -> pantry-keeper        -> proposal.md
      -> recipe-space-analyst -> balance.md (PASS | REVISE)
      -> Kitchen Lead decides
         REVISE -> back to pantry-keeper with the specific defect
         PASS   -> health-inspector -> .tres + verification.md
      -> Kitchen Lead verifies independently -> accept, or one bounded repair
```

Sequential, never parallel: each stage consumes the previous stage's file.

## THE CRITICAL GAP

**The crew has never been run.** That is rubric line one, worth 3.0 marks, and
it is entirely unverified. Do this before anything else.

Suggested first brief — deliberately small, and chosen because it needs a *new
ingredient* to be solvable, so the Analyst has something real to catch:

> A late-shift medic who wants something fresh and light, nothing heavy. Add
> whatever single ingredient makes that request solvable against the existing
> pantry.

Why this brief: the current pantry has exactly one Fresh source
(`ember_chili_paste`, fresh 1) and it also carries spicy 3 and adventurous 2. A
customer wanting Fresh without heaviness is *not* satisfiable today, so the
Pantry Keeper must add an ingredient and the Analyst must confirm it worked. If
the crew produces a PASS without adding anything, that is a finding.

Expect problems on first run. Likely ones:

- an agent writing outside its boundary, or trying to and failing on tool grants;
- the Analyst reimplementing the formula instead of running `Evaluator.evaluate`;
- the Health Inspector hand-writing `.tres` rather than using `ResourceSaver`;
- disagreement between `balance.md` scores and `verification.md` scores. **That
  is a real finding, not noise — investigate before fixing.**

## Then: diagram and ReadMe

Mermaid should show the **repair loop**, not just a straight line — the
REVISE→Pantry Keeper edge is what makes it a crew rather than a chain. Also show
which artifact each edge carries.

ReadMe must **name the game** (*Neon Kitchen*) and say what the crew produces.
The strongest Game Connection argument, worth making explicitly: the crew's
output is validated by the game's own code — `ContentValidator` rejects malformed
IDs, out-of-range values and vacuous constraints; `Evaluator` computes real
scores; `scripts/check.sh` gates it. Success is the game's criterion, not a human
eyeballing plausible JSON.

## Project state at handoff

- 107 tests, gate green, CI green on `7d139bf`, working tree clean apart from the
  four agent specs and this file.
- 11 of 17 issues Done. Open: #1 (epic), #5 (terminal runner, blocked by #18),
  #6, #10, #12, #18 (Ready).
- Nothing is playable yet. #5 is the first issue that changes that.
- **#12 may already be satisfied** by `docs/agents/Systems Cook.md` + DEC-019.
  Worth reading before doing work on it.

## Conventions that will bite if ignored

- **Never `git push` without explicit human approval.** Commits are fine.
- Commit subject ≤72 chars, body ≤15 lines; detail goes on the issue (DEC-014).
- Run `./scripts/setup.sh` then `./scripts/check.sh` before changing anything.
- **Prove a check can fail.** For any check or test added, introduce the defect
  it guards and confirm it reports and exits nonzero. See `AGENTS.md`.
- Godot omits any `.tres` field equal to its class default, even when set
  explicitly in code. Only a test can pin such a value.
- Concurrent *writing* agents need worktree isolation. Read-only reviewers should
  not have it — a fresh worktree lacks the gitignored `.venv/` and `addons/`.

## The failure mode this project keeps producing

Five review rounds, and nearly every defect was the same shape: **the code was
defensible and the claim about it was false.** A port promising sorted output
while sorting by interned pointer. A guard covering half its comment. A test
named for a bug it could not catch. A composer documented as asserting its own
output while leaning entirely on the value object below it — deleting its clamp
left all 95 tests green.

When an agent reports success, ask what it actually ran. A `PASS` with no pasted
output is an unverified claim.

## Two things the human decided that are easy to get wrong

**A stated boundary is absolute regardless of the reason given.** "No soy" means
no soy whether allergy, intolerance or dislike. The engine cannot distinguish
them and does not try. ADR 0004 §5.

**Solvability is a session property, not per customer.** A customer may be
impossible to fully satisfy with the current pantry; what matters is that the day
is completable and each encounter teaches something. So a reaction line authored
for an unreachable band is correct content, not dead weight. ADR 0004 §11.
