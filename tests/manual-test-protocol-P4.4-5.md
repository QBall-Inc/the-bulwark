# P4.4-5 Manual Test Protocol - Implementer Agent & Pipeline Updates

**Purpose**: Verify bulwark-implementer agent (direct + pipeline invocation) and pipeline-templates updates.
**Prerequisite**: P4.4 implementation complete, pipeline-templates updated (P4.5), fixtures in place.

---

## Pre-Test Setup

1. Ensure fixtures exist:
   ```bash
   ls scripts/modules/user-service.ts scripts/modules/data-export.ts
   ls tests/modules/user-service.test.ts tests/modules/data-export.test.ts
   ls tests/fixtures/implementer/debug-report.yaml tests/fixtures/implementer/design-doc.yaml
   ```
2. Ensure agent exists in both locations:
   ```bash
   ls agents/bulwark-implementer.md .claude/agents/bulwark-implementer.md
   ```
3. Ensure implementer-quality.sh is executable:
   ```bash
   ls -la scripts/hooks/implementer-quality.sh
   ```
4. Run `just typecheck && just lint` to confirm Phase 1 passes
5. Ensure `logs/` directory structure exists
6. Start a **fresh Claude Code session**
7. Verify governance protocol appears (SessionStart hook working)

---

# P4.4 Bulwark-Implementer Tests

## Test P4.4-1: Direct Invocation (Fix Mode)

**Fixtures**: `scripts/modules/user-service.ts`, `tests/modules/user-service.test.ts`, `tests/fixtures/implementer/debug-report.yaml`

**Prompt** (conversational):
```
The user service is crashing when new users try to log in - we're getting
"Cannot read properties of undefined" errors in the greeting page. The issue
has already been analyzed and there's a debug report at
tests/fixtures/implementer/debug-report.yaml. Can you use the implementer
agent to fix this?
```

**Expected Behavior**:
1. Orchestrator spawns bulwark-implementer via Task tool
2. Agent reads debug report, identifies non-null assertion bug
3. Agent modifies `scripts/modules/user-service.ts` (adds null check / optional chaining)
4. Agent calls `implementer-quality.sh` via Bash after each Write/Edit
5. Agent writes test(s) for the null profile scenario
6. Agent runs final `just typecheck && just lint`
7. Agent writes implementation report to `logs/implementer-IMPL-FIX-001-*.yaml`
8. Agent writes diagnostics to `logs/diagnostics/bulwark-implementer-*.yaml`
9. Agent returns summary to orchestrator

**Verification**:
- [ ] bulwark-implementer agent spawned (check SubagentStart in hooks.log)
- [ ] `scripts/modules/user-service.ts` modified (null check added, `!` removed)
- [ ] Fix handles user without profile (fallback to email or similar)
- [ ] Existing tests still pass (users with profile)
- [ ] New test(s) cover null profile scenario
- [ ] Agent called `implementer-quality.sh` via Bash (check agent transcript)
- [ ] Agent ran `just typecheck && just lint` as final check
- [ ] Quality gates passed (typecheck, lint)
- [ ] Implementation report at `logs/implementer-IMPL-FIX-001-*.yaml`
- [ ] Report includes `pipeline_suggestions` field
- [ ] Diagnostics at `logs/diagnostics/bulwark-implementer-*.yaml`
- [ ] Summary includes MANDATORY FOLLOW-UP with pipeline suggestions (SA6)
- [ ] SubagentStop hook fires and verifies log output (check hooks.log)

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.4-2: Direct Invocation (Feature Mode)

**Fixtures**: `scripts/modules/data-export.ts`, `tests/modules/data-export.test.ts`, `tests/fixtures/implementer/design-doc.yaml`

**Prompt** (conversational):
```
We need to add CSV export to our data export module. The design has been
finalized and is at tests/fixtures/implementer/design-doc.yaml. Can you
use the implementer agent to build this feature?
```

**Expected Behavior**:
1. Orchestrator spawns bulwark-implementer via Task tool
2. Agent reads design doc, identifies CSV export requirement
3. Agent adds `exportToCsv` function to `scripts/modules/data-export.ts`
4. Agent updates `getSupportedFormats` to include 'csv'
5. Agent calls `implementer-quality.sh` via Bash after each Write/Edit
6. Agent writes tests for CSV export (including special characters)
7. Agent writes implementation report to `logs/implementer-IMPL-FEAT-001-*.yaml`

**Verification**:
- [ ] bulwark-implementer agent spawned
- [ ] `exportToCsv` function added to `scripts/modules/data-export.ts`
- [ ] `getSupportedFormats()` returns `['pdf', 'csv']`
- [ ] CSV handles special characters (commas, quotes per RFC 4180)
- [ ] Existing PDF tests unaffected
- [ ] New tests cover CSV export scenarios
- [ ] Agent called `implementer-quality.sh` via Bash
- [ ] Quality gates passed
- [ ] Implementation report at `logs/implementer-IMPL-FEAT-001-*.yaml`
- [ ] Report includes `pipeline_suggestions` field
- [ ] Summary includes MANDATORY FOLLOW-UP (SA6)

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.4-3: Quality Gate Failure and Self-Correction

**Setup**: Before running this test, temporarily introduce a type error the implementer might encounter. OR observe self-correction behavior naturally during P4.4-1 or P4.4-2 if the agent makes a mistake on first attempt.

**Verification**:
- [ ] Agent called `implementer-quality.sh` and received failure output
- [ ] Agent read error from script output
- [ ] Agent attempted to fix the violation
- [ ] Agent re-called `implementer-quality.sh` after fix attempt
- [ ] Retry count documented in implementation report `quality_gates.retries` field
- [ ] Quality gates eventually passed (or escalation after 3 retries)

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL / [ ] N/A (no failures observed)
**Notes**: _____

---

## Test P4.4-4: Fix Validation Pipeline Stage 2

**Fixtures**: Same as P4.4-1 (restore originals first if modified)

**Setup**: Restore original fixture files before running:
```bash
# If fixtures were modified by P4.4-1, restore them:
git checkout scripts/modules/user-service.ts tests/modules/user-service.test.ts
```

**Prompt** (conversational):
```
There's a crash in the user service when new users log in. Can you run the
fix validation pipeline on this? The source file is
scripts/modules/user-service.ts and the error is "Cannot read properties
of undefined (reading 'name')".
```

**Expected Behavior**:
1. Orchestrator runs Fix Validation Pipeline
2. Stage 1: IssueAnalyzer (bulwark-issue-analyzer) produces debug report
3. Stage 2: FixWriter (bulwark-implementer) implements fix using debug report
4. Stage 3: TestWriter writes tests if needed
5. Stage 4: FixValidator validates fix against debug report
6. Stage 5: CodeReviewer reviews and approves/rejects

**Verification**:
- [ ] Fix Validation Pipeline triggered (not just direct implementer invocation)
- [ ] Stage 1: Debug report produced at `logs/debug-reports/*.yaml`
- [ ] Stage 2: bulwark-implementer spawned (not orchestrator direct fix)
- [ ] Stage 2: Implementer reads debug report from Stage 1
- [ ] Stage 2: Fix applied to `scripts/modules/user-service.ts`
- [ ] Stage 2: Implementation report at `logs/implementer-*.yaml`
- [ ] Stage 3-5: Pipeline continues through remaining stages
- [ ] Pipeline summary includes all stage results

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.4-5: New Feature Pipeline Stage 3

**Fixtures**: Same as P4.4-2 (restore originals first if modified)

**Setup**: Restore original fixture files before running:
```bash
git checkout scripts/modules/data-export.ts tests/modules/data-export.test.ts
```

**Prompt** (conversational):
```
We want to add CSV export support to our data export module at
scripts/modules/data-export.ts. Can you run the new feature pipeline
to research, design, implement, and review this addition?
```

**Expected Behavior**:
1. Orchestrator runs New Feature Pipeline
2. Stage 1: Researcher gathers requirements
3. Stage 2: Architect designs approach
4. Stage 3: Implementer (bulwark-implementer) writes code
5. Stage 4: TestWriter writes tests
6. Stage 5: CodeReviewer reviews

**Verification**:
- [ ] New Feature Pipeline triggered
- [ ] Stage 1: Research findings produced
- [ ] Stage 2: Design document produced
- [ ] Stage 3: bulwark-implementer spawned (not generic Opus agent)
- [ ] Stage 3: Implementer follows design from Stage 2
- [ ] Stage 3: Implementation report at `logs/implementer-*.yaml`
- [ ] Stage 4-5: Pipeline continues through remaining stages
- [ ] Pipeline summary includes all stage results

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.4-6: Hook Failure Escalation

**Setup**: Create intentionally broken code that fails quality gates repeatedly. For example, add a file with unresolvable type errors that the implementer cannot fix.

**Verification**:
- [ ] Agent retries up to 3 times
- [ ] Each retry logged in implementation report
- [ ] After 3 failures: partial report written with `escalated: true`
- [ ] Escalation message returned to orchestrator: "ESCALATED: Quality gates failed after 3 retries"
- [ ] Report includes retry count and failure details

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL / [ ] DEFERRED
**Notes**: _____

---

## P4.4 Post-Test Checklist

- [ ] Agent spawnable via Task tool with subagent_type=bulwark-implementer
- [ ] Fix mode: reads debug report, fixes bug, writes tests
- [ ] Feature mode: reads design doc, implements feature, writes tests
- [ ] implementer-quality.sh called after each Write/Edit (check transcript)
- [ ] Final self-validation: `just typecheck && just lint` (check transcript)
- [ ] Pipeline suggestions in implementation report `pipeline_suggestions` field
- [ ] Pipeline suggestions in summary with MANDATORY language (SA6)
- [ ] Implementation report written to `logs/implementer-*.yaml`
- [ ] Diagnostics written to `logs/diagnostics/bulwark-implementer-*.yaml`
- [ ] SubagentStop hook verifies log output (check hooks.log)
- [ ] Quality gate self-correction observed or escalation works
- [ ] Fix Validation Pipeline Stage 2 uses bulwark-implementer
- [ ] New Feature Pipeline Stage 3 uses bulwark-implementer

---

# P4.5 Pipeline-Templates Tests

## Test P4.5-1: Parallel Execution Notation

**Action**: Read `skills/pipeline-templates/SKILL.md`

**Verification**:
- [ ] `[]` array notation documented in Pipeline Execution Pattern section
- [ ] Comment explains: "Array notation = parallel"
- [ ] Key principles section explains: sequential (`|>`) vs parallel (`[]`)
- [ ] Parallel stages described as "multiple Task calls in a single message"

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.5-2: Code Review Pipeline Uses Parallel Notation

**Action**: Read `skills/pipeline-templates/SKILL.md` (Quick Reference) and `skills/pipeline-templates/references/code-review.md`

**Verification**:
- [ ] SKILL.md Quick Reference: Code Review uses `[SecurityReviewer, TypeSafetyReviewer, LintReviewer, StandardsReviewer]`
- [ ] code-review.md Pipeline Definition: Uses `[...]` array notation for stages 1-4
- [ ] code-review.md: Comment says "Stages 1-4 run concurrently, findings merged in Stage 5"
- [ ] code-review.md Example Invocation: Shows "Stages 1-4: Parallel Review Agents (single message, multiple Task calls)"
- [ ] code-review.md: Architecture note mentions "parallel execution for bias prevention"

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.5-3: Fix Validation Stage 2 References Implementer

**Action**: Read `skills/pipeline-templates/references/fix-validation.md`

**Verification**:
- [ ] Pipeline Definition: Stage 2 comment says `Opus - bulwark-implementer`
- [ ] Stage 2 heading shows `**Agent**: \`bulwark-implementer\` (custom sub-agent)`
- [ ] Stage 2 has CONTEXT section with `debug_report_path`, `root_cause`, `affected_files`, `fix_approach`
- [ ] Stage 2 has Invocation block with `Task: subagent_type=bulwark-implementer`
- [ ] Stage 2 has SA6 note about pipeline suggestions
- [ ] Example Invocation Stage 2 shows `Task: subagent_type=bulwark-implementer`

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.5-4: New Feature Stage 3 References Implementer

**Action**: Read `skills/pipeline-templates/references/new-feature.md`

**Verification**:
- [ ] Pipeline Definition: Stage 3 comment says `Opus - bulwark-implementer`
- [ ] Stage 3 heading shows `**Agent**: \`bulwark-implementer\` (custom sub-agent)`
- [ ] Stage 3 has CONTEXT section with `design_document`, `requirements`, `existing_patterns`
- [ ] Stage 3 has Invocation block with `Task: subagent_type=bulwark-implementer`
- [ ] Stage 3 has SA6 note about pipeline suggestions
- [ ] Example Invocation Stage 3 shows `Task: subagent_type=bulwark-implementer`
- [ ] Loop condition references `Stage 3 (bulwark-implementer)`

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.5-5: No Stale Code-Auditor References

**Action**: Search all pipeline files

**Command**:
```bash
grep -rn "bulwark-code-auditor" skills/pipeline-templates/
```

**Verification**:
- [ ] Zero results from grep (no stale references)
- [ ] No "Standalone Alternative" section in code-review.md

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.5-6: Model Override Terminology

**Action**: Read `skills/pipeline-templates/SKILL.md` Model Selection section

**Verification**:
- [ ] Override rule says `model:` (not `agent:`)
- [ ] Text reads: "If a custom agent specifies `model:` in frontmatter, use that model instead"

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.5-7: Test Execution & Fix Clarification

**Action**: Read `skills/pipeline-templates/SKILL.md` Quick Reference

**Verification**:
- [ ] Test Execution & Fix entry includes `(orchestrator)` label on FixWriter
- [ ] Comment explains "PostToolUse hook enforces quality"

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

---

## P4.5 Post-Test Checklist

- [ ] Parallel `[]` notation documented and used correctly
- [ ] Code Review Pipeline uses parallel notation for 4 review stages
- [ ] Fix Validation Stage 2 references bulwark-implementer
- [ ] New Feature Stage 3 references bulwark-implementer
- [ ] No stale bulwark-code-auditor references anywhere
- [ ] Model override uses correct `model:` field name
- [ ] Test Execution & Fix clarifies orchestrator FixWriter

---

# Cleanup Steps

## CLEANUP-P4.4-001: Restore Modified Fixtures

```bash
git checkout scripts/modules/user-service.ts tests/modules/user-service.test.ts
git checkout scripts/modules/data-export.ts tests/modules/data-export.test.ts
```

## CLEANUP-P4.4-002: Remove All Test Fixtures (after all testing complete)

```bash
rm -rf scripts/modules/
rm -rf tests/modules/
rm -rf tests/fixtures/implementer/
```

## CLEANUP-P4.4-003: Clean Generated Logs

```bash
rm -f logs/implementer-*.yaml
rm -f logs/diagnostics/bulwark-implementer-*.yaml
rm -f logs/debug-reports/IMPL-*.yaml
```

## CLEANUP-P4.4-004: Verify Clean State

```bash
just typecheck
just lint
git status
```

## Cleanup Verification Checklist

- [ ] `scripts/modules/` removed
- [ ] `tests/modules/` removed
- [ ] `tests/fixtures/implementer/` removed
- [ ] Generated logs cleaned
- [ ] `just typecheck` passes
- [ ] `just lint` passes
- [ ] No untracked test artifacts in git status

---

## Design Reference

- **Agent**: `agents/bulwark-implementer.md`
- **Quality script**: `scripts/hooks/implementer-quality.sh`
- **Pipeline templates**: `skills/pipeline-templates/SKILL.md`
- **Task Brief**: `plans/task-briefs/P4.4-5-implementer-and-pipelines.md`
- **Research Doc**: `docs/p4.3-4-research.md`
