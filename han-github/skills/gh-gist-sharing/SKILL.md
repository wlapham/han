---
name: gh-gist-sharing
description: >
  Share a local tmp/ subdirectory with teammates via a GitHub Gist, and keep
  both sides in sync using git-on-Gist. Requires the gh CLI. Use when a team
  needs bidirectional access to working documents (handoffs, investigations,
  feature drafts) without a shared repo. Does not handle nested subdirectories
  inside the shared directory — Gists are flat by design. Does not post to
  Slack or any channel; the Gist URL is shared manually. For posting code
  reviews to GitHub, use post-code-review-to-pr instead.
argument-hint: "[<local-dir-path> | <gist-url-or-id> | --add-collaborator <name> <fork-id> | --merge [<name>]]"
allowed-tools: Bash(gh *), Bash(git *), Bash(find *), Bash(rsync *), Bash(cp *), Read, Write, Edit
---

## Pre-requisites

- gh CLI: !`which gh 2>/dev/null || echo "not installed"`

If `gh` is not found, inform the user it must be installed and configured, then stop.

## Mode Detection (Step 1)

Route based on the argument:

- Argument starts with `--add-collaborator` → **Add-collaborator mode**
- Argument starts with `--merge` → **Merge mode**
- Argument looks like a local path (starts with `tmp/` or `.`) → **Push mode**
- Argument looks like a Gist URL or 32-char hex ID, AND appears in the registry as `role: fork` → **Pull mode**
- Argument looks like a Gist URL or 32-char hex ID, AND is NOT in the registry (or no clones registered yet) → **Join mode**
- No argument → Display the registry (or "no Gists shared yet" if empty), show usage summary, and stop.

Build the in-memory registry now: `find tmp/.han-gist-sharing -maxdepth 2 -name manifest.yml 2>/dev/null`. Read each found file to collect `{gist_id, local_dir, role, upstream_id}` per entry. The manifest schema is documented in `${CLAUDE_SKILL_DIR}/references/manifest-schema.md`.

---

## Push Mode

The creator syncs local changes to their Gist.

### Step 2: Validate the directory

1. Confirm the path exists under `tmp/`.
2. Run `find <dir> -maxdepth 1 -mindepth 1 -type d` to check for subdirectories. If any exist, list them and stop — Gists are flat and cannot represent directory structure.
3. List the files that will be shared: `find <dir> -maxdepth 1 -mindepth 1 -type f`.

### Step 3: Look up or create the Gist

Check the registry for an existing entry where `local_dir` matches.

**If no existing entry (new Gist):** Human gate before creating.
1. Show the user: the directory path, the file list, and ask whether the Gist should be public or secret.
2. Run `${CLAUDE_SKILL_DIR}/scripts/create-gist-from-dir.sh <dir> "[<repo-name>] <rel-path>" [--secret]`. It outputs the Gist ID and URL on separate lines.
3. Clone the Gist: `gh gist clone <id> tmp/.han-gist-sharing/<id>`.
4. Ensure `tmp/.han-gist-sharing/` is listed in `.gitignore`; add it if absent.
5. Write `tmp/.han-gist-sharing/<id>/manifest.yml` with `local_dir`, `gist_id: <id>`, `role: creator` (see manifest schema).
6. Write `<local-dir>/.han-gist-sharing-manifest.yml` with `gist_id: <id>` and an empty `collaborators:` block (see manifest schema). This file travels with the gist so collaborators can discover the creator's Gist ID.
7. **Context file (optional):** Ask the user: "Would you like to add a `.context.md` working-conventions file so Claude knows how to use this shared directory?" If yes: ask for the content, or confirm to write a minimal template. Also ask if there is a Linear project or GitHub URL for this work to include as a reference link. The template includes the directory name as a heading, an optional reference link (if provided), and placeholder text inviting the user to describe conventions — what skills read and write here, naming rules, what output belongs here vs elsewhere. Write the content to `<local-dir>/.context.md`. Then check `CLAUDE.md` at the project root: if the file exists and does not already contain `@<local-dir>/.context.md`, append that line. Tell the user: the context file will sync to teammates on the next push; teammates who join via Join mode will be prompted to add the import to their own CLAUDE.md.

8. **Stop-hook registration:** Set up automatic session-end syncing.
   - Copy `${CLAUDE_SKILL_DIR}/scripts/auto-push-gists.sh` to `.claude/scripts/auto-push-gists.sh` (skip if the file is already there).
   - Read `.claude/settings.json` if it exists. If a Stop hook for `bash .claude/scripts/auto-push-gists.sh` is not already present, add it. Write the updated (or new) file. The expected shape:
     ```json
     {
       "hooks": {
         "Stop": [
           {
             "matcher": "",
             "hooks": [{ "type": "command", "command": "bash .claude/scripts/auto-push-gists.sh" }]
           }
         ]
       }
     }
     ```
   - Tell the user: "Changes in this directory will now sync to the Gist automatically at the end of each session."

**If an existing entry:** Proceed directly to Step 4.

### Step 4: Sync files to the Gist

Run `${CLAUDE_SKILL_DIR}/scripts/sync-dir-to-gist.sh <src-dir> tmp/.han-gist-sharing/<gist-id>`.

### Step 5: Output

Display the Gist URL and the collaborator onboarding instructions from `${CLAUDE_SKILL_DIR}/references/collaboration-guide.md`, substituting the actual Gist ID.

---

## Pull Mode

A collaborator pulls the creator's latest updates into their local directory. Triggered when the Gist ID/URL is already in the manifest as `role: fork`.

### Step 2: Pull and sync

1. Look up the registry entry for this Gist: `gist_id` (the fork's own ID), `upstream_id`, `local_dir`.
2. `git -C tmp/.han-gist-sharing/<fork-id> pull upstream master`.
3. Run `${CLAUDE_SKILL_DIR}/scripts/sync-gist-to-dir.sh tmp/.han-gist-sharing/<fork-id> <local_dir>`.
4. Report which files changed.

---

## Join Mode

First-time collaborator setup for a Gist the creator shared.

### Step 2: Fork and clone

1. Extract the Gist ID from the URL (strip `https://gist.github.com/` and any trailing path).
2. Tell the user: "Fork this Gist first by running `gh gist fork <id>` in your terminal. When it completes, paste the fork's Gist ID here." Wait for the response.
3. Clone the fork: `gh gist clone <fork-id> tmp/.han-gist-sharing/<fork-id>`.
4. Add the creator's Gist as upstream: `git -C tmp/.han-gist-sharing/<fork-id> remote add upstream https://gist.github.com/<creator-id>.git`.

### Step 3: Sync to a local directory

Ask which `tmp/` subdirectory to sync the files into. Run `${CLAUDE_SKILL_DIR}/scripts/sync-gist-to-dir.sh tmp/.han-gist-sharing/<fork-id> <target-dir>`.

### Step 4: Record in manifest and output

Read `<target-dir>/.han-gist-sharing-manifest.yml` from the synced files to confirm `gist_id` (the creator's Gist ID). Write `tmp/.han-gist-sharing/<fork-id>/manifest.yml` with `local_dir: <target-dir>`, `gist_id: <fork-id>`, `role: fork`, `upstream_id: <creator-gist-id>`.

If `<target-dir>/.context.md` is present in the synced files, offer to add `@<target-dir>/.context.md` to `CLAUDE.md` at the project root. Check first — if the line is already there, skip silently.

Display the instructions from `${CLAUDE_SKILL_DIR}/references/collaboration-guide.md` (collaborator section), substituting the actual IDs.

---

## Add-Collaborator Mode

The creator registers a teammate's fork so they can later merge the teammate's changes.

Argument form: `--add-collaborator <name> <fork-gist-id-or-url>`

### Step 2: Add the remote

1. Resolve which creator Gist to use: find the `role: creator` entry in the registry. If there is more than one, ask the user which Gist this collaborator is forking.
2. Extract the fork Gist ID (strip URL prefix if needed).
3. `git -C tmp/.han-gist-sharing/<creator-id> remote add <name> https://gist.github.com/<fork-id>.git`.

### Step 3: Update the manifest

Add `<name>: <fork-id>` under `collaborators` in `<local-dir>/.han-gist-sharing-manifest.yml`. Sync immediately: run `${CLAUDE_SKILL_DIR}/scripts/sync-dir-to-gist.sh <local-dir> tmp/.han-gist-sharing/<creator-id>` so the updated collaborator list reaches the gist.

Confirm success and show the current remote list: `git -C tmp/.han-gist-sharing/<creator-id> remote -v`.

---

## Merge Mode

The creator fetches and merges a collaborator's changes.

Argument form: `--merge [<name>]`

### Step 2: Identify the collaborator

1. Resolve the creator's Gist ID from the registry (the `role: creator` entry).
2. If `<name>` was not provided and the registry lists multiple creator entries, show them and ask which one to merge.

### Step 3: Fetch, merge, push

In `tmp/.han-gist-sharing/<creator-id>/`:

1. `git fetch <name>`
2. `git merge <name>/master` — if conflicts arise, report them and stop. Do not auto-resolve.
3. `git push origin master`

### Step 4: Sync to local directory

Run `${CLAUDE_SKILL_DIR}/scripts/sync-gist-to-dir.sh tmp/.han-gist-sharing/<creator-id> <local_dir>`.

Report what changed.
