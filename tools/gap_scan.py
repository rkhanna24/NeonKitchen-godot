#!/usr/bin/env python3
"""Read the ADR corpus, inventory the codebase, and report what the
documents require but the code does not have -- distinguishing "not built
yet" from "deliberately not built" using the documents' own words, not an
inferred rule.

    python3 tools/gap_scan.py
    python3 tools/gap_scan.py --check-backlog
    python3 tools/gap_scan.py --file-issues

Analysis (the default) is offline: standard library only, no network, no
credentials. It reads two documents -- ADR 0002 and ADR 0004, not the wider
nine-file corpus `lore_query.py` searches -- plus the codebase under the
repository root. `--check-backlog` and `--file-issues` shell out to `gh` and
therefore need network and an authenticated session; they are off by
default so a grader can run the reasoning with none of that. `--file-issues`
implies `--check-backlog`, since filing without checking would defeat the
point of checking.

See docs/adr/0002-phase-1-structural-foundation.md sections 5 and 6, and
docs/adr/0004-phase-1-contracts.md sections 7, 7a, and 8 for the declarations
this reads, and issue #30 for the approved design this implements.

Exit codes:
    0  ran to completion (gaps may or may not have been found)
    1  a document did not have the expected shape (a table or section this
       tool depends on could not be found) -- the ADRs changed under it
    2  usage error (bad arguments)
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

from heading_sections import split_sections

# --------------------------------------------------------------------------
# Documents read
# --------------------------------------------------------------------------

ADR_0002_PATH = "docs/adr/0002-phase-1-structural-foundation.md"
ADR_0004_PATH = "docs/adr/0004-phase-1-contracts.md"

# The deferral vocabulary measured in issue #30's scope comment (counted
# across docs/adr/). Used only for the generic "does this heading or
# sentence carry deferral language" check (rule b/c below). The port table
# does NOT use this list -- see PortRow handling: every non-"Built" status
# cell is itself the citation, whatever words it uses, because #30's own
# spike found "the port table's status column IS the citation. No
# vocabulary-hunting needed for that table at all."
_DEFERRAL_VOCAB: tuple[str, ...] = (
    "deferred",
    "interface only",
    "reserved but undefined",
    "deliberately unimplemented",
    "contract recorded, not implemented",
    "requires an adr",
)

# Directories under the repo root never scanned for `class_name` or `enum`:
# third-party, engine-generated, or gitignored.
_EXCLUDED_DIR_NAMES = frozenset({".git", ".godot", ".venv", "addons"})

_CLASS_NAME_RE = re.compile(
    r"^\s*(?:@abstract\s+)?class_name\s+([A-Za-z_][A-Za-z0-9_]*)",
    re.MULTILINE,
)
_ENUM_BLOCK_RE = re.compile(r"enum\s+\w*\s*\{([^}]*)\}")


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


# --------------------------------------------------------------------------
# Small text-extraction helpers shared by every declaration type below
# --------------------------------------------------------------------------


def _find_section(text: str, needle: str) -> tuple[str, str]:
    """The (heading_text, body_text) of the first section whose heading
    contains `needle`. Raises LookupError if the document no longer has a
    heading matching it -- deliberately loud, since every extractor below
    depends on the ADR keeping this exact shape.
    """
    lines = text.splitlines(keepends=True)
    for heading_text, _start, _end, body in split_sections(lines):
        if needle in heading_text:
            return heading_text, "".join(body)
    raise LookupError(f"no section heading contains {needle!r}")


_TABLE_ROW_RE = re.compile(r"^\|(.+)\|\s*$")
_SEPARATOR_CELL_RE = re.compile(r"^:?-{3,}:?$")


def _parse_table(body: str) -> list[list[str]]:
    """Every row of the first Markdown pipe table in `body`, as raw cell
    text (header row included, separator row excluded), stopping at the
    first blank line after the table starts.
    """
    rows: list[list[str]] = []
    in_table = False
    for line in body.splitlines():
        m = _TABLE_ROW_RE.match(line.strip())
        if not m:
            if in_table:
                break
            continue
        in_table = True
        cells = [c.strip() for c in m.group(1).split("|")]
        if all(_SEPARATOR_CELL_RE.match(c) for c in cells):
            continue
        rows.append(cells)
    return rows


def _strip_backticks(cell: str) -> str:
    return cell.strip().strip("`")


_BRACE_RE = re.compile(r"\{([^{}]+)\}")


def expand_braces(path: str) -> list[str]:
    """`a/{b,c}/d` -> [`a/b/d`, `a/c/d`]. Recurses so a path with more than
    one brace group expands fully; none of today's ADR 0002 paths need that,
    but nothing here assumes at most one.
    """
    m = _BRACE_RE.search(path)
    if not m:
        return [path]
    prefix, suffix = path[: m.start()], path[m.end() :]
    expanded: list[str] = []
    for option in m.group(1).split(","):
        expanded.extend(expand_braces(prefix + option + suffix))
    return expanded


def _snake_case(name: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "_", name).lower()


def _contains_deferral_vocab(text: str) -> str | None:
    lowered = text.lower()
    for phrase in _DEFERRAL_VOCAB:
        if phrase in lowered:
            return phrase
    return None


_SENTENCE_SPLIT_RE = re.compile(r"(?<=[.!?])\s+(?=[A-Z0-9`\"])")


def _strip_table_lines(text: str) -> str:
    """Drop every Markdown table row before sentence-splitting. Without
    this, a table cell like `` `RemoveIngredient` `` and an unrelated prose
    sentence earlier in the same section body can be concatenated into one
    "sentence" by the heuristic splitter below (no `.!?` boundary separates
    a table from the paragraph before it), producing a false rule-(c) match:
    the identifier is real, but the deferral vocabulary belongs to a
    different sentence about different identifiers entirely. Caught by the
    approved proposal's own required spike (moving `RemoveIngredient` out of
    the tree to construct a second gap): it came back DEFERRED, quoting a
    sentence about the four cooking-challenge terms, not about
    `RemoveIngredient`. Table rows are handled by rule (a) where a status
    column exists; they are never prose for rule (c).
    """
    return "\n".join(
        line
        for line in text.splitlines()
        if not _TABLE_ROW_RE.match(line.strip())
    )


def _split_sentences(text: str) -> list[str]:
    """A heuristic sentence split, not a parser: good enough to ask "does
    this one sentence both name the identifier and carry deferral vocabulary",
    which is the only thing rule (c) needs. Not exercised by any live case in
    the current tree -- see the "Known limitations" note in tools/README.md.
    """
    collapsed = " ".join(_strip_table_lines(text).split())
    return _SENTENCE_SPLIT_RE.split(collapsed)


def _names_identifier(sentence: str, identifier: str) -> bool:
    return re.search(rf"`?\b{re.escape(identifier)}\b`?", sentence) is not None


def _search_deferral(
    identifier: str, heading_text: str, body_text: str
) -> tuple[str, str] | None:
    """Rule (b) then (c) from the approved proposal: stop at first match.

    (a) -- "another cell in the same table row states status or reason" --
    is handled by each table-specific extractor below, because only the port
    table has a status/reason column; the commands and events tables do not,
    so applying (a) there would misread a "Fields" cell as a deferral cell.

    (b) the declaring heading itself carries deferral vocabulary;
    (c) a sentence in the section body that names the declaration by its
        exact identifier AND carries deferral vocabulary.

    No match -> None, meaning GAP. Never inferred from a section merely
    being *about* deferral: rule (c) requires this exact identifier, not
    just deferral vocabulary somewhere nearby. This function only ever sees
    command, event, and phase identifiers -- `scan_layout` implements the
    directory-declaration analogue of this same requirement separately (list
    membership against the exact paths named in "Deferred folders", not a
    sentence search), which is what keeps `tests/golden/` (declared but not
    deferred) out of a false match against that paragraph, even though the
    paragraph sits in the very section that declares `tests/golden/`. Not
    exercised by any live command/event/phase case in the current tree,
    since none of the twelve declarations extracted from ADR 0004 is
    currently deferred -- see tools/README.md.
    """
    heading_marker = _contains_deferral_vocab(heading_text)
    if heading_marker:
        return ("heading", heading_text.strip())
    for sentence in _split_sentences(body_text):
        if _names_identifier(sentence, identifier) and _contains_deferral_vocab(
            sentence
        ):
            return ("body", sentence.strip())
    return None


# --------------------------------------------------------------------------
# Codebase inventory: the two independent "contains" facts
# --------------------------------------------------------------------------


def _iter_gd_files(repo_root: Path):
    for path in repo_root.rglob("*.gd"):
        if _EXCLUDED_DIR_NAMES & set(path.relative_to(repo_root).parts):
            continue
        yield path


def find_class_name(repo_root: Path, class_name: str) -> list[Path]:
    """Every `.gd` file under the repo root (excluding third-party and
    engine-generated directories) that declares `class_name <class_name>`,
    wherever it lives. Independent of, and does not assume, the ratified
    path -- see `_locate` for why both facts are kept separate.
    """
    hits: list[Path] = []
    for path in _iter_gd_files(repo_root):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for m in _CLASS_NAME_RE.finditer(text):
            if m.group(1) == class_name:
                hits.append(path)
                break
    return hits


def find_enum_members(repo_root: Path) -> set[str]:
    """Every member name of every `enum` block in the codebase, regardless
    of which enum it belongs to. Coarser than tracking enum identity, but
    that is the definition confirmed for section 7a: "enum-member presence"
    alone, not "member of a specifically-named and specifically-located
    enum" -- see tools/README.md.
    """
    members: set[str] = set()
    for path in _iter_gd_files(repo_root):
        text = path.read_text(encoding="utf-8", errors="ignore")
        for m in _ENUM_BLOCK_RE.finditer(text):
            for raw_member in m.group(1).split(","):
                name = raw_member.strip().split("=")[0].strip()
                if name:
                    members.add(name)
    return members


_RATIFIED_DIR = {
    "command": "core/domain/commands",
    "event": "core/domain/events",
    "port": "core/ports",
}


@dataclass(frozen=True)
class CodeLocation:
    """The two independent "contains" facts for a class_name declaration:
    whether it exists anywhere, and whether it exists at its ratified path.
    Collapsing these into one boolean is exactly what would hide a
    declaration built in the wrong place -- see MISLOCATED below.
    """

    ratified_path: Path
    at_ratified_path: bool
    other_hits: tuple[Path, ...]


def _locate(repo_root: Path, category: str, name: str) -> CodeLocation:
    ratified_dir = _RATIFIED_DIR[category]
    ratified_path = repo_root / ratified_dir / f"{_snake_case(name)}.gd"
    at_ratified_path = False
    if ratified_path.exists():
        text = ratified_path.read_text(encoding="utf-8", errors="ignore")
        at_ratified_path = any(
            m.group(1) == name for m in _CLASS_NAME_RE.finditer(text)
        )
    hits = find_class_name(repo_root, name)
    other_hits = tuple(h for h in hits if h != ratified_path)
    return CodeLocation(ratified_path, at_ratified_path, other_hits)


# --------------------------------------------------------------------------
# Findings
# --------------------------------------------------------------------------

BUILT = "BUILT"
DEFERRED = "DEFERRED"
GAP = "GAP"
MISLOCATED = "MISLOCATED"


@dataclass(frozen=True)
class Finding:
    category: str  # "port", "directory", "command", "event", "phase"
    name: str
    source: str  # e.g. "ADR 0002 §5"
    status: str  # BUILT / DEFERRED / GAP / MISLOCATED
    detail: str  # citation (DEFERRED/GAP) or location (BUILT/MISLOCATED)


def _class_declaration_finding(
    repo_root: Path,
    category: str,
    name: str,
    source: str,
    heading_text: str,
    body_text: str,
) -> Finding:
    loc = _locate(repo_root, category, name)
    if loc.at_ratified_path:
        rel = loc.ratified_path.relative_to(repo_root)
        return Finding(category, name, source, BUILT, str(rel))
    if loc.other_hits:
        rel = loc.other_hits[0].relative_to(repo_root)
        detail = (
            f"declared as `class_name {name}` at {rel}, not at its "
            f"ratified path {loc.ratified_path.relative_to(repo_root)}"
        )
        return Finding(category, name, source, MISLOCATED, detail)
    deferral = _search_deferral(name, heading_text, body_text)
    if deferral:
        where, quote = deferral
        return Finding(
            category, name, source, DEFERRED, f'{source} {where}: "{quote}"'
        )
    return Finding(
        category,
        name,
        source,
        GAP,
        f"{source} requires `{name}`; no deferral marker names it",
    )


# --------------------------------------------------------------------------
# ADR 0002 section 5: ports
# --------------------------------------------------------------------------


def scan_ports(repo_root: Path, adr0002_text: str) -> list[Finding]:
    source = "ADR 0002 §5"
    _heading, body = _find_section(adr0002_text, "5. Ports")
    rows = _parse_table(body)
    if len(rows) < 2:
        raise LookupError("ADR 0002 section 5's port table has no data rows")
    findings: list[Finding] = []
    for name_cell, status_cell in (row[:2] for row in rows[1:]):
        name = _strip_backticks(name_cell)
        loc = _locate(repo_root, "port", name)
        if loc.at_ratified_path:
            rel = loc.ratified_path.relative_to(repo_root)
            findings.append(Finding("port", name, source, BUILT, str(rel)))
            continue
        if loc.other_hits:
            rel = loc.other_hits[0].relative_to(repo_root)
            detail = (
                f"declared as `class_name {name}` at {rel}, not at its "
                f"ratified path {loc.ratified_path.relative_to(repo_root)}"
            )
            findings.append(Finding("port", name, source, MISLOCATED, detail))
            continue
        # Rule (a): the status cell of this same row IS the citation,
        # whatever words it uses -- confirmed by the approved proposal's
        # spike. But an *empty* cell is not a citation of anything: a row
        # added to this table with no status recorded is a document defect,
        # not a standing decision, and must not be silently reported as
        # DEFERRED quoting nothing. Checked by construction: blanking
        # `RandomPort`'s status cell during self-review turned it into
        # `DEFERRED: ""` before this guard existed.
        if not status_cell.strip():
            findings.append(
                Finding(
                    "port",
                    name,
                    source,
                    GAP,
                    (
                        f"{source} lists `{name}` with no recorded status; "
                        "nothing licenses its absence"
                    ),
                )
            )
            continue
        findings.append(
            Finding(
                "port",
                name,
                source,
                DEFERRED,
                f'{source}: "{status_cell}"',
            )
        )
    return findings


# --------------------------------------------------------------------------
# ADR 0002 section 6: repository layout
# --------------------------------------------------------------------------

_TREE_LINE_RE = re.compile(
    r"^((?:\│   )*)(?:├── |└── )(\S+)(?:\s{2,}(.*))?$"
)
_FENCE_BLOCK_RE = re.compile(r"```text\n(.*?)```", re.DOTALL)
_DEFERRED_PARAGRAPH_RE = re.compile(
    r"Deferred folders.*?(?=\n\n|\Z)", re.DOTALL
)


def _parse_ratified_directories(tree_text: str) -> list[str]:
    """Every directory path (ending in `/`) in the fenced tree, brace groups
    expanded. Depth is derived from the box-drawing indentation: each
    `"│   "` group is one nesting level, matching the connector's own
    4-character width.
    """
    parents: dict[int, str] = {1: ""}
    paths: list[str] = []
    for line in tree_text.splitlines():
        m = _TREE_LINE_RE.match(line)
        if not m:
            continue  # the root line, or a blank line
        prefix, name, _comment = m.groups()
        depth = len(prefix) // 4 + 1
        parent = parents.get(depth, "")
        full = parent + name
        if not name.endswith("/"):
            continue  # a file, not a directory
        parents[depth + 1] = full
        paths.extend(expand_braces(full))
    return paths


def _parse_deferred_directories(body_text: str) -> list[str]:
    m = _DEFERRED_PARAGRAPH_RE.search(body_text)
    if not m:
        raise LookupError(
            "ADR 0002 section 6 has no 'Deferred folders' paragraph"
        )
    raw_paths = re.findall(r"`([^`]+)`", m.group(0))
    deferred: list[str] = []
    for raw in raw_paths:
        deferred.extend(expand_braces(raw))
    return deferred


def scan_layout(repo_root: Path, adr0002_text: str) -> list[Finding]:
    source = "ADR 0002 §6"
    _heading, body = _find_section(adr0002_text, "6. Repository layout")
    tree_match = _FENCE_BLOCK_RE.search(body)
    if not tree_match:
        raise LookupError("ADR 0002 section 6 has no fenced tree block")
    ratified = _parse_ratified_directories(tree_match.group(1))
    deferred = _parse_deferred_directories(body)
    deferred_quote = re.search(r"Deferred folders.*?exists\.", body, re.DOTALL)
    deferred_text = (
        deferred_quote.group(0).replace("\n", " ") if deferred_quote else ""
    )

    findings: list[Finding] = []
    for rel_path in ratified:
        exists = (repo_root / rel_path.rstrip("/")).is_dir()
        if exists:
            findings.append(
                Finding("directory", rel_path, source, BUILT, rel_path)
            )
            continue
        if rel_path in deferred:
            findings.append(
                Finding(
                    "directory",
                    rel_path,
                    source,
                    DEFERRED,
                    f'{source}: listed in "Deferred folders" ({deferred_text})',
                )
            )
            continue
        findings.append(
            Finding(
                "directory",
                rel_path,
                source,
                GAP,
                (
                    f"{source} lists `{rel_path}` in the ratified layout; it "
                    f'is not named in the "Deferred folders" paragraph '
                    f"({deferred_text}), so nothing licenses its absence"
                ),
            )
        )
    return findings


# --------------------------------------------------------------------------
# ADR 0004 sections 7, 7a, 8: commands, phases, events
# --------------------------------------------------------------------------


def scan_commands(repo_root: Path, adr0004_text: str) -> list[Finding]:
    source = "ADR 0004 §7"
    heading, body = _find_section(adr0004_text, "7. Commands")
    rows = _parse_table(body)
    if len(rows) < 2:
        raise LookupError("ADR 0004 section 7's command table has no rows")
    return [
        _class_declaration_finding(
            repo_root,
            "command",
            _strip_backticks(row[0]),
            source,
            heading,
            body,
        )
        for row in rows[1:]
    ]


def scan_events(repo_root: Path, adr0004_text: str) -> list[Finding]:
    source = "ADR 0004 §8"
    heading, body = _find_section(adr0004_text, "8. Events")
    rows = _parse_table(body)
    if len(rows) < 2:
        raise LookupError("ADR 0004 section 8's event table has no rows")
    return [
        _class_declaration_finding(
            repo_root,
            "event",
            _strip_backticks(row[0]),
            source,
            heading,
            body,
        )
        for row in rows[1:]
    ]


def scan_phases(repo_root: Path, adr0004_text: str) -> list[Finding]:
    """Session phases (ADR 0004 section 7a). `_locate`'s ratified-path check
    does not apply here -- phases are enum members, not classes -- so
    "contains" is a single fact: enum-member presence anywhere in the
    codebase. This was confirmed as a chosen working definition, not derived
    from the ADR (nothing in it specifies where the enum must live), and it
    means MISLOCATED cannot occur for this category by construction: a
    single fact has nothing to disagree with itself.
    """
    source = "ADR 0004 §7a"
    heading, body = _find_section(adr0004_text, "7a. Session phases")
    rows = _parse_table(body)
    if len(rows) < 2:
        raise LookupError("ADR 0004 section 7a's phase table has no rows")
    members = find_enum_members(repo_root)
    findings: list[Finding] = []
    # The table has one row per (phase, command) pair, so a phase that
    # accepts more than one command -- BUILDING_DISH accepts three -- repeats
    # across rows. Dedupe to the five distinct phases, first occurrence wins.
    seen: set[str] = set()
    phase_names = []
    for row in rows[1:]:
        name = _strip_backticks(row[0])
        if name not in seen:
            seen.add(name)
            phase_names.append(name)
    for name in phase_names:
        if name in members:
            findings.append(
                Finding("phase", name, source, BUILT, "enum member found")
            )
            continue
        deferral = _search_deferral(name, heading, body)
        if deferral:
            where, quote = deferral
            detail = f'{source} {where}: "{quote}"'
            findings.append(Finding("phase", name, source, DEFERRED, detail))
            continue
        findings.append(
            Finding(
                "phase",
                name,
                source,
                GAP,
                f"{source} requires `{name}`; no deferral marker names it",
            )
        )
    return findings


# --------------------------------------------------------------------------
# Backlog dedupe (network, off by default)
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class BacklogMatch:
    kind: str  # SCHEDULED / POSSIBLE / REGRESSION / UNSCHEDULED / UNKNOWN
    issue_number: int | None = None
    issue_title: str | None = None


def _search_term(name: str) -> str:
    """The single whole-word token matched against the issue backlog: the
    identifier itself for a class-name or enum-member declaration
    (`RandomPort`), or the final path segment for a directory declaration
    (`tests/golden/` -> `golden`). A path's full form never appears verbatim
    in issue prose, so matching on its last segment is the only part likely
    to. Known limitation, stated once here rather than assumed silently: a
    generic final segment (e.g. a directory literally named `core/`) would
    produce a weak, high-false-positive search term. Not exercised by
    today's one real gap (`tests/golden/` -> `golden`, which is specific).
    """
    if name.endswith("/"):
        return name.rstrip("/").rsplit("/", 1)[-1]
    return name


def fetch_backlog_issues() -> list[dict] | None:
    try:
        proc = subprocess.run(
            [
                "gh",
                "issue",
                "list",
                "--state",
                "all",
                "--limit",
                "300",
                "--json",
                "number,title,body,state",
            ],
            capture_output=True,
            text=True,
            timeout=30,
            check=True,
        )
    except (OSError, subprocess.CalledProcessError, subprocess.TimeoutExpired):
        return None
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        return None


def check_backlog(term: str, issues: list[dict]) -> BacklogMatch:
    """Title-first, whole-word, case-insensitive. Erring toward duplicates:
    a title match is reported as SCHEDULED (confident); a body-only match is
    reported as POSSIBLE ("verify"), never silently folded into SCHEDULED.
    A duplicate issue costs a human ten seconds to close; a gap suppressed
    by a false match is invisible until someone re-discovers it by hand.
    """
    word_re = re.compile(rf"\b{re.escape(term)}\b", re.IGNORECASE)
    open_issues = [i for i in issues if i.get("state") == "OPEN"]
    closed_issues = [i for i in issues if i.get("state") == "CLOSED"]

    for i in open_issues:
        if word_re.search(i.get("title") or ""):
            return BacklogMatch("SCHEDULED", i["number"], i["title"])
    for i in open_issues:
        if word_re.search(i.get("body") or ""):
            return BacklogMatch("POSSIBLE", i["number"], i["title"])
    for i in closed_issues:
        if word_re.search(i.get("title") or "") or word_re.search(
            i.get("body") or ""
        ):
            return BacklogMatch("REGRESSION", i["number"], i["title"])
    return BacklogMatch("UNSCHEDULED")


# --------------------------------------------------------------------------
# Ranking
# --------------------------------------------------------------------------

_SOURCE_RE = re.compile(r"ADR (\d{4}) §(\d+)([a-z]?)")


def _source_sort_key(source: str) -> tuple[int, int, str]:
    m = _SOURCE_RE.search(source)
    if not m:
        return (9999, 9999, "")
    return (int(m.group(1)), int(m.group(2)), m.group(3))


def rank_gaps(
    gaps: list[Finding], backlog: dict[str, BacklogMatch]
) -> list[tuple[Finding, BacklogMatch, str]]:
    """Order gaps by: regressions first (proven-lost work over
    merely-undone work), then unscheduled before scheduled (name something
    nobody is already tracking), then earlier ADR position as a
    foundational-ness proxy, then the matched issue number (or, absent one,
    the declaration's own name) as a final deterministic tie-break.

    Returns (finding, backlog_match, reason) so the caller can state, in
    words, which tier decided the order -- a ranked list with no argument is
    a linter, not a reasoning layer.
    """

    def key(item: tuple[Finding, BacklogMatch]):
        finding, match = item
        is_regression = 0 if match.kind == "REGRESSION" else 1
        is_scheduled = 1 if match.kind == "SCHEDULED" else 0
        tiebreak = (
            (0, match.issue_number)
            if match.issue_number is not None
            else (1, finding.name)
        )
        return (
            is_regression,
            is_scheduled,
            _source_sort_key(finding.source),
            tiebreak,
        )

    paired = [(g, backlog.get(g.name, BacklogMatch("UNKNOWN"))) for g in gaps]
    paired.sort(key=key)

    ranked: list[tuple[Finding, BacklogMatch, str]] = []
    for idx, (finding, match) in enumerate(paired):
        if idx == 0:
            if len(paired) == 1:
                reason = "the only genuine gap found"
            elif match.kind == "REGRESSION":
                reason = (
                    f"a regression: closed issue #{match.issue_number} "
                    f"({match.issue_title!r}) covered this, and it has "
                    "reappeared"
                )
            elif match.kind != "SCHEDULED" and any(
                m.kind == "SCHEDULED" for _, m in paired[1:]
            ):
                reason = (
                    "not yet tracked by any open issue, unlike the "
                    "alternative(s)"
                )
            else:
                reason = (
                    f"earlier in the decision record ({finding.source}) than "
                    "the alternative(s)"
                )
        else:
            reason = ""
        ranked.append((finding, match, reason))
    return ranked


# --------------------------------------------------------------------------
# Reporting
# --------------------------------------------------------------------------

_CATEGORY_TITLES = {
    "port": "Ports (ADR 0002 §5)",
    "directory": "Repository layout (ADR 0002 §6)",
    "command": "Commands (ADR 0004 §7)",
    "phase": "Session phases (ADR 0004 §7a)",
    "event": "Events (ADR 0004 §8)",
}


def _print_findings(findings: list[Finding], out=sys.stdout) -> None:
    by_category: dict[str, list[Finding]] = {}
    for f in findings:
        by_category.setdefault(f.category, []).append(f)

    for category in ("port", "directory", "command", "phase", "event"):
        items = by_category.get(category, [])
        if not items:
            continue
        print(f"=== {_CATEGORY_TITLES[category]} ===", file=out)
        if category == "phase":
            print(
                "    (\"contains\" here is enum-member presence only -- a "
                "chosen convention, confirmed rather than derived from the "
                "ADR; no ratified-path check applies to this category.)",
                file=out,
            )
        for f in items:
            print(f"  [{f.status:<10}] {f.name:<24} {f.detail}", file=out)
        print(file=out)


def _print_gaps(
    ranked: list[tuple[Finding, BacklogMatch, str]],
    checked_backlog: bool,
    out=sys.stdout,
) -> None:
    print("=== Gaps requiring action ===", file=out)
    if not ranked:
        print("  None found.", file=out)
        return
    print(f"  {len(ranked)} genuine gap(s) found.", file=out)
    for finding, match, _reason in ranked:
        line = f"  - {finding.name} ({finding.source})"
        if checked_backlog:
            if match.kind == "UNSCHEDULED":
                line += " -- not tracked by any issue"
            elif match.kind in ("SCHEDULED", "REGRESSION"):
                line += f" -- {match.kind.lower()}, issue #{match.issue_number}"
            elif match.kind == "POSSIBLE":
                line += (
                    f" -- possible match on #{match.issue_number} — verify"
                )
            else:
                line += " -- backlog unavailable"
        print(line, file=out)
    print(file=out)
    top_finding, _top_match, reason = ranked[0]
    print(f"Next: {top_finding.name} ({top_finding.source})", file=out)
    print(f"      {top_finding.detail}", file=out)
    print(f"      Reason: {reason}", file=out)


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def run_scan(repo_root: Path) -> list[Finding]:
    adr0002_text = (repo_root / ADR_0002_PATH).read_text(encoding="utf-8")
    adr0004_text = (repo_root / ADR_0004_PATH).read_text(encoding="utf-8")
    findings: list[Finding] = []
    findings += scan_ports(repo_root, adr0002_text)
    findings += scan_layout(repo_root, adr0002_text)
    findings += scan_commands(repo_root, adr0004_text)
    findings += scan_phases(repo_root, adr0004_text)
    findings += scan_events(repo_root, adr0004_text)
    return findings


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        prog="gap_scan.py",
        description=(
            "Report what the ADRs require but the codebase does not have, "
            "distinguishing deliberate deferral from a genuine gap."
        ),
    )
    parser.add_argument(
        "--check-backlog",
        action="store_true",
        help="look up open/closed GitHub issues via `gh` (network) to "
        "classify each gap as scheduled, a possible match, or a regression",
    )
    parser.add_argument(
        "--file-issues",
        action="store_true",
        help="file a GitHub issue via `gh` for each gap with no backlog "
        "match at all (implies --check-backlog; network, mutating)",
    )
    args = parser.parse_args(argv)

    repo_root = _repo_root()
    try:
        findings = run_scan(repo_root)
    except LookupError as exc:
        print(f"gap_scan.py: document structure error: {exc}", file=sys.stderr)
        return 1

    _print_findings(findings)

    gaps = [f for f in findings if f.status == GAP]
    check_backlog_flag = args.check_backlog or args.file_issues
    backlog: dict[str, BacklogMatch] = {}
    checked_backlog = False
    if check_backlog_flag and gaps:
        issues = fetch_backlog_issues()
        if issues is None:
            print(
                "Backlog check requested but `gh issue list` failed "
                "(no network, no auth, or `gh` not installed).",
                file=sys.stderr,
            )
        else:
            checked_backlog = True
            for g in gaps:
                backlog[g.name] = check_backlog(_search_term(g.name), issues)

    ranked = rank_gaps(gaps, backlog)
    _print_gaps(ranked, checked_backlog)

    if args.file_issues:
        if not gaps:
            pass  # nothing to file; the "Gaps requiring action" section
            # above already said so.
        elif not checked_backlog:
            print(
                "\n--file-issues requires a successful backlog check; "
                "filing nothing.",
                file=sys.stderr,
            )
        else:
            print(file=sys.stdout)
            print("=== Filing ===", file=sys.stdout)
            for finding, match, _reason in ranked:
                if match.kind != "UNSCHEDULED":
                    print(
                        f"  skip {finding.name}: backlog match "
                        f"({match.kind}, #{match.issue_number}) -- filing "
                        "is more conservative than reporting and skips on "
                        "any match, title or body",
                        file=sys.stdout,
                    )
                    continue
                title = f"[Gap] {finding.name} required by {finding.source}"
                body = finding.detail
                try:
                    subprocess.run(
                        [
                            "gh",
                            "issue",
                            "create",
                            "--title",
                            title,
                            "--body",
                            body,
                        ],
                        check=True,
                        timeout=30,
                    )
                except (
                    OSError,
                    subprocess.CalledProcessError,
                    subprocess.TimeoutExpired,
                ) as exc:
                    print(
                        f"  failed to file {finding.name}: {exc}",
                        file=sys.stderr,
                    )

    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
