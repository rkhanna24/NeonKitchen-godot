#!/usr/bin/env bash
#
# Project-owned verification gate. CI runs this exact script, so local and
# continuous-integration results cannot drift.
#
#   ./scripts/check.sh
#
# Engine binary resolution, in order:
#   1. $GODOT_BIN
#   2. `godot` on PATH
#   3. /Applications/Godot.app/Contents/MacOS/Godot   (macOS default)
#
# The pinned engine is recorded in docs/adr/0001-pin-godot-version.md. The macOS
# bundle name carries no version, so this script asserts the version string
# rather than trusting the path.
#
# Portability: must run on bash 3.2, which macOS still ships. No `mapfile`, no
# associative arrays, and no reliance on `set -u` with empty arrays.

set -o pipefail

readonly EXPECTED_GODOT_VERSION="4.7.1.stable.official.a13da4feb"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
cd "$REPO_ROOT" || exit 1

failures=0

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
pass() { printf '    \033[32mPASS\033[0m %s\n' "$1"; }
fail() { printf '    \033[31mFAIL\033[0m %s\n' "$1"; failures=$((failures + 1)); }

# Any unexpected error is a failure, never a silent skip.
trap 'fail "unexpected error on line $LINENO"' ERR

# ---------------------------------------------------------------- engine ----
if [ -n "${GODOT_BIN:-}" ]; then
	godot_bin="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
	godot_bin="$(command -v godot)"
elif [ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]; then
	godot_bin="/Applications/Godot.app/Contents/MacOS/Godot"
else
	echo "No Godot binary found. Set GODOT_BIN or put godot on PATH." >&2
	exit 1
fi

step "Engine version"
actual_version="$("$godot_bin" --version 2>/dev/null | tr -d '\r')"
if [ "$actual_version" = "$EXPECTED_GODOT_VERSION" ]; then
	pass "$actual_version"
else
	fail "expected $EXPECTED_GODOT_VERSION, got ${actual_version:-<none>}"
fi

# ------------------------------------------------------------- gdtoolkit ----
if [ -x ".venv/bin/gdformat" ]; then
	gdformat_bin="$REPO_ROOT/.venv/bin/gdformat"
	gdlint_bin="$REPO_ROOT/.venv/bin/gdlint"
elif command -v gdformat >/dev/null 2>&1; then
	gdformat_bin="gdformat"
	gdlint_bin="gdlint"
else
	echo "gdtoolkit not found. Run ./scripts/setup.sh first." >&2
	exit 1
fi

# Project-owned GDScript only. Vendored addons and the venv are never checked.
gd_list="$(mktemp)"
trap 'rm -f "$gd_list"' EXIT
find . -name '*.gd' \
	-not -path './.godot/*' \
	-not -path './.venv/*' \
	-not -path './addons/*' \
	| sort >"$gd_list"
gd_count="$(wc -l <"$gd_list" | tr -d ' ')"

step "Format (gdformat --check)"
if [ "$gd_count" -eq 0 ]; then
	pass "no project GDScript files yet"
elif xargs "$gdformat_bin" --check <"$gd_list"; then
	pass "$gd_count file(s) formatted"
else
	fail "run: $gdformat_bin <files>"
fi

step "Lint (gdlint)"
if [ "$gd_count" -eq 0 ]; then
	pass "no project GDScript files yet"
elif xargs "$gdlint_bin" <"$gd_list"; then
	pass "$gd_count file(s) clean"
else
	fail "gdlint reported problems"
fi

# ---------------------------------------------------------------- import ----
step "Headless import"
if "$godot_bin" --headless --path . --import >/tmp/nk_import.log 2>&1; then
	pass "project imports"
else
	fail "import failed; see /tmp/nk_import.log"
fi

# ----------------------------------------------------------- type checks ----
# Godot reports GDScript warnings-as-errors but still exits 0, so the exit code
# cannot be trusted here. Output is inspected instead.
step "Type and warning check"
if [ "$gd_count" -eq 0 ]; then
	pass "no project GDScript files yet"
else
	script_errors=0
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		out="$("$godot_bin" --headless --path . --check-only -s "$f" 2>&1 || true)"
		if printf '%s' "$out" | grep -qE 'SCRIPT ERROR|Parse Error'; then
			printf '    %s\n' "$f"
			printf '%s' "$out" | grep -E 'SCRIPT ERROR|Parse Error' | sed 's/^/      /'
			script_errors=$((script_errors + 1))
		fi
	done <"$gd_list"
	if [ "$script_errors" -eq 0 ]; then
		pass "$gd_count file(s) clean"
	else
		fail "$script_errors file(s) with script errors"
	fi
fi

# --------------------------------------------------------- domain purity ----
# ADR 0002 section 4: the domain contains no randomness and no wall-clock time.
step "Domain purity (no randomness or clock in core/domain)"
if [ -d "core/domain" ]; then
	if hits="$(grep -rnE '\b(randf|randi|randomize|rand_from_seed)\b|\bTime\.|OS\.get_ticks' core/domain 2>/dev/null)"; then
		printf '%s\n' "$hits" | sed 's/^/      /'
		fail "forbidden randomness or time access in core/domain"
	else
		pass "core/domain is pure"
	fi
else
	pass "core/domain does not exist yet"
fi

# ------------------------------------------------------------------ tests ----
# GUT v9.7.1, pinned by docs/adr/0003-test-framework.md.
#
# -ginclude_subdirs is required: GUT does not recurse into tests/unit,
# tests/content, tests/contract, or tests/golden without it, and reports
# "Nothing was run" while still exiting 0. A zero-test run is treated as a
# failure here so broken discovery cannot pass silently.
step "Tests"
if [ ! -f "addons/gut/gut_cmdln.gd" ]; then
	# Never a soft pass: a missing harness must not look like a green run.
	fail "GUT not installed -- run ./scripts/setup.sh"
else
	gut_log="$(mktemp)"
	# Kept inside an `if`, so a failing suite does not also trip the ERR trap.
	if "$godot_bin" --headless --path . -s addons/gut/gut_cmdln.gd \
		-gdir=res://tests -ginclude_subdirs -gexit >"$gut_log" 2>&1; then
		gut_status=0
	else
		gut_status=1
	fi
	tests_run="$(sed -n 's/^Tests  *\([0-9][0-9]*\).*/\1/p' "$gut_log" | head -1)"
	[ -n "$tests_run" ] || tests_run=0

	if [ "$gut_status" -ne 0 ]; then
		sed -n '/Run Summary/,$p' "$gut_log" | sed 's/^/      /'
		fail "test suite ($tests_run test(s) ran)"
	elif [ "$tests_run" -eq 0 ]; then
		fail "no tests were discovered under res://tests"
	else
		pass "$tests_run test(s)"
	fi
	rm -f "$gut_log"
fi

# ---------------------------------------------------------------- summary ----
printf '\n'
if [ "$failures" -eq 0 ]; then
	printf '\033[32mAll checks passed.\033[0m\n'
	exit 0
fi
printf '\033[31m%d check(s) failed.\033[0m\n' "$failures"
exit 1
