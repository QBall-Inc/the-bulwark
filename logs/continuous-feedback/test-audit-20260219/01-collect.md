---
run_slug: "test-audit-20260219"
target: "test-audit"
sources:
  session_handoffs: "10"
  memory_files: "1"
  custom_paths: "0"
since: "session-57"
total_items: "20"
skill_types_detected:
  - "test-audit"
  - "general"
---

# Collected Learnings — test-audit

## Collection Summary

| Source Type | Files Scanned | Items Extracted |
|-------------|---------------|-----------------|
| Session handoffs | 10 | 12 |
| MEMORY.md | 1 | 8 |
| Agent memory | 0 | 0 |
| Custom paths | 0 | 0 |

**Skill types detected in learnings**: test-audit, general

## Learning Items

```yaml
items:
  - id: L001
    source: "sessions/session_57_20260215.md"
    section: "## Learnings"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      File-scope mocks are invisible to section-scoped AST: The original
      integration-mock-detector only looked inside describe blocks. File-scope
      jest.mock() is a different pattern — the mock is declared globally but
      contamination is per-section. Requires cross-reference logic. Fix: create
      one T3 lead per file-scope mock per integration/e2e section (cross-product).
      A file with 2 file-scope mocks and 2 integration sections produces 4 leads.

  - id: L002
    source: "sessions/session_57_20260215.md"
    section: "## Learnings"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      Double-counting is a LLM synthesis issue, not detection: The detection agent
      correctly reports per-violation scope. The synthesis agent naively sums them.
      Adding an explicit union dedup instruction fixes it without changing the
      detection output schema. Fix applied at two layers: mock-detection
      (file_summaries pre-dedup) and synthesis (effectiveness calculation dedup).
      Defense in depth — synthesis must also handle it in case detection doesn't.

  - id: L003
    source: "sessions/session_57_20260215.md"
    section: "## Learnings"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      Haiku verification_lines unreliable without AST anchoring: At scale (14+
      files), Haiku takes shortcuts. Without explicit ground truth, Haiku may echo
      total_lines instead of counting correctly (e.g., knowledge-linker.test.ts:
      571/571). Fix: Provide AST data as MANDATORY ground truth. Classification
      Haiku must use AST-provided verification_lines, not re-count. AST is
      deterministic; Haiku's heuristic counting path is eliminated entirely.

  - id: L004
    source: "sessions/session_57_20260215.md"
    section: "## Technical Decisions"
    category: architecture-decision
    skill_relevance:
      - test-audit
    content: |
      File-Scope Mock Detection Architecture: Create one T3 lead per file-scope
      mock per integration/e2e section (cross-product). Each file-scope mock
      independently contaminates each integration section. Added Step 3b
      file-scope mock detection to integration-mock-detector.ts. Impact: increases
      AST precision for mixed-type files like router.test.ts. Two new fixtures
      created (file-scope-mocks/router-mixed.test.ts, file-scope-mocks/unit-only.test.ts)
      with 8 new tests covering this pattern.

  - id: L005
    source: "sessions/session_57_20260215.md"
    section: "## Technical Decisions"
    category: architecture-decision
    skill_relevance:
      - test-audit
    content: |
      AST Verification Lines as Ground Truth in Classification: Classification
      Haiku must use AST-provided verification_lines, not re-count independently.
      Rationale: Haiku sometimes echoes total_lines instead of counting correctly.
      AST output is deterministic. Updated test-classification/SKILL.md to use AST
      verification_lines as mandatory ground truth. Prevents effectiveness inflation
      like knowledge-linker.test.ts (571/571 case).

  - id: L006
    source: "sessions/session_57_20260215.md"
    section: "## Technical Decisions"
    category: architecture-decision
    skill_relevance:
      - test-audit
    content: |
      Affected Lines Deduplication — Two-Layer Fix: Added dedup instruction to
      both mock-detection (file_summaries) and synthesis (effectiveness
      calculation). Defense in depth — mock-detection should pre-deduplicate,
      but synthesis must also handle it in case detection doesn't. Prevents
      effectiveness inflation when multiple violations share the same scope.

  - id: L007
    source: "sessions/session_58_20260215.md"
    section: "## Technical Decisions"
    category: defect-pattern
    skill_relevance:
      - general
    content: |
      Cascading sed pattern collision: When multiple sed transforms share prefix
      patterns (e.g., __dirname, '..'), earlier transforms create text that later
      transforms re-match. Fix: use non-overlapping patterns unique to each target
      line rather than ordering by specificity. Non-overlapping patterns (4-parent
      chain, 'node_modules', .ts filename) are deterministic regardless of execution
      order. Applied in sync-essential-skills.sh for test path transforms.

  - id: L008
    source: "sessions/session_60_20260216.md"
    section: "## Technical Decisions"
    category: architecture-decision
    skill_relevance:
      - general
    content: |
      Critical Evaluation Gate prevents blind incorporation: Without classification,
      orchestrator blindly incorporates unvalidated user suggestions into synthesis.
      Gate classifies input (Factual/Opinion/Speculative for research;
      Preference/Technical Claim/Architectural Suggestion for brainstorm) and spawns
      targeted follow-up agents for unvalidated claims. Research uses Direct
      Investigation + Contrarian (2 Sonnet) for speculative claims; Brainstorm uses
      Architect + Critic (2 Opus) for technical claims/architectural suggestions.

  - id: L009
    source: "sessions/session_66_20260219.md"
    section: "## Technical Decisions"
    category: workflow-improvement
    skill_relevance:
      - general
    content: |
      Session estimates need validation tax: Every skill implementation needs a
      validation session. Pattern: Session 1 = author skill + validator + fixtures
      + test protocol. Session 2 = user tests, reports back, we fix. Original
      single-session estimates for P5.3/P5.4/P5.5 omitted validation sessions and
      were consistently too optimistic. All remaining P5 tasks revised upward;
      total 11 implementation sessions (was 8).

  - id: L010
    source: "sessions/session_63_20260217.md"
    section: "## Technical Decisions"
    category: architecture-decision
    skill_relevance:
      - general
    content: |
      Pass-Through Schema: Collector preserves near-raw content. Analyzers handle
      interpretation. Maximum fidelity. Addresses concern about lossy intermediate
      formats destroying actionability. Higher token consumption in Analyze stage,
      but avoids quality-destroying compression. Applied in continuous-feedback
      pipeline design for the Collect stage.

  - id: L011
    source: "sessions/session_65_20260218.md"
    section: "## Learnings"
    category: workflow-improvement
    skill_relevance:
      - general
    content: |
      Critic breaks groupthink effectively: All 4 non-Critic agents recommended
      "proceed." The Critic's MODIFY verdict with specific kill criteria and the
      "comparative test first" recommendation added genuine corrective value. The
      user selectively adopted Critic insights (role count, framing) while
      overriding timing. Pattern: Critic challenges improve outcome even when
      overridden, because specific failure modes directly shape the final design.

  - id: L012
    source: "sessions/session_66_20260219.md"
    section: "## Learnings"
    category: workflow-improvement
    skill_relevance:
      - general
    content: |
      Pre-brainstorm alignment eliminates post-synthesis rounds: Extensive
      pre-brainstorm discussion (settled decisions, focused questions, review of
      prior artifacts) meant the post-synthesis review needed only 1 round of 4
      questions, all classified as Preference. Same pattern as Session 65.
      Compare to Session 63 which had more post-synthesis rounds without
      pre-alignment.

  - id: L013
    source: "memory/MEMORY.md"
    section: "## Defects & Lessons Learned"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      Violation scope variance across runs: Same T3 violation can get different
      affected_lines (19 vs 8) from two Sonnet runs depending on whether assertions
      using mock return values are included in scope. This can flip gate outcomes.
      Known LLM judgment variance, not a data pipeline bug. Monitor for impact on
      effectiveness calculations.

  - id: L014
    source: "memory/MEMORY.md"
    section: "## Defects & Lessons Learned"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      BINDING language prevents LLM re-classification: Without explicit "AST
      classification is final" language, LLM dismisses T3 leads by re-classifying
      sections as "actually unit". Fix: Added "AST classification is final" to both
      deep-mode-detection.md prompt AND mock-detection/SKILL.md for two-path
      reinforcement. Without this binding language, the LLM substitutes its own
      judgment over AST output.

  - id: L015
    source: "memory/MEMORY.md"
    section: "## Defects & Lessons Learned"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      Haiku verification_lines inflation: In Scale mode classification, Haiku may
      report verification_lines = total_lines for some files (e.g.,
      knowledge-linker.test.ts: 571/571). Monitor — could affect effectiveness
      calculations if violations found in such files. Root cause: Haiku takes
      shortcuts at scale without AST-anchored ground truth.

  - id: L016
    source: "memory/MEMORY.md"
    section: "## Defects & Lessons Learned"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      Inline objects are input params, not violations: createOrder({ customerId: 'x' })
      starts a chain. T3+ violations are variables constructed as literals replacing
      upstream output. The distinction matters: inline object literals used as
      function arguments are NOT T3 violations. Only variables assigned from
      literal construction that replace real upstream function output are violations.

  - id: L017
    source: "memory/MEMORY.md"
    section: "## Defects & Lessons Learned"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      Property-access tracing needed: Real code uses mockOrder.id inside new
      objects, not fn(mockOrder) directly. Without property-access tracing, the
      AST analyzer misses most real-world T3 violations. The contamination path
      goes: mock declaration → property access → property used in literal
      construction → literal passed to tested code. Tracing this chain is required
      for accurate detection.

  - id: L018
    source: "memory/MEMORY.md"
    section: "## Defects & Lessons Learned"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      Unbiased fixtures essential: Use test-fixture-creation skill (Sonnet agent
      that cannot read implementation) for validation fixtures. Automated tests
      written by the same agent miss real issues because the agent unconsciously
      writes tests matching its own implementation logic. Unbiased fixture
      creation requires a separate agent with no access to the implementation code.

  - id: L019
    source: "memory/MEMORY.md"
    section: "## Defects & Lessons Learned"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      TestAudit gap pattern: When implementer writes tests, TestWriter skips,
      cascading to TestAudit skip. Fixed by widening Stage 3b/4b condition to
      trigger on any new/modified tests from Implementer OR TestWriter. Applied
      to both fix-validation and new-feature pipelines. Without this widening,
      implementer-authored tests bypass the test audit pipeline entirely.

  - id: L020
    source: "memory/MEMORY.md"
    section: "## Critical Findings (Sessions 40-45)"
    category: defect-pattern
    skill_relevance:
      - test-audit
    content: |
      Prose/code count mismatch matters: "Run all three" with 4 commands caused
      orchestrator to skip 4th script. Always keep prose counts matching code
      blocks exactly. When describing multiple scripts to run in test-audit
      context, the number stated in prose must exactly match the number of
      commands in the code block, or the LLM orchestrator will stop at the
      stated count and skip remaining items.
```

## Notes

Sessions 59–66 are primarily research/brainstorm sessions with minimal test-audit-specific content. The substantive test-audit learnings are concentrated in Session 57 (the last robustness-fix session for P5.10-12) and the MEMORY.md entries from earlier P5 work. Items L007–L012 are workflow/general learnings with indirect applicability to test-audit skill authoring and pipeline robustness.
