# P4 Manual Test Protocol - Review Skills & Standalone Agents

**Purpose**: Verify code-review skill sections and bug-magnet-data consumer integrations.
**Prerequisite**: P0-P3 implementation complete, hooks restored, skills synced to `.claude/`

---

## Pre-Test Setup

1. Restore hooks config from Session 27-28 commits
2. Run `just sync-hooks` to sync hooks to `.claude/settings.json`
3. Copy skills to `.claude/skills/` (code-review, bug-magnet-data if implemented)
4. Copy agents to `.claude/agents/` (bulwark-code-auditor, bulwark-implementer if implemented)
5. Ensure `logs/` directory structure exists
6. Start a **fresh Claude Code session**
7. Verify governance protocol appears (SessionStart hook working)

---

# P4.1 Code-Review Skill Tests

## Test P4.1-1: Direct Invocation (Security Section)

**Prompt** (conversational, non-developer language):
```
I just joined the team and was asked to review the user authentication module before we go live. Can you take a look at scripts/components/user-service.ts and let me know if there's anything concerning? I'm particularly worried about customer data safety.
```

**Expected Behavior**:
1. Claude loads code-review skill
2. Phase 1: `just typecheck` and `just lint` run and pass
3. Phase 2: LLM review identifies security issues
4. Findings include SQL injection, hardcoded secrets

**Verification**:
- [x] Skill loaded (visible in response)
- [x] Phase 1 passes (no blocking errors)
- [x] SQL injection detected in `getUserByEmail` (CRITICAL) - SEC-003 line 14
- [x] SQL injection detected in `authenticateUser` (CRITICAL) - SEC-003 line 25
- [x] SQL injection detected in `updateUserProfile` (CRITICAL) - SEC-003 line 40
- [x] Hardcoded API key detected (CRITICAL) - SEC-001 line 4
- [x] Hardcoded JWT secret detected (CRITICAL) - SEC-002 line 5
- [x] Path traversal risk in `downloadUserFile` (CRITICAL or IMPORTANT) - SEC-005 lines 45-46
- [x] Insecure token generation noted (IMPORTANT) - SEC-006 lines 51-53
- [x] Output in YAML format or structured findings

**Result**: [x] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Session 33 (2026-02-01). All expected findings detected. Bonus findings: SEC-004 (plaintext password), SEC-007 (user enumeration), TS-001 (unsafe assertion). Diagnostic log written to logs/diagnostics/code-review-2026-02-01T120000Z.yaml. DEF-P4-003 and DEF-P4-004 fixed prior to this test.

---

## Test P4.1-2: Direct Invocation (Type Safety Section)

**Prompt** (conversational):
```
The data processing module has been giving us intermittent issues in production -
sometimes things work, sometimes we get weird undefined errors. Could you check
scripts/components/data-processor.ts for any issues with how data types are handled?
```

**Expected Behavior**:
1. Claude loads code-review skill
2. Phase 1 passes
3. Phase 2 identifies type safety issues
4. Findings include excessive `any` usage

**Verification**:
- [x] Skill loaded
- [x] Phase 1 passes
- [x] Excessive `any` in cache property detected (CRITICAL or IMPORTANT) - TS-003 lines 9-10
- [x] Excessive `any` in config property detected - TS-003 lines 9-10
- [x] `any` in function parameters detected (processRecords, transformRecord) - TS-004 (8 functions)
- [x] `any` return types detected - TS-004, TS-005
- [x] Unsafe assertion `(e as any).message` detected - TS-002 lines 37-38
- [x] `as unknown as` pattern noted as type-unsafe - TS-007 (parseResponse)

**Result**: [x] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Session 33 (2026-02-01). All expected findings detected. Bonus findings: TS-001 (unvalidated JSON.parse), TS-006 (null gap on Map.get). Root cause analysis included: "any-driven development" pattern identified. Diagnostic log: logs/diagnostics/code-review-2026-02-01T121500Z.yaml

---

## Test P4.1-3: Direct Invocation (Linting Section)

**Prompt** (conversational):
```
A colleague wrote this workflow processing code and I need to maintain it now,
but I can barely understand what it does. The function names don't make sense
to me. Can you review scripts/components/workflow-handler.ts and tell me if
this follows good coding practices?
```

**Expected Behavior**:
1. Claude loads code-review skill
2. Phase 1 passes
3. Phase 2 identifies linting issues
4. Findings include naming and complexity issues

**Verification**:
- [x] Skill loaded
- [x] Phase 1 passes
- [x] Single-letter function name `p` detected (IMPORTANT) - LINT-001
- [x] Single-letter function name `x` detected - LINT-001
- [x] Single-letter function name `z` detected - LINT-001
- [x] Deep nesting (8+ levels) in `p` detected - LINT-003 (8 levels)
- [x] Generic variable names (`s`, `d`, `c`, `i`, `r`) detected - LINT-002 (10 vars)
- [x] High cyclomatic complexity noted - LINT-004 (~15 decision points, god function)
- [x] Suggestions for refactoring provided - LINT-001 recommendations

**Result**: [x] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Session 33 (2026-02-01). All expected findings detected. Bonus findings: LINT-005 (pyramid of doom in x), LINT-006 (14x duplicate `as Record` casts), LINT-007 (early return missing), LINT-008 (magic strings), LINT-009 (abbreviated 'op'). Diagnostic log: logs/diagnostics/code-review-2026-02-01T123000Z.yaml

---

## Test P4.1-4: Direct Invocation (Coding Standards Section)

**Prompt** (conversational):
```
I'm trying to understand how our configuration system works but it seems to do
a lot of different things. When I call getConfig it sometimes initializes things
automatically which surprised me. Can you review scripts/components/config-manager.ts
and tell me if this follows our team's coding standards?
```

**Expected Behavior**:
1. Claude loads code-review skill
2. Phase 1 passes
3. Phase 2 identifies coding standards issues
4. Findings include multiple responsibilities and side effects

**Verification**:
- [x] Skill loaded
- [x] Phase 1 passes
- [x] Multiple responsibilities detected (config, connections, cache, logging, metrics) - STD-002 (7 responsibilities)
- [x] Global mutable state detected - STD-003 (module-level variables)
- [x] Implicit side effects in `getConfig` detected (auto-initialization) - STD-001 (DB, cache, logging, metrics, feature flags)
- [x] Mixed concerns in `processRequest` detected - STD-005 (request handler in config manager)
- [x] Single Responsibility Principle violation noted - STD-002, STD-005
- [x] "No Magic" principle violation noted - STD-001, STD-003, STD-004

**Result**: [x] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Session 33 (2026-02-01). All expected findings detected. Bonus findings: STD-006 (5x console.log in prod), STD-007 (missing JSDoc on 7 exports), STD-008 (resetSystem incomplete). Root cause analysis included. Diagnostic log: logs/diagnostics/code-review-2026-02-01T124500Z.yaml

---

## Test P4.1-5: Full Review (All Sections)

**Prompt** (conversational):
```
We're about to ship a major release and I want to make sure the components
in scripts/components/ are production-ready. Can you do a comprehensive
code review of all files in that directory?
```

**Expected Behavior**:
1. Claude loads code-review skill
2. All 4 files reviewed
3. All 4 sections applied to each file
4. Summary report generated

**Verification**:
- [x] All 4 files analyzed (user-service, data-processor, workflow-handler, config-manager) - files_count: 4
- [x] Security findings from user-service - SEC-001 to SEC-005 (5 critical)
- [x] Type Safety findings from data-processor - TS-001 (1 critical)
- [x] Linting findings from workflow-handler - 3 important, 1 suggestion
- [x] Standards findings from config-manager - 1 important, 1 suggestion
- [x] Summary shows CRITICAL/IMPORTANT/SUGGESTION counts - 6/6/3
- [x] Diagnostic output written to `logs/diagnostics/` - code-review-20260201-001.yaml

**Result**: [x] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Session 33 (2026-02-01). All 4 files reviewed with all 4 sections. Verdict: NOT_PRODUCTION_READY with blocking issues (SQL injection, hardcoded secrets, broken auth). Total 15 findings across sections. Diagnostic log: logs/diagnostics/code-review-20260201-001.yaml

---

## Test P4.1-6: Section Flag (--section=security)

**Prompt** (slash command):
```
/code-review scripts/components/user-service.ts --section=security
```

**Expected Behavior**:
1. Only Security section runs
2. Other sections skipped
3. Only security findings reported

**Verification**:
- [x] Only Security findings in output - SEC-001 through SEC-008 (8 critical)
- [x] No Type Safety findings
- [x] No Linting findings
- [x] No Standards findings

**Result**: [x] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Session 33 (2026-02-01). Section flag correctly limited review to security-only. All 8 findings are security section. Diagnostic log: logs/diagnostics/code-review-20260201-001.yaml (overwritten from P4.1-5)

---

## Test P4.1-7: Quick Mode (--quick)

**Prompt** (slash command):
```
/code-review scripts/components/user-service.ts --quick
```

**Expected Behavior**:
1. File is ~60 lines → Security + Type Safety only (<500 lines threshold)
2. Linting and Standards skipped
3. Faster review

**Verification**:
- [x] Security section runs - SEC-001 through SEC-007
- [x] Type Safety section runs - TS-001 (double assertion)
- [x] Linting section skipped - No LINT-* findings
- [x] Standards section skipped - No STD-* findings
- [x] Mode noted as "quick" in output - `mode: quick`

**Result**: [x] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Session 33 (2026-02-01). File is 59 lines → falls in 50-500 tier → Security + Type Safety only. Tiering logic correct. 8 findings (7 security, 1 type safety). Diagnostic log: logs/diagnostics/code-review-20260201-001.yaml (overwritten)

---

## Test P4.1-8: Menu Visibility

**Action**: Type `/` in Claude Code to open skill menu

**Expected Behavior**:
- `code-review` SHOULD appear in the menu
- Can be invoked as `/code-review [path]`

**Verification**:
- [x] Skill appears in `/` menu
- [x] `user-invocable: true` working correctly

**Result**: [x] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Session 33 (2026-02-01). Implicitly verified via P4.1-6 and P4.1-7 which used `/code-review` slash command invocation. Skill correctly appears in menu and responds to direct invocation.

---

# P4.1 Pipeline Integration Tests

These tests verify the Code Review Pipeline works when orchestrated by Claude (LLM judgment), not user-specified flags.

## Test P4.1-9: Pipeline Trigger (Mixed Issues)

**Fixtures**: `scripts/services/payment-gateway.ts`, `scripts/services/analytics-tracker.ts`

**Prompt** (conversational):
```
We just finished a sprint and pushed new payment and analytics code to
scripts/services/. Before we merge to main, can you run the full code
review pipeline on those files? I want to make sure we catch any issues
before deployment.
```

**Expected Behavior**:
1. Claude recognizes this as a pipeline request (not direct skill invocation)
2. Code Review Pipeline triggered
3. All 4 section sub-agents spawn (SecurityReviewer, TypeSafetyReviewer, LintReviewer, StandardsReviewer)
4. ReviewSynthesizer consolidates findings
5. Output follows pipeline template format

**Verification**:
- [x] Pipeline triggered (not just `/code-review` direct invocation)
- [x] Sub-agents spawned for each section (visible in output or logs)
- [x] payment-gateway.ts findings:
  - [x] Security: Hardcoded STRIPE_SECRET_KEY, SQL injection
  - [x] Type Safety: `any` usage in paymentCache, metadata param
  - [x] Standards: Global mutable state, implicit initialization
- [x] analytics-tracker.ts findings:
  - [x] Security: Hardcoded ANALYTICS_API_KEY
  - [x] Type Safety: `any` in eventQueue, sessionData
  - [x] Linting: Single-letter function `t`, deep nesting
- [x] Consolidated summary with severity counts
- [x] Output in pipeline YAML format (not direct format)

**Result**: [x] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: Session 33 (2026-02-01). Initial prompt required amendment to explicitly invoke pipeline-templates skill. Hybrid execution pattern observed: Phase 1 (static analysis) ran once in main context, Phase 2 spawned 4 parallel general-purpose sub-agents for sections. This is efficient - avoids redundant typecheck/lint runs. Pipeline summary: 80 unique findings (40 critical) after deduplication. Gate: FAILED. Logs: security-review-stage1.yaml, type-safety-review-stage2.yaml, code-review-standards-findings.yaml, review-report.yaml (synthesis).

---

## Test P4.1-10: Pipeline Section Routing

**Fixtures**: `scripts/services/payment-gateway.ts`

**Prompt** (conversational):
```
I'm concerned about the security of our new payment code. Can you have
the security team review scripts/services/payment-gateway.ts specifically
for vulnerabilities? Don't worry about code style for now.
```

**Expected Behavior**:
1. Claude interprets this as security-focused review
2. May trigger pipeline with emphasis on Security section
3. OR may invoke code-review with implicit section focus
4. Security findings prioritized in output

**Verification**:
- [-] Security findings prominent (SQL injection, hardcoded keys)
- [-] Type Safety/Linting findings either absent or de-prioritized
- [-] Response acknowledges security focus
- [-] Actionable fix recommendations for security issues

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL / [x] SKIPPED
**Notes**: Session 33 (2026-02-01). Skipped - redundant after P4.1-9 comprehensive pipeline test. Security-focused review already validated via P4.1-6 (--section=security flag) and P4.1-9 security stage findings.

---

## Test P4.1-11: Pipeline with Fix Request

**Fixtures**: `scripts/services/analytics-tracker.ts`

**Prompt** (conversational):
```
The analytics code in scripts/services/analytics-tracker.ts has some
issues that are blocking our release. Can you review it and fix any
critical problems you find?
```

**Expected Behavior**:
1. Code Review Pipeline runs
2. Critical issues identified
3. FixWriter stage may trigger (if critical issues found)
4. Fixes applied OR recommendations provided

**Verification**:
- [x] Review completed with findings
- [x] Critical issues identified (hardcoded API key is security-critical)
- [x] Either:
  - [ ] Fixes applied automatically (FixWriter triggered), OR
  - [x] Fix recommendations provided with clear guidance
- [ ] Changes verified if fixes applied

**Result**: [ ] PASS / [x] SOFT PASS / [ ] FAIL
**Notes**: Session 33 (2026-02-01). Claude correctly identified 5 issue categories and chose Fix Validation Pipeline. However, issue identification bypassed code-review skill (no structured sections, OWASP patterns, severity tiers). See OBS-003 below.

---

### OBS-003: Pipeline Routing and Skill Bypass (Session 33)

During P4.1-11, Claude identified issues by reading the file directly rather than using the code-review skill's structured analysis.

**Observed behavior:**
1. Claude chose Fix Validation Pipeline (reasonable for "review + fix" prompt)
2. Identified 5 issue categories correctly (security, type safety, code quality)
3. BUT: Did not load code-review skill - used direct LLM judgment

**Gap 1: Issue identification without code-review skill**
- No structured sections (Security, Type Safety, Linting, Standards)
- No OWASP pattern references
- No severity tier classification (critical/important/suggestion)
- No diagnostic log output

**Gap 2: Fix Validation CodeReviewer ≠ code-review skill**
- Stage 5 (CodeReviewer) focuses on fix verification
- Does not use code-review skill's structured analysis
- Missing: Security patterns, type safety checks, standards validation

**Action Items (P6+ Enhancements):**

| ID | Action | Reference |
|----|--------|-----------|
| OBS-003-A | Amend Code Review → FixWriter pipeline trigger language in pipeline-templates | `tests/manual-test-protocol-P4.md#OBS-003` |
| OBS-003-B | Update Fix Validation Stage 5 (CodeReviewer) to use code-review skill | `tests/manual-test-protocol-P4.md#OBS-003` |
| OBS-003-C | Investigate routing: when should "review + fix" trigger Code Review vs Fix Validation? | `tests/manual-test-protocol-P4.md#OBS-003` |

---

## Pipeline Integration Post-Test Checklist

- [ ] Pipeline can be triggered via conversational prompt
- [ ] Sub-agents spawn for each section
- [ ] Mixed issues routed to correct sections
- [ ] Findings consolidated by ReviewSynthesizer
- [ ] Pipeline output format differs from direct invocation format
- [ ] Security-focused requests prioritize security findings
- [ ] Fix requests can trigger FixWriter stage

---

# P4.2 Bug-Magnet-Data Consumer Tests

**Purpose**: Verify bug-magnet-data integration in test-audit, bulwark-verify, and bulwark-fix-validator.
**Prerequisite**: P4.2 implementation complete, consumers updated (T-013, T-014, T-015)
**Fixtures**: `scripts/handlers/input-handler.ts`, `tests/handlers/input-handler.test.ts`

---

## Pre-Test Setup (P4.2)

1. Ensure fixtures exist:
   - `scripts/handlers/input-handler.ts` (source component)
   - `tests/handlers/input-handler.test.ts` (test file with edge case gaps)
2. Run `just sync-hooks` to sync hooks
3. Verify `just typecheck` and `just lint` pass
4. Start a **fresh Claude Code session**

---

## Test P4.2-1: test-audit Edge Case Gap Detection

**Fixture**: `tests/handlers/input-handler.test.ts`
**Backup**: `backup/tests/handlers/input-handler.test.ts` (restore if modified)

**Prompt** (conversational):
```
I wrote some tests for our input handler but I'm worried they might not cover
all the edge cases. Can you audit tests/handlers/input-handler.test.ts and
tell me if there are any gaps in my test coverage? Please just list the issues
and recommendations - don't make any changes to the file yet.
```

**Expected Behavior**:
1. Claude loads test-audit skill
2. Classification stage runs (Haiku)
3. Mock detection stage runs (Sonnet)
4. Synthesis stage runs (Sonnet)
5. Step 7 loads bug-magnet-data for HTTP/input component type
6. Edge case gaps identified

**Verification**:
- [ ] test-audit skill loaded
- [ ] Component type detected (HTTP body handler or similar)
- [ ] bug-magnet-data context file loaded
- [ ] Edge case gaps flagged:
  - [ ] Missing empty string tests (T0 - strings/boundaries)
  - [ ] Missing unicode tests (T1 - strings/unicode)
  - [ ] Missing injection tests (T1 - strings/injection)
  - [ ] Missing number boundary tests (T0 - 0, negative, MAX_INT)
  - [ ] Missing empty array tests (T0 - collections/arrays)
- [ ] Recommendations reference bug-magnet-data categories
- [ ] Diagnostic output written to `logs/diagnostics/test-audit-*.yaml`

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.2-2: bulwark-verify Edge Case Injection

**Fixture**: `scripts/handlers/input-handler.ts`
**Backup**: `backup/scripts/handlers/input-handler.ts`

**Prompt** (slash command):
```
/bulwark-verify scripts/handlers/input-handler.ts
```

**Expected Behavior**:
1. Claude loads bulwark-verify skill
2. Component type detected (HTTP body handler)
3. bug-magnet-data context file loaded (context/http-body.md)
4. T0 + T1 edge cases loaded from data files
5. Sonnet sub-agent generates verification script
6. Script includes edge cases from bug-magnet-data

**Verification**:
- [ ] bulwark-verify skill loaded
- [ ] Component type identified
- [ ] bug-magnet-data context file loaded
- [ ] Verification script generated to `tmp/verification/input-handler-verify.*.js`
- [ ] Script includes T0 edge cases:
  - [ ] Empty string test (`""`)
  - [ ] Very long string test
  - [ ] Zero value test
  - [ ] Empty array test
- [ ] Script includes T1 edge cases:
  - [ ] Unicode characters
  - [ ] Special characters (quotes, escapes)
- [ ] Destructive patterns excluded or marked manual-only
- [ ] Script syntax validated (passes `node --check`)

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.2-3: bulwark-fix-validator Edge Case Analysis

**Prerequisite**: This test requires a debug report and a fix to validate. Run the setup prompt first.

**Setup Prompt** (to create debug report):
```
The input handler in scripts/handlers/input-handler.ts has a bug - when a user
submits a username with only spaces, it passes validation but causes issues
downstream. Can you analyze this issue?
```

**Expected**: IssueAnalyzer produces debug report in `logs/debug-reports/`

**Then apply this fix** (manually or ask Claude):
```typescript
// In validateUserInput, after checking username length:
else if (data.username.trim().length < 3) {
  errors.push('Username must have at least 3 non-whitespace characters');
}
```

**Test Prompt** (after fix applied):
```
I applied the fix for the whitespace username bug. Can you validate that the
fix is correct and complete?
```

**Expected Behavior**:
1. Claude loads bulwark-fix-validator (or invokes via Task)
2. Reads debug report from IssueAnalyzer
3. Step 5 performs edge case analysis using bug-magnet-data
4. Fix checked against T0/T1 edge cases
5. Validation report generated

**Verification**:
- [ ] Fix validator invoked
- [ ] Debug report read
- [ ] Edge case analysis performed (Step 5):
  - [ ] T0 edge cases checked (empty string, single char, spaces-only)
  - [ ] T1 edge cases checked if applicable (unicode whitespace)
- [ ] `edge_cases_handled` section in validation report
- [ ] Each edge case has status: handled | not_handled | not_applicable
- [ ] Unhandled edge cases flagged as risks
- [ ] Confidence level assessed based on edge case coverage
- [ ] Validation report written to `logs/validations/fix-validation-*.yaml`

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.2-4: bug-magnet-data Tier Loading

**Prompt** (technical verification):
```
I want to understand what edge case data is available. Can you show me the
bug-magnet-data categories and what tier each belongs to?
```

**Expected Behavior**:
1. Claude reads bug-magnet-data skill
2. Lists available categories by tier (T0, T1, T2, T3)
3. Explains which tiers are loaded when

**Verification**:
- [ ] T0 categories listed (boundaries, null handling)
- [ ] T1 categories listed (basic injection, unicode)
- [ ] T2 categories listed (dates, encoding, formats)
- [ ] T3/manual-only patterns explained
- [ ] Safety filtering (`safe_for_automation: false`) explained

**Result**: [ ] PASS / [ ] SOFT PASS / [ ] FAIL
**Notes**: _____

---

## Post-Test Checklist (P4.2)

### test-audit Consumer
- [ ] bug-magnet-data loaded in Step 7
- [ ] Component type detected correctly
- [ ] Context file loaded for component type
- [ ] Edge case gaps identified
- [ ] Recommendations reference bug-magnet-data categories

### bulwark-verify Consumer
- [ ] bug-magnet-data loaded in Step 3
- [ ] T0 + T1 edge cases included in generated script
- [ ] Destructive patterns excluded from automation
- [ ] Script syntax valid

### bulwark-fix-validator Consumer
- [ ] bug-magnet-data loaded in Step 5
- [ ] Edge case analysis documented in validation report
- [ ] Each edge case has status assessment
- [ ] Unhandled cases flagged as risks

### General
- [ ] All three consumers use bug-magnet-data correctly
- [ ] Diagnostic outputs include edge case loading info
- [ ] No regressions in consumer core functionality

---

## Cleanup Steps (P4.2)

### CLEANUP-P4.2-000: Restore Fixtures from Backup (if modified during testing)

```bash
# Restore source fixture
cp backup/scripts/handlers/input-handler.ts scripts/handlers/

# Restore test fixture
cp backup/tests/handlers/input-handler.test.ts tests/handlers/
```

### CLEANUP-P4.2-001: Remove Test Fixtures (after all testing complete)

```bash
# Remove source fixtures
rm -rf scripts/handlers/

# Remove test fixtures
rm -rf tests/handlers/

# Remove backup
rm -rf backup/

# Verify directories empty or removed
ls scripts/ | grep -v claude-project | grep -v hooks | grep -v statusline | grep -v sync-hooks
ls tests/ 2>/dev/null || echo "tests/ removed"
```

### CLEANUP-P4.2-002: Clean Generated Files

```bash
# Clean verification scripts
rm -f tmp/verification/input-handler-*

# Clean debug reports (optional - may want to keep)
# rm -f logs/debug-reports/*input-handler*

# Clean validation reports (optional)
# rm -f logs/validations/*input-handler*

# Clean diagnostic logs
rm -f logs/diagnostics/test-audit-*.yaml
rm -f logs/diagnostics/bulwark-verify-*.yaml
rm -f logs/diagnostics/bulwark-fix-validator-*.yaml
```

### CLEANUP-P4.2-003: Verify Clean State

```bash
just typecheck
just lint
git status
```

### Cleanup Verification Checklist (P4.2)

- [ ] `scripts/handlers/` removed
- [ ] `tests/handlers/` removed
- [ ] `backup/` removed
- [ ] Generated verification scripts cleaned
- [ ] `just typecheck` passes
- [ ] `just lint` passes
- [ ] No untracked test artifacts in git status

---

# P4.3 Bulwark-Code-Auditor Tests

*To be added after P4.3 implementation*

---

# P4.4 Bulwark-Implementer Tests

*To be added after P4.4 implementation*

---

## Post-Test Checklist (P4.1)

- [x] code-review appears in `/` menu (P4.1-8)
- [x] Phase 1 (static tools) runs before Phase 2 (LLM) (all tests)
- [x] Phase 1 failures block Phase 2 (fail fast) (verified in skill design)
- [x] Security section detects SQL injection (P4.1-1, P4.1-6)
- [x] Security section detects hardcoded secrets (P4.1-1, P4.1-6)
- [x] Type Safety section detects `any` abuse (P4.1-2)
- [x] Type Safety section detects unsafe assertions (P4.1-2)
- [x] Linting section detects poor naming (P4.1-3)
- [x] Linting section detects deep nesting (P4.1-3)
- [x] Standards section detects multiple responsibilities (P4.1-4)
- [x] Standards section detects implicit side effects (P4.1-4)
- [x] `--section` flag limits to single section (P4.1-6)
- [x] `--quick` flag applies tiered review (P4.1-7)
- [x] Diagnostic output written to `logs/diagnostics/` (all tests)
- [x] All YAML outputs valid and parseable (verified)

**P4.1 Testing Complete**: Session 33 (2026-02-01)
- 8 PASS, 1 SOFT PASS, 1 SKIPPED
- 3 Observations recorded (OBS-001, OBS-002, OBS-003)
- 4 P6+ enhancement tasks added (P6.4, P6.5, P6.6, P6.7)

---

## Test Results Template (P4.1)

```yaml
# tests/logs/code-review-test-results-YYYYMMDD.yaml
test_date: 2026-XX-XX
tester: [name]
session_id: [from /context]

results:
  security_section:
    status: pass|fail
    sql_injection_detected: true|false
    hardcoded_secrets_detected: true|false
    notes: ""
  type_safety_section:
    status: pass|fail
    any_abuse_detected: true|false
    unsafe_assertions_detected: true|false
    notes: ""
  linting_section:
    status: pass|fail
    naming_issues_detected: true|false
    complexity_issues_detected: true|false
    notes: ""
  standards_section:
    status: pass|fail
    srp_violation_detected: true|false
    side_effects_detected: true|false
    notes: ""
  full_review:
    status: pass|fail
    files_analyzed: 4
    findings_count: X
    notes: ""
  section_flag:
    status: pass|fail
    single_section_only: true|false
    notes: ""
  quick_mode:
    status: pass|fail
    tiered_correctly: true|false
    notes: ""
  menu_visibility:
    status: pass|fail
    notes: ""

overall: pass|fail
blockers: []
```

---

## Known Limitations (P4.1)

1. **Framework detection**: May not detect framework in scripts/components/ (no package.json parent)
2. **Phase 1 dependency**: Requires `just` recipes to be working
3. **Hook integration**: PostToolUse hook may suggest pipeline after file changes
4. **LLM variability**: Same file may produce slightly different findings between runs

---

## Observations (P4.1)

### OBS-001: Post-Review Fixture Inference (Session 33)

During P4.1-6 testing, Claude inferred `user-service.ts` was a test fixture **after** completing the full review - not before or during.

**Critical timing distinction:**
- **Pre-review knowledge** ("this is a fixture") → Risk of lenient evaluation, skipped checks, or pattern-matching to expected findings
- **Post-review inference** ("this looks like a fixture based on finding density") → Review already complete, no bias introduced

The inference came after tracing data flows and cataloging findings. By that point, the evaluation was done. The observation about fixture-like density was a post-hoc explanation for why the file had so many issues, not a reason to treat it differently during analysis.

**Inference factors cited (post-review):**
1. Vulnerability concentration - 8 critical issues in 59 lines
2. Textbook patterns - Pedagogically perfect examples
3. Project context - The Bulwark is a code review tool
4. Git status - `scripts/components/` untracked (`??`)

**Fixture design validation:**
The fixtures are indistinguishable from plausible production code that happens to have problems:
- No revealing comments (e.g., `// VULNERABLE: SQL injection`)
- No revealing filenames (e.g., `insecure-example.ts`)
- Path looks like real application code
- Structure is coherent
- Vulnerabilities are the kind that actually ship in codebases

This validates both the `test-fixture-creation` skill guidelines and the code-review skill's unbiased execution.

---

### OBS-002: Self-Describing Usage Documentation (Session 33)

When asked "What are the different switches I can use for the code-review command?", Claude extracted and formatted the usage information directly from `SKILL.md`:

```
Usage: /code-review [path] [flags]

Arguments:
- path: File or directory to review (default: files in recent context)

Flags:
- --quick: Tiered review by change size
- --framework=<name>: Override auto-detected framework
- --include-git-context: Include git history for complexity findings
- --section=<name>: Run single section only

Examples:
- /code-review src/auth/
- /code-review src/api.ts --quick
- /code-review src/ --section=security
```

**Key pattern:** The skill documentation structure enables Claude to serve as its own help system:
1. Clear **Usage** section with syntax
2. **Arguments** and **Flags** tables with descriptions
3. **Examples** showing real invocations

**Action Items (P6+ Enhancements):**

| ID | Action | Reference |
|----|--------|-----------|
| OBS-002-A | Review all skills for consistent usage/args documentation pattern | `tests/manual-test-protocol-P4.md#OBS-002` |
| OBS-002-B | Add guidance to `anthropic-validator` skill for validating command-style skills have self-describing usage sections | `tests/manual-test-protocol-P4.md#OBS-002` |

**Note:** This skill took 3 sessions to plan/draft/create + 1 session to enhance. The investment in research and iterative refinement produced a skill that is both functionally robust and self-documenting.

---

## Cleanup Steps

After testing is complete, remove test fixtures to keep the codebase clean:

### CLEANUP-P4-001: Remove All Test Fixtures

```bash
# Direct invocation fixtures
rm -rf scripts/components/

# Pipeline integration fixtures
rm -rf scripts/services/

# Supporting stubs
rm -f scripts/lib/database.ts
rm -f scripts/lib/logger.ts

# Verify scripts/lib/ is empty or has only intentional files
rmdir scripts/lib/ 2>/dev/null || echo "scripts/lib/ has other files, review manually"
```

### CLEANUP-P4-002: Clean Diagnostic Logs

```bash
rm -f logs/diagnostics/code-review-*.yaml
```

### CLEANUP-P4-003: Verify Clean State

```bash
# Verify typecheck still passes after cleanup
just typecheck

# Verify no orphaned test artifacts
git status
```

### Cleanup Verification Checklist

- [ ] `scripts/components/` removed (direct invocation fixtures)
- [ ] `scripts/services/` removed (pipeline integration fixtures)
- [ ] `scripts/lib/database.ts` removed
- [ ] `scripts/lib/logger.ts` removed
- [ ] Diagnostic logs cleaned (optional)
- [ ] `just typecheck` passes
- [ ] `just lint` passes
- [ ] No untracked test artifacts in git status

---

## Design Reference

- **Skill**: `skills/code-review/SKILL.md`
- **Task Brief**: `plans/task-briefs/P4.1-2-review-skills.md`
- **Synthesis Doc**: `docs/code-review-synthesis.md`
