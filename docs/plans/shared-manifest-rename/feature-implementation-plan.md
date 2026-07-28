# Renaming the shared manifest via expand-and-contract

Deferred plan. The `gh-gist-collaboration` skill writes one file that leaves the
machine: `.han-gist-sharing-manifest.yml`, committed into the Gist and cloned by
everyone who joins or forks it. The skill was renamed from `gh-gist-sharing` in
`0233602`; this file kept the old spelling because renaming data that already
exists in other people's Gists is a distributed change, not a local one.

This plan aligns the name without ever leaving a Gist in a state some client
cannot read.

## Precondition, satisfied

This plan was written to wait on the earlier `manifest.yml` split migration,
because two half-applied migrations at once is the thing it exists to avoid.
That migration is now confirmed complete and `scripts/migrate-manifest.sh` has
been deleted, so nothing blocks Phase 1. Recover the script from git history if
an unmigrated workspace turns up.

## Why a straight rename fails

Three failure modes, in the order they would appear:

1. **Join mode breaks.** It reads the shared manifest out of the cloned Gist to
   learn the creator's `gist_id`, which is how it sets `upstream`. Against a
   Gist written before the rename, the file it wants is absent. The collaborator
   gets a clone with no upstream and no explanation.
2. **Split brain on the collaborator list.** Add-collaborator writes into that
   file. A Gist carrying both names has two collaborator lists, and which one
   wins depends on which plugin version each person is running. Nothing errors.
3. **Fan-out.** Every Gist and every fork is a separate repository needing its
   own `git mv` and push. A fork with unpushed work hits a rename-versus-modify
   conflict on the next merge.

## Phase 1. Expand: read both, write both

Ship this and let it run for a while. Nothing is deleted in this phase, so a
client on the old plugin version keeps working throughout.

Read sites, all in `han-github/skills/gh-gist-collaboration/SKILL.md`:

- Join Mode, Step 3, reads the shared manifest to confirm the creator's
  `gist_id`.
- Add-Collaborator Mode, Step 3, edits `collaborators` in it.

Change each to prefer `.han-gist-collaboration-manifest.yml` and fall back to
`.han-gist-sharing-manifest.yml` when the preferred name is absent. Prefer the
new name even when both exist, so a Gist mid-migration converges rather than
oscillating.

Write sites:

- Push Mode, Step 3.6, creates the shared manifest for a new Gist.
- Add-Collaborator Mode, Step 3, updates and pushes it.

Change each to write **both** filenames with identical content, and to stage and
push both. Dual write is what makes the phase safe: a collaborator still on the
old plugin version reads the legacy name and sees current data.

Also update `references/manifest-schema.md` to document both names and say which
one is authoritative during the transition.

## Phase 2. Migrate: get both files into every Gist

Each creator runs the skill once against each of their Gist directories, which
dual-writes and pushes. Each collaborator then pulls. Nothing to automate; the
existing push and pull modes do it.

Done when every Gist and every fork carries both files. Verify per Gist:

    git -C tmp/features/<project-name> ls-tree --name-only origin/master

Both filenames should appear. Check the collaborator's fork the same way before
declaring the phase complete. A fork that never pulled is the case that breaks
Phase 3.

## Phase 3. Contract: drop the legacy name

Only after Phase 2 is verified across every Gist and fork:

1. Remove the fallback read and the legacy write from SKILL.md, leaving
   `.han-gist-collaboration-manifest.yml` as the only name.
2. Delete the legacy file from each Gist:

       git -C tmp/features/<project-name> rm .han-gist-sharing-manifest.yml
       git -C tmp/features/<project-name> commit -m "chore: drop legacy manifest name"
       git -C tmp/features/<project-name> push origin master

3. Update `references/manifest-schema.md`: drop the dual-name documentation and
   the note explaining why the old spelling persisted.

## Rollback

Phase 1 is safe to revert at any point: both files exist, so reverting to the
legacy-only reader loses nothing. Phase 3 is the irreversible step, which is why
it waits on per-Gist verification rather than on a calendar date. If a fork
surfaces after Phase 3 that only has the legacy file, recover it by cloning the
fork, copying the legacy file to the new name, and pushing.

## Verification

- After Phase 1: create a throwaway Gist, confirm both files appear in it, then
  join it from a second directory and confirm upstream is set correctly.
- After Phase 3: repeat the same two checks and confirm only the new filename
  appears.
