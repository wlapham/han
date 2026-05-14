# Screenshot embed rules

When the plan folder contains a `ui-designs/` subfolder with screenshot files (typically produced by the `ui-design-from-feature-spec` skill), every UI-bearing slice MUST embed the relevant screenshots **inline in the issue body** — not as plain links.

## Why cross-repo URLs are forbidden

The automated implementation tooling (Ralph) runs against the **target code repo** and cannot resolve URLs that point into a different repository. An issue body with cross-repo image URLs renders blank in that environment, and the implementer can't see the design.

Solution: **copy each PNG into the target repo first**, then embed it via a same-repo URL.

## Required URL form

```
https://github.com/<organization>/<target-repo>/raw/<branch>/.github/issue-assets/<SYM-N>/<file>.png
```

- `<organization>` is the GitHub organization that contains the code repo, usually a username or business name (e.g., `testdouble`).
- `<target-repo>` is the code repo the issue is being created in (e.g., `han`).
- `<branch>` is the target repo's default branch, fetched at upload time via `gh repo view <organization>/<repo> --json defaultBranchRef --jq .defaultBranchRef.name` (typically `main`).
- `<SYM-N>` is the slice's symbolic ID (e.g., `W-3`).
- `<file>.png` matches the source filename in `<plan-folder>/ui-designs/<file>.png`.

## Embed format inside the issue body

Wrap each embed in a link to the same URL so readers can open the full-size image in a new tab:

```
- *<state-or-scenario name>* — [![<alt text>](<URL>)](<URL>)
```

One image per bullet, with a short caption naming the depicted state.

## Mapping screenshots to slices

Map screenshots to slices via the feature spec's own embeds: the section in the spec that describes the behavior a slice implements is where the canonical screenshot for that slice is referenced.

## Duplication over sharing

When a screenshot applies to multiple slices, copy it once **per slice** so each `<SYM-N>` folder is self-contained. The upload script handles this automatically — every URL it sees in the work-items file produces an upload, even if the source file is shared.

## What never to do

- Never embed any cross-repo URL in an issue body.
- Never use a shared `.github/issue-assets/shared/` path. Each slice owns its own folder.
- Never link to a screenshot without embedding the image — implementers should see the design without clicking out.
