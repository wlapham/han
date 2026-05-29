# Extending Han with Plugin Dependencies

*Audience: anyone authoring a Claude Code plugin that builds on Han, whether you ship it inside the Han suite or in a marketplace of your own. Time to read: about ten minutes. Outcome: a working plugin that declares Han as a dependency, adds a skill on top of it, and loads cleanly.*

> See also: [Plugin landing page](../../../README.md) · [plugin.json reference](./plugin-json-options.md) · [marketplace.json reference](./marketplace-json-options.md) · [Choosing a Han plugin](../../choosing-a-han-plugin.md)

Claude Code plugins were not always able to build on each other. For a while, the only way to ship a related set of skills was to put them all in one plugin and hope nobody wanted a smaller slice. Plugin dependencies changed that: a plugin can now name the plugins it needs, and Claude Code installs and enables them for you when your plugin goes in. That is the mechanism Han itself uses to split into three plugins, and it is the same mechanism you use to extend Han from a plugin of your own.

This guide shows you how to do that. First it walks through how the dependency mechanism works and how Han already uses it, so you have a working model to copy. Then it splits into two paths: one for adding a plugin inside the Han suite, and one for building your own plugin in a separate marketplace that depends on Han. Pick the path that matches where your plugin lives.

## How a dependency works

You declare dependencies in a `dependencies` array in your plugin's `.claude-plugin/plugin.json`. Each entry is either a plain plugin name or an object that pins a version and, when the dependency lives elsewhere, names its marketplace:

    "dependencies": [
      "han.core",
      { "name": "some-plugin", "version": "~2.1.0" }
    ]

A plain name floats to whatever version the marketplace currently provides. An object with a `version` field constrains the resolution to a semver range. The [plugin.json reference](./plugin-json-options.md#dependencies) covers the field shape, and the canonical Claude Code documentation at [code.claude.com/docs/en/plugin-dependencies](https://code.claude.com/docs/en/plugin-dependencies) is the source of truth for how resolution, versioning, and cross-marketplace trust behave. The behavior that matters for extending Han is short:

- **Install pulls dependencies in.** When someone installs your plugin, Claude Code resolves each dependency, installs it, and tells you what it added. Your reader runs one install command and gets your plugin plus everything it depends on.
- **Enabling is transitive.** Enabling your plugin enables its dependencies at the same scope. Disabling is the reverse: Claude Code refuses to disable a plugin while another enabled plugin still depends on it, and it prints the command to disable them together.
- **Cross-marketplace dependencies need permission.** A dependency in a different marketplace from your plugin is refused unless the marketplace your reader is installing from explicitly allows that other marketplace. This is the one rule that separates the two paths below, so hold on to it.

## How Han uses it

Han is its own worked example. It ships as three plugins in one marketplace, wired together with exactly the `dependencies` array above.

`han.core` is the base layer. It carries the planning, investigation, review, and documentation skills, plus every agent those skills dispatch, and it depends on nothing:

    {
      "name": "han.core",
      "version": "1.0.0"
    }

`han.github` is a layer on top of core. It adds the GitHub-facing skills (`gh-pr-review`, `update-pr-description`, `work-items-to-issues`), and several of them build directly on core skills. The `gh-pr-review` skill, for example, runs core's `/code-review` and then posts the result to a pull request. Because it cannot do its job without core, it declares core as a dependency:

    {
      "name": "han.github",
      "version": "1.0.0",
      "dependencies": [
        "han.core"
      ]
    }

`han` is a meta-plugin. It has no skills or agents of its own. Its entire job is to pull in the other two so that one install command gives you the whole suite:

    {
      "name": "han",
      "version": "3.0.0",
      "dependencies": [
        "han.core",
        "han.github"
      ]
    }

A plugin with no components and nothing but a `dependencies` array is a pattern worth naming, because it is how you bundle a set of plugins under a single install. The canonical docs describe what install does with dependencies but do not name this zero-component "meta-plugin" shape on its own, so treat it as observed practice that Han relies on rather than a documented construct, and check the [canonical docs](https://code.claude.com/docs/en/plugin-dependencies) if install behavior ever surprises you.

All three plugins are listed in one `marketplace.json`, each with a relative `source` path:

    {
      "name": "han",
      "plugins": [
        { "name": "han",        "source": "./han",        "version": "3.0.0" },
        { "name": "han.core",   "source": "./han.core",   "version": "1.0.0" },
        { "name": "han.github", "source": "./han.github", "version": "1.0.0" }
      ]
    }

Notice the topology that falls out of this: `han` depends on `han.core` and `han.github`; `han.github` depends on `han.core`; `han.core` depends on nothing. That is the shape you are about to copy. Where you copy it to is the only thing that changes.

## Path 1: Add a plugin inside the Han suite

Take this path when your plugin lives in the Han repository and ships from the Han marketplace, the way `han.github` does. Because your plugin and `han.core` are in the same marketplace, the cross-marketplace rule never comes up, and a plain dependency name is all you need.

First, create the plugin directory and its manifest. Name the dependency with a plain string, since core is a sibling in the same marketplace:

    {
      "name": "han.example",
      "version": "1.0.0",
      "description": "Example extension that builds on han.core.",
      "dependencies": [
        "han.core"
      ]
    }

Second, add the skill (or agent) that does the new work. Put it where Claude Code scans by default, at `han.example/skills/<name>/SKILL.md`. This is the skill that builds on core: it can dispatch a `han.core` agent, call a core skill as a step, or read a core reference file, because installing your plugin guarantees core is present and enabled alongside it.

Third, register the plugin in the marketplace so a reader can install it. Add an entry to `.claude-plugin/marketplace.json` with a relative source path, next to the three that are already there:

    { "name": "han.example", "source": "./han.example", "version": "1.0.0" }

Lastly, if you want the full `han` suite to carry your plugin, add its name to the `han` meta-plugin's `dependencies` array. That is the one edit that makes `han.example` part of what `/plugin install han@han` delivers. Leave it out and your plugin is installable on its own but is not bundled into the suite, which is the right choice when it is optional.

A reader installs your plugin with `/plugin install han.example@han`, and Claude Code pulls `han.core` along automatically.

## Path 2: Build your own plugin that depends on Han

Take this path when your plugin ships from a marketplace you own, separate from Han's, and you want it to build on `han.core`. Everything from Path 1 applies, with one addition: because your plugin and `han.core` now live in different marketplaces, the cross-marketplace rule from earlier comes into play, and you have three extra things to get right.

First, declare the dependency as an object that names Han's marketplace, not a plain string. Han's marketplace is named `han`, so:

    {
      "name": "acme-han-extras",
      "version": "1.0.0",
      "description": "Acme's extensions built on han.core.",
      "dependencies": [
        { "name": "han.core", "marketplace": "han" }
      ]
    }

Second, allow the cross-marketplace dependency from your own marketplace. Claude Code refuses to reach into another marketplace unless the marketplace your reader is installing from grants permission. Since your reader installs from your marketplace, the permission goes there: add an `allowCrossMarketplaceDependenciesOn` array to your `marketplace.json` that names Han's marketplace.

    {
      "name": "acme",
      "allowCrossMarketplaceDependenciesOn": ["han"],
      "plugins": [
        { "name": "acme-han-extras", "source": "./acme-han-extras", "version": "1.0.0" }
      ]
    }

Third, tell your reader to add the Han marketplace before installing. Claude Code will not add a marketplace on its own to satisfy a dependency, so a dependency from a marketplace your reader has never added stays unresolved. The install sequence for your reader becomes:

    /plugin marketplace add testdouble/han
    /plugin marketplace add acme/your-marketplace-repo
    /plugin install acme-han-extras@acme

With those three pieces in place, installing your plugin resolves `han.core` from the Han marketplace and installs it alongside your own.

A word on scope before you commit to this path: Han is built and maintained for the Han suite's own plugins. Extending it from an outside marketplace works through the standard Claude Code mechanism described here, but Han does not publish a stability contract for outside dependents, so pin a `version` range on the dependency and re-check it when you upgrade.

## Confirm it works

You are done when a clean install of your plugin loads both your plugin and the Han plugin it depends on. Check it the way your reader will:

1. From a fresh state, run the install command for your plugin.
2. Read the install output. Claude Code lists what it added, including the dependency it pulled in. Confirm `han.core` is in that list.
3. Run your new skill and confirm the core behavior it builds on is available. If your skill dispatches a `han.core` agent or calls a core skill, exercise that path, not the parts that are yours alone.
4. Disable your plugin and confirm Claude Code enables and disables the dependency along with it, rather than leaving an orphan behind.

If the dependency does not show up in the install output, the most common causes are a misspelled dependency name, a missing marketplace registration, or (on Path 2) a missing `allowCrossMarketplaceDependenciesOn` entry or a marketplace your reader has not added.

## What this guide does not cover

This guide is about extending Han through the dependency mechanism. It is not the place to learn how to write a skill or an agent from scratch; for that, see the skill-building and agent-building guidance. It also does not cover which Han plugin to install as an end user, since [Choosing a Han plugin](../../choosing-a-han-plugin.md) already does. The full set of resolution, versioning, and error-handling behaviors lives in the [canonical Claude Code documentation](https://code.claude.com/docs/en/plugin-dependencies); this guide stays with the parts you need to extend Han and links out for the rest.

## Related Documentation

- [Plugin landing page](../../../README.md). Where the Han suite starts, and where the install commands live.
- [plugin.json reference](./plugin-json-options.md). The full manifest schema, including the [`dependencies`](./plugin-json-options.md#dependencies) field used throughout this guide.
- [marketplace.json reference](./marketplace-json-options.md). The marketplace schema, including cross-marketplace settings.
- [Choosing a Han plugin](../../choosing-a-han-plugin.md). The end-user view of the same three-plugin split, for deciding which one to install.
- [Claude Code: plugin dependencies](https://code.claude.com/docs/en/plugin-dependencies). The canonical reference for resolution, versioning, and cross-marketplace trust.
