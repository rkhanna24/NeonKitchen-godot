#!/usr/bin/env bash
#
# The GER loop's Tier 1 evaluator: does the content in the working tree still
# produce a real puzzle?
#
#   tools/ger/evaluate_recipe_space.sh <defect-output-file>
#
# This enforces one rule, and the rule is the GDD's, quoted at
# docs/design/Neon Kitchen - Game Design Document.md section 2.4:
#
#   "Each customer must have at least three satisfying combinations, including
#    at least two that do not depend on the same central ingredient. No single
#    recipe should satisfy more than half of the customer roster."
#
# It does not reimplement any of that. It runs bootstrap/audit_recipe_space.gd,
# which enumerates every legal dish against every customer through the real
# `Evaluator` -- 298 dishes and 2,384 evaluations at 12 ingredients and 8
# customers -- and reads the verdict out of the report it writes. A second
# implementation of the rule would be a second thing to keep in agreement with
# the game, and the point of the audit was to stop having those.
#
# Note that this regenerates docs/design/Recipe Space Audit.md rather than
# checking it. That is correct inside the loop: the content just changed, so the
# committed report is *supposed* to be stale, and a regenerated report is the
# measurement. `scripts/check.sh` runs the same audit in --check mode for the
# opposite purpose -- catching content that moved without the report following.
#
# Exit codes, which are the loop's three-state verdict:
#   0  PASS
#   1  REVISE -- defects written to the output file
#   2  the audit could not run, so there is no verdict to give

set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT
cd "$REPO_ROOT" || exit 2

readonly REPORT="docs/design/Recipe Space Audit.md"
readonly AUDIT="bootstrap/audit_recipe_space.gd"

defects="${1:-}"
[ -n "$defects" ] || { echo "usage: evaluate_recipe_space.sh <defect-output-file>" >&2; exit 2; }
: >"$defects"

# Same resolution order as scripts/check.sh, so the loop and the gate cannot
# disagree about which engine measured the content.
if [ -n "${GODOT_BIN:-}" ]; then
	godot_bin="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
	godot_bin="$(command -v godot)"
else
	godot_bin="/Applications/Godot.app/Contents/MacOS/Godot"
fi
[ -x "$godot_bin" ] || { echo "evaluator: no Godot binary; set GODOT_BIN" >&2; exit 2; }
[ -f "$AUDIT" ] || { echo "evaluator: $AUDIT is missing" >&2; exit 2; }

# Godot resolves `class_name` types through .godot/global_script_class_cache.cfg,
# which a fresh clone does not have. Without it every type in the audit fails to
# resolve, the script never loads -- and Godot still exits 0. Importing first is
# cheap and idempotent; the exit-code check below is what catches it anyway.
if [ ! -f ".godot/global_script_class_cache.cfg" ]; then
	echo "evaluator: building the Godot import cache (first run)"
	"$godot_bin" --headless --path . --import >/dev/null 2>&1 \
		|| { echo "evaluator: godot --import failed" >&2; exit 2; }
fi

audit_log="$(mktemp)"
trap 'rm -f "$audit_log"' EXIT

# Fingerprint the report before the run. Godot's exit code cannot be trusted on
# its own: a GDScript parse error makes the script fail to load and the engine
# still exits 0, so a bare `if godot ...; then pass` reports success for a run
# that never happened. This bit the evaluator during development -- it read a
# stale committed report and returned PASS for content that fails the rule. The
# same blind spot is live in scripts/check.sh's recipe-audit step.
# Fractional seconds where the platform offers them. Whole-second granularity
# is not enough: two writes inside the same second compare equal, which would
# read as "the audit did not run" and trip the breaker on a healthy run.
mtime_of() {
	stat -f %Fm "$1" 2>/dev/null \
		|| stat -c %.9Y "$1" 2>/dev/null \
		|| stat -f %m "$1" 2>/dev/null \
		|| stat -c %Y "$1" 2>/dev/null \
		|| echo 0
}
report_mtime_before=0
[ -f "$REPORT" ] && report_mtime_before="$(mtime_of "$REPORT")"

"$godot_bin" --headless --path . -s "$AUDIT" >"$audit_log" 2>&1
audit_status=$?

# A script that failed to load produces these and exits 0.
if grep -qE '^(SCRIPT ERROR|ERROR: Failed to load script)' "$audit_log"; then
	{
		echo "evaluator: $AUDIT did not load; no measurement was taken"
		grep -E '^(SCRIPT ERROR|ERROR: Failed to load script)' "$audit_log" | head -5 | sed 's/^/  /'
	} >&2
	exit 2
fi

if [ "$audit_status" -ne 0 ]; then
	# Malformed content is a defect the generator can act on, not an evaluator
	# failure: ContentValidator rejecting an out-of-range flavour value or an
	# unknown tag is exactly the kind of thing a refinement round fixes. Anything
	# else -- a crash, a missing resource, an engine error -- is not a verdict,
	# and saying REVISE there would send the generator chasing a defect nobody
	# measured.
	if grep -q '^content error:' "$audit_log"; then
		{
			printf 'The content does not load. `ContentValidator` rejected it:\n\n'
			grep '^content error:' "$audit_log" | sed 's/^content error: /- /'
			printf '\nFix these before any balance question can be asked.\n'
		} >"$defects"
		exit 1
	fi
	{
		echo "evaluator: $AUDIT exited $audit_status without a content error"
		sed 's/^/  /' "$audit_log"
	} >&2
	exit 2
fi

[ -f "$REPORT" ] || { echo "evaluator: the audit did not write $REPORT" >&2; exit 2; }

# The verdict below is read out of this file, so a run that left it untouched
# would have this script grading a previous round's content. The audit rewrites
# the report unconditionally in generate mode, so an mtime that did not advance
# means it did not get that far -- regardless of what the exit code said.
#
# Byte-identical content is NOT the test: re-running on unchanged content
# legitimately reproduces the report exactly, which is the whole basis of the
# gate's drift check.
if [ "$(mtime_of "$REPORT")" = "$report_mtime_before" ]; then
	echo "evaluator: $REPORT was not rewritten; the audit did not re-measure" >&2
	exit 2
fi

found=0

# --- GDD 2.4, first clause: every customer needs a real set of solutions ------
# The audit writes exactly one of two sentinel lines, so this reads its verdict
# rather than recomputing it.
if grep -q '^\*\*Fails the viability rule:\*\*' "$REPORT"; then
	found=1
	failing="$(grep '^\*\*Fails the viability rule:\*\*' "$REPORT" \
		| sed 's/^\*\*Fails the viability rule:\*\* //; s/\.$//')"
	{
		printf '## Viability (GDD 2.4)\n\n'
		printf 'These customers do not have three satisfying dishes across at least two\n'
		printf 'distinct central ingredients: **%s**.\n\n' "$failing"
		printf 'Their rows in the report, with the counts:\n\n'
		# The table row is the actionable part: it names the best reachable dish,
		# so the fix is aimed at the gap rather than guessed at.
		grep '| \*\*FAIL\*\* |' "$REPORT" | sed 's/^/    /'
		printf '\n'
	} >>"$defects"
elif ! grep -q '^Every customer satisfies the viability rule\.$' "$REPORT"; then
	# Neither sentinel present means the report's shape changed under this
	# script. Silently passing would be the worst outcome: the rule would stop
	# being enforced and nothing would say so.
	echo "evaluator: neither viability sentinel found in $REPORT; the audit's output shape changed" >&2
	exit 2
fi

# --- GDD 2.4, second clause: no recipe satisfies more than half the roster ----
dominant="$(grep -E '^- `.*` satisfies [0-9]+ of [0-9]+$' "$REPORT")"
if [ -n "$dominant" ]; then
	found=1
	{
		printf '## Dominant dishes (GDD 2.4)\n\n'
		printf 'A recipe satisfying more than half the roster makes the pantry a lookup\n'
		printf 'table -- one dish answers most of the day.\n\n'
		printf '%s\n\n' "$dominant"
	} >>"$defects"
fi

# --- GDD 5: illusory choice ---------------------------------------------------
# The audit lists every ingredient a customer cannot be served without; only the
# ones over half the roster are a rule violation. The rest are information.
over_half="$(grep -E '^- `.*` appears in every satisfying dish for .*over half\*\*$' "$REPORT")"
if [ -n "$over_half" ]; then
	found=1
	{
		printf '## Illusory choice (GDD 5)\n\n'
		printf 'More than half the roster cannot be served without the same ingredient,\n'
		printf 'so the choice the pantry appears to offer is not a real one.\n\n'
		printf '%s\n\n' "$over_half"
	} >>"$defects"
fi

if [ "$found" -eq 1 ]; then
	exit 1
fi

rm -f "$defects"
: >"$defects"
exit 0
