#!/usr/bin/env bash
set -euo pipefail

# Usage: create-gist-from-dir.sh <dir> <description> [--secret]
#
# Collects top-level files from <dir> and creates a GitHub Gist.
# Prints the Gist ID on the first line and the URL on the second line.

DIR="${1:?Usage: create-gist-from-dir.sh <dir> <description> [--secret]}"
DESCRIPTION="${2:?Missing description}"
SECRET_FLAG="${3:-}"

if [ ! -d "$DIR" ]; then
  echo "Error: '$DIR' is not a directory" >&2
  exit 1
fi

mapfile -t FILES < <(find "$DIR" -maxdepth 1 -mindepth 1 -type f)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "Error: no files found in '$DIR'" >&2
  exit 1
fi

GH_ARGS=("--desc" "$DESCRIPTION")
if [ "$SECRET_FLAG" = "--secret" ]; then
  GH_ARGS+=("--secret")
else
  GH_ARGS+=("--public")
fi

for f in "${FILES[@]}"; do
  GH_ARGS+=("$f")
done

OUTPUT=$(gh gist create "${GH_ARGS[@]}")

# gh gist create prints the URL; extract the ID from the last path segment
GIST_URL="$OUTPUT"
GIST_ID="${GIST_URL##*/}"

echo "$GIST_ID"
echo "$GIST_URL"
