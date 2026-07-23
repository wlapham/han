#!/usr/bin/env bash
set -euo pipefail

# Auto-push all creator-owned Gist directories at session end.
# Reads tmp/.gist-manifest.yml, finds role:creator entries, and syncs each one.

MANIFEST="tmp/.gist-manifest.yml"
[ -f "$MANIFEST" ] || exit 0

# Parse creator entries: emit "<gist_id> <local_dir>" per creator entry.
# Relies on the manifest's consistent indentation: list items at 2 spaces,
# their fields at 4 spaces, collaborator sub-entries at 6+ spaces (skipped).
creators=$(python3 - "$MANIFEST" <<'PYTHON'
import sys

entries, cur = [], {}
with open(sys.argv[1]) as f:
    for line in f:
        s = line.rstrip()
        if not s or s.strip().startswith('#'):
            continue
        indent = len(s) - len(s.lstrip())
        content = s.strip()
        if indent == 2 and content.startswith('- '):
            if cur:
                entries.append(cur)
            cur = {}
            rest = content[2:]
            if ': ' in rest:
                k, v = rest.split(': ', 1)
                cur[k.strip()] = v.strip()
        elif indent == 4 and ': ' in content:
            k, v = content.split(': ', 1)
            cur[k.strip()] = v.strip()
        # indent >= 6: collaborator sub-entries — skip
if cur:
    entries.append(cur)

for e in entries:
    if e.get('role') == 'creator':
        print(e['gist_id'], e['local_dir'])
PYTHON
)

[ -z "$creators" ] && exit 0

while IFS=' ' read -r gist_id local_dir; do
    clone="tmp/.gist-clones/$gist_id"
    [ -d "$clone/.git" ] || continue
    find "$local_dir" -maxdepth 1 -mindepth 1 -type f -exec cp {} "$clone/" \;
    git -C "$clone" add -A
    if ! git -C "$clone" diff --cached --quiet; then
        git -C "$clone" commit -m "sync: $(date -u '+%Y-%m-%d %H:%M UTC')"
        git -C "$clone" push origin master
        echo "[gh-gist-sharing] Pushed $local_dir to Gist $gist_id"
    fi
done <<< "$creators"
