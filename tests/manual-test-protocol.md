# Manual Test Protocol

This document contains manual test protocols for skills that cannot be fully automated.

---

# P0.5 Anthropic Validator - Manual Test Protocol

**Purpose**: Verify anthropic-validator skill works correctly for validating Claude Code assets.
**Prerequisite**: P0.5 implementation complete, skill copied to `.claude/skills/anthropic-validator/`
**Design**: Main Context Orchestration pattern - Claude follows skill instructions to orchestrate sub-agents.

---

## Pre-Test Setup (P0.5)

1. Ensure skill is copied to `.claude/skills/anthropic-validator/`
2. Ensure agent is copied to `.claude/agents/bulwark-standards-reviewer.md`
3. Ensure `logs/validations/` directory exists
4. Start a fresh Claude Code session
5. Verify `/skills` shows `anthropic-validator` (user-invocable: true)

---

## Test P0.5-1: Single Skill Validation

**Prompt**:
```
Use the anthropic-validator skill to validate skills/issue-debugging/SKILL.md
Follow the skill instructions to fetch standards and analyze the asset.
```

**Expected Behavior**:
1. Claude loads anthropic-validator skill
2. Claude spawns claude-code-guide to fetch skills standards
3. Claude spawns bulwark-standards-reviewer to analyze issue-debugging
4. Reviewer writes YAML report to `logs/validations/`
5. Claude presents human-readable summary

**Verification**:
- [x] Skill correctly identified as `skill` type
- [x] claude-code-guide invoked for standards fetch
- [x] bulwark-standards-reviewer invoked for analysis
- [x] YAML report exists in `logs/validations/`
- [x] Report has correct schema (metadata, findings, summary)
- [x] Verdict shown to user (PASS/FAIL)

---

## Test P0.5-2: Hook Validation

**Prompt**:
```
Validate the hooks configuration in .claude/settings.json using anthropic-validator.
```

**Expected Behavior**:
1. Claude detects hooks configuration
2. Fetches hooks standards from docs
3. Analyzes against hook requirements
4. Reports any violations

**Verification**:
- [x] Asset type detected as `hook`
- [x] Correct documentation URL used
- [x] YAML report generated
- [x] Hook-specific validation points checked

---

## Test P0.5-3: Agent Validation

**Prompt**:
```
Validate agents/bulwark-standards-reviewer.md using anthropic-validator.
```

**Expected Behavior**:
1. Claude detects agent file
2. Fetches sub-agent standards
3. Validates frontmatter and structure
4. Reports findings

**Verification**:
- [x] Asset type detected as `agent`
- [x] Frontmatter fields validated (name, description, model, tools, skills)
- [x] YAML report generated
- [x] Appropriate findings (if any)

**Notes**: Since the bulwark-standards-reviewer is being used to perform the validation itself, I did not want to cause a circular loop here. Therefore I asked for the code-analyzer agent to be reviewed.
---

## Test P0.5-4: Intentional Violation Detection

**Setup**: Create a deliberately broken skill:
```bash
mkdir -p tests/fixtures/broken-skill
cat > tests/fixtures/broken-skill/SKILL.md << 'EOF'
---
invalid-field: true
agent: gpt-4
---
No description field, no name field
EOF
```

**Prompt**:
```
Validate tests/fixtures/broken-skill/SKILL.md using anthropic-validator.
```

**Expected Behavior**:
1. Validator detects missing required fields
2. Validator detects invalid `agent` value
3. Reports Critical findings
4. Verdict is FAIL

**Verification**:
- [x] Missing `name` flagged as Critical
- [x] Missing `description` flagged as Critical
- [x] Invalid `agent` value flagged as High
- [x] Unknown `invalid-field` flagged (Medium or Low)
- [x] Verdict is FAIL
- [x] Remediation suggestions provided

---

## Test P0.5-5: Fallback Behavior

**Prompt**:
```
Validate skills/issue-debugging/SKILL.md using anthropic-validator.
Simulate that you cannot fetch the latest standards from claude-code-guide.
Use the fallback checklist instead and note this in the report.
```

**Expected Behavior**:
1. Simulated fetch failure
2. Warning logged
3. Fallback checklist used from references/
4. Report shows `standards_source: fallback`
5. Note in summary about potentially outdated standards

**Verification**:
- [x] Fallback checklist used
- [x] Warning shown to user
- [x] Report metadata shows `standards_source: fallback`
- [x] Summary includes note about fallback

---

## Test P0.5-6: Batch Validation

**Prompt**:
```
Validate all skills in the skills/ directory using anthropic-validator.
Generate a batch summary report.
```

**Expected Behavior**:
1. Claude globs all SKILL.md files in skills/
2. Validates each skill
3. Writes individual reports
4. Writes batch summary report

**Verification**:
- [x] All skills validated
- [x] Individual reports exist for each skill
- [x] Batch summary report exists
- [x] Summary shows passed/failed counts
- [x] Failures list specific assets and report paths

**Notes:** The individual review of the issue-debugging skill had yielded 2 observations, but the batch process did not yield a single issue. Probably our batching strategy is not correct and may need further discussion.
---

## Test P0.5-7: Menu Visibility

**Action**: Type `/` in Claude Code to open skill menu

**Expected Behavior**:
- `anthropic-validator` SHOULD appear in the menu
- Can be invoked as `/anthropic-validator [path]`

**Verification**:
- [x] Skill appears in `/` menu
- [x] `user-invocable: true` working correctly

---

## Test P0.5-8: Slash Command - Single File

**Prompt**:
```
/anthropic-validator skills/issue-debugging/SKILL.md
```

**Expected Behavior**:
1. Skill loaded via slash command
2. Single file path passed as argument
3. Full validation workflow executes
4. Report written and summary shown

**Verification**:
- [ ] Slash command recognized
- [ ] Argument `$1` contains file path
- [ ] Validation executes on specified file
- [ ] YAML report generated
- [ ] Summary shown to user

**NOTES:** I'll consider this as a failure since the skill frontmatter has no mention of arguments. Launching the command works, but it does not really load the skill and follow the workflow correctly although it follows the steps broadly; it did not create a log file. I believe that as part of the skills and command merging, there should have been an arguments in the frontmatter, isn't it?
---

## Test P0.5-9: Slash Command - Batch (Directory)

**Prompt**:
```
/anthropic-validator skills/
```

**Expected Behavior**:
1. Skill loaded via slash command
2. Directory path triggers batch mode
3. All SKILL.md files in directory validated
4. Individual reports + batch summary generated

**Verification**:
- [ ] Slash command recognized
- [ ] Directory detected, batch mode activated
- [ ] All skills validated
- [ ] Batch summary report generated
- [ ] Individual reports for each skill

**Notes:** Skipped this due to the aforementioned issues with batch strategy and arguments.
---

## Test P0.5-10: Slash Command - Context Inference

**Setup**: Open a skill file in context first:
```
Read skills/subagent-prompting/SKILL.md
```

**Prompt**:
```
/anthropic-validator
```

**Expected Behavior**:
1. Skill loaded via slash command with no argument
2. Validator infers asset from current context
3. Validates the file currently in context

**Verification**:
- [ ] Slash command recognized without argument
- [ ] Context inference works (detects file in context)
- [ ] Correct file validated
- [ ] Report generated for inferred file

---

## Post-Test Checklist (P0.5)

- [ ] Skill appears in `/` menu
- [ ] Single asset validation works
- [ ] Correct asset type detection
- [ ] Standards fetching via claude-code-guide
- [ ] Critical analysis via bulwark-standards-reviewer
- [ ] YAML reports generated correctly
- [ ] Human-readable summary shown
- [ ] Intentional violations caught
- [ ] Fallback behavior works
- [ ] Batch validation works
- [ ] Slash command - single file works
- [ ] Slash command - batch (directory) works
- [ ] Slash command - context inference works
- [ ] All logs valid and readable

---

## Test Results Template (P0.5)

```yaml
# tests/logs/validator-test-results-YYYYMMDD.yaml
test_date: 2026-01-XX
tester: [name]
session_id: [from /context]

results:
  single_skill_validation:
    status: pass|fail
    report_path: ""
    notes: ""
  hook_validation:
    status: pass|fail
    notes: ""
  agent_validation:
    status: pass|fail
    notes: ""
  violation_detection:
    status: pass|fail
    violations_caught: []
    notes: ""
  fallback_behavior:
    status: pass|fail
    notes: ""
  batch_validation:
    status: pass|fail
    skills_validated: X
    notes: ""
  menu_visibility:
    status: pass|fail
    notes: ""
  slash_cmd_single_file:
    status: pass|fail
    notes: ""
  slash_cmd_batch:
    status: pass|fail
    notes: ""
  slash_cmd_context_inference:
    status: pass|fail
    notes: ""

overall: pass|fail
blockers: []
```

---

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
