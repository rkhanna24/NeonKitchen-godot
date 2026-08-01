#!/usr/bin/env bash
#
# One-time (and idempotent) developer setup. Installs pinned dependencies that
# are deliberately NOT committed to the repository.
#
#   ./scripts/setup.sh
#
# Godot has no package manager, so this script is ours. It handles two
# dependencies the same way: pin an exact version, fetch it, verify it.
#
#   gdtoolkit  -> requirements-dev.txt, installed into .venv
#   GUT        -> pinned below, fetched into addons/gut
#
# Both directories are gitignored. Run ./scripts/check.sh afterwards; the gate
# fails loudly if either dependency is missing, so a fresh clone cannot silently
# pass with no linter and no tests.

set -o pipefail

# GUT pin. Authoritative record: docs/adr/0003-test-framework.md.
# Changing either value requires updating that ADR.
readonly GUT_VERSION="9.7.1"
readonly GUT_COMMIT="aeb5d4f3f7f0a6c9b5e178876d6c99b791fda605"
readonly GUT_REPO="https://github.com/bitwes/Gut.git"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
cd "$REPO_ROOT" || exit 1

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
info() { printf '    %s\n' "$1"; }
die() { printf '    \033[31mERROR\033[0m %s\n' "$1" >&2; exit 1; }

# --------------------------------------------------------------- gdtoolkit ----
step "Python environment (gdformat, gdlint)"
if [ ! -x ".venv/bin/python" ]; then
	python3 -m venv .venv || die "could not create .venv"
	info "created .venv"
fi
.venv/bin/pip install --quiet --upgrade pip || die "pip upgrade failed"
.venv/bin/pip install --quiet -r requirements-dev.txt || die "gdtoolkit install failed"
info "$(.venv/bin/gdlint --version 2>&1 | head -1)"

# --------------------------------------------------------------------- GUT ----
step "Test framework (GUT $GUT_VERSION)"

installed_commit=""
[ -f "addons/.gut-commit" ] && installed_commit="$(cat addons/.gut-commit)"

if [ "$installed_commit" = "$GUT_COMMIT" ] && [ -f "addons/gut/gut_cmdln.gd" ]; then
	info "already at $GUT_VERSION ($GUT_COMMIT)"
else
	command -v git >/dev/null 2>&1 || die "git is required to fetch GUT"

	tmp="$(mktemp -d)"
	# shellcheck disable=SC2064
	trap "rm -rf '$tmp'" EXIT

	info "cloning $GUT_REPO at v$GUT_VERSION"
	git -c advice.detachedHead=false clone --quiet --depth 1 \
		--branch "v$GUT_VERSION" "$GUT_REPO" "$tmp/gut" \
		|| die "clone failed (network required for first setup)"

	# Git is content-addressed, so verifying the commit SHA is a cryptographic
	# integrity check. GitHub's generated tarballs are not guaranteed to be
	# byte-stable, so their checksums are not used here.
	actual_commit="$(git -C "$tmp/gut" rev-parse HEAD)"
	if [ "$actual_commit" != "$GUT_COMMIT" ]; then
		die "commit mismatch: expected $GUT_COMMIT, got $actual_commit"
	fi
	info "verified commit $actual_commit"

	# GUT's repository root is itself a full Godot project. Only the addon
	# subdirectory may be copied in; a nested project.godot would break ours.
	[ -d "$tmp/gut/addons/gut" ] || die "addons/gut not found in the clone"

	rm -rf addons/gut
	mkdir -p addons
	cp -R "$tmp/gut/addons/gut" addons/
	printf '%s' "$GUT_COMMIT" >addons/.gut-commit

	reported="$(sed -n 's/^version="\(.*\)"$/\1/p' addons/gut/plugin.cfg | head -1)"
	[ "$reported" = "$GUT_VERSION" ] \
		|| die "plugin.cfg reports $reported, expected $GUT_VERSION"
	info "installed GUT $reported into addons/gut"
fi

printf '\n\033[32mSetup complete.\033[0m Run ./scripts/check.sh\n'
