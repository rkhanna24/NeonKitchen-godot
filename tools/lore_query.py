#!/usr/bin/env python3
"""Search the design/lore/ADR corpus for passages relevant to a query.

    python3 tools/lore_query.py "north tower"
    python3 tools/lore_query.py --verify-probes

No dependencies beyond the standard library, no network access, and no
persisted index: the corpus is walked and scored fresh on every run. See
`tools/README.md` for the design rationale (scoring, the size cap, and the
"no good match" gate) and issue #27 for the approved proposal this
implements.

Exit codes:
    0  one or more chunks matched and were printed
    1  no chunk cleared the coverage gate ("no good match")
    2  usage error (bad arguments)
    3  --verify-probes found a regression (only meaningful with that flag)
"""

from __future__ import annotations

import argparse
import math
import re
import sys
from dataclasses import dataclass
from pathlib import Path

# --------------------------------------------------------------------------
# Corpus definition
# --------------------------------------------------------------------------

# Design, lore, and accepted-decision documents only. `docs/agents/`,
# `docs/crew/`, `docs/Home.md`, and `docs/worklogs/` are process
# documentation or project log, not design or lore content a content agent
# should retrieve from -- see the scope comment on issue #27. Nine files.
CORPUS_RELATIVE_PATHS: tuple[str, ...] = (
    "docs/design/Lore Bible.md",
    "docs/design/Content Voice.md",
    "docs/design/Neon Kitchen - Game Design Document.md",
    "docs/adr/0001-pin-godot-version.md",
    "docs/adr/0002-phase-1-structural-foundation.md",
    "docs/adr/0003-test-framework.md",
    "docs/adr/0004-phase-1-contracts.md",
    "docs/adr/README.md",
    "docs/technical_architecture.md",
)

# A section longer than this falls back to paragraph-level matches. Reused
# from the scope comment's own measurement of the corpus rather than a
# second invented number; see tools/README.md for the load-bearing check
# (ADR 0004 section 8a at 39 lines must stay whole, section 2 at 60 must
# fall back).
SECTION_LINE_CAP = 40

# A retrieved chunk must contain at least this fraction of the query's
# distinct non-stopword terms to count as a real answer. A structural
# "did we find most of what was asked about, together, in one place" test,
# not a score threshold -- see tools/README.md.
COVERAGE_THRESHOLD = 0.5

BM25_K1 = 1.5
BM25_B = 0.75

# Extra score for each query term that also appears in a chunk's own
# heading, so "who is the Cook" prefers a section titled "The Cook (Player
# Character)" over one that merely uses the word "Cook" three times in its
# body (the GDD's agent-coordination diagram names "Systems Cook", "Service
# Cook", and "Prep Cook"). Without this, BM25's raw term frequency prefers
# the latter -- and a single-word query like "cook" has no other signal
# available to prefer "named by" over "mentions in passing". (This tool used
# to reject single-term queries outright via a MIN_QUERY_TERMS gate; that
# masked this exact ranking failure instead of fixing it, and broke
# legitimate single-noun queries like "kimchi" in the process. See
# tools/README.md.)
#
# Measured, not guessed: with the query terms held fixed, this is the
# smallest weight, out of {0.0, 0.1, 0.2, 0.3, 0.5, ...}, that flips "who is
# the Cook" to the Lore Bible section (binary search puts the exact
# crossover at ~0.155). Raising the weight further was then pushed until it
# broke something else: at ~2.6 it flips "who approves the truck parking"
# from "What the Gangster Establishes" to "The Truck" (which also has
# "truck" in its heading, with less body signal to make up the gap), and at
# ~3.3 it separately breaks "can a description name a flavour dimension".
# 0.3 sits with roughly 2x headroom above the minimum that fixes the Cook
# probe and better than 8x headroom below the point where the truck-parking
# probe regresses -- verified with all eight hit probes and all three
# adversarial probes, not just the one this constant was added for.
HEADING_BOOST_WEIGHT = 0.3

DEFAULT_RESULT_COUNT = 3

# Heading levels that are split points. Bare `#`, `##`, and `###` all start
# a new chunk; `####` and deeper are body text of the enclosing chunk (two
# such headings exist in ADR 0004, at lines 33 and 97) unless a section
# exceeds SECTION_LINE_CAP, in which case the nearest one becomes a
# breadcrumb for the paragraph returned from inside it.
_HEADING_RE = re.compile(r"^(#{1,3})\s+(.+?)\s*$")
_SUBHEADING_RE = re.compile(r"^(#{4,6})\s+(.+?)\s*$")
_FENCE_RE = re.compile(r"^\s*(```|~~~)")

# A paragraph that is only a bare label -- `**ESTABLISHED**` alone on its
# line, as the Lore Bible's "## The City" uses -- carries no claim by
# itself. Left unmerged, paragraph-level fallback could return the bullets
# that follow with no label attached, silently dropping the one property
# the Lore Bible exists to preserve. Not exercised by today's content (no
# section using this pattern is currently oversized), but load-bearing the
# moment one is.
_BARE_LABEL_RE = re.compile(r"^\*\*(ESTABLISHED|PROPOSED|DECIDED)[^*]*\*\*$")

_STOPWORDS: frozenset[str] = frozenset(
    """
    a an the of in on to for is are was were be been being and or but not
    no do does did doing can could will would shall should who whom whose
    what which when where why how this that these those it its as by with
    from at into about than then there here so such if while than each
    all any both more most other some such only own same too very just
    also up down out off over under again further once i you he she we
    they them his her their our your my me him
    """.split()
)

_TOKEN_RE = re.compile(r"[a-z]{2,}|[0-9]+")


def tokenize(text: str) -> list[str]:
    """Lowercase word/number tokens, no stemming."""
    return _TOKEN_RE.findall(text.lower())


def content_terms(text: str) -> list[str]:
    """Tokens with stopwords removed, order preserved."""
    return [t for t in tokenize(text) if t not in _STOPWORDS]


# --------------------------------------------------------------------------
# Corpus model
# --------------------------------------------------------------------------


@dataclass(frozen=True)
class Chunk:
    """One retrievable passage: either a whole heading section, or -- when
    that section exceeds SECTION_LINE_CAP -- one paragraph from inside it
    with its heading (and, if applicable, the nearest enclosing sub-heading)
    prepended.
    """

    file: str
    heading_path: tuple[str, ...]
    text: str
    start_line: int
    end_line: int
    is_fallback: bool

    def label(self) -> str:
        return " › ".join(self.heading_path)

    def source(self) -> str:
        return f"{self.file}:{self.start_line}-{self.end_line}"


def _split_sections(
    lines: list[str],
) -> list[tuple[str, int, int, list[str]]]:
    """Return (heading_text, start_line, end_line, body_lines) for every
    top-level split (bare #, ##, or ###) in the file, 1-indexed inclusive
    line numbers. Fenced code blocks suspend heading detection so a literal
    "# ADR NNNN" inside a ```markdown template is never mistaken for a
    real heading.
    """
    headings: list[tuple[str, int]] = []
    in_fence = False
    for idx, line in enumerate(lines, start=1):
        if _FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = _HEADING_RE.match(line)
        if m:
            headings.append((line.rstrip("\n"), idx))

    sections: list[tuple[str, int, int, list[str]]] = []
    for i, (heading_text, start) in enumerate(headings):
        end = headings[i + 1][1] - 1 if i + 1 < len(headings) else len(lines)
        body = lines[start:end]  # body excludes the heading line itself
        sections.append((heading_text, start, end, body))
    return sections


def _split_paragraphs(body: list[str]) -> list[tuple[int, int, list[str]]]:
    """Blank-line-delimited blocks within a section's body, fence-aware so a
    blank line inside a fenced example never splits one paragraph in two.
    Returns (start_offset, end_offset, lines), offsets 0-indexed into body.
    """
    paragraphs: list[tuple[int, int, list[str]]] = []
    current: list[str] = []
    current_start = 0
    in_fence = False
    for offset, line in enumerate(body):
        is_fence_line = bool(_FENCE_RE.match(line))
        if is_fence_line:
            in_fence = not in_fence
        blank = (line.strip() == "") and not in_fence and not is_fence_line
        if blank:
            if current:
                paragraphs.append(
                    (current_start, current_start + len(current) - 1, current)
                )
                current = []
            continue
        if not current:
            current_start = offset
        current.append(line)
    if current:
        paragraphs.append(
            (current_start, current_start + len(current) - 1, current)
        )
    return paragraphs


def _merge_bare_labels(
    paragraphs: list[tuple[int, int, list[str]]]
) -> list[tuple[int, int, list[str]]]:
    """Merge a paragraph that is only a bare `**LABEL**` line into the
    paragraph that follows it, so fallback can never return a claim's body
    without the label that scopes it.
    """
    merged: list[tuple[int, int, list[str]]] = []
    pending: tuple[int, int, list[str]] | None = None
    for start, end, text_lines in paragraphs:
        is_bare_label = len(text_lines) == 1 and bool(
            _BARE_LABEL_RE.match(text_lines[0].strip())
        )
        if pending is not None:
            start = pending[0]
            text_lines = pending[2] + text_lines
            pending = None
        if is_bare_label:
            pending = (start, end, text_lines)
            continue
        merged.append((start, end, text_lines))
    if pending is not None:
        # A bare label with nothing after it in the section: keep it as its
        # own chunk rather than discarding it.
        merged.append(pending)
    return merged


def _nearest_subheading(body: list[str], up_to_offset: int) -> str | None:
    """The most recent level-4+ heading at or before `up_to_offset` in this
    section's body, ignoring lines inside fenced code.
    """
    result: str | None = None
    in_fence = False
    for offset, line in enumerate(body):
        if offset > up_to_offset:
            break
        if _FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = _SUBHEADING_RE.match(line)
        if m:
            result = line.rstrip("\n")
    return result


def load_chunks(repo_root: Path) -> list[Chunk]:
    chunks: list[Chunk] = []
    for rel_path in CORPUS_RELATIVE_PATHS:
        path = repo_root / rel_path
        text = path.read_text(encoding="utf-8")
        lines = text.splitlines(keepends=True)
        for heading_text, start, end, body in _split_sections(lines):
            total_lines = end - start + 1
            if total_lines <= SECTION_LINE_CAP:
                chunks.append(
                    Chunk(
                        file=rel_path,
                        heading_path=(heading_text,),
                        text=heading_text + "\n" + "".join(body),
                        start_line=start,
                        end_line=end,
                        is_fallback=False,
                    )
                )
                continue

            paragraphs = _merge_bare_labels(_split_paragraphs(body))
            for p_start, p_end, p_lines in paragraphs:
                subheading = _nearest_subheading(body, p_start)
                heading_path = (
                    (heading_text, subheading)
                    if subheading
                    else (heading_text,)
                )
                prefix = "\n".join(heading_path) + "\n"
                chunks.append(
                    Chunk(
                        file=rel_path,
                        heading_path=heading_path,
                        text=prefix + "".join(p_lines),
                        # start/end are 1-indexed absolute file lines; body
                        # is 0-indexed starting the line after the heading.
                        start_line=start + 1 + p_start,
                        end_line=start + 1 + p_end,
                        is_fallback=True,
                    )
                )
    return chunks


# --------------------------------------------------------------------------
# BM25
# --------------------------------------------------------------------------


@dataclass
class _Index:
    chunks: list[Chunk]
    doc_terms: list[list[str]]
    doc_len: list[int]
    avg_doc_len: float
    df: dict[str, int]
    n_docs: int
    heading_terms: list[frozenset[str]]


def build_index(chunks: list[Chunk]) -> _Index:
    doc_terms = [tokenize(c.text) for c in chunks]
    doc_len = [len(t) for t in doc_terms]
    avg_doc_len = (sum(doc_len) / len(doc_len)) if doc_len else 0.0
    df: dict[str, int] = {}
    for terms in doc_terms:
        for term in set(terms):
            df[term] = df.get(term, 0) + 1
    heading_terms = [
        frozenset(tokenize(" ".join(c.heading_path))) for c in chunks
    ]
    return _Index(
        chunks=chunks,
        doc_terms=doc_terms,
        doc_len=doc_len,
        avg_doc_len=avg_doc_len,
        df=df,
        n_docs=len(chunks),
        heading_terms=heading_terms,
    )


def _idf(index: _Index, term: str) -> float:
    n = index.n_docs
    df = index.df.get(term, 0)
    return math.log((n - df + 0.5) / (df + 0.5) + 1.0)


def _bm25_score(index: _Index, doc_idx: int, query_terms: list[str]) -> float:
    terms = index.doc_terms[doc_idx]
    if not terms:
        return 0.0
    dl = index.doc_len[doc_idx]
    avgdl = index.avg_doc_len or 1.0
    score = 0.0
    for term in query_terms:
        tf = terms.count(term)
        if tf == 0:
            continue
        idf = _idf(index, term)
        denom = tf + BM25_K1 * (1 - BM25_B + BM25_B * (dl / avgdl))
        score += idf * (tf * (BM25_K1 + 1)) / denom
    return score


def _heading_boost(
    index: _Index, doc_idx: int, query_terms: list[str]
) -> float:
    """Extra score for each query term that names this chunk's own heading,
    weighted by the term's idf so a common word gains little and a rare,
    distinctive one gains more. See HEADING_BOOST_WEIGHT for how the weight
    was measured.
    """
    hterms = index.heading_terms[doc_idx]
    return sum(
        HEADING_BOOST_WEIGHT * _idf(index, term)
        for term in query_terms
        if term in hterms
    )


@dataclass
class ScoredChunk:
    chunk: Chunk
    score: float
    coverage: float
    matched_terms: tuple[str, ...]


@dataclass
class QueryResult:
    query: str
    distinct_terms: tuple[str, ...]
    ranked: list[ScoredChunk]
    ok: bool
    reason: str = ""

    def top(self) -> ScoredChunk | None:
        return self.ranked[0] if self.ranked else None


def run_query(index: _Index, query: str) -> QueryResult:
    distinct_terms = tuple(sorted(set(content_terms(query))))

    if not distinct_terms:
        return QueryResult(
            query=query,
            distinct_terms=distinct_terms,
            ranked=[],
            ok=False,
            reason=(
                "query has no distinct content terms after removing "
                "stopwords"
            ),
        )

    query_terms = list(distinct_terms)
    scored: list[ScoredChunk] = []
    for doc_idx, chunk in enumerate(index.chunks):
        score = _bm25_score(index, doc_idx, query_terms)
        score += _heading_boost(index, doc_idx, query_terms)
        if score <= 0.0:
            continue
        doc_term_set = set(index.doc_terms[doc_idx])
        matched = tuple(t for t in query_terms if t in doc_term_set)
        coverage = len(matched) / len(query_terms)
        scored.append(ScoredChunk(chunk, score, coverage, matched))

    scored.sort(key=lambda s: s.score, reverse=True)

    if not scored:
        return QueryResult(
            query=query,
            distinct_terms=distinct_terms,
            ranked=[],
            ok=False,
            reason="no chunk in the corpus contains any query term",
        )

    top = scored[0]
    if top.coverage < COVERAGE_THRESHOLD:
        return QueryResult(
            query=query,
            distinct_terms=distinct_terms,
            ranked=scored,
            ok=False,
            reason=(
                f"top match covers {top.coverage:.2f} of the query's "
                f"distinct terms, below the {COVERAGE_THRESHOLD:.2f} gate"
            ),
        )

    return QueryResult(
        query=query, distinct_terms=distinct_terms, ranked=scored, ok=True
    )


# --------------------------------------------------------------------------
# CLI
# --------------------------------------------------------------------------


def _print_result(result: QueryResult, top_n: int, out=sys.stdout) -> None:
    terms = ", ".join(result.distinct_terms) or "(none)"
    print(f'Query: "{result.query}"', file=out)
    print(f"Distinct query terms: {terms}", file=out)
    if not result.ok:
        print(f"No good match: {result.reason}", file=out)
        return
    for rank, sc in enumerate(result.ranked[:top_n], start=1):
        chunk = sc.chunk
        print(file=out)
        print(f"[{rank}] {chunk.file} — {chunk.label()}", file=out)
        print(f"    lines {chunk.start_line}-{chunk.end_line}", file=out)
        print(
            f"    score={sc.score:.3f} coverage={sc.coverage:.2f} "
            f"matched=({', '.join(sc.matched_terms)})",
            file=out,
        )
        print(file=out)
        for line in chunk.text.rstrip("\n").splitlines():
            print(f"    {line}", file=out)


# Probe queries and the passage each must return, from the scope comment on
# issue #27. `heading_contains` and `file_contains` are checked against the
# top-ranked chunk's label and file path.
_HIT_PROBES: tuple[tuple[str, str, str], ...] = (
    ("north tower", "Lore Bible.md", "The North Tower"),
    ("reaction key resolution", "0004-phase-1-contracts.md", "8a"),
    (
        "can a description name a flavour dimension",
        "Content Voice.md",
        "Five rules",
    ),
    (
        "who approves the truck parking",
        "Lore Bible.md",
        "What the Gangster Establishes",
    ),
    (
        "what does a weight of zero mean",
        "0004-phase-1-contracts.md",
        "2. Customer targets",
    ),
    # Added in the issue #27 bounded repair. The Lore Bible's own
    # "## The Cook (Player Character)" section IS the correct answer to
    # this query -- it honestly reports that nothing is established about
    # the player character. Returning the GDD's agent-coordination diagram
    # instead (which uses "Cook" three times, as "Systems Cook", "Service
    # Cook", and "Prep Cook") was a ranking failure, not a case for
    # withholding an answer; see HEADING_BOOST_WEIGHT.
    (
        "who is the Cook",
        "Lore Bible.md",
        "The Cook (Player Character)",
    ),
    # Single-noun queries a content agent will actually make while writing
    # customers. These previously returned "no good match" solely because
    # of the now-removed MIN_QUERY_TERMS gate -- not because the corpus
    # lacked an answer.
    ("kimchi", "Content Voice.md", "Five rules"),
    ("gangster", "Lore Bible.md", "What the Gangster Establishes"),
    (
        "solarpunk",
        "Lore Bible.md",
        "Corporate Neon Against Community Solarpunk",
    ),
)

# Two nonsense queries and one plausible-but-unanswered query. Per the
# approved addition, a check that only exercises its passing cases is half
# a check: these prove the coverage gate actually declines rather than
# merely that it accepts.
#
# "who is the Cook" used to be here: the original requirement was that it
# return no match, on the theory that the Lore Bible establishes nothing
# about the player character. That was a misreading of the Lore Bible's own
# "## The Cook (Player Character)" section, which honestly reports the gap
# -- that section is a real, correct answer, so it now lives in
# _HIT_PROBES instead. These three remain genuinely unanswerable.
_NO_MATCH_PROBES: tuple[tuple[str, str], ...] = (
    ("wizard tax bracket harmonics", "nonsense, no corpus overlap"),
    ("bicycle mango stock exchange plumbing", "nonsense, no corpus overlap"),
    (
        "how much does a customer tip after a delighted rating",
        "plausible, but no tip mechanic exists anywhere in the corpus",
    ),
)


def verify_probes(index: _Index, out=sys.stdout) -> bool:
    all_ok = True

    print("== Hit probes (must return the named passage) ==", file=out)
    for query, file_contains, heading_contains in _HIT_PROBES:
        result = run_query(index, query)
        top = result.top()
        passed = (
            result.ok
            and top is not None
            and file_contains in top.chunk.file
            and heading_contains in top.chunk.label()
        )
        status = "PASS" if passed else "FAIL"
        if not passed:
            all_ok = False
        coverage = f"{top.coverage:.2f}" if top else "n/a"
        got = f"{top.chunk.file} — {top.chunk.label()}" if top else "no match"
        print(
            f"  [{status}] {query!r}\n"
            f"        expected: {file_contains} / {heading_contains!r}\n"
            f"        got:      {got}\n"
            f"        coverage: {coverage}",
            file=out,
        )

    print(file=out)
    print(
        "== Adversarial probes (must return no match) ==",
        file=out,
    )
    for query, note in _NO_MATCH_PROBES:
        result = run_query(index, query)
        top = result.top()
        passed = not result.ok
        status = "PASS" if passed else "FAIL"
        if not passed:
            all_ok = False
        coverage = f"{top.coverage:.2f}" if top else "n/a"
        got = (
            f"{top.chunk.file} — {top.chunk.label()}"
            if (top and result.ok)
            else f"no match ({result.reason})"
        )
        print(
            f"  [{status}] {query!r}  ({note})\n"
            f"        got:      {got}\n"
            f"        coverage: {coverage}",
            file=out,
        )

    print(file=out)
    print("All PASS" if all_ok else "One or more probes FAILED", file=out)
    return all_ok


def _repo_root() -> Path:
    return Path(__file__).resolve().parent.parent


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(
        prog="lore_query.py",
        description=(
            "Search docs/design, docs/adr, and technical_architecture.md "
            "for passages relevant to a query."
        ),
    )
    parser.add_argument(
        "query",
        nargs="*",
        help="the query text, e.g. lore_query.py north tower",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=DEFAULT_RESULT_COUNT,
        help=(
            "number of ranked chunks to print "
            f"(default {DEFAULT_RESULT_COUNT})"
        ),
    )
    parser.add_argument(
        "--verify-probes",
        action="store_true",
        help=(
            "run the acceptance probes from issue #27 and exit nonzero "
            "on regression"
        ),
    )
    args = parser.parse_args(argv)

    if not args.verify_probes and not args.query:
        parser.print_usage(sys.stderr)
        print("lore_query.py: error: a query is required", file=sys.stderr)
        return 2

    chunks = load_chunks(_repo_root())
    index = build_index(chunks)

    if args.verify_probes:
        ok = verify_probes(index)
        return 0 if ok else 3

    query = " ".join(args.query)
    result = run_query(index, query)
    _print_result(result, args.top)
    return 0 if result.ok else 1


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
