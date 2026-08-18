---
type: agent-worklog
agent-id: kitchen-lead
status: active
phase: phase-1
created: 2026-07-30
last-updated: 2026-07-31
agent-definition: "[[Kitchen Lead]]"
governed-by: "[[Neon Kitchen - Game Design Document]]"
repository: "https://github.com/rkhanna24/NeonKitchen-godot"
task-board: "https://github.com/users/rkhanna24/projects/1"
tags:
  - neon-kitchen
  - worklog
  - persistent-memory
  - phase-1
---

# Kitchen Lead Worklog

> [!important] Purpose
> This file is the Kitchen Lead’s durable project memory. Keep the current snapshot concise and current. Preserve material decisions, evidence, and handoffs in the chronological log.

## How to Use This File

- Update **Current Project Snapshot** whenever the active state changes.
- Append chronological entries at the bottom; do not rewrite history to make an old decision appear current.
- Mark superseded decisions explicitly.
- Link authoritative artifacts rather than duplicating their full contents.
- Record whether a statement is approved, provisional, recommended, or observed.
- Never store credentials, private personal information, or secret values here.

## Current Project Snapshot

**Last reviewed:** 2026-07-30  
**Current phase:** Phase 1 — primitive headless GDScript recipe prototype  
**Human-facing persistent agent:** Kitchen Lead  
**Current objective:** Approve the smallest long-term architecture slice, then build a GDScript prototype that tests whether composing recipes for customer preferences is understandable and enjoyable.

### Authority Order

1. explicit human decisions;
2. [[Neon Kitchen - Game Design Document]];
3. approved decisions in this worklog;
4. test and playtest evidence;
5. provisional recommendations.

### Current Working Decisions

| ID | Decision | Status | Authority |
|---|---|---|---|
| DEC-001 | The capstone deliverable is an exported Godot 4.x desktop game with a functional player-facing UI. | Approved | Human |
| DEC-002 | Phase 1 is a primitive headless GDScript prototype used to validate recipe composition before UI production. | Approved | Human |
| DEC-003 | Phase 1 should reuse UI-independent data and recipe-evaluation code in the later Godot interface. | Approved | Human and GDD |
| DEC-004 | Kitchen Lead is the only persistent active agent during Phase 1 and is the human’s default design and coordination interface. | Approved | Human |
| DEC-005 | Worldkeeper and Pantry Keeper are deferred as active agents until the project has enough lore and culinary content to justify persistent stewardship. | Approved | Human |
| DEC-006 | Phase 1 implementation and verification agents are narrowly scoped and terminate after handoff, bounded repair, and acceptance. | Approved | Human and GDD |
| DEC-007 | Expeditor is unnecessary for simple Phase 1 tasks; Kitchen Lead may decompose them directly. | Recommended working rule | Kitchen Lead |
| DEC-008 | Asset Scout, Media Coach, Prep Cook, Service Cook, Sous Chef, and other presentation roles remain dormant until the Godot UI stage. | Approved | Human and GDD |
| DEC-009 | Use a deterministic UI-independent domain core, application commands/domain events, stable content IDs, and ports/adapters as the proposed technical foundation. | **Superseded** by [ADR 0002](../adr/0002-phase-1-structural-foundation.md) | [[technical_architecture\|Technical Architecture]] |
| DEC-010 | Use typed custom `.tres` Resources as canonical game-content definitions from Phase 1 onward. | Approved | Human |
| DEC-011 | Do not use a project-wide ECS; allow a bounded ECS subsystem only when measured needs justify it and an ADR approves it. | Approved | Human |
| DEC-012 | Give coding agents a short root `AGENTS.md`; keep rationale in `docs/technical_architecture.md` and architectural decisions in `docs/adr/`. | Approved | Human |
| DEC-013 | Bootstrap static typing, Godot warnings, `gdformat`, `gdlint`, headless import, and project tests as the code-quality gate. | Approved | Human |
| DEC-014 | Use private GitHub Issues and the Neon Kitchen Development Project as the system of record for executable work; keep design authority and durable decision memory in the GDD, accepted ADRs, and Kitchen Lead Worklog. | Approved | Human |
| DEC-015 | Pin Godot 4.7.1 stable standard (non-.NET); develop on macOS arm64; support macOS arm64 and Windows x86_64 exports; accept 4.7.x patches but require a superseding ADR for a new minor. | Approved | Human and [ADR 0001](../adr/0001-pin-godot-version.md) |
| DEC-016 | Ratify a narrowed Phase 1 structural foundation: interface independence and inward dependency direction; the full command/event vocabulary with cooking-challenge terms reserved but undefined; no randomness or wall-clock time in the domain; three ports (`ContentRepository` built, `RandomPort` and `CookingChallengePort` declared); a minimal repository layout; and six Godot-specific correctness rules. Supersedes DEC-009. | Approved | Human and [ADR 0002](../adr/0002-phase-1-structural-foundation.md) |
| DEC-017 | Lock the Phase 1 evaluator contract: normalised weighted distance to per-dimension targets with integer arithmetic; weight 0 means the dimension is ignored; four hard constraint kinds capping at 39; deterministic feedback selection; five commands and eight events with typed fields; rejected commands emit no events; three ingredients and two customers as contract fixtures. | Approved | Human and [ADR 0004](../adr/0004-phase-1-contracts.md) |
| DEC-018 | Use the repository `docs/` directory as the canonical, version-controlled Obsidian vault for game design, architecture, agent definitions, and durable project memory. | Approved | Human |
| DEC-019 | Activate the task-scoped Systems Cook via [[Systems Cook]], with a propose-and-stop loop, mandatory red-path proof, an adversarial pass aimed at unchecked claims, and Kitchen Lead `/code-review` before acceptance. Run specialists on Sonnet. Commit subjects ≤72 characters and bodies ≤15 lines, with detail on the issue per DEC-014. | Approved | Human |
| DEC-020 | Ratify the Phase 1 agent team in [[Phase 1 Agent Team]]: one persistent coordinator and four task-scoped specialists, centralised task allocation, file- and issue-mediated message passing, and no peer-to-peer specialist channel. Narrow **Health Inspector** to content only — its former general-verification scope overlapped the Systems Cook's mandatory red-path proof, and two jobs had come to share one name. Promote **Pantry Keeper** from dormant to active, since the content crew activated it; Ingredient Designer and Customer Designer stay dormant rather than splitting a role not yet proven too large. Make Systems Cook executable as `.claude/agents/systems-cook.md`, with its packet stating `PROPOSE` or `IMPLEMENT` because the propose-and-stop hard stop terminates the process rather than pausing it. **Amended after the first dispatch (#19):** the coordinator must post the specialist's returned proposal on the issue, since for a propose-and-stop role that proposal is the implement dispatch's specification and otherwise exists only in a session transcript; and a reverted throwaway spike is explicitly permitted during `PROPOSE`, provided the tree is left clean and the spike is reported. | Approved | Human |
| DEC-021 | Make a violated constraint identifiable by carrying a **value copy** of it in `Evaluation` — `kind`, `subject`, and `explanation_key` — replacing `violated_constraint_ids: Array[StringName]`, which carried only `subject` and could not distinguish `REQUIRE_INGREDIENT(soy)` from `FORBID_TAG(soy)` when both fired. A copy rather than a reference, because content Resources are shared and immutable at runtime (AGENTS.md rule 7), following the same reasoning as `per_dimension`. `ContentValidator` additionally rejects two constraints sharing a `subject` on the same side of the identity/tag divide, which makes `subject` plus `kind` unique per customer by construction and avoids inventing an authored constraint id. Amends [ADR 0004](../adr/0004-phase-1-contracts.md) §5 and §9. | Approved | Human |
| DEC-022 | Close two contract gaps found while decomposing #5, both present since the original ADR 0004. Define **five session phases** — `NOT_STARTED`, `AWAITING_CUSTOMER`, `BUILDING_DISH`, `SHOWING_RESULT`, `ENDED` — giving `INVALID_PHASE` (§10) an actual contract; `SHOWING_RESULT` is kept distinct from `AWAITING_CUSTOMER` despite accepting the same command, because they differ in what a presenter should render and a later Godot UI needs a state to hold feedback in. `SessionEnded` fires on the command that exhausts the roster, not spontaneously after the last submit. Define **`EncounterResult`** as `customer_id`, `ingredient_ids`, `score`, `band`, `constraint_satisfied` — a value copy carrying the dish as served, so the first playtest can discuss a specific encounter; `per_dimension` and `violated_constraints` are deliberately omitted since `DishEvaluated` already carried them. Adds [ADR 0004](../adr/0004-phase-1-contracts.md) §7a and defines `EncounterResult` in §8. | Approved | Human |
| DEC-023 | Close five more gaps found while preparing #23, all present since the original ADR 0004. **Map each command to the events it emits**, in §7a's table — previously derivable but unwritten, which left `SubmitDish`, the one command emitting three events, with no specified order; it is `DishSubmitted`, `DishEvaluated`, `CustomerReacted`, ordered by causality. **`sequence` starts at 1 and increments per event**, not per command, so a numbering gap means a lost event rather than a rejected command. **`CustomerPresented.index` is 0-based** into the `StartSession` roster. **The dish clears on `PresentCustomer`, not on `SubmitDish`**, so `SHOWING_RESULT` can still display what was served. **`StartSession` rejects an unknown customer id (`UNKNOWN_CUSTOMER`) and an empty roster (`EMPTY_ROSTER`)**, since its roster comes from the caller and `ContentValidator` never sees it; a *repeated* customer id stays legal, deliberately unlike DEC-021's duplicate constraints, because two visits are two encounters rather than one boundary written twice. Amends §7a and §10. **Corrected 2026-08-06:** `EMPTY_ROSTER` makes `AWAITING_CUSTOMER → ENDED` unreachable, since a successful `StartSession` always leaves a customer to present, so §7a's table described a transition no session can perform; only `SHOWING_RESULT` reaches `ENDED`. Also clarified that §8a's resolver produces `<prefix>.<band>` unconditionally in Phase 1 — "most specific *available*" needs a `LocalizationPort` that does not exist, and the other two tiers must not be written as unreachable branches. Both found by a Systems Cook at propose-and-stop. | Approved | Human |
| DEC-024 | Treat an incomplete specification as the expected condition rather than an exception, and say so in every agent definition. ADR 0004 was corrected six times in Phase 1, every time at propose-and-stop and every time before code existed; **five of the six originated in decisions the coordinator wrote**, because the coordinator is who writes contracts. Two came from decisions made a day apart that were each correct alone. Record the five recurring shapes in [[Phase 1 Agent Team]] — referenced but never defined; derivable but unwritten; individually correct but jointly contradictory; assumes machinery that does not exist; a principle illustrated too narrowly — and have every agent read for them. A specialist returning a contradiction instead of code has done the job, not stalled. None of these were bugs and no test could have caught any of them, which is why the propose step sits alongside the gate rather than duplicating it. | Approved | Human |
| DEC-025 | Exclude a weighted dimension whose target **and** actual value are both 0 from feedback selection entirely — neither strongest match nor largest miss. Such a dimension has penalty 0 and so won strongest match outright: the first hands-on session of the terminal runner reported `Strongest match: Spicy` in every encounter, including a spice-free dish served to a customer who asked for "a little kick". Nothing was miscomputed; zero penalty *is* a perfect match. But it reads as praise for a flavour that was never there, and §12's advance gate turns on a tester explaining a result in ingredient and customer terms. Absence of an unwanted flavour is a boundary respected, not a flavour matched. **Feedback only** — these fields never enter the score, so no score, band, or balance changes. Found by playing the game; no automated check could have caught it. Amends [ADR 0004](../adr/0004-phase-1-contracts.md) §6. | Approved | Human |
| DEC-026 | Ratify [[Content Voice]] as the standard for ingredient descriptions, customer requests, and reaction lines, from the human's reading of the first four shipped ingredients. Five rules: describe the thing rather than its role; never name a flavour dimension, since those are the evaluator's words and saying an ingredient is "comforting" reads the number aloud; never make a claim relative to the rest of the pantry, because #24 triples it and any comparative claim silently becomes false with no check able to catch it; do not restate a constraint in a description, since the constraint carries its own explanation and the inference is the mechanic; and ration the emotional register, because if every customer arrives exhausted none of them reads as exhausted. Binds #24 and every later content run. The human owns tone and canon; this records a decision rather than delegating one. | Approved | Human |
| DEC-027 | Treat GDD §2.2's worked example as **illustrative prose, not a specification**. The document narrates a night courier served noodles, mushrooms and chili crisp and reaching Satisfied; with the shipped twelve-ingredient pantry that dish composes to `[5,2,0,4,0]` and scores 66. Three numbers exist for it — the GDD's narrated 78, ADR 0004's contract vector of 81, and 66 from the ingredients as authored — and they answer different questions: the vector pins the §3 formula against a synthetic profile, while the narration sketches an encounter. Shipped customers are authored on their own merits and on the flavour space, not reverse-engineered to reproduce a passage. **Ingredient values must not be adjusted to make the narration land**, which would rebalance a pantry cleared across 298 dishes in order to fit a paragraph. | Approved | Human |
| DEC-028 | Break the two feedback tie-breaks in **opposite directions** — strongest match toward the higher weight, largest miss toward the lower — and drop the strongest match whenever both selections still name the same dimension. Closes #29, found by playing: `old_local` served noodles and smoked fish reported `Strongest match: Savory` directly above `Largest miss: Savory`. Enumerating all 2384 dish-customer pairs found 141 collisions, only 40 of them the single-candidate shape DEC-025 creates; the other 101 were ordinary penalty ties, and those exposed the real error. Penalty is `weight * error`, so dimensions tied on penalty with different weights have inversely different raw errors and the heavier one is *closer* to target — breaking the miss toward higher weight was naming the dimension nearest its target the largest miss. The flip also corrected 8 pairs that were never collisions. Feedback only: score and band dumped across all 2384 pairs before and after are byte-identical. | Approved | Human |
| DEC-029 | Give every ingredient an authored `group` — `staple`, `broth_and_fat`, `heat_and_ferment`, `fresh_and_cured` — and print the pantry under headings in that order, as **navigation only**. Closes #28. The issue asked for grouping so the pantry would hint whether ingredients mix well; enumerating all 220 three-ingredient dishes against the eight customers disproved the premise. One-from-each-group is worth 1.9 points of mean score (49.3 vs 47.4) and costs up to 30 points of reachable best: six of eight customers are served best by a dish concentrating in one group, and `office_worker` and `late_shift_medic` cannot reach DELIGHTED under the heuristic at all. A customer wanting Fresh 5 and Adventurous 4 is answered by three fresh things, which a slot rule forbids. So the groups make twelve ingredients scannable and claim nothing about composition; no content may imply otherwise. An empty or unknown group is rejected at load, since Godot writes an unset export and a deliberately-empty one as identical bytes. | Approved | Human |
| DEC-030 | Advance to the Phase 2 Godot UI with ADR 0004 §12's advance gate (points 2, 3, 4) **unrecorded rather than passed**, and move that gate to the Phase 2 playtest. Run 01 answered point 5 positively and unprompted -- a second player asked for more ingredients and customers -- and produced sixteen sensible dishes across two players with all sixteen scores reproducing exactly through the evaluator. Points 2-4 ask whether a player can explain a result from what the screen tells them, and the terminal is the weakest screen the project will ever ship; a UI showing request, pantry and dish together may settle those questions rather than answer them. GDD §3 already sets a higher bar for the Godot playtests (four of five testers explaining a result, four proposing two plausible dishes), so the gate is not lowered by moving. Run 01 is the terminal baseline. Two content findings stay open regardless: the tenfold difficulty spread between office_worker and scrap_trader, and block_boss and night_courier having no dish that reaches 100. | Approved | Human |
| DEC-031 | Create `shared/` with `EncounterText` and have **both** adapters delegate to it for band labels, dimension labels, rejection wording, ingredient names and the summary line. ADR 0002 §6 already listed `shared/` among the deferred folders created "when their first real file exists"; this is that file, so no amendment. Prompted by finding that `adapters/terminal` and `adapters/godot_ui` had independently grown copies of the same three strings within a day of the second adapter existing, and had already diverged twice in ways no test could see because each adapter only ever compared against itself: the terminal labels an unrecognised band `Unknown` where the UI copy fell through to `Dissatisfied`, reporting a real band for an unreadable one, and the terminal capitalises a dimension where the UI printed the raw lowercase identifier. Neither was a typo; both are what happens when the same sentence is written twice from memory. Proven real rather than cosmetic: changing a string in `shared/` fails a **terminal** test. | Approved | Human |
| DEC-032 | Activate the **Service Cook**, the interface specialist GDD §4.1 names and `.claude/agents/` lacked. Amends DEC-020, which ratified the Phase 1 team as one coordinator plus four specialists. Grants `Read, Grep, Glob, Bash, Write, Edit` — the same set as the Systems Cook. `Bash` because this project accepts no claim it has not seen fail, and an agent that cannot run the gate cannot prove its own work; `Write`/`Edit` because #36 needs a `Theme` resource authored. **The content boundary is prose and gate, not tool grant**, and that is weaker than the Pantry Keeper's, which has no `Bash` and therefore *cannot* compute a score however it is asked: `Write` is path-agnostic, so "may not touch `content/`" is enforced by review and by `check.sh`, not by capability. Recorded rather than hidden. Inherits DEC-019's propose-and-stop and DEC-024's expect-the-spec-to-be-wrong. The Systems Cook is its complement, not its substitute — UI-independent GDScript versus scenes and Control nodes — so a task needing both was decomposed wrongly. | Approved | Human |
| DEC-033 | Ratify [[Visual Language]] as the palette and the rules governing its use, chosen from five candidates rendered in the real screen layout with real content. *Solarpunk, tempered*: `#12140F` grounds, `#1E2219` surfaces, `#EDE8D9` text, sodium `#C08A47`, sage `#9DB4A0`. Tokens are named by **role** — a token named for its appearance must be renamed to be re-skinned, and Week 5 re-skins. Four rules: colour is never the only carrier of meaning; surfaces are overlays with a contrast floor rather than opaque fills, since a panel that reads on a flat token need not read on a painted background and all of them would need rework at once; the food is the most saturated thing on screen, which is the entire difference from the untempered variant this was chosen over; and disabled means unreadable-*looking*, not unreadable. That last rule came from measuring rather than assuming — the original `disabled` value gave **1.38:1** against surface, so an excluded ingredient would have been an unreadable smudge, and a player must be able to see that Smoked Fish *exists and is excluded* for the constraint mechanic to teach anything. Split into `disabled_surface` and `disabled_text` at 3.27:1. All six contrast pairs computed and recorded. | Approved | Human |
| DEC-034 | License `assets/` in ADR 0002 §6 for **authored presentation resources** — themes, fonts, sprites — and require themes to be **plural by construction**. Not `content/`: content is game data, validated at load and governed by ADR 0004, and a Theme that failed to load would not make a customer invalid. The test is whether changing it can change a score, a constraint, or what a customer says. `assets/themes/` holds one resource per palette, named for the palette and never for the game, with exactly one place naming the active one, so trying a different theme is a path change rather than a rewrite — the palette is provisional and expected to be re-tried against real art. [[Visual Language]] is split accordingly: its four rules bind every theme including unwritten ones, while its palette table describes only the active theme. The amendment also **trims the deferred-folder list to what is still deferred** — `shared/`, `adapters/godot_ui/`, `content/base/localization/`, `tests/{smoke,golden}/` and `core/domain/value_objects/` had all been built while remaining listed as pending, which is precisely how a folder came to be reported as licensed-absent while sitting in the tree. Audio is deliberately absent: GDD §5.1 defers a soundtrack and the shipping list names no audio. | Approved | Human |
| DEC-035 | Amend the GDD's Art Direction section (v7) to separate **information priorities**, which bind, from **layout**, which does not. The section previously named five panels for the Godot build — customer request, ingredient choices, proposed dish, Serve, feedback — which is the terminal's own information architecture restated. Read as a design it produces exactly one screen, and that screen was built four times across #32, #34, #36 and the #37 plan before the document rather than the implementation was identified as the thing repeating itself. The five panels are kept as a **superseded example** rather than deleted, so the history of the mistake survives its correction. Names the question the section never asked: not which panels, but where the player is standing. Nothing about what information must reach the player changed — constraints stay visible before choosing (§2.3), descriptions stay available throughout (§2.4). Establishes that the GDD is amended when it is wrong rather than worked around, which is the first time a governing document has been corrected for prescribing an implementation instead of a requirement. | Approved | Human |
| DEC-036 | Activate the **Stagiaire** and add it to the GDD's §4.1 specialist pool (v8). The roster had no design-research role — the Asset Scout is production sourcing, finding usable images under licence, size and format constraints, and pointing it at a structural question would use it outside its charter the same way handing the Systems Cook a scene task would. Scoped to **analysing references the human has already gathered**, never to finding its own, because choosing what is worth studying is a taste judgement and the human moved to references-first precisely because that instinct beats anything generated cold. **The boundary is enforced by absent tool grants** — no web access, no shell — which makes it stronger than the Service Cook's content boundary, where `Write` is path-agnostic and the rule is prose plus review. Two rules carry the risk: never assert from memory about a game, since a confident description of a screen nobody can check is indistinguishable from a real observation until someone plays it; and keep observation separate from interpretation, the same discipline ADR 0004 §12's playtest protocol already requires. | Approved | Human |
| DEC-037 | Adopt **one continuous food-truck workspace** as the Phase 3 screen framing, from the human's own reference research ([[frame-notes-and-greybox-brief]], [[godot-greybox-ideas]]). `ServiceWindow` and `Worktop` are physical regions of a single scene, not two screens: the customer and a slice of the city stay visible while the worktop takes focus. The spoken request **condenses into a persistent ticket** — load-bearing rather than decorative, since the longest shipped request is `old_local` at 319 characters, nearly three times the longest ingredient description, and Good Pizza's failure mode is a large speech bubble being the only durable record of a nuanced request. Emphasis shift is presentation-only: `BUILDING_DISH`, `SHOWING_RESULT` and `ENDED` already describe the visual states, and the request-to-ticket moment is a substate within `BUILDING_DISH`, **not a new domain phase**, so ADR 0004 §7a is untouched. The greybox is built as a new scene calling the existing `KitchenSession` seam rather than replacing `kitchen_screen.gd`, which stays as a working control until the experiment earns its place. Supersedes the four framings I proposed cold; derived from references rather than invented. | Approved | Human |
| DEC-038 | **Supersede DEC-037's continuous workspace with two phased views.** The first greybox built DEC-037 faithfully and reproduced the thing it was meant to escape: an `HBoxContainer` with two `EXPAND_FILL` children is the column split by another name, and the human's report was that it "looks like the other kitchen_screen runner almost." It was discarded rather than iterated (`c3cddb4`), because iterating would have kept the split as the starting point. The brief was also **self-contradictory** — it required "one continuous workspace, not separate screens" while the human's own frame note said the flow "should transition from customer request to preparation" — so the implementation could not have satisfied both. Rewritten as a **request view and a preparation view**, one active at a time inside the same truck. Continuity now comes from the ticket carrying the request across the cut, not from both regions sharing the frame, which makes the ticket load-bearing instead of a convenience. The five-second recall test is **split per view**: a combined recall is unpassable by construction under two views and would have reported the design working as a defect. | Approved | Human |
| DEC-039 | Source final art from **licensed asset packs**. Chosen over generated art, shape-and-type only, and hand-drawn, with the patchwork risk stated before the choice and accepted. The mitigation is a *sourcing rule*, not a hope: prefer one pack covering most of the twelve ingredients over several packs each covering a few, because a consistent style with gaps reads better than a complete set in four styles. Shape-and-type stays available as the per-item fallback for anything unfound, which is what keeps the risk bounded — no ingredient can block the build for want of a picture. This is the first answer to "where does art come from at all"; the Asset Scout in GDD §4.1 has a charter but has never been activated, and DEC-034's `assets/` licence already anticipates this by requiring themes to be plural so a palette can be re-tried against real art. | Approved | Human |
| DEC-040 | **Move the art pipeline and the visual polish pass from Week 5 into Week 4** (GDD v9), and add **a locked screen design** to Week 3. Week 5's "final assets" was the schedule's largest exposure: sourcing is lead time rather than effort, so it is the one item that cannot be absorbed by working faster. The lock is what makes the reshuffle safe rather than merely earlier — polishing an interface that is still being decided is the failure already named in `dont-polish-what-is-about-to-be-replaced`, and moving polish up without locking first would repeat it a week sooner. The five observed playtests stay in Week 4 and are unaffected: they are calendar time waiting on people, so they run alongside sourcing rather than competing with it. Week 5 becomes release work only — export, remaining assets, test report, final GDD, presentation. | Approved | Human |
| DEC-041 | Define **central ingredient** as the ingredient in a dish with the largest `sum(customer weight × ingredient value)` across the flavour dimensions, ties to the lowest `content_id`. GDD §2.4 requires "at least two [satisfying combinations] that do not depend on the same central ingredient" and §5.5 repeats it as the illusory-choice mitigation, but the term is never defined, so **half of the GDD's headline balance guarantee had never been checkable** — it was quoted in three places and enforced in none. The definition is deliberately **customer-relative**: an ingredient can carry a dish for one customer and be incidental to it for another, and a pantry-global notion of centrality would answer a different question than the rule asks. Recorded in the generated report rather than only in code, so a reader can disagree with the definition without reading GDScript. Provisional: it is the first definition proposed, not one chosen from alternatives, and the shipped roster passes the rule by a wide margin under it — which means the definition has not yet been stress-tested by a near-miss. | Proposed | Kitchen Lead |
| DEC-042 | **A ticket condenses what the customer said; it never translates what they meant.** Content Voice rule 7. My first draft rendered `solar_tech`'s *"I want to feel human again"* as `deeply comforting` — mechanically faithful, since comfort 5 at weight 3 is their dominant want, and wrong, because **working out that the feeling means comfort is the puzzle**. A ticket that does the translation simplifies the game rather than serving it. The line stays *"Wants to feel human again."* The rule has a mechanical test: every quality word on a ticket should already appear in that customer's own request. Seven of eight shipped tickets passed it on the first draft and only `solar_tech` failed, which is what makes the rule look correct rather than invented to justify one edit. The corollary is accepted rather than worked around: `late_shift_medic` carries a spice dislike they never speak, so no honest ticket can warn about it — the human's answer is a **repeat-customer mechanic** where such quirks are discovered, not a ticket that leaks them. Also settled: ticket order is **want first, avoid second**, held constant across all eight even where it puts a customer's heaviest weight second (`old_local`'s adventurous 0 at weight 3), because a consistent shape a player learns to read beats per-customer optimisation. | Approved | Human |

### Phase 1 Scope

**In scope:**

- ingredient and customer data schemas;
- UI-independent GDScript data loading;
- deterministic recipe evaluation;
- customer constraints;
- rating and feedback output;
- a terminal or headless runner;
- automated rule, data, and golden-case tests;
- a small initial data set followed by expansion only when justified;
- human evaluation of clarity and curiosity.

**Out of scope:**

- Godot UI scenes and visual polish;
- asset research and preparation;
- inventory depletion;
- economy and profit;
- cooking techniques and heat timing;
- persistent progression;
- high-volume lore or narrative production.

### Minimal Shared State

The dormant Worldkeeper and Pantry Keeper roles still need future-compatible artifacts:

- a short setting-and-tone statement;
- an authoritative ingredient schema;
- an authoritative ingredient registry;
- customer and constraint schemas;
- flavor-dimension definitions;
- golden recipe-evaluation cases;
- a record of approved design decisions.

Kitchen Lead maintains these artifacts during Phase 1 without pretending to be a full lore or culinary-content specialist.

### Active Risks

| Risk | Current response |
|---|---|
| Phase 1 grows into UI production too early | Keep the first milestone headless and require a rules gate before UI work. |
| Terminal and UI behavior diverge later | Keep rules outside interfaces and preserve golden parity cases. |
| Persistent-agent overhead exceeds project complexity | Keep only Kitchen Lead active; instantiate all other roles per task. |
| Ingredient rules become inconsistent before Pantry Keeper activation | Use one authoritative schema and registry from the beginning. |
| Thin lore becomes contradictory before Worldkeeper activation | Preserve a minimal tone and setting statement; defer broad worldbuilding. |
| Automated correctness is mistaken for fun | Require human playtesting before advancing the design. |
| Long-term flexibility turns Phase 1 into speculative infrastructure | Build only stable IDs, typed commands/events, deterministic rules, a content repository, and golden tests; defer unused adapters. |
| A future presentation or networking concern leaks into recipe rules | Keep engine nodes, translated text, scene paths, RPCs, and spatial coordinates outside the domain core. |
| ~~GDScript Toolkit lags the pinned engine release~~ | **Resolved 2026-08-01 in #2.** gdtoolkit 4.5.0 parses `@abstract`, typed dictionaries, `static var`, StringName literals, and `@warning_ignore`; its formatted output is accepted by Godot 4.7.1 and is idempotent. Pinned in `requirements-dev.txt`. |
| ~~Binding architecture rules are unenforced~~ | **Largely resolved 2026-08-01 in #16.** The gate now enforces dependency direction, domain purity, layout, and `.uid` sidecars, each verified in the failing direction. Rules 2, 3, 5–8 and 12 remain review-only; `AGENTS.md` states which is which so the distinction is visible rather than assumed. |
| Export has never been produced on any platform | ADR 0001's platform matrix is an intent for the release milestone, not a verified capability. No export templates, no `export_presets.cfg`, no export attempted. macOS notarisation cost is unknown. Needs an issue when a release milestone exists; discovering this in week 5 would be expensive. |
| A second implementation of the scoring contract now lives in the repo | `tools/flavor_explorer.html` models ADR 0004 and will be the *third* implementation once #9 lands. `tools/verify_flavor_model.sh` compares it against an ADR-derived oracle over 7,476 cases and is verified to fail on drift. **After #9 the oracle must be replaced by the real evaluator**, or the check only proves two models agree with each other. |
| Godot's own commands cannot be trusted as CI gates | `--import` exits 0 and reports nothing on script type or warning violations; `--check-only` reports them but also exits 0. `scripts/check.sh` inspects output instead of exit codes. Never substitute the raw commands for the gate. |
| GitHub tasks and durable design memory drift apart | Keep executable scope and status in GitHub; update the worklog only when a decision, milestone, risk, or durable context changes. |
| The repository and former Obsidian vault become competing sources of truth | Treat repository `docs/` as canonical after migration verification; keep only a pointer or archive in the former vault. |

### Open Questions

None. Every question opened during design has a recorded resolution below.
New questions are added here as they arise.

### Resolved Questions

| ID | Question | Resolution |
|---|---|---|
| Q-001 | What is the exact smallest Phase 1 data set? | Three ingredients, two customers, as evaluator **contract fixtures** rather than a playable slice. [ADR 0004](../adr/0004-phase-1-contracts.md) §11. 2026-08-01 |
| Q-002 | Which headless Godot testing approach will be used? | GUT v9.7.1, fetched by `scripts/setup.sh`. [ADR 0003](../adr/0003-test-framework.md). 2026-08-01 |
| Q-003 | What exact flavor-score formula and feedback rules are locked? | Normalised weighted distance to per-dimension targets, integer arithmetic, single truncation. [ADR 0004](../adr/0004-phase-1-contracts.md) §3 and §6. 2026-08-01 |
| Q-004 | Will the proposed repository structure be approved as the bootstrap structure? | Partly. [ADR 0002](../adr/0002-phase-1-structural-foundation.md) §6 ratifies a reduced Phase 1 layout; §6 of the architecture document remains the target shape. 2026-07-31 |
| Q-005 | Which observations define success for the first internal human playtest? | Five per-encounter observations; points 2–4 are the GDD's advance gate, point 5 is the design question. [ADR 0004](../adr/0004-phase-1-contracts.md) §12. 2026-08-01 |
| Q-006 | Which exact Godot 4.x version and desktop export targets will be pinned? | DEC-015 / [ADR 0001](../adr/0001-pin-godot-version.md), 2026-07-31 |
| Q-007 | Which remaining architectural proposal items should be promoted to approved decisions? | DEC-016 / [ADR 0002](../adr/0002-phase-1-structural-foundation.md), which supersedes DEC-009. 2026-07-31 |

### Next Actions

1. [#3 — Implement typed Resource definitions and validation](https://github.com/rkhanna24/NeonKitchen-godot/issues/3),
   against the schemas in ADR 0004.
2. [#8 — Author the minimal fixtures](https://github.com/rkhanna24/NeonKitchen-godot/issues/8):
   three ingredients, two customers, exercising all four bands and a hard
   violation.
3. [#9 — Implement the deterministic evaluator](https://github.com/rkhanna24/NeonKitchen-godot/issues/9)
   to ADR 0004 §3 and §6.
4. [#6 — Golden and contract coverage](https://github.com/rkhanna24/NeonKitchen-godot/issues/6),
   enumerating all seven fixture dishes.
5. Activate task-scoped specialists only after their issues are Ready.

## Canonical Artifact Index

| Artifact | Purpose | Status |
|---|---|---|
| [[Neon Kitchen - Game Design Document]] | Authoritative game design and MAS architecture | Active |
| [[Kitchen Lead]] | Stable Kitchen Lead operating definition | Active |
| [[Systems Cook]] | Task-scoped GDScript implementation role | Active |
| [[Phase 1 Agent Team]] | The team as a system: role contracts, coordination protocol, status transitions, and role-to-backlog mapping | Active |
| `.claude/agents/` | Executable agent definitions; frontmatter tool grants are the enforcement | Active |
| [[Kitchen Lead Worklog]] | Current state, decisions, evidence, and handoffs | Active |
| [[technical_architecture\|Technical Architecture]] | Proposed modular architecture, extension seams, and GDScript/C# standards | Proposed v0.2 |
| [[Home]] | Repository documentation-vault entry point | Active |
| `AGENTS.md` | Short operational contract for coding agents | Active |
| `docs/adr/` | Durable architecture decision records | Active |
| [ADR 0001](../adr/0001-pin-godot-version.md) | Pinned Godot 4.7.1 build, platform matrix, and upgrade policy | Accepted |
| [ADR 0002](../adr/0002-phase-1-structural-foundation.md) | Narrowed Phase 1 structural foundation; supersedes DEC-009 | Accepted |
| [ADR 0003](../adr/0003-test-framework.md) | GUT v9.7.1 as the headless test framework, fetched not vendored | Accepted |
| [ADR 0004](../adr/0004-phase-1-contracts.md) | Commands, events, evaluator, fixtures, and playtest protocol | Accepted |
| [NeonKitchen-godot](https://github.com/rkhanna24/NeonKitchen-godot) | Private implementation repository and issue tracker | Active |
| [Neon Kitchen Development](https://github.com/users/rkhanna24/projects/1) | Managed status, priority, dependency, phase, and area tracking | Active |
| [Phase 1 — Recipe Rules Prototype](https://github.com/rkhanna24/NeonKitchen-godot/milestone/1) | Current implementation milestone | Active |
| Lore Bible | Setting and canon source | Deferred; minimal statement needed |
| Ingredient Registry | Authoritative ingredient data and tags | Not yet created |
| Customer Registry | Authoritative customer requests and constraints | Not yet created |
| Decision Log | Durable design decisions | Currently maintained in this worklog |

## Task-Agent History

| Task ID | Role | Goal | Result | Status | Artifacts |
|---|---|---|---|---|---|
| — | — | No task-scoped agent has been activated yet. | — | — | — |

## Decision Records

### DEC-001

- **Status:** Approved
- **Decision:** Deliver an exported Godot 4.x desktop game with a functional player-facing UI as the capstone.
- **Reason:** The terminal prototype is a validation tool, not the desired final player experience.
- **Player-facing effect:** The submitted game presents recipe composition through a usable visual interface.
- **Consequences:** Phase 1 architecture must migrate into Godot without rewriting its rules.
- **Supersedes:** Any framing of the terminal prototype as the capstone deliverable.
- **Authority:** Human
- **Date:** 2026-07-30

### DEC-002

- **Status:** Approved
- **Decision:** Use a primitive headless GDScript prototype for Phase 1.
- **Reason:** Validate the central recipe puzzle before investing in UI and media.
- **Player-facing effect:** No direct final-player effect; it protects the later UI game from being built on an unproven loop.
- **Consequences:** Data loading and evaluation must remain independent of interface code.
- **Supersedes:** A Python-only terminal implementation or immediate full UI production.
- **Authority:** Human
- **Date:** 2026-07-30

### DEC-004

- **Status:** Approved
- **Decision:** Use Kitchen Lead as the only persistent active agent during Phase 1.
- **Reason:** The phase is too small to justify multiple long-lived coordinators and stewards.
- **Player-facing effect:** Development decisions remain coherent without spending the schedule on agent coordination.
- **Consequences:** Kitchen Lead temporarily maintains minimal lore and ingredient state; specialists are task-scoped.
- **Supersedes:** Activating Worldkeeper, Pantry Keeper, and Expeditor for every Phase 1 task.
- **Authority:** Human
- **Date:** 2026-07-30

### DEC-009

- **Status:** Superseded by [ADR 0002](../adr/0002-phase-1-structural-foundation.md) and DEC-016 on 2026-07-31
- **Superseded because:** it remained Proposed while `AGENTS.md` presented its
  content as non-negotiable, and its scope exceeded what Phase 1 needs. ADR 0002
  accepts a narrowed form: it keeps interface independence, dependency direction,
  commands/events, and stable IDs; replaces "inject randomness" with a stricter
  ban on randomness and wall-clock time in the domain; and limits ports to three.
- **Decision:** Use a deterministic UI-independent domain core, explicit application commands and domain events, stable versioned content IDs, and ports/adapters as the technical foundation.
- **Reason:** These seams let new content remain data-driven and let terminal, Godot UI, minigame, localization, networking, persistence, and visual presentation implementations evolve without owning recipe policy.
- **Player-facing effect:** The same recipe behavior can survive richer interfaces and future modes while additions remain less likely to destabilize unrelated play.
- **Consequences:** Phase 1 must type its boundaries, inject randomness, validate content, and preserve golden cases. It must not build every deferred adapter.
- **Authority:** Kitchen Lead recommendation pending human review
- **Evidence:** Official Godot guidance on scene organization, Resources, static typing, Autoload scope, localization, high-level multiplayer, and GDScript/C# conventions.
- **Date:** 2026-07-30

### DEC-010

- **Status:** Approved
- **Decision:** Use typed custom `.tres` Resources as the canonical format for ingredient, customer, recipe-pattern, level, challenge, and presentation definitions from Phase 1 onward.
- **Reason:** Phase 1 now runs inside Godot, so Resources provide typed data, Inspector authoring, built-in loading/export, and text-based version control without an interim JSON migration.
- **Consequences:** Resources retain stable `content_id` values and are validated before domain use. JSON remains available for saves, replays, networking, and external interchange.
- **Authority:** Human
- **Date:** 2026-07-30

### DEC-011

- **Status:** Approved
- **Decision:** Do not use a project-wide Entity Component System.
- **Reason:** Godot’s node/scene composition and the proposed domain/application boundaries fit the current game; ECS complexity is not justified by a measured high-entity simulation requirement.
- **Consequences:** A future bounded subsystem may use ECS behind a port only after profiling and an accepted ADR.
- **Authority:** Human
- **Date:** 2026-07-30

### DEC-012

- **Status:** Approved
- **Decision:** Use root `AGENTS.md` as the short coding-agent contract, `docs/technical_architecture.md` as the long-form rationale, and `docs/adr/` for material architecture decisions.
- **Reason:** Coding agents need a concise enforceable guide without repeatedly loading the full architecture history.
- **Consequences:** `AGENTS.md` contains invariants, style, checks, and completion rules; the long document is linked rather than duplicated.
- **Authority:** Human
- **Date:** 2026-07-30

### DEC-013

- **Status:** Approved
- **Decision:** Bootstrap GDScript static typing and warnings, pinned `gdformat`/`gdlint`, Godot headless import, content validation, and automated tests as project quality gates.
- **Reason:** Formatting, style, type-safety, Resource loading, and rule correctness should be checked consistently for human and agent-authored code.
- **Consequences:** Exact commands and pinned versions must be added when the Godot version and test harness are selected.
- **Authority:** Human
- **Date:** 2026-07-30

### DEC-014

- **Status:** Approved
- **Decision:** Use private GitHub Issues and the Neon Kitchen Development
  Project as the system of record for executable work, including scope,
  acceptance criteria, status, priority, size, phase, area, dependencies, and
  implementation evidence.
- **Reason:** Managed task tracking makes sequencing, ownership, blockers, and
  completion visible without turning the Kitchen Lead Worklog into a duplicate
  backlog.
- **Player-facing effect:** No direct effect; clearer coordination reduces
  implementation drift and helps the team reach a coherent playable prototype.
- **Consequences:** The GDD and accepted ADRs remain authoritative for design
  and architecture. The Kitchen Lead Worklog preserves approved decisions,
  rationale, risks, milestone state, and durable context. Specialists receive
  one Ready issue at a time and issues move through Inbox, Ready, In progress,
  Verification, Blocked, and Done.
- **Authority:** Human
- **Date:** 2026-07-30

### DEC-018

- **Status:** Approved
- **Note:** Originally recorded as DEC-015. Renumbered on 2026-08-01 after the
  Godot version pin reused that identifier, creating a duplicate in this log.
  This record was renumbered rather than the pin because nothing referenced it,
  whereas the pin is cited by ADR 0001, ADR 0002, and Q-006.
- **Decision:** Use the `docs/` directory in `NeonKitchen-godot` as the
  canonical, version-controlled Obsidian vault for the GDD, technical
  architecture, ADRs, agent definitions, and Kitchen Lead durable memory.
- **Reason:** Repository-scoped agents need direct access to the context and
  decisions governing their work, and the human should be able to navigate the
  same documents as one Obsidian knowledge base.
- **Player-facing effect:** No direct effect; shared context reduces design and
  implementation drift.
- **Consequences:** Root `AGENTS.md` remains outside the vault so coding agents
  discover it automatically. GitHub Issues and the Project remain the
  executable-work system. The former standalone Neon Kitchen vault is no longer
  canonical after migration verification and should retain only a pointer or
  archive.
- **Authority:** Human
- **Date:** 2026-07-31

### DEC-015

- **Status:** Approved
- **Decision:** Pin Godot 4.7.1 stable standard (non-.NET) as the engine for
  Phase 1 and the capstone. Develop on macOS arm64, run CI on Linux headless at
  the same version, and treat macOS arm64 and Windows x86_64 as the supported
  export targets with Linux desktop untested. Accept 4.7.x patch releases after
  a full check pass; require a superseding ADR for any new minor.
- **Reason:** Godot supports a stable branch actively only until its successor's
  first patch release. 4.7.1 shipped 2026-07-14, so 4.6 is already on partial
  support and 4.5 is end of life. The repository has no `project.godot`, making
  the migration cost zero at this moment, and Phase 1 exercises none of the
  rendering, physics, or navigation code where new-minor regressions cluster.
- **Player-facing effect:** No direct effect. Testers and graders receive a
  build for a platform they can actually run, produced from a reproducible
  toolchain.
- **Consequences:** 4.6.3 is retired as the project build. Issues #2 and #7 pin
  CI and the harness to 4.7.1. Issue #2 must additionally resolve how `godot` is
  invoked, because the binary is not on `PATH` and the `AGENTS.md` verification
  commands are therefore not yet runnable, and must demonstrate rather than
  assume GDScript Toolkit compatibility. Export presets, signing, notarization,
  and Linux verification stay out of scope.
- **Supersedes:** The unqualified "Godot 4.x" target in the GDD, `AGENTS.md`, and
  the technical architecture; resolves Q-006.
- **Authority:** Human
- **Date:** 2026-07-31

## Chronological Worklog

### 2026-07-30 — Session 001: Kitchen Lead persistence structure

**Summary**

Established a version-controlled operating definition and persistent worklog for the Kitchen Lead.

**Decisions captured**

- Kitchen Lead is the human’s primary agent and design rubber duck.
- Kitchen Lead is the only persistent active agent during Phase 1.
- Worldkeeper and Pantry Keeper are deferred as active agents.
- Phase 1 focuses on a primitive headless GDScript prototype.
- Implementation, verification, and later content agents are task-scoped.

**Artifacts**

- [[Kitchen Lead]]
- [[Kitchen Lead Worklog]]
- [[Neon Kitchen - Game Design Document]]

**Risks or limitations**

- Ingredient, customer, lore, and implementation registries do not exist yet.
- Exact evaluator and test-harness contracts remain open.

**Next**

Define the Phase 1 repository structure, evaluator contract, first fixtures, and acceptance tests.

### 2026-07-30 — Session 002: Long-term technical foundation

**Summary**

Researched current official Godot and Microsoft guidance and drafted a modular architecture intended to preserve recipe rules across terminal and Godot interfaces, real-time cooking challenges, localization, multiplayer, C# modules, and alternate 2D/3D presentations.

**Recommendations or provisional assumptions**

- Use an interface-independent deterministic domain core.
- Express interactions as typed commands and ordered domain events.
- Use stable namespaced content IDs and versioned schemas.
- Put content, presentation, storage, localization, networking, time, randomness, and cooking challenges behind focused ports.
- Default to statically typed GDScript; introduce C# only for a cohesive, justified module.
- Treat future flexibility as stable seams, not permission to build speculative systems in Phase 1.

**Work completed**

- Created the technical architecture v0.1, later moved to [[technical_architecture|Technical Architecture]].
- Defined an extension change map for ingredients, characters, recipes, levels, minigames, Japanese localization, multiplayer, new visual styles, and C#.
- Defined Phase 1 implementation and deferral boundaries.
- Added proposed code style, testing, verification, and architecture-decision rules.

**Evidence**

- Godot official documentation for GDScript style/static typing, project and scene organization, Autoloads, Node alternatives, Resources, signals, internationalization, pseudolocalization, multiplayer, and C# integration.
- Microsoft official C# coding conventions and `dotnet format` documentation.

**Risks or limitations**

- The proposal deliberately creates compatibility seams but cannot make multiplayer, localization, or 3D production inexpensive.
- Exact Godot version, test framework, and first command/event DTOs remain undecided.
- Proposal v0.1 is not yet an approved implementation contract.

**Next**

Review the proposal with the human, promote accepted items to approved decisions, and derive the Phase 1 bootstrap work package.

### 2026-07-30 — Session 003: Coding-agent documentation structure

**Summary**

Converted the long-form architecture into a repository documentation structure that gives coding agents a concise operational contract while retaining the full rationale.

**Human-approved decisions**

- Use typed custom `.tres` Resources as canonical content from Phase 1.
- Do not adopt a project-wide ECS.
- Put the coding contract in root `AGENTS.md`, the full architecture in `docs/technical_architecture.md`, and architecture decisions in `docs/adr/`.
- Bootstrap automated GDScript formatting, linting, warnings, headless import, content validation, and tests.

**Work completed**

- Moved the existing architecture document to [[technical_architecture|Technical Architecture]] without replacing its long-form content.
- Updated it to v0.2 for `.tres`-first content, scoped ECS policy, and GDScript quality gates.
- Created root `AGENTS.md`.
- Created `docs/adr/README.md` with ADR triggers, naming, and template.
- Updated durable links and decisions in this worklog.

**Risks or limitations**

- Exact Godot, GDScript Toolkit, and test-framework versions remain unpinned.
- The root coding guide contains placeholder test commands until the test harness exists.
- The broader technical architecture remains proposed except for the decisions explicitly approved above.

**Next**

Pin the Godot version and test framework, then bootstrap the repository and replace placeholder verification commands with executable project commands.

### 2026-07-30 — Session 004: Managed GitHub execution system

**Summary**

Established private GitHub Issues and the Neon Kitchen Development Project as
the managed execution system for Phase 1 and updated the Kitchen Lead operating
definition to coordinate work through it.

**Human-approved decisions**

- Use GitHub Issues for bounded executable outcomes, acceptance criteria,
  discussion, and verification evidence.
- Use the GitHub Project for workflow status, priority, size, phase, area, and
  dependency sequencing.
- Keep the GDD and accepted ADRs authoritative; keep durable decision context
  and rationale in the Kitchen Lead Worklog.

**Work completed**

- Created the Phase 1 milestone and an eleven-issue backlog.
- Created one parent validation epic with ten sub-issues.
- Recorded native blocked-by relationships for implementation order.
- Configured Project status, priority, phase, and area options.
- Updated [[Kitchen Lead]] with issue-readiness, status-transition, delegation,
  handoff, and task-memory protocols.

**Evidence**

- [Neon Kitchen Development Project](https://github.com/users/rkhanna24/projects/1)
- [Phase 1 validation epic](https://github.com/rkhanna24/NeonKitchen-godot/issues/1)
- [Phase 1 milestone](https://github.com/rkhanna24/NeonKitchen-godot/milestone/1)

**Risks or limitations**

- New issues must be added to the Project manually until an auto-add workflow
  is configured and verified.
- The repository has not yet been bootstrapped with Godot files or quality
  gates.

**Next**

Resolve issues #11 and #4, then begin the unblocked repository bootstrap work.

### 2026-07-31 — Session 005: Repository documentation vault

**Summary**

Moved the complete canonical project-context set into the Godot repository and
established `docs/` as an Obsidian vault available to repository-scoped agents.

**Human-approved decisions**

- Use repository `docs/` as the canonical Obsidian knowledge base.
- Keep root `AGENTS.md` at repository root for automatic coding-agent
  discovery.
- Keep GitHub Issues and the Project as the executable-work system.

**Work completed**

- Added the GDD, technical architecture, ADR guidance, Kitchen Lead definition,
  and Kitchen Lead Worklog beneath `docs/`.
- Added [[Home]] as the vault entry point.
- Updated repository-relative and vault-relative links.
- Configured Obsidian machine-specific state to remain untracked.

**Risks or limitations**

- The former standalone vault must not continue evolving as a competing
  canonical source after this migration is accepted.
- Obsidian must be pointed at the repository `docs/` directory on each machine.

**Next**

Review and merge the documentation-vault migration, open repository `docs/` in
Obsidian, and replace the former vault contents with a pointer or archive.

### 2026-07-31 — Session 005: Engine pin and platform matrix

**Summary**

Resolved issue #11 by pinning Godot 4.7.1 stable standard, recording the Phase 1
platform matrix, and setting an upgrade policy in ADR 0001. Also reconciled the
documentation-location and architecture-authority conflicts raised at session
start.

**Human-approved decisions**

- DEC-015: pin Godot 4.7.1 stable standard; develop on macOS arm64; support
  macOS arm64 and Windows x86_64 exports; accept patch releases but require a
  superseding ADR for a new minor. Supersedes the unqualified "Godot 4.x" target.

**Work completed**

- Created [ADR 0001](../adr/0001-pin-godot-version.md) with status Accepted.
- Recorded DEC-015 and resolved Q-006.
- Noted #14 as the owner of Q-004 and Q-007.
- Added the GDScript Toolkit lag risk.
- Installed and verified the pinned engine locally.

**Evidence**

- Godot release history: 4.7.1 published 2026-07-14; 4.7 on 2026-06-18; 4.6.3 on
  2026-05-20.
- Godot release policy: a branch is actively supported until its successor's
  first patch release, then partial, then end of life. 4.7.1 is 4.7's first
  patch, so 4.6 became partial on 2026-07-14 and 4.5 is end of life.
- Local install inspected: `4.6.3.stable.official.7d41c59c4`, standard non-.NET
  bundle, universal binary, on macOS 26.5.2 arm64.
- GDScript Toolkit latest release is 4.5.0, published 2025-10-09.
- Godot 4.7's only GDScript language change is Android Java-interface support.
- Installed `4.7.1.stable.official.a13da4feb` at
  `/Applications/Godot_4.7.1.app`. The archive matched the published SHA512 sum,
  the bundle contains no .NET/Mono components, it is a universal binary, and
  `--headless --quit` exits 0. Installed by direct download rather than Homebrew,
  because the `godot` cask tracks the latest release and would undermine the pin.

**Specialist handoffs**

- None. Kitchen Lead executed #11 directly per DEC-007.

**Risks or limitations**

- The pinned binary sits at `/Applications/Godot.app/Contents/MacOS/Godot` and is
  not on `PATH`, so #2 must name it explicitly. The bundle name carries no
  version, so verification should assert the expected version string rather than
  trust the path. 4.6.3 was uninstalled on 2026-07-31, leaving 4.7.1 as the only
  installation.
- The `AGENTS.md` verification commands remain unrunnable: `godot` is not on
  `PATH`, and the test and content-validation commands are still placeholders.
  Owned by #2 and #7.
- GDScript Toolkit compatibility with 4.7 is assessed but unverified.
- ADR 0001 was written without loading the official release-policy page
  directly; the policy statement comes from Godot's own documentation via search
  plus the observed release history, which agree.

**Open questions**

- None newly opened. Q-006 closed; Q-004 and Q-007 remain, owned by #14.

**Next**

Install Godot 4.7.1, close #11, then ratify the structural foundation in #14 to
unblock #2 and #4.

### 2026-07-31 — Session 006: Phase 1 structural foundation ratified

**Summary**

Resolved issue #14. Audited every binding rule in `AGENTS.md` against real
authority, researched current Godot practice for gaps, and ratified a narrowed
Phase 1 structural foundation in ADR 0002. DEC-009 now has a final disposition.

**Human-approved decisions**

- DEC-016 / ADR 0002, superseding DEC-009. Full command and event vocabulary
  retained with cooking-challenge terms reserved but undefined; no randomness or
  wall-clock time in the domain; `ContentRepository` built with `RandomPort` and
  `CookingChallengePort` declared as interfaces only; reduced repository layout;
  rule 10 split into a binding constraint plus guidance; six Godot-specific
  correctness rules added.

**Work completed**

- Created [ADR 0002](../adr/0002-phase-1-structural-foundation.md).
- Rewrote the `AGENTS.md` rule set so every binding rule cites its authority;
  added a Conventions section; corrected the Authority order so the architecture
  document is guidance rather than authority; replaced "Godot 4.x" with 4.7.1.
- Marked [[technical_architecture|Technical Architecture]] v0.3 as
  partially-accepted and recorded which sections ADR 0002 accepts.
- Resolved Q-004 and Q-007.

**Evidence**

- Traceability audit: 6 of 16 binding items authorized, 4 partial, 6 orphaned.
  Every orphan traced to DEC-009 or the proposed architecture document.
- Two structural defects found: `AGENTS.md` ranked a proposed document fourth in
  its authority order, and still described the engine as "Godot 4.x".
- Godot practice review found four correctness hazards: Resources are shared by
  reference so mutating one mutates all consumers; `.uid` sidecar files must be
  committed and rule 6 risked being read as licence to delete them; a custom
  `Resource` with a required `_init()` argument loads as `null`; and float math
  is not deterministic across platforms, which threatens golden parity across
  the macOS/Windows/Linux matrix pinned by ADR 0001.
- GDD evidence used in scoping: cooking techniques appear in the stretch-goal
  list, so challenge vocabulary is roadmap; a randomized visible pantry was
  deliberately removed in revision v4, so it is a rejected feature rather than a
  deferred one.

**Specialist handoffs**

- None. Kitchen Lead executed #14 directly per DEC-007.

**Risks or limitations**

- The integer-arithmetic rule constrains #4: customer target weights must be
  integers. Accepted deliberately to protect band boundaries at 40, 65, and 85.
- Exact `project.godot` warning levels are named as a mechanism but not chosen;
  #2 selects and records them against real code.
- ADR 0002 §5 forbids creating ports beyond the three named without an ADR,
  which will require an ADR at the Godot UI migration if a presentation port is
  wanted.

**Open questions**

- A randomized initial ingredient set contradicts GDD §2.3 and the v4 revision.
  Raised as a future possibility; **not** approved. It would need an explicit GDD
  revision, not a port-level decision.

**Next**

Close #14, then #7, #2, and #4.

### 2026-07-31 — Session 007: GDD reconciled with accepted decisions

**Summary**

Resolved issue #15. Corrected one contradiction and four stale references in the
game design document so the top authority artifact no longer disagrees with
accepted ADRs and approved decisions.

**Work completed**

- GDD v5. Content format corrected from human-readable JSON to typed `.tres`
  Resources per DEC-010, with JSON retained for saves, replays, network DTOs, and
  golden snapshots; "Godot 4.x" replaced with the pinned 4.7.1 and the supported
  export targets named per ADR 0001; shared definitions moved from `data/` to
  `content/` per ADR 0002 §6; integer weighting and integer scoring arithmetic
  stated where weighted targets are defined; a note added to §4.1 recording that
  only the Kitchen Lead is active during Phase 1 per DEC-004 and DEC-005.

**Evidence**

- The JSON contradiction was material, not cosmetic. The GDD is authority #2 and
  DEC-010 is human authority, so DEC-010 governed — but an agent citing the GDD
  could have authored content in the wrong format with a defensible reference.
  This is the same failure mode #14 corrected in `AGENTS.md`.
- Grep confirms no remaining stale usage of `JSON` as a content format,
  `Godot 4.x`, or `data/` outside the v5 revision entry itself.

**Risks or limitations**

- The GDD is a living document; a snapshot was already submitted for grading, so
  these edits do not affect work already assessed.
- GDD §5.3 budgets roughly 14,000 tokens per focused session across fifty
  sessions. Observed usage is materially higher. This affects the Week 5 writeup's
  accuracy, not any current decision, and should be revisited before submission.

**Next**

Close #15. Proceed to #7, then #2 and #4.

### 2026-08-01 — Session 008: Project bootstrap and verification gate

**Summary**

Selected GUT as the test framework (ADR 0003) and bootstrapped the Godot project
with a working verification gate. Issue #2 is complete pending a human editor
check; issue #7 is partially complete and now correctly blocked by #2.

**Human-approved decisions**

- ADR 0003: use GUT v9.7.1 from the `godot_4_7` branch, pinned to commit
  `aeb5d4f3f7f0a6c9b5e178876d6c99b791fda605`, vendored into `addons/`. Chosen
  over gdUnit4 because its differentiators — mocking, spying, orphan detection —
  target problems ADR 0002's dependency injection already avoids.

**Work completed**

- `project.godot` for Godot 4.7.1, with GDScript warning levels enforcing static
  typing.
- `scripts/check.sh`, a single verification gate covering engine version,
  format, lint, headless import, type and warning checks, domain purity, and
  tests. CI calls the same script.
- `.github/workflows/checks.yml`, which provisions the toolchain with a checksum
  -verified Godot download and contains no check logic of its own.
- `requirements-dev.txt` and `gdlintrc` pinning and configuring gdtoolkit.
- `AGENTS.md` verification section replaced with executable commands.

**Evidence**

- **Neither Godot command is usable as a CI gate on its own.**
  `godot --headless --path . --import` exits 0 and reports nothing when a script
  has type or warning violations. `godot --headless --check-only -s <file>`
  reports violations but also exits 0. The gate therefore inspects output. The
  previous `AGENTS.md` bootstrap command list would have passed a codebase full
  of type violations.
- gdtoolkit 4.5.0 verified against the pinned engine, resolving the risk ADR
  0001 recorded. `gdformat --check` exits 1 when reformatting is needed and 0
  when clean; `gdlint` exits 1 on problems. Both are usable gates.
- `untyped_declaration=2` is workable: `for i in range(10)` does **not** trip it,
  because Godot infers loop variable types. This was verified against a probe
  script, not assumed.
- `integer_division=2` does trip on intentional truncation, which ADR 0002 rule
  13 requires. Kept as an error so every truncation must carry a narrow
  `@warning_ignore("integer_division")` and a reason — truncation direction can
  move a score across the 40, 65, and 85 band boundaries.
- The gate was tested in both directions: clean tree exits 0; a file with an
  untyped variable and a `randi()` call in `core/domain` exits 1 and names both
  violations.

**Risks or limitations**

- An earlier draft of `scripts/check.sh` used `mapfile`, which macOS bash 3.2
  lacks, and **reported "All checks passed" while three steps were broken**. The
  script is now bash 3.2 compatible and traps unexpected errors as failures. The
  episode is the reason the gate is tested in the failing direction, not only the
  passing one.
- CI has not run yet; the workflow is unexercised until the first push.
- Warning levels are calibrated against a probe, not a real domain. Expect one
  revision when #9 lands actual evaluator code.
- `scripts/` is not in the ADR 0002 §6 layout. It was added deliberately so the
  gate is runnable locally and by CI from one definition. Recorded here rather
  than silently extending the ratified structure.
- `tools/` is likewise outside the §6 layout, added on 2026-08-01 for the
  flavour explorer. Both are developer tooling rather than game structure. If a
  third such directory appears, the layout should be revisited properly rather
  than extended a fourth time by note.
- **The editor catches project-configuration errors that headless mode cannot.**
  The first `project.godot` listed `"GDScript"` in `config/features`, which is not
  a valid feature tag — tags describe engine capabilities such as the version, a
  renderer, or `C#` on .NET builds, not languages. Headless import accepted it
  silently, and so did `--headless --editor --quit`. Only the editor GUI reported
  "this project uses the following features not supported by this build".
  Corrected to `PackedStringArray("4.7")`.

  Consequence: `scripts/check.sh` cannot verify project-configuration validity,
  because no headless invocation surfaces it. **Opening the editor after changing
  `project.godot` remains a human step.** This was found only because that step
  was requested rather than assumed.

- **The editor rewrites `project.godot`,** normalising order and dropping both
  comments and any value equal to its default. Documentation about project
  settings therefore belongs in the ADRs, not in that file. The warning levels
  survived; `unused_parameter` disappeared only because `1` is its default.

- `docs/.gdignore` keeps the documentation vault out of Godot's filesystem scan,
  as anticipated by architecture §6. Measured effect: cache entries fell from 20
  to 6. There was **no measurable import-speed gain** — 1.53s before, 1.72s
  after, both dominated by engine startup. The benefit is a clean FileSystem
  dock that stays clean as `docs/` grows, not performance. Godot already skips
  dot-directories, so `.venv/` and `.git/` were never scanned despite `.venv/`
  holding 876 files.

**Next**

Human opens the project in the editor once to confirm the GUI path. Then #7
vendors GUT, adds the smoke test, and demonstrates a nonzero failure exit.

### 2026-08-01 — Session 009: GUT harness vendored and verified

**Summary**

Resolved issue #7. Vendored GUT v9.7.1, added a harness smoke test, and proved
the gate reports failure. Three separate silent-pass hazards were found and
closed along the way.

**Work completed**

- Added `scripts/setup.sh`, the project's dependency installer. Godot has no
  package manager, so it handles gdtoolkit and GUT identically: pin an exact
  version, fetch it, verify it. `.venv/` and `addons/` are both gitignored.
- Added `tests/unit/test_harness_smoke.gd`.
- Extended the test step in `scripts/check.sh` with `-ginclude_subdirs`, a
  zero-test guard, and hard failures when either dependency is missing.
- Corrected the headless command recorded in ADR 0003 and revised its
  installation decision from vendoring to fetch-on-setup.
- CI now calls `scripts/setup.sh`, so it exercises the same path a developer
  does.

**Evidence**

- **GUT's exit codes are asymmetric.** It exits 1 when a test *fails*, but 0
  when no tests are *found*. Without `-ginclude_subdirs` it discovered nothing
  under the ADR 0002 §6 layout, printed "Nothing was run", and exited 0. CI
  would have passed with zero coverage. The gate now parses the run summary and
  fails when the count is zero.
- The gate is verified in three directions: a deliberately failing assertion
  gives exit 1; removing it gives exit 0 with 3 tests; an empty `tests/`
  directory gives exit 1 with "no tests were discovered".
- GUT's own scripts load cleanly under the project's strict warning levels
  (`untyped_declaration=2` and the `unsafe_*` family). This was not guaranteed —
  project warning settings apply to addon code too — and would have blocked the
  choice had it failed.
- The smoke test itself passes `gdformat`, `gdlint`, and the type gate, so test
  files are held to the same standard as production code.
- **Vendoring was reversed on review.** GUT was first copied into the repository
  — 259 files and 3.2 MB of third-party source — before the human questioned it.
  The decisive argument was consistency: gdtoolkit was already pinned-and-fetched
  rather than committed, so vendoring GUT applied two different philosophies to
  two dependencies of the same kind.
- **Git submodules were rejected on structure, not preference.** GUT's repository
  root is itself a complete Godot project including its own `project.godot`. A
  submodule at `addons/gut` would nest a second Godot project inside this one;
  installing to `third_party/` would still need a copy step and clones 6.4 MB to
  obtain the 3.2 MB required.
- Integrity is verified with `git rev-parse HEAD` against the pinned commit
  rather than a tarball checksum, because GitHub's generated archives are not
  guaranteed byte-stable.
- Rehearsed from a clean slate: deleting both `.venv/` and `addons/`, then
  running setup and the gate, ends green.

**Risks or limitations**

- An `ERR` trap in `scripts/check.sh` fired on GUT's nonzero exit, reporting a
  spurious "unexpected error on line 166" and double-counting the failure. Fixed
  by running the suite inside an `if`. Found only because the red path was
  exercised, not just the green one.
- The GUT editor panel is not enabled. The CLI runner does not require it;
  enabling it is a `project.godot` change and therefore needs an editor check.
- Fetch-on-setup trades offline robustness for a clean repository. A fresh clone
  needs network access once. If GitHub or the tag became unreachable, setup would
  fail where a vendored copy would not. Accepted deliberately; reproducibility,
  vendoring's substantive advantage, is preserved by the pinned commit and SHA
  verification.
- The smoke test covers the harness, not gameplay. Real domain coverage arrives
  with #9.
- **CI failed on its first run** (08d6960), in the workflow rather than the
  project. The Godot archive was saved as `/tmp/godot.zip` while
  `SHA512-SUMS.txt` lists its published filename, so `sha512sum -c` reported
  "No such file or directory" — a missing file, not a checksum mismatch. Fixed
  by downloading under the published name. The download and verification logic
  was then rehearsed locally against the real Linux asset before re-pushing.

**Next**

Push, confirm CI green on first run, then #4 locks the Phase 1 contracts.

### 2026-08-01 — Session 010: Phase 1 contracts locked

**Summary**

Resolved issue #4. [ADR 0004](../adr/0004-phase-1-contracts.md) locks the
evaluator, commands, events, invalid-action behaviour, fixture scope, and
playtest protocol. Q-001, Q-003, and Q-005 are resolved, closing the last of the
design questions.

**Human-approved decisions**

- DEC-017 / ADR 0004. Scoring is normalised weighted distance to per-dimension
  targets, integer arithmetic, one deliberate truncation. Weight 0 means the
  dimension is ignored, which is the tuning lever that makes multiple solutions
  possible without vague targets. Four hard constraint kinds cap at 39. Feedback
  selection is deterministic via explicit tie-breaks. Fixtures are three
  ingredients and two customers, scoped as evaluator contract fixtures rather
  than a playable slice.

**Evidence**

- The formula was validated computationally before being written down. Against
  the GDD's worked example it returns 81 / Satisfied / strongest match Comfort /
  largest miss Spicy; the GDD narrates that dish as Satisfied 78 with the same
  two feedback fields. A perfect dish scores 100, the worst scores 0, and an
  exhaustive two-dimension sweep over every target, weight, and dish value
  stayed inside 0–100.
- Overshooting is penalised as much as undershooting, which is what prevents
  "more ingredients is always better" — a dominance risk the GDD names.
- Rejected alternatives were compared against the same worked example rather
  than argued abstractly. A ±1 tolerance scored it a full band higher, and a
  direction-based model cannot express "spicy, but not too spicy".

**Risks or limitations**

- The GDD's Week 1 fixture count and its viability rule are in tension: three
  ingredients admit only seven dishes, so requiring three satisfying solutions
  with two different central ingredients would force targets so generous the
  puzzle loses teeth. Resolved by scoping the fixtures as contract tests and
  deferring the viability rule to the twelve-ingredient roster, audited in #6
  across all 298 dishes.
- Two defects were found in this log while recording the decision. **DEC-015 was
  duplicated** — the Godot pin reused an identifier already held by the docs
  vault decision. The vault record is renumbered DEC-018 because nothing
  referenced it. Separately, Q-004 had been added to Resolved Questions in
  session 006 without being removed from Open Questions.
- Fixture identities and flavour values are approved in count and purpose only;
  #8 authors the actual ingredients and customers.

**Next**

#3 typed Resources, #8 fixtures, #9 evaluator, #6 golden coverage.

### 2026-08-01 — Session 011: Binding rules made enforceable

**Summary**

Resolved issue #16. The gate now enforces the architecture rules it previously
only stated. Before this it checked 2 of 13; it now checks 5 fully and 1
partially, and `AGENTS.md` records which rules rely on review instead.

**Work completed**

- Dependency direction: no reference from `core/` to `adapters/`, `features/`
  or `bootstrap/`, and none from `core/domain/` to `core/application/`. Both
  path references and `class_name` references are checked.
- Layout: no empty directories, and every file in `shared/` must have at least
  two consumers outside it.
- UID sidecars: every project `.gd` has one, none is gitignored, and no orphan
  sidecar exists.
- `AGENTS.md` gained a table separating gate-enforced rules from review-only
  ones.

**Evidence**

- All eight scenarios verified in the failing direction, then confirmed green
  again: adapter reference by path, adapter reference by `class_name`,
  domain-to-application reference, empty directory, single-consumer `shared/`,
  gitignored `.uid`, orphan `.uid`, and a restored clean tree.
- **The red-path test found a real bug in the check itself.** `git check-ignore`
  consults the index by default, so an already-tracked `.uid` reported as
  not-ignored even with a matching rule — the check would have silently never
  fired. Fixed with `--no-index`, since the hazard is the rule existing and
  silently dropping future sidecars, not the state of one tracked file.

**Risks or limitations**

- The `class_name` half of the dependency check is a heuristic, matching
  identifiers declared in outer layers anywhere under `core/`. Path references
  are definitive. A false positive is possible if an unrelated identifier
  collides with an adapter class name.
- Rules 2, 3, 5–8 and 12 remain unenforced. Rule 12 becomes checkable with #3.
- Every check is currently exercised against a tree with one real script. They
  will meet real code for the first time in #3 and #9.

**Next**

#3 typed Resources, then #8 fixtures and #9 the evaluator.

### 2026-08-01 — Session 012: Content model, validation, and repository contract

**Summary**

Resolved issue #3. Typed `.tres` definitions, a content validator, the
`ContentRepository` port and two implementations now exist, with 58 tests
including a shared contract suite both repositories must pass.

**Work completed**

- `Flavor` and `FlavorProfile` domain value objects; `FlavorProfile` is the
  typed value between the two evaluation stages of ADR 0004 §9.
- `IngredientDefinition`, `CustomerDefinition`, and `CustomerConstraint` as
  typed Resources, with the ADR 0004 §2 default of comfort weight 1, target 3.
- `ContentValidator` covering duplicate and malformed IDs, out-of-range flavour
  values, negative and all-zero weights, missing localisation keys, dangling
  constraint references, and require/forbid contradictions.
- `ContentRepository` port, a `.tres` adapter, and an in-memory adapter, both
  held to one shared contract suite.
- Test fixtures generated with `ResourceSaver` rather than hand-written, so the
  `.tres` format is correct by construction.

**Evidence**

- 58 tests pass; the gate, its own eight-scenario self-verification, and the
  applet parity check are all green.
- The `.tres` repository refuses to serve anything when validation fails, as
  rule 7 requires, and that is asserted rather than assumed.

**Risks or limitations**

- **The lexicographic-order test cannot catch the bug it was written for.**
  `Array[StringName].sort()` orders by internal pointer rather than text, which
  Godot documents. With these fixtures, pointer order happens to coincide with
  text order, so reinstating the bug left the suite green. A second,
  deterministic test was added that supplies definitions in reverse order and
  does fail when sorting is removed — verified. The invariant assertion is kept
  but documented as partial.

  **Correction, same session.** This was first recorded as "nondeterministic",
  which was wrong and understated the risk. Measured on Godot 4.7.1: five names
  interned in ascending text order sort to exactly reversed text order, and
  identically across runs. It is stably wrong, not flaky. What varies is
  interning order, which follows content load order — so the symptom is a
  confidently consistent wrong order locally and a different one after a
  fixture is renamed or on another platform. An earlier experiment reporting
  "eight trials, no disagreement" was itself the error: it interned names in
  reverse-text order, which is precisely the case where pointer order coincides
  with text order, so it could not have detected the bug.

  No gate check or rule was added. The hazard is a documented Godot behaviour,
  the guidance lives as a comment on `_sorted_ids`, and a heuristic check for
  one library quirk was judged not worth its false positives.
- Fixtures are contract fixtures, not game content. #8 authors the real roster.
- No composer or evaluator exists yet; `FlavorProfile` has no producer until #9.

**Next**

#8 authors the Phase 1 fixtures, then #9 implements the evaluator.

---

## Worklog Entry Template

```markdown
### YYYY-MM-DD — Session ###: Short title

**Summary**

One-paragraph description of the material outcome.

**Human-approved decisions**

- Decision and what it supersedes.

**Recommendations or provisional assumptions**

- Recommendation that is not yet authoritative.

**Work completed**

- Artifact or implementation change.

**Evidence**

- Test, inspection, playtest, or source supporting the result.

**Specialist handoffs**

- Task ID, role, result, and termination status.

**Risks or limitations**

- Newly discovered issue or constraint.

**Open questions**

- Decision still needed.

**Next**

- Smallest useful next action.
```
