"""Shared Markdown heading-section splitting for tools that read the design
and ADR corpus.

Factored out of `lore_query.py` (issue #27) so `gap_scan.py` (issue #30) does
not duplicate fence-aware heading detection. Both tools need the same thing:
"give me the text between one `#`/`##`/`###` heading and the next", with a
fenced code block never mistaken for a real heading -- `lore_query.py` uses
it to build retrievable chunks, `gap_scan.py` uses it to locate a specific
ADR section (e.g. "5. Ports") by heading substring.

No dependencies beyond the standard library.
"""

from __future__ import annotations

import re

# Heading levels that are split points. Bare `#`, `##`, and `###` all start a
# new section; `####` and deeper are body text of the enclosing section. See
# `tools/README.md` under "Chunking" for why `lore_query.py` needs a bare `#`
# to also be a split point.
HEADING_RE = re.compile(r"^(#{1,3})\s+(.+?)\s*$")
FENCE_RE = re.compile(r"^\s*(```|~~~)")


def split_sections(
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
        if FENCE_RE.match(line):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        m = HEADING_RE.match(line)
        if m:
            headings.append((line.rstrip("\n"), idx))

    sections: list[tuple[str, int, int, list[str]]] = []
    for i, (heading_text, start) in enumerate(headings):
        end = headings[i + 1][1] - 1 if i + 1 < len(headings) else len(lines)
        body = lines[start:end]  # body excludes the heading line itself
        sections.append((heading_text, start, end, body))
    return sections
