# Context File Template

The creator writes this to `tmp/features/<project-name>/.context.md` so Claude
knows how the shared directory is meant to be used. It syncs to the Gist with
everything else, so teammates get the same conventions.

Substitute before writing:

- `<PROJECT_NAME>` — the directory name, e.g. `topaz-fit`.
- `<REFERENCE_LINK>` — the Linear project or GitHub URL if the user gave one.
  Drop the whole line when they didn't.

Keep the placeholder prompts in place when the user has nothing specific to say
yet. They tell whoever opens the directory next what belongs in each section.

---

# <PROJECT_NAME>

Reference: <REFERENCE_LINK>

Shared via GitHub Gist. Files here sync to everyone working on this project.

## What lives here

Describe what belongs in this directory, and what belongs elsewhere in the
project instead.

## Conventions

Describe how files here are named, which skills read and write them, and
anything a teammate should do before adding to the directory.

## Notes

Gists are flat, so subdirectories cannot be shared. Keep everything at the top
level of this directory. To share a file that would otherwise live in a
subdirectory, flatten it to the gist root using the directory name as an
underscore-prefix:

- `artifacts/implementation-decision-log.md` → `artifacts_implementation-decision-log.md`
- `artifacts/.discovery-notes.md` → `.artifacts_discovery-notes.md`
