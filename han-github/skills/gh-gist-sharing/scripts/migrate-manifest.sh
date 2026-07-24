#!/usr/bin/env bash
set -euo pipefail

# One-time migration to the new tmp/.han-gist-sharing/ layout with split manifests.
# Steps are independent and idempotent — safe to run multiple times or in any state.
# Revert this script from the repo once all workspaces have been migrated.

OLD_MANIFEST="tmp/.gist-manifest.yml"
OLD_CLONES="tmp/.gist-clones"
NEW_CLONES="tmp/.han-gist-sharing"

step() { echo; echo "── $*"; }

# ---------------------------------------------------------------------------
# Collect all known gist IDs from every possible source
# ---------------------------------------------------------------------------
step "Discovering gist IDs"

gist_ids=()

# From the old project-level manifest (list format)
if [ -f "$OLD_MANIFEST" ]; then
  mapfile -t old_ids < <(ruby -r yaml -e '
    manifest = YAML.load_file(ARGV[0])
    (manifest["gists"] || []).each { |e| puts e["gist_id"] if e["gist_id"] }
  ' "$OLD_MANIFEST")
  gist_ids+=("${old_ids[@]}")
  echo "  found ${#old_ids[@]} gist(s) in $OLD_MANIFEST"
fi

# From old clone directories
if [ -d "$OLD_CLONES" ]; then
  while IFS= read -r d; do
    id=$(basename "$d")
    gist_ids+=("$id")
    echo "  found gist $id in $OLD_CLONES"
  done < <(find "$OLD_CLONES" -maxdepth 1 -mindepth 1 -type d)
fi

# From new clone directories (already partially migrated)
if [ -d "$NEW_CLONES" ]; then
  while IFS= read -r d; do
    id=$(basename "$d")
    gist_ids+=("$id")
    echo "  found gist $id in $NEW_CLONES"
  done < <(find "$NEW_CLONES" -maxdepth 1 -mindepth 1 -type d)
fi

# Deduplicate
mapfile -t gist_ids < <(printf '%s\n' "${gist_ids[@]}" | sort -u)

if [ ${#gist_ids[@]} -eq 0 ]; then
  echo "  no gists found — nothing to migrate."
  exit 0
fi

echo "  migrating ${#gist_ids[@]} gist(s): ${gist_ids[*]}"

mkdir -p "$NEW_CLONES"

# ---------------------------------------------------------------------------
# Step 1: Move clone directories from old location to new
# ---------------------------------------------------------------------------
step "Step 1: Move clone directories $OLD_CLONES → $NEW_CLONES"

for id in "${gist_ids[@]}"; do
  old="$OLD_CLONES/$id"
  new="$NEW_CLONES/$id"
  if [ -d "$old" ] && [ ! -d "$new" ]; then
    mv "$old" "$new"
    echo "  moved $old → $new"
  elif [ -d "$old" ] && [ -d "$new" ]; then
    echo "  skip $id: both $old and $new exist — resolve manually"
  elif [ -d "$new" ]; then
    echo "  ok $id: already in $new"
  else
    echo "  skip $id: no clone found in either location"
  fi
done

# ---------------------------------------------------------------------------
# Step 2: Remove old .gist-manifest.yml from each gist clone
# ---------------------------------------------------------------------------
step "Step 2: Remove old .gist-manifest.yml from gist clones"

for id in "${gist_ids[@]}"; do
  clone="$NEW_CLONES/$id"
  old_file="$clone/.gist-manifest.yml"
  [ -d "$clone/.git" ] || { echo "  skip $id: not a git repo"; continue; }
  if [ -f "$old_file" ]; then
    git -C "$clone" rm -f .gist-manifest.yml
    git -C "$clone" commit -m "chore: remove old .gist-manifest.yml"
    git -C "$clone" push origin master
    echo "  removed .gist-manifest.yml from gist $id"
  else
    echo "  ok $id: no old manifest in gist"
  fi
done

# ---------------------------------------------------------------------------
# Step 3: Ensure manifest.yml exists in each clone
# ---------------------------------------------------------------------------
step "Step 3: Ensure manifest.yml exists in each clone"

for id in "${gist_ids[@]}"; do
  clone="$NEW_CLONES/$id"
  manifest="$clone/manifest.yml"
  [ -d "$clone" ] || { echo "  skip $id: clone missing"; continue; }

  if [ -f "$manifest" ]; then
    echo "  ok $id: manifest.yml already exists"
    continue
  fi

  # Source registration data from old project manifest if available
  entry=$(ruby -r yaml -e '
    manifest_path, target_id = ARGV
    manifest = File.exist?(manifest_path) ? YAML.load_file(manifest_path) : {}
    entry = (manifest["gists"] || []).find { |e| e["gist_id"] == target_id }
    if entry
      puts entry.slice("local_dir","gist_id","role","upstream_id").compact
                .map { |k,v| "#{k}: #{v}" }.join("\n")
    end
  ' "$OLD_MANIFEST" "$id" 2>/dev/null || true)

  if [ -z "$entry" ]; then
    echo "  skip $id: no registration data found — write manifest.yml manually"
    continue
  fi

  echo "$entry" > "$manifest"
  echo "  wrote $manifest"
done

# ---------------------------------------------------------------------------
# Step 4: Ensure .han-gist-sharing-manifest.yml exists in each creator's working dir
# ---------------------------------------------------------------------------
step "Step 4: Ensure .han-gist-sharing-manifest.yml exists in working directories"

for id in "${gist_ids[@]}"; do
  manifest="$NEW_CLONES/$id/manifest.yml"
  [ -f "$manifest" ] || { echo "  skip $id: no manifest.yml"; continue; }

  role=$(ruby -r yaml -e 'm=YAML.load_file(ARGV[0]); puts m["role"]' "$manifest")
  [ "$role" = "creator" ] || { echo "  skip $id: not a creator entry"; continue; }

  local_dir=$(ruby -r yaml -e 'm=YAML.load_file(ARGV[0]); puts m["local_dir"]' "$manifest")
  shared="$local_dir/.han-gist-sharing-manifest.yml"

  if [ -f "$shared" ]; then
    echo "  ok $id: $shared already exists"
    continue
  fi

  [ -d "$local_dir" ] || { echo "  skip $id: local_dir $local_dir not found"; continue; }

  # Pull collaborators from old manifest if available
  ruby -r yaml -e '
    old_path, gist_id, out_path = ARGV
    collabs = {}
    if File.exist?(old_path)
      manifest = YAML.load_file(old_path)
      entry = (manifest["gists"] || []).find { |e| e["gist_id"] == gist_id }
      collabs = entry["collaborators"] || {} if entry
    end
    File.write(out_path, YAML.dump({"gist_id" => gist_id, "collaborators" => collabs}))
  ' "$OLD_MANIFEST" "$id" "$shared" 2>/dev/null || \
  ruby -r yaml -e '
    gist_id, out_path = ARGV
    File.write(out_path, YAML.dump({"gist_id" => gist_id, "collaborators" => {}}))
  ' "$id" "$shared"
  echo "  wrote $shared"
done

# ---------------------------------------------------------------------------
# Step 5: Ensure .han-gist-sharing-manifest.yml is present in each gist
# ---------------------------------------------------------------------------
step "Step 5: Ensure .han-gist-sharing-manifest.yml is in each creator gist"

for id in "${gist_ids[@]}"; do
  clone="$NEW_CLONES/$id"
  [ -d "$clone/.git" ] || { echo "  skip $id: not a git repo"; continue; }

  manifest="$clone/manifest.yml"
  [ -f "$manifest" ] || { echo "  skip $id: no manifest.yml"; continue; }

  role=$(ruby -r yaml -e 'm=YAML.load_file(ARGV[0]); puts m["role"]' "$manifest")
  [ "$role" = "creator" ] || { echo "  skip $id: not a creator entry"; continue; }

  if [ -f "$clone/.han-gist-sharing-manifest.yml" ]; then
    echo "  ok $id: .han-gist-sharing-manifest.yml already in gist"
    continue
  fi

  local_dir=$(ruby -r yaml -e 'm=YAML.load_file(ARGV[0]); puts m["local_dir"]' "$manifest")
  shared="$local_dir/.han-gist-sharing-manifest.yml"

  if [ ! -f "$shared" ]; then
    echo "  skip $id: $shared not found — run step 4 first"
    continue
  fi

  cp "$shared" "$clone/.han-gist-sharing-manifest.yml"
  git -C "$clone" add .han-gist-sharing-manifest.yml
  git -C "$clone" commit -m "chore: add .han-gist-sharing-manifest.yml"
  git -C "$clone" push origin master
  echo "  pushed .han-gist-sharing-manifest.yml to gist $id"
done

# ---------------------------------------------------------------------------
# Step 6: Remove old project manifest if all entries are accounted for
# ---------------------------------------------------------------------------
step "Step 6: Remove $OLD_MANIFEST"

if [ -f "$OLD_MANIFEST" ]; then
  unaccounted=0
  for id in "${gist_ids[@]}"; do
    [ -f "$NEW_CLONES/$id/manifest.yml" ] || { unaccounted=1; break; }
  done
  if [ "$unaccounted" -eq 0 ]; then
    rm "$OLD_MANIFEST"
    echo "  removed $OLD_MANIFEST"
  else
    echo "  skip: some gists still missing manifest.yml — leaving $OLD_MANIFEST in place"
  fi
else
  echo "  ok: $OLD_MANIFEST already gone"
fi

# ---------------------------------------------------------------------------
# Step 7: Remove empty old clone directory
# ---------------------------------------------------------------------------
step "Step 7: Remove empty $OLD_CLONES"

if [ -d "$OLD_CLONES" ] && [ -z "$(ls -A "$OLD_CLONES")" ]; then
  rmdir "$OLD_CLONES"
  echo "  removed $OLD_CLONES"
elif [ -d "$OLD_CLONES" ]; then
  echo "  skip: $OLD_CLONES not empty — check for unmigrated clones"
else
  echo "  ok: $OLD_CLONES already gone"
fi

echo
echo "Migration complete."
