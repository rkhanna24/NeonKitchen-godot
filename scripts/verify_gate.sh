#!/usr/bin/env bash
# Verify every new gate check in the FAILING direction. A check that cannot go
# red is not a check. Each case introduces one violation, asserts the gate names
# it and exits nonzero, then cleans up and asserts green again.
cd /Users/rokhanna/godot/neon-kitchen || exit 1

pass_count=0
fail_count=0

expect_red() { # <label> <string the gate must print>
	./scripts/check.sh >/tmp/vc.txt 2>&1
	code=$?
	if [ "$code" -ne 0 ] && grep -q "$2" /tmp/vc.txt; then
		printf '  \033[32mOK\033[0m   %s -> exit %s, reported\n' "$1" "$code"
		pass_count=$((pass_count + 1))
	else
		printf '  \033[31mBAD\033[0m  %s -> exit %s, expected message %s\n' "$1" "$code" "$2"
		grep -E 'FAIL|==>' /tmp/vc.txt | tail -6 | sed 's/^/         /'
		fail_count=$((fail_count + 1))
	fi
}

cleanup() {
	rm -rf core shared
	rm -f tests/unit/_orphan.gd.uid
	git checkout -- .gitignore 2>/dev/null
}
trap cleanup EXIT

valid_gd() { printf 'extends RefCounted\n\n\nfunc %s() -> int:\n\treturn 1\n' "$1"; }

echo "=== 1. domain references an adapter by path ==="
mkdir -p core/domain/rules adapters/content
valid_gd noop > adapters/content/repo.gd
printf 'extends RefCounted\n\nconst Repo := preload("res://adapters/content/repo.gd")\n\n\nfunc use() -> int:\n\treturn 1\n' > core/domain/rules/bad.gd
expect_red "path reference core -> adapters" "must not reference adapters"
rm -rf core adapters

echo "=== 2. domain references an adapter by class_name ==="
mkdir -p core/domain/rules adapters/content
printf 'class_name ContentRepoAdapter\nextends RefCounted\n\n\nfunc noop() -> int:\n\treturn 1\n' > adapters/content/repo.gd
printf 'extends RefCounted\n\n\nfunc use() -> int:\n\tvar r: ContentRepoAdapter = null\n\treturn 1 if r == null else 0\n' > core/domain/rules/bad.gd
expect_red "class_name reference core -> adapters" "declared in adapters/"
rm -rf core adapters

echo "=== 3. domain references the application layer ==="
mkdir -p core/domain/rules core/application
valid_gd noop > core/application/session.gd
printf 'extends RefCounted\n\nconst S := preload("res://core/application/session.gd")\n\n\nfunc use() -> int:\n\treturn 1\n' > core/domain/rules/bad.gd
expect_red "core/domain -> core/application" "must not reference the application layer"
rm -rf core

echo "=== 4. empty directory ==="
mkdir -p core/domain/state
expect_red "empty directory" "empty directories are not permitted"
rm -rf core

echo "=== 5. shared/ with only one consumer ==="
mkdir -p shared core/domain
valid_gd helper > shared/helper.gd
printf 'extends RefCounted\n\nconst H := preload("res://shared/helper.gd")\n\n\nfunc use() -> int:\n\treturn 1\n' > core/domain/only_consumer.gd
expect_red "shared/ single consumer" "two real consumers"
rm -rf shared core

echo "=== 6. gitignored .uid ==="
printf '\n*.uid\n' >> .gitignore
expect_red "gitignored .uid" "gitignored"
git checkout -- .gitignore

echo "=== 7. orphan .uid with no source ==="
printf 'uid://fake\n' > tests/unit/_orphan.gd.uid
expect_red "orphan .uid" "orphan, no source file"
rm -f tests/unit/_orphan.gd.uid

echo
echo "=== restored tree must be green again ==="
./scripts/check.sh >/tmp/vc.txt 2>&1
if [ $? -eq 0 ]; then
	printf '  \033[32mOK\033[0m   clean tree -> exit 0\n'; pass_count=$((pass_count + 1))
else
	printf '  \033[31mBAD\033[0m  clean tree did not return to green\n'
	grep -E 'FAIL' /tmp/vc.txt | sed 's/^/         /'; fail_count=$((fail_count + 1))
fi

echo
printf 'verified: %s passed, %s failed\n' "$pass_count" "$fail_count"
[ "$fail_count" -eq 0 ]
