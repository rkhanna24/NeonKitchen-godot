---
type: agent-protocol
display-name: Phase 1 Agent Team
status: active
phase: phase-1
version: 1.0
updated: 2026-08-05
governed-by: "[[Neon Kitchen - Game Design Document]]"
coordinated-by: "[[Kitchen Lead]]"
repository: "https://github.com/rkhanna24/NeonKitchen-godot"
tags:
  - neon-kitchen
  - agent
  - multi-agent-system
---

# Phase 1 Agent Team

The team, the coordination protocol that binds it, and which backlog item each
role owns. Individual role definitions live in [[Kitchen Lead]],
[[Systems Cook]], and `.claude/agents/`; this document is the system view.

Ratified in DEC-020.

## The team as a multi-agent system

One **persistent** agent and four **task-scoped** ones. Stated in MAS terms so the
structure is legible rather than implied:

| Property | This system |
|---|---|
| **Architecture** | Centralised. A single coordinator (Kitchen Lead) holds all decision authority; specialists are stateless workers. No peer-to-peer specialist communication exists, and none is permitted. |
| **Task allocation** | Manual, coordinator-assigned, one Ready issue at a time. No bidding, no market, no self-selection. A specialist cannot claim work. |
| **Message passing** | File- and issue-mediated, never direct. A specialist's inbox is a **context packet**; its outbox is a **completion message**. Both templates are in [[Kitchen Lead]]. Specialists never message each other. |
| **Shared state** | The git working tree, the `content/staging/` handoff files, and the GitHub issue. Deliberately small — see *Shared state hazards*. |
| **Verification** | Adversarial and separated. The agent that produces an artifact never certifies it. |
| **Agent lifecycle** | Spawn → orient → propose → *terminate* → respawn → implement → prove → hand off → terminate. Task-scoped agents carry no memory across tasks. |
| **Conflict resolution** | Authority order, in [[Kitchen Lead]] and `AGENTS.md`. Unresolvable conflicts escalate to the human, who owns canon. |

### Why centralised

A specialist cannot decide anything, so there is nothing for specialists to
negotiate. Every genuine conflict this project has produced was a disagreement
about a *contract* — and the contract's owner is the human or an ADR, not a
consensus of agents. Adding peer negotiation would add a channel with no
authority behind it.

## Role contracts

Each row is the full contract. `+ tool` means "in addition to Read/Grep/Glob".

| | **Kitchen Lead** | **Systems Cook** | **Pantry Keeper** | **Recipe-Space Analyst** | **Health Inspector** |
|---|---|---|---|---|---|
| **Lifetime** | persistent | task-scoped | task-scoped | task-scoped | task-scoped |
| **Activation** | always | a bounded, approved code or config task | a design brief needs candidate content | a proposal needs its dish space enumerated | accepted content must become real files |
| **Input** | human intent, issues | context packet (`PROPOSE` or `IMPLEMENT`) | brief + ADR 0004 §§1,2,4,5 + schemas | `proposal.md` + ADR 0004 §3,4,5,11 | `proposal.md` + `balance.md` (must read `PASS`) |
| **Output** | decisions, commits | code + both-direction proof + handoff | `proposal.md` | `balance.md` with `PASS`/`REVISE` | `.tres` + locale rows + `verification.md` |
| **Shared state it may touch** | everything | files its packet names | `content/staging/` | `content/staging/` | `content/base/`, `content/staging/` |
| **Tools** | `+ Bash, Write, Edit, Task` | `+ Bash, Write, Edit` | `Write` only | `+ Bash, Write` | `+ Bash, Write, Edit` |
| **May not** | — | decide design; touch `docs/`, `project.godot`, `scripts/`, `.claude/` unprompted | compute scores; write game files | edit the proposal; propose numbers | change any number; proceed on `REVISE` |
| **Verifier** | the human | Kitchen Lead `/code-review` + independent evidence check | Recipe-Space Analyst | Kitchen Lead reads verdict *and* numbers | Kitchen Lead re-runs load, validate, score, gate |
| **Repair loop** | — | one bounded round | `REVISE` returns the specific defect | re-run after proposal correction | reports failure; does not repair |
| **Termination** | never | after acceptance | after writing the proposal | after writing the report | after reporting |

**Only the Kitchen Lead holds `Task`.** No specialist can spawn another, so none
can subcontract its own judgement.

### The boundaries are enforced, not requested

Tool grants do the work that prose cannot. The Pantry Keeper has no `Bash`, so it
*cannot* run the evaluator — which is what makes the Analyst's independent check
meaningful rather than a rubber stamp.

This was load-bearing on the first crew run: the Pantry Keeper hand-enumerated the
dish space, claimed a customer's best dish scored 80, and the Analyst found the
real best was 90. Neither role catches that alone.

But grants bound *capability*, not *intent* — in the same run the Pantry Keeper
computed scores by hand despite being told not to. Where a boundary matters and no
grant can express it, the verifier must check it.

## Coordination protocol

The twelve-step sequence lives in [[Kitchen Lead]] § Task-Scoped Agent Protocol
and is not duplicated here. What follows is the state machine it drives.

### Status transitions

GitHub Projects status is the coordination signal. DEC-014 makes issues the system
of record.

```
Inbox ──> Ready ──> In progress ──> Verification ──> Done
                         │               │
                         │               └──> In progress   (bounded repair)
                         └──> Blocked ──> Ready             (dependency cleared)
```

| Transition | Trigger | Who |
|---|---|---|
| Inbox → Ready | acceptance criteria exist and dependencies are closed | Kitchen Lead |
| Ready → In progress | specialist spawned, context packet posted **on the issue** | Kitchen Lead |
| In progress → Verification | completion message received | Kitchen Lead |
| Verification → In progress | verification found a defect; one bounded repair | Kitchen Lead |
| Verification → Done | evidence independently reproduced | Kitchen Lead, human for subjective calls |
| any → Blocked | a dependency is discovered mid-task | Kitchen Lead |

### Three protocol rules learned the hard way

**Post the packet on the issue before spawning, and record approval on the issue
before sending it.** A task-scoped agent cannot be resumed after it terminates. An
approval that exists only in a chat message is lost and the work must be respawned
from scratch. This has already happened once.

**Post the specialist's returned proposal on the issue too.** For a
propose-and-stop role the proposal *is* the specification for the implement
dispatch, and it arrives in the coordinator's context rather than on the issue
unless someone puts it there. On #19 nobody did: the implement dispatch was told
to expect three comments and found two. It proceeded correctly only because the
approval comment happened to restate both resolved ambiguities in full — luck, not
design. An approved specification living solely in a session transcript is exactly
what DEC-014 exists to prevent.

**Propose-and-stop means the agent dies at the stop.** The Systems Cook's hard stop
is not a pause — the process ends. Implementation therefore requires a *second*
dispatch carrying the approved proposal. Its packet states `PROPOSE` or
`IMPLEMENT` for exactly this reason.

### Shared state hazards

**Concurrent writers need worktree isolation.** Two agents in one tree see each
other's in-flight edits, each other's `git status`, and each other's gate runs. One
agent correctly diagnosed another's deliberately-failing test as a concurrent
process; it could as easily have concluded the tree was broken and started
repairing it. Disjoint file paths are luck, not isolation.

**Read-only reviewers should not get a worktree** — a fresh one lacks the
gitignored `.venv/` and `addons/` that the gate needs.

**The content crew runs strictly sequentially**, so it needs no isolation: each
stage consumes the previous stage's file.

**An agent must leave files it cannot account for.** If a path is modified or
untracked and was absent from the pre-flight `git status`, it belongs to another
session. The first crew run met this case and correctly declined to commit.

## Role-to-backlog mapping

Phase 1 as of 2026-08-05. Work the Kitchen Lead does directly is listed, because
"which tasks need no specialist" is part of the design.

**This table assigns roles; it is not a backlog.** GitHub Issues and the project
board remain the system of record for status, priority, dependencies, and
acceptance criteria (DEC-014). Nothing here should be consulted to learn whether
an issue is open. If a row disagrees with the tracker, the tracker wins and the
row is stale.

| Issue | Owner | Why |
|---|---|---|
| #1 epic | Kitchen Lead | coordination only, never implemented directly |
| #5 terminal runner | **Systems Cook** | bounded adapter code against a locked contract; blocked on #18 and #19 |
| #6 golden coverage | **Systems Cook**, decomposed first | too large for one packet as written; its adversarial-audit scope is a judgement task the Kitchen Lead must frame before any dispatch |
| #10 playtest | **human only** | no agent can answer whether the mechanic is fun |
| #12 this design | Kitchen Lead + human | an agent cannot draft its own charter; the issue reserves role boundaries for human approval |
| #18 constraint identity | Kitchen Lead **then** Systems Cook | needs a design decision first — the ADR is implicated. Not dispatchable until the contract is settled |
| #19 register translation | **Systems Cook** | single config change plus a check that must be proven to fail; the archetype for this role |
| #20 false claim in a test | **Systems Cook** | small, but the fix is a judgement about what the test should pin — packet must say which |
| #21 dead `ext_resource` | Kitchen Lead | one line; a packet would cost more than the change |
| future content briefs | **content crew** | Pantry Keeper → Analyst → Health Inspector, via `/crew` or `tools/run_crew.sh` |

### What no specialist may take

- anything requiring an ADR or GDD amendment;
- tone, canon, cultural or dietary framing — the human owns canon;
- a decision about the agent team itself, including this document;
- anything where the specification is the thing in doubt.

The last one is the common case and the easiest to get wrong. When a task is
blocked on *what the contract should say*, dispatching an implementer produces a
confident implementation of a guess.
