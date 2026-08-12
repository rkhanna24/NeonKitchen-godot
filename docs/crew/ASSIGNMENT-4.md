---
type: crew-documentation
display-name: "Assignment 4 — Dynamic Content Pipeline"
repository: "https://github.com/rkhanna24/NeonKitchen-godot"
---

# Assignment 4 — Dynamic Content Pipeline

**Game:** *Neon Kitchen* — a Godot 4.7.1 recipe-composition puzzle set in a nomad
food truck. The player combines up to three ingredients for a customer with a
hidden flavour preference; the dish is scored and the customer reacts.

This pipeline generated the game's entire remaining content: **8 ingredients, 5
customers, and 20 reaction lines**, all shipped and playable.

## The gap, in numbers

The game was thin on **content itself**, and the shortfall was measurable rather
than felt:

| | Before | Required | Source of the requirement |
|---|---|---|---|
| Ingredients | 4 | 12 | GDD §2.3 names all twelve |
| Customers | 3 | 8 | GDD §2.4, "the eight recipes" |
| Reaction lines | 12 | 32 | ADR 0004 §8a, four bands per customer |

ADR 0004 §12 states the first playtest must run on the twelve-ingredient roster,
"not these fixtures". Until this pipeline ran, the playtest that Phase 1 exists to
reach was blocked on content nobody had written.

### The sharper version of the gap

**The GDD's own worked example could not be played.** §2.2 explains the entire
game through one encounter — a customer wanting comfort and spice with "nothing
fermented tonight", solved with *noodles, mushrooms and chili crisp*. Mushrooms
did not exist, and the only spicy ingredient in the pantry carried the
`fermented` tag.

The document used a dish the game could not produce to teach the game. The
pipeline's first output fixed that.

## The pipeline

Five agents, orchestrated by Claude Code, each with tool grants that make its
boundary structural rather than advisory.

```
brief ──> Pantry Keeper ──> proposal ──> Recipe-Space Analyst ──> PASS / REVISE
             (no Bash)                        (Bash, no Edit)
                 ^                                   │
                 └───────── specific defect ─────────┘
                                                     │ PASS
                                                     v
                                        Health Inspector ──> .tres + locale
                                                     │
                                        Kitchen Lead verifies independently
```

| Agent | Grant | What the grant makes impossible |
|---|---|---|
| `worldkeeper` | `Write`, no `Bash`/`Edit` | Cannot alter an existing document; drafts lore and stops |
| `pantry-keeper` | `Write` only | **Cannot run the evaluator**, so cannot pre-compute the scores the Analyst exists to check |
| `recipe-space-analyst` | `+ Bash`, no `Edit` | Can compute but not author; reports a defect, cannot fix it |
| `health-inspector` | `+ Edit` | Generates files; may not change a number to make its own report pass |
| `kitchen-lead` | `+ Task` | The only agent that can spawn another |

Plus **`tools/lore_query.py`** — retrieval over the design corpus. Stdlib only,
no index, no network, no API key.

## The knowledge base

Nine markdown files: the GDD, four ADRs, the technical architecture, and two
documents written for this pipeline.

**`docs/design/Lore Bible.md`** is the direct GDD extension. Every claim in it
carries one of three labels:

- **ESTABLISHED** — traceable to a cited line of the GDD or to shipped content
- **PROPOSED** — invented by the Worldkeeper, requiring human approval
- **DECIDED** — canon by human decision, dated

That split is the document's whole safety property. Without it, later generation
retrieves an invention and treats it as settled fact. **A retrieved chunk must
carry its label**, which constrains chunking: the retriever may never split
inside a labelled claim.

Its own summary of itself was that roughly a third was ESTABLISHED, and that past
the truck the entire world rested on four phrases in a CSV.

## RAG — query, retrieved chunk, output

Heading-bounded chunks, BM25 with a heading boost, and a term-coverage gate
rather than a score threshold. `--verify-probes` runs 9 queries that must hit and
3 that must return nothing.

### 1. Cultural framing — retrieval preventing an error

```
$ python3 tools/lore_query.py "cultural origins of the ingredients"

docs/design/Lore Bible.md — ## Escalation: Cultural Origins of the Provisional Ingredients
    coverage=1.00

    The twelve named ingredients draw on real, distinct culinary traditions.
    Naming those traditions here is descriptive, not an assignment of any of
    them to a specific in-fiction person, neighborhood, or migration history.
```

**Output — the three most culturally specific ingredients:**

> **kimchi** — "Napa cabbage packed in chili paste and left to sour in a sealed jar until the lid won't stay quiet."
>
> **smoked fish** — "Fillets cured in salt, then hung over smoldering wood chips until the flesh turns a deep, glossy amber."
>
> **coconut milk** — "Coconut flesh grated, soaked, and squeezed through cloth until the liquid runs rich and pale, thick enough to slow a boil."

Every description is **preparation, never provenance**. No tradition is attached
to an invented in-fiction group. The retrieved chunk is a *refusal*, and the
output honours it.

### 2. Lore reaching a character

```
$ python3 tools/lore_query.py "who approves the truck parking on this block"

docs/design/Lore Bible.md — ## What the Gangster Establishes
    coverage=0.75

    DECIDED by the human, 2026-08-07. A gang controls the block the truck is
    parked on, and the truck operates there by permission rather than by right.

    This is the first faction with a concrete relationship to the truck, and it
    is not an antagonistic one: the arrangement has already been made...
```

**Output:**

> **Block Boss** — "This corner's mine, so for once I get to sit and actually eat instead of just watching it. Make it savory, and put some real heat on it while you're at it — but skip anything smoked. I don't trust anything that hides what's underneath it."

"Not antagonistic, the arrangement has already been made" becomes a man sitting
down to eat on his own corner. The retrieved constraint is visible in the output.

### 3. The roster

```
$ python3 tools/lore_query.py "twelve ingredient roster provisional names"

docs/design/Lore Bible.md — ## The Provisional Twelve-Ingredient Roster
    coverage=1.00

    ESTABLISHED. GDD §2.3 names the Phase 1 pantry: "noodles, tofu, mushrooms,
    kimchi, pepper paste, chili crisp, coconut milk, pickled cucumber,
    chickpeas, flatbread, citrus herbs, and smoked fish."
```

**Output:** eight ingredients drawn from that list — with **tofu and flatbread
deliberately cut**, on GDD §2.3's own criterion of "distinct gameplay roles":

> An honest tofu duplicates `soy_broth`'s exact niche. Giving it a different
> profile stops describing tofu and starts describing whatever seasons it, which
> fails tag accuracy instead.

### Retrieval caught something reading would not

Running the retriever *before* generating returned a Lore Bible section still
flagging the roster question as **open**, three sections away from an Open
Questions list that already recorded it resolved. Nothing connected them.

**Staleness is invisible in a document and visible in a knowledge base.**

## What the critic caught

Four corrections, each with the numbers on both sides.

### 1. A constraint that named a real tag and did nothing

`block_boss` carried `FORBID_TAG(raw)`. It passed the criterion the Kitchen Lead
had written — the tag exists on real ingredients — and the Analyst tested it
differently: *drop the tagged ingredient from a dish the customer would otherwise
be satisfied by; does the outcome change?*

```
FORBID_TAG(raw)      0 of 120 dishes changed     inert
FORBID_TAG(fermented)  111 of 120 changed        a real boundary
```

Zero. `raw` ingredients contribute nothing to savory or comfort, this customer's
only weighted dimensions — he was forbidding food he would never have chosen.
**Flavour text pretending to be a mechanic.**

Corrected to `FORBID_TAG(smoked)`, which removes the pantry's only savory-3
source from a customer wanting Savory 5:

```
FORBID_TAG(smoked)    41 of 41 dishes changed    100%
```

The Analyst's test replaced the coordinator's criterion and is now the standard.

### 2. The roster rule, failed at 75%

GDD §2.3: no single recipe may satisfy more than half the roster. Enumeration of
all 298 dishes against all 8 customers found one satisfying **6 of 8**, and 17
dishes over the limit.

Three revision rounds followed, each fixing the named dish and producing another
— what local fixes do to a global constraint. It converged only once the
mechanism was named:

> **Sharing a dimension is harmless when customers disagree about it and fatal
> when they agree.**

Spicy is weighted by five of eight customers and never violated anything; fresh
at four broke it twice. The final fix left the target mechanism entirely, using a
constraint — which ADR §5 keeps separate from flavour and which therefore cannot
create a new shared-dimension cluster.

Final state: maximum 4 of 8, verified exhaustively.

### 3. The critic found a bug in its own instrument

Mid-verification, the Analyst discovered its probe had left
`comfort_target`/`comfort_weight` at the schema defaults — **3 and 1** — instead
of the authored `0`, for four of eight customers. They were carrying a preference
nobody wrote.

It proved this by deliberately reintroducing the leak and reproducing its own
earlier figures exactly, then reported that prior rounds had been partly
measuring customers that did not exist.

Catching your own instrument is harder than catching someone else's output.

### 4. A boundary whose tag did not mean what its sentence said

Found by playing. The old local's constraint had subject `gluten` while its
explanation described food held under a heat lamp — a dietary category and a
freshness category, coinciding only because one ingredient happened to carry
both. Corrected by adding a `held` preparation tag that means what the sentence
says.

## Voice judgment

**Do the outputs sound like the game?** Yes, and the evidence is that the human
could not tell the machine-written descriptions from the hand-written ones — the
critique that produced the voice rules was levelled at the *original four*,
written by hand.

Two concrete tweaks, both with before and after.

### Tweak 1 — the voice document itself

The human read the four shipped ingredients and said which lines worked:

| Rejected | Why |
|---|---|
| "the most reliably comforting thing in the pantry" | states its mechanical role, and makes a claim about the rest of the pantry |
| "for anyone chasing something adventurous" | names a flavour dimension outright |
| "but not for anyone avoiding soy" | restates the constraint the constraint already states |

That became `docs/design/Content Voice.md` — six rules, added to the Pantry
Keeper's prompt. One rule turned out to be a *maintenance* rule rather than a
taste one: a claim relative to the pantry is true of four ingredients and false
of twelve, silently, with no check able to catch it.

**Before:** "Fermented chilies pounded down with citrus peel — a fresh, sharp heat for anyone chasing something adventurous."

**After:** "Fermented chilies pounded down with citrus peel, sharp enough to catch the back of the throat."

### Tweak 2 — a rule that was wrong, caught by the agent

The Pantry Keeper reported that its five customers never named a flavour
dimension while the three shipped ones did, and **raised it as an open question
instead of choosing a direction.**

It was right that something was wrong, and it was the rule. GDD §1:

> Customers do not order exact menu items. **They describe what they want through
> qualities such as comforting, spicy, fresh, savory, or adventurous.**

Rule 2 had said "never name a flavour dimension" with no stated scope. Written
for ingredient descriptions, it was being applied to the one place the game
*needs* that vocabulary.

**Before:** "something with some real weight to it" — for a customer targeting Savory 3 and Adventurous 4.

**After:** "something hearty and savory would hit the spot, but don't be shy going adventurous with it too."

Not subtle — unclear. ADR 0004 §12's advance gate asks whether a tester can state
*before serving* what a customer wants.

## Running it

```bash
python3 tools/lore_query.py "who approves the truck parking"   # retrieval
python3 tools/lore_query.py --verify-probes                    # 9 hit + 3 no-match, exit 0

./scripts/check.sh                                             # the full gate, 179 tests

/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s bootstrap/main.gd
```

The last one plays the game the content was generated for. `start`, `present`,
`list`, `select <id>`, `submit`.

## What the pipeline produced, judged by the game

Not by a human reading plausible output — by the shipped code:

- `ContentValidator` — zero problems across 12 ingredients and 8 customers
- `TresContentRepository` — loads clean
- `Evaluator` — 2,384 evaluations per verification round, scores matching the balance report exactly
- `scripts/check.sh` — green at 179 tests
- All 33 new localisation keys resolve through the real `TranslationServer`

And it plays. A full eight-customer session by the human, unprompted:

> "It was fun to me."

Two Delighted, four Satisfied, one Mixed, one Dissatisfied — all four rating
bands in one freely-played session.
