# Investigation: issue-triage / research / plan-a-feature / plan-implementation — friction surfaced by feedback issue #36

The "What didn't work" items in [issue #36](https://github.com/testdouble/han/issues/36) trace to five recurring places where these four skills push a responsibility — right-sizing the output, handing off to the next skill, detecting that a request is a scoping exercise, auditing their own generated artifacts for consistency, or resolving a factual question before asking the user — onto a fixed shape, a downstream reader, or an upstream input instead of owning it. This plan grounds every item against the current files (the report was from v2.7.0; the skills have since changed), acts on the genuine skill-level gaps, and is explicit about the two items it declines and why.

## Problem Statement

- **Symptoms.** Issue #36 is structured feedback from a real end-to-end run (`issue-triage` → `research` → `plan-a-feature` → `plan-implementation`, scoping a local task dashboard aggregating Notion + Monday.com). Analysis quality and validation usefulness rated high (4-5/5). The friction concentrated in three rated dimensions: **Output length appropriateness** (2/5 research, 3/5 the two planning skills), **Skill chain continuity** (2/5), and **Skill-to-problem fit** (3/5). The "What didn't work" bullets name fourteen specific items across the four skills.
- **Expected behavior.** The depth is warranted for a high-stakes technical decision; it is overkill for a fifteen-minute scoping conversation. The skills should right-size their output to the weight of the decision, route the operator to the natural next skill instead of relying on the operator to know the chain, detect when a request is a problem-definition exercise rather than a ticket, and (for `plan-implementation`) audit their own generated artifacts for the kind of copy-paste and cross-reference inconsistencies a synthesis pass should catch.
- **Conditions.** Surfaces most sharply when (a) the decision is relatively clear yet the report still renders full-weight supporting material, (b) the operator runs one skill and must manually carry context to the next, (c) the incoming request is a scoping/discovery problem rather than a software bug or a specified feature, (d) the generated plan inlines configuration verbatim or carries a copy-pasted title, and (e) a factual question could be answered by an authoritative source the operator already connected.
- **Impact.** Output-length friction lowers the skill's usefulness as something to act on quickly (the lowest-rated dimension). Missing handoffs make the operator the integration layer between skills. Mode-misfit adds noise fields to a triage that was never a ticket. Artifact-consistency gaps put a copy-paste title and a path mismatch in front of a developer on build day. None of these are correctness defects; all are friction that lowers usefulness — the same class of finding as issue #34.

## Evidence Summary

Evidence is grouped by skill. Each item carries its trust class (all **codebase**: direct file citations) and the verbatim text that locates the friction.

### Issue-triage

#### E1: The issue-type taxonomy has no "discovery / problem-definition" mode

- **Source:** `han.core/skills/issue-triage/SKILL.md:42-51`
- **Finding:** The seven types are Bug, Feature Request, Performance, Security, Regression, Question, Other. None names a "help me define and scope a problem" request. The closest are `Question` ("asking how something works") and `Other` (catch-all). Neither carries semantics that signal "this is a scoping exercise, not a ticket."
- **Relevance (T1):** Direct location of the mode-fit gap. The taxonomy is not the gap on its own — `Feature Request` / `Question` / `Other` already classify these requests — the gap is in the *downstream handling* of those types (E2, E5).

#### E2: Severity and Reproducibility are applied unconditionally, with no omit rule

- **Source:** `han.core/skills/issue-triage/SKILL.md:71-87`; template `references/template.md:30-38`; long-form `docs/skills/issue-triage.md:99-108`
- **Finding:** Step 4 runs for every issue type with no conditional. Contrast Step 5 (Suspected Areas), which has an explicit omit rule: "omit this entire section per Step 5 when nothing is inferable." Step 4 has no equivalent, so a Feature Request or scoping request always renders Severity and Reproducibility (at best as `Unknown`), which the feedback calls "clearly not applicable and added noise."
- **Relevance (T1):** This is the concrete source of the "added noise" complaint, and there is a working pattern (the Step 5 omit rule) already in the same file to copy.

#### E3: Step 6's recommendation table has no `/research` branch

- **Source:** `han.core/skills/issue-triage/SKILL.md:94-101`; long-form output contract `docs/skills/issue-triage.md:106-108`; related-docs `docs/skills/issue-triage.md:170-177`
- **Finding:** The four branches route only to `/investigate`, `/plan-a-feature`, `/plan-implementation`, or "Clarify with reporter." `/research` appears in no branch. When the missing information is about the *problem space* (not user-specific facts), there is no path that says "research this before specifying."
- **Relevance (T2):** Direct location of the "no triage → research path" gap. The omission is consistent across the SKILL.md table, the long-form output contract, and the related-docs list (no doc drift).

#### E4: There is no structured handoff brief; the recommendation is a bare string

- **Source:** `han.core/skills/issue-triage/SKILL.md:103-112`; long-form guidance `docs/skills/issue-triage.md:112-116`
- **Finding:** Step 7 produces one artifact (the triage report). `Recommended Next Step` is a verbatim string (a skill name or a phrase) with no structured context. The "How to get the most out of it" guidance says "Pass it to `/investigate` or `/plan-a-feature`" — naming the report itself as the handoff, but never naming `/research`.
- **Relevance (T3):** The triage report *is* already a usable handoff document (the long-form doc says so). The gap is narrower than "no handoff artifact": it is that the report's recommendation cannot point at `/research`, and the operator must still carry the file forward manually.

### Research

#### E5: One fixed report structure, rendered full-weight every run

- **Source:** `han.core/skills/research/SKILL.md:28` (Operating Principle), `:110` (Step 6), `:126` (Step 8); template `references/research-report-template.md:87-90`
- **Finding:** The skill "renders the template … every run, never an inline structure," and the Sources registry is "ALWAYS present, even for a minimal run — never omitted." This rule is stated in three places in SKILL.md plus the template (a four-point lock).
- **Relevance (R1):** Direct location of the "1,500+ words even when the decision is clear" complaint. The structure does not scale with the band the skill already computes.

#### E6: Size band controls the agent roster, not report verbosity

- **Source:** `han.core/skills/research/SKILL.md:82` (roster caps), `:102` (calibration directive)
- **Finding:** `small`/`medium`/`large` define only how many agents run. The calibration directive ("at small, the clearest options and the decisive evidence") shapes what *agents gather*, not what the *report renders*. A small run still renders the full fixed template and the full Sources registry — so a small/personal-tooling run produced the 39-entry Sources section.
- **Relevance (R1):** Confirms the band signal exists but is not wired to output length. The fix has a natural lever already present.

#### E7: The formal confidence rating lives in Validation, not the Summary

- **Source:** `han.core/skills/research/references/research-report-template.md:6-15` (Summary spec), `:79-82` (Confidence Assessment)
- **Finding:** The Summary carries a prose solidity phrase ("well-corroborated", "rests on a single source"). The structured High/Med/Low rating sits in the Validation section (section five of six). A reader who stops at the Summary — which the template says they can — never sees the formal rating the feedback asked for.
- **Relevance (R1):** The "5-sentence version with confidence rating" the feedback wants is partly present; the formal rating just is not promoted to the top.

#### E8: Closing handoff pointer fires only for hybrid requests

- **Source:** `han.core/skills/research/SKILL.md:128`; template (no handoff section, `references/research-report-template.md` six sections only); long-form `docs/skills/research.md:90`
- **Finding:** The Step 8 closing message names a sibling handoff only "(for a hybrid request)." A pure research request — the normal case — gets no closing pointer to `/plan-a-feature`, even when the recommendation is obviously a starting point for it. The long-form doc names the `/plan-a-feature` pairing, but only in operator-facing prose, not in the skill process.
- **Relevance (R2):** Direct location of the "no research → plan-a-feature handoff" gap.

### Plan-a-feature

#### E9: The decision-log "full" trigger is presence-based, not weight-based

- **Source:** `han.core/skills/plan-a-feature/references/decision-log-template.md:12-27`; `SKILL.md:139`
- **Finding:** A decision is "full" when "it has at least one rejected alternative" — regardless of whether that alternative was worth discussing. The trivial path is "an obvious convention with no alternative worth discussing," and the tie-breaker is "If unsure, treat the decision as full." So a decision with an obvious rejected alternative and a two-sentence rationale (the feedback's D10/D12) is forced into the full format.
- **Relevance (F1):** The full/trivial mechanism already exists; the trigger just keys on presence of an alternative, not its weight — which is exactly the distinction the template's own trivial definition ("no alternative *worth discussing*") already names.

#### E10: The no-implementation-mechanics rule is intended behavior with no handoff-evaluation gate

- **Source:** `han.core/skills/plan-a-feature/SKILL.md:35` (Operating Principle); `references/feature-specification-template.md:27-38`
- **Finding:** The rule generalizes brand/runtime terms ("client-side", "Python", "TypeScript") out of behavioral sentences. There is no "evaluate at plan-implementation handoff" clause anywhere; the abstraction the feedback found harder to parse is the rule working as designed.
- **Relevance (F2):** This is not a located gap. The feedback itself only says it is "worth evaluating … whether the abstraction level actually helps or hurts." See the Declined Items section.

#### E11: Step 9 is the final step and has no feedback-file behavior; no Han skill references a feedback directory

- **Source:** `han.core/skills/plan-a-feature/SKILL.md:261-273` (Step 9); negative search across `han.core/`, `han.github/`, `han.reporting/`, `docs/` for `han-feedback` (zero matches)
- **Finding:** Step 9 presents the spec and asks whether to iterate or proceed. It does not, and no Han skill does, reference `~/.claude/han-feedback/`. That path is the operator's personal Stop-hook convention, not a Han feature.
- **Relevance (F3):** Confirms F3 is out of Han's scope. See the Declined Items section.

#### E12: Resolve-before-asking is bounded to static local artifacts; allowed-tools is filesystem-only

- **Source:** `han.core/skills/plan-a-feature/SKILL.md:9-11` (description), `:32` (Operating Principle), `:64-73` (Step 2), `:90` (Step 4 sub-bullet 1), `:22` (allowed-tools)
- **Finding:** Every resolution-source enumeration names only codebase, project docs, coding standards, ADRs, existing specs. None mentions querying a live API or an MCP tool the operator has connected. `allowed-tools: Read, Write, Edit, Glob, Grep, Agent, Bash(find *), Bash(mkdir *)` permits no network or MCP call.
- **Relevance (F4):** The discipline says "resolve before asking" but bounds resolution to static local artifacts, so a question a connected Notion schema query could answer gets surfaced to the user. The allowed-tools line is the hard constraint the fix must reckon with.

### Plan-implementation

#### E13: The PM synthesis brief has no semantic-consistency audit; its invariants are structural only

- **Source:** `han.core/skills/plan-implementation/SKILL.md:268-280` (Step 8 brief), `:273-277` (cross-reference invariants)
- **Finding:** Step 8 instructs the project-manager to classify decisions, write the three files, and "preserve the cross-reference invariants" — but every invariant is structural (every `D#` lists its `Driven by rounds:` / `Dependent decisions:` / `Referenced in plan:`; every link resolves). Nothing checks that a decision's *title matches its body*, or that a path assumed in one section matches the file layout described in another. A copy-pasted title (D-3 ← D-1) and an install-script `dashboard/` path that the layout never places there both pass every structural invariant.
- **Relevance (I1, I2):** Both artifact errors slip through the same gap — there is no audit pass, only a population-and-link pass.

#### E14: plan-a-feature's PM synthesis has an active-correction mandate; plan-implementation's does not

- **Source:** `han.core/skills/plan-a-feature/SKILL.md:247-258` vs. `han.core/skills/plan-implementation/SKILL.md:268-280`
- **Finding:** plan-a-feature's Step 8 tells the PM to "reconcile the specialist input against the files and apply any remaining corrections directly," and explicitly: "Any leak the project-manager finds is rewritten in place during synthesis." plan-implementation's Step 8 is four numbered *write-and-preserve* tasks with no analogous "find and fix inconsistencies" directive. The issue praised plan-a-feature's synthesis pass for catching exactly this class of error; plan-implementation has no equivalent.
- **Relevance (I1, I2):** This is the structural asymmetry between the two skills. The fix is to bring plan-implementation's synthesis to parity, not to invent a new mechanism.

#### E15: No altitude rule governs what goes in the plan body; the template invites detail without a ceiling

- **Source:** `han.core/skills/plan-implementation/references/feature-implementation-plan-template.md:53-56` (Implementation Approach comment); `SKILL.md:36-43` (Operating Principles)
- **Finding:** The template says "Technical details are welcome here — this is the *how* document," with no ceiling and no distinction between *naming/referencing* a config artifact and *inlining its full contents*. None of the eight Operating Principles addresses altitude. YAGNI gates *inclusion*, not *verbosity of what is included*, so evidence-backed full plist XML would not fail YAGNI.
- **Relevance (I3):** Direct location of the "25+ line XML block belongs in the file, not the plan" complaint.

#### E16: Specialist briefs do not require checking the spec before raising an Open Question

- **Source:** `han.core/skills/plan-implementation/SKILL.md:122-148` (Step 4 briefs), `:207-209` (Step 6 evidence-first rule)
- **Finding:** The Step 4 brief gives each specialist "read additional spec sections only if your domain needs context" — a permission, not a "before raising an Open Question, confirm the spec does not already answer it" requirement. The evidence-first rule does exist, but at the *skill* level in Step 6, after the question is already an Open Question. So a specialist (junior-developer, in the run) raised a staleness question the spec answered directly, which then cost a Step 6 loop pass to retire.
- **Relevance (I4):** The evidence-first discipline is present but lives one layer too late; the brief never pushes it onto the specialist who raises the question.

#### E17: PM-layer / synthesis-step resolution of an Open Question is permitted but undocumented

- **Source:** `han.core/skills/plan-implementation/SKILL.md:207-227` (Step 6 loop); `references/implementation-iteration-history-template.md:36-38` (Resolution source field)
- **Finding:** `Resolution source:` allows "evidence" / "junior-developer reframing" / "user input" / "deferred to next round." When an Open Question is actually settled by the PM re-reading the spec during Step 8 synthesis (as OQ-2 was), it gets labeled "evidence," but the lookup happened in the synthesis layer, not Step 6's loop. There is no category or note distinguishing "evidence found in the Step 6 loop" from "evidence synthesized in the Step 8 PM pass," which is the circularity the feedback flagged.
- **Relevance (I5):** The resolution path is real and efficient, but invisible to the audit record.

### Cross-cutting specialist judgment

#### E18: Information-architect verdict — tighten the single artifact; do not add an executive-summary mode

- **Source:** `docs/plans/skills-feedback-issue-36/artifacts/ia-right-sizing-findings.md` (information-architect, this investigation)
- **Finding:** For R1, F1, and I3 the IA's verdict is to tighten the one canonical artifact rather than add a second output shape, because (a) a second mode violates the repo's "one canonical source per concept" and YAGNI-on-docs conventions, (b) it forces a mode-selection decision on the operator, and (c) progressive disclosure is an *ordering-and-weight* property achievable inside one file — the audiences here need the same answer at different *depths*, not different *content*. Specifics: the Sources registry can become a compact table (ID, title, link, trust class, evidence status) with prose summaries reserved for recommendation-bearing sources, preserving `A#` resolvability (the actual traceability invariant); the formal confidence rating should be promoted to the Summary; the decision-log "full" trigger should become weight-based; and the plan body needs a one-line altitude rule.
- **Relevance (R1, F1, I3):** Sets the fix approach for the entire right-sizing theme and keeps every change to an edit of an existing rule or template comment — no new file, section, or mode.

## Root Cause Analysis

### Summary

Across the fourteen items, five distinct root causes recur, and each is the same shape as issue #34's: a responsibility the skill should own at its synthesis or routing layer is instead delegated to a fixed output shape, a downstream reader, or an upstream input — so it is met only when something outside the skill happens to carry it. Two further items are not skill gaps at all (one is intended behavior, one is out of scope) and are declined with reasoning.

### Detailed Analysis

**Root cause 1 — output length is governed by fixed-shape rules and presence-based triggers that do not scale to the decision's weight (E5, E6, E7, E9, E15, E18).** The research report renders its full fixed structure and full Sources registry every run regardless of the band the skill already computed (E5, E6); the decision-log "full" trigger fires on the *presence* of any rejected alternative, not its *weight* (E9); the implementation plan template invites technical detail with no altitude ceiling (E15). The common defect is that each artifact's verbosity is wired to a structural fact (a section exists, an alternative exists, details are "welcome") rather than to the weight of the decision being recorded. The IA's verdict (E18) is that the fix is to tighten each single artifact so the layered read works, not to add a parallel "short mode" — which would violate the repo's one-canonical-structure and YAGNI-on-docs conventions.

**Root cause 2 — no skill names the natural next skill for the common case (E3, E4, E8).** `issue-triage` cannot recommend `/research` (E3); `research` only points at a sibling for hybrid requests, never for the normal pure-research case (E8). The triage report is already a serviceable handoff document (E4), so the gap is not "build a new brief artifact" — it is the much narrower "the routing table and the closing message do not know the next skill exists for this case." The operator became the integration layer because the skills end without pointing forward.

**Root cause 3 — issue-triage applies ticket-shaped fields unconditionally (E1, E2).** The taxonomy already has types that fit a scoping request (E1), but Step 4 has no omit rule for Severity/Reproducibility when they do not apply (E2), even though the very next step (Suspected Areas) demonstrates the omit-when-not-inferable pattern. So a scoping request gets ticket noise. The fix is to extend the existing omit pattern to Step 4 and to route problem-space gaps to `/research` (which is Root cause 2's fix), giving the "graceful detection" the feedback asked for without inventing a new taxonomy entry.

**Root cause 4 — plan-implementation's synthesis is a write pass, not an audit pass (E13, E14, E16, E17).** plan-a-feature's PM synthesis actively reconciles and rewrites in place (E14); plan-implementation's only populates and links (E13), so a copy-pasted title and a path mismatch survive (E13, the two artifact errors). Separately, the evidence-first discipline that should keep spec-answered questions from becoming Open Questions lives at the skill level, one layer after the specialist raises the question (E16), and PM-layer resolution of an Open Question is permitted but unlabeled (E17). All four are the same root: responsibilities that plan-a-feature places in its synthesis/brief layer are missing from plan-implementation's.

**Root cause 5 — resolve-before-asking is bounded to static local artifacts (E12).** The discipline is correct but its source list stops at the filesystem, and `allowed-tools` enforces that bound, so a factual question an operator-connected API could answer is surfaced to the user instead. The fix must respect the allowed-tools constraint: it can direct the skill to prefer an authoritative source the operator has *already connected* before asking, without mandating a network capability the skill does not have.

**Declined (E10, E11).** F2 (spec abstraction friction) is intended behavior with no located gap (E10); the feedback only suggests *evaluating* it, and weakening the no-implementation-mechanics rule on one run's readability impression would trade a clear, enforced rule for an ambiguous one. F3 (feedback file) is out of Han's scope (E11): `~/.claude/han-feedback/` is the operator's personal hook, and coupling a Han skill to a non-standard local convention is wrong. Both are recorded here so the decision is explicit, not silently dropped.

## Coding Standards Reference

| Standard | Source | Applies To |
|----------|--------|------------|
| Voice profile: no em-dashes, direct second person, plainspoken mentor tone, no hype | `docs/writing-voice.md` (referenced from `CLAUDE.md`) | All prose added to every SKILL.md, template, and long-form doc below |
| YAGNI / evidence rule: no speculative sections; every addition traces to evidence | `CLAUDE.md` ("YAGNI applies to docs too"), `han.core/references/evidence-rule.md` | Every change below must trace to an E-item; the two declined items must stay declined absent new evidence |
| One canonical source per concept; long-form doc is canonical | `CLAUDE.md` (Conventions) | Each skill's `docs/skills/{name}.md` must be updated to match every behavior change |
| Skill authoring: progressive disclosure, deterministic flowchartable steps, context hygiene | `docs/guidance/skill-building-guidance/`, `docs/guidance/plugin-entity-taxonomy.md` | New omit rules, routing branches, altitude rule, and audit directives |
| Sizing model (small/medium/large) governs dispatch | `docs/sizing.md` | Research report right-sizing must reuse the existing band, not introduce a new scale |
| Indexes stay complete | `CLAUDE.md` (Conventions) | If any routing/handoff change adds a cross-link, verify the skills index still scents correctly |

## Planned Fix

### Summary

Tighten each artifact in place so output scales with decision weight (research report, decision log, plan body); add the two missing forward pointers (`issue-triage` → `/research`, `research` → `/plan-a-feature` for pure requests); make `issue-triage` omit inapplicable ticket fields; bring `plan-implementation`'s synthesis pass to parity with `plan-a-feature`'s active-correction mandate and push the evidence-first check onto the specialists; and extend resolve-before-asking to prefer an already-connected authoritative source — while declining the two items that are intended behavior or out of scope.

> Every change is an edit to an existing rule line, template comment, or routing table. No new file, no new output mode, no new taxonomy entry, and no new allowed-tools capability beyond what is noted in Fix 9. Each fix names the canonical long-form doc it must also update.

### Fix 1 — Right-size the research report (R1)

- **Files:** `han.core/skills/research/SKILL.md` (lines 28, 102, 110, 126); `han.core/skills/research/references/research-report-template.md` (Summary spec lines 6-15, Sources comment lines 87-90); `docs/skills/research.md`.
- **Change:** (a) Reword the "always present, even for a minimal run" statements in lockstep across all four locations from "rendered in full" to a **resolvability** invariant: every cited `A#` must resolve to a registry entry; *entry depth scales with the band*. (b) Render the Sources registry as a compact table (ID, title/source, link, retrieval date for web, trust class, evidence status) by default, reserving a prose summary only for sources the recommendation rests on. (c) Promote the formal High/Med/Low confidence rating into the Summary as one labeled line, leaving the supporting risk reasoning in Validation. (d) Add a render note that at `small` the Research Results and Options carry the decisive evidence only, not the full landscape — wiring the existing calibration directive (E6) through to the rendered output.
- **Evidence:** (E5), (E6), (E7); approach set by (E18).
- **Standards:** One canonical structure (every section heading stays; this is depth, not a second mode); sizing model reused; writing voice; evidence-rule traceability preserved (A# resolvability is the real invariant).

### Fix 2 — Add the `/research` route and forward pointer to issue-triage (T2, T3)

- **Files:** `han.core/skills/issue-triage/SKILL.md` (Step 6, lines 94-101; Step 7 presentation, 103-112); `docs/skills/issue-triage.md` (output contract 106-108, related-docs 170-177, "How to get the most out of it" 112-116).
- **Change:** (a) In Step 6, add to the Feature Request and Question/Other branches: when the missing information is about the **problem space** (which approach, what's possible, what the options are) rather than user-specific facts, the recommendation is `/research`. (b) When the recommendation is a han skill, have Step 7 state plainly that the triage report itself is the handoff document for that skill (no new artifact — the report already serves; E4). (c) Add `/research` to the long-form output contract and related-docs list.
- **Evidence:** (E3), (E4).
- **Standards:** Deterministic routing (the branch keys on a stated, checkable condition); one-canonical-source (long-form updated in lockstep). Explicitly **not** building a new structured-brief artifact — YAGNI, since the report already handles off (E4).

### Fix 3 — Add the pure-request forward pointer to research (R2)

- **Files:** `han.core/skills/research/SKILL.md` (Step 8 closing message, line 128); `docs/skills/research.md`.
- **Change:** Extend the closing message so that for a pure research request whose recommendation is a starting point for specifying or building, the skill names the natural next sibling (`/plan-a-feature`) — not only "(for a hybrid request)." Keep it a one-line pointer, not a new section or artifact.
- **Evidence:** (E8).
- **Standards:** YAGNI (a pointer, not a handoff-brief section); writing voice; the long-form doc already names this pairing, so this just brings the process in line with the doc.

### Fix 4 — Make Severity and Reproducibility omittable when inapplicable (T1)

- **Files:** `han.core/skills/issue-triage/SKILL.md` (Step 4, lines 71-87); `references/template.md` (lines 30-38); `docs/skills/issue-triage.md` (99-108, "What you get back" 66-68).
- **Change:** Add an omit rule to Step 4 modeled on Step 5's existing one: when the issue type is Feature Request, Question, or Other **and** severity/reproducibility are not inferable from the report, omit those sections entirely rather than rendering `Unknown`. Mark both template sections optional with the same kind of omit comment Suspected Areas already carries.
- **Evidence:** (E1), (E2).
- **Standards:** Reuses an in-file pattern (Step 5 omit rule); deterministic; one-canonical-source. Explicitly **not** adding a new "Discovery" issue type — the existing types plus the omit rule plus the `/research` route (Fix 2) deliver the graceful handling without expanding the taxonomy.

### Fix 5 — Make the decision-log "full" trigger weight-based (F1)

- **Files:** `han.core/skills/plan-a-feature/references/decision-log-template.md` (lines 12-27); `han.core/skills/plan-a-feature/SKILL.md` (line 139); `docs/skills/plan-a-feature.md` (if it describes the full/trivial rule).
- **Change:** Change the first "full" signal from "it has at least one rejected alternative" to "it has at least one rejected alternative **a reasonable engineer would plausibly have chosen** (an obvious or strawman alternative does not by itself make a decision full)." Extend the trivial one-line bullet format to permit a one-clause mention of an obvious discarded alternative, so the information is not lost. Keep the "if unsure, treat as full" safety default.
- **Evidence:** (E9); approach set by (E18).
- **Standards:** Aligns the trigger with the template's own trivial definition ("no alternative *worth discussing*"); minimal edit; preserves the audit value (the discarded alternative is still recorded, just inline).

### Fix 6 — Add an altitude rule to the implementation plan body (I3)

- **Files:** `han.core/skills/plan-implementation/references/feature-implementation-plan-template.md` (Implementation Approach comment, lines 53-56); `han.core/skills/plan-implementation/SKILL.md` (Operating Principles, 36-43); `docs/skills/plan-implementation.md`.
- **Change:** Add a one-line altitude rule to the template comment and mirror it as an Operating Principle: **"Name and reference config and code artifacts; do not inline their full contents. Inline only the specific values that are themselves decisions (a flag default, a key name, a threshold). A full file block belongs in the file it configures, not in the plan."**
- **Evidence:** (E15); approach set by (E18).
- **Standards:** YAGNI (the plan stays at planning altitude); deterministic; writing voice.

### Fix 7 — Bring plan-implementation's synthesis to audit parity (I1, I2)

- **Files:** `han.core/skills/plan-implementation/SKILL.md` (Step 8 PM brief, lines 268-280); `docs/skills/plan-implementation.md`.
- **Change:** Add an active-correction directive to the Step 8 brief, modeled on plan-a-feature's "any leak the project-manager finds is rewritten in place." The PM must, during synthesis, audit and fix: (a) every decision-log entry's **title matches its body** (catches the D-3 ← D-1 copy-paste); (b) every path, filename, or directory referenced in one plan section is **consistent with the file layout** described in another (catches the install-script `dashboard/` mismatch); (c) the altitude rule from Fix 6 is honored. This is a semantic audit on top of the existing structural-invariant preservation, not a replacement for it.
- **Evidence:** (E13), (E14).
- **Standards:** Parity with plan-a-feature's praised synthesis pass; one-canonical-source. These are repeatable guards, not one-run patches.

### Fix 8 — Push evidence-first onto the specialists and document synthesis-layer resolution (I4, I5)

- **Files:** `han.core/skills/plan-implementation/SKILL.md` (Step 4 briefs, 122-148; Step 6/Step 8 resolution path); `references/implementation-iteration-history-template.md` (Resolution source field, 36-38); `docs/skills/plan-implementation.md`.
- **Change:** (a) Add one directive to every Step 4 specialist brief: "Before raising an Open Question, re-read the relevant feature-specification section; if the spec answers it, cite the line and do not raise it." (b) Add a `Resolution source:` value `"PM synthesis (Step 8 evidence)"` and a one-line note that an Open Question settled by the PM's spec re-read during synthesis is labeled with it — making the path explicit rather than mislabeled as Step 6 "evidence."
- **Evidence:** (E16), (E17).
- **Standards:** Deterministic; honest audit trail; minimal edits to brief and template.

### Fix 9 — Extend resolve-before-asking to a connected authoritative source (F4)

- **Files:** `han.core/skills/plan-a-feature/SKILL.md` (Operating Principle 32, Step 2 64-73, Step 4 sub-bullet 90; note on allowed-tools 22); `docs/skills/plan-a-feature.md`.
- **Change:** Add to the resolve-before-asking discipline: when an **authoritative source the operator has already connected for this session** (an MCP tool, a project API, a live schema endpoint) can answer a factual question, query it before surfacing the question to the user; surface the question only if no such source is available or it does not resolve the answer. This directs *preference and ordering*; it does not grant the skill a network capability it lacks. Add a one-line note acknowledging the `allowed-tools` constraint: the skill uses whatever connected tools the session already exposes (e.g., an MCP server), and falls back to asking when none applies.
- **Evidence:** (E12).
- **Standards:** YAGNI (no speculative always-on API integration; the fix is conditional on a source already being present); deterministic fallback (ask the user when no source applies). **Open for validation:** whether this belongs given the filesystem-only `allowed-tools` line, or whether it should instead be framed purely as session-tool preference. Flagged for the adversarial-validator.

### Declined items (recorded, not actioned)

- **F2 (spec abstraction friction) — Declined.** Intended behavior, no located gap (E10). The feedback only suggests evaluating it; acting would weaken a clear, enforced rule on one run's readability impression. Reopen trigger: a second feedback run reporting that the abstraction actively caused a plan-implementation misunderstanding, with the specific sentence that misled.
- **F3 (feedback file) — Declined as out of scope.** `~/.claude/han-feedback/` is the operator's personal Stop-hook (E11); no Han skill references it. Coupling a Han skill to a non-standard local convention is wrong. Reopen trigger: a decision to standardize a feedback-capture convention across Han, which would be its own design effort, not a per-skill Step-9 edit.

## Validation Results

*(To be completed in Step 4 — adversarial-validator dispatched against the full evidence summary, root cause, and all nine fixes plus the two declines.)*

## Final Summary

*(To be completed after validation.)*
