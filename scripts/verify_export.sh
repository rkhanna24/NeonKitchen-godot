#!/usr/bin/env bash
#
# Proves the game still exports, that the exported pack carries the whole
# content set, and that it carries nothing it should not.
#
#   ./scripts/verify_export.sh
#
# Why this exists separately from a full platform export: producing a runnable
# binary needs Godot's export templates, a ~1GB download that is not a declared
# project dependency and that CI would have to fetch. `--export-pack` needs only
# the preset, and the pack is where every risk this checks actually lives.
#
# The risk is specific. An export rewrites every `.tres` into a `.tres.remap`,
# and `TresContentRepository._resource_paths` handles that -- including a
# de-duplication branch for when both forms are present. That code was written
# from documentation and, until this script existed, had never once executed.
# A repository that resolved none of them would report a directory-level
# failure and open a blank kitchen with no error the player could see.
#
# Portability: bash 3.2, which macOS still ships.

set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
cd "$REPO_ROOT" || exit 1

readonly PRESET="macOS"

# The whole shipped content set. Bump these when content is added; they are the
# reason a new customer that fails to export is a failure rather than a silence.
readonly EXPECTED_INGREDIENTS=12
readonly EXPECTED_CUSTOMERS=8

# Paths that must never reach a player's build.
readonly FORBIDDEN="tests/ addons/gut content/test_fixtures audit_recipe_space"

failures=0
step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
pass() { printf '    \033[32mPASS\033[0m %s\n' "$1"; }
fail() { printf '    \033[31mFAIL\033[0m %s\n' "$1"; failures=$((failures + 1)); }

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

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
pack="$work/neon_kitchen.pck"

step "Export pack"
if "$godot_bin" --headless --path . --export-pack "$PRESET" "$pack" >"$work/export.log" 2>&1; then
	# Strip ANSI colour before parsing; Godot writes the manifest with it.
	sed 's/\x1b\[[0-9;]*m//g' "$work/export.log" \
		| grep -o 'Storing File: res://.*' | sed 's/Storing File: //' | sort >"$work/manifest.txt"
	pass "$(wc -l <"$work/manifest.txt" | tr -d ' ') file(s) packed"
else
	tail -20 "$work/export.log" | sed 's/^/      /'
	fail "export failed; is export_presets.cfg present and the preset named $PRESET?"
	printf '\n\033[31m%d check(s) failed.\033[0m\n' "$failures"
	exit 1
fi

step "The whole content set is in the build"
ingredients="$(grep -c 'content/base/ingredients' "$work/manifest.txt" || true)"
customers="$(grep -c 'content/base/customers' "$work/manifest.txt" || true)"
if [ "$ingredients" -eq "$EXPECTED_INGREDIENTS" ] && [ "$customers" -eq "$EXPECTED_CUSTOMERS" ]; then
	pass "$ingredients ingredient(s), $customers customer(s)"
else
	fail "expected $EXPECTED_INGREDIENTS/$EXPECTED_CUSTOMERS, packed $ingredients/$customers"
fi

step "Translations are in the build"
# An unregistered or unpacked translation makes tr() return the key unchanged,
# which is indistinguishable from success to every caller. See
# tests/unit/test_localization.gd for the same failure in the editor.
if grep -q '\.translation$' "$work/manifest.txt"; then
	pass "compiled translation packed"
else
	fail "no .translation in the pack; every string would render as its key"
fi

step "Nothing that should not ship"
leaked=0
for path in $FORBIDDEN; do
	hits="$(grep -c "$path" "$work/manifest.txt" || true)"
	if [ "$hits" -ne 0 ]; then
		printf '      %s: %s file(s)\n' "$path" "$hits"
		leaked=$((leaked + 1))
	fi
done
if [ "$leaked" -eq 0 ]; then
	pass "no test, fixture, harness, or tooling files packed"
else
	fail "$leaked path(s) leaked into the build"
fi

step "The exported build loads its content"
# The load path is what matters here, not the frame: an export turns every
# .tres into a .tres.remap, and this is the only place that resolution is
# exercised. `_fail_loudly` prints as well as draws precisely so a headless run
# can observe it -- silence below means all 20 resources resolved AND passed
# full validation, since the repository refuses to serve a set with problems.
(cd "$work" && "$godot_bin" --headless --main-pack "$pack" >run.log 2>&1) &
run_pid=$!
sleep 10
kill "$run_pid" 2>/dev/null
wait "$run_pid" 2>/dev/null
if grep -aq 'content error' "$work/run.log"; then
	grep -a 'content error' "$work/run.log" | head -5 | sed 's/^/      /'
	fail "the exported build could not load its content"
elif grep -aqE 'SCRIPT ERROR|Parse Error' "$work/run.log"; then
	grep -aE 'SCRIPT ERROR|Parse Error' "$work/run.log" | head -5 | sed 's/^/      /'
	fail "the exported build raised a script error"
else
	pass "content resolved through .tres.remap and validated"
fi

printf '\n'
if [ "$failures" -eq 0 ]; then
	printf '\033[32mExport verified.\033[0m\n'
	exit 0
fi
printf '\033[31m%d check(s) failed.\033[0m\n' "$failures"
exit 1
