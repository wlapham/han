# Manifest Schema

The skill uses two manifest files with different scopes and content.

---

## Local machine manifest — `tmp/.han-gist-sharing/<gist-id>/manifest.yml`

Lives inside the Gist clone directory. Tracks this machine's registration for the Gist.
Never pushed to GitHub — excluded from `git add` by the sync script.
The skill builds an in-memory registry by scanning `tmp/.han-gist-sharing/*/manifest.yml` at startup.

```yaml
# Creator entry
local_dir: tmp/handoffs          # path relative to repo root
gist_id: abc1234567890abcdef     # this machine's Gist ID (the creator's)
role: creator

# Fork entry (collaborator's own machine)
local_dir: tmp/investigations
gist_id: def4567890abcdef12      # this machine's fork Gist ID
role: fork
upstream_id: abc1234567890abcdef # creator's Gist ID
```

Rules:
- One file per Gist clone. Never a combined file.
- `local_dir` is relative to the repo root.
- `gist_id` is the ID this machine owns — the creator's own for `role: creator`, the fork ID for `role: fork`.
- `upstream_id` is only present on `role: fork` entries.

---

## Shared Gist manifest — `<local-dir>/.han-gist-sharing-manifest.yml`

Lives in the local working directory and syncs to the Gist as a Gist file.
Visible to all collaborators. Lets new collaborators discover the creator's Gist ID
and see who else is involved.

```yaml
gist_id: abc1234567890abcdef     # creator's Gist ID
collaborators:
  alice: def4567890abcdef12      # remote name → collaborator's fork Gist ID
```

Rules:
- `gist_id` is always the creator's Gist ID, regardless of which machine reads the file.
- `collaborators` is populated by `--add-collaborator` and may be empty on creation.
