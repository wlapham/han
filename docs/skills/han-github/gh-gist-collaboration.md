# /gh-gist-collaboration

Operator documentation for the `/gh-gist-collaboration` skill in the han plugin. This document helps you decide *when* and *how* to use the skill. For what the skill does internally, read the skill definition at [`han-github/skills/gh-gist-collaboration/SKILL.md`](../../../han-github/skills/gh-gist-collaboration/SKILL.md).

> See also: [Plugin landing page](../../../README.md) · [All skills](../README.md) · [All agents](../../agents/README.md)

## TL;DR

- **What it does.** Shares a directory under `tmp/features/` with teammates through a GitHub Gist, and keeps both sides in sync by treating the Gist as a git remote.
- **When to use it.** Two or more people need to read and write the same working documents (handoffs, investigations, feature drafts) and there is no shared repository to put them in.
- **What you get back.** A Gist URL to send your teammate, a local directory that is also the Gist clone, and a Stop hook that pushes your changes at the end of every session.

## Key concepts

- **The working directory is the Gist clone.** `tmp/features/<project-name>` is a git repository whose remote is the Gist. There is no staging directory and no copy step, so a file you write is a file that syncs.
- **Gists are git repositories.** Every Gist has a git remote, which is what makes fork, pull, and merge available. It is also why the skill can use plain git commands rather than the Gists API.
- **Gists are flat.** A Gist cannot represent a directory tree. The skill refuses to share a directory containing subdirectories rather than silently flattening or skipping them.
- **Creator and fork roles.** The person who creates the Gist is the creator. Everyone else forks it, which produces a second Gist they own, with the creator's Gist set as `upstream`. Changes travel back to the creator by merge, not by direct push.
- **Two manifests, two scopes.** `manifest.yml` records this machine's Gist ID and role and never leaves the machine. `.han-gist-sharing-manifest.yml` sits beside it, syncs to the Gist, and carries the creator's Gist ID and the collaborator list so teammates can find each other. The second keeps an older spelling on purpose; see [`references/manifest-schema.md`](../../../han-github/skills/gh-gist-collaboration/references/manifest-schema.md).
- **The registry is derived, not stored.** At startup the skill scans `tmp/features/*/manifest.yml` to build an in-memory registry. Nothing central tracks your Gists, so deleting a directory deregisters it.
- **Session-end push is personal.** The Stop hook and its script install outside the repository, so enabling automatic sync adds nothing to version control and nothing to a teammate's session.
- **gh CLI required.** Without `gh` the skill stops immediately and tells you to install it.

## When to use it

**Invoke when:**

- You want a teammate to read and edit your working notes for a piece of work, and neither of you wants them in the project repository.
- You are handing off an investigation and the recipient needs to add to it rather than just read it.
- A teammate has sent you a Gist URL and you want it set up locally with the right remotes.
- You need to pull a collaborator's changes back into the Gist you own.

**Do not invoke for:**

- **Sharing a single file with no expectation of edits.** Run `gh gist create` directly; the manifests and remotes exist to support two-way work.
- **Anything that belongs in the repository.** Committed code, docs, and plans go in the repo. A Gist is for the working material around them.
- **Posting a review or description to a pull request.** Use [`/post-code-review-to-pr`](./post-code-review-to-pr.md) or [`/update-pr-description`](./update-pr-description.md).
- **Publishing work items as trackable issues.** Use [`/work-items-to-issues`](./work-items-to-issues.md).

## How to invoke it

Run `/gh-gist-collaboration` in Claude Code. The argument selects the mode.

Give it:

1. **A path, to push.** A directory under `tmp/features/`. On the first run the skill asks whether the Gist should be public or secret, and for a short project name to use as the directory name.
2. **A Gist URL or ID, to join or pull.** The skill decides between the two by looking the ID up in the registry. Known fork means pull; unknown means first-time join.
3. **`--add-collaborator <name> <fork-id>`, to register a teammate's fork.** Needed once per collaborator before you can merge their work.
4. **`--merge [<name>]`, to pull a collaborator's changes into your Gist.**

Example prompts:

- `/gh-gist-collaboration`. With no argument, lists the Gists registered on this machine and stops.
- `/gh-gist-collaboration tmp/features/topaz-fit`. Create or update the Gist for that directory.
- `/gh-gist-collaboration https://gist.github.com/<id>`. Join a Gist a teammate sent you.
- `/gh-gist-collaboration --add-collaborator alice <alice-fork-id>`. Register Alice's fork as a remote.
- `/gh-gist-collaboration --merge alice`. Fetch and merge Alice's changes, then push the result.

## What you get back

Which artifacts appear depends on the mode.

- **A Gist, public or secret**, described as `[<repo-name>] <project-name>` so it is identifiable in a list of Gists.
- **`tmp/features/<project-name>`**, a git repository with the Gist as `origin`. For a collaborator, the fork is `origin` and the creator's Gist is `upstream`.
- **`manifest.yml`**, inside that directory, holding `local_dir`, `gist_id`, `role`, and (on a fork) `upstream_id`. Excluded from every `git add`, so it never reaches GitHub.
- **`.han-gist-sharing-manifest.yml`**, beside it, holding the creator's `gist_id` and the `collaborators` map. This one does sync, which is how a new collaborator discovers who to set as upstream.
- **`.context.md`, when you opt in.** A working-conventions file written from [`references/context-file-template.md`](../../../han-github/skills/gh-gist-collaboration/references/context-file-template.md), plus an `@` import appended to your `CLAUDE.md` so Claude picks it up each session. It syncs with everything else, and teammates who join are offered the same import.
- **A Stop hook.** `~/.claude/scripts/han-gist-auto-push.sh` and a hook registration in the project's gitignored `.claude/settings.local.json`. At session end the script pushes every directory whose manifest says `role: creator`. It exits immediately when `tmp/features` is absent, so it costs nothing in projects that do not use the skill.
- **Onboarding text to send your teammate**, from [`references/collaboration-guide.md`](../../../han-github/skills/gh-gist-collaboration/references/collaboration-guide.md), with the real Gist ID filled in.

## How to get the most out of it

- **Pick the project name deliberately.** It becomes the directory name on your machine and, through the Gist description, the label everyone sees. Rename cost is real, so choose the name you would use in conversation.
- **Choose secret for anything client-adjacent.** A secret Gist is unlisted, not private. Anyone with the URL can read it, and forks stay secret but remain reachable by URL. Nothing sensitive belongs in either kind.
- **Write `.context.md` even when it feels premature.** It is the only place that tells a teammate's Claude what the directory is for. Two lines beat nothing, and it syncs, so it improves as the work does.
- **Keep it flat from the start.** The skill rejects subdirectories, so a structure you build locally has to be flattened before the first push. Naming files `area-topic.md` costs less than reorganizing later.
- **Register collaborators before you need to merge.** `--add-collaborator` is a one-time setup per person. Doing it when they tell you their fork ID is easier than doing it while trying to merge.
- **Let the Stop hook do the pushing.** Once installed you rarely need push mode again. Run it explicitly when you want a checkpoint mid-session or want to see the output.
- **Re-run the skill on each machine you work from.** The hook is personal to the machine that installed it and does not travel.

## Cost and latency

No agents are dispatched and no model tier is involved beyond the conversation itself. Every step is a `gh` or `git` call, or a small shell script under [`scripts/`](../../../han-github/skills/gh-gist-collaboration/scripts/). Runs are a few seconds, dominated by network round trips to GitHub. The skill is built for tight-loop use, and the Stop hook makes the common case (push what changed) cost nothing at all.

## In more detail

Step 1 is always mode detection. The skill reads the argument, builds the registry by scanning `tmp/features/*/manifest.yml`, and routes to one of five modes. The interesting case is a bare Gist ID, which means pull when the registry already knows it as a fork, and join when it does not.

**Push mode** validates that the path is under `tmp/features/`, has no subdirectories, and lists what will be shared. If the registry has no entry for the directory, the skill gates on a human: it shows the file list, asks public or secret, and asks for a project name before creating anything. It then creates the Gist through [`scripts/create-gist-from-dir.sh`](../../../han-github/skills/gh-gist-collaboration/scripts/create-gist-from-dir.sh), wires the directory up as the clone, writes both manifests, offers `.context.md`, and installs the Stop hook. With an entry already present it skips straight to the push, which runs [`scripts/sync-dir-to-gist.sh`](../../../han-github/skills/gh-gist-collaboration/scripts/sync-dir-to-gist.sh) and reports when there was nothing to send.

**Join mode** is deliberately not fully automatic. Forking a Gist is something you do in your own terminal with `gh gist fork`, and the skill waits for you to paste the resulting fork ID rather than forking on your behalf. It then clones your fork, adds the creator's Gist as `upstream`, reads the shared manifest to confirm the creator's ID, writes your local manifest with `role: fork`, and offers the `.context.md` import if the creator wrote one.

**Pull mode** is a single `git pull upstream master` against your fork, followed by a report of what changed.

**Add-collaborator mode** adds a named remote pointing at a teammate's fork, records the pairing in the shared manifest, and pushes it so everyone sees the same collaborator list.

**Merge mode** fetches that remote, merges `<name>/master`, and pushes. Conflicts stop the skill and are reported rather than resolved, because a conflict in shared working documents is a conversation, not a mechanical merge.

## Sources

### GitHub: Creating gists, and forking and cloning gists

GitHub's Gist documentation establishes that every Gist is a git repository with a clone URL, and that a fork is a separate Gist owned by the forker. The skill's entire collaboration model, upstream remotes and merge rather than shared write access, follows from those two facts. The same documentation is the source of the flat-file constraint the skill enforces.

URL: https://docs.github.com/en/get-started/writing-on-github/editing-and-sharing-content-with-gists/creating-gists

### GitHub CLI manual: `gh gist`

The `gh gist create`, `gh gist fork`, and `gh gist clone` commands are the skill's interface to Gists, chosen over the REST API so that authentication is whatever the operator already configured for `gh`.

URL: https://cli.github.com/manual/gh_gist

## Related documentation

- [Plugin landing page](../../../README.md). The front door. Start here if you arrived from outside the docs tree.
- [Skills Index](../README.md). All skills, grouped by purpose.
- [`/post-code-review-to-pr`](./post-code-review-to-pr.md). Post a code review to a pull request through the same `gh` CLI.
- [`/update-pr-description`](./update-pr-description.md). Generate a PR description for a branch.
- [`/investigate`](../han-coding/investigate.md). Produces the kind of working document this skill is built to share.
- [`SKILL.md` for /gh-gist-collaboration](../../../han-github/skills/gh-gist-collaboration/SKILL.md). The internal process definition.
