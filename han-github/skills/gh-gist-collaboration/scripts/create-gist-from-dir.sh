#!/bin/sh
[ -n "$HAN_GIST_SHELL" ] || exec env HAN_GIST_SHELL=1 "${SHELL:-bash}" "$0" "$@"
set -euo pipefail

# Usage: create-gist-from-dir.sh <dir> <description> [--public|--secret]
#
# Collects top-level files from <dir> and creates a GitHub Gist. Gists are
# secret by default; pass --public to create a public one instead.
# Prints the Gist ID on the first line and the URL on the second line.
#
# `gh gist create` is already secret by default and has no --secret flag, so
# secret means passing no visibility flag at all. --secret is accepted here to
# say so at the call site, and is deliberately not forwarded to gh.

DIR="${1:?Usage: create-gist-from-dir.sh <dir> <description> [--public|--secret]}"
DESCRIPTION="${2:?Missing description}"
VISIBILITY_FLAG="${3:---secret}"

if [ ! -d "$DIR" ]; then
  echo "Error: '$DIR' is not a directory" >&2
  exit 1
fi

FILES=()
while IFS= read -r f; do FILES+=("$f"); done < <(find "$DIR" -maxdepth 1 -mindepth 1 -type f)

if [ ${#FILES[@]} -eq 0 ]; then
  echo "Error: no files found in '$DIR'" >&2
  exit 1
fi

GH_ARGS=("--desc" "$DESCRIPTION")
case "$VISIBILITY_FLAG" in
  --secret) ;;
  --public) GH_ARGS+=("--public") ;;
  *)
    echo "Error: unknown flag '$VISIBILITY_FLAG' (expected --public or --secret)" >&2
    exit 1
    ;;
esac

for f in "${FILES[@]}"; do
  GH_ARGS+=("$f")
done

OUTPUT=$(gh gist create "${GH_ARGS[@]}")

# gh gist create prints the URL; extract the ID from the last path segment
GIST_URL="$OUTPUT"
GIST_ID="${GIST_URL##*/}"

echo "$GIST_ID"
echo "$GIST_URL"
