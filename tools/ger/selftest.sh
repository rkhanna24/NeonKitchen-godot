#!/usr/bin/env bash
#
# Proves the GER loop's control flow with scripted hooks.
#
#   tools/ger/selftest.sh
#
# Every case here runs on fixture generators and evaluators: no API key, no
# Godot, no content touched. That is the point. The loop's job is to decide when
# to keep going and when to stop, and that decision is worth testing on its own,
# separately from whether the recipe-space evaluator judges a pantry correctly.
#
# The circuit breaker is the part that is hard to demonstrate honestly on real
# content -- you would have to author content bad enough to fail three times in a
# specific pattern. Scripted verdicts make each trip reproducible in a second.
#
# Exit 0 if every case behaves as expected, 1 otherwise.

set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
readonly REPO_ROOT
cd "$REPO_ROOT" || exit 1

readonly LOOP="tools/ger_loop.sh"
readonly ESCALATION="content/staging/escalation.md"

work="$(mktemp -d)" || exit 1
trap 'rm -rf "$work"; rm -f "$ESCALATION"' EXIT

failures=0
cases=0

pass() { printf '  \033[32mok\033[0m   %s\n' "$1"; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; failures=$((failures + 1)); }

# A generator that always succeeds, and records the defect text it was handed so
# a test can assert the refinement channel actually carried something.
make_generator() {
	cat >"$work/gen.sh" <<'GEN'
#!/usr/bin/env bash
cp "$2" "$WORK/seen-defect-$3.md" 2>/dev/null || true
echo "  [fixture generator] attempt $3"
exit 0
GEN
	chmod +x "$work/gen.sh"
}

# A generator that fails on the attempt named by $FAIL_ON.
make_failing_generator() {
	cat >"$work/gen_fail.sh" <<'GEN'
#!/usr/bin/env bash
if [ "$3" = "$FAIL_ON" ]; then
	echo "  [fixture generator] deliberate failure on attempt $3" >&2
	exit 7
fi
exit 0
GEN
	chmod +x "$work/gen_fail.sh"
}

# An evaluator driven by a verdict script: one line per attempt, either
# "PASS", "ERROR", or "REVISE:<text>".
make_evaluator() {
	cat >"$work/eval.sh" <<'EVAL'
#!/usr/bin/env bash
n=1
[ -f "$WORK/count" ] && n=$(cat "$WORK/count")
echo $((n + 1)) >"$WORK/count"
verdict="$(sed -n "${n}p" "$WORK/verdicts")"
case "$verdict" in
	PASS) : >"$1"; exit 0 ;;
	ERROR) echo "  [fixture evaluator] cannot judge" >&2; exit 2 ;;
	REVISE:*) printf '%s\n' "${verdict#REVISE:}" | tr '|' '\n' >"$1"; exit 1 ;;
	*) echo "  [fixture evaluator] no verdict scripted for attempt $n" >&2; exit 2 ;;
esac
EVAL
	chmod +x "$work/eval.sh"
}

# run_case <name> <expected-exit> <verdicts...> -- runs the loop and checks the
# exit code. Verdicts are passed one per argument.
run_case() {
	local name="$1"; shift
	local expected="$1"; shift
	local generator="$1"; shift
	cases=$((cases + 1))
	rm -f "$work/count" "$ESCALATION" "$work"/seen-defect-*.md
	printf '%s\n' "$@" >"$work/verdicts"
	WORK="$work" FAIL_ON="${FAIL_ON:-}" "$LOOP" \
		--brief "self-test brief" \
		--generator "$generator" \
		--evaluator "$work/eval.sh" \
		--max-attempts 3 \
		--allow-dirty >"$work/out.txt" 2>&1
	local actual=$?
	if [ "$actual" -eq "$expected" ]; then
		pass "$name (exit $actual)"
		return 0
	fi
	fail "$name — expected exit $expected, got $actual"
	sed 's/^/       /' "$work/out.txt"
	return 1
}

# Asserts the escalation names the reason it should, so a trip cannot pass this
# suite by tripping for the wrong cause.
assert_escalation() {
	local name="$1"
	local needle="$2"
	cases=$((cases + 1))
	if [ ! -f "$ESCALATION" ]; then
		fail "$name — no escalation written"
		return 1
	fi
	if grep -qi "$needle" "$ESCALATION"; then
		pass "$name"
		return 0
	fi
	fail "$name — escalation does not mention '$needle'"
	sed 's/^/       /' "$ESCALATION"
	return 1
}

assert_no_escalation() {
	local name="$1"
	cases=$((cases + 1))
	if [ -f "$ESCALATION" ]; then
		fail "$name — an escalation was written on a passing run"
		return 1
	fi
	pass "$name"
}

make_generator
make_failing_generator
make_evaluator

printf '\033[1mGER loop self-test\033[0m\n\n'

printf 'accepting\n'
run_case "passes on the first attempt" 0 "$work/gen.sh" "PASS"
assert_no_escalation "a passing run leaves no escalation"

run_case "refines once, then passes" 0 "$work/gen.sh" "REVISE:office_worker has 1 distinct centre" "PASS"
cases=$((cases + 1))
if [ -f "$work/seen-defect-2.md" ] && grep -q "office_worker" "$work/seen-defect-2.md"; then
	pass "the generator received the specific defect, not just a failure"
else
	fail "the defect was not handed to the generator on attempt 2"
fi

printf '\nbreaker trips\n'
run_case "budget exhausted on three distinct defects" 1 "$work/gen.sh" \
	"REVISE:defect A" "REVISE:defect B" "REVISE:defect C"
assert_escalation "escalation blames the attempt budget" "attempt budget ran out"

run_case "oscillation caught on the repeat" 1 "$work/gen.sh" \
	"REVISE:the same defect" "REVISE:the same defect" "PASS"
assert_escalation "escalation blames oscillation" "oscillating"

# The repeat above was on attempt 2 of a 3-attempt budget, and attempt 3 was
# scripted to PASS. Tripping anyway is the intended behaviour: a loop that has
# demonstrably stopped converging should not be given another turn on the
# strength of hope.
cases=$((cases + 1))
if grep -q "Attempt 2 produced exactly the defects attempt 1 produced" "$ESCALATION"; then
	pass "oscillation trips before spending the remaining budget"
else
	fail "oscillation did not trip on the second attempt"
fi

run_case "non-consecutive repeat also counts" 1 "$work/gen.sh" \
	"REVISE:first" "REVISE:second" "REVISE:first"
assert_escalation "a defect seen two rounds ago still counts as oscillation" "oscillating"

run_case "evaluator error is not treated as REVISE" 1 "$work/gen.sh" "ERROR"
assert_escalation "escalation blames the evaluator" "could not reach a verdict"

FAIL_ON=1 run_case "generator failure trips immediately" 1 "$work/gen_fail.sh" "PASS"
assert_escalation "escalation blames the generator" "generator failed"

printf '\nnormalisation\n'
run_case "reordered defects are the same signature" 1 "$work/gen.sh" \
	"REVISE:alpha|beta" "REVISE:beta|alpha" "PASS"
assert_escalation "cosmetic reordering does not read as progress" "oscillating"

printf '\n'
if [ "$failures" -eq 0 ]; then
	printf '\033[32m%d checks, all passed\033[0m\n' "$cases"
	exit 0
fi
printf '\033[31m%d checks, %d failed\033[0m\n' "$cases" "$failures"
exit 1
