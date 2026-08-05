#!/usr/bin/env bash
#
# Runs the Neon Kitchen content crew non-interactively, so a crew run is
# reproducible evidence rather than a story about a session someone once had.
#
#   ./tools/run_crew.sh "A late-shift medic who wants something fresh and light"
#   ./tools/run_crew.sh              # reads the brief from stdin
#
# For a live, interactive demo use the `/crew` slash command instead. This script
# is the same pipeline with the human removed from the loop.
#
# The session runs as the Kitchen Lead (`--agent kitchen-lead`), which then
# dispatches pantry-keeper, recipe-space-analyst and health-inspector via Task.
# Claude Code discovers `.claude/agents/*.md` at process start, so a session that
# began before those files existed cannot see them -- that is why this is a fresh
# process and not something the calling session does itself.
#
# PERMISSIONS: non-interactive runs cannot answer a permission prompt, so this
# passes --permission-mode bypassPermissions. Two things bound the risk, and both
# matter:
#
#   1. Each specialist is still confined by the `tools:` grant in its own
#      definition. The Pantry Keeper has no Bash and cannot acquire it here.
#   2. This script refuses to start on a dirty working tree, so anything the crew
#      writes is recoverable with `git checkout . && git clean -fd`.
#
# Do not remove the dirty-tree guard to make a run convenient. It is the only
# reason bypassing permissions is defensible.
#
# Portability: bash 3.2, which macOS still ships.

set -o pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
cd "$REPO_ROOT" || exit 1

readonly LOG_DIR="docs/worklogs/crew-runs"

die() { printf '\033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }
note() { printf '\033[1m==> %s\033[0m\n' "$1"; }

command -v claude >/dev/null 2>&1 || die "the 'claude' CLI is not on PATH"

# The guard that makes bypassing permissions recoverable. Read the header before
# adding an escape hatch to this.
if [ -n "$(git status --porcelain 2>/dev/null)" ]; then
	git status --short
	die "working tree is dirty; commit or stash first so a crew run is revertible"
fi

brief="$1"
if [ -z "$brief" ]; then
	if [ -t 0 ]; then
		die "no brief given: pass one as an argument or pipe it on stdin"
	fi
	brief="$(cat)"
fi
[ -n "$brief" ] || die "the brief is empty"

mkdir -p "$LOG_DIR"
# No timestamp: the git history already dates a run, and a stable filename means
# a re-run produces a reviewable diff instead of a new file each time.
readonly LOG_FILE="$LOG_DIR/latest.md"

note "Brief"
printf '%s\n\n' "$brief"

note "Dispatching the crew as kitchen-lead"

{
	printf '# Crew run\n\n'
	printf '## Brief\n\n> %s\n\n' "$brief"
	printf '## Kitchen Lead transcript\n\n```\n'
} >"$LOG_FILE"

printf 'Run the content crew on this brief.\n\n%s\n' "$brief" |
	claude -p \
		--agent kitchen-lead \
		--permission-mode bypassPermissions |
	tee -a "$LOG_FILE"
status=$?

printf '```\n' >>"$LOG_FILE"

if [ "$status" -ne 0 ]; then
	die "the crew run exited $status; see $LOG_FILE"
fi

note "Transcript written to $LOG_FILE"

# The crew's own claims are not evidence. Re-run the gate here so the run is
# scored by the project's criterion rather than by an agent's report of it.
note "Re-running the gate independently"
./scripts/check.sh || die "the gate is red after the crew run; do not accept this content"

note "Artifacts"
git status --short
