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
argument-hint: "[<project-name-or-path> | <gist-url-or-id> | --add-collaborator <name> <fork-id> | --merge [<name>]]"
allowed-tools: Bash(gh *), Bash(git *), Bash(find *), Read, Write, Edit
---

## Pre-requisites

- gh CLI: !`which gh 2>/dev/null || echo "not installed"`

If `gh` is not found, inform the user it must be installed and configured, then stop.

## Mode Detection (Step 1)

Route based on the argument:

- Argument starts with `--add-collaborator` → **Add-collaborator mode**
- Argument starts with `--merge` → **Merge mode**
- Argument looks like a local path (starts with `tmp/`) → **Push mode**
- Argument looks like a Gist URL or 32-char hex ID, AND appears in the registry as `role: fork` → **Pull mode**
- Argument looks like a Gist URL or 32-char hex ID, AND is NOT in the registry (or no clones registered yet) → **Join mode**
- No argument → Display the registry (or "no Gists shared yet" if empty), show usage summary, and stop.

Build the in-memory registry now: `find tmp/features -maxdepth 2 -name manifest.yml 2>/dev/null`. Read each found file to collect `{gist_id, local_dir, role, upstream_id}` per entry. The manifest schema is documented in `${CLAUDE_SKILL_DIR}/references/manifest-schema.md`.

---

## Push Mode

The creator syncs local changes to their Gist. The working directory at `tmp/features/<project-name>` is also the Gist clone — no separate clone directory.

### Step 2: Validate the directory

1. Confirm the path exists under `tmp/features/`.
2. Run `find <dir> -maxdepth 1 -mindepth 1 -type d ! -name .git` to check for subdirectories. If any exist, list them and stop — Gists are flat and cannot represent directory structure.
3. List the files that will be shared: `find <dir> -maxdepth 1 -mindepth 1 -type f`.

### Step 3: Look up or create the Gist

Check the registry for an existing entry where `local_dir` matches.

**If no existing entry (new Gist):** Human gate before creating.
1. Show the user: the directory path, the file list, and ask whether the Gist should be public or secret.
2. Ask for a short human-readable project name to use as the directory name (e.g. `topaz-fit`). The directory will be at `tmp/features/<project-name>`.
3. Run `${CLAUDE_SKILL_DIR}/scripts/create-gist-from-dir.sh <dir> "[<repo-name>] <project-name>" [--secret]`. It outputs the Gist ID and URL on separate lines.
4. Set up `tmp/features/<project-name>` as the Gist clone:
   - If the directory already exists with content: `git -C tmp/features/<project-name> init`, `git -C tmp/features/<project-name> remote add origin git@gist.github.com:<id>.git`, stage all files except manifest.yml (`git -C tmp/features/<project-name> add -A -- ':!manifest.yml'`), commit, then `git -C tmp/features/<project-name> push --force -u origin master`.
   - If the directory does not yet exist: `gh gist clone <id> tmp/features/<project-name>`.
5. Write `tmp/features/<project-name>/manifest.yml` with `local_dir: tmp/features/<project-name>`, `gist_id: <id>`, `role: creator` (see manifest schema).
6. Write `tmp/features/<project-name>/.han-gist-sharing-manifest.yml` with `gist_id: <id>` and an empty `collaborators:` block (see manifest schema). This file travels with the gist so collaborators can discover the creator's Gist ID.
7. **Context file (optional):** Ask the user: "Would you like to add a `.context.md` working-conventions file so Claude knows how to use this shared directory?" If yes, ask for the content (or confirm they want the template as-is), and ask whether there is a Linear project or GitHub URL to include as a reference link. Fill in `${CLAUDE_SKILL_DIR}/references/context-file-template.md` and write the result to `tmp/features/<project-name>/.context.md`. Then check `CLAUDE.md` at the project root: if the file exists and does not already contain `@tmp/features/<project-name>/.context.md`, append that line. Tell the user: the context file will sync to teammates on the next push; teammates who join via Join mode will be prompted to add the import to their own CLAUDE.md.

8. **Stop-hook registration:** Set up automatic session-end syncing by running `${CLAUDE_SKILL_DIR}/scripts/install-stop-hook.sh`. It installs the push script to `~/.claude/scripts/han-gist-auto-push.sh`, outside the repository, and registers the Stop hook in the project's gitignored `.claude/settings.local.json`, preserving every other setting and skipping registration when the hook is already there. Then tell the user: "Changes in this directory will now sync to the Gist automatically at the end of each session. The hook is personal to this machine — run this skill again on any other machine you work from."

**If an existing entry:** Proceed directly to Step 4.

### Step 4: Sync files to the Gist

Push the directory by running `${CLAUDE_SKILL_DIR}/scripts/sync-dir-to-gist.sh tmp/features/<project-name>`. It stages everything except `manifest.yml`, commits with a timestamped message, and pushes to the Gist. When there is nothing to push it says so and exits cleanly. Report its output to the user.

### Step 5: Output

Display the Gist URL and the collaborator onboarding instructions from `${CLAUDE_SKILL_DIR}/references/collaboration-guide.md`, substituting the actual Gist ID.

---

## Pull Mode

A collaborator pulls the creator's latest updates into their local directory. Triggered when the Gist ID/URL is already in the manifest as `role: fork`.

### Step 2: Pull

1. Look up the registry entry for this Gist: `gist_id` (the fork's own ID), `upstream_id`, `local_dir`.
2. `git -C tmp/features/<project-name> pull upstream master`
3. Report which files changed.

---

## Join Mode

First-time collaborator setup for a Gist the creator shared.

### Step 2: Fork and clone

1. Extract the Gist ID from the URL (strip `https://gist.github.com/` and any trailing path).
2. Tell the user: "Fork this Gist first by running `gh gist fork <id>` in your terminal. When it completes, paste the fork's Gist ID here." Wait for the response.
3. Ask for a short human-readable project name for the local directory (e.g. `topaz-fit`). The directory will be at `tmp/features/<project-name>`.
4. Clone the fork: `gh gist clone <fork-id> tmp/features/<project-name>`.
5. Add the creator's Gist as upstream: `git -C tmp/features/<project-name> remote add upstream https://gist.github.com/<creator-id>.git`.

### Step 3: Record in manifest and output

Read `tmp/features/<project-name>/.han-gist-sharing-manifest.yml` from the cloned files to confirm `gist_id` (the creator's Gist ID). Write `tmp/features/<project-name>/manifest.yml` with `local_dir: tmp/features/<project-name>`, `gist_id: <fork-id>`, `role: fork`, `upstream_id: <creator-gist-id>`.

If `tmp/features/<project-name>/.context.md` is present in the cloned files, offer to add `@tmp/features/<project-name>/.context.md` to `CLAUDE.md` at the project root. Check first — if the line is already there, skip silently.

Display the instructions from `${CLAUDE_SKILL_DIR}/references/collaboration-guide.md` (collaborator section), substituting the actual IDs.

---

## Add-Collaborator Mode

The creator registers a teammate's fork so they can later merge the teammate's changes.

Argument form: `--add-collaborator <name> <fork-gist-id-or-url>`

### Step 2: Add the remote

1. Resolve which creator Gist to use: find the `role: creator` entry in the registry. If there is more than one, ask the user which Gist this collaborator is forking.
2. Extract the fork Gist ID (strip URL prefix if needed).
3. `git -C tmp/features/<project-name> remote add <name> https://gist.github.com/<fork-id>.git`.

### Step 3: Update the manifest

Add `<name>: <fork-id>` under `collaborators` in `tmp/features/<project-name>/.han-gist-sharing-manifest.yml`, then sync it to the Gist immediately:

1. Stage the manifest by running `git -C tmp/features/<project-name> add .han-gist-sharing-manifest.yml`.
2. Commit it by running `git -C tmp/features/<project-name> commit -m "chore: add collaborator <name>"`.
3. Push it by running `git -C tmp/features/<project-name> push origin master`.

Confirm success and show the current remote list by running `git -C tmp/features/<project-name> remote -v`.

---

## Merge Mode

The creator fetches and merges a collaborator's changes.

Argument form: `--merge [<name>]`

### Step 2: Identify the collaborator

1. Resolve the creator's project directory from the registry (the `role: creator` entry).
2. If `<name>` was not provided and the registry lists multiple creator entries, show them and ask which one to merge.

### Step 3: Fetch, merge, push

1. Fetch the collaborator's fork by running `git -C tmp/features/<project-name> fetch <name>`.
2. Merge it by running `git -C tmp/features/<project-name> merge <name>/master`. If conflicts arise, report them and stop. Do not auto-resolve.
3. Push the result by running `git -C tmp/features/<project-name> push origin master`.

Report what changed.
