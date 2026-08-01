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

Install it with `scripts/setup.sh`, which fetches the pinned commit into
`addons/gut`. **`addons/` is gitignored; GUT is not committed.**

Godot has no package manager, so `scripts/setup.sh` is ours. It treats both
project dependencies identically — pin an exact version, fetch it, verify it —
so gdtoolkit and GUT are managed the same way rather than by two different
philosophies.

Verification uses `git rev-parse HEAD` against the pinned commit. Git is
content-addressed, so matching the SHA is a cryptographic integrity check.
GitHub's generated tarballs are deliberately not used: they are not guaranteed
byte-stable, so their checksums can change without the content changing.

`scripts/check.sh` **fails** when `addons/gut` is absent rather than skipping the
test step, so a fresh clone that has not run setup gets a red gate telling it
what to do, instead of a green run with zero tests.

> **Revised 2026-08-01, before this ADR was published.** The first draft vendored
> `addons/gut/` into the repository, on the grounds that Godot has no package
> manager and vendoring needs no fetch step. That would have committed 259
> third-party files and 3.2 MB, and — more tellingly — it was inconsistent with
> gdtoolkit, which was already pinned-and-fetched rather than vendored. The
> choice of GUT is unchanged; only its installation mechanism is.
>
> Git submodules were evaluated and rejected on structure, not preference. GUT's
> repository root is itself a complete Godot project, including its own
> `project.godot`. A submodule at `addons/gut` would nest a second Godot project
> inside this one; installing to `third_party/` instead would still require a
> copy step and clones 6.4 MB to obtain the 3.2 MB that is needed.

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
godot --headless --path . -s addons/gut/gut_cmdln.gd \
    -gdir=res://tests -ginclude_subdirs -gexit
```

`-gexit` makes the runner quit when finished and return a nonzero exit code when
a test fails. Verified: a deliberately failing assertion produces exit 1.

> **Correction, 2026-08-01.** This command was first recorded without
> `-ginclude_subdirs`. GUT does not recurse into subdirectories by default, so
> with the ADR 0002 §6 layout — `tests/unit`, `tests/content`, `tests/contract`,
> `tests/golden` — it discovered nothing, reported "Nothing was run", **and still
> exited 0**. The decision to use GUT is unchanged; only the recorded invocation
> was incomplete.

That asymmetry matters and is guarded in `scripts/check.sh`: GUT exits nonzero
when a test *fails*, but exits zero when no tests are *found*. Broken discovery
would otherwise pass CI silently with zero coverage. The gate therefore parses
the run summary and fails when the test count is zero.

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

- The repository contains no third-party source. Upgrading GUT is a one-line
  change to the pinned commit, not a 259-file diff.
- Port contract suites can run one shared suite against multiple adapters.
- JUnit XML output is available to CI without extra tooling.

**Required**

- A fresh clone must run `./scripts/setup.sh` before `./scripts/check.sh`. This
  needs network access once; afterwards the working copy is self-contained.
- CI runs the same setup script, so it exercises the same path a developer does.
- Adopting a new Godot minor requires switching the GUT branch and commit in the
  same ADR that adopts the engine version.

**Accepted trade-off**

Vendoring would survive GitHub being unreachable and needs no setup step. That
robustness is given up in exchange for a repository that contains only this
project's code. The pinned commit and SHA verification preserve reproducibility,
which was vendoring's substantive advantage.

**Sequencing constraint**

GUT's runner requires a Godot project. The repository has no `project.godot`
yet, which issue #2 creates. The decision, pin, and conventions above are
complete and independent, but the executable smoke test and the nonzero-exit
demonstration cannot be verified until #2 lands.

## Verification

- `./scripts/check.sh` runs from a clean checkout without opening the editor.
- A deliberately failing test produces a nonzero exit code; removing it restores
  a zero exit. **Verified 2026-08-01.**
- A run that discovers no tests fails the gate. **Verified 2026-08-01.**
- The vendored `addons/gut/` matches GUT v9.7.1 at commit
  `aeb5d4f3f7f0a6c9b5e178876d6c99b791fda605`; `addons/gut/plugin.cfg` reports
  `version="9.7.1"`.
