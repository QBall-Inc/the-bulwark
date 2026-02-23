# P5.10-12 Manual Test Protocol - Test Audit Hardening (Dual-Mode + AST)

**Purpose**: Verify the restructured test-audit skill with dual-mode architecture, Stage 0 AST pre-processing, reference file loading, and sub-agent orchestration.
**Prerequisite**: P5.10-12 implementation complete (Phases 1-4), skill synced to `.claude/skills/test-audit/`.
**Test data**: Real test files from `clear-framework` project at `/mnt/c/projects/clear-framework/tests/infrastructure/sync/`.

---

## Pre-Test Setup

1. Sync skill to `.claude/skills/` for dogfooding:
   ```bash
   rsync -av --delete skills/test-audit/ .claude/skills/test-audit/
   ```

2. Verify skill is loadable:
   ```bash
   ls .claude/skills/test-audit/SKILL.md
   ls .claude/skills/test-audit/references/prompts/deep-mode-detection.md
   ls .claude/skills/test-audit/references/prompts/synthesis.md
   ls .claude/skills/test-audit/references/schemas/audit-output.yaml
   ls .claude/skills/test-audit/references/schemas/diagnostic-output.yaml
   ls .claude/skills/test-audit/references/priority-classification.md
   ls .claude/skills/test-audit/references/known-limitations.md
   ls .claude/skills/test-audit/references/rewrite-instructions.md
   ```

3. Verify AST scripts are operational:
   ```bash
   just verify-count tests/  # Should produce JSON output (or error if no test files in Bulwark)
   just skip-detect tests/
   just ast-analyze tests/
   ```

4. Verify AST script dependencies installed:
   ```bash
   ls skills/test-audit/scripts/node_modules/ts-morph/
   ```

5. Ensure `logs/` directory structure exists:
   ```bash
   mkdir -p logs/diagnostics
   ```

6. Verify clear-framework test files accessible:
   ```bash
   ls /mnt/c/projects/clear-framework/tests/infrastructure/sync/*.test.ts | wc -l
   # Expected: 14 files
   ```

7. Start a **fresh Claude Code session** (separate from this one)

8. Verify governance protocol appears (SessionStart hook working)

---

## Test Data Overview

**Source**: `/mnt/c/projects/clear-framework/tests/infrastructure/sync/`

| File | Lines | Notable Characteristics |
|------|-------|------------------------|
| `e2e.test.ts` | 831 | Real fs operations, multi-step lifecycle, large setup fixtures |
| `session-sync.test.ts` | 345 | Real fs + tmpdir, clean assertions |
| `error-handler.test.ts` | 628 | 13 mock patterns (jest.spyOn, mockImplementation) — likely T1/T2/T3 violations |
| `sync-lifecycle.test.ts` | 304 | Integration-style lifecycle test |
| `debug-cli.test.ts` | 886 | Largest file, CLI testing patterns |
| `knowledge-linker.test.ts` | 858 | Complex integration patterns |
| `plan-rollup.test.ts` | 847 | Data-heavy aggregation tests |
| `plan-propagate.test.ts` | 705 | Cross-domain propagation |
| `deprecation.test.ts` | 475 | Deprecation workflow testing |
| `types.test.ts` | 488 | Type validation tests |
| `audit-log.test.ts` | 425 | Audit trail tests |
| `sync-state-manager.test.ts` | 464 | State management, has manually constructed test data |
| `sync-infrastructure.test.ts` | 273 | Infrastructure integration |
| `sync-workflows.test.ts` | 345 | Workflow chain tests |

**Total**: 14 files, 7874 lines

**Known violation signals**:
- `error-handler.test.ts`: 13 mock patterns (jest.spyOn, mockImplementation)
- `sync-state-manager.test.ts`: manually constructed test data objects
- No `.skip`/`.only`/`.todo` markers found (T4 clean)

---

# P5.10-12 Test Audit Tests

## Test P5.10-1: Deep Mode — Slash Command Invocation (≤5 files)

**Target**: 3 specific test files from clear-framework (triggers Deep mode)

**Prompt** (slash command):
```
/test-audit /mnt/c/projects/clear-framework/tests/infrastructure/sync/e2e.test.ts /mnt/c/projects/clear-framework/tests/infrastructure/sync/session-sync.test.ts /mnt/c/projects/clear-framework/tests/infrastructure/sync/error-handler.test.ts

/test-audit /mnt/c/projects/clear-framework/tests/infrastructure/sync/plan-propagate.test.ts /mnt/c/projects/clear-framework/tests/infrastructure/sync/sync-state-manager.test.ts /mnt/c/projects/clear-framework/tests/infrastructure/sync/error-handler.test.ts /mnt/c/projects/clear-framework/tests/infrastructure/sync/sync-lifecycle.test.ts
```

**Expected Behavior**:
1. Skill loads and Pre-Flight Gate acknowledged
2. Stage 0 runs all three AST scripts (`just verify-count`, `just skip-detect`, `just ast-analyze`)
3. AST output files written to `/tmp/claude/ast-*.json`
4. Mode selected: **Deep** (3 files ≤ default threshold 5)
5. Mode selection displayed to user with AST status
6. Classification stage **skipped** (Deep mode)
7. Detection sub-agent spawned (Sonnet, `general-purpose`) with Deep Mode Detection Prompt from `references/prompts/deep-mode-detection.md`
8. Detection agent self-computes classification metadata per file
9. Detection agent analyzes ALL 3 files (no filtering)
10. Detection output written to `logs/mock-detection-*.yaml`
11. Synthesis sub-agent spawned (Sonnet, `general-purpose`) with Synthesis Prompt from `references/prompts/synthesis.md`
12. Synthesis output written to `logs/test-audit-*.yaml`
13. Diagnostic output written to `logs/diagnostics/test-audit-*.yaml`
14. Summary displayed to user with violation counts and REWRITE_REQUIRED status

**Verification**:
- [ ] Skill loaded (test-audit appears in context)
- [ ] Pre-Flight Gate acknowledged (STOP language visible in orchestrator flow)
- [ ] Stage 0 AST scripts executed (3 `just` commands ran)
- [ ] AST output files exist in `/tmp/claude/ast-*.json` (or graceful degradation logged)
- [ ] Mode displayed as **Deep** with file count and threshold
- [ ] AST status displayed (verify-count: ok/failed, skip-detect: ok/failed, ast-analyze: ok/failed)
- [ ] Classification stage NOT spawned (Deep mode skips it)
- [ ] Detection sub-agent spawned as `general-purpose` with `model="sonnet"`
- [ ] Detection prompt includes self-classification instructions (Deep mode specific)
- [ ] Detection prompt includes AST metadata per file (verification_lines, skip_markers, data_flow_leads)
- [ ] Detection output at `logs/mock-detection-*.yaml`
- [ ] Synthesis sub-agent spawned as `general-purpose` with `model="sonnet"`
- [ ] Synthesis output at `logs/test-audit-*.yaml`
- [ ] Diagnostic output at `logs/diagnostics/test-audit-*.yaml`
- [ ] Diagnostic includes `mode: deep`, `stages_skipped: ["classification"]`
- [ ] Summary includes: files audited, files analyzed, effectiveness %, violation counts by priority
- [ ] REWRITE_REQUIRED status displayed
- [ ] `error-handler.test.ts` flagged for mock violations (13 mock patterns expected)

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**:

---

## Test P5.10-2: Scale Mode — Slash Command Invocation (>5 files)

**Target**: Full sync directory (14 files, triggers Scale mode)

**Prompt** (slash command):
```
/test-audit /mnt/c/projects/clear-framework/tests/infrastructure/sync/
```

**Expected Behavior**:
1. Skill loads and Pre-Flight Gate acknowledged
2. Stage 0 runs all three AST scripts on the directory
3. Mode selected: **Scale** (14 files > default threshold 5)
4. Classification sub-agent spawned (Haiku, `general-purpose`)
5. Classification includes AST hints in CONTEXT (verify-count + skip-detect per file)
6. Classification output written to `logs/test-classification-*.yaml`
7. Detection sub-agent spawned (Sonnet) — only flagged files analyzed
8. Detection may batch if >10 files flagged
9. Synthesis sub-agent spawned (Sonnet)
10. All log files written

**Verification**:
- [ ] Mode displayed as **Scale** with 14 files, threshold 5
- [ ] Classification sub-agent spawned as `general-purpose` with `model="haiku"`
- [ ] Classification prompt includes AST hints per file
- [ ] Classification output at `logs/test-classification-*.yaml`
- [ ] Classification output contains `files` array with per-file `needs_deep_analysis` flags
- [ ] Detection sub-agent spawned for flagged files only (not all 14)
- [ ] Detection output at `logs/mock-detection-*.yaml`
- [ ] Synthesis sub-agent spawned
- [ ] Synthesis output at `logs/test-audit-*.yaml`
- [ ] Diagnostic output at `logs/diagnostics/test-audit-*.yaml`
- [ ] Diagnostic includes `mode: scale`, classification stage listed as completed
- [ ] Summary displayed with full pipeline results
- [ ] `error-handler.test.ts` in flagged files (has 13 mock patterns)

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**:

---

## Test P5.10-3: Conversational Invocation (Deep Mode)

**Target**: 2 test files via natural language prompt (triggers Deep mode)

**Prompt** (conversational):
```
Can you audit the test quality of these two test files from the clear-framework project?
- /mnt/c/projects/clear-framework/tests/infrastructure/sync/error-handler.test.ts
- /mnt/c/projects/clear-framework/tests/infrastructure/sync/session-sync.test.ts

I'm particularly interested in whether they're using too many mocks and if the tests are actually verifying real behavior.
```

**Expected Behavior**:
1. Claude recognizes this as a test audit request and loads test-audit skill
2. Follows full pipeline (Stage 0 → Deep mode → Detection → Synthesis)
3. Responds to user's specific concern about mocking in the summary

**Verification**:
- [ ] test-audit skill auto-loaded (not manually invoked via `/test-audit`)
- [ ] Full pipeline executed (not Claude doing analysis directly — SC1-SC2 compliance)
- [ ] Deep mode selected (2 files ≤ 5)
- [ ] Sub-agents spawned for detection and synthesis (not self-performed)
- [ ] Summary addresses user's mocking concern with specific findings
- [ ] `error-handler.test.ts` has mock-related violations identified
- [ ] `session-sync.test.ts` shows better test quality (real fs operations)
- [ ] All log files written

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**:

---

## Test P5.10-4: Threshold Override (Force Scale on Small Set)

**Target**: 3 test files with `--threshold=2` (forces Scale mode on a small set)

**Prompt** (slash command):
```
/test-audit /mnt/c/projects/clear-framework/tests/infrastructure/sync/e2e.test.ts /mnt/c/projects/clear-framework/tests/infrastructure/sync/session-sync.test.ts /mnt/c/projects/clear-framework/tests/infrastructure/sync/error-handler.test.ts --threshold=2
```

**Expected Behavior**:
1. Stage 0 AST scripts run
2. Mode selected: **Scale** (3 files > threshold 2)
3. Classification stage runs (unlike P5.10-1 which was Deep)
4. Full Scale pipeline executes

**Verification**:
- [ ] Mode displayed as **Scale** with threshold 2 (not default 5)
- [ ] Classification sub-agent spawned (Haiku) — this is the key difference from P5.10-1
- [ ] Classification output at `logs/test-classification-*.yaml`
- [ ] Full Scale pipeline completes (classification → detection → synthesis)
- [ ] All log files written

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**:

---

## Test P5.10-5: AST Script Output Validation

**Target**: Verify AST scripts produce correct output on clear-framework files

**Setup**: Run AST scripts manually before the test session to establish baseline:
```bash
just verify-count /mnt/c/projects/clear-framework/tests/infrastructure/sync/error-handler.test.ts
just skip-detect /mnt/c/projects/clear-framework/tests/infrastructure/sync/error-handler.test.ts
just ast-analyze /mnt/c/projects/clear-framework/tests/infrastructure/sync/error-handler.test.ts
```

**Verification**:
- [ ] `verify-count` produces valid JSON with `metrics.total_lines`, `metrics.test_logic_lines`, `metrics.assertion_lines`, `metrics.effectiveness_percent`, `metrics.framework_detected`
- [ ] `skip-detect` produces valid JSON with `markers` array (expected: empty — no skip/only/todo in these files)
- [ ] `ast-analyze` produces valid JSON with `violations` array (check for T3+ data flow leads)
- [ ] Line counts are plausible (not negative, not exceeding total file lines)
- [ ] Framework detected as `jest` or `vitest`

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: This test can be run in the existing session (no skill invocation needed). Results establish baseline for validating AST output during P5.10-1 through P5.10-4.

---

## Test P5.10-6: AST Graceful Degradation

**Target**: Verify skill continues when AST scripts fail

**Setup**: Point at a non-TypeScript file or a path where scripts will fail:

**Prompt** (slash command):
```
/test-audit /mnt/c/projects/the-bulwark/CLAUDE.md
```

**Expected Behavior**:
1. Stage 0 AST scripts run but fail (not a .test.ts file)
2. Graceful degradation logged in diagnostics
3. Skill continues with LLM-only analysis (or reports "no test files found")

**Verification**:
- [ ] AST script failure handled gracefully (no crash)
- [ ] Diagnostic output includes `graceful_degradation: true` or appropriate error
- [ ] Skill either continues with degraded mode or cleanly reports "no test files"
- [ ] No unhandled exceptions or broken pipeline

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**:

---

## Test P5.10-7: Reference File Loading Verification

**Target**: Verify sub-agents receive content from reference files

**Prompt** (slash command — same as P5.10-1):
```
/test-audit /mnt/c/projects/clear-framework/tests/infrastructure/sync/error-handler.test.ts
```

**Verification** (check sub-agent logs for evidence of reference file content):
- [ ] Detection log (`logs/mock-detection-*.yaml`) shows self-classification block (Deep mode detection prompt loaded from `references/prompts/deep-mode-detection.md`)
- [ ] Audit report (`logs/test-audit-*.yaml`) follows schema from `references/schemas/audit-output.yaml` (has metadata.mode, audit.file_analysis, directive.REWRITE_REQUIRED)
- [ ] Diagnostic (`logs/diagnostics/test-audit-*.yaml`) follows schema from `references/schemas/diagnostic-output.yaml` (has mode_selection, stage_0_ast, gate_evaluation)
- [ ] Priority classification uses P0/P1/P2 definitions from `references/priority-classification.md`

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: This test can be evaluated by reading logs generated during P5.10-1 (no separate run needed).

---

## Test P5.10-8: REWRITE_REQUIRED Gate Logic

**Target**: Verify two-gate logic produces correct directive

**Verification** (from P5.10-1 or P5.10-2 audit report):
- [ ] Gate evaluation documented in diagnostic output
- [ ] If P0 violations found → Gate 1 triggered, REWRITE_REQUIRED = true
- [ ] If P1 only + effectiveness ≥95% → Advisory only
- [ ] If P2 only → Advisory only
- [ ] `directive.gate_triggered` field populated with explanation
- [ ] `directive.files_to_rewrite` ordered by priority then effectiveness (if REWRITE_REQUIRED)

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Evaluated from log output, not a separate invocation.

---

## Test P5.10-9: SC1-SC2 Compliance (Bias Avoidance)

**Target**: Verify orchestrator does NOT perform analysis directly

**Verification** (observed across all test runs):
- [ ] Orchestrator spawns sub-agents for detection (does not analyze files itself)
- [ ] Orchestrator spawns sub-agents for synthesis (does not compute metrics itself)
- [ ] Orchestrator spawns sub-agent for classification in Scale mode
- [ ] No instance of orchestrator reading test files and producing violation findings directly
- [ ] Log files are written by sub-agents, not the orchestrator
- [ ] Pre-Flight Gate language visible in orchestrator behavior

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Cross-cutting verification across all tests. Key indicator: violations appear in sub-agent logs, not in orchestrator's direct output.

---

# Post-Test Checklist

## Functional Coverage

- [ ] Deep mode works (P5.10-1, P5.10-3)
- [ ] Scale mode works (P5.10-2)
- [ ] Threshold override works (P5.10-4)
- [ ] Slash command invocation works (P5.10-1, P5.10-2, P5.10-4)
- [ ] Conversational invocation works (P5.10-3)
- [ ] AST scripts produce correct output (P5.10-5)
- [ ] AST graceful degradation works (P5.10-6)
- [ ] Reference files loaded correctly (P5.10-7)
- [ ] Two-gate logic correct (P5.10-8)
- [ ] SC1-SC2 compliance (P5.10-9)

## Artifact Coverage

- [ ] `logs/mock-detection-*.yaml` written in all runs
- [ ] `logs/test-audit-*.yaml` written in all runs
- [ ] `logs/test-classification-*.yaml` written in Scale mode runs
- [ ] `logs/diagnostics/test-audit-*.yaml` written in all runs
- [ ] AST output in `/tmp/claude/ast-*.json` during runs

## Mode Coverage

| Scenario | Mode | Threshold | Files | Test |
|----------|------|-----------|-------|------|
| 3 files, default threshold | Deep | 5 | 3 | P5.10-1 |
| 14 files, default threshold | Scale | 5 | 14 | P5.10-2 |
| 2 files, conversational | Deep | 5 | 2 | P5.10-3 |
| 3 files, threshold=2 | Scale | 2 | 3 | P5.10-4 |

---

# Cleanup Steps

## CLEANUP-P5.10-001: Remove Generated Logs

```bash
rm -f logs/mock-detection-*.yaml
rm -f logs/test-audit-*.yaml
rm -f logs/test-classification-*.yaml
rm -f logs/diagnostics/test-audit-*.yaml
rm -f logs/diagnostics/mock-detection-*.yaml
```

## CLEANUP-P5.10-002: Remove AST Temp Files

```bash
rm -f /tmp/claude/ast-verify-count.json
rm -f /tmp/claude/ast-skip-detect.json
rm -f /tmp/claude/ast-data-flow.json
```

## CLEANUP-P5.10-003: Verify Clean State

```bash
just typecheck
just lint
git status
```

## Cleanup Verification Checklist

- [ ] Generated logs cleaned
- [ ] AST temp files cleaned
- [ ] `just typecheck` passes
- [ ] `just lint` passes
- [ ] No untracked test artifacts in git status

---

## Design Reference

- **Skill**: `skills/test-audit/SKILL.md`
- **Reference files**: `skills/test-audit/references/`
- **AST scripts**: `skills/test-audit/scripts/`
- **Task Brief**: `plans/task-briefs/P5.10-12-test-audit-hardening.md`
- **Dogfood copy**: `.claude/skills/test-audit/`
- **Test data**: `/mnt/c/projects/clear-framework/tests/infrastructure/sync/`
