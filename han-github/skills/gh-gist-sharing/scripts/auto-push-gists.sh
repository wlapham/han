#!/usr/bin/env bash
set -euo pipefail

# Auto-push all creator-owned Gist directories at session end.
# Scans tmp/.han-gist-sharing/*/manifest.yml for creator entries and syncs each one.

CLONES_DIR="tmp/.han-gist-sharing"
[ -d "$CLONES_DIR" ] || exit 0

while IFS= read -r manifest; do
    result=$(python3 - "$manifest" <<'PYTHON'
import sys

entry = {}
with open(sys.argv[1]) as f:
    for line in f:
        s = line.rstrip()
        if not s or s.startswith('#') or s.startswith(' '):
            continue
        if ': ' in s:
            k, v = s.split(': ', 1)
            entry[k.strip()] = v.strip()

if entry.get('role') == 'creator':
    print(entry.get('gist_id', ''), entry.get('local_dir', ''))
PYTHON
)
    [ -z "$result" ] && continue
    read -r gist_id local_dir <<< "$result"
    clone="$CLONES_DIR/$gist_id"
    [ -d "$clone/.git" ] || continue
    find "$local_dir" -maxdepth 1 -mindepth 1 -type f -exec cp {} "$clone/" \;
    git -C "$clone" add -A -- ':!manifest.yml'
    if ! git -C "$clone" diff --cached --quiet; then
        git -C "$clone" commit -m "sync: $(date -u '+%Y-%m-%d %H:%M UTC')"
        git -C "$clone" push origin master
        echo "[gh-gist-sharing] Pushed $local_dir to Gist $gist_id"
    fi
done < <(find "$CLONES_DIR" -maxdepth 2 -name "manifest.yml" 2>/dev/null)
