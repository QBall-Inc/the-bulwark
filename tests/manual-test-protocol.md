# P0.3 Pipeline Templates - Manual Test Protocol

**Purpose**: Verify pipeline templates and PostToolUse hook work correctly.
**Prerequisite**: P0.3 implementation complete, hooks configured in `.claude/settings.json`
**Design**: PostToolUse hook on Write|Edit suggests pipelines based on file type and change size.

---

## Pre-Test Setup

1. Ensure P0.3 skill is copied to `.claude/skills/pipeline-templates/`
2. Ensure hooks are configured in `.claude/settings.json`
3. Ensure test agents are in `.claude/agents/` (code-analyzer, file-counter)
4. Start a fresh Claude Code session
5. Verify `/skills` shows `pipeline-templates` is NOT listed (user-invocable: false)

---

## Test 1: PostToolUse Hook - Small Change Bypass

**Prompt**:
```
Add a comment to calculator.ts explaining what the add function does.
Target: tests/fixtures/calculator-app/src/calculator.ts
```

**Expected Behavior**:
1. Claude edits the file (small change, ~2-3 lines)
2. PostToolUse hook fires
3. Change size < 5 lines threshold
4. Hook exits silently (no pipeline suggestion)

**Verification**:
- [x] File edited successfully
- [x] Check `logs/hooks.log` shows "SKIP (small change)"
- [x] No pipeline suggestion in Claude's response

---

## Test 2: PostToolUse Hook - Code Review Suggestion

**Prompt**:
```
Add a new subtract function to calculator.ts with error handling and validation.
Make it comprehensive with input validation, overflow checking, and detailed comments.
Target: tests/fixtures/calculator-app/src/calculator.ts
```

**Expected Behavior**:
1. Claude writes significant code (>5 lines)
2. PostToolUse hook fires
3. Change size > 5 lines threshold
4. Hook injects additionalContext suggesting Code Review pipeline
5. Claude may acknowledge the suggestion

**Verification**:
- [x] File edited with new function
- [x] Check `logs/hooks.log` shows "SUGGEST (Code Review for X lines)"
- [x] Claude receives pipeline suggestion context

---

## Test 3: PostToolUse Hook - Test Audit Suggestion

**Prompt**:
```
Add comprehensive tests for the subtract function in calculator.test.ts.
Include edge cases, error handling tests, and boundary tests.
Target: tests/fixtures/calculator-app/src/calculator.test.ts
```

**Expected Behavior**:
1. Claude writes test file (>10 lines for test files)
2. PostToolUse hook fires
3. Detects test file pattern (*.test.ts)
4. Hook suggests Test Audit pipeline

**Verification**:
- [x] Test file updated
- [x] Check `logs/hooks.log` shows "SUGGEST (Test Audit for X lines)"
- [x] Pipeline suggestion recommends Test Audit (not Code Review)

---

## Test 4: Pipeline Orchestration - Code Review

**Prompt**:
```
I just made significant code changes. Please run a Code Review pipeline:
1. Load the pipeline-templates skill
2. Follow the Code Review pipeline stages
3. Use the test agents (code-analyzer, file-counter) as stand-ins
Target: tests/fixtures/calculator-app/
```

**Expected Behavior**:
1. Claude loads pipeline-templates skill
2. Claude invokes file-counter agent (stage 1)
3. Claude invokes code-analyzer agent (stage 2)
4. SubagentStart/SubagentStop hooks log each invocation
5. Results synthesized

**Verification**:
- [x] Pipeline-templates skill referenced
- [x] Check `logs/pipeline-tracking.log` for SubagentStart/SubagentStop entries
- [x] Both agents executed in sequence
- [x] Logs written to `logs/`

---

## Test 5: Pipeline Orchestration - Chained Agents

**Prompt**:
```
Run a two-stage analysis pipeline on the calculator app:
Stage 1: Use file-counter agent to count files
Stage 2: Use code-analyzer agent to analyze code structure
Chain the results - pass stage 1 output to stage 2 context.
```

**Expected Behavior**:
1. First Task spawns file-counter
2. file-counter completes, returns summary
3. Claude synthesizes and invokes code-analyzer
4. code-analyzer receives context from stage 1
5. Final synthesis of both stages

**Verification**:
- [x] Two SubagentStart entries in logs
- [x] Two SubagentStop entries in logs
- [x] Stage 2 has context from Stage 1
- [x] Both agent outputs in `logs/`

---

## Test 6: Documentation Change - Higher Threshold

**Prompt**:
```
Update the README.md with a detailed description of the calculator app.
Add at least 15 lines of documentation.
Target: tests/fixtures/calculator-app/README.md
```

**Expected Behavior**:
1. Claude writes documentation (markdown file)
2. PostToolUse hook fires
3. For .md files, threshold is 10 lines
4. If >10 lines, suggests "light review or skip"

**Verification**:
- [ ] Documentation updated
- [ ] Check `logs/hooks.log` for doc threshold (10 lines)
- [ ] Suggestion is "light review or skip" (not Code Review)

---

## Test 7: Config File - Security Focus

**Prompt**:
```
Add a new configuration section to the calculator app's config.json.
Add environment settings, API keys placeholder, and feature flags.
Target: tests/fixtures/calculator-app/config.json
```

**Expected Behavior**:
1. Claude edits config file
2. PostToolUse hook fires
3. Config file threshold is 3 lines
4. If >3 lines, suggests "Code Review (security focus)"

**Verification**:
- [ ] Config file updated
- [ ] Check `logs/hooks.log` shows config detected
- [ ] Suggestion mentions "security focus"

---

## Test 8: Menu Visibility Check

**Action**: Type `/` in Claude Code to open skill menu

**Expected Behavior**:
- `pipeline-templates` should NOT appear in the menu
- Only user-invocable skills should appear

**Verification**:
- [ ] Skill NOT in `/` menu
- [ ] `user-invocable: false` working correctly

---

## Post-Test Checklist

- [ ] PostToolUse hook fires on Write/Edit
- [ ] Small changes bypass correctly (no suggestion)
- [ ] Significant changes trigger suggestion
- [ ] File type detection works (code, test, config, doc)
- [ ] Correct pipeline recommended per file type
- [ ] SubagentStart/SubagentStop logging works
- [ ] Chained agents execute sequentially
- [ ] Skill NOT in `/` menu
- [ ] All logs valid and readable

---

## Test Results Template

```yaml
# tests/logs/pipeline-test-results-YYYYMMDD.yaml
test_date: 2026-01-XX
tester: [name]
session_id: [from /context]

results:
  small_change_bypass:
    status: pass|fail
    notes: ""
  code_review_suggestion:
    status: pass|fail
    lines_changed: X
    notes: ""
  test_audit_suggestion:
    status: pass|fail
    lines_changed: X
    notes: ""
  pipeline_orchestration:
    status: pass|fail
    agents_invoked: [file-counter, code-analyzer]
    notes: ""
  chained_agents:
    status: pass|fail
    notes: ""
  doc_threshold:
    status: pass|fail
    notes: ""
  config_security:
    status: pass|fail
    notes: ""
  menu_visibility:
    status: pass|fail
    notes: ""

overall: pass|fail
blockers: []
```

---

## Known Limitations

1. **Cannot fully automate**: Hook integration requires interactive Claude Code session
2. **additionalContext is suggestion, not directive**: Claude may or may not follow pipeline suggestion
3. **Agent skills loading**: Test agents have `skills: subagent-output-templating` but skill availability depends on session
4. **Manual judgment**: Output quality requires human review

---

## Design Notes (Session 3 Changes)

| Original Design | Revised Design |
|-----------------|----------------|
| PreToolUse on Task | PostToolUse on Write\|Edit |
| Validates before sub-agent spawn | Suggests after code change |
| Pattern matching on task description | File type + change size detection |
| `systemMessage` injection | `additionalContext` injection |
| Blocking validation | Non-blocking suggestion |
