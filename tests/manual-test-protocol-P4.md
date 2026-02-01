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
I just joined the team and was asked to review the user authentication module
before we go live. Can you take a look at scripts/components/user-service.ts
and let me know if there's anything concerning? I'm particularly worried about
customer data safety.
```

**Expected Behavior**:
1. Claude loads code-review skill
2. Phase 1: `just typecheck` and `just lint` run and pass
3. Phase 2: LLM review identifies security issues
4. Findings include SQL injection, hardcoded secrets

**Verification**:
- [ ] Skill loaded (visible in response)
- [ ] Phase 1 passes (no blocking errors)
- [ ] SQL injection detected in `getUserByEmail` (CRITICAL)
- [ ] SQL injection detected in `authenticateUser` (CRITICAL)
- [ ] SQL injection detected in `updateUserProfile` (CRITICAL)
- [ ] Hardcoded API key detected (CRITICAL)
- [ ] Hardcoded JWT secret detected (CRITICAL)
- [ ] Path traversal risk in `downloadUserFile` (CRITICAL or IMPORTANT)
- [ ] Insecure token generation noted (IMPORTANT)
- [ ] Output in YAML format or structured findings

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

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
- [ ] Skill loaded
- [ ] Phase 1 passes
- [ ] Excessive `any` in cache property detected (CRITICAL or IMPORTANT)
- [ ] Excessive `any` in config property detected
- [ ] `any` in function parameters detected (processRecords, transformRecord)
- [ ] `any` return types detected
- [ ] Unsafe assertion `(e as any).message` detected
- [ ] `as unknown as` pattern noted as type-unsafe

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

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
- [ ] Skill loaded
- [ ] Phase 1 passes
- [ ] Single-letter function name `p` detected (IMPORTANT)
- [ ] Single-letter function name `x` detected
- [ ] Single-letter function name `z` detected
- [ ] Deep nesting (8+ levels) in `p` detected
- [ ] Generic variable names (`s`, `d`, `c`, `i`, `r`) detected
- [ ] High cyclomatic complexity noted
- [ ] Suggestions for refactoring provided

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

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
- [ ] Skill loaded
- [ ] Phase 1 passes
- [ ] Multiple responsibilities detected (config, connections, cache, logging, metrics)
- [ ] Global mutable state detected
- [ ] Implicit side effects in `getConfig` detected (auto-initialization)
- [ ] Mixed concerns in `processRequest` detected
- [ ] Single Responsibility Principle violation noted
- [ ] "No Magic" principle violation noted

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

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
- [ ] All 4 files analyzed (user-service, data-processor, workflow-handler, config-manager)
- [ ] Security findings from user-service
- [ ] Type Safety findings from data-processor
- [ ] Linting findings from workflow-handler
- [ ] Standards findings from config-manager
- [ ] Summary shows CRITICAL/IMPORTANT/SUGGESTION counts
- [ ] Diagnostic output written to `logs/diagnostics/`

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

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
- [ ] Only Security findings in output
- [ ] No Type Safety findings
- [ ] No Linting findings
- [ ] No Standards findings

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

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
- [ ] Security section runs
- [ ] Type Safety section runs
- [ ] Linting section skipped
- [ ] Standards section skipped
- [ ] Mode noted as "quick" in output

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

---

## Test P4.1-8: Menu Visibility

**Action**: Type `/` in Claude Code to open skill menu

**Expected Behavior**:
- `code-review` SHOULD appear in the menu
- Can be invoked as `/code-review [path]`

**Verification**:
- [ ] Skill appears in `/` menu
- [ ] `user-invocable: true` working correctly

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

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
- [ ] Pipeline triggered (not just `/code-review` direct invocation)
- [ ] Sub-agents spawned for each section (visible in output or logs)
- [ ] payment-gateway.ts findings:
  - [ ] Security: Hardcoded STRIPE_SECRET_KEY, SQL injection
  - [ ] Type Safety: `any` usage in paymentCache, metadata param
  - [ ] Standards: Global mutable state, implicit initialization
- [ ] analytics-tracker.ts findings:
  - [ ] Security: Hardcoded ANALYTICS_API_KEY
  - [ ] Type Safety: `any` in eventQueue, sessionData
  - [ ] Linting: Single-letter function `t`, deep nesting
- [ ] Consolidated summary with severity counts
- [ ] Output in pipeline YAML format (not direct format)

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

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
- [ ] Security findings prominent (SQL injection, hardcoded keys)
- [ ] Type Safety/Linting findings either absent or de-prioritized
- [ ] Response acknowledges security focus
- [ ] Actionable fix recommendations for security issues

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

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
- [ ] Review completed with findings
- [ ] Critical issues identified (hardcoded API key is security-critical)
- [ ] Either:
  - [ ] Fixes applied automatically (FixWriter triggered), OR
  - [ ] Fix recommendations provided with clear guidance
- [ ] Changes verified if fixes applied

**Result**: [ ] PASS / [ ] FAIL
**Notes**: _____

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

# P4.2 Bug-Magnet-Data Tests

*To be added after P4.2 implementation*

---

# P4.3 Bulwark-Code-Auditor Tests

*To be added after P4.3 implementation*

---

# P4.4 Bulwark-Implementer Tests

*To be added after P4.4 implementation*

---

## Post-Test Checklist (P4.1)

- [ ] code-review appears in `/` menu
- [ ] Phase 1 (static tools) runs before Phase 2 (LLM)
- [ ] Phase 1 failures block Phase 2 (fail fast)
- [ ] Security section detects SQL injection
- [ ] Security section detects hardcoded secrets
- [ ] Type Safety section detects `any` abuse
- [ ] Type Safety section detects unsafe assertions
- [ ] Linting section detects poor naming
- [ ] Linting section detects deep nesting
- [ ] Standards section detects multiple responsibilities
- [ ] Standards section detects implicit side effects
- [ ] `--section` flag limits to single section
- [ ] `--quick` flag applies tiered review
- [ ] Diagnostic output written to `logs/diagnostics/`
- [ ] All YAML outputs valid and parseable

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
