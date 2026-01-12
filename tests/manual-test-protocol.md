# P0.3 Pipeline Templates - Manual Test Protocol

**Purpose**: Verify all 6 pipeline templates work correctly via manual invocation.
**Prerequisite**: P0.3 implementation complete, hooks configured in `.claude/settings.json`

---

## Pre-Test Setup

1. Ensure P0.3 skill is copied to `.claude/skills/pipeline-templates/`
2. Ensure hooks are configured in `.claude/settings.json`
3. Start a fresh Claude Code session
4. Verify `/skills` shows `pipeline-templates`

---

## Test 1: Code Review Pipeline

**Prompt**:
```
Review the calculator app code for security and architecture issues.
Use the pipeline-templates skill for orchestration.
Target: tests/fixtures/calculator-app/src/calculator.ts
```

**Expected Behavior**:
1. PreToolUse hook fires, injects pipeline guidance
2. CodeAuditor (Sonnet) runs security analysis
3. CodeAuditor (Sonnet) runs architecture analysis
4. TestAuditor (Sonnet) checks test coverage
5. If findings > 0, IssueDebugger runs
6. Logs written to `logs/`

**Verification**:
- [ ] Hook fired (check `logs/pipeline-tracking.log`)
- [ ] All stages executed in order
- [ ] Output follows subagent-output-templating format

---

## Test 2: Fix Validation Pipeline

**Prompt**:
```
Fix the division by zero issue in calculator.ts and validate the fix.
Use the fix validation pipeline.
Target: tests/fixtures/calculator-app/src/calculator.ts
```

**Expected Behavior**:
1. IssueDebugger (Sonnet) analyzes root cause
2. FixWriter (Opus) applies fix
3. CodeAuditor (Sonnet) reviews fix
4. TestAuditor (Sonnet) verifies tests pass
5. Loop if issues remain (max 3 iterations)

**Verification**:
- [ ] Fix applied correctly
- [ ] Review stage ran
- [ ] Loop terminated appropriately
- [ ] Output follows format

---

## Test 3: Test Audit Pipeline

**Prompt**:
```
Audit the test quality in calculator.test.ts.
Identify mock-heavy tests and recommend rewrites.
Use the test audit pipeline.
```

**Expected Behavior**:
1. TestAuditor (Sonnet) classifies tests
2. If mock_heavy > 0, VerificationScriptCreator runs
3. Recommendations provided for rewrites

**Verification**:
- [ ] Tests classified (real vs mock-heavy)
- [ ] Conditional branching worked
- [ ] YAML output valid

---

## Test 4: New Feature Pipeline

**Prompt**:
```
Add a power function (exponentiation) to the calculator.
Use the new feature pipeline.
Include tests and code review.
```

**Expected Behavior**:
1. Investigation (Haiku) researches existing patterns
2. Implementer (Opus) writes code
3. TestAuditor (Sonnet) identifies test gaps
4. Implementer (Opus) writes tests
5. CodeAuditor (Sonnet) final review

**Verification**:
- [ ] Feature implemented
- [ ] Tests added
- [ ] Review completed
- [ ] All stages logged

---

## Test 5: Research & Planning Pipeline

**Prompt**:
```
Research and plan how to add a formula parser to the calculator.
Use the research & planning pipeline.
Ensure the plan is reviewed at least 3 times.
```

**Expected Behavior**:
1. Researcher (Haiku) searches for patterns, docs
2. Orchestrator synthesizes plan draft
3. PlanReviewer (Sonnet) critically reviews
4. Orchestrator applies feedback
5. Loop repeats minimum 3 times

**Verification**:
- [ ] Research phase completed (web/file search)
- [ ] Plan synthesized
- [ ] Review feedback incorporated
- [ ] Minimum 3 iterations completed
- [ ] Final plan quality improved

---

## Test 6: Test Execution & Fix Pipeline

**Prompt**:
```
Run the calculator tests and fix any failures.
Use the test execution & fix pipeline.
```

**Expected Behavior**:
1. TestRunner (Haiku) executes tests
2. If failures, FailureAnalyzer (Sonnet) analyzes
3. FixWriter (Opus) applies fixes
4. TestRunner (Haiku) re-executes
5. Loop until pass or max iterations

**Verification**:
- [ ] Tests executed
- [ ] Failures analyzed
- [ ] Fixes applied
- [ ] Re-execution verified
- [ ] Loop terminated correctly

---

## Test 7: Single-Agent Bypass

**Prompt**:
```
Explore the calculator app codebase structure.
```

**Expected Behavior**:
1. PreToolUse hook fires
2. Detects simple lookup task
3. Allows silently WITHOUT pipeline guidance injection

**Verification**:
- [ ] No pipeline guidance injected
- [ ] Task completed directly
- [ ] No unnecessary overhead

---

## Test 8: Model Selection Verification

For each pipeline, verify correct models used:

| Stage Type | Expected Model |
|------------|----------------|
| Lookup/Execute/Run | Haiku |
| Review/Analyze/Audit | Sonnet |
| Write/Fix/Implement | Opus |

**Verification**:
- [ ] Check `logs/diagnostics/` for `model_actual` field
- [ ] Compare against expected model per stage type

---

## Post-Test Checklist

- [ ] All 6 pipelines executed successfully
- [ ] Single-agent bypass works
- [ ] Model selection follows P0.1 task-type rubric
- [ ] Hooks fired correctly (PreToolUse, SubagentStart, SubagentStop)
- [ ] All logs valid YAML
- [ ] Pipeline tracking log shows all stages

---

## Known Limitations

1. **Cannot automate**: Pipeline invocation requires interactive Claude Code session
2. **Manual judgment**: Some verification requires human review of output quality
3. **Loop verification**: Min 3 iterations for Research & Planning must be counted manually

---

## Test Results Template

```yaml
# tests/logs/pipeline-test-results-YYYYMMDD.yaml
test_date: 2026-01-XX
tester: [name]
session_id: [from /context]

results:
  code_review:
    status: pass|fail
    notes: ""
  fix_validation:
    status: pass|fail
    notes: ""
  test_audit:
    status: pass|fail
    notes: ""
  new_feature:
    status: pass|fail
    notes: ""
  research_planning:
    status: pass|fail
    iteration_count: 3
    notes: ""
  test_execution_fix:
    status: pass|fail
    notes: ""
  single_agent_bypass:
    status: pass|fail
    notes: ""
  model_selection:
    status: pass|fail
    notes: ""

overall: pass|fail
blockers: []
```
