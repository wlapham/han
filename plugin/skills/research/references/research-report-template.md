# Research: {Question Title}

<!-- One-sentence statement of the open-ended question being researched. -->

## Question

<!-- The question framed as the specific decision or unknown to resolve. -->
<!-- - What is being decided or understood? -->
<!-- - What alternatives, if any, are in play? (If none — a "how does X work" question — say so.) -->
<!-- - What would a good answer let the reader do next? -->

## Evidence Summary

<!-- Every piece of evidence gathered, numbered sequentially (E1, E2, ...). -->
<!-- Every item carries a source the reader can independently check. -->

### E1: {Brief description of finding}

- **Source:** `https://example.com/path` (retrieved {YYYY-MM-DD}) — or `path/to/file.ext:line` — or `provided: {reference}`
- **Finding:**
  ```
  verbatim quote, close paraphrase, or code snippet
  ```
- **Corroboration:** {independent source confirming it, with its own source — or "single source — caveated"}
- **Relevance:** {how this connects to the question}

### E2: {Brief description of finding}

- **Source:** ...
- **Finding:**
  ```
  ...
  ```
- **Corroboration:** ...
- **Relevance:** ...

<!-- Add more evidence items as needed (E3, E4, ...). -->

## Options Landscape

<!-- Each viable option, steelmanned, with trade-offs keyed to evidence items. -->
<!-- Include "continue with the current approach" as a named option when codebase evidence conflicts with external evidence. -->

### Option A: {name}

- **What it is:** {one or two sentences}
- **Supports:** {evidence items that favor it, e.g. (E1), (E4)}
- **Trade-offs:** {costs, risks, constraints, with evidence references}

### Option B: {name}

- **What it is:** ...
- **Supports:** ...
- **Trade-offs:** ...

<!-- Add more options as needed. -->

### Conflicts and open questions

<!-- Source-vs-source or codebase-vs-web conflicts surfaced rather than silently resolved. Single-source caveats. -->

## Recommendation

<!-- The recommended option and why, referencing evidence by number. -->
<!-- If the evidence does not support a single answer, state "No clear winner" and list the
     deciding criteria or the missing information that would break the tie. Do not force a pick. -->

## Validation

<!-- Adversarial-validator findings: numbered V1, V2, ... -->

### V1: {Hypothesis challenged}

- **Strategy:** Challenge the Evidence | Challenge the Options Framing | Challenge the Recommendation | Challenge the Evidence-Gathering Integrity
- **Investigation:** {what was checked}
- **Result:** Confirmed / Refuted / Partially Refuted
- **Impact:** {what changed, or why this supports the recommendation}

### V2: {Hypothesis challenged}

- ...

<!-- Add more validation findings as needed. -->

### Adjustments Made

<!-- CONDITIONAL: include only if validation changed the landscape or recommendation. -->
<!-- List what changed and which V# triggered it. If the recommendation did not survive,
     state that it was rewritten into the no-clear-winner form. -->

### Confidence Assessment

- **Confidence:** High / Medium / Low
- **Remaining Risks:** {known gaps, uncorroborated single sources relied on, staleness risk, areas not covered by the band}

## Final Summary

<!-- One sentence each. Reference evidence (E#) and validation (V#) where appropriate. -->

- **Question:** {what was asked}
- **Recommendation:** {the recommended option, or "no clear winner" with deciding criteria}
- **Why:** {the strongest evidence supporting it}
- **Validation outcome:** {what validation confirmed or changed}
- **Remaining risks:** {see Confidence Assessment above}
- **Handoff:** {for a hybrid request — the sibling skill named for the non-research portion; otherwise "none"}
