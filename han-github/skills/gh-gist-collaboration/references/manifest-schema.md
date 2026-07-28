# Manifest Schema

The skill uses two manifest files with different scopes and content.

---

## Local machine manifest — `tmp/features/<project-name>/manifest.yml`

Lives inside the Gist directory (which is also the working directory). Tracks this machine's registration for the Gist.
Never pushed to GitHub — excluded from `git add` by the sync scripts.
The skill builds an in-memory registry by scanning `tmp/features/*/manifest.yml` at startup.

```yaml
# Creator entry
local_dir: tmp/features/topaz-fit  # same as the directory containing this file
gist_id: abc1234567890abcdef       # this machine's Gist ID (the creator's)
role: creator

# Fork entry (collaborator's own machine)
local_dir: tmp/features/topaz-fit
gist_id: def4567890abcdef12        # this machine's fork Gist ID
role: fork
upstream_id: abc1234567890abcdef   # creator's Gist ID
```

Rules:
- One file per Gist directory. Never a combined file.
- `local_dir` is the path to this directory (relative to the repo root). The working directory and the Gist clone are the same directory.
- `gist_id` is the ID this machine owns — the creator's own for `role: creator`, the fork ID for `role: fork`.
- `upstream_id` is only present on `role: fork` entries.

---

## Shared Gist manifest — `tmp/features/<project-name>/.han-gist-sharing-manifest.yml`

Lives in the Gist directory and syncs to the Gist as a Gist file.
Visible to all collaborators. Lets new collaborators discover the creator's Gist ID
and see who else is involved.

The filename keeps the older `han-gist-sharing` spelling on purpose. It is a runtime
file that already exists inside every Gist created so far, and renaming it would
strand those Gists on a name the skill no longer looks for.

```yaml
gist_id: abc1234567890abcdef     # creator's Gist ID
collaborators:
  alice: def4567890abcdef12      # remote name → collaborator's fork Gist ID
```

Rules:
- `gist_id` is always the creator's Gist ID, regardless of which machine reads the file.
- `collaborators` is populated by `--add-collaborator` and may be empty on creation.
