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

# Floors for the test run. Bump them deliberately when tests are added, and
# lower them only when a suite is deleted on purpose.
#
# This exists because a green run is not the same as a complete one: GUT does
# not fail a test it never collected, so a test that stops being discovered
# reports as silence rather than as red.
#
# The prompt was a `String(Variant)` that took a whole file out of discovery,
# 245 tests across 27 scripts becoming 237 across 26 with nothing going red.
# That particular case is already caught upstream by the "Type and warning
# check" step, which is worth being precise about -- the near-miss happened
# while running GUT directly, not while running this script.
#
# What the floor covers is everything that leaves a file *parsing correctly*
# and still uncollected: a test class that no longer extends `GutTest`, a
# `test_` prefix lost in a rename, a file moved out of `res://tests`, a
# directory deleted, or `-gdir`/`-ginclude_subdirs` drifting. None of those is
# a script error, and all of them are silent.
#
# The script count matters as much as the test count: deleting one file's worth
# of tests while adding the same number elsewhere keeps the total flat.
readonly MIN_TEST_SCRIPTS=26
readonly MIN_TESTS=233
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

# ------------------------------------------------- dependency direction ----
# ADR 0002 section 2 and technical architecture section 4: adapters depend
# inward; the domain imports neither application nor adapter code. This is the
# rule that makes the GDD's "evaluator callable without either interface" true.
step "Dependency direction (adapters depend inward)"

# refs_from <dir> <forbidden-path-segment>
refs_from() {
	[ -d "$1" ] || return 1
	grep -rnE "res://$2/" "$1" --include='*.gd' 2>/dev/null
}

dep_violations=0
check_layer() { # <source dir> <forbidden segment> <human description>
	hits="$(refs_from "$1" "$2")" || return 0
	if [ -n "$hits" ]; then
		printf '%s\n' "$hits" | sed 's/^/      /'
		printf '    %s must not reference %s\n' "$1" "$3"
		dep_violations=$((dep_violations + 1))
	fi
}

for forbidden in adapters features bootstrap; do
	check_layer "core" "$forbidden" "$forbidden/"
done
check_layer "core/domain" "core/application" "the application layer"

# Path references are definitive. A domain file could also reach an adapter by
# its class_name with no path, so those are checked too, as a heuristic.
if [ -d "core" ]; then
	for outer in adapters features bootstrap; do
		[ -d "$outer" ] || continue
		# `|| true`: grep exits 1 when it matches nothing, which would trip the
		# ERR trap and fail a clean tree.
		outer_classes="$(grep -rhoE '^class_name[[:space:]]+[A-Za-z0-9_]+' "$outer" \
			--include='*.gd' 2>/dev/null | awk '{print $2}' | sort -u || true)"
		for cls in $outer_classes; do
			hits="$(grep -rnwE "$cls" core --include='*.gd' 2>/dev/null || true)"
			if [ -n "$hits" ]; then
				printf '%s\n' "$hits" | sed 's/^/      /'
				printf '    core/ references %s, declared in %s/\n' "$cls" "$outer"
				dep_violations=$((dep_violations + 1))
			fi
		done
	done
fi

if [ ! -d "core" ]; then
	pass "core/ does not exist yet"
elif [ "$dep_violations" -eq 0 ]; then
	pass "no inward-only violations"
else
	fail "$dep_violations dependency-direction violation(s)"
fi

# ------------------------------------------------------ repository layout ----
# ADR 0002 section 7.
step "Layout (no empty directories, shared/ needs two consumers)"
layout_ok=1

# Git-ignored paths are excluded. This check is about the *repository's* layout,
# and an ignored directory is by definition not part of it -- a scratch tool or a
# node_modules scaffold with an empty folder in it is not a layout defect. The
# hardcoded skips remain for paths that are ignored anyway but are worth naming.
# `git check-ignore` is the authority on what is ignored, so this cannot drift
# from .gitignore the way a second hand-maintained list would.
empties="$(find . -type d -empty \
	-not -path './.git/*' -not -path './.godot/*' \
	-not -path './.venv/*' -not -path './addons/*' 2>/dev/null \
	| { grep -vxFf <(git check-ignore $(find . -type d -empty -not -path './.git/*' 2>/dev/null) 2>/dev/null || true) || true; })"
if [ -n "$empties" ]; then
	printf '%s\n' "$empties" | sed 's/^/      /'
	fail "empty directories are not permitted"
	layout_ok=0
fi

if [ -d "shared" ]; then
	while IFS= read -r f; do
		[ -n "$f" ] || continue
		# Search for the token consumers actually write. A file declaring
		# `class_name EncounterText` is referenced by that name, never by its
		# snake_case filename, so matching on the file stem found zero consumers
		# for every correctly-written file and this check could not pass. It had
		# never run against a real file: `shared/` was empty from the day the
		# rule was added until the first file landed.
		token="$(sed -n 's/^class_name \([A-Za-z0-9_]*\).*/\1/p' "$f" | head -1)"
		if [ -z "$token" ]; then
			base="$(basename "$f")"
			token="${base%.gd}"
		fi
		# `|| true`: with pipefail a zero-match grep fails the pipeline, so the
		# assignment fails and the ERR trap fires on top of the correct
		# "fewer than two consumers" diagnosis.
		consumers="$(grep -rlw "$token" . --include='*.gd' 2>/dev/null \
			| grep -v '^./shared/' | grep -v '^./addons/' | sort -u | wc -l || true)"
		if [ "$(echo "$consumers" | tr -d ' ')" -lt 2 ]; then
			printf '      %s has fewer than two consumers\n' "$f"
			layout_ok=0
		fi
	done <<EOF
$(find shared -name '*.gd' 2>/dev/null)
EOF
	[ "$layout_ok" -eq 1 ] || fail "shared/ requires two real consumers per file"
fi

# Written as if/then, not `[ ... ] && pass`: the latter returns non-zero
# whenever layout_ok is 0, which trips the ERR trap and inflates the count.
if [ "$layout_ok" -eq 1 ]; then
	pass "layout clean"
fi

# ------------------------------------------------------------ uid sidecars ----
# AGENTS.md rule 11. Runs after import so Godot has generated any new sidecars.
step "Resource UID sidecars"
uid_problems=0

while IFS= read -r f; do
	[ -n "$f" ] || continue
	[ -f "${f}.uid" ] || {
		printf '      missing sidecar: %s.uid\n' "$f"
		uid_problems=$((uid_problems + 1))
	}
done <"$gd_list"

# The real hazard is a .uid being ignored, not merely uncommitted.
while IFS= read -r u; do
	[ -n "$u" ] || continue
	# --no-index is required: without it git consults the index, so an
	# already-tracked file reports as not-ignored even when a rule matches.
	# The hazard is the rule existing, which would silently drop future
	# sidecars, so the rule is what must be checked.
	if git check-ignore --no-index -q "$u" 2>/dev/null; then
		printf '      gitignored (must be committed): %s\n' "$u"
		uid_problems=$((uid_problems + 1))
	fi
	[ -f "${u%.uid}" ] || {
		printf '      orphan, no source file: %s\n' "$u"
		uid_problems=$((uid_problems + 1))
	}
done <<EOF
$(find . -name '*.gd.uid' -not -path './.godot/*' -not -path './.venv/*' \
	-not -path './addons/*' 2>/dev/null)
EOF

if [ "$uid_problems" -eq 0 ]; then
	pass "sidecars present, tracked, and paired"
else
	fail "$uid_problems UID sidecar problem(s)"
fi

# ----------------------------------------------------------- recipe audit ----
# GDD section 3's Week 3 all-combination audit. Regenerates the report in memory
# and compares it against the committed copy.
#
# This fails on *drift* only, never on the audit's own PASS/REVISE verdict. A
# balance finding is for the human to act on; wiring it to the gate would let a
# known content problem block every unrelated change. See
# bootstrap/audit_recipe_space.gd.
step "Recipe space audit (committed report matches content)"
if [ ! -f "bootstrap/audit_recipe_space.gd" ]; then
	fail "bootstrap/audit_recipe_space.gd is missing"
else
	audit_log="$(mktemp)"
	if "$godot_bin" --headless --path . -s bootstrap/audit_recipe_space.gd -- --check \
		>"$audit_log" 2>&1; then
		pass "docs/design/Recipe Space Audit.md is current"
	else
		# `|| true`: a zero-match grep fails the pipeline under pipefail, which
		# would trip the ERR trap on top of the correct diagnosis below.
		{ grep -aE 'audit:|committed:|regenerated:|content error:' "$audit_log" || true; } \
			| sed 's/^/      /'
		fail "stale; regenerate with: $godot_bin --headless --path . -s bootstrap/audit_recipe_space.gd"
	fi
	rm -f "$audit_log"
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
	scripts_run="$(sed -n 's/^Scripts  *\([0-9][0-9]*\).*/\1/p' "$gut_log" | head -1)"
	[ -n "$scripts_run" ] || scripts_run=0

	if [ "$gut_status" -ne 0 ]; then
		sed -n '/Run Summary/,$p' "$gut_log" | sed 's/^/      /'
		fail "test suite ($tests_run test(s) ran)"
	elif [ "$tests_run" -eq 0 ]; then
		fail "no tests were discovered under res://tests"
	elif [ "$scripts_run" -lt "$MIN_TEST_SCRIPTS" ] || [ "$tests_run" -lt "$MIN_TESTS" ]; then
		printf '      expected at least %d script(s) and %d test(s)\n' \
			"$MIN_TEST_SCRIPTS" "$MIN_TESTS"
		printf '      got %d script(s) and %d test(s)\n' "$scripts_run" "$tests_run"
		printf '      GUT cannot fail a test it never collected. Look for a class that\n'
		printf '      no longer extends GutTest, a lost test_ prefix, a file moved out\n'
		printf '      of res://tests, or a deliberate deletion -- if deletion, lower the\n'
		printf '      floor in this script in the same commit.\n'
		fail "fewer tests ran than the floor; see the note above the floor in this script"
	else
		pass "$tests_run test(s) across $scripts_run script(s)"
	fi
	rm -f "$gut_log"
fi

# ----------------------------------------------------------------- export ----
# Delegated to scripts/verify_export.sh, which explains what it checks and why.
#
# In the gate rather than beside it, unlike verify_flavor_model.sh: an export
# failure is invisible until somebody exports, and the whole reason #46 was
# filed early is that the last weekend of a project is the worst possible place
# to discover one. It needs no export templates -- only the committed preset --
# so CI can run it too.
#
# It costs about fifteen seconds, most of it waiting for the exported build to
# start and load. That is the price of the one check that runs the game the way
# a player would get it.
step "Export"
if [ ! -x "scripts/verify_export.sh" ]; then
	fail "scripts/verify_export.sh is missing or not executable"
elif export_out="$(./scripts/verify_export.sh 2>&1)"; then
	printf '%s\n' "$export_out" | grep -a 'PASS' | sed 's/^ *//; s/^/    /'
else
	printf '%s\n' "$export_out" | sed 's/^/      /'
	fail "the exported build is broken; run ./scripts/verify_export.sh"
fi

# ---------------------------------------------------------------- summary ----
printf '\n'
if [ "$failures" -eq 0 ]; then
	printf '\033[32mAll checks passed.\033[0m\n'
	exit 0
fi
printf '\033[31m%d check(s) failed.\033[0m\n' "$failures"
exit 1
