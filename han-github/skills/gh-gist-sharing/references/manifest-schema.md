# Gist Manifest Schema

The manifest lives at `tmp/.gist-manifest.yml` in the project root and is committed to the repo so teammates can discover Gist IDs.

```yaml
gists:
  # Creator entry
  - local_dir: tmp/handoffs          # path relative to repo root
    gist_id: abc1234567890abcdef     # creator's own Gist ID
    role: creator
    collaborators:                   # populated by add-collaborator mode
      alice: def4567890abcdef12      # remote name → collaborator's fork Gist ID

  # Fork entry (collaborator's own machine)
  - local_dir: tmp/investigations
    gist_id: def4567890abcdef12      # this machine's fork Gist ID
    role: fork
    upstream_id: abc1234567890abcdef # creator's Gist ID
```

Rules:
- `local_dir` is always relative to the repo root.
- `gist_id` is the ID of the Gist this machine owns (creator's Gist for `role: creator`; the fork for `role: fork`).
- `collaborators` is only present on `role: creator` entries. Each key is the git remote name; each value is the collaborator's fork Gist ID.
- `upstream_id` is only present on `role: fork` entries.
