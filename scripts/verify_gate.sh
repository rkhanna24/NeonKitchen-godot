#!/usr/bin/env bash
#
# Verifies every architecture check in scripts/check.sh in the FAILING
# direction. A check that cannot go red is not a check.
#
#   ./scripts/verify_gate.sh
#
# Each case introduces one violation, asserts the gate names it and exits
# nonzero, removes it, and finally asserts the tree is green again.
#
# SAFETY: this writes into the live working tree, so it only ever creates and
# deletes paths carrying the _gateverify_ sentinel, and refuses to start if any
# already exist. The first version used `rm -rf core adapters` in its cleanup,
# which was harmless while those directories were empty and would have deleted
# real source the moment they were not. Never widen these deletions.

cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)" || exit 1

readonly SENTINEL="_gateverify"
pass_count=0
fail_count=0

# Case 6 appends to .gitignore. Restore the original BYTES rather than running
# `git checkout`, which would silently discard a developer's uncommitted edits
# to that file -- contradicting this script's own safety promise.
GITIGNORE_BACKUP="$(mktemp)"
readonly GITIGNORE_BACKUP
# Installed immediately: three pre-flight bail-outs follow, and each would
# otherwise exit with the temp file already created and never removed.
trap 'rm -f "$GITIGNORE_BACKUP"' EXIT
if ! cp .gitignore "$GITIGNORE_BACKUP" || [ ! -s "$GITIGNORE_BACKUP" ]; then
	echo "Refusing to run: could not back up .gitignore." >&2
	exit 1
fi

# Every path this script may create. Nothing outside this list is removed.
sentinel_paths() {
	cat <<-LIST
		core/domain/rules/${SENTINEL}_bad.gd
		core/domain/rules/${SENTINEL}_bad.gd.uid
		core/domain/${SENTINEL}_consumer.gd
		core/domain/${SENTINEL}_consumer.gd.uid
		core/application/${SENTINEL}_session.gd
		core/application/${SENTINEL}_session.gd.uid
		core/domain/${SENTINEL}_emptydir
		adapters/content/${SENTINEL}_adapter.gd
		adapters/content/${SENTINEL}_adapter.gd.uid
		shared/${SENTINEL}_helper.gd
		shared/${SENTINEL}_helper.gd.uid
		tests/unit/${SENTINEL}_orphan.gd.uid
	LIST
}

for p in $(sentinel_paths); do
	if [ -e "$p" ]; then
		echo "Refusing to run: $p already exists. Remove it first." >&2
		exit 1
	fi
done
if [ -e shared ]; then
	echo "Refusing to run: shared/ already exists; this script creates it." >&2
	exit 1
fi

scrub() {
	for p in $(sentinel_paths); do
		if [ -d "$p" ]; then
			rmdir "$p" 2>/dev/null
		elif [ -f "$p" ]; then
			rm -f "$p"
		fi
	done
	rmdir shared 2>/dev/null
	# Every directory prepare() creates, children before parents. rmdir only
	# removes an empty directory, so a real one with content is never touched.
	rmdir core/domain/rules core/application adapters/content tests/unit 2>/dev/null
	rmdir core/domain adapters tests 2>/dev/null
	rmdir core 2>/dev/null
	# Non-empty guard: restoring from a failed backup would blank the
	# developer's .gitignore, the opposite of this script's promise.
	if [ -s "$GITIGNORE_BACKUP" ]; then
		cp "$GITIGNORE_BACKUP" .gitignore
	fi
	return 0
}
cleanup_all() { scrub; rm -f "$GITIGNORE_BACKUP"; }
# Replaces the narrow pre-flight trap now that scrub() is defined.
trap cleanup_all EXIT

expect_red() { # <label> <substring the gate must print>
	./scripts/check.sh >/tmp/vg.txt 2>&1
	code=$?
	if [ "$code" -ne 0 ] && grep -q "$2" /tmp/vg.txt; then
		printf '  \033[32mOK\033[0m   %s -> exit %s, reported\n' "$1" "$code"
		pass_count=$((pass_count + 1))
	else
		printf '  \033[31mBAD\033[0m  %s -> exit %s, expected %s\n' "$1" "$code" "$2"
		grep -E 'FAIL|==>' /tmp/vg.txt | tail -6 | sed 's/^/         /'
		fail_count=$((fail_count + 1))
	fi
	scrub
}

# scrub() removes directories it created, so each scenario re-makes what it
# needs. assert_exists() then guarantees the violation actually landed -- a
# redirect into a missing directory would otherwise leave the tree clean and
# the gate would "pass", turning a broken harness into a green result.
# Make ONLY the directories a case will put a file in. A blanket mkdir left
# core/domain/rules and core/application empty for the whole run, so every case
# ran against a tree already violating "no empty directories" -- defeating
# case 4 entirely and adding a spurious second violation to the rest.
prepare() { for d in "$@"; do mkdir -p "$d"; done; }
assert_exists() {
	[ -e "$1" ] && return 0
	printf '  \033[31mBAD\033[0m  harness failed to create %s\n' "$1"
	fail_count=$((fail_count + 1))
	# scrub here too: expect_red is short-circuited past on failure, so
	# without this the leftover files leak into every later case.
	scrub
	return 1
}

echo "=== 1. domain references an adapter by path ==="
prepare core/domain/rules adapters/content
# Self-contained: referencing a real production file would keep reporting OK
# after that file is renamed, while breaking the type check instead.
printf 'extends RefCounted\n\n\nfunc noop() -> int:\n\treturn 1\n' \
	>"adapters/content/${SENTINEL}_adapter.gd"
printf 'extends RefCounted\n\nconst R := preload("res://adapters/content/%s_adapter.gd")\n\n\nfunc use() -> int:\n\treturn 1\n' "$SENTINEL" \
	>"core/domain/rules/${SENTINEL}_bad.gd"
assert_exists "core/domain/rules/${SENTINEL}_bad.gd" && expect_red "path reference core -> adapters" "must not reference adapters"

echo "=== 2. domain references an adapter by class_name ==="
prepare core/domain/rules adapters/content
printf 'class_name GateVerifyAdapter\nextends RefCounted\n\n\nfunc noop() -> int:\n\treturn 1\n' \
	>"adapters/content/${SENTINEL}_adapter.gd"
printf 'extends RefCounted\n\n\nfunc use() -> int:\n\tvar a: GateVerifyAdapter = null\n\treturn 1 if a == null else 0\n' \
	>"core/domain/rules/${SENTINEL}_bad.gd"
assert_exists "core/domain/rules/${SENTINEL}_bad.gd" && expect_red "class_name reference core -> adapters" "declared in adapters/"

echo "=== 3. domain references the application layer ==="
prepare core/domain/rules core/application
printf 'extends RefCounted\n\n\nfunc noop() -> int:\n\treturn 1\n' \
	>"core/application/${SENTINEL}_session.gd"
printf 'extends RefCounted\n\nconst S := preload("res://core/application/%s_session.gd")\n\n\nfunc use() -> int:\n\treturn 1\n' "$SENTINEL" \
	>"core/domain/rules/${SENTINEL}_bad.gd"
assert_exists "core/domain/rules/${SENTINEL}_bad.gd" && expect_red "core/domain -> core/application" "must not reference the application layer"

echo "=== 4. empty directory ==="
# Only the sentinel directory, so it is unambiguously the cause.
mkdir -p "core/domain/${SENTINEL}_emptydir"
assert_exists "core/domain/${SENTINEL}_emptydir" && expect_red "empty directory" "empty directories are not permitted"

echo "=== 5. shared/ with only one consumer ==="
prepare core/domain
mkdir -p shared
printf 'extends RefCounted\n\n\nfunc helper() -> int:\n\treturn 1\n' >"shared/${SENTINEL}_helper.gd"
printf 'extends RefCounted\n\nconst H := preload("res://shared/%s_helper.gd")\n\n\nfunc use() -> int:\n\treturn 1\n' "$SENTINEL" \
	>"core/domain/${SENTINEL}_consumer.gd"
assert_exists "core/domain/${SENTINEL}_consumer.gd" && expect_red "shared/ single consumer" "two real consumers"

echo "=== 6. gitignored .uid ==="
printf '\n*.uid\n' >>.gitignore
expect_red "gitignored .uid" "gitignored"

echo "=== 7. orphan .uid with no source ==="
prepare tests/unit
printf 'uid://fake\n' >"tests/unit/${SENTINEL}_orphan.gd.uid"
assert_exists "tests/unit/${SENTINEL}_orphan.gd.uid" && expect_red "orphan .uid" "orphan, no source file"

echo
echo "=== the real tree must be green ==="
if ./scripts/check.sh >/tmp/vg.txt 2>&1; then
	printf '  \033[32mOK\033[0m   clean tree -> exit 0\n'
	pass_count=$((pass_count + 1))
else
	printf '  \033[31mBAD\033[0m  clean tree did not return to green\n'
	grep -E 'FAIL' /tmp/vg.txt | sed 's/^/         /'
	fail_count=$((fail_count + 1))
fi

echo
printf 'verified: %s passed, %s failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ]
