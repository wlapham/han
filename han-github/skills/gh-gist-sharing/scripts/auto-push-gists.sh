#!/usr/bin/env bash
set -euo pipefail

# Auto-push all creator-owned Gist directories at session end.
# Scans tmp/.han-gist-sharing/*/manifest.yml for creator entries and syncs each one.

CLONES_DIR="tmp/.han-gist-sharing"
[ -d "$CLONES_DIR" ] || exit 0

while IFS= read -r manifest; do
    result=$(ruby -r yaml -e '
      m = YAML.load_file(ARGV[0])
      puts "#{m["gist_id"]} #{m["local_dir"]}" if m["role"] == "creator"
    ' "$manifest")
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
