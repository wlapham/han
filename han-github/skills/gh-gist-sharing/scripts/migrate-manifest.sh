#!/usr/bin/env bash
set -euo pipefail

# One-time migration from the old tmp/.gist-manifest.yml + tmp/.gist-clones/ layout
# to the new tmp/.han-gist-sharing/<gist-id>/ layout with split manifest files.
# Run once per workspace, then revert this script from the repo.

OLD_MANIFEST="tmp/.gist-manifest.yml"
OLD_CLONES="tmp/.gist-clones"
NEW_CLONES="tmp/.han-gist-sharing"

if [ ! -f "$OLD_MANIFEST" ]; then
  echo "No manifest found at $OLD_MANIFEST — nothing to migrate."
  exit 0
fi

mkdir -p "$NEW_CLONES"

python3 - "$OLD_MANIFEST" "$OLD_CLONES" "$NEW_CLONES" <<'PYTHON'
import sys, os, shutil, subprocess

old_manifest_path, old_clones, new_clones = sys.argv[1], sys.argv[2], sys.argv[3]

entries, cur, collaborators, in_collabs = [], {}, {}, False

with open(old_manifest_path) as f:
    for line in f:
        s = line.rstrip()
        if not s or s.strip().startswith('#'):
            continue
        indent = len(s) - len(s.lstrip())
        content = s.strip()

        if indent == 2 and content.startswith('- '):
            if cur:
                entries.append((dict(cur), dict(collaborators)))
            cur, collaborators, in_collabs = {}, {}, False
            rest = content[2:]
            if ': ' in rest:
                k, v = rest.split(': ', 1)
                cur[k.strip()] = v.strip()
        elif indent == 4:
            if content == 'collaborators:':
                in_collabs = True
            elif ': ' in content and not in_collabs:
                k, v = content.split(': ', 1)
                cur[k.strip()] = v.strip()
        elif indent == 6 and in_collabs and ': ' in content:
            k, v = content.split(': ', 1)
            collaborators[k.strip()] = v.strip()

if cur:
    entries.append((dict(cur), dict(collaborators)))

for entry, collabs in entries:
    gist_id = entry.get('gist_id', '')
    old_clone = os.path.join(old_clones, gist_id)
    new_clone = os.path.join(new_clones, gist_id)

    # Move the clone directory to the new location
    if os.path.isdir(old_clone):
        if os.path.exists(new_clone):
            print(f"  skip move: {new_clone} already exists")
        else:
            shutil.move(old_clone, new_clone)
            print(f"  moved {old_clone} → {new_clone}")
    elif not os.path.isdir(new_clone):
        print(f"  skip {gist_id}: clone not found at {old_clone} — re-clone manually")
        continue

    # Remove old .gist-manifest.yml from the gist if present
    old_gist_manifest = os.path.join(new_clone, '.gist-manifest.yml')
    if os.path.exists(old_gist_manifest):
        subprocess.run(['git', '-C', new_clone, 'rm', '-f', '.gist-manifest.yml'], check=True)
        subprocess.run(['git', '-C', new_clone, 'commit', '-m', 'chore: remove old .gist-manifest.yml'], check=True)
        subprocess.run(['git', '-C', new_clone, 'push', 'origin', 'master'], check=True)
        print(f"  removed .gist-manifest.yml from gist {gist_id}")

    # Write the new local manifest
    manifest_path = os.path.join(new_clone, 'manifest.yml')
    lines = [
        f"local_dir: {entry.get('local_dir', '')}",
        f"gist_id: {gist_id}",
        f"role: {entry.get('role', '')}",
    ]
    if entry.get('upstream_id'):
        lines.append(f"upstream_id: {entry['upstream_id']}")
    with open(manifest_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    print(f"  wrote {manifest_path}")

    # Write the shared Gist manifest to the working directory (creator only)
    local_dir = entry.get('local_dir', '')
    if local_dir and os.path.isdir(local_dir) and entry.get('role') == 'creator':
        shared_path = os.path.join(local_dir, '.han-gist-sharing-manifest.yml')
        shared_lines = [f"gist_id: {gist_id}", "collaborators:"]
        for name, fork_id in collabs.items():
            shared_lines.append(f"  {name}: {fork_id}")
        with open(shared_path, 'w') as f:
            f.write('\n'.join(shared_lines) + '\n')
        print(f"  wrote {shared_path} (push the Gist to sync this to collaborators)")

PYTHON

# Clean up old clone root if now empty
if [ -d "$OLD_CLONES" ] && [ -z "$(ls -A "$OLD_CLONES")" ]; then
  rmdir "$OLD_CLONES"
  echo "  removed empty $OLD_CLONES"
fi

echo "Removing $OLD_MANIFEST"
rm "$OLD_MANIFEST"
echo "Migration complete."
