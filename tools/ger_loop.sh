#!/usr/bin/env bash
#
# The Generate -> Evaluate -> Refine loop, with a circuit breaker.
#
#   ./tools/ger_loop.sh --brief "An ingredient that gives night_courier a second
#                                satisfying dish not built on chili_crisp"
#
# The loop itself knows nothing about ingredients, customers, or Godot. It knows
# how to run a generator, ask an evaluator whether the result is acceptable, hand
# a *specific* defect back to the generator, and stop when stopping is the right
# answer. Everything game-shaped lives behind the two hooks below, so the same
# driver can refine content, prose, or documents by swapping them.
#
# ---------------------------------------------------------------- the hooks --
#
# GENERATOR   "$GENERATOR" <brief-file> <defect-file> <attempt-number>
#
#   Produces or revises the candidate in the working tree. On attempt 1 the
#   defect file exists and is empty; on every later attempt it holds the
#   evaluator's report from the previous round, which is the whole mechanism of
#   refinement -- the generator is told what specifically was wrong, not that it
#   failed.
#
#   Exit 0 to continue. Any non-zero exit trips the breaker immediately: a
#   generator that cannot generate will not generate better on a second ask.
#
# EVALUATOR   "$EVALUATOR" <defect-output-file>
#
#   Judges what is in the working tree and writes its findings to the file it is
#   given. Its exit code is a three-state verdict, and the third state is the
#   point:
#
#     0   PASS    accept and stop
#     1   REVISE  the content is wrong; the defect file says how
#     >=2 ERROR   the evaluator could not reach a verdict
#
#   ERROR is separated from REVISE so the loop never refines against a broken
#   judge. A crashed evaluator that reported REVISE would send the generator
#   chasing a defect nobody measured, and three rounds later the escalation
#   would blame the content.
#
# ------------------------------------------------------- the circuit breaker --
#
# Three independent trips, because "ran out of attempts" is only one of the ways
# a self-correcting loop fails to self-correct:
#
#   1. BUDGET       --max-attempts rounds elapsed without a PASS.
#
#   2. OSCILLATION  a defect signature repeats. Local fixes to a global
#                   constraint cycle: docs/crew/ASSIGNMENT-4.md records three
#                   revision rounds where each fix "produced another", and the
#                   loop was ended by a human noticing, not by the pipeline. A
#                   repeated signature is proof the loop is not converging, and
#                   it is worth catching on round 2 rather than burning the
#                   remaining budget to reach the same conclusion.
#
#   3. HARD ERROR   the generator failed, or the evaluator could not judge.
#
# Every trip writes content/staging/escalation.md and exits non-zero. The loop
# does not decide what to do about a defect it could not fix -- that is the
# human's call, and the escalation exists to make the call answerable.
#
# ------------------------------------------------------------------ safety --
#
# The generator writes into the working tree, so this refuses to start on a dirty
# one. That guard is what makes every run revertible with
# `git checkout . && git clean -fd`, and it is the reason a generator that shells
# out to an agent under bypassed permissions is defensible here.
#
# Exit codes:
#   0  PASS
#   1  the circuit breaker tripped; see content/staging/escalation.md
#   2  usage error
#   3  a precondition failed (dirty tree, missing hook, unrunnable hook)
#
# Portability: bash 3.2, which macOS still ships. No associative arrays.

set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
cd "$REPO_ROOT" || exit 3

readonly STAGING="content/staging"
readonly ESCALATION="$STAGING/escalation.md"
readonly DEFAULT_GENERATOR="tools/ger/generate_via_crew.sh"
readonly DEFAULT_EVALUATOR="tools/ger/evaluate_recipe_space.sh"

die() { printf '\033[31merror:\033[0m %s\n' "$1" >&2; exit "${2:-3}"; }
note() { printf '\033[1m==> %s\033[0m\n' "$1"; }
warn() { printf '\033[33m%s\033[0m\n' "$1"; }

usage() {
	cat >&2 <<'USAGE'
usage: ger_loop.sh --brief <text> [options]
       ger_loop.sh --brief-file <path> [options]

  --brief <text>          the design brief, in plain English
  --brief-file <path>     read the brief from a file instead
  --generator <cmd>       default: tools/ger/generate_via_crew.sh
  --evaluator <cmd>       default: tools/ger/evaluate_recipe_space.sh
  --max-attempts <n>      default: 3
  --allow-dirty           skip the clean-tree guard (self-tests only)
  -h, --help              this message
USAGE
	exit 2
}

brief=""
brief_file=""
generator="$DEFAULT_GENERATOR"
evaluator="$DEFAULT_EVALUATOR"
max_attempts=3
allow_dirty=0

while [ $# -gt 0 ]; do
	case "$1" in
		--brief) brief="${2:-}"; shift 2 || usage ;;
		--brief-file) brief_file="${2:-}"; shift 2 || usage ;;
		--generator) generator="${2:-}"; shift 2 || usage ;;
		--evaluator) evaluator="${2:-}"; shift 2 || usage ;;
		--max-attempts) max_attempts="${2:-}"; shift 2 || usage ;;
		--allow-dirty) allow_dirty=1; shift ;;
		-h|--help) usage ;;
		*) printf 'unknown argument: %s\n' "$1" >&2; usage ;;
	esac
done

case "$max_attempts" in
	''|*[!0-9]*) die "--max-attempts must be a positive integer, got '$max_attempts'" 2 ;;
esac
[ "$max_attempts" -ge 1 ] || die "--max-attempts must be at least 1" 2

if [ -n "$brief_file" ]; then
	[ -f "$brief_file" ] || die "brief file not found: $brief_file" 2
	brief="$(cat "$brief_file")"
fi
[ -n "$brief" ] || usage

[ -x "$generator" ] || die "generator is not executable: $generator"
[ -x "$evaluator" ] || die "evaluator is not executable: $evaluator"

# See the safety note in the header before adding an escape hatch here. The flag
# below exists for the self-test, which runs entirely on fixtures and never asks
# a generator to touch tracked content.
if [ "$allow_dirty" -eq 0 ] && [ -n "$(git status --porcelain 2>/dev/null)" ]; then
	git status --short
	die "working tree is dirty; commit or stash first so a run is revertible"
fi

mkdir -p "$STAGING" || die "cannot create $STAGING"
work="$(mktemp -d)" || die "cannot create a working directory"
trap 'rm -rf "$work"' EXIT

brief_path="$work/brief.txt"
printf '%s\n' "$brief" >"$brief_path"

defect_path="$work/defect.md"
: >"$defect_path"

# Normalise before hashing so cosmetic reordering does not read as a new defect,
# and so a run that reports the same three failures in a different order is
# correctly recognised as not having moved.
signature_of() {
	local file="$1"
	local hasher
	if command -v shasum >/dev/null 2>&1; then
		hasher="shasum -a 256"
	elif command -v sha256sum >/dev/null 2>&1; then
		hasher="sha256sum"
	else
		# No hasher is not a reason to lose oscillation detection; a sorted,
		# whitespace-collapsed copy of the defects compares just as well.
		sed -e 's/[[:space:]]\{1,\}/ /g' -e 's/^ //' -e 's/ $//' "$file" \
			| grep -v '^$' | sort | tr '\n' '|'
		return
	fi
	sed -e 's/[[:space:]]\{1,\}/ /g' -e 's/^ //' -e 's/ $//' "$file" \
		| grep -v '^$' | sort | $hasher | cut -d' ' -f1
}

# bash 3.2 has no associative arrays, so history is a newline-delimited string of
# "attempt<TAB>signature" and repeats are found with grep.
signature_history=""
verdict_log="$work/verdicts.md"
: >"$verdict_log"

trip_breaker() {
	local reason="$1"
	local detail="$2"
	{
		printf '# GER escalation\n\n'
		printf 'The loop could not self-correct. This is the pipeline stopping on\n'
		printf 'purpose, not a crash.\n\n'
		printf '## Brief\n\n> %s\n\n' "$brief"
		printf '## Why it stopped\n\n**%s.** %s\n\n' "$reason" "$detail"
		printf '## Configuration\n\n'
		printf -- '- generator: `%s`\n' "$generator"
		printf -- '- evaluator: `%s`\n' "$evaluator"
		printf -- '- attempt budget: %d\n\n' "$max_attempts"
		printf '## Every round\n\n'
		cat "$verdict_log"
		printf '\n## Defect signatures\n\n'
		printf 'Identical signatures on different attempts mean the loop revisited a\n'
		printf 'defect it had already been asked to fix.\n\n```\n'
		printf '%s\n' "$signature_history"
		printf '```\n\n'
		printf '## What a human needs to decide\n\n'
		printf 'The last round is still in the working tree. Inspect it, then either\n'
		printf 'accept the trade-off the loop kept failing to avoid, relax the rule the\n'
		printf 'evaluator enforces, or revert with `git checkout . && git clean -fd`.\n'
	} >"$ESCALATION"

	warn ""
	warn "CIRCUIT BREAKER TRIPPED — $reason"
	warn "$detail"
	warn ""
	printf 'escalation written to %s\n' "$ESCALATION" >&2
	exit 1
}

note "Brief"
printf '%s\n\n' "$brief"
note "Loop: generator=$generator evaluator=$evaluator max-attempts=$max_attempts"

attempt=1
while [ "$attempt" -le "$max_attempts" ]; do
	note "Attempt $attempt of $max_attempts — generating"
	if ! "$generator" "$brief_path" "$defect_path" "$attempt"; then
		status=$?
		printf -- '- attempt %d: generator exited %d\n' "$attempt" "$status" >>"$verdict_log"
		trip_breaker "The generator failed" \
			"\`$generator\` exited $status on attempt $attempt. A generator that cannot produce a candidate will not produce a better one on a retry, so the loop stopped rather than spending the remaining budget."
	fi

	note "Attempt $attempt — evaluating"
	: >"$defect_path"
	"$evaluator" "$defect_path"
	verdict=$?

	if [ "$verdict" -eq 0 ]; then
		printf -- '- attempt %d: PASS\n' "$attempt" >>"$verdict_log"
		note "PASS on attempt $attempt"
		rm -f "$ESCALATION"
		exit 0
	fi

	if [ "$verdict" -ge 2 ]; then
		printf -- '- attempt %d: evaluator error (exit %d)\n' "$attempt" "$verdict" >>"$verdict_log"
		trip_breaker "The evaluator could not reach a verdict" \
			"\`$evaluator\` exited $verdict, which is neither PASS nor REVISE. The loop refuses to refine against a judge it cannot trust: a defect nobody measured would send the generator chasing the wrong thing and make the eventual escalation blame the content."
	fi

	signature="$(signature_of "$defect_path")"
	{
		printf -- '- attempt %d: REVISE\n' "$attempt"
		sed 's/^/  /' "$defect_path"
	} >>"$verdict_log"

	printf '%s\n' "REVISE — defects:" >&2
	sed 's/^/  /' "$defect_path" >&2

	if printf '%s' "$signature_history" | grep -q "	$signature\$"; then
		earlier="$(printf '%s' "$signature_history" | grep "	$signature\$" | head -1 | cut -f1)"
		signature_history="$signature_history
$attempt	$signature"
		trip_breaker "The loop is oscillating" \
			"Attempt $attempt produced exactly the defects attempt $earlier produced. The generator is cycling between states rather than converging, which is what a local fix to a global constraint does — see docs/crew/ASSIGNMENT-4.md. Spending the rest of the budget would reach this same conclusion more slowly."
	fi

	if [ -z "$signature_history" ]; then
		signature_history="$attempt	$signature"
	else
		signature_history="$signature_history
$attempt	$signature"
	fi

	attempt=$((attempt + 1))
done

trip_breaker "The attempt budget ran out" \
	"$max_attempts attempts produced $max_attempts different sets of defects without a PASS. The loop was making progress in the sense that it never repeated itself, but it did not converge within budget."
