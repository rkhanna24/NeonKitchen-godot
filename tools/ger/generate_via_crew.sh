#!/usr/bin/env bash
#
# The GER loop's default generator: the existing content crew, reduced to a
# single generate step.
#
#   tools/ger/generate_via_crew.sh <brief-file> <defect-file> <attempt-number>
#
# The crew already knows how to turn a brief into `.tres`. What it did not have
# was anything outside itself deciding when to stop, which is what the loop adds.
# So this deliberately runs only the two authoring stages:
#
#   pantry-keeper    brief (+ defects) -> content/staging/proposal.md
#   health-inspector proposal          -> content/base/**.tres + locale rows
#
# It does *not* dispatch the recipe-space-analyst. That role is now the loop's
# evaluator, and running it here would put the check inside the thing being
# checked -- the same collapse the crew's own README warns about on the
# REVISE edge. The Pantry Keeper still holds no `Bash`, so it cannot score its
# own proposal before the evaluator sees it.
#
# On attempt 2 and later the defect file is non-empty, and its contents are given
# to the Pantry Keeper verbatim. Handing over the specific defect rather than
# "that failed, try again" is the entire difference between a refiner and a
# retry.
#
# Exit non-zero if either stage fails or produces nothing; the loop treats that
# as a hard breaker trip rather than something to retry.

set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT
cd "$REPO_ROOT" || exit 1

readonly PROPOSAL="content/staging/proposal.md"

brief_file="${1:-}"
defect_file="${2:-}"
attempt="${3:-1}"

[ -f "$brief_file" ] || { echo "generator: no brief file at '$brief_file'" >&2; exit 1; }
command -v claude >/dev/null 2>&1 || { echo "generator: the 'claude' CLI is not on PATH" >&2; exit 1; }

mkdir -p content/staging

prompt_file="$(mktemp)"
trap 'rm -f "$prompt_file"' EXIT

{
	if [ "$attempt" -gt 1 ] && [ -s "$defect_file" ]; then
		printf 'Revise the proposal in %s. Attempt %d was rejected.\n\n' "$PROPOSAL" "$((attempt - 1))"
		printf 'The evaluator enumerated every dish through the real Evaluator and found\n'
		printf 'these specific defects. Fix these, and do not introduce new ones:\n\n'
		cat "$defect_file"
		printf '\n\nThe original brief still stands:\n\n'
	else
		printf 'Write a content proposal to %s for this brief:\n\n' "$PROPOSAL"
	fi
	cat "$brief_file"
	printf '\n\nRead docs/adr/0004-phase-1-contracts.md and docs/design/Content Voice.md\n'
	printf 'yourself. Do not assume the existing roster is correct; new content joins it.\n'
} >"$prompt_file"

echo "generator: dispatching pantry-keeper (attempt $attempt)"
if ! claude -p --agent pantry-keeper --permission-mode bypassPermissions <"$prompt_file"; then
	echo "generator: pantry-keeper failed" >&2
	exit 1
fi

[ -s "$PROPOSAL" ] || { echo "generator: pantry-keeper wrote no proposal to $PROPOSAL" >&2; exit 1; }

echo "generator: dispatching health-inspector"
if ! printf 'Generate the .tres files and localisation rows for the proposal in %s.\n' "$PROPOSAL" \
	| claude -p --agent health-inspector --permission-mode bypassPermissions; then
	echo "generator: health-inspector failed" >&2
	exit 1
fi

# The loop's evaluator reads content off disk, so a generator that reported
# success while changing nothing would send an unchanged candidate round the
# loop until the oscillation trip caught it. Catching it here names the cause.
if [ -z "$(git status --porcelain content/base 2>/dev/null)" ]; then
	echo "generator: health-inspector left content/base unchanged" >&2
	exit 1
fi
