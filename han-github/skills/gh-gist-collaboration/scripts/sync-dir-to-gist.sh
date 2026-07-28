#!/bin/sh
[ -n "$HAN_GIST_SHELL" ] || exec env HAN_GIST_SHELL=1 "${SHELL:-bash}" "$0" "$@"
set -euo pipefail

# Usage: sync-dir-to-gist.sh <dir>
#
# Stages, commits, and pushes a Gist-backed working directory.
# The working directory IS the Gist clone, so there is no copy step.
#
# auto-push-gists.sh repeats this logic on purpose: it is copied out of the
# skill into the user's .claude/scripts/ and has to stand on its own there.

DIR="${1:?Usage: sync-dir-to-gist.sh <dir>}"

if [ ! -d "$DIR/.git" ]; then
  echo "Error: '$DIR' is not a Gist clone (no .git directory)" >&2
  exit 1
fi

git -C "$DIR" add -A -- ':!manifest.yml'

if git -C "$DIR" diff --cached --quiet; then
  echo "Nothing to sync — no changes since last push."
  exit 0
fi

git -C "$DIR" commit -m "sync: $(date -u '+%Y-%m-%d %H:%M UTC')"
git -C "$DIR" push origin master
echo "Pushed $DIR to its Gist."
