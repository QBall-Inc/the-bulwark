---
run_slug: "test-audit-20260219"
stage: "02-analyze"
specialization: "test-audit"
analyst_model: "sonnet"
items_analyzed: 13
items_skipped: 7
items_skipped_reason: "L007-L012 general/workflow items without test-audit skill_relevance; L020 is prose-count orchestration hygiene not skill-specific"
---

# Test-Audit Skill Analysis — 2026-02-19

## Scope

Items analyzed: L001, L002, L003, L004, L005, L006, L013, L014, L015, L016, L017, L018, L019, L020
Items skipped: L007 (sed/rsync, general), L008 (evaluation gates, general), L009 (session estimates, general), L010 (pass-through schema, general), L011 (critic pattern, general), L012 (pre-alignment, general)

---

## Improvement 1: File-Scope Mock Detection Pattern in known-limitations.md

**What was learned (L001, L004)**
The integration-mock-detector's original design only searched for `jest.mock()` calls *inside* describe blocks. File-scope mocks (declared globally, above any describe) are a distinct pattern: the mock declaration contaminates every integration/e2e section in the file. The fix was a cross-product logic: one T3 lead per file-scope mock per integration/e2e section. Two new AST fixtures were created (file-scope-mocks/router-mixed.test.ts, file-scope-mocks/unit-only.test.ts) to cover this.

**What it affects**
`references/known-limitations.md` — The "Manual Stub Pattern Detection" limitation section does not mention file-scope mocks as a resolved or documented pattern. The entry for this pattern is missing entirely.

**Proposed improvement**
Add a new resolved limitation entry to the `## Resolved Limitations` table in `references/known-limitations.md`:

```markdown
| File-scope mocks invisible to section-scoped AST | File-scope `jest.mock()` cross-product detection: one T3 lead per file-scope mock per integration/e2e section (Step 3b in integration-mock-detector.ts) | P5.12 |
```

Also add a short paragraph to the body of the document before the Resolved table:

```markdown
## File-Scope Mock Detection

**Issue (Resolved):** The integration-mock-detector originally scanned only inside describe blocks. File-scope `jest.mock()` declarations (above all describe blocks) contaminate every integration/e2e section in the file, but were invisible to section-scoped analysis.

**Resolution (P5.12):** Step 3b added to integration-mock-detector.ts. Logic: cross-product of (file-scope mocks) × (integration/e2e sections) = one T3 lead per pair. A file with 2 file-scope mocks and 2 integration sections produces 4 leads. Two AST fixtures validate this pattern.
```

**Priority:** Medium — the AST script already handles this, but the known-limitations doc does not reflect it. Documentation gap only; no behavior change needed.

**Evidence:** L001, L004

---

## Improvement 2: Synthesis Prompt — Deduplication Hardening

**What was learned (L002, L006)**
Double-counting of `affected_lines` is a synthesis-stage LLM issue, not a detection issue. The synthesis agent naively summed per-violation `affected_lines` rather than computing the union of overlapping line ranges. The fix was applied at two layers: mock-detection (file_summaries pre-dedup) and synthesis (effectiveness calculation dedup). The synthesis prompt already has the union instruction, but it does not have binding language preventing the naive sum path.

**What it affects**
`references/prompts/synthesis.md` — The CONSTRAINTS section has the union instruction, but it is phrased as guidance ("merge overlapping/identical ranges") without explicit MUST NOT language for the alternative (naive sum).

**Proposed improvement**
Replace in `references/prompts/synthesis.md` CONSTRAINTS:

Current:
```
- When multiple violations affect the same file, compute affected_lines as the UNION of all
  violation_scope ranges (merge overlapping/identical ranges), NOT the sum of individual
  affected_lines values. Example: two violations both scoped to [228, 269] = 42 affected
  lines total, not 84.
```

Proposed:
```
- When multiple violations affect the same file, compute affected_lines as the UNION of all
  violation_scope ranges (merge overlapping/identical ranges), NOT the sum of individual
  affected_lines values. Example: two violations both scoped to [228, 269] = 42 affected
  lines total, not 84.
- MUST NOT sum individual violation affected_lines values. Summing is ALWAYS wrong and will
  produce inflated effectiveness penalties. The detection stage may pre-deduplicate in
  file_summaries — if so, use that value. If not, you MUST deduplicate before calculating.
- BINDING: If you find yourself adding affected_lines across multiple violations for the
  same file, STOP. Compute the set union of all line ranges first.
```

**Priority:** High — naive summation can inflate penalty counts, causing files to fail Gate 2 that should be advisory-only, or exaggerate how bad a file is in the audit report. This directly affects gate outcomes.

**Evidence:** L002, L006

---

## Improvement 3: Classification Stage — AST Ground Truth Binding for Haiku

**What was learned (L003, L005, L015)**
At scale (14+ files), Haiku takes shortcuts. Without explicit ground truth anchoring, Haiku reported `verification_lines = total_lines` for some files (e.g., knowledge-linker.test.ts: 571/571). The fix was to declare AST-provided `verification_lines` as mandatory ground truth and eliminate Haiku's independent counting path entirely.

**What it affects**
`SKILL.md` — Step 4 (Classification Stage) injects AST hints with "Use this to improve classification accuracy" language. This is advisory, not binding. The Haiku sub-agent can still fall back to independent counting.

**Proposed improvement**
In `SKILL.md`, Step 4, update the "AST hints for classification CONTEXT" block. Change the preamble from:

```
The following AST-computed metadata is available for each file.
Use this to improve classification accuracy — these are deterministic,
not heuristic.
```

To:

```
The following AST-computed metadata is MANDATORY ground truth for each file.
You MUST use ast_verification_lines as the verification_lines value — do NOT
re-count independently. AST line counts are deterministic; your re-count is not.
MUST NOT report verification_lines = total_lines — this indicates you re-counted
instead of using AST data. If AST data is missing for a file, set
verification_lines_source: "heuristic" and note it in diagnostics.
```

**Priority:** High — inflated verification_lines cause understated effectiveness percentages. A file that is 40% effective looks like 100% if verification_lines echoes total_lines. This silently suppresses Gate 2 triggers, letting bad test suites pass the audit without rewrite.

**Evidence:** L003, L005, L015

---

## Improvement 4: Violation Scope Variance — Documented in known-limitations.md

**What was learned (L013)**
The same T3 violation can produce different `affected_lines` values (19 vs 8) across two Sonnet runs, depending on whether the agent includes assertions that *use* mock return values in the affected scope. This variance can flip Gate 2 outcomes. It is not a data pipeline bug — it is inherent LLM judgment variance in scope interpretation.

**What it affects**
`references/known-limitations.md` — This is an undocumented active limitation. There is no entry for it.

**Proposed improvement**
Add a new active limitation section to `references/known-limitations.md`:

```markdown
## Violation Scope Variance (LLM Judgment)

**Issue:** The detection agent (Sonnet) may report different `affected_lines` values for the same T3 violation across runs. The variance arises from whether the agent includes assertions that consume mock return values in the violation scope. Observed range: 19 lines vs 8 lines for identical code.

**Impact:** Scope variance can flip Gate 2 outcomes. A file may be above or below the 95% effectiveness threshold on different runs. This is nondeterministic.

**Mitigation:** AST-computed verification_lines provide a fixed denominator. The numerator (affected_lines) remains subject to LLM variance. The diagnostics log records `verification_lines_source: ast | heuristic` — use this to assess denominator reliability. For scope disputes, accept the higher affected_lines value (more conservative) to avoid false Gate 2 passes.

**Future:** Consider AST-based affected_lines computation (deferred to P6+). Requires tracking which assertion lines reference mocked variables.
```

**Priority:** Medium — currently only monitored. Documenting it helps future sessions recognize the pattern instead of re-investigating it as a bug.

**Evidence:** L013

---

## Improvement 5: Instruction Hardening — AST Re-Classification Prevention

**What was learned (L014)**
Without explicit "AST classification is final" language, LLMs dismiss T3 leads by re-classifying sections as "actually unit tests." The fix was already applied to `deep-mode-detection.md` and mock-detection's SKILL.md. The binding language in `deep-mode-detection.md` is strong and clear.

**What it affects**
`SKILL.md` — The main orchestration SKILL.md does not contain equivalent binding language in its own Pre-Flight Gate or orchestration instructions. An orchestrator reading only SKILL.md (without loading the sub-agent prompt) could still rationalize skipping T3 leads. The "Why This Matters" section in the Pre-Flight Gate does not address re-classification specifically.

**Proposed improvement**
Add to `SKILL.md` Pre-Flight Gate, under "What You MUST NOT Do":

```markdown
- **Do NOT dismiss AST T3 leads by re-classifying sections** — If the AST classifies a section as integration or e2e, that classification is FINAL. You MUST pass that lead to the detection stage. Rationalizing that a section is "actually a unit test" to dismiss an AST lead is a rule violation.
- **Do NOT override AST verification_lines** — AST-computed line counts are ground truth. Do not substitute heuristic estimates or Haiku's independent counts.
```

**Priority:** High — the rule exists in sub-agent prompts but not in the orchestrator's own binding section. An orchestrator can violate this before spawning any sub-agents.

**Evidence:** L014

---

## Improvement 6: Inline Object False Positive — Detection Documentation

**What was learned (L016)**
`createOrder({ customerId: 'x' })` is NOT a T3 violation. Inline object literals used as function arguments start a chain rather than replacing upstream output. Only variables assigned from literal construction that replace real upstream function output are T3+. This distinction is easy to misapply.

**What it affects**
The mock-detection skill's false-positive-prevention reference (referenced in `deep-mode-detection.md`). The `deep-mode-detection.md` prompt points to it, but the distinction about inline objects as input params is not surfaced in `SKILL.md` or the synthesis prompt.

**Proposed improvement**
Add a clarification note to `references/prompts/synthesis.md` CONSTRAINTS:

```markdown
- Inline object literals used as function arguments are NOT T3+ violations:
  `createOrder({ customerId: 'x' })` starts a chain — the literal is input, not replacement.
  T3+ applies only when a variable is assigned from literal construction and that variable
  *replaces* what should be real upstream function output.
  Example of a violation: `const orderData = { id: 'mock-123', ... }; processOrder(orderData)`
  where orderData should have come from `createOrder()`.
```

This surfaces the distinction at synthesis time, preventing false positive P0 classifications in the final report.

**Priority:** Medium — false positives at synthesis produce incorrect REWRITE_REQUIRED decisions. A non-violating file flagged as P0 triggers unnecessary rewrites.

**Evidence:** L016

---

## Improvement 7: Property-Access Tracing — Known Limitation and AST Enhancement Note

**What was learned (L017)**
Real-world T3 violations propagate through property access: `mockOrder.id` inside a new object literal, not `fn(mockOrder)` directly. Without property-access tracing, the AST data-flow-analyzer misses this pattern. The contamination chain is: mock declaration → property access → property used in literal construction → literal passed to tested code.

**What it affects**
`references/known-limitations.md` — This gap is not documented. The "T3+ Detection: Single-File Scope" section mentions cross-file chains but not property-access chains within the same file.

**Proposed improvement**
Expand the "T3+ Detection: Single-File Scope" section in `references/known-limitations.md`:

```markdown
## T3+ Detection: Property-Access Chain Gap

**Issue:** AST data-flow-analyzer traces direct variable usage (e.g., `fn(mockOrder)`) but does not trace property-access chains. When mock data propagates via property access (`mockOrder.id` used inside a new object literal), the AST does not follow the contamination path.

**Impact:** The pattern `const payload = { orderId: mockOrder.id, ... }; processOrder(payload)` is a T3+ violation but the AST reports no lead. The detection Sonnet agent must catch this via call graph analysis.

**Mitigation:** Deep mode detection prompt instructs the agent to use call graph analysis beyond AST leads. The phrase "Validate AST leads and add any the AST missed" covers this path. However, the agent must proactively look for property-access chains — it is not guaranteed without explicit instruction.

**Future:** Extend data-flow-analyzer.ts to trace `MemberExpression` nodes as tainted when the object is a known mock variable (deferred to P6+).
```

Additionally, add to `references/prompts/deep-mode-detection.md` CONSTRAINTS:

```markdown
- When tracing T3+ violations, follow property-access chains: if `mockOrder` is a mock variable,
  then `mockOrder.id` is also tainted. If `mockOrder.id` is embedded in a new object literal
  that is passed to the tested function, that is a T3+ violation even if the AST did not flag it.
  The contamination path: mock → property access → literal construction → SUT input.
```

**Priority:** High — property-access chains are the most common real-world T3+ pattern. Without this instruction, the detection agent catches fewer real violations than it should.

**Evidence:** L017

---

## Improvement 8: Unbiased Fixtures Requirement — Rewrite Instructions

**What was learned (L018)**
Tests written by the same agent that implemented the code miss real issues because the agent unconsciously writes tests matching its own implementation logic. The test-fixture-creation skill (a Sonnet agent that cannot read the implementation) is the correct approach for validation fixtures.

**What it affects**
`references/rewrite-instructions.md` — The rewrite procedure generates a verification script (step 8) and rewrites the test. There is no instruction that the fixtures or verification inputs must be created without reading the implementation being tested.

**Proposed improvement**
Add to `references/rewrite-instructions.md` after step 8:

```markdown
   8b. If verification script requires fixture data (input values, expected outputs), use
       the `test-fixture-creation` skill to generate unbiased fixtures. The fixture-creation
       agent MUST NOT read the implementation file being tested. Rationale: an agent that
       reads the implementation unconsciously aligns fixtures to its logic, missing real bugs.
       This applies to any fixture that represents "what a real upstream function would return"
       in a T3+ rewrite.
```

**Priority:** Medium — applies to the rewrite path only (Step 9). Incorrect fixtures in rewrites validate the wrong behavior, defeating the purpose of the rewrite. Critical for T3+ rewrites where the correct chain output is not obvious.

**Evidence:** L018

---

## Improvement 9: Pipeline Gate Condition — TestAudit Trigger Documentation

**What was learned (L019)**
When the implementer writes tests (without going through TestWriter), the TestAudit stage was being skipped because the pipeline condition checked only for TestWriter output. The fix widened Stage 3b/4b to trigger on any new/modified tests from Implementer OR TestWriter.

**What it affects**
`SKILL.md` — The "Hook Integration" section mentions that PostToolUse on `*.test.*` files suggests Test Audit pipeline. But it does not specify that direct implementer test writes must also trigger the audit path. A pipeline template that only gates on TestWriter output would silently bypass test-audit for implementer-authored tests.

**Proposed improvement**
Add to `SKILL.md` Integration Notes, Hook Integration section:

```markdown
**TestAudit trigger condition (IMPORTANT):** The pipeline stage that invokes test-audit MUST trigger on test file modifications from ANY source — implementer, TestWriter, or direct edit. Conditioning on TestWriter output only causes implementer-authored tests to bypass auditing entirely (TestAudit gap pattern). The condition must be: `new or modified *.test.* files exist, regardless of which agent created them`.
```

**Priority:** Medium — affects pipeline configuration, not the test-audit skill's own logic. But documenting it here prevents the gap from reappearing when pipeline-templates are updated.

**Evidence:** L019

---

## Improvement 10: Prose Count Precision — Orchestration Instructions

**What was learned (L020)**
When the orchestrator is told to "run all three" scripts but four commands appear in the code block, the LLM stops at three and skips the fourth. Prose counts must exactly match code block item counts.

**What it affects**
`SKILL.md` — Step 2 (Stage 0 AST Pre-Processing) has this issue. The prose says "Run all four AST scripts via Justfile recipes" and the code block has four commands — this is currently correct. However, the Pre-Flight Gate MUST DO list says "Run Stage 0 AST scripts" and lists three bullets (verify-count, skip-detect, ast-analyze) but SKILL.md Step 2 has four commands (including integration-mocks). This is a mismatch.

**Proposed improvement**
Update the Pre-Flight Gate "What You MUST Do" Step 1 in `SKILL.md`:

Current:
```markdown
1. **Run Stage 0 AST scripts** before any LLM stages:
   - `just verify-count {target}` → `/tmp/claude/ast-verify-count.json`
   - `just skip-detect {target}` → `/tmp/claude/ast-skip-detect.json`
   - `just ast-analyze {target}` → `/tmp/claude/ast-data-flow.json`
```

Proposed:
```markdown
1. **Run all four Stage 0 AST scripts** before any LLM stages:
   - `just verify-count {target}` → `/tmp/claude/ast-verify-count.json`
   - `just skip-detect {target}` → `/tmp/claude/ast-skip-detect.json`
   - `just ast-analyze {target}` → `/tmp/claude/ast-data-flow.json`
   - `just integration-mocks {target}` → `/tmp/claude/ast-integration-mocks.json`
```

This makes the bullet count (4) match the prose number ("four") and matches Step 2's actual command list.

**Priority:** Medium — the mismatch could cause an orchestrator reading the Pre-Flight Gate to skip `just integration-mocks`, which is required for file-scope mock detection (Improvement 1 above).

**Evidence:** L020

---

## Summary Table

| # | Improvement | Priority | Affects | Learning IDs |
|---|-------------|----------|---------|--------------|
| 1 | File-scope mock detection — add to known-limitations.md | Medium | known-limitations.md | L001, L004 |
| 2 | Synthesis dedup — MUST NOT sum binding language | High | prompts/synthesis.md | L002, L006 |
| 3 | Haiku classification — AST ground truth binding | High | SKILL.md Step 4 | L003, L005, L015 |
| 4 | Violation scope variance — document active limitation | Medium | known-limitations.md | L013 |
| 5 | AST re-classification prevention — Pre-Flight Gate hardening | High | SKILL.md Pre-Flight Gate | L014 |
| 6 | Inline object false positive — synthesis constraint | Medium | prompts/synthesis.md | L016 |
| 7 | Property-access tracing — limitation doc + detection prompt | High | known-limitations.md + prompts/deep-mode-detection.md | L017 |
| 8 | Unbiased fixtures for rewrites | Medium | references/rewrite-instructions.md | L018 |
| 9 | Pipeline gate condition — TestAudit gap pattern | Medium | SKILL.md Integration Notes | L019 |
| 10 | Prose count precision — Pre-Flight Gate bullet count | Medium | SKILL.md Pre-Flight Gate | L020 |

**High priority count:** 4 (Improvements 2, 3, 5, 7)
**Medium priority count:** 6 (Improvements 1, 4, 6, 8, 9, 10)
**Low priority count:** 0
