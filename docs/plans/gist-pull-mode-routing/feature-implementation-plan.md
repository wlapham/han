# Routing a Gist URL to the right mode

Planned fix for `gh-gist-collaboration`. When a collaborator passes the creator's
Gist URL to pull the latest changes, which is what the collaboration guide tells
them to do, the skill can route to Join mode instead of Pull mode. A creator who
passes their own Gist URL matches no rule at all. This plan moves the routing
decision out of prose and into a tested script, so the same argument always picks
the same mode.

## The defect

Step 1 of `han-github/skills/gh-gist-collaboration/SKILL.md` routes a Gist URL or
ID with two rules:

- appears in the registry as `role: fork` → Pull mode
- is NOT in the registry → Join mode

The registry is built from each `tmp/features/*/manifest.yml`. On a
collaborator's machine that file looks like this:

```yaml
local_dir: tmp/features/client-onboarding
gist_id: <fork-id>          # the collaborator's own fork
role: fork
upstream_id: <creator-id>   # the Gist they were invited to
```

The collaborator only ever handles the creator's ID. It is the URL they were
sent, and `references/collaboration-guide.md` tells them to pull with it:

> To pull my latest updates: run `/gh-gist-collaboration https://gist.github.com/<CREATOR_GIST_ID>` again.

Read literally, "appears in the registry" means `gist_id`, and the creator's ID is
stored as `upstream_id`. So the rule that should fire does not, the "NOT in the
registry" rule does, and the collaborator lands in Join mode. Whether that
happens depends on how the model reads one sentence, so the outcome can differ
from one run to the next.

### What a misroute does

Join mode, Step 2, tells the collaborator to run `gh gist fork <id>` again and
paste the result, asks for a project name, and runs
`gh gist clone <fork-id> tmp/features/<project-name>`. Then:

1. If they reuse the project name, the clone fails because the directory already
   exists, and nothing has been pulled.
2. If they pick a new name, they end up with a second clone of the same work and
   a second `manifest.yml` pointing at the same upstream. The registry now holds
   two entries for one Gist, and later runs have two candidates to pick from.
3. Either way they did not get the creator's changes, which was the only thing
   they asked for.

### The creator's own URL

On the creator's machine the manifest has `role: creator` and
`gist_id: <creator-id>`. Passing that ID matches neither rule: it is in the
registry, but not as a fork. The skill has no defined behavior here. The likely
intent is "sync this Gist," which is Push mode for that entry's `local_dir`.

### Why this is a script and not a prose fix

Rewording the bullet ("match `gist_id` or `upstream_id`") would probably fix the
common case, but it leaves the decision to interpretation. It is also the kind of
logic Han's script-execution guidance says to extract: deterministic, the same
every run, easy to get subtly wrong in prose, and easy to test. The skill already
reads manifests with a `ruby -r yaml` one-liner in `scripts/auto-push-gists.sh`,
so the new script needs no new tools.

## The fix

### New script: `scripts/resolve-gist-mode.sh`

```
Usage: resolve-gist-mode.sh <gist-url-or-id> [<project-root>]
```

`<project-root>` defaults to the current directory, matching
`install-stop-hook.sh`. The script reads `<project-root>/tmp/features/*/manifest.yml`
and nothing else. It makes no network calls and writes nothing.

**Normalizing the argument.** Accept every form a person is likely to paste and
reduce it to the bare ID:

| Input                                                 | ID                |
| ----------------------------------------------------- | ----------------- |
| `9c20ca39bf70575724be87618b87a05e`                    | itself            |
| `https://gist.github.com/9c20ca39bf70575724be87618b87a05e` | last segment |
| `https://gist.github.com/wlapham/9c20ca39bf70575724be87618b87a05e` | last segment |
| the same with a trailing `/`, `#file-notes-md`, or `?query` | strip, then last segment |
| `https://gist.github.com/<id>.git`, `git@gist.github.com:<id>.git` | strip `.git` |

After normalizing, the ID must match `^[0-9a-f]+$`. Anything else is a usage
error (exit 2, message on stderr). Compare case-insensitively, and lowercase
before comparing.

**Matching.** For each manifest, compare the ID as a string against `gist_id`
and, for `role: fork` entries, against `upstream_id`. Read both values with
`.to_s` so a YAML value that happens to parse as a number still compares
correctly. An ID made only of digits and a single `e` parses as a float, which
is unlikely at 32 characters but costs one call to rule out.

**Output contract.** One line on stdout, tab-separated, exit 0:

| Match                                              | Output                     |
| -------------------------------------------------- | -------------------------- |
| a `role: fork` entry's `gist_id` or `upstream_id`  | `pull<TAB><local_dir>`     |
| a `role: creator` entry's `gist_id`                | `push<TAB><local_dir>`     |
| nothing                                            | `join`                     |

Two error cases, both exit 2 with a message on stderr and nothing on stdout:

- **More than one entry matches.** This is the duplicate-clone state a past
  misroute leaves behind. List every matching `local_dir` so the person can
  delete the stray copy. Do not guess which one is real.
- **A manifest fails to parse.** Name the file. Skipping it silently would route
  a known Gist to Join mode, which is the bug this plan exists to fix.

A missing `tmp/features` directory is not an error. It means nothing is
registered yet, so the output is `join`.

Follow the conventions of the existing scripts: the
`[ -n "$HAN_GIST_SHELL" ] || exec env HAN_GIST_SHELL=1 "${SHELL:-bash}" "$0" "$@"`
re-exec line, `set -euo pipefail`, and a usage comment at the top. It must pass
ShellCheck through `npm run lint`.

### Changes to `SKILL.md`

**Step 1, Mode Detection.** Replace the two Gist-URL bullets with one:

> - Argument looks like a Gist URL or ID → run `${CLAUDE_SKILL_DIR}/scripts/resolve-gist-mode.sh <argument>` and route on the first field of its output: `pull` → **Pull mode**, `push` → **Push mode**, `join` → **Join mode**. The second field is the entry's `local_dir`; use it in that mode instead of looking the entry up again. If the script exits non-zero, show its message and stop.

Keep the registry scan in Step 1. The no-argument listing and Push mode's
path lookup still use it.

**Pull Mode, Step 2.** It currently starts from "Look up the registry entry for
this Gist." Change it to take `local_dir` from the script's output. The pull
itself, `git -C <local_dir> pull upstream HEAD`, does not change.

**Push Mode, Step 3.** When routed from a Gist URL, the entry already exists, so
go straight to Step 4 with the `local_dir` from the script.

**Join Mode, Step 2.** Add a guard before cloning: if
`tmp/features/<project-name>` already exists, stop and say so rather than letting
`gh gist clone` fail halfway. The resolver makes a misroute into Join mode much
less likely, but a person can still pick a name that is taken.

Do not add the script to `allowed-tools`. Per
`han-plugin-builder/skills/guidance/references/skill-building-guidance/script-execution-instructions.md`,
script commands cannot be reliably auto-approved, and the skill's other scripts
are not listed either.

### Documentation

- `references/collaboration-guide.md`: the pull instruction stays the same,
  because the creator's URL is now the right thing to pass. Add one line saying
  either the creator's URL or the collaborator's own fork URL works.
- `references/manifest-schema.md`: in the local-manifest rules, note that the
  registry is matched on `gist_id` and, for forks, `upstream_id`, and that one
  Gist must not have two local directories.
- `han-github/docs/skills/gh-gist-collaboration.md`:
  - The "How to use it" list (around line 47) says "Known fork means pull."
    Change it to say a creator's or fork's ID both mean pull for a collaborator,
    and the creator's own ID means push.
  - The "How it works" paragraph on Step 1 (around line 87) gets the same
    correction and names the script.

## Tests first

Add `test/resolve-gist-mode.bats`, in the style of
`test/install-stop-hook.bats`: each test builds its own project root under
`$BATS_TEST_TMPDIR` and writes fixture manifests, and nothing touches the
network. Write it before the script and confirm each case fails for the right
reason.

Fixture IDs: `CREATOR=aaaa…` (32 chars), `FORK=bbbb…`, `OTHER=cccc…`.

1. A collaborator passing the creator's bare ID gets `pull<TAB>tmp/features/x`.
   This is the case the plan exists for.
2. A collaborator passing their own fork ID gets the same.
3. The creator passing their own ID gets `push<TAB>tmp/features/x`.
4. An unregistered ID gets `join`.
5. No `tmp/features` directory at all gets `join`.
6. Every URL form in the normalization table resolves to the same output as
   the bare ID. Write this as one test with sequential `run` calls, one per form.
7. Uppercase hex matches a lowercase manifest value.
8. Two manifests matching one ID exit 2, list both directories, and print
   nothing on stdout.
9. A manifest that fails to parse exits 2 and names the file.
10. An argument that is not a Gist ID (`not-a-gist`) exits 2.
11. A `role: creator` entry whose `gist_id` equals the argument is not treated
    as a fork's upstream. This guards against a matcher that checks
    `upstream_id` on every entry.

`npm test` runs `bats --recursive test/`, so the new file is picked up with no
config change.

## Out of scope, noticed along the way

These came up while tracing the defect. Each is its own change.

1. **`create-gist-from-dir.sh` fails by default.** It now defaults
   `VISIBILITY_FLAG` to `--secret` and passes it straight to `gh gist create`.
   The `gh` CLI has no `--secret` flag (secret is its default; the flag is
   `-p/--public`), so every new Gist fails with `unknown flag: --secret`.
   `test/create-gist-visibility.bats` doesn't catch it because its `gh` stub
   accepts any argument. The fix is to pass nothing for secret and `--public`
   only when asked, and to change the first and third tests to assert that
   `--secret` never reaches `gh`.
2. **The long-form doc still says `master`.** "Pull mode is a single
   `git pull upstream master`" and "merges `<name>/master`" in
   `han-github/docs/skills/gh-gist-collaboration.md` no longer match the skill,
   which pulls `upstream HEAD` and merges `FETCH_HEAD`.
3. **The manifest-rename plan verifies against `origin/master`.**
   `docs/plans/shared-manifest-rename/feature-implementation-plan.md`, Phase 2,
   checks `ls-tree --name-only origin/master`. Gists created now use `main`, so
   that check would report a false failure. Plans are archives, so fix this only
   when that plan is picked up.
4. **A pulled fork falls behind its own origin.** Pull mode pulls `upstream`
   into the local clone but never pushes, so the collaborator's fork Gist lags
   until their next push. Harmless today, since the creator merges from the fork
   and the fork never needs the creator's commits, but worth knowing if Merge
   mode starts reporting conflicts that are really just stale history.

## Release

The fix ships as fork release `han-github 2.4.0-wl.4`, per
`docs/adr/release-fork-plugin-versioning.md`. The skill is still unreleased
upstream, so the base stays `2.4.0` and only the counter moves.

1. Bump `version` in `han-github/.claude-plugin/plugin.json` to `2.4.0-wl.4`.
2. Add a paragraph to the `han-github` entry under "Unreleased (fork)" in
   `CHANGELOG.md`: a collaborator can pull with the creator's URL, the
   creator's own URL syncs, and an ambiguous registry stops with a message.
3. Run `npm test` and `npm run lint`.
4. Commit in this order, each separately: the failing test, the script, the
   `SKILL.md` routing change, the docs, the version bump with CHANGELOG.

## Verifying it end to end

After teammates update, check on a real pair of machines:

1. On the collaborator's machine, run
   `/han-github:gh-gist-collaboration https://gist.github.com/<creator-id>`. It
   should report Pull mode and list the changed files, with no fork prompt.
2. Run it again with the collaborator's own fork URL. Same result.
3. On the creator's machine, run it with the creator's own URL. It should push
   (or report nothing to push), not ask to fork.
4. On a machine with no clone, run it with the creator's URL. It should start
   Join mode as before.

## Done when

- `test/resolve-gist-mode.bats` passes, and `npm test` and `npm run lint` are clean.
- `SKILL.md` Step 1 routes every Gist URL or ID through the script.
- All four end-to-end checks behave as described.
