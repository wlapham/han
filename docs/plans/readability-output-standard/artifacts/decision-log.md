# Decision Log: Human-Readable Output Standard

This file records every decision settled while specifying the Human-Readable Output Standard. Behavioral statements live in [../feature-specification.md](../feature-specification.md); this file captures the history, rationale, evidence, and rejected alternatives for each decision.

Evidence sources cited below draw on two trust classes: **codebase** (the trusted current-state anchor — files on disk in this repo) and **web** (the research report's external sources, outside the trust boundary, carried at the strength the report assigned). The research report itself is at `docs/research/human-readable-output-standard.md`; its source IDs (A1, A24, etc.) are cited where a decision rests on them.

## Trivial decisions

- D13: Canonical location of the rule — the rule's canonical copy lives with the other shared rules in the core plugin's references, alongside `yagni-rule.md` and `evidence-rule.md`. — Referenced in spec: Preconditions, Coordinations.
- D14: Naming follows the existing pattern — the rule is named to match `yagni-rule.md` / `evidence-rule.md`, and its operator summary matches `docs/yagni.md` / `docs/evidence.md` (considered a novel name; rejected because the whole value is recognizability as a sibling of the existing rules). — Referenced in spec: Coordinations.

## Full decisions

### D1: Standard shape — shared rule file on the YAGNI/evidence model

- **Question:** How should the readability standard be delivered — as one shared rule that every reader-facing skill applies, as per-skill restated guidance with no shared file, or as a docs-only concept re-implemented per skill (the sizing model)?
- **Decision:** One shared readability rule that reader-facing skills load and apply at runtime, exactly as they already load the YAGNI and evidence rules. The skills' output stays consistent because the rules live in one place, not because each skill restates them.
- **Rationale:** Han already ships this exact mechanism and it has real runtime grip: `docs/yagni.md` states plainly that "every YAGNI-aware skill and agent loads that file at runtime," and skill steps direct the executor to read and apply the referenced rule by relative link. The operator asked for a shared, evolvable reference to cite across skills, which is itself acceptable evidence (a user-described need). A single source of truth is materially easier to keep current than the same rules re-stated in every skill.
- **Evidence:** codebase — `han-core/references/yagni-rule.md`, `han-core/references/evidence-rule.md`, `docs/yagni.md:13`; research report recommendation and A53, A57. User input (request to plan a shared standard).
- **Rejected alternatives:**
  - Per-skill restated guidance with no shared file (research option O3) — rejected because it omits the single evolvable source of truth the operator asked for, and each skill re-derives the rules (investigate barely states them today). The drift this risks is plausible but un-measured, so O3 is the honest lower-cost alternative rather than a defeated one.
  - Docs-only concept re-implemented per skill, like sizing — rejected because sizing has no shared rule file and no runtime loading; it would not give the standard runtime grip.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D2, D9, D12
- **Referenced in spec:** Outcome, Edge Cases and Failure Modes

### D2: Layered enforcement, applied one layer at a time

- **Question:** How does a skill apply a rule of roughly eight to twelve items without reproducing the "curse of instructions," where compliance decays as simultaneous instructions stack up?
- **Decision:** The rule is never fired as one instruction block. Its structural rules are embedded in each skill's output template, its do/don't pairs are handed to the model as examples, and its testable checks run as an after-the-fact self-check. A skill applies one layer at a time.
- **Rationale:** Compliance with a stacked instruction set drops sharply as the count rises; splitting the work across a template, examples, and a separate check keeps each step's constraint count low. Examples are the most reliable lever for steering output format and tone.
- **Evidence:** web (via research report) — A24 (curse of instructions), A23 (per-constraint decomposition), A25 and A32 (few-shot examples as the reliable style lever). codebase — several skills already embed structural rules in their output templates.
- **Rejected alternatives:**
  - Load the whole rule as a single instruction block each run — rejected because it reproduces the exact failure the rule is meant to dodge.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D11
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

### D3: Skill scope — all reader-facing prose skills

- **Question:** Which reader-facing skills does the standard commit to wiring now?
- **Decision:** All eight skills whose primary output is human-facing prose: research, stakeholder-summary, code-overview, investigate, update-pr-description, html-summary, gap-analysis, and project-documentation.
- **Rationale:** The operator chose the broader scope over the five skills the research audited. investigate gains the most, because today its top summary is a five-field structured technical block, not a plain one-line summary, and it cites no readability principle.
- **Evidence:** User input. codebase — the current-state audit of each skill's SKILL.md and output template.
- **Rejected alternatives:**
  - The five audited skills only (research, stakeholder-summary, code-overview, investigate, update-pr-description) — rejected because the operator chose to include html-summary, gap-analysis, and project-documentation as well.
  - Rule file plus operator summary only, deferring all per-skill wiring — rejected because it undercuts the request to plan the per-skill enforcement layers.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D5
- **Referenced in spec:** Primary Flow

### D4: A new dedicated readability-editor reviewer

- **Question:** How is the editor-agent readability pass provided — by reusing the two existing prose reviewers, or by a new dedicated reviewer?
- **Decision:** A new dedicated readability-editor reviewer that audits and rewrites a draft against a small, behaviorally-anchored rubric.
- **Rationale:** The operator chose a dedicated reviewer over reusing the existing two. A tight rubric with concrete yes/no anchors gives targeted feedback and guards against the unreliability of ungrounded prose judging.
- **Evidence:** User input. web (via research report) — A30 (ungrounded self-judging is unreliable and sycophantic; anchors required), A50 (rubrics need three to six behaviorally-anchored dimensions). codebase — code-overview already dispatches `information-architect` + `junior-developer` for a readability pass, the pattern this reviewer generalizes.
- **Rejected alternatives:**
  - Reuse the existing `information-architect` + `junior-developer` reviewers, as code-overview does today — rejected on the operator's choice; recorded here because it is the lower-cost path and remains the fallback if the dedicated reviewer proves unnecessary.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** D5
- **Referenced in spec:** Alternate Flows and States, Coordinations

### D5: Rewrite pass only where a synthesis step already exists

- **Question:** Where does the dedicated "rewrite for readability, preserve every fact" pass run?
- **Decision:** Only in skills that already have a synthesis or editor step: code-overview, stakeholder-summary, and research. Every other in-scope skill applies the template, audience frame, and self-check but runs no separate rewrite pass.
- **Rationale:** The research recommendation softens a mandatory two-pass to "where a skill already synthesizes." A mandatory rewrite in every skill adds an extra call and latency each run and raises the risk of over-simplification dropping facts on dense content, with little gain where the self-check already covers the output.
- **Evidence:** User input. web (via research report) — A22 and A23 (two-pass payoff), A29 (readability/accuracy tension on dense content). codebase — code-overview has an agent pass at its Step 7; stakeholder-summary runs a multi-pass self-check; research synthesizes its report.
- **Rejected alternatives:**
  - A mandatory rewrite pass in every reader-facing skill — rejected because the added cost and over-simplification risk are not justified where no synthesis step exists to extend.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Alternate Flows and States, Edge Cases and Failure Modes

### D6: Reuse the existing vocabulary blocklist for word-level rules

- **Question:** Should the readability rule state its own word-level vocabulary rules, or reuse the blocklist that already exists in the operator writing-voice profile?
- **Decision:** The readability rule points skills at the existing blocklist for word-level rules rather than duplicating them. This makes the blocklist relevant to skill output at runtime for the first time; it continues to govern operator documentation unchanged.
- **Rationale:** The blocklist already exists and is specific (no "just", no "leverage", no em-dash, a named AI-slop list). Reusing it avoids maintaining the same vocabulary rules in two places. The operator chose reuse over a self-contained rule.
- **Evidence:** User input. codebase — `docs/writing-voice.md` (the blocklist), confirmed not currently loaded at runtime by any skill or agent.
- **Rejected alternatives:**
  - Keep the readability rule self-contained and leave the writing-voice profile for operator docs only — rejected on the operator's choice; it would duplicate the vocabulary rules across two files.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Coordinations

### D7: Qualitative length guidance, not hard word caps

- **Question:** Should the sentence- and document-length rules be hard numeric caps or qualitative targets?
- **Decision:** Qualitative length guidance (short sentences, roughly fifteen to twenty words on average, few past twenty-five to thirty), not a hard numeric word cap on sentences or documents.
- **Rationale:** Models systematically overshoot numeric length targets, and hard caps can strip the connective tissue that makes prose readable. Qualitative targets steer without the failure mode.
- **Evidence:** web (via research report) — A28 (LLMs overshoot numeric length targets; qualitative targets work better). The report drops the single-source first-party postmortem (A39) from the basis; this decision rests on A28 alone.
- **Rejected alternatives:**
  - A hard per-sentence or per-document word cap — rejected because models overshoot the target and caps degrade cohesion.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** (rule content; not directly cited in a spec sentence)

### D8: Readability formulas and linting are not the enforcement mechanism

- **Question:** Should a readability formula (Flesch, grade level) be the standard's target, and should output be gated by a prose linter in CI?
- **Decision:** No to both. Formulas are demoted to an optional diagnostic (deferred), never the spine. CI/prose-linting is out of scope because skill output is ephemeral, not committed files in a pipeline.
- **Rationale:** Formulas are weak comprehension proxies that reward gaming and degrade cohesion when optimized. Prose linting is proven to change output at scale only by hard-gating committed files, which reader-facing skill output is not.
- **Evidence:** web (via research report) — A10 (formula criticism), A42 and A49 (Vale/CI mechanism), A7-A9 (the formulas). codebase — skill output is conversational or scratch text with no CI surface (A55, A57).
- **Rejected alternatives:**
  - A Flesch band or grade-level target as the standard's measure (research option O6) — rejected as a poor proxy that rewards gaming.
  - Vale or equivalent prose linting in CI over produced output (research option O5) — rejected on fit: there is no committed-file surface to lint.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Out of Scope, Deferred (YAGNI)

### D9: Vendoring — manual byte-identical copies into plugins shipping in-scope skills

- **Question:** How is the shared rule made available to skills across plugins?
- **Decision:** The canonical copy lives in the core plugin's references. It is copied byte-for-byte into every plugin that ships an in-scope skill — the coding, reporting, and github plugins — the same way the YAGNI and evidence rules are already vendored. All copies stay byte-identical.
- **Rationale:** This is the proven, understood mechanism already in use. The vendored YAGNI and evidence copies are confirmed byte-identical to their canonical originals, so each plugin's skills run with no cross-plugin dependency.
- **Evidence:** codebase — identical vendored copies of `yagni-rule.md` / `evidence-rule.md` in `han-planning/references/` and `han-coding/references/`; the in-scope skills live in han-core, han-coding, han-reporting, and han-github.
- **Rejected alternatives:**
  - A build-step or automated sync of the copies — rejected under the simpler-version test; manual copying matches the current pattern and no drift has been observed (recorded in Deferred (YAGNI)).
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Preconditions, Alternate Flows and States, Coordinations, Edge Cases and Failure Modes

### D10: Always-on audience frame

- **Question:** What single instruction should be on for every reader-facing skill while it drafts?
- **Decision:** An always-on audience frame: write for a smart non-expert who has not seen the code.
- **Rationale:** Audience or grade-level framing is the most practical single instruction for steering plain output, and it is backed by Anthropic's own prompting guidance (role/persona for audience). It is carried as directionally sound for technical output rather than proven, because the strongest audience-targeting evidence is from the healthcare-simplification domain and is in tension with fidelity on dense reports.
- **Evidence:** web (via research report) — A21 (audience/grade-level targeting, domain-caveated per V6), A32 (Anthropic prompting guidance). A29 governs as the fidelity constraint on dense output.
- **Rejected alternatives:**
  - A grade-level numeric target instead of an audience frame — rejected because numeric targets are overshot and grade levels are meaningless for adult expert readers.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow

### D11: Self-check uses behaviorally-anchored yes/no criteria

- **Question:** What does the standardized plain-language self-check evaluate?
- **Decision:** Concrete, behaviorally-anchored yes/no criteria (does the first line state the main point? does any sentence exceed the length guidance? is any blocklisted word present?), not a subjective "is this clear?" judgment.
- **Rationale:** General models barely beat random on writing-quality assessment and carry a sycophancy and verbosity bias, so a self-check needs concrete anchors it can evaluate reliably.
- **Evidence:** web (via research report) — A30 (unreliable ungrounded self-judging). codebase — stakeholder-summary's existing Pass A/B/C self-check is the closest current example to generalize.
- **Rejected alternatives:**
  - A subjective "rate the clarity of this text" self-check — rejected because ungrounded self-judging is unreliable and biased toward longer, agreeable text.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Primary Flow, Edge Cases and Failure Modes

### D12: Operator-facing summary and concepts index entry

- **Question:** How does the standard surface to operators, separate from the runtime rule?
- **Decision:** A plain-language operator summary of the rule sits alongside the existing YAGNI and evidence summaries, mirrors their structure, and is listed in the same index of foundational mechanics.
- **Rationale:** Every shared rule in Han pairs a runtime rule file with an operator-facing summary, and the concepts index introduces the foundational mechanics. Following the pattern keeps the standard discoverable the same way YAGNI and evidence are.
- **Evidence:** codebase — `docs/yagni.md`, `docs/evidence.md` as operator extracts; `docs/concepts.md` as the index of the foundational mechanics (no `docs/README.md` exists).
- **Rejected alternatives:**
  - Ship the runtime rule with no operator summary — rejected because it breaks the established rule/summary pairing and leaves operators without a plain-language entry point.
- **Linked technical notes:** —
- **Driven by findings:** —
- **Dependent decisions:** —
- **Referenced in spec:** Coordinations
</content>
