---
run_slug: "test-audit-20260219"
stage: "03-proposal"
target: "test-audit"
total_proposals: 11
priority_distribution:
  high: 5
  medium: 5
  low: 1
source_analyses:
  - logs/continuous-feedback/test-audit-20260219/02-analyze-test-audit.md
  - logs/continuous-feedback/test-audit-20260219/02-analyze-general.md
---

# Test-Audit Skill — Change Proposals

## Proposal Summary

| # | Title | Priority | Target File | Source |
|---|-------|----------|-------------|--------|
| 1 | Synthesis dedup — MUST NOT sum binding language | High | references/prompts/synthesis.md | L002, L006 |
| 2 | Haiku classification — AST ground truth binding in Step 4 | High | SKILL.md | L003, L005, L015 |
| 3 | AST re-classification prevention — Pre-Flight Gate hardening | High | SKILL.md | L014 |
| 4 | Property-access tracing — detection prompt instruction | High | references/prompts/deep-mode-detection.md | L017 |
| 5 | Prose/code count hardening — Pre-Flight Gate + Step 2 | High | SKILL.md | L020, G1 |
| 6 | File-scope mock detection — resolved limitation entry | Medium | references/known-limitations.md | L001, L004 |
| 7 | Violation scope variance — active limitation entry | Medium | references/known-limitations.md | L013 |
| 8 | Inline object false positive — synthesis constraint | Medium | references/prompts/synthesis.md | L016 |
| 9 | Property-access chain gap — known limitation entry | Medium | references/known-limitations.md | L017 |
| 10 | Unbiased fixtures requirement in rewrite Step 8 | Medium | references/rewrite-instructions.md | L018, G4 |
| 11 | Pass-through rationale for AST injection blocks | Low | SKILL.md | L010, G5 |

Note: Proposals 4 and 9 both address L017 (property-access tracing) at different layers — the detection prompt (actionable instruction) and known-limitations.md (documented gap). They are complementary, not duplicates. Proposals 5 and G1 are merged into a single proposal covering both the Pre-Flight Gate bullet fix and the Stage 2 count note. Proposals 8 and G4 (unbiased fixtures) are merged into a single Proposal 10 covering rewrite-instructions.md Step 8. Pipeline trigger gap (L019/G2) is merged into a single Proposal addressing Hook Integration in SKILL.md (not listed separately — see note after Proposal 10).

---

## Proposed Change 1: Synthesis Dedup — MUST NOT Sum Binding Language

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/references/prompts/synthesis.md`
**Change type**: Modify
**Section**: CONSTRAINTS — union instruction (after "Example: two violations both scoped to...")
**Priority**: High
**Source learnings**: L002, L006

### Proposed content:

Replace the existing union constraint block:

```
- When multiple violations affect the same file, compute affected_lines as the UNION of all
  violation_scope ranges (merge overlapping/identical ranges), NOT the sum of individual
  affected_lines values. Example: two violations both scoped to [228, 269] = 42 affected
  lines total, not 84.
```

With:

```
- When multiple violations affect the same file, compute affected_lines as the UNION of all
  violation_scope ranges (merge overlapping/identical ranges), NOT the sum of individual
  affected_lines values. Example: two violations both scoped to [228, 269] = 42 affected
  lines total, not 84.
- MUST NOT sum individual violation affected_lines values across violations in the same file.
  Summing is ALWAYS wrong and will produce inflated effectiveness penalties. The detection
  stage may pre-deduplicate in file_summaries — if so, use that value directly. If not, you
  MUST compute the set union before calculating effectiveness.
- BINDING: If you find yourself adding affected_lines across violations for the same file,
  STOP. Compute the union of all line ranges first. Naive summation that inflates affected
  line counts can cause files to fail Gate 2 that should be advisory-only.
```

### Rationale:

L002 and L006 documented that the synthesis agent can naively sum per-violation `affected_lines` rather than computing the union of overlapping ranges. The existing guidance ("merge overlapping/identical ranges") is phrased as guidance without explicit MUST NOT language for the alternative path. The added lines close that gap with binding language and the STOP pattern that prevents the LLM from continuing down the wrong path once it recognizes the error. Inflated affected_lines directly corrupts Gate 2 decisions, causing false REWRITE_REQUIRED outcomes.

### Validation:

Run `/test-audit` against a test file with two violations that share overlapping line ranges (e.g., lines 228-269 for both violations). Verify the synthesis output shows `affected_lines: 42` (not 84) in `logs/test-audit-*.yaml` and that `test_effectiveness` reflects the union, not the sum.

---

## Proposed Change 2: Haiku Classification — AST Ground Truth Binding in Step 4

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/SKILL.md`
**Change type**: Modify
**Section**: Step 4 — "AST hints for classification CONTEXT" preamble
**Priority**: High
**Source learnings**: L003, L005, L015

### Proposed content:

Replace the existing preamble in the "AST hints for classification CONTEXT" block:

```
The following AST-computed metadata is available for each file.
Use this to improve classification accuracy — these are deterministic,
not heuristic.
```

With:

```
The following AST-computed metadata is MANDATORY ground truth for each file.
You MUST use ast_verification_lines as the verification_lines value — do NOT
re-count independently. AST line counts are deterministic; your independent
re-count is not and will inflate verification_lines.
MUST NOT report verification_lines = total_lines — this indicates you re-counted
instead of using AST data, and is always wrong.
If AST data is missing for a file, set verification_lines_source: "heuristic"
and note it in diagnostics. Do not silently echo total_lines.
```

### Rationale:

L003, L005, and L015 document that at scale (14+ files), Haiku reported `verification_lines = total_lines` for some files (e.g., knowledge-linker.test.ts: 571/571). This occurs when Haiku defaults to independent counting instead of using AST ground truth. The current preamble uses advisory language ("Use this to improve classification accuracy") that Haiku can bypass. Changing to MUST NOT language with an explicit failure signature ("verification_lines = total_lines") gives the LLM a self-correction trigger. Inflated verification_lines understate the effectiveness percentage, silently suppressing Gate 2 triggers and letting degraded test suites pass audit.

### Validation:

Run `/test-audit` in Scale mode against 14+ test files. Inspect `logs/test-classification-*.yaml` and verify that no file has `verification_lines == total_lines` unless the file is genuinely 100% test logic. Cross-check against AST `metrics.test_logic_lines` from `ast-verify-count.json`.

---

## Proposed Change 3: AST Re-Classification Prevention — Pre-Flight Gate Hardening

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/SKILL.md`
**Change type**: Modify
**Section**: Pre-Flight Gate — "What You MUST NOT Do" list
**Priority**: High
**Source learnings**: L014

### Proposed content:

Append the following two items to the existing "What You MUST NOT Do" list (after "Do NOT return to user until all log files are written"):

```markdown
- **Do NOT dismiss AST T3 leads by re-classifying sections** — If the AST classifies a section as integration or e2e, that classification is FINAL. You MUST pass that lead to the detection stage unchanged. Rationalizing that a section is "actually a unit test" to dismiss an AST lead is a rule violation. Your role as orchestrator is to route leads, not re-classify them.
- **Do NOT override AST verification_lines** — AST-computed line counts are ground truth for the classification and synthesis stages. Do not substitute heuristic estimates or allow Haiku's independent counts to replace them.
```

### Rationale:

L014 established that without explicit "AST classification is final" language in the orchestrator's own binding section, the orchestrator can rationalize skipping T3 leads before any sub-agent is spawned. The binding language already exists in `deep-mode-detection.md` (where the sub-agent is directly instructed) and mock-detection's SKILL.md. However, the test-audit orchestrator's Pre-Flight Gate — the first binding section the orchestrator reads — does not contain this constraint. An orchestrator reading SKILL.md without loading sub-agent prompts can still violate the rule. Adding it here closes the gap at the orchestrator layer.

### Validation:

Review session logs for a test-audit run against a file with AST-classified integration sections. Verify the orchestrator passes all integration-mock leads from `ast-integration-mocks.json` to the detection sub-agent without filtering or re-classifying any as unit sections.

---

## Proposed Change 4: Property-Access Tracing — Detection Prompt Instruction

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/references/prompts/deep-mode-detection.md`
**Change type**: Modify
**Section**: CONSTRAINTS — after "Use call graph analysis to detect T1-T3 violations beyond AST leads"
**Priority**: High
**Source learnings**: L017

### Proposed content:

Insert the following item after "Use call graph analysis to detect T1-T3 violations beyond AST leads" in the CONSTRAINTS list:

```markdown
- When tracing T3+ violations, follow property-access chains: if `mockOrder` is a mock
  variable, then `mockOrder.id` is also tainted. If `mockOrder.id` is embedded in a new
  object literal that is passed to the tested function, that is a T3+ violation even if
  the AST data-flow-analyzer did not flag it. The full contamination path to check:
  mock declaration → property access (mockOrder.id) → literal construction
  ({ orderId: mockOrder.id }) → SUT input (processOrder(payload)). Flag the outer
  literal construction as the violation, not the property access itself.
```

### Rationale:

L017 identified that property-access chains are the most common real-world T3+ pattern. The AST data-flow-analyzer traces direct variable usage but not `MemberExpression` nodes — a known gap documented in the limitations file (Proposal 9). Without explicit instruction to follow property-access chains, the detection agent catches fewer real violations. The phrase "Validate AST leads and add any the AST missed" in the current CONTEXT block is insufficient because it does not explain what patterns the AST misses or how to trace them. This instruction gives the agent a concrete pattern to apply proactively.

### Validation:

Run `/test-audit` (Deep mode) against a test file containing the pattern `const payload = { orderId: mockOrder.id, ... }; processOrder(payload)` where `mockOrder` is declared via `jest.mock()`. Verify the detection output in `logs/mock-detection-*.yaml` includes a T3+ violation on the `payload` construction, not just the `jest.mock()` declaration.

---

## Proposed Change 5: Prose/Code Count Hardening — Pre-Flight Gate + Step 2

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/SKILL.md`
**Change type**: Modify
**Section**: (a) Pre-Flight Gate — "What You MUST Do" Step 1; (b) Step 2 — before the four-command bash block
**Priority**: High
**Source learnings**: L020, G1

### Proposed content:

**(a) Pre-Flight Gate — Step 1 update:**

Replace:

```markdown
1. **Run Stage 0 AST scripts** before any LLM stages:
   - `just verify-count {target}` → `/tmp/claude/ast-verify-count.json`
   - `just skip-detect {target}` → `/tmp/claude/ast-skip-detect.json`
   - `just ast-analyze {target}` → `/tmp/claude/ast-data-flow.json`
```

With:

```markdown
1. **Run all four Stage 0 AST scripts** before any LLM stages:
   - `just verify-count {target}` → `/tmp/claude/ast-verify-count.json`
   - `just skip-detect {target}` → `/tmp/claude/ast-skip-detect.json`
   - `just ast-analyze {target}` → `/tmp/claude/ast-data-flow.json`
   - `just integration-mocks {target}` → `/tmp/claude/ast-integration-mocks.json`
```

Also append to "What You MUST Do" (after the existing items):

```markdown
- **Count prose against code blocks exactly** — if instructions say "N scripts" or "N steps", count the code blocks and verify they match N before executing. If they do not match, default to running every code block shown.
```

**(b) Step 2 — insert count note before bash block:**

Insert the following line immediately before the four-command bash block in Step 2 (between "3. Run all four AST scripts via Justfile recipes:" and the opening triple-backtick):

```markdown
> **COUNT CHECK**: The code block below contains EXACTLY 4 commands. Run ALL 4. Do not stop after 3.
```

### Rationale:

L020 and G1 documented that when an orchestrator is told "run all three scripts" but four commands follow, the LLM stops at three and silently skips the fourth. Two failure modes exist: (1) the prose count mismatches the code block count (the Pre-Flight Gate Step 1 had three bullets while Step 2 had four commands — the `just integration-mocks` script was missing from the Gate), and (2) the LLM uses the prose count as a stopping signal without counting the code. Both fixes are applied here: the bullet mismatch is corrected, and a blockquote COUNT CHECK makes the code block's item count explicit, preventing the LLM from relying solely on prose to determine when to stop.

### Validation:

Inspect the Pre-Flight Gate "What You MUST Do" Step 1 and confirm it lists exactly 4 bullets matching the 4 commands in Step 2's bash block. Run `/test-audit` and verify `ast-integration-mocks.json` is populated in a session log — absence indicates `just integration-mocks` was skipped.

---

## Proposed Change 6: File-Scope Mock Detection — Resolved Limitation Entry

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/references/known-limitations.md`
**Change type**: Add
**Section**: Resolved Limitations table + new body section before the table
**Priority**: Medium
**Source learnings**: L001, L004

### Proposed content:

**(a) Add a new row to the Resolved Limitations table:**

```markdown
| File-scope mocks invisible to section-scoped AST | File-scope `jest.mock()` cross-product detection: one T3 lead per file-scope mock per integration/e2e section (Step 3b in integration-mock-detector.ts) | P5.12 |
```

**(b) Add a new body section before the Resolved Limitations table heading:**

```markdown
## File-Scope Mock Detection

**Issue (Resolved):** The integration-mock-detector originally scanned only inside describe blocks. File-scope `jest.mock()` declarations (declared above all describe blocks) contaminate every integration/e2e section in the file, but were invisible to section-scoped analysis.

**Resolution (P5.12):** Step 3b added to integration-mock-detector.ts. Logic: cross-product of (file-scope mocks) × (integration/e2e sections) = one T3 lead per pair. A file with 2 file-scope mocks and 2 integration sections produces 4 leads. Two AST fixtures validate this pattern: `file-scope-mocks/router-mixed.test.ts` and `file-scope-mocks/unit-only.test.ts`.
```

### Rationale:

L001 and L004 documented a real detection gap and its resolution in P5.12. The known-limitations.md currently has no mention of file-scope mocks — neither as an active limitation nor as a resolved one. Without this entry, future sessions investigating missing T3 leads on file-scope mocks would re-discover the same gap rather than recognizing it as already resolved. The resolved table entry provides a traceable record; the body section provides the implementation detail needed to understand how the resolution works.

### Validation:

Review `known-limitations.md` and confirm the new row appears in the Resolved Limitations table and the new section appears above the table. Verify cross-references to `integration-mock-detector.ts` Step 3b are accurate by reading that script.

---

## Proposed Change 7: Violation Scope Variance — Active Limitation Entry

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/references/known-limitations.md`
**Change type**: Add
**Section**: New section after "Context Limits at Scale" and before "Resolved Limitations"
**Priority**: Medium
**Source learnings**: L013

### Proposed content:

Insert the following new section after "Context Limits at Scale" and before "Resolved Limitations":

```markdown
## Violation Scope Variance (LLM Judgment)

**Issue:** The detection agent (Sonnet) may report different `affected_lines` values for the same T3 violation across runs. The variance arises from whether the agent includes assertions that consume mock return values in the violation scope. Observed range: 19 lines vs 8 lines for identical code.

**Impact:** Scope variance can flip Gate 2 outcomes. A file may be above or below the 95% effectiveness threshold on different runs. This is nondeterministic behavior, not a data pipeline bug.

**Mitigation:** AST-computed `verification_lines` provides a fixed denominator. The numerator (`affected_lines`) remains subject to LLM variance. The diagnostics log records `verification_lines_source: ast | heuristic` — use this to assess denominator reliability. For scope disputes across runs, accept the higher `affected_lines` value (more conservative) to avoid false Gate 2 passes.

**Future:** Consider AST-based `affected_lines` computation (deferred to P6+). Requires tracking which assertion lines reference mocked variables via `MemberExpression` tracing.
```

### Rationale:

L013 documented a reproducible pattern where the same T3 violation received affected_lines of 19 vs 8 across two Sonnet runs. This variance can flip Gate 2 outcomes. Without a documented limitation entry, future sessions will investigate the variance as a bug rather than recognizing it as known LLM judgment variance. The mitigation guidance (accept the more conservative value) gives a concrete decision rule for when the variance matters.

### Validation:

Run `/test-audit` twice against the same file with a known T3 violation. If affected_lines differ between runs, confirm the guidance in this section is applied — the more conservative (higher) value should be used for gate evaluation.

---

## Proposed Change 8: Inline Object False Positive — Synthesis Constraint

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/references/prompts/synthesis.md`
**Change type**: Add
**Section**: CONSTRAINTS — end of the list
**Priority**: Medium
**Source learnings**: L016

### Proposed content:

Append the following item to the end of the CONSTRAINTS list in synthesis.md:

```markdown
- Inline object literals used as function arguments are NOT T3+ violations:
  `createOrder({ customerId: 'x' })` starts a chain — the literal is input data,
  not a replacement for upstream output. T3+ applies only when a variable is assigned
  from literal construction AND that variable replaces what should be real upstream
  function output (e.g., `const orderData = { id: 'mock-123', ... }; processOrder(orderData)`
  where orderData should have come from `createOrder()`). Do not flag the argument literal
  itself — flag the variable that replaces upstream function output.
```

### Rationale:

L016 documented that `createOrder({ customerId: 'x' })` is not a T3 violation — the inline object is input, not replacement. Without a synthesis-stage constraint, a detection agent's borderline finding can be promoted to a false positive P0 classification during synthesis. False positive P0 classifications trigger unnecessary REWRITE_REQUIRED outcomes. The constraint surfaces the distinction at the synthesis layer where the final priority classification is made, preventing escalation of borderline pattern-matched findings.

### Validation:

Run `/test-audit` against a file containing `createOrder({ customerId: 'x' })` as a function argument. Verify the synthesis output in `logs/test-audit-*.yaml` does not classify this as a T3+ violation. If the detection agent flagged it, verify synthesis downgrades or drops it per this constraint.

---

## Proposed Change 9: Property-Access Chain Gap — Known Limitation Entry

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/references/known-limitations.md`
**Change type**: Add
**Section**: New subsection appended to "T3+ Detection: Single-File Scope"
**Priority**: Medium
**Source learnings**: L017

### Proposed content:

Append the following subsection after the existing "T3+ Detection: Single-File Scope" section:

```markdown
## T3+ Detection: Property-Access Chain Gap

**Issue:** AST data-flow-analyzer (`data-flow-analyzer.ts`) traces direct variable usage (e.g., `processOrder(mockOrder)`) but does not follow `MemberExpression` nodes. When mock data propagates via property access (`mockOrder.id` used inside a new object literal), the AST does not flag the contamination path.

**Impact:** The pattern `const payload = { orderId: mockOrder.id, ... }; processOrder(payload)` is a T3+ violation but produces no AST lead. The detection Sonnet agent must catch this via explicit call graph analysis (see deep-mode-detection.md CONSTRAINTS for property-access tracing instruction).

**Mitigation:** Deep mode detection prompt (as of P5.12) instructs the agent to follow property-access chains explicitly. The phrase "Validate AST leads and add any the AST missed" covers this path, supplemented by the property-access tracing constraint. However, the agent must proactively look for this pattern — it is not guaranteed without the explicit instruction.

**Future:** Extend `data-flow-analyzer.ts` to trace `MemberExpression` nodes as tainted when the object is a known mock variable (deferred to P6+). Requires building a taint set from mock declarations and propagating it through property accesses.
```

### Rationale:

L017 identified that property-access chains are the most common real-world T3+ miss pattern. This gap is not documented anywhere in known-limitations.md — the existing "Single-File Scope" section mentions cross-file chains but not intra-file property-access chains. Without this entry, future sessions will attribute missed violations to detection failures rather than recognizing the AST architectural gap and the mitigation path already in place.

### Validation:

Verify the new section appears in `known-limitations.md` after "T3+ Detection: Single-File Scope". Cross-check that the referenced mitigation (property-access tracing instruction in deep-mode-detection.md) exists — this is added by Proposal 4.

---

## Proposed Change 10: Unbiased Fixtures Requirement in Rewrite Step 8

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/references/rewrite-instructions.md`
**Change type**: Modify
**Section**: Step 8 — "Generate verification script as intermediate artifact"
**Priority**: Medium
**Source learnings**: L018, G4

### Proposed content:

Replace the existing Step 8 block:

```markdown
    8. Generate verification script as intermediate artifact:
       - Location: tmp/verification/{test-name}-verify.{ext}
       - Purpose: Validate rewrite works before modifying test
       - REQUIRED: Include edge cases from bug-magnet-data in verification
```

With:

```markdown
    8. Generate verification script as intermediate artifact:
       - Location: tmp/verification/{test-name}-verify.{ext}
       - Purpose: Validate rewrite works before modifying test
       - REQUIRED: Include edge cases from bug-magnet-data in verification
       - REQUIRED (UNBIASED FIXTURES): If using a sub-agent to generate the
         verification script, the sub-agent MUST NOT be given access to the
         implementation file being tested. Provide only the interface/contract
         (function signature, expected behavior description, input/output types).
         Rationale: an agent that reads the implementation unconsciously writes
         fixtures that match implementation logic rather than probing real failure
         modes — missing the bugs the rewrite is meant to expose.
         Preferred approach: Use `test-fixture-creation` skill to author the
         verification script. This skill enforces implementation access isolation.
```

### Rationale:

L018 and G4 documented that tests written by the same agent that implemented the code miss real issues because the agent unconsciously aligns fixtures to its own logic. The test-fixture-creation skill (a Sonnet agent that cannot read the implementation) was developed as the correct approach. The rewrite procedure's Step 8 currently says "Generate verification script" without specifying who generates it or whether implementation access must be blocked. For T3+ rewrites in particular, the "correct chain output" is not obvious — it requires genuine isolation to avoid circular reasoning. Adding this requirement closes the gap at the point of use.

### Validation:

Review a rewrite session log where Step 8 was executed. Verify the verification script was generated without the sub-agent receiving the implementation file's contents. Check that test-fixture-creation skill was invoked or that implementation access was explicitly excluded from the sub-agent prompt.

---

## Proposed Change 11: Pass-Through Rationale for AST Injection Blocks

**Target**: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/SKILL.md`
**Change type**: Add
**Section**: Step 4 — immediately before the "AST hints for classification CONTEXT" code block
**Priority**: Low
**Source learnings**: L010, G5

### Proposed content:

Insert the following blockquote immediately before the CONTEXT code block in Step 4 (after the "AST hints for classification CONTEXT:" heading):

```markdown
> **WHY RAW**: Inject AST data as-is — do NOT summarize or compress it before passing
> to the classification sub-agent. Summaries lose field-level precision (particularly
> `ast_verification_lines`) that Haiku requires to avoid falling back to independent
> line-counting. Maximum fidelity in → maximum accuracy out. If AST data is large,
> truncate individual field arrays (e.g., skip marker arrays beyond 20 entries) rather
> than summarizing field values.
```

Also insert an equivalent note in Step 5 (Scale Mode Detection), immediately before the AST metadata injection block:

```markdown
> **WHY RAW**: Pass AST metadata as-is into the detection prompt. Do not summarize
> data-flow violations or integration-mock leads before injection — the detection agent
> needs exact line numbers and variable names for accurate violation scoping.
```

### Rationale:

L010 and G5 observed that the continuous-feedback pipeline's pass-through schema design exists to preserve actionability, and the same principle applies to test-audit's AST injection pattern. Without a rationale note, future maintainers may "optimize" by summarizing AST output before injection — reasoning that smaller prompts are cheaper. This would degrade quality by removing the field-level precision that anchors Haiku's classification (addressed in Proposal 2). The note makes the design intent explicit and gives a concrete alternative (truncate array lengths, not field values) for when size reduction is genuinely needed.

### Validation:

Inspect SKILL.md Step 4 and Step 5 and confirm both blockquote notes are present. No runtime validation needed — this is a documentation/guidance change that prevents future regression.

---

## Notes on Deduplication

The following analysis-level improvements were merged into single proposals:

- **L019 (Pipeline gap) + G2 (Hook Integration warning)**: Both concern the same Hook Integration section of SKILL.md. These were merged into a consolidated note appended to Proposal 3's "What You MUST NOT Do" context, but on review the Hook Integration section (separate from Pre-Flight Gate) requires its own dedicated update. This is tracked as the addendum below.

**Addendum — Hook Integration Gap Pattern (merged from L019/G2):**

This change is included as part of Proposal 3's scope but applied to a different section. Add the following to SKILL.md "Integration Notes > Hook Integration" section, replacing the current two-bullet list:

Target: `/mnt/c/projects/the-bulwark/.claude/skills/test-audit/SKILL.md`
Section: Integration Notes > Hook Integration

```markdown
### Hook Integration

This skill can be triggered by:
1. **Direct invocation:** `/test-audit [path]`
2. **Pipeline hook:** PostToolUse on `*.test.*` files suggests Test Audit pipeline

Both paths use the same orchestration flow.

**WARNING — Pipeline Gap Pattern:** If the pipeline condition for Stage 3b/4b only triggers when a *TestWriter* sub-agent produced output, implementer-authored tests bypass test-audit entirely (TestAudit gap pattern). The correct trigger condition is:

```
IF any new or modified test files exist (from Implementer OR TestWriter OR direct edit):
    → Run test-audit pipeline
```

When updating `pipeline-templates`, always use the widened condition. Never narrow it to a single agent source.
```
