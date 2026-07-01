# Feature Specification: Human-Readable Output Standard

A shared, evolvable readability standard that every reader-facing Han skill applies while it writes, so that skill output leads with the main point, uses plain language, and reveals detail in layers — consistently across skills rather than restated skill-by-skill.

## Outcome

When an operator runs any reader-facing Han skill, the human-facing deliverable it produces can be found, understood, and used by a smart non-expert who has not seen the code: the main point comes first, each paragraph carries one idea, sentences are short and active, common words beat jargon, and complexity is revealed progressively. The output reads consistently across skills because every reader-facing skill applies **one shared readability rule** as it writes, the same way skills already apply the shared YAGNI and evidence rules ([D1](artifacts/decision-log.md#d1-standard-shape-shared-rule-file-on-the-yagnievidence-model)). A contributor who adds or evolves a reader-facing skill has one source of truth to cite and one place to change the rules, instead of re-deriving plain-language guidance per skill.

## Actors and Triggers

- **Actors:**
  - **The operator** — runs a reader-facing skill and reads the deliverable it produces. The primary beneficiary; experiences more readable, more consistent output.
  - **The skill author / contributor** — wires the standard into a reader-facing skill, and evolves the shared rule over time.
- **Triggers:**
  - A reader-facing skill runs and begins producing its human-facing deliverable.
  - A contributor adds a new reader-facing skill, or edits the shared readability rule.
- **Preconditions:**
  - The shared readability rule exists and is available to the running skill's plugin (present in that plugin's references, the same way the YAGNI and evidence rules are) ([D9](artifacts/decision-log.md#d9-vendoring-manual-byte-identical-copies-into-plugins-shipping-in-scope-skills)).

## Primary Flow

The reader-facing skills in scope are **research**, **stakeholder-summary**, **code-overview**, **investigate**, **update-pr-description**, **html-summary**, **gap-analysis**, and **project-documentation** ([D3](artifacts/decision-log.md#d3-skill-scope-all-reader-facing-prose-skills)). When one of them produces its deliverable:

1. The skill loads the shared readability rule as part of producing its human-facing output, the same way it already loads the YAGNI and evidence rules.
2. The skill applies an always-on audience frame while drafting: write for a smart non-expert who has not seen the code ([D10](artifacts/decision-log.md#d10-always-on-audience-frame)).
3. The skill drafts the deliverable into an output template that already carries the standard's structural rules: the main point first, descriptive front-loaded headings, one idea per paragraph with the first sentence carrying the weight, numbered lists for steps and bullets for non-sequential items, and detail revealed progressively ([D2](artifacts/decision-log.md#d2-layered-enforcement-applied-one-layer-at-a-time)).
4. The skill runs a standardized plain-language self-check against the rule before finishing, using concrete yes/no criteria anchored to observable properties of the text rather than a subjective "is this clear?" judgment ([D11](artifacts/decision-log.md#d11-self-check-uses-behaviorally-anchored-yesno-criteria)). Anything the self-check fails is corrected before the deliverable is presented.
5. The skill presents the finished deliverable.

The rule is never applied as one large block of instructions. Each layer has a distinct home — structural rules in the template, do/don't pairs handed to the model as examples, testable checks run as an after-the-fact self-check — and the skill applies one layer at a time ([D2](artifacts/decision-log.md#d2-layered-enforcement-applied-one-layer-at-a-time)).

## Alternate Flows and States

### Synthesis skills run a dedicated readability rewrite pass

- **Entry condition:** The running skill already has a synthesis or editor step in its flow. This is true for **code-overview**, **stakeholder-summary**, and **research** ([D5](artifacts/decision-log.md#d5-rewrite-pass-only-where-a-synthesis-step-already-exists)).
- **Sequence:** After the draft is written (Primary Flow step 3) and before the self-check (step 4), the skill runs a dedicated pass that rewrites the draft for readability while preserving every fact. This pass is performed by a dedicated readability-editor reviewer that audits and rewrites the draft against a small, behaviorally-anchored rubric ([D4](artifacts/decision-log.md#d4-a-new-dedicated-readability-editor-reviewer)). Any imperative or conditional content carried in from the skill's own source material is clearly delimited so the rewrite does not mistake input prose for instructions.
- **Exit:** The rewritten draft, with every fact preserved, continues to the self-check and is presented.

### Non-synthesis skills apply the rule inline only

- **Entry condition:** The running skill has no synthesis or editor step. This is true for **investigate**, **update-pr-description**, **html-summary**, **gap-analysis**, and **project-documentation**.
- **Sequence:** The skill applies the template, audience frame, and self-check (Primary Flow) but does not run a separate rewrite pass. No dedicated readability reviewer is dispatched.
- **Exit:** The deliverable is presented after the self-check.

### A contributor adds a new reader-facing skill

- **Entry condition:** A contributor is authoring a new skill whose primary output is human-facing prose.
- **Sequence:** The contributor embeds the structural rules in the skill's output template, has the skill load and apply the shared readability rule, and adds the standardized self-check. If the new skill has a synthesis or editor step, the contributor also wires the dedicated readability rewrite pass.
- **Exit:** The new skill produces output under the standard with no per-skill re-statement of the rules.

### The shared rule evolves

- **Entry condition:** A contributor changes the readability rule.
- **Sequence:** The contributor edits the canonical copy, then copies it byte-for-byte into every plugin that ships an in-scope skill ([D9](artifacts/decision-log.md#d9-vendoring-manual-byte-identical-copies-into-plugins-shipping-in-scope-skills)). The operator-facing summary is updated to match.
- **Exit:** Every in-scope skill applies the updated rule on its next run.

## Edge Cases and Failure Modes

| Condition | Required Behavior |
|-----------|-------------------|
| The deliverable is inherently technical (e.g., investigate's root-cause finding). | The standard governs *how* the content is said — lead with the answer, plain framing, progressive disclosure — not whether necessary technical facts appear. No required technical fact is removed to satisfy the standard. |
| The readability pass would drop a fact to read more simply. | Fidelity wins. Every fact in the draft is preserved through the rewrite and self-check; over-simplifying dense content to read "cleaner" is a failure, not a success ([D5](artifacts/decision-log.md#d5-rewrite-pass-only-where-a-synthesis-step-already-exists)). |
| The rule is large enough that applying it all at once would degrade compliance. | The rule is applied one layer at a time (template, then examples, then self-check), never as a single stacked instruction block ([D2](artifacts/decision-log.md#d2-layered-enforcement-applied-one-layer-at-a-time)). |
| The self-check is asked to judge subjective clarity. | The self-check evaluates concrete, behaviorally-anchored yes/no criteria (does the first line state the main point? does any sentence exceed the length guidance? is any blocklisted word present?), not "is this clear?" ([D11](artifacts/decision-log.md#d11-self-check-uses-behaviorally-anchored-yesno-criteria)). |
| Source material the rewrite pass reads contains imperative or conditional prose. | That content is delimited so the rewrite treats it as text to preserve, not as instructions to follow. |
| A vendored copy of the rule diverges from the canonical copy. | The copies must be byte-identical; any divergence is a defect, the same discipline the YAGNI and evidence rule copies already hold ([D9](artifacts/decision-log.md#d9-vendoring-manual-byte-identical-copies-into-plugins-shipping-in-scope-skills)). |
| A skill loads the rule but its other instructions crowd it out. | Loading does not guarantee compliance; the template, examples, and self-check layers are what make the rule take effect, not loading alone ([D1](artifacts/decision-log.md#d1-standard-shape-shared-rule-file-on-the-yagnievidence-model)). |

## Coordinations

| Coordinating System | Direction | Interaction | Ordering / Consistency Requirement |
|---------------------|-----------|-------------|-----------------------------------|
| Shared readability rule | inbound | Each reader-facing skill loads and applies the rule as it produces output. | The rule must be present in the skill's plugin before the skill runs. |
| Vocabulary blocklist (the existing writing-voice profile) | outbound | The readability rule points skills at the existing blocklist for word-level rules instead of duplicating them ([D6](artifacts/decision-log.md#d6-reuse-the-existing-vocabulary-blocklist-for-word-level-rules)). | The blocklist becomes relevant to skill output at runtime for the first time; it continues to govern operator documentation unchanged. |
| Dedicated readability-editor reviewer | outbound | Synthesis skills dispatch the reviewer for the rewrite pass ([D4](artifacts/decision-log.md#d4-a-new-dedicated-readability-editor-reviewer)). | Runs after the draft exists and before the self-check. |
| Canonical rule copy and its per-plugin copies | outbound | The canonical copy is duplicated byte-for-byte into each plugin that ships an in-scope skill ([D9](artifacts/decision-log.md#d9-vendoring-manual-byte-identical-copies-into-plugins-shipping-in-scope-skills)). | All copies stay byte-identical; a rule change re-copies to every shipping plugin. |
| Operator-facing summary and the concepts index | outbound | A plain-language summary of the rule sits alongside the existing YAGNI and evidence summaries and is listed in the same index of foundational mechanics ([D12](artifacts/decision-log.md#d12-operator-facing-summary-and-concepts-index-entry)). | The summary mirrors the structure of the existing summaries and is updated when the rule changes. |

## Out of Scope

- **CI or prose-linting enforcement over produced output.** Reader-facing skill output is ephemeral conversational or scratch text, not committed files in a pipeline, so there is no build surface to lint ([D8](artifacts/decision-log.md#d8-readability-formulas-and-linting-are-not-the-enforcement-mechanism)).
- **Controlled-language systems** (a fixed approved-word list with hard length caps). High authoring cost, stilted output unfit for analytical deliverables, and cannot be auto-applied to existing prose.
- **A readability-formula score as the standard's target or spine.** Formulas are weak comprehension proxies that reward gaming; they are not the measure the standard optimizes ([D8](artifacts/decision-log.md#d8-readability-formulas-and-linting-are-not-the-enforcement-mechanism)).
- **Changing the operator-documentation voice profile.** The existing voice profile continues to govern operator docs; this feature reuses its blocklist but does not rewrite it.
- **Skills whose primary output is not human-facing prose** — specification, plan, work-item, and coding-standard skills, and code-writing skills. They are not reader-facing prose deliverables and are not wired in this feature.

## Deferred (YAGNI)

### Readability-formula diagnostic (Flesch / grade level) as an optional one-glance check

- **Why deferred:** Fails the evidence test. No operator has asked for a numeric readability diagnostic, and the formulas are documented as poor comprehension proxies; including one now would be speculative machinery.
- **Reopen when:** An operator asks for a rough numeric diagnostic, or a measured case shows the qualitative self-check is missing a class of unreadable output a formula would catch.
- **Source:** Research report option O6; conversation.

### Automated sync of the vendored rule copies

- **Why deferred:** Simpler-version test. Manual byte-for-byte copying matches how the YAGNI and evidence rules are already vendored; a build-step sync is more machinery than the current pattern needs.
- **Reopen when:** A vendored copy is observed to have drifted from the canonical copy in practice.
- **Source:** Simpler-version test against the existing vendoring pattern.

## Open Items

<!-- Populated by the project-manager during synthesis. -->

## Summary

- **Outcome delivered:** Every reader-facing Han skill produces output a smart non-expert can find, understand, and use, by applying one shared readability rule as it writes.
- **Primary actors:** The operator who reads skill output; the contributor who wires and evolves the standard.
- **Decisions settled by evidence:** 10 — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Decisions settled by user input:** 4 — see [artifacts/decision-log.md](artifacts/decision-log.md)
- **Sub-agents consulted:** (pending review) — see [artifacts/team-findings.md](artifacts/team-findings.md)
- **Key adjustments from review:** (pending review) — see [artifacts/team-findings.md](artifacts/team-findings.md)
- **Remaining open items:** 0 (pending review)
</content>
</invoke>
