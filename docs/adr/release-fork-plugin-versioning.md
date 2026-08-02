# Fork plugin versions use a `-wl` semver prerelease

- **Status:** accepted
- **Date Created:** 2026-08-02 12:09
- **Last Updated:** 2026-08-02 12:09

## Context

This repository is a fork of `testdouble/han`, and the fork's owner is not a maintainer of the upstream repository. The release rules in [`../semantic-versioning.md`](../semantic-versioning.md) govern upstream. They do not decide what this fork publishes.

The fork exists to iterate on the `gh-gist-collaboration` workflow in `han-github` and to share it with a small number of teammates, who install plugins directly from this fork. For their Claude Code installations to notice new work, the `version` field in each changed plugin's `plugin.json` has to change.

Two findings constrain how that field can be set.

`plugin.json` decides what gets fetched, not `marketplace.json`. The cache directory `~/.claude/plugins/cache/han/han-github/ffaa265` exists while `.claude-plugin/marketplace.json` still records `2.2.2` for the same plugin. Claude Code followed `plugin.json`.

The field is specified as semver. The Claude Code binary carries the string `version (e.g., 1.2.3) following semver.org specification` and bundles a semver comparison library.

Until this decision, the fork wrote a short git SHA into the field. Eight consecutive `han-github` bumps used it, most recently `ffaa265`. A SHA cannot collide with an upstream number, which was the point, but it is not a semver value and it carries no ordering.

## Decision Drivers

- Teammates must detect every update published from this fork.
- A fork version must never collide with a version upstream might publish.
- Upstream's numbering is not ours to change, so the fork adapts to it.
- The value must stay valid semver, because that is what the field is specified to hold.
- When forked work merges upstream and testdouble publishes a release, teammates should move back to that release rather than sitting on a fork build forever.
- The same content can exist as more than one commit. The code-smell-baseline work exists as `751e4a9` on `feat/code-smell-baseline` and as `2d57171` on `main`.

## Considered Options

1. **Short git SHA of the bump commit's parent** (the prior approach)
   - Pro: collision with upstream is impossible.
   - Pro: the value names the exact commit the plugin's tree is at.
   - Con: not valid semver, so it works as unvalidated behavior rather than as a contract.
   - Con: no ordering relationship to upstream's numbers, so nothing moves a teammate back when the work ships upstream.
   - Con: no answer for which commit to record when identical content exists on two branches.

2. **Continue upstream's semver line**, bumping `han-github` to `2.3.0` and so on
   - Pro: ordinary semver, and every tool behaves.
   - Pro: nothing new to learn or maintain.
   - Con: collides directly with upstream, since testdouble will publish its own `2.3.0`.
   - Con: a teammate holding the fork's `2.3.0` would never receive upstream's `2.3.0`, because the versions rank equal.

3. **Semver build metadata**, such as `2.2.2+wl.3`
   - Pro: valid semver, and unambiguous about origin.
   - Pro: leaves the upstream number visible.
   - Con: semver precedence ignores build metadata, so `2.2.2+wl.3` and `2.2.2+wl.4` rank equal and no update is detected. This defeats the requirement outright.
   - Con: some tooling drops the metadata when normalizing.

4. **Date-based versions**, such as `2026.8.2`
   - Pro: valid semver, and monotonic without any bookkeeping.
   - Pro: obviously a fork build at a glance.
   - Con: carries no relationship to upstream's numbering, so it cannot express that an upstream release supersedes a fork build.
   - Con: two builds on one day still need a further segment, so the counter returns anyway.

5. **Semver prerelease naming the fork**, such as `2.3.0-wl.1` (chosen)
   - Pro: valid semver, monotonic, and collision-free at once.
   - Pro: ranks below the upstream release it anticipates, so teammates roll off the fork automatically.
   - Con: requires classifying each change's level against upstream's rules before picking the base.
   - Con: the counter is manual, so a missed increment publishes a version teammates already hold.

## Decision

We will version fork builds as `<next-upstream-version>-wl.<n>`.

The base is the version the change would warrant upstream, classified against [`../semantic-versioning.md`](../semantic-versioning.md). The `-wl.<n>` suffix is a counter, incremented once per fork release.

Semver precedence supplies four properties at once:

| Comparison | Result | What it buys |
|---|---|---|
| `2.3.0-wl.2` vs `2.3.0-wl.1` | greater | teammates detect each fork release |
| `2.3.0-wl.1` vs `2.2.2` | greater | a teammate on upstream's release moves to the fork build |
| `2.3.0-wl.9` vs `2.3.0` | lesser | when upstream ships `2.3.0`, teammates upgrade off the fork |
| `-wl.` prerelease | never published upstream | collision cannot happen |

Only `main` carries version bumps. Feature branches carry none. `main` is the branch teammates install from, so it is the only branch whose version has an audience. This also settles the ambiguity a content-addressed version could not answer: when the same tree exists as `751e4a9` and `2d57171`, a counter on the delivery branch has one obvious value where a SHA has two. It matches existing practice as well, since every prior bump commit landed on `main`.

The parent `han` plugin keeps upstream's version. Its `dependencies` array names children without version constraints, so the parent's version does not gate child updates and changing it would create divergence for no gain.

## Consequences

**Positive:**

- Teammates receive fork builds and later roll onto upstream releases without manual intervention.
- The version field holds a value matching its specification, so semver-aware tooling behaves predictably.
- Contributing a branch upstream means dropping the `-wl` suffix and letting maintainers choose the number. No other rework.
- Reading a version tells you both which upstream release it anticipates and that it came from this fork.

**Negative:**

- The counter is maintained by hand. Forgetting to increment publishes a version teammates already hold, and nothing detects that.
- Each bump requires classifying the change level first, which is a judgment call rather than a mechanical step.
- Moving off the existing SHA values is a one-time risk. `ffaa265` does not parse as semver, so comparison against it is undefined. Teammates should run `/plugin` once and reinstall rather than trusting an automatic upgrade across that boundary. This is being verified on the client machine on 2026-08-03.

**Neutral:**

- This ADR is specific to the fork and is not intended for upstream. It lives on `main`, which is the fork's integration branch. Feature branches based on `upstream/main` do not carry it.
- `.claude-plugin/marketplace.json` versions have drifted from `plugin.json` and are not what drives installs. Whether to resync them is a separate question this decision does not settle.

## Notes

Initial versions applied under this scheme:

| Plugin | Upstream baseline | Fork version | Level and reason |
|---|---|---|---|
| `han-core` | 3.2.0 | 3.3.0-wl.1 | minor, adds `references/code-smell-baseline.md` |
| `han-coding` | 3.4.0 | 3.5.0-wl.1 | minor, adds the same reference plus wiring into `code-review` and `refactor` |
| `han-github` | 2.3.2 | 2.4.0-wl.1 | minor, adds the `gh-gist-collaboration` skill, which upstream does not carry |

These baselines are upstream's `v5.5.0` versions. The fork rebased onto `v5.5.0`, so the bases moved and the `-wl` counter restarted at `1`.

Key files:

| File | Purpose |
|------|---------|
| `docs/semantic-versioning.md` | Upstream's level classification, which supplies the base version |
| `han-core/.claude-plugin/plugin.json` | Version field for `han-core` |
| `han-coding/.claude-plugin/plugin.json` | Version field for `han-coding` |
| `han-github/.claude-plugin/plugin.json` | Version field for `han-github` |
| `han/.claude-plugin/plugin.json` | Parent plugin, deliberately left at upstream's version |
| `.claude-plugin/marketplace.json` | Marketplace manifest, which does not drive installs |
| `.claude/skills/han-release/SKILL.md` | Upstream's release process, which assumes plain semver |

Related documentation:

- [Semantic Versioning for Plugins](../semantic-versioning.md), whose "One Bump Per Branch" rule still supplies the level classification even though its numbering is upstream's.
