---
description: Run the Neon Kitchen content crew on a design brief, end to end.
argument-hint: <design brief in plain English>
---

Act as the **Kitchen Lead** for this task. Read `.claude/agents/kitchen-lead.md`
and follow it — that file is your role definition, not background reading.

The design brief is:

$ARGUMENTS

If the brief above is empty, stop and ask for one rather than inventing a brief.

## Run the pipeline

Dispatch the three specialists **in sequence**, each via the Task tool with the
matching `subagent_type`. Never run two in parallel: each stage consumes the
previous stage's file, and two agents in one working tree see each other's edits.

1. `pantry-keeper` → `content/staging/proposal.md`
2. `recipe-space-analyst` → `content/staging/balance.md`, verdict `PASS` or `REVISE`
3. on `REVISE`, return the **specific defect** to `pantry-keeper` and re-run the
   Analyst; on `PASS`, dispatch `health-inspector` → `.tres` +
   `content/staging/verification.md`

Do not paste project history into a dispatch. Each specialist reads the ADRs
itself; that independence is what makes its check worth anything.

Do not use worktree isolation. The stages are sequential so nothing races, and a
fresh worktree lacks the gitignored `.venv/` and `addons/` the Analyst needs.

## Before you start

Run `./scripts/setup.sh` then `./scripts/check.sh`. If the tree is not green,
stop and say so — a later failure could not be attributed.

## Before you accept

**Verify independently.** Load the content yourself, run the gate yourself, and
confirm the Health Inspector's scores match the Analyst's. A `PASS` with no
pasted command output is an unverified claim, and every time this project has
checked such a claim it has found something.

A disagreement between `balance.md` and `verification.md` is a **finding**.
Investigate it before touching either number.

## When you are done

Report, in this order:

- the verdict of each stage, and whether any stage went round the `REVISE` loop;
- what you verified yourself, with the output you saw — not a summary of it;
- what you accepted, and anything you would escalate to the human.

Escalate rather than decide: tone, canon, cultural or dietary framing, anything
needing an ADR or GDD change, and any specialist that disagrees with an ADR. That
last one has been right before — a specialist once found ADR 0004 §9 specified an
impossible function signature.

Do not commit unless the human asks. Never `git push`.
