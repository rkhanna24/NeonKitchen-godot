# Health Inspection — Late-Shift Medic content

## Verdict: **FAIL at the gate step.** Content itself loads, validates, and
scores exactly as `content/staging/balance.md` (verdict PASS, §11) predicts.
The failure is a pre-existing, pinned repository test that hard-codes the
prior content-catalogue size and that this role is not authorized to modify.
See §5 for the exact failure and why it was not worked around.

---

## 0. Preconditions checked before doing anything

`content/staging/balance.md` §11 reads:

```
## 11. Verdict

**PASS.**
```

Confirmed by reading the file directly (not taking the launching agent's word
for it). Proceeded on that basis.

## 1. What was generated

- `content/base/ingredients/rooftop_greens.tres`
- `content/base/customers/late_shift_medic.tres`
- Six rows appended to `content/base/localization/en.csv` matching
  `content/staging/proposal.md` §3 verbatim (two ingredient rows: `.name`,
  `.description`; plus the customer's `.name`, `.request`, and the four
  `reaction.<band>` rows — eight lines counted individually, six being the
  customer's).

All generated via `ResourceSaver` from a throwaway script at `/tmp/gen.gd`,
run as:

```
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s /tmp/gen.gd
```

Output:
```
Godot Engine v4.7.1.stable.official.a13da4feb - https://godotengine.org

ingredient save error: 0
customer save error: 0
```

`/tmp/gen.gd` and the verification script `/tmp/gen_verify.gd` (see §3 below)
were both deleted after use:

```
$ rm -f /tmp/gen.gd /tmp/gen_verify.gd
$ ls /tmp/gen.gd /tmp/gen_verify.gd 2>&1
ls: /tmp/gen_verify.gd: No such file or directory
ls: /tmp/gen.gd: No such file or directory
```

### Generated `rooftop_greens.tres` (verbatim, unedited from ResourceSaver output)

```
[gd_resource type="Resource" script_class="IngredientDefinition" format=3]

[ext_resource type="Script" path="res://content/schemas/ingredient_definition.gd" id="1_grfix"]

[resource]
script = ExtResource("1_grfix")
content_id = &"ingredient.rooftop_greens"
name_key = &"ingredient.rooftop_greens.name"
description_key = &"ingredient.rooftop_greens.description"
fresh = 3
tags = Array[StringName]([&"raw", &"vegan"])
```

Only `fresh` is written because `savory`, `spicy`, `comfort`, and
`adventurous` are all 0, the class default, and Godot omits fields equal to
their default. This is expected per the task brief and not a bug — none of
those fields were dropped from the proposal, they were never non-zero.

### Generated `late_shift_medic.tres` — one manual cleanup after generation

`ResourceSaver` produced an `ext_resource` for
`res://content/schemas/customer_constraint.gd` even though `constraints` is
empty and never serialized — the exact dead reference the task warned about
in `solar_tech.tres`. Because it is genuinely unreferenced by anything else in
the file (the `constraints` field itself is omitted, being empty/default), I
removed that one `ext_resource` line and renumbered the remaining id from
`2_ngpoj` to `1_ngpoj`. This is a deletion of dead engine-emitted cruft, not
hand-authoring of content data — no field, value, or key was written by hand.
Final file:

```
[gd_resource type="Resource" script_class="CustomerDefinition" format=3]

[ext_resource type="Script" path="res://content/schemas/customer_definition.gd" id="1_ngpoj"]

[resource]
script = ExtResource("1_ngpoj")
content_id = &"customer.late_shift_medic"
name_key = &"customer.late_shift_medic.name"
request_key = &"customer.late_shift_medic.request"
reaction_key = &"customer.late_shift_medic.reaction"
fresh_target = 4
comfort_target = 1
fresh_weight = 3
comfort_weight = 2
```

I verified this edit did not break loading — see §2 below, run *after* this
edit, which loads it cleanly through the real repository.

No `savory_target/weight`, `spicy_target/weight`, or `adventurous_target/weight`
appear because all are 0, the class default — matching the proposal (all
those dimensions are target 0, weight 0). `comfort_target = 1` is written
(not the 3-default) because it genuinely differs.

## 2. Localisation — CSV, re-import, and compiled translation

Appended exactly the eight lines from proposal §3 to
`content/base/localization/en.csv` (in the existing house style, after the
`scrap_trader` block).

Re-ran the headless import so the stale compiled `.translation` could not
silently miss the new keys:

```
$ /Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
...
[   0% ] reimport | en.csv
[  50% ] reimport | Finalizing Asset Import...
[ DONE ] reimport
```

`en.en.translation` grew from 1668 bytes to 2324 bytes and its mtime moved to
the import run, consistent with new content — but size/mtime alone is not
proof, so the actual resolved strings were queried at runtime (§3 below,
"LOCALISATION" block) rather than trusted from the byte count.

`content/base/localization/en.csv.import` was already tracked and produced
no diff (`git diff --stat -- content/base/localization/en.csv.import` empty).
`en.en.translation` is confirmed gitignored:

```
$ git check-ignore -v content/base/localization/en.en.translation
.gitignore:16:*.translation	content/base/localization/en.en.translation
```

So only `en.csv` (and its already-committed `.import` sidecar) needed to be
part of any commit; the compiled `.translation` is regenerated build output.

## 3. Real-repository load, validate, score, and localisation — full output

Ran via `/tmp/gen_verify.gd` (deleted after use, confirmed in §1), which used
the real `TresContentRepository`, real `ContentValidator`, real `Evaluator`,
and the real compiled `Translation` resource — no hand-built objects.

```
$ /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s /tmp/gen_verify.gd
Godot Engine v4.7.1.stable.official.a13da4feb - https://godotengine.org

=== LOAD ===
problems: []
is_loaded: true
ingredient count: 4
customer count: 3
  ingredient: ingredient.ember_chili_paste
  ingredient: ingredient.neon_noodles
  ingredient: ingredient.rooftop_greens
  ingredient: ingredient.umami_broth
  customer: customer.late_shift_medic
  customer: customer.scrap_trader
  customer: customer.solar_tech

=== VALIDATE (standalone, direct call) ===
validate problems: []

=== SCORE ===
medic + greens alone -> score=75 band=SATISFIED
medic + chili+greens -> score=90 band=DELIGHTED
medic + noodles+greens -> score=65 band=SATISFIED
scrap_trader best: score=90 dishes=["neon_noodles", "neon_noodles+rooftop_greens"]
solar_tech best: score=100 dishes=["neon_noodles+umami_broth", "ember_chili_paste+neon_noodles+umami_broth", "neon_noodles+umami_broth+rooftop_greens"]

=== LOCALISATION ===
  ingredient.rooftop_greens.name -> Rooftop Greens
  ingredient.rooftop_greens.description -> Leafy greens pulled straight from the truck's rooftop planter — crisp, cool, and the closest thing to fresh air on this block.
  customer.late_shift_medic.name -> Late-Shift Medic
  customer.late_shift_medic.request -> Something fresh and light, please — nothing heavy. I've been elbow-deep in triage since second shift and my stomach won't forgive anything rich right now.
  customer.late_shift_medic.reaction.delighted -> Light, clean, and exactly what my stomach needed after a shift like that.
  customer.late_shift_medic.reaction.satisfied -> Good and light — I can actually feel human again.
  customer.late_shift_medic.reaction.mixed -> It's alright, but heavier than I wanted after tonight.
  customer.late_shift_medic.reaction.dissatisfied -> This is way too heavy. My stomach's not going to forgive either of us for this.
```

### Cross-check against `balance.md`

| Claim | balance.md §1b/§2/§3 | This run | Match |
|---|---|---|---|
| `TresContentRepository.load_from` | (not run there — probe built objects in code) | `problems: []`, `is_loaded: true`, 4 ingredients, 3 customers | first real on-disk load, clean |
| `ContentValidator.validate` | (not run there) | `[]` | clean |
| medic + `rooftop_greens` alone | 75 SATISFIED | 75 SATISFIED | **match** |
| medic + `ember_chili_paste+rooftop_greens` | 90 DELIGHTED | 90 DELIGHTED | **match** |
| medic + `neon_noodles+rooftop_greens` | 65 SATISFIED | 65 SATISFIED | **match** |
| `scrap_trader` best (post-change) | 90, dishes `{neon_noodles, neon_noodles+rooftop_greens}` | 90, same two dishes | **match** |
| `solar_tech` best | 100, three tied dishes (`neon_noodles+umami_broth`, `ember_chili_paste+neon_noodles+umami_broth`, `neon_noodles+umami_broth+rooftop_greens`) | 100, same three dishes | **match** |
| Localisation keys (name/description/request + 4 `reaction.<band>`) | text specified in proposal §3 | identical text resolved at runtime through the real compiled `Translation` | **match** |

No mismatch found. This is the first time these numbers were produced from
the actual `.tres` files on disk (via the real repository, validator, and
evaluator) rather than from a probe's in-code objects, and they agree with
`balance.md` exactly.

## 4. `git status` after generation, before the gate run

```
 M README.md
 M content/base/localization/en.csv
?? content/base/customers/late_shift_medic.tres
?? content/base/ingredients/rooftop_greens.tres
?? content/staging/balance.md
?? content/staging/proposal.md
?? docs/crew/
?? docs/worklogs/crew-runs/
```

`README.md`, `content/staging/proposal.md`, `docs/crew/`, and
`docs/worklogs/crew-runs/` were already modified/untracked before this task
started and were not touched by it (consistent with `balance.md` §12's own
statement). This task is responsible only for `en.csv`,
`late_shift_medic.tres`, and `rooftop_greens.tres`.

No stray `.uid` sidecar was created for either new `.tres` — checked directly
(`ls` above): neither new file has a `.uid` file, matching the existing
`ember_chili_paste.tres` / `neon_noodles.tres` / `umami_broth.tres` /
`solar_tech.tres` / `scrap_trader.tres`, none of which carry one either.
`scripts/check.sh`'s "Resource UID sidecars" step only scans `*.gd` files
(confirmed by reading `scripts/check.sh`), so `.tres` files are outside that
check's scope regardless.

## 5. Gate — `./scripts/check.sh` — FAIL, and why it was not worked around

```
$ ./scripts/check.sh
==> Engine version
    PASS 4.7.1.stable.official.a13da4feb

==> Format (gdformat --check)
25 files would be left unchanged
    PASS 25 file(s) formatted

==> Lint (gdlint)
Success: no problems found
    PASS 25 file(s) clean

==> Headless import
    PASS project imports

==> Type and warning check
    PASS 25 file(s) clean

==> Domain purity (no randomness or clock in core/domain)
    PASS core/domain is pure

==> Dependency direction (adapters depend inward)
    PASS no inward-only violations

==> Layout (no empty directories, shared/ needs two consumers)
    PASS layout clean

==> Resource UID sidecars
    PASS sidecars present, tracked, and paired

==> Tests
      = Run Summary
      ==============================================

      res://tests/content/test_phase_1_content.gd
      - test_the_set_is_the_approved_size
          [Failed]:  [4] expected to equal [3]:
                at line 44
          [Failed]:  [3] expected to equal [2]:
                at line 45

      Totals
      ------
      Scripts              10
      Tests               107
      Passing Tests       106
      Failing Tests         1
      Asserts           301/303
      Time              0.491s


      ---- 1 failing tests ----
    FAIL test suite (107 test(s) ran)

1 check(s) failed.
```

Exit code: `1`. 107 tests ran (not zero, so this is a real failure, not a
discovery problem), 106 passed, 1 failed, 2 of 303 asserts failed.

**Root cause.** `tests/content/test_phase_1_content.gd` line 43-45:

```gdscript
func test_the_set_is_the_approved_size() -> void:
	assert_eq(repository.all_ingredients().size(), 3)
	assert_eq(repository.all_customers().size(), 2)
```

This test hard-codes the previously-approved catalogue size (3 ingredients, 2
customers). Adding `rooftop_greens` and `late_shift_medic` — exactly what
`content/staging/proposal.md` §1/§2 and the now-`PASS`ed `balance.md` both
call for — makes the real count 4 and 3, so this specific assertion now fails
by construction. Every other assertion in the same file (per-ingredient
flavour/tag pins, per-customer target/weight pins, the soy-boundary test, the
cross-set band-reachability test) still passes unchanged, because none of
them depend on the catalogue size — only this one line does.

**Why I did not fix it.** The task's explicit list of things I may not do
includes: "modify... `tests/`... ". This assertion is inside `tests/`. Per
the same brief: "Report failure rather than working around it," and "never
weaken a gate check... to make something pass." Editing
`test_the_set_is_the_approved_size()` from `3`/`2` to `4`/`3` would very
plausibly be the *correct* fix once this content is accepted into the shipped
catalogue — the test's own comment block explains it exists precisely to
catch exactly this kind of catalogue change and force someone to look at it
— but making that edit is outside this role's authority as scoped for this
task, so I stopped rather than doing it myself.

**What this means concretely:** the new content loads, validates, and scores
exactly as specified and exactly as `balance.md` predicts (§3 above). The
repository-owned regression gate is red only because a test that intentionally
pins the *previous* approved catalogue size has not yet been updated to
acknowledge the new, larger, accepted catalogue. That update needs to happen
under `tests/`, by whoever owns that directory, as a visible, reviewed change
of its own — for example bumping the two literals to `4`/`3` and adding
pinning assertions for `rooftop_greens` and `late_shift_medic` mirroring the
existing per-ingredient/per-customer tests in the same file — not silently
inside this content-generation pass.

## 6. Summary

| Check | Result |
|---|---|
| `content/staging/balance.md` verdict | **PASS** (confirmed by direct read) |
| `.tres` generation via `ResourceSaver` | done; one dead `ext_resource` line removed post-generation (documented in §1) |
| Localisation CSV + re-import | done; new keys resolve through the real compiled `Translation` (§2, §3) |
| `TresContentRepository.load_from` | zero problems, `is_loaded() == true`, 4 ingredients / 3 customers (§3) |
| `ContentValidator.validate` | zero problems (§3) |
| `Evaluator` scores vs. `balance.md` | exact match on every figure checked (§3) |
| `./scripts/check.sh` | **FAIL** — 1 of 107 tests fails, root cause identified and not worked around (§5) |
| Scratch scripts | both deleted, tree clean (§1, §4) |

**Overall: FAIL**, solely on the gate step, for the reason in §5. No number
from the proposal was changed to make anything pass, no check was weakened,
and no test was edited to force green.
