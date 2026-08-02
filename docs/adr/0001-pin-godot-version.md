# ADR 0001: Pin Godot 4.7.1 and the Phase 1 platform matrix

- Status: Accepted
- Date: 2026-07-31
- Deciders: Rohan Khanna (human authority); Kitchen Lead (recommendation)
- Supersedes: —

## Context

`AGENTS.md`, the game design document, and
[Technical Architecture](../technical_architecture.md) all target an ambiguous
"Godot 4.x". Worklog question Q-006 and issue
[#11](https://github.com/rkhanna24/NeonKitchen-godot/issues/11) require an exact
engine build and platform matrix before repository scaffolding, so that a fresh
environment can reproduce the toolchain without relying on conversation history.

Evidence gathered on 2026-07-31:

| Fact | Value |
|---|---|
| Current stable release | 4.7.1, published 2026-07-14 |
| Previously installed locally | 4.6.3.stable.official.7d41c59c4, published 2026-05-20 |
| Development host | macOS 26.5.2, arm64 (Apple Silicon) |
| macOS editor distribution | Universal binary (arm64 + x86_64) |
| Latest GDScript Toolkit | 4.5.0, published 2025-10-09 |

The decisive constraint is Godot's release policy: a stable branch is supported
actively only until its successor's first patch release, after which it drops to
partial support, and the branch before that reaches end of life. Because 4.7.1
is 4.7's first patch release, the 4.6 branch moved to partial support on
2026-07-14 and 4.5 is now end of life.

Two conditions make this the cheapest possible moment to choose:

1. the repository contains no `project.godot`, so adopting a different build
   costs a download and no migration; and
2. Phase 1 is a headless GDScript prototype that exercises no rendering,
   physics, or navigation code, which is where new-minor regressions normally
   concentrate.

## Decision

1. Pin **Godot 4.7.1, stable, official, standard (non-.NET) build** as the
   engine for Phase 1 and the capstone.
2. Use the **standard GDScript editor**, not the .NET editor. This confirms the
   existing GDScript-default position in Technical Architecture §13.1 and
   DEC-002.
3. Record the **Phase 1 platform matrix** as:

   | Role | Platform | Meaning |
   |---|---|---|
   | Development | macOS 26.x, arm64 | Editor, headless import, and test execution |
   | Continuous integration | Linux x86_64, headless | Same 4.7.1 version, no editor GUI |
   | Supported export target | macOS, arm64 | Exported and verified before release |
   | Supported export target | Windows, x86_64 | Exported and verified before release |
   | Untested | Linux desktop | May work; not exported or verified in capstone scope |

   "Supported" means an export is produced and launched as part of verification.
   Linux desktop is deliberately best-effort so the week-5 release milestone
   does not acquire a third verification target.

   > **Status as of 2026-08-01: not yet exercised.** No export has been produced
   > on any platform. Export templates are not installed and no
   > `export_presets.cfg` exists. This table states an intent for the release
   > milestone, not a verified capability, and the two are easy to conflate when
   > reading a table of "supported" targets. macOS distribution outside the
   > development machine may additionally require notarisation, whose cost is
   > unknown and unbudgeted.

4. Adopt this **upgrade policy**:
   - **Patch releases within 4.7.x are accepted** after a headless import and a
     full pass of the repository's checks on the new build. Record the new exact
     version in this ADR's revision table.
   - **A new minor release (4.8 or later) requires a superseding ADR.** It is
     not adopted mid-milestone merely because it is current.
   - **A regression traced to the pinned build** may justify an out-of-policy
     move, recorded as a superseding ADR with the failing evidence.
   - Adopting the .NET editor or C# remains governed by Technical Architecture
     §13.2 and requires its own ADR.

## Alternatives Considered

**Pin 4.6.3, the already-installed build.** Zero setup cost and a build already
run locally. Rejected because 4.6 is on partial support as of 2026-07-14 and
reaches end of life when 4.8.1 ships, which would likely land the capstone on an
unmaintained branch while still paying an upgrade cost later — with code
written, rather than now with none.

**Pin 4.7.1 but hard-freeze the exact build.** Maximum reproducibility.
Rejected because it forgoes compatibility-preserving bugfixes that could cost
days on a five-week solo schedule.

**Track latest stable, including minors.** Always current. Rejected because a
minor version bump mid-capstone is precisely the churn this schedule can least
absorb.

**macOS-only export.** One export path and one test target. Rejected because the
GDD requires at least five observed playtests and a submitted build; testers and
graders are likely to be on Windows.

**All three desktop platforms as supported.** Widest reach. Rejected because it
triples export verification and requires a Linux test environment that does not
currently exist, while the GDD's week-5 milestone calls for one exported desktop
build.

## Consequences

**Enabled**

- A fresh environment can install the exact editor and runtime from this record.
- The project stays on the actively supported branch through the capstone
  window. The 4.6-to-4.7 interval was approximately five months, so 4.8 is
  unlikely to ship before release.
- Issues [#2](https://github.com/rkhanna24/NeonKitchen-godot/issues/2) and
  [#7](https://github.com/rkhanna24/NeonKitchen-godot/issues/7) can pin CI and
  the test harness to a concrete version.

**Required**

- Install Godot 4.7.1 standard locally; 4.6.3 is superseded as the project
  build.
- CI must obtain the same 4.7.1 version as a Linux headless build.
- Issue #2 must resolve how `godot` is invoked. The binary is not on `PATH`
  today, so the verification commands in `AGENTS.md`
  (`godot --headless --path . --import`) are not runnable as written. Choose a
  documented `PATH` entry or a `GODOT_BIN` environment variable and update
  `AGENTS.md` accordingly.
- Issue #2 must **verify** rather than assume GDScript Toolkit compatibility.
  gdtoolkit 4.5.0 predates both 4.6 and 4.7. The risk is assessed as low —
  4.7's only GDScript language change is Android Java-interface support — but
  DEC-013 makes `gdformat` and `gdlint` a merge gate, so the gate must be
  demonstrated working on project code. If a specific new syntax breaks the
  toolkit, prefer avoiding that syntax over disabling the gate.
- Export presets and signing remain out of scope here and belong to the release
  milestone. macOS distribution outside the development machine may require
  notarization; this is not a Phase 1 concern.

**Deferred**

- Linux desktop verification.
- Any .NET or C# toolchain.
- Export preset configuration and code signing.

## Verification

- The engine reports `4.7.1.stable.official.a13da4feb` on the development machine
  and in CI. Verified locally on 2026-07-31: the downloaded archive matched the
  published SHA512 sum, the bundle contains no .NET/Mono components, it is a
  universal (arm64 + x86_64) binary, and `--headless --quit` exits 0.
- The pinned version imports the project headlessly once `project.godot` exists
  (issue #2).
- `AGENTS.md` and the CI workflow name this exact version, with no remaining
  reference to an unqualified "Godot 4.x" toolchain requirement.
- A fresh checkout plus this ADR is sufficient to reconstruct the toolchain.

## Revision Table

| Date | Version in effect | Note |
|---|---|---|
| 2026-07-31 | `4.7.1.stable.official.a13da4feb` | Initial pin; installed and verified locally |

Installed on the development machine at
`/Applications/Godot.app/Contents/MacOS/Godot`. The superseded 4.6.3 bundle and
its version-scoped editor settings and doc cache were removed on 2026-07-31, so
4.7.1 is the only Godot installation present.

This path is recorded as environment evidence, not as a project convention. The
binary is not on `PATH`, so issue #2 must still choose and document how the
engine is invoked by the project's verification commands. Because the bundle name
is unversioned, that decision must **assert the version** rather than infer it
from the path — see the Verification section.
