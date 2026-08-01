# ADR 0003: Use GUT as the headless test framework

- Status: Accepted
- Date: 2026-08-01
- Deciders: Rohan Khanna (human authority); Kitchen Lead (research and recommendation)
- Supersedes: —

## Context

DEC-013 makes automated tests a quality gate, and ADR 0002 requires domain unit
tests, content validation, port contract suites, and golden cases. Issue
[#7](https://github.com/rkhanna24/NeonKitchen-godot/issues/7) must select a
headless framework that runs without opening the editor and returns a nonzero
exit code on failure.

ADR 0001 pins Godot 4.7.1, so any candidate must support that exact release
rather than "Godot 4.x". Two mature MIT-licensed options qualified, both actively
maintained and both exporting JUnit XML:

| | GUT | gdUnit4 |
|---|---|---|
| Latest | v9.7.1, 2026-07-10 | v6.2.0, 2026-07-28 |
| 4.7.1 support | Yes, `godot_4_7` branch | Yes, stated explicitly |
| Versioning | One branch per Godot minor | One tag spans 4.5–4.7.1 |
| CI | Hand-written workflow | Official GitHub Action |
| Repository | `bitwes/Gut` | `godot-gdunit-labs/gdUnit4` |

## Decision

Use **GUT v9.7.1** from the `godot_4_7` branch, pinned to commit
`aeb5d4f3f7f0a6c9b5e178876d6c99b791fda605`.

Vendor `addons/gut/` into the repository and commit it. Godot addons have no
package manager, and vendoring makes a clean checkout reproducible with no
fetch step. Record the version and commit in this ADR; changing either requires
updating this record.

### Rationale

GUT is the better fit for the architecture ADR 0002 ratified. gdUnit4's main
advantages — mocking, spying, and orphan detection — target problems this
project has already designed away. ADR 0002 §5 requires a real in-memory test
adapter for `ContentRepository`, so port seams are exercised with genuine
substitutes rather than mocks. Orphan detection targets `Node` leaks, and the
domain is `RefCounted`.

The remaining differentiator was CI convenience, which is a one-time cost of
roughly ten lines of workflow, weighed against carrying a larger dependency for
the project's lifetime.

GUT's branch-per-Godot-minor model is not a meaningful drawback here. ADR 0001
already requires a superseding ADR before adopting a new Godot minor, so a GUT
branch change happens exactly when that ADR is being written.

### Headless command

```text
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit
```

`-gexit` makes the runner quit when finished and return a nonzero exit code on
failure, which is what CI and the `AGENTS.md` verification block require.

### Test placement and naming

Directories follow the ADR 0002 §6 layout:

| Directory | Contents |
|---|---|
| `tests/unit/` | Domain rules, state transitions, invariants |
| `tests/content/` | Content validation: IDs, ranges, references, schema versions |
| `tests/contract/` | Port contract suites run against every implementation |
| `tests/golden/` | Golden cases: recorded inputs and expected outcomes |

Conventions:

- test files are named `test_<subject>.gd` and extend `GutTest`;
- test methods are named `test_<expected_behaviour>()`;
- a port contract suite is written once as a base class and subclassed per
  implementation, so the `.tres` repository and the in-memory repository run
  the identical suite;
- tests never construct `Node`s for pure domain coverage.

## Alternatives Considered

**gdUnit4 v6.2.0.** Rejected as described above: richer than needed, with its
differentiating features aimed at problems the DI architecture avoids. It
remains the stronger option if CI convenience or its inspector tooling later
outweigh footprint. Reconsidering it would supersede this ADR.

**A minimal custom harness.** Rejected. It would mean reimplementing discovery,
assertions, reporting, and exit-code handling — real cost on a five-week
schedule against two mature MIT tools.

**GUT `main` branch.** Rejected: `main` targets Godot 4.6.x, not the pinned
4.7.1.

## Consequences

**Enabled**

- A clean checkout runs tests headlessly with no fetch step.
- Port contract suites can run one shared suite against multiple adapters.
- JUnit XML output is available to CI without extra tooling.

**Required**

- Issue #2 writes the CI workflow invoking the command above, and replaces the
  `<repository headless test command>` placeholder in `AGENTS.md`.
- `addons/` is committed, so `.gitignore` must not exclude it. GUT ships `.uid`
  files, which are committed per rule 11.
- Adopting a new Godot minor requires switching the GUT branch in the same ADR
  that adopts the engine version.

**Sequencing constraint**

GUT's runner requires a Godot project. The repository has no `project.godot`
yet, which issue #2 creates. The decision, pin, and conventions above are
complete and independent, but the executable smoke test and the nonzero-exit
demonstration cannot be verified until #2 lands.

## Verification

- `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit` runs
  from a clean checkout without opening the editor.
- A deliberately failing test produces a nonzero exit code; removing it restores
  a zero exit.
- The vendored `addons/gut/` matches GUT v9.7.1 at commit
  `aeb5d4f3f7f0a6c9b5e178876d6c99b791fda605`.
