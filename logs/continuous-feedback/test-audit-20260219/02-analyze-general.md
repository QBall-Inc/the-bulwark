---
analyzer: general
run_slug: test-audit-20260219
target: test-audit
items_processed:
  - L007
  - L008
  - L009
  - L010
  - L011
  - L012
  - L019
  - L020
improvements_identified: 5
---

# General Specialization Analysis — test-audit

## Scope

This analyzer covers items tagged `general` skill_relevance (L007–L012) plus cross-cutting items with general implications not fully addressed by the test-audit Analyzer (L019, L020). Items L001–L006, L013–L018 are fully owned by the test-audit Analyzer.

---

## Improvement G1: Add Prose/Code Count Hardening to Orchestration Instructions

**Priority:** High

**What was learned (L020)**
When an orchestrator is told "run all three scripts" but four `bash` code blocks follow, the LLM stops after three and silently skips the fourth. This is not a parsing failure — the model simply stops when it reaches the count stated in prose. The test-audit SKILL.md Step 2 currently lists four AST scripts with prose preamble "Run all four AST scripts via Justfile recipes:" but this is the only place that convention is enforced. If the prose and code ever diverge, a silent skip will occur.

**What it affects**
- `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/SKILL.md` — Step 2 (Stage 0 AST Pre-Processing) preamble, and any subsequent step that enumerates a sequence of actions.

**Proposed improvement**
Add a count-verification note immediately before the four-script bash block in Step 2:

```markdown
> **COUNT CHECK**: The code block below contains EXACTLY 4 commands. Run ALL 4. Do not stop after 3.
```

Additionally, add a universal convention note in the Pre-Flight Gate under "What You MUST Do":

```markdown
- **Count prose against code blocks exactly** — if instructions say "N scripts" or "N steps", count the code blocks and verify they match before executing. If they do not match, default to running every code block shown.
```

This turns a silent LLM shortcut into a detectable mismatch.

**Evidence:** L020 — "Run all three" with 4 commands caused orchestrator to skip 4th script.

---

## Improvement G2: Add TestAudit Gap Pattern to SKILL.md Pipeline Trigger Documentation

**Priority:** High

**What was learned (L019)**
When an implementer writes tests directly (bypassing the TestWriter sub-agent), the pipeline condition `Stage 3b/4b: IF TestWriter produced output` evaluates to false and the TestAudit stage is silently skipped. The fix was to widen the trigger condition to `IF new/modified tests exist from Implementer OR TestWriter`. This is a pipeline-template fix, not a SKILL.md fix — but the test-audit SKILL.md does describe Hook Integration and states it can be triggered by pipeline hooks. The SKILL.md currently has no guidance on what happens when the pipeline trigger fires vs. doesn't fire, leaving the orchestrator unaware of this gap pattern.

**What it affects**
- `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/SKILL.md` — "Integration Notes > Hook Integration" section.
- Also relevant to `pipeline-templates` skill (out of scope here).

**Proposed improvement**
Expand the Hook Integration section to add a warning about the gap pattern and the correct trigger condition:

```markdown
### Hook Integration

This skill can be triggered by:
1. **Direct invocation:** `/test-audit [path]`
2. **Pipeline hook:** PostToolUse on `*.test.*` files suggests Test Audit pipeline

Both paths use the same orchestration flow.

**WARNING — Pipeline Gap Pattern:** If the pipeline condition for Stage 3b/4b only triggers when a *TestWriter* sub-agent produced output, implementer-authored tests bypass test-audit entirely. The correct trigger condition is:

```
IF any new or modified test files exist (from Implementer OR TestWriter):
    → Run test-audit pipeline
```

When updating pipeline-templates, always use the widened condition. Never narrow it to a single agent source.
```

**Evidence:** L019 — TestAudit gap when implementer writes tests and TestWriter skips.

---

## Improvement G3: Add Non-Overlapping Pattern Convention to AST Script Authoring Notes

**Priority:** Medium

**What was learned (L007)**
Cascading sed pattern collision: when multiple transforms share prefix patterns (e.g., `__dirname, '..'`), an earlier transform creates text that a later transform re-matches and corrupts. The fix is to use non-overlapping patterns unique to each target line — patterns that are deterministic regardless of execution order. This was discovered in `sync-essential-skills.sh` but the underlying principle applies wherever the test-audit AST scripts are extended with new content transforms or where the skill's sed-based sync transforms are modified.

**What it affects**
- `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/SKILL.md` — "Integration Notes > AST Scripts" section (currently has a table of scripts and purposes).
- Relevant to any future extension of the four AST scripts or the sync transform pipeline.

**Proposed improvement**
Add a "Script Extension Guidelines" note at the bottom of the AST Scripts section:

```markdown
**Script Extension Guidelines (for maintainers):**

When adding new transforms to AST scripts or sync pipelines:
- Use **non-overlapping patterns** unique to each target line. Do not rely on ordering by specificity.
- Bad: Two transforms matching `__dirname, '..'` where the first introduces text the second re-matches.
- Good: Match the longest unique string on each target line (e.g., `'node_modules'`, `.ts` filename, 4-parent chain).
- Deterministic transforms must be order-independent. If removing one sed line would break another, the patterns are not non-overlapping.
```

**Evidence:** L007 — Cascading sed pattern collision in sync-essential-skills.sh.

---

## Improvement G4: Add Unbiased Fixture Requirement to Rewrite Instructions

**Priority:** Medium

**What was learned (L018)**
Tests written by the same agent that implemented the code being tested unconsciously match the implementation's logic rather than probing real edge cases. The validation fixture must be authored by a separate agent with no access to the implementation. This principle was applied in P5.10-12 via the `test-fixture-creation` skill, but the rewrite-instructions.md currently says "Generate verification script as intermediate artifact" without specifying who generates it or whether implementation access must be blocked.

**What it affects**
- `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/references/rewrite-instructions.md` — Step 8 (verification script generation).

**Proposed improvement**
Amend Step 8 in rewrite-instructions.md to add an unbiased generation requirement:

```markdown
    8. Generate verification script as intermediate artifact:
       - Location: tmp/verification/{test-name}-verify.{ext}
       - Purpose: Validate rewrite works before modifying test
       - REQUIRED: Include edge cases from bug-magnet-data in verification
       - REQUIRED (UNBIASED FIXTURES): If using a sub-agent to generate the
         verification script, the sub-agent MUST NOT be given access to the
         implementation code being tested. Provide only the interface/contract
         (function signature, expected behavior description). Sub-agents that
         read the implementation unconsciously write tests that match implementation
         logic rather than probing real failure modes.
         Preferred: Use `test-fixture-creation` skill for verification script authoring.
```

**Evidence:** L018 — Unbiased fixtures essential; same-agent tests miss real issues.

---

## Improvement G5: Document Pass-Through Schema Rationale in Synthesis Prompt Note

**Priority:** Low

**What was learned (L010)**
The continuous-feedback pipeline's Collect stage deliberately preserves near-raw content (pass-through schema) rather than compressing it. The rationale is that lossy intermediate formats destroy actionability for downstream Analyzers. This design principle is directly analogous to how the test-audit skill injects AST metadata into sub-agent prompts — the AST output is passed through as-is into the classification and detection prompts rather than being summarized.

The current SKILL.md Step 4 and Step 5 show AST hint injection patterns but do not explain why raw JSON is passed rather than a summary. Without that rationale, future maintainers may "optimize" by summarizing the AST output before injection, which would degrade quality.

**What it affects**
- `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/SKILL.md` — Step 4 "AST hints for classification CONTEXT" block.

**Proposed improvement**
Add a one-sentence rationale comment to the AST hints injection block in Step 4:

```markdown
**AST hints for classification CONTEXT:**

> **WHY RAW**: Pass AST data as-is. Do NOT summarize or compress it. Summaries lose field-level precision that Haiku needs to avoid re-counting verification_lines from scratch (which causes inflation). Maximum fidelity in → maximum accuracy out.

```
{for each file in target}:
  file: {path}
  ast_verification_lines: {metrics.test_logic_lines}
  ...
```
```

The same note should appear inline in Step 5 (Scale Mode Detection) where AST metadata is injected into the detection agent context.

**Evidence:** L010 — Pass-through schema preserves actionability; L003/L015 — Haiku inflates verification_lines when not anchored to AST ground truth.

---

## Items Reviewed but No Improvement Proposed

| Item | Reason |
|------|--------|
| L008 (Critical Evaluation Gate) | Specific to brainstorm/research pipeline design. No test-audit impact — test-audit does not incorporate user suggestions into synthesis. |
| L009 (Validation tax in session estimates) | Scheduling/planning observation. Not actionable as a skill file change. Already reflected in task brief authoring conventions. |
| L011 (Critic breaks groupthink) | Specific to multi-agent brainstorm pipeline. test-audit uses sequential pipeline stages with fixed roles, no groupthink risk. |
| L012 (Pre-brainstorm alignment) | Specific to brainstorm workflow efficiency. No test-audit pipeline equivalent. |

---

## Summary Table

| ID | Improvement | Priority | Affected File |
|----|-------------|----------|---------------|
| G1 | Prose/code count hardening in Stage 0 and Pre-Flight Gate | High | SKILL.md |
| G2 | TestAudit gap pattern documented in Hook Integration | High | SKILL.md |
| G3 | Non-overlapping pattern convention in AST Scripts section | Medium | SKILL.md |
| G4 | Unbiased fixture requirement in rewrite Step 8 | Medium | rewrite-instructions.md |
| G5 | Pass-through rationale for AST injection blocks | Low | SKILL.md |
