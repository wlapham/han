#!/usr/bin/env bash
set -euo pipefail

# Usage: sync-gist-to-dir.sh <clone-dir> <target-dir> [<remote>]
#
# Pulls the latest from the Gist clone (optionally from <remote> master),
# then copies top-level files to <target-dir>.
# <remote> defaults to "origin"; use "upstream" on a fork to pull the creator's changes.

CLONE="${1:?Usage: sync-gist-to-dir.sh <clone-dir> <target-dir> [remote]}"
TARGET="${2:?Missing target-dir}"
REMOTE="${3:-origin}"

if [ ! -d "$CLONE/.git" ]; then
  echo "Error: '$CLONE' is not a git repository" >&2
  exit 1
fi

mkdir -p "$TARGET"

git -C "$CLONE" pull "$REMOTE" master

# Copy only top-level files back to the target directory
find "$CLONE" -maxdepth 1 -mindepth 1 -type f ! -name ".git" -exec cp {} "$TARGET/" \;

echo "Synced files from Gist clone to '$TARGET'."
