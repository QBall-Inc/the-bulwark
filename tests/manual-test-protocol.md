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

---

# P1.2 Bulwark Issue Analyzer - Manual Test Protocol

**Purpose**: Verify bulwark-issue-analyzer agent correctly analyzes issues to identify root cause, map impact, and produce debug reports.
**Prerequisite**: P1.2 implementation complete, agent copied to `.claude/agents/`
**Design**: Wrapper agent that loads issue-debugging skill and produces debug reports at `logs/debug-reports/`

---

## Pre-Test Setup (P1.2)

1. Ensure agent is copied to `.claude/agents/bulwark-issue-analyzer.md`
2. Ensure skills exist:
   - `skills/issue-debugging/SKILL.md`
   - `skills/subagent-output-templating/SKILL.md`
   - `skills/subagent-prompting/SKILL.md`
3. Ensure test fixtures exist in `tests/fixtures/issue-analyzer/`
4. Ensure `logs/debug-reports/` and `logs/diagnostics/` directories exist
5. Start a fresh Claude Code session
6. **Note**: Agents don't appear in `/` menu (that's for skills only)

---

## Test P1.2-1: Conversational Invocation - Production Bug

**Prompt** (conversational - agents are invoked via Task tool, not slash commands):
```
Please analyze the issue in tests/fixtures/issue-analyzer/production-bug/
The tests pass but users report login failures for new accounts.
Use the bulwark-issue-analyzer agent to investigate.
```

**Expected Behavior**:
1. Orchestrator spawns agent via Task tool with Sonnet model
2. Agent investigates code, forms hypotheses
3. Debug report written to `logs/debug-reports/`
4. Diagnostics written to `logs/diagnostics/`
5. Summary returned with debug report path
6. No code modifications (git status clean)

**Verification**:
- [x] Agent spawned via Task tool (check conversation)
- [x] Debug report exists with correct schema
- [x] Root cause identified (should find null check issue in `generateWelcome`)
- [x] Validation plan has tiered tests (P1/P2/P3)
- [x] Complexity assessment present
- [x] No files modified outside `logs/`

**Expected Results Reference**: `tests/fixtures/issue-analyzer-expected/production-bug.yaml`

---

## Test P1.2-2: Conversational Invocation - Test Bug

**Prompt** (conversational):
```
Please analyze the issue in tests/fixtures/issue-analyzer/test-bug/
Tests are flaky - they pass locally but fail in CI randomly.
Use the bulwark-issue-analyzer agent to investigate.
```

**Expected Behavior**:
1. Agent investigates test code (not just production code)
2. Identifies test code as the source of the issue
3. Root cause points to test flakiness, not production bug

**Verification**:
- [ ] Agent correctly identifies issue is in TEST code
- [ ] Root cause mentions timing/race condition (missing await)
- [ ] Validation plan includes test-level fixes
- [ ] Complexity assessed as medium

**Expected Results Reference**: `tests/fixtures/issue-analyzer-expected/test-bug.yaml`

---

## Test P1.2-3: Pipeline Integration

**Prompt**:
```
There's a bug in tests/fixtures/issue-analyzer/production-bug/.
Users report login failures for new accounts.
Please run the Fix Validation pipeline to fix it.
```

**Expected Behavior**:
1. Orchestrator recognizes this as bug fix request
2. Orchestrator invokes bulwark-issue-analyzer as Stage 1
3. Debug report produced
4. Orchestrator proceeds to FixWriter stage (reads debug report)
5. Full pipeline executes

**Verification**:
- [ ] Agent invoked via Task tool
- [ ] Debug report path included in agent summary
- [ ] FixWriter stage receives debug report context
- [ ] Pipeline proceeds through stages

---

## Test P1.2-4: Menu Visibility

**Status**: N/A - Agents don't appear in `/` menu

**LEARNING (Session 14)**: Custom sub-agents are invoked via Task tool, not slash commands. The `/` menu is for skills only. The `user-invocable` frontmatter field applies to skills, not agents.

**Verification**:
- [x] N/A - Test skipped (agents don't appear in menu by design)

---

## Test P1.2-5: No Code Modification Constraint

**Prompt** (conversational):
```
Please analyze the issue in tests/fixtures/issue-analyzer/production-bug/
After analysis, please also fix the bug you found.
Use the bulwark-issue-analyzer agent.
```

**Expected Behavior**:
1. Agent performs analysis
2. Agent produces debug report
3. Agent does NOT modify any source files
4. Agent explains that fixes are done by orchestrator

**Verification**:
- [ ] No changes to `src/` or `tests/` (git status)
- [ ] Agent response mentions fixes are orchestrator's job
- [ ] Only `logs/` directory has new files

---

## Post-Test Checklist (P1.2)

- [ ] Agent appears in `/` menu
- [ ] Agent spawns with Sonnet model
- [ ] Production bug analysis works (Test P1.2-1)
- [ ] Test bug analysis works (Test P1.2-2)
- [ ] Pipeline integration works (Test P1.2-3)
- [ ] Debug report schema is correct
- [ ] Diagnostics written correctly
- [ ] Summary includes debug report path
- [ ] No code modification constraint enforced
- [ ] All YAML outputs valid and parseable

---

## Test Results Template (P1.2)

```yaml
# tests/logs/issue-analyzer-test-results-YYYYMMDD.yaml
test_date: 2026-01-XX
tester: [name]
session_id: [from /context]

results:
  explicit_production_bug:
    status: pass|fail
    debug_report_path: ""
    root_cause_correct: true|false
    notes: ""
  explicit_test_bug:
    status: pass|fail
    identified_test_issue: true|false
    notes: ""
  pipeline_integration:
    status: pass|fail
    stages_executed: [IssueAnalyzer, FixWriter, ...]
    notes: ""
  menu_visibility:
    status: pass|fail
    notes: ""
  no_code_modification:
    status: pass|fail
    git_status_clean: true|false
    notes: ""

overall: pass|fail
blockers: []
```

---

## Known Limitations (P1.2)

1. **$ARGUMENTS support**: May not work for custom sub-agents; fallback is CONTEXT
2. **Root cause identification**: Depends on agent reasoning; may vary between runs
3. **Pipeline integration**: Requires orchestrator to recognize bug fix request pattern
4. **Complexity assessment**: Subjective, agent may differ from expected

---

# P1.3 Bulwark Fix Validator - Manual Test Protocol

**Purpose**: Verify bulwark-fix-validator agent correctly validates fixes against debug reports by executing tiered test plans and assessing confidence.
**Prerequisite**: P1.3 implementation complete, agent copied to `.claude/agents/`, P1.2 agent available
**Design**: Full Fix Validation pipeline tests - exercises IssueAnalyzer, FixWriter, TestWriter (conditional), and FixValidator stages.

---

## Pre-Test Setup (P1.3)

1. Ensure agents are copied to `.claude/agents/`:
   - `bulwark-issue-analyzer.md`
   - `bulwark-fix-validator.md`
2. Ensure skills exist:
   - `skills/issue-debugging/SKILL.md`
   - `skills/subagent-output-templating/SKILL.md`
   - `skills/subagent-prompting/SKILL.md`
3. Ensure test fixtures exist in `tests/fixtures/fix-validator/`:
   - `simple-fix/` (auth service null pointer)
   - `complex-fix/` (data service race condition)
   - `no-tests/` (calculator division by zero)
4. Ensure directories exist:
   - `logs/debug-reports/`
   - `logs/validations/`
   - `logs/diagnostics/`
   - `tmp/`
5. Start a fresh Claude Code session
6. **Note**: Agents don't appear in `/` menu (that's for skills only)

---

## Test P1.3-1: Full Pipeline - Simple Fix (Low Complexity)

**Fixture**: `tests/fixtures/fix-validator/simple-fix/`
**Bug**: Null pointer in `generateWelcome` - accesses `user.profile.displayName` without null check

**Prompt** (conversational):
```
There's a bug in tests/fixtures/fix-validator/simple-fix/
Users report "Cannot read property 'displayName' of undefined" when new accounts try to login.
Please run the Fix Validation pipeline to investigate and fix this.
```

**Expected Pipeline Flow**:
1. **IssueAnalyzer** (bulwark-issue-analyzer): Identifies null pointer in `generateWelcome`
2. **FixWriter** (orchestrator): Adds optional chaining + email fallback
3. **TestWriter** (conditional): Adds test for login without profile (existing tests don't cover)
4. **FixValidator** (bulwark-fix-validator): Validates fix, expects HIGH confidence

**Verification**:
- [x] IssueAnalyzer produces debug report at `logs/debug-reports/`
- [x] Root cause identified as null pointer access
- [x] Complexity assessed as `low`
- [x] Fix applied uses optional chaining pattern
- [x] TestWriter invoked (existing tests don't cover null profile scenario)
- [x] New test added for login without profile
- [x] FixValidator produces validation report at `logs/validations/`
- [x] Confidence level is HIGH
- [x] P1 tests pass
- [x] P2/P3 skipped (low complexity)
- [ ] Call site analysis skipped (low complexity)
- [x] Human-readable report NOT generated (low complexity)
- [x] Recommendation: proceed to review

**Expected Results Reference**: `tests/fixtures/fix-validator-expected/simple-fix.yaml`

---

## Test P1.3-2: Full Pipeline - Complex Fix (Medium Complexity)

**Fixture**: `tests/fixtures/fix-validator/complex-fix/`
**Bug**: Race condition in `fetchBatch` - missing await before Promise.all

**Prompt** (conversational):
```
There's a bug in tests/fixtures/fix-validator/complex-fix/
Tests are flaky - fetchBatch sometimes returns empty results.
Please run the Fix Validation pipeline to investigate and fix this.
```

**Expected Pipeline Flow**:
1. **IssueAnalyzer**: Identifies missing await as root cause
2. **FixWriter**: Adds await before Promise.all
3. **TestWriter**: SKIPPED (existing tests cover scenario when fix applied)
4. **FixValidator**: Full validation with call site analysis

**Verification**:
- [x] IssueAnalyzer identifies missing await
- [x] Complexity assessed as `medium`
- [x] Fix applied adds single `await` keyword
- [x] TestWriter NOT invoked (existing tests sufficient)
- [x] FixValidator performs call site analysis
- [x] All 3 callers identified (generateReport, aggregateData, prefetchUrls)
- [x] Human-readable report generated at `tmp/validation-results-*.txt`
- [x] P1 and P2 tests executed
- [x] Confidence level is HIGH or MEDIUM
- [x] May recommend running tests multiple times

**Expected Results Reference**: `tests/fixtures/fix-validator-expected/complex-fix.yaml`

---

## Test P1.3-3: Full Pipeline - No Tests (TestWriter Exercise)

**Fixture**: `tests/fixtures/fix-validator/no-tests/`
**Bug**: Division by zero in `divide` returns `{ success: true, value: Infinity }`

**Prompt** (conversational):
```
There's a bug in tests/fixtures/fix-validator/no-tests/
The divide function returns Infinity when dividing by zero instead of an error.
Please run the Fix Validation pipeline to investigate and fix this.
```

**Expected Pipeline Flow**:
1. **IssueAnalyzer**: Identifies missing zero check
2. **FixWriter**: Adds zero check with error return
3. **TestWriter**: Creates entire test file (none exists)
4. **FixValidator**: Validates new tests pass

**Verification**:
- [x] IssueAnalyzer identifies division by zero issue
- [x] Complexity assessed as `low`
- [x] Fix adds zero check before division
- [x] TestWriter invoked (no test file exists)
- [x] New test file created at `tests/calculator.test.ts`
- [x] Tests cover division by zero scenario
- [x] FixValidator validates newly created tests pass
- [x] Confidence level is HIGH or MEDIUM

**Expected Results Reference**: `tests/fixtures/fix-validator-expected/no-tests.yaml`

---

## Test P1.3-4: No Code Modification Constraint (Validator Only)

**Setup**: First run Test P1.3-1 to completion, then in a new session:

**Prompt** (conversational):
```
Please validate the fix that was applied to tests/fixtures/fix-validator/simple-fix/
If any tests fail, please fix them.
Use the bulwark-fix-validator agent directly.
Debug report: logs/debug-reports/[path from P1.3-1]
```

**Expected Behavior**:
1. FixValidator agent invoked directly (not full pipeline)
2. Agent reads debug report
3. Agent validates fix
4. Agent does NOT modify any source files
5. Agent reports findings and recommends revision if needed

**Verification**:
- [x] Agent invoked via Task tool
- [x] No changes to `src/` or `tests/` (git status)
- [x] Agent response mentions it cannot modify files
- [x] Only `logs/` directory has new files

---

## Test P1.3-5: Confidence Level Mapping

**Setup**: Modify a fixture to create test failures, then validate

**Prompt** (conversational):
```
I've introduced a regression in the simple-fix fixture.
Please validate the current state using the bulwark-fix-validator agent.
Debug report: [use existing debug report from P1.3-1]
```

**Expected Behavior**:
1. FixValidator detects test failures
2. Confidence level is LOW
3. Recommendation is "Needs revision"
4. Clear rationale for low confidence

**Verification**:
- [x] Test failures detected
- [x] Confidence level is LOW
- [x] Rationale mentions test failures
- [x] Recommendation is NOT "proceed to review"

---

## Post-Test Checklist (P1.3)

- [x] Agent spawns with Sonnet model
- [x] IssueAnalyzer → FixWriter → TestWriter → FixValidator flow works
- [x] TestWriter conditional logic works (invoked when needed, skipped when not)
- [x] Debug report correctly parsed
- [x] Tiered test execution (P1 → P2 → P3)
- [x] Complexity-based validation depth (low=P1 only, medium=P1+P2+call sites)
- [x] Call site analysis works (medium/high complexity)
- [x] Human-readable report generated for medium/high complexity
- [x] Confidence assessment uses criteria from debug report
- [x] Escalation triggers work (manual testing flagged when needed)
- [x] Validation report schema is correct
- [x] Diagnostics written correctly
- [x] Summary includes report paths
- [x] No code modification constraint enforced
- [x] All YAML outputs valid and parseable

---

## Test Results Template (P1.3)

```yaml
# tests/logs/fix-validator-test-results-YYYYMMDD.yaml
test_date: 2026-01-XX
tester: [name]
session_id: [from /context]

results:
  full_pipeline_simple:
    status: pass|fail
    debug_report_path: ""
    validation_report_path: ""
    confidence_level: high|medium|low
    test_writer_invoked: true|false
    notes: ""
  full_pipeline_complex:
    status: pass|fail
    call_sites_identified: 0
    human_readable_generated: true|false
    confidence_level: high|medium|low
    test_writer_invoked: true|false
    notes: ""
  full_pipeline_no_tests:
    status: pass|fail
    test_file_created: true|false
    confidence_level: high|medium|low
    notes: ""
  no_code_modification:
    status: pass|fail
    git_status_clean: true|false
    notes: ""
  confidence_mapping:
    status: pass|fail
    low_confidence_on_failure: true|false
    notes: ""

overall: pass|fail
blockers: []
```

---

## Known Limitations (P1.3)

1. **Test execution environment**: May need project dependencies installed to run tests
2. **TestWriter quality**: Generated tests depend on orchestrator understanding of the code
3. **Call site analysis accuracy**: Grep-based search may miss aliased imports
4. **Confidence assessment**: Subjective mapping from debug report criteria
5. **Pipeline coordination**: Requires orchestrator to correctly chain stages

---

# P2.1-3 Verification Skills - Manual Test Protocol

**Purpose**: Verify bulwark-verify (P2.3) correctly generates executable scripts using assertion-patterns (P2.1) and component-patterns (P2.2).
**Prerequisite**: P2.1-3 implementation complete, skills copied to `.claude/skills/`
**Design**: Main Context Orchestration - Orchestrator spawns Sonnet sub-agent using skill prompt templates.

---

## Pre-Test Setup (P2.1-3)

1. Ensure skills are copied to `.claude/skills/`:
   - `assertion-patterns/SKILL.md`
   - `component-patterns/SKILL.md`
   - `bulwark-verify/SKILL.md`
2. Ensure test fixtures exist in `tests/fixtures/bulwark-verify/`
3. Ensure `tmp/verification/` directory exists
4. Start a fresh Claude Code session
5. Verify `/skills` shows `bulwark-verify` (user-invocable: true)
6. Verify `assertion-patterns` and `component-patterns` are NOT in menu

---

## Test P2-1: Slash Command - Node CLI

**Prompt**:
```
/bulwark-verify tests/fixtures/bulwark-verify/node-cli/src/cli.js
```

**Expected Behavior**:
1. Language detected as Node (package.json present)
2. Component type detected as CLI
3. Sonnet sub-agent spawns for script generation
4. Script written to `tmp/verification/cli-verify.test.js`

**Verification**:
- [x] Script exists at expected location
- [x] Script is valid JavaScript
- [x] Script tests CLI behavior (spawn, capture, verify)
- [x] Log written to `logs/bulwark-verify-*.yaml`

---

## Test P2-2: Slash Command - Python Parser

**Prompt**:
```
/bulwark-verify tests/fixtures/bulwark-verify/python-parser/src/parser.py
```

**Expected Behavior**:
1. Language detected as Python (pyproject.toml present)
2. Component type detected as file parser
3. Script written to `tmp/verification/parser_test.py`

**Verification**:
- [x] Script exists at expected location
- [x] Script is valid Python
- [x] Script tests parser with real file input

---

## Test P2-3: Slash Command - HTTP Server

**Prompt**:
```
/bulwark-verify tests/fixtures/bulwark-verify/node-http/src/server.js
```

**Expected Behavior**:
1. Language detected as Node
2. Component type detected as HTTP Server
3. Script written to `tmp/verification/server-verify.test.js`

**Verification**:
- [x] Script exists at expected location
- [x] Script starts server, makes requests, verifies responses
- [x] Script includes cleanup (server shutdown)

---

## Test P2-4: Script Execution

**Prompt**:
```
/bulwark-verify tests/fixtures/bulwark-verify/node-cli/src/cli.js --execute
```

**Expected Behavior**:
1. Script generated
2. Script executed via appropriate runner
3. PASS/FAIL reported

**Verification**:
- [x] Script executed (check logs)
- [x] Clear PASS/FAIL output shown
- [x] Execution time recorded in log

---

## Test P2-5: Generic Component (Bash)

**Prompt**:
```
/bulwark-verify tests/fixtures/bulwark-verify/generic-spawner/spawner.sh
```

**Expected Behavior**:
1. No manifest files → Generic language detected
2. Component type detected as Process Spawner
3. Script written as bash (`.sh`)

**Verification**:
- [x] Language detected as Generic
- [x] Script is bash
- [x] Script tests process spawning behavior

---

## Test P2-6: test-audit Integration

**Prompt**:
```
/test-audit tests/fixtures/test-audit/t1-violation/
After running, check if P2 skills were loaded in Step 7.
```

**Expected Behavior**:
1. Test audit runs full pipeline
2. Step 7 loads assertion-patterns and component-patterns
3. Intermediate verification script may be generated

**Verification**:
- [x] test-audit completes successfully
- [x] Check if P2.1/P2.2 referenced in rewrite
- [x] Rewritten test uses structured patterns

---

## Test P2-7: Menu Visibility

**Action**: Type `/` in Claude Code to open skill menu

**Expected Behavior**:
- `bulwark-verify` SHOULD appear in the menu
- `assertion-patterns` should NOT appear
- `component-patterns` should NOT appear

**Verification**:
- [x] `bulwark-verify` in menu (user-invocable: true)
- [x] `assertion-patterns` NOT in menu
- [x] `component-patterns` NOT in menu

---

## Post-Test Checklist (P2.1-3)

- [x] bulwark-verify appears in `/` menu
- [x] assertion-patterns and component-patterns NOT in menu
- [x] Language detection works (Node, Python, Generic)
- [x] Component type detection works (CLI, HTTP, file parser, process)
- [x] Generated scripts are executable
- [x] Scripts report PASS/FAIL
- [x] test-audit Step 7 uses P2 skills
- [x] All YAML outputs valid and parseable

---

## Test Results Template (P2.1-3)

```yaml
# tests/logs/bulwark-verify-test-results-YYYYMMDD.yaml
test_date: 2026-01-XX
tester: [name]
session_id: [from /context]

results:
  node_cli_script:
    status: pass|fail
    script_path: ""
    notes: ""
  python_parser_script:
    status: pass|fail
    script_path: ""
    notes: ""
  http_server_script:
    status: pass|fail
    script_path: ""
    notes: ""
  script_execution:
    status: pass|fail
    pass_fail_reported: true|false
    notes: ""
  generic_component:
    status: pass|fail
    language_detected: ""
    notes: ""
  test_audit_integration:
    status: pass|fail
    p2_skills_loaded: true|false
    notes: ""
  menu_visibility:
    status: pass|fail
    notes: ""

overall: pass|fail
blockers: []
```

---

## Known Limitations (P2.1-3)

1. **Component type detection**: Relies on import/pattern analysis; may misclassify mixed components
2. **Language detection**: Only checks for manifest files; may not detect language for single files
3. **Script generation quality**: Depends on Sonnet sub-agent interpretation of patterns
4. **Execution environment**: Generated scripts may need dependencies to run successfully
5. **test-audit integration**: Verification script is intermediate artifact; not always generated
