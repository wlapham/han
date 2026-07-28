#!/bin/sh
[ -n "$HAN_GIST_SHELL" ] || exec env HAN_GIST_SHELL=1 "${SHELL:-bash}" "$0" "$@"
set -euo pipefail

# Auto-push all creator-owned Gist directories at session end.
# Scans tmp/features/*/manifest.yml for creator entries and pushes each one.
# The working directory IS the Gist clone — no separate copy step needed.

FEATURES_DIR="tmp/features"
[ -d "$FEATURES_DIR" ] || exit 0

while IFS= read -r manifest; do
    local_dir=$(ruby -r yaml -e '
      m = YAML.load_file(ARGV[0])
      print m["local_dir"] if m["role"] == "creator"
    ' "$manifest")
    [ -z "$local_dir" ] && continue
    [ -d "$local_dir/.git" ] || continue
    git -C "$local_dir" add -A -- ':!manifest.yml'
    if ! git -C "$local_dir" diff --cached --quiet; then
        git -C "$local_dir" commit -m "sync: $(date -u '+%Y-%m-%d %H:%M UTC')"
        git -C "$local_dir" push origin master
        echo "[gh-gist-collaboration] Pushed $local_dir"
    fi
done < <(find "$FEATURES_DIR" -maxdepth 2 -name "manifest.yml" 2>/dev/null)
