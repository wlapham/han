# Investigation: gap-analysis skill — friction surfaced by feedback issue #34

Four "what didn't work" items in [issue #34](https://github.com/testdouble/han/issues/34) trace to four specific places where the `gap-analysis` skill pushes responsibility onto the brief, the analyzer, or a fixed report shape instead of owning it at the synthesis layer; this plan fixes each at its source.

## Problem Statement

- **Symptoms.** Issue #34 is structured feedback from a real `han:gap-analysis` run (the `proposal-roi` skill compared against a `proposals/CLAUDE.md` spec, 13 gaps). The run worked well on analysis quality (5/5, zero false positives), but four frictions were called out under "What didn't work":
  1. **V7 spec-provenance noise.** The validator flagged that the desired-state spec was an uncommitted, same-session artifact and that the analysis was therefore "circular." Technically correct, but this is *always* true when you run a gap analysis against a spec you just wrote — a common, legitimate use case. Surfacing it as a high-confidence validator finding made a workflow reminder feel like a problem.
  2. **Second-round ceremony.** Trigger A (≥ 3 proposed new gaps) fired, so the protocol-required second `gap-analyzer` round ran. It only re-confirmed what the swarm had already described thoroughly. At this gap count and specificity, the second round was ceremony.
  3. **Actor sweep depended on brief quality.** The two actors that produced the highest-value gaps (interactive Mike in full-discovery mode vs. the swag batch runner) were not obvious from the skill file alone. The operator had to name them explicitly in the brief. The skill did not discover the actors itself, so G-011/G-012 quality was a function of brief quality.
  4. **No "top N that block the goal" shortcut.** 13 gaps is a long document. There is no way to ask for "the top 5 that block the redesign" — the output format has no purpose-conditioned prioritized view.
- **Expected behavior.** Workflow reminders read as reminders, not high-confidence gap contradictions. The second analyzer round runs only when it would add information. The skill seeds the actor sweep from the desired-state artifact so quality does not depend on brief wording. The report offers a short, purpose-conditioned "blocking subset" when the operator stated why they are comparing.
- **Conditions.** Surfaces on any medium/large gap-analysis run, most sharply when (a) the desired-state spec is a same-session operator artifact, (b) the swarm proposes ≥ 3 well-specified new gaps, (c) the artifacts imply more than one actor or mode, and (d) the operator stated a purpose for the comparison.
- **Impact.** Signal-to-noise of the validation section (rated 3/5 in the issue), wasted wall-clock on a non-additive second round, brief-quality dependence for the single highest-value part of the analysis, and output-length friction (rated 3/5). None of these are correctness bugs; all are friction that lowers the skill's usefulness as a redesign brief.

## Evidence Summary

### E1: The validator brief gives no class for provenance / same-session-artifact observations

- **Source:** `han.core/skills/gap-analysis/SKILL.md` (Step 5, Validator brief) and `han.core/agents/adversarial-validator.md` (Validation Strategy 4)
- **Finding:**
  ```
  # SKILL.md Step 5 — Validator brief:
  - **Validator** (`adversarial-validator`) — "For each gap below, attempt to
    disprove it. Cite counter-evidence. Return a per-gap verdict: `confirmed`,
    `contradicted`, or `inconclusive`, with reasoning."

  # adversarial-validator.md — Strategy 4 (always applies to gathered evidence):
  - Probe source provenance and recency: is a source stale, astroturfed, an
    interested party, or implausibly convenient for the conclusion
  ```
- **Relevance:** Strategy 4 is correct and generic — the validator is *supposed* to question provenance. The friction is that the gap-analysis skill gives the validator only three verdicts (`confirmed` / `contradicted` / `inconclusive`), all of which are gap-validity verdicts. A provenance observation about a same-session operator spec has nowhere to go except into one of those buckets, so it lands as a per-gap contradiction or a high-confidence finding. The skill never tells the validator that "the operator's own uncommitted spec is the desired state" is a workflow note, not a gap contradiction.

### E2: Section 4 of the report has no channel for process/workflow notes

- **Source:** `han.core/skills/gap-analysis/references/gap-analysis-report-template.md` (Section 4) and `SKILL.md` (Step 6, render rule 7)
- **Finding:**
  ```
  # Template Section 4 has exactly three signal groups + a confidence table:
  ### Confirmations   ### Contradictions   ### Augmentations   ### Confidence summary

  # SKILL.md render rule 7:
  Group entries into Confirmations, Contradictions, and Augmentations using the
  swarm agents' verbatim verdicts.
  ```
- **Relevance:** Even if the validator wanted to label V7 a workflow note, the report has no place to render it. Confirmations/Contradictions/Augmentations are all about gap validity; the confidence table is per-gap. A workflow reminder gets forced into "Contradictions" (reads as a real disagreement) or inflates the confidence noise. This is the rendering half of E1.

### E3: The second-round trigger keys on a raw count, with no escape when the delta is already covered

- **Source:** `han.core/skills/gap-analysis/SKILL.md` (Step 5.5, Conditional Second Round)
- **Finding:**
  ```
  - **Trigger A:** the swarm returned ≥ 3 `proposed_new_gap` entries.
  - **Trigger B:** the swarm returned contradictions on ≥ 20% of the analyzer's
    original gaps.
  ...
  1. Re-dispatch `gap-analyzer` with the new findings ... Return only the delta:
     new gaps the first pass missed ...
  ```
- **Relevance:** Trigger A fires on the *count* of proposed new gaps, not on whether a re-scan would add anything. When the swarm has already specified each new gap with evidence and ≥ 2 agents confirmed it, the re-dispatch can only re-confirm — exactly the ceremony the issue describes. There is no escape clause permitting the skill to skip the round when the delta is already fully characterized.

### E4: Actor enumeration is delegated to the junior-developer brief; the skill never derives actors from the artifact

- **Source:** `han.core/skills/gap-analysis/SKILL.md` (Step 1, Step 5 junior-developer brief) and the Operating Principles bullet on the actor sweep
- **Finding:**
  ```
  # Step 5 junior-developer brief:
  "... Enumerate every actor type the desired state addresses or implies —
  human end users (and sub-roles ...), API callers, AI agents, integration
  partners, batch processes, internal services. ..."

  # Step 1 identifies the two artifacts and the comparison direction only —
  # it does NOT read the desired state for actor/mode signals or pass a
  # candidate actor list into any brief.
  ```
- **Relevance:** The skill tells junior-developer to enumerate actors but never does any enumeration itself, so the quality of the sweep depends on whatever actors the operator happened to name in the brief. The two highest-value gaps (G-011, G-012) came from the swag *batch runner* actor, which is not obvious from the skill file. Nothing in Steps 1–4 reads the desired-state artifact for actor or mode signals and seeds the brief with them.

### E5: There is no purpose-conditioned prioritized view, and prioritization is (correctly) forbidden in the analyzer

- **Source:** `han.core/agents/gap-analyzer.md` (Rules), `han.core/skills/gap-analysis/SKILL.md` (Step 1, Step 6), `gap-analysis-report-template.md` (Section 1)
- **Finding:**
  ```
  # gap-analyzer.md Rules:
  - No prioritization, no impact assessment. Produce an unprioritized gap list.

  # Template Section 1 executive summary: magnitude table (counts by category)
  # + "shape of the gap" themes. No prioritized / blocking subset.

  # SKILL.md Step 1 captures the two artifacts and direction, but never
  # captures WHY the operator is comparing (the purpose/goal).
  ```
- **Relevance:** The analyzer is deliberately neutral — it must not prioritize. So a "top N that block X" view cannot come from the analyzer; it has to be a skill-level synthesis judgment conditioned on the operator's stated purpose. But Step 1 never captures the purpose, and the template has no slot for the view, so there is nowhere for the shortcut to live. The issue's own context ("before a redesign pass") is exactly the kind of purpose that would drive it.

## Root Cause Analysis

### Summary

In four places the skill delegates a synthesis responsibility (classifying process observations, deciding whether re-analysis adds value, discovering actors, prioritizing against a goal) to a downstream brief, the neutral analyzer, or a fixed report shape, instead of owning it at the skill's synthesis layer — so each responsibility is only met when an upstream input happens to carry it.

### Detailed Analysis

The skill is well-factored for its primary job: the analyzer owns neutral gap classification (E5), and the swarm owns adversarial validation and the actor sweep. The four frictions all sit at the seam where the *skill* is supposed to add judgment on top of those neutral inputs, and in each case the seam is missing:

- **V7 noise (E1, E2)** is a missing taxonomy plus a missing render channel. The validator is correctly probing provenance (Strategy 4), but the skill collapses every validator output into three gap-validity verdicts and renders only Confirmations/Contradictions/Augmentations. A workflow observation — "your desired-state spec is your own uncommitted same-session file" — has no class and no place, so it masquerades as a high-confidence gap contradiction. The fix is to give it a class in the brief (E1) and a channel in the report (E2).

- **Second-round ceremony (E3)** is a gate that keys on the wrong signal. Trigger A asks "were there ≥ 3 new gaps?" when the question that determines whether the round adds value is "would re-analysis tell us anything the swarm hasn't already established?" When each proposed gap is already specified and corroborated, the answer is no, and the round is ceremony.

- **Actor-sweep brief-dependence (E4)** is a responsibility delegated without a seed. The skill asks junior-developer to enumerate actors but never reads the desired-state artifact for actor/mode signals itself, so a non-obvious actor (the batch runner) only enters the sweep if the operator names it. Actor discovery from the artifact is a skill responsibility that is currently unowned.

- **No blocking subset (E5)** is a synthesis judgment with no input and no output slot. Prioritization cannot live in the analyzer (it is correctly forbidden), so it must be a skill-level view conditioned on the operator's purpose — but the skill never captures the purpose and the template has no slot for the view.

The common thread: these are not analyzer or agent defects. They are gaps in the skill's own synthesis layer. Every fix below lands in `SKILL.md` and the report template; the `gap-analyzer` agent stays neutral and unchanged, and the `adversarial-validator` and `junior-developer` agents keep their generic behavior — the skill just briefs and renders them better.

## Coding Standards Reference

| Standard | Source | Applies To |
|----------|--------|------------|
| Voice profile: no em-dashes, direct second person, plainspoken mentor tone, no hype | `docs/writing-voice.md` (referenced from `CLAUDE.md`) | All prose added to `SKILL.md` and the template |
| YAGNI / evidence rule: do not add speculative sections; every addition needs evidence | `CLAUDE.md` ("YAGNI applies to docs too"), `han.core/references/evidence-rule.md` | Every new step, trigger clause, and template slot below — each must trace to an E-item |
| Skill authoring: progressive disclosure, context hygiene, deterministic flowchartable steps | `docs/guidance/skill-building-guidance/`, `docs/guidance/plugin-entity-taxonomy.md` | New Step 1.5, Step 5.5 escape clause, Step 6 render rules |
| Analyzer stays neutral: no prioritization, no impact assessment | `han.core/agents/gap-analyzer.md` (Rules) | Fix 4 must keep prioritization in the skill, never push it into the analyzer |
| One canonical source per concept; long-form doc is canonical | `CLAUDE.md` (Conventions) | `docs/skills/gap-analysis.md` must be updated to match every behavior change below |

## Planned Fix

### Summary

Add the four missing synthesis responsibilities to `SKILL.md` and the report template — a workflow-note class and render channel, a second-round escape clause, a skill-owned actor-enumeration step, and a purpose-conditioned blocking-subset view — while leaving the `gap-analyzer` agent neutral and the swarm agents generic.

### Changes

#### `han.core/skills/gap-analysis/SKILL.md`

- **Change (Fix 1 — workflow-note class for the validator):** In Step 5's validator brief, add a clause: provenance and process observations that do not bear on whether a gap is real — for example, "the desired-state artifact is the operator's own uncommitted, same-session file" — are returned as a `workflow_note`, not as a per-gap `contradicted`/`inconclusive` verdict. Keep the corroboration/provenance scrutiny for *external or third-party* desired-state sources as a real verdict (those can genuinely invalidate a gap). Add one Operating-Principles line stating that workflow notes are surfaced as reminders and never feed per-gap confidence.
- **Evidence:** (E1), (E2)
- **Standards:** Analyzer-neutral (untouched); writing voice; YAGNI (the carve-out for external sources prevents over-suppression).
- **Details:** New verdict token `workflow_note` added only to the validator brief. Confidence derivation in Step 6 render rule 3 explicitly ignores `workflow_note` items so they cannot lower or raise any gap's confidence.

- **Change (Fix 2 — second-round escape clause):** In Step 5.5, after the Trigger A/B definitions, add: before re-dispatching the analyzer, check whether the proposed new gaps are already fully characterized — each has an evidence pair and ≥ 2 swarm agents confirmed it. If every proposed new gap meets that bar, **skip** the second round and record the skip reason ("second round skipped: all N proposed gaps already specified and corroborated by the swarm; re-analysis would only re-confirm"). Reframe the round's purpose so it runs only when the proposed gaps are under-specified, contested, or point to a *systematic* actor/behavior-class the first pass excluded — not on raw count alone.
- **Evidence:** (E3)
- **Standards:** Deterministic/flowchartable (the escape is a concrete, checkable condition); YAGNI (keeps the round for the case it was built for, drops it for the ceremony case).
- **Details:** Trigger A stays as the *entry* condition, but gains an exit gate. The in-channel summary (Step 7) reports "second round skipped (reason)" in addition to the existing "second round ran (trigger/changes)".

- **Change (Fix 3 — skill-owned actor enumeration):** Add **Step 1.5: Enumerate candidate actors.** After inputs are resolved, the skill reads the desired-state artifact for actor and mode signals — named roles, sub-roles, interaction modes (interactive vs. batch/automated), API/agent/integration surfaces — and produces a candidate actor list. In Step 5, the junior-developer brief is seeded with that list ("candidate actors derived from the desired state: [list]; expand it — these are a floor, not a ceiling"). If the artifact yields no actor signal, record that and fall back to the current generic enumeration.
- **Evidence:** (E4)
- **Standards:** Skill-as-process-engine (actor discovery becomes a deterministic skill step); junior-developer role preserved (it still owns the sweep and still expands the list).
- **Details:** Step 1.5 is lightweight — a read-and-list step, not an analysis. It does not replace junior-developer's enumeration; it removes the dependence on the operator naming non-obvious actors in the brief.

- **Change (Fix 4 — capture purpose; purpose-conditioned blocking subset):** In Step 1, capture the **purpose** of the comparison when the operator stated one (e.g., "before a redesign pass," "to scope the next sprint"), or ask for it in the same one-line confirmation that states the comparison direction. In Step 6, add a render rule: when a purpose was captured, the skill produces a **Blocking subset** — a short list (default top 5, fewer if fewer qualify) of the gaps that most block that stated purpose, with a one-line reason each. This is an explicit skill-level synthesis judgment, labeled as such; it never alters the analyzer's neutral, unprioritized gap list. When no purpose was given, the subset is omitted.
- **Evidence:** (E5)
- **Standards:** Analyzer stays neutral (prioritization lives only in the skill, labeled as a synthesis view); optional sections must not be load-bearing (the subset is additive — Sections 1–2 still stand alone without it); writing voice.
- **Details:** The subset is a pointer view: each entry is `G-NNN — one-line reason it blocks {purpose}`. It cites existing `G-NNN` IDs; it adds no new gaps and changes no categories or confidence.

#### `han.core/skills/gap-analysis/references/gap-analysis-report-template.md`

- **Change:** (a) Add a **Process notes** subsection at the end of Section 4 (after Augmentations, outside the Confidence summary) for `workflow_note` items — rendered as plain reminders, explicitly not gap findings. (b) Add an optional **Blocking subset** block near the top of Section 1 (right after "Bottom line"), shown only when a purpose was captured: a titled mini-list of the top blocking gaps with their `G-NNN` IDs and one-line reasons, prefaced by the stated purpose. Mark both as optional in the front-matter `sections_included` guidance and in "How to Read This Report."
- **Evidence:** (E2), (E5)
- **Standards:** Information-architect's layered-report design (the blocking subset sits in the two-minute read; process notes sit with the confidence signals); optional-sections-not-load-bearing; writing voice.
- **Details:** Process notes use a one-line italic preface ("These are workflow reminders, not gaps."). The blocking subset is conditional and purpose-labeled so it never reads as the analyzer prioritizing.

#### `docs/skills/gap-analysis.md`

- **Change:** Update the canonical long-form doc to describe the new Step 1.5, the purpose capture, the second-round escape clause, the workflow-note class, and the blocking-subset view, so the doc matches the implementation.
- **Evidence:** (E1)–(E5); `CLAUDE.md` Conventions ("one canonical source per concept")
- **Standards:** Long-form doc is canonical; voice profile.
- **Details:** Prose-only update; no new behaviors beyond those in `SKILL.md`. Verify the skills index entry still scents correctly.

## Validation Results

<!-- Populated from the adversarial-validator dispatch in Step 5. -->

## Final Summary

<!-- Populated after validation. -->
