# Code Smell Baseline

A fixed vocabulary of code smells, drawn from Martin Fowler's *Refactoring* (chapter 3), that applies even when a repository documents no conventions of its own. Its job is to give reviewers and refactorers a shared name for "this works, but it is going to hurt later," so a finding can say *what* is wrong instead of gesturing at it.

This baseline is the floor, not the ceiling. A project's own documented standards sit on top of it and win wherever the two disagree.

## The two rules that bind it

These rules matter more than the list. A smell vocabulary without them turns into a false-positive generator, which is worse than having no vocabulary at all.

### Rule 1: The repository overrides the baseline

A documented project standard always wins. Where a repository's `CONTRIBUTING.md`, coding standards, ADRs, or CLAUDE.md endorse a pattern this baseline would flag, suppress the smell entirely. Do not raise it "for awareness." The project made a decision, and re-litigating it in every review is noise.

The same applies to anything tooling already enforces. If a linter, formatter, type checker, or CI gate catches it mechanically, it is not a review finding.

### Rule 2: Every smell is a judgement call

A smell is a labelled heuristic, never a hard violation. Say "possible Feature Envy here" and let the author decide. Never write a finding that treats a smell as a rule breach.

Concretely, in skills that assign severity: a smell alone never justifies Critical. It earns Warning only when the change actively introduces or worsens it, and Suggestion otherwise. When you are unsure whether something is a smell, leave it out. A missed smell costs one review cycle; a confidently wrong smell costs the reviewer's credibility.

## The smells

Each entry reads as what it is, then how to fix it.

**Mysterious Name.** A function, variable, or type whose name does not reveal what it does or holds. Rename it. If no honest name comes to mind, that is the real finding: the design underneath is murky.

**Duplicated Code.** The same logic shape appears in more than one place. Extract the shared shape and call it from both. Be careful to distinguish structural duplication (worth extracting) from incidental duplication (two things that look alike today and will diverge tomorrow).

**Feature Envy.** A method that reaches into another object's data more than its own. Move the method onto the data it envies.

**Data Clumps.** The same few fields or parameters keep travelling together. That is a type asking to be born. Bundle them into one type and pass that instead.

**Primitive Obsession.** A primitive or string standing in for a domain concept that deserves its own type. Give the concept a small type of its own.

**Repeated Switches.** The same `switch` or `if` cascade on the same type recurs in several places. Replace it with polymorphism, or with one map that every site shares.

**Shotgun Surgery.** One logical change forces scattered edits across many files. Gather what changes together into one module.

**Divergent Change.** One file or module gets edited for several unrelated reasons. Split it so each module changes for one reason.

**Speculative Generality.** Abstraction, parameters, or hooks added for needs that do not exist yet. Delete it and inline back until a real need shows up. This project treats speculative generality under [`yagni-rule.md`](./yagni-rule.md), which carries the evidence test and the deferral format. Route it there rather than raising it twice.

**Message Chains.** Long `a.b().c().d()` navigation that the caller should not have to know about. Hide the walk behind one method on the first object.

**Middle Man.** A class or function that mostly just delegates onward. Cut it and call the real target directly.

**Refused Bequest.** A subclass or implementer that ignores or overrides most of what it inherits. Drop the inheritance and use composition.

## Overlap with han's analysis agents

Several of these smells are already the working vocabulary of agents this suite dispatches. Know which, so the same problem does not get reported twice under two names.

| Smell | Also raised by |
|---|---|
| Duplicated Code, Feature Envy, Shotgun Surgery, Divergent Change, Middle Man, Message Chains, Refused Bequest | `han-core:structural-analyst` |
| Speculative Generality | [`yagni-rule.md`](./yagni-rule.md), applied by every skill that gates inclusion |
| Mysterious Name, Primitive Obsession, Data Clumps, Repeated Switches | nothing else in the suite |

When a skill both applies this baseline manually and dispatches `han-core:structural-analyst`, the aggregation step deduplicates: if the agent already raised the finding with evidence, keep the agent's version and drop the manual one. The four smells in the last row are the ones the manual pass exists to catch.

## What this baseline is not

- **Not a refactoring mandate.** Naming a smell does not oblige anyone to fix it. It records a cost so the team can decide consciously.
- **Not a replacement for project standards.** Where the project documents a convention, read the convention. This list is what you use when it does not.
- **Not a static-analysis substitute.** If a tool can find it, let the tool find it.
