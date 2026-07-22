#!/usr/bin/env bash
set -euo pipefail

# Usage: sync-dir-to-gist.sh <src-dir> <clone-dir>
#
# Copies top-level files from <src-dir> into the Gist clone, commits, and pushes.

SRC="${1:?Usage: sync-dir-to-gist.sh <src-dir> <clone-dir>}"
CLONE="${2:?Missing clone-dir}"

if [ ! -d "$SRC" ]; then
  echo "Error: source directory '$SRC' not found" >&2
  exit 1
fi

if [ ! -d "$CLONE/.git" ]; then
  echo "Error: '$CLONE' is not a git repository" >&2
  exit 1
fi

# Copy only top-level files (Gists are flat)
find "$SRC" -maxdepth 1 -mindepth 1 -type f -exec cp {} "$CLONE/" \;

git -C "$CLONE" add -A

if git -C "$CLONE" diff --cached --quiet; then
  echo "Nothing to sync — no changes since last push."
  exit 0
fi

TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')
git -C "$CLONE" commit -m "sync: $TIMESTAMP"
git -C "$CLONE" push origin master
echo "Pushed to Gist."
