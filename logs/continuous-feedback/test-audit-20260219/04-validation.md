# Validation Annotations — test-audit-20260219

## Overview

Each proposal targets a skill asset (`.md` file in `skills/test-audit/` or `.claude/skills/test-audit/`). All proposals require `/anthropic-validator` after applying.

---

## Per-Proposal Validation Steps

### Proposal 1: Synthesis Dedup — MUST NOT Sum Binding Language
- **Target**: `references/prompts/synthesis.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: Run `/test-audit` against a file with overlapping violation scopes; verify synthesis output shows union-based `affected_lines`, not naive sum.

### Proposal 2: Haiku Classification — AST Ground Truth Binding in Step 4
- **Target**: `SKILL.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: Run `/test-audit` in Scale mode (14+ files); verify no file has `verification_lines == total_lines` in classification output unless genuinely 100% test logic.

### Proposal 3: AST Re-Classification Prevention — Pre-Flight Gate Hardening
- **Target**: `SKILL.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: Run `/test-audit` against a file with AST-classified integration sections; verify all integration-mock leads pass through to detection without filtering.

### Proposal 4: Property-Access Tracing — Detection Prompt Instruction
- **Target**: `references/prompts/deep-mode-detection.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: Run `/test-audit` (Deep mode) against a file with `mockOrder.id` embedded in a payload object; verify detection catches the T3+ violation.

### Proposal 5: Prose/Code Count Hardening — Pre-Flight Gate + Step 2
- **Target**: `SKILL.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: Run `/test-audit` and verify all 4 AST scripts execute (check for `ast-integration-mocks.json` existence in `/tmp/claude/`).

### Proposal 6: File-Scope Mock Detection — Resolved Limitation Entry
- **Target**: `references/known-limitations.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: N/A (documentation of resolved limitation). Verify cross-reference to `integration-mock-detector.ts` Step 3b is accurate.

### Proposal 7: Violation Scope Variance — Active Limitation Entry
- **Target**: `references/known-limitations.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: N/A (documentation of known limitation). Informational — no runtime behavior change.

### Proposal 8: Inline Object False Positive — Synthesis Constraint
- **Target**: `references/prompts/synthesis.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: Run `/test-audit` against a file containing `createOrder({ customerId: 'x' })`; verify synthesis does not classify the inline argument literal as a T3+ violation.

### Proposal 9: Property-Access Chain Gap — Known Limitation Entry
- **Target**: `references/known-limitations.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: N/A (documentation of known limitation). Verify cross-reference to Proposal 4's deep-mode-detection.md instruction is accurate.

### Proposal 10: Unbiased Fixtures Requirement in Rewrite Step 8
- **Target**: `references/rewrite-instructions.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: In next rewrite session, verify Step 8 enforces implementation-access isolation for verification script generation.

### Proposal 11: Pass-Through Rationale for AST Injection Blocks
- **Target**: `SKILL.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: N/A (documentation/guidance change). No runtime behavior change.

### Addendum: Hook Integration Gap Pattern
- **Target**: `SKILL.md` (skill asset)
- **After applying**: Run `/anthropic-validator` on `.claude/skills/test-audit/`
- **Functional test**: Verify pipeline-templates use widened trigger condition (Implementer OR TestWriter OR direct edit).

---

## Summary

- **All 11 proposals + 1 addendum** target skill assets (`.md` files)
- **Common validation**: Run `/anthropic-validator` on `.claude/skills/test-audit/` after applying each change
- **Functional tests**: 6 proposals have concrete runtime tests (1, 2, 3, 4, 5, 8); 5 are documentation-only (6, 7, 9, 10, 11); 1 is pipeline-config (addendum)
