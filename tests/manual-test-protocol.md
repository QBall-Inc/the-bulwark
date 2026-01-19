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
- [x] Slash command recognized
- [x] Argument `$1` contains file path
- [x] Validation executes on specified file
- [x] YAML report generated
- [x] Summary shown to user

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
- [x] Slash command recognized
- [x] Directory detected, batch mode activated
- [x] All skills validated
- [x] Batch summary report generated
- [x] Individual reports for each skill

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
- [x] Slash command recognized without argument
- [x] Context inference works (detects file in context)
- [x] Correct file validated
- [x] Report generated for inferred file

---

## Post-Test Checklist (P0.5)

- [x] Skill appears in `/` menu
- [x] Single asset validation works
- [x] Correct asset type detection
- [x] Standards fetching via claude-code-guide
- [x] Critical analysis via bulwark-standards-reviewer
- [x] YAML reports generated correctly
- [x] Human-readable summary shown
- [x] Intentional violations caught
- [x] Fallback behavior works
- [x] Batch validation works
- [x] Slash command - single file works
- [x] Slash command - batch (directory) works
- [x] Slash command - context inference works
- [x] All logs valid and readable

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
- [x] Documentation updated
- [x] Check `logs/hooks.log` for doc threshold (10 lines)
- [x] Suggestion is "light review or skip" (not Code Review)

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
- [x] Skill NOT in `/` menu
- [x] `user-invocable: false` working correctly

---

## Post-Test Checklist

- [x] PostToolUse hook fires on Write/Edit
- [x] Small changes bypass correctly (no suggestion)
- [x] Significant changes trigger suggestion
- [x] File type detection works (code, test, config, doc)
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

---

# P0.6-8 Test Audit Skills - Manual Test Protocol

**Purpose**: Verify test-classification (P0.6), mock-detection (P0.7), and test-audit (P0.8) skills work correctly.
**Prerequisite**: P0.6-8 implementation complete, skills copied to `.claude/skills/`
**Design**: Main Context Orchestration - Orchestrator spawns Haiku/Sonnet sub-agents using skill prompt templates.

---

## Pre-Test Setup (P0.6-8)

1. Ensure skills are copied to `.claude/skills/`:
   - `test-classification/SKILL.md`
   - `mock-detection/SKILL.md`
   - `test-audit/SKILL.md`
2. Ensure test fixtures exist in `tests/fixtures/test-audit/`
3. Ensure `logs/` directory exists
4. Start a fresh Claude Code session
5. Verify `/skills` shows `test-audit` (user-invocable: true)
6. Verify `test-classification` and `mock-detection` are NOT in menu

---

## Test P0.6-1: Classification - Clean Test

**Prompt**:
```
Run the test-audit skill on tests/fixtures/test-audit/clean/calculator.test.ts
Focus on the classification stage only for now.
```

**Expected Behavior**:
1. Claude loads test-audit skill
2. Claude spawns Haiku sub-agent for classification
3. Classification output written to `logs/test-classification-{timestamp}.yaml`
4. File classified as `unit`, `needs_deep_analysis: false`

**Verification**:
- [x] Classification YAML exists in `logs/`
- [x] `category: unit`
- [x] `needs_deep_analysis: false`
- [x] `verification_lines` count present

---

## Test P0.6-2: Classification - T1 Violation Detection

**Prompt**:
```
Run the test-audit skill on tests/fixtures/test-audit/t1-violation/proxy.test.ts
Focus on the classification stage only.
```

**Expected Behavior**:
1. Classification detects `jest.spyOn(child_process, 'spawn')`
2. File flagged with `needs_deep_analysis: true`
3. Reason: "Unit test mocks core module (spawn)"

**Verification**:
- [x] `category: unit`
- [x] `needs_deep_analysis: true`
- [x] `mock_indicators` includes spawn pattern
- [x] `deep_analysis_reason` mentions core module

---

## Test P0.6-3: Classification - Integration File with Mocks

**Prompt**:
```
Run the test-audit skill on tests/fixtures/test-audit/t3-violation/api.integration.ts
Focus on the classification stage only.
```

**Expected Behavior**:
1. Filename pattern `.integration.ts` → `category: integration`
2. Mock detected → `needs_deep_analysis: true`
3. Reason: "Integration test contains mocks"

**Verification**:
- [x] `category: integration` (from filename)
- [x] `needs_deep_analysis: true`
- [x] `mock_indicators` includes fetch mock

---

## Test P0.6-4: Classification - Mixed Types Risk

**Prompt**:
```
Run the test-audit skill on tests/fixtures/test-audit/mixed-types/everything.test.ts
Focus on the classification stage only.
```

**Expected Behavior**:
1. File contains unit, integration, AND e2e tests
2. Classified as `unit` (default) but flagged for `test_management` risk
3. Recommendation to split file

**Verification**:
- [x] `risk: test_management` present
- [x] Recommendation mentions splitting files
- [x] `needs_deep_analysis: true`

---

## Test P0.7-1: Detection - T1 Violation Analysis

**Prompt**:
```
Run the test-audit skill on tests/fixtures/test-audit/t1-violation/proxy.test.ts
Run both classification AND detection stages.
```

**Expected Behavior**:
1. Classification runs first (Haiku)
2. Detection runs on flagged file (Sonnet)
3. T1 violation detected with violation scope
4. `priority: P0` (false confidence)

**Verification**:
- [x] Detection YAML exists in `logs/`
- [x] `rule: T1`
- [x] `severity: critical`
- [x] `priority: P0`
- [x] `violation_scope` shows affected line range
- [x] `affected_lines` calculated
- [x] `suggested_fix` provided

---

## Test P0.7-2: Detection - T3+ Broken Chain

**Prompt**:
```
Run the test-audit skill on tests/fixtures/test-audit/t3plus-violation/workflow.integration.ts
Run both classification AND detection stages.
```

**Expected Behavior**:
1. Detection identifies broken integration chain
2. Mock data used instead of real function output
3. `rule: T3+`, `priority: P0`

**Verification**:
- [x] `rule: T3+`
- [x] `pattern: "Broken integration chain"`
- [x] `priority: P0`
- [x] Reason explains data flow break
- [x] Multiple violation scopes (lines 45, 62, 78)

---

## Test P0.7-3: Detection - T2 Call-Only Assertion

**Prompt**:
```
Run the test-audit skill on tests/fixtures/test-audit/t2-violation/db.test.ts
Run both classification AND detection stages.
```

**Expected Behavior**:
1. T2 violations detected (toHaveBeenCalled without result check)
2. Single-line scopes (minimal impact)
3. `priority: P1` (incomplete verification)

**Verification**:
- [x] `rule: T2`
- [x] `severity: high`
- [x] `priority: P1`
- [x] `violation_scope` is single line each
- [ ] `test_effectiveness` is high (>90%)

**Notes:** The test effectiveness was determined to be 11.1%. This is the summary shared: 

```
Unlike the previous files, the mocks themselves are appropriate for a unit test:
  - Database, Logger, EventEmitter are external dependencies (correct to mock)
  - ConfigService (system under test) is NOT mocked (correct)
  - No T1, T3, or T3+ violations

  The problem is how assertions are written, not what's mocked.

This file is a textbook T2 violation. The tests verify "the code was executed" not "the code worked correctly." 
  They would pass even if:
  - saveConfig() saved wrong data
  - deleteConfig() passed wrong ID
  - Events emitted with wrong name/payload
```  
---

## Test P0.8-1: Full Pipeline - Gate 1 Trigger

**Prompt**:
```
/test-audit tests/fixtures/test-audit/t1-violation/
```

**Expected Behavior**:
1. Full pipeline runs (classification → detection → synthesis)
2. P0 violation found (T1)
3. Gate 1 triggered (P0 violation exists)
4. `REWRITE_REQUIRED: true`

**Verification**:
- [x] All three YAML files in `logs/`
- [x] `directive.REWRITE_REQUIRED: true`
- [x] `directive.gate_triggered: "Gate 1: Impact"`
- [x] Audit summary presented before rewrite
- [x] Orchestrator begins rewrite (or asks for confirmation)

---

## Test P0.8-2: Full Pipeline - Gate 2 Trigger

**Prompt**:
```
/test-audit tests/fixtures/test-audit/t3-violation/
```

**Expected Behavior**:
1. P1 violation found (T3)
2. test_effectiveness < 95%
3. Gate 2 triggered
4. `REWRITE_REQUIRED: true`

**Verification**:
- [x] `directive.REWRITE_REQUIRED: true`
- [x] `directive.gate_triggered: "Gate 2: Threshold"`
- [x] `test_effectiveness` shown below 95%

---

## Test P0.8-3: Full Pipeline - Advisory Only

**Prompt**:
```
/test-audit tests/fixtures/test-audit/t2-violation/
```

**Expected Behavior**:
1. P1 violation found (T2)
2. test_effectiveness >= 95% (small impact)
3. Neither gate triggered
4. `REWRITE_REQUIRED: false` (advisory)

**Verification**:
- [ ] `directive.REWRITE_REQUIRED: false`
- [ ] `files_advisory` list present
- [ ] Reason: "Above 95% threshold"
- [ ] No automatic rewrite triggered

**Notes:** Skipped for directly running P0.8-5 which would validate all the fixtures
---

## Test P0.8-4: Full Pipeline - Clean Tests

**Prompt**:
```
/test-audit tests/fixtures/test-audit/clean/
```

**Expected Behavior**:
1. No violations found
2. `REWRITE_REQUIRED: false`
3. No recommendations

**Verification**:
- [ ] `directive.REWRITE_REQUIRED: false`
- [ ] No violations in detection output
- [ ] Summary shows 100% test effectiveness

**Notes:** Skipped for directly running P0.8-5 which would validate all the fixtures
---

## Test P0.8-5: Full Pipeline - All Fixtures

**Prompt**:
```
/test-audit tests/fixtures/test-audit/
```

**Expected Behavior**:
1. All 6 fixtures classified
2. 5 flagged for deep analysis
3. Multiple violations detected
4. Gate 1 triggered (P0 violations exist)
5. Priority rewrite list generated

**Verification**:
- [x] 6 files in classification output
- [x] 4+ files with violations in detection
- [x] `files_to_rewrite` ordered by priority (P0 first)
- [x] `files_advisory` includes high-effectiveness P1 files

---

## Test P0.8-6: Menu Visibility

**Action**: Type `/` in Claude Code to open skill menu

**Expected Behavior**:
- `test-audit` SHOULD appear in the menu
- `test-classification` should NOT appear
- `mock-detection` should NOT appear

**Verification**:
- [x] `test-audit` in menu (user-invocable: true)
- [x] `test-classification` NOT in menu
- [x] `mock-detection` NOT in menu

---

## Test P0.8-7: Model Selection Verification

**Prompt**:
```
/test-audit tests/fixtures/test-audit/t1-violation/
After running, show me the diagnostic outputs to verify model selection.
```

**Verification**:
- [x] Check `logs/diagnostics/test-classification-*.yaml` shows `model: haiku`
- [x] Check `logs/diagnostics/mock-detection-*.yaml` shows `model: sonnet`
- [x] Check `logs/diagnostics/test-audit-*.yaml` shows `model: sonnet`

**Notes:** Validated implicitly while executing other tests.
---

## Post-Test Checklist (P0.6-8)

- [x] test-audit appears in `/` menu
- [x] test-classification and mock-detection NOT in menu
- [x] Classification correctly categorizes by filename
- [x] Classification flags mock+integration mismatches
- [x] Classification counts verification_lines correctly
- [x] Detection uses Sonnet (not Haiku)
- [x] Detection tracks violation_scope (not just line)
- [x] Detection calculates test_effectiveness
- [x] Synthesis applies two-gate logic correctly
- [x] Gate 1 triggers on any P0 violation
- [x] Gate 2 triggers on P1 + <95% effectiveness
- [x] Advisory mode for P1 with >=95% or P2 only
- [x] Rewrite direction provided (not pseudo-code)
- [x] All YAML outputs valid and parseable

---

## Test Results Template (P0.6-8)

```yaml
# tests/logs/test-audit-results-YYYYMMDD.yaml
test_date: 2026-01-XX
tester: [name]
session_id: [from /context]

results:
  classification_clean:
    status: pass|fail
    notes: ""
  classification_t1:
    status: pass|fail
    needs_deep_analysis: true|false
    notes: ""
  classification_integration:
    status: pass|fail
    notes: ""
  classification_mixed:
    status: pass|fail
    risk_detected: true|false
    notes: ""
  detection_t1:
    status: pass|fail
    priority: P0|P1|P2
    notes: ""
  detection_t3plus:
    status: pass|fail
    priority: P0|P1|P2
    notes: ""
  detection_t2:
    status: pass|fail
    effectiveness: X%
    notes: ""
  full_pipeline_gate1:
    status: pass|fail
    rewrite_required: true|false
    notes: ""
  full_pipeline_gate2:
    status: pass|fail
    rewrite_required: true|false
    notes: ""
  full_pipeline_advisory:
    status: pass|fail
    rewrite_required: true|false
    notes: ""
  full_pipeline_clean:
    status: pass|fail
    notes: ""
  full_pipeline_all:
    status: pass|fail
    files_classified: X
    violations_found: X
    notes: ""
  menu_visibility:
    status: pass|fail
    notes: ""
  model_selection:
    status: pass|fail
    haiku_used_for_classification: true|false
    sonnet_used_for_detection: true|false
    sonnet_used_for_synthesis: true|false
    notes: ""

overall: pass|fail
blockers: []
```

---

## Known Limitations (P0.6-8)

1. **Test effectiveness calculation**: Requires accurate line counting which may vary by code style
2. **Violation scope detection**: Call graph analysis has heuristic limits
3. **T3+ (broken chain)**: Requires understanding data flow intent, may have false positives
4. **Automatic rewrite**: Opus implements fixes based on direction; quality depends on direction clarity
