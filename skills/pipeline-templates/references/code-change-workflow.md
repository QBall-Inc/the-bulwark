# Code Change Workflow (Composite Pipeline)

## Purpose

Full automation after code file creation or edit. Chains multiple pipelines to ensure:
- Code quality (review)
- Test coverage and quality (audit)
- Test execution (verification)
- Issue resolution (fix validation loop)

## When to Use

- After creating or editing code files (`.ts`, `.js`, `.py`, `.go`, `.rs`, `.java`)
- PostToolUse hook suggests this workflow for significant code changes
- Manual invocation when comprehensive quality assurance needed

## Entry Points

| Trigger | How |
|---------|-----|
| PostToolUse hook | Automatic suggestion after Write/Edit on code files above threshold |
| Manual | "Run code change workflow on [files]" |
| After feature implementation | Chain from New Feature pipeline |

---

## Composite Pipeline Definition

```fsharp
// CODE CHANGE WORKFLOW
// Trigger: Code file created or significantly edited
// Output: Reviewed, tested, validated code

// PHASE 1: Code Review (if code-review skill available)
CodeReviewPipeline (optional, requires P4.1)
|> (if critical_issues then FixWriter else Continue)

// PHASE 2: Test Audit (Main Context Orchestration)
// Orchestrator loads test-audit skill, follows instructions
TestClassifier (Haiku, surface classification)
|> MockDetector (Sonnet, T1-T4 violations)
|> AuditSynthesizer (Sonnet, REWRITE_REQUIRED directive)
|> (if REWRITE_REQUIRED then TestRewriter(Opus) else Continue)
|> LOOP(max=2)

// PHASE 3: Test Execution
TestRunner (Haiku, execute tests)
|> (if failures > 0
    then FailureAnalyzer (Sonnet)
         |> (if test_issue then TestFixWriter(Opus) else CodeBugDetected)
    else Continue)
|> LOOP(max=3)

// PHASE 4: Fix Validation (if code bugs detected)
(if CodeBugDetected
    then IssueAnalyzer (bulwark-issue-analyzer)
         |> FixWriter (Opus)
         |> TestWriter (Opus)
         |> FixValidator (bulwark-fix-validator)
         |> CodeReviewer (Sonnet)
         |> (if !approved then IssueAnalyzer else Done)
         |> LOOP(max=3)
    else Done)
```

---

## Phase Details

### Phase 1: Code Review (Optional)

**Dependency**: Requires `code-review` skill (P4.1) and optionally `bulwark-code-auditor` (P4.3)

**Skip Condition**: If code-review skill not available, proceed to Phase 2

**Stages**:
1. SecurityReviewer (Sonnet) - OWASP patterns
2. TypeSafetyReviewer (Sonnet) - any, null, unsafe assertions
3. LintReviewer (Sonnet) - complexity, formatting
4. StandardsReviewer (Sonnet) - naming, patterns
5. ReviewSynthesizer (Sonnet) - consolidate findings
6. FixWriter (Opus) - fix critical/high issues if any

**Output**: Review findings, fixes applied if critical

---

### Phase 2: Test Audit (Main Context Orchestration)

**Pattern**: Orchestrator loads `test-audit` skill and follows its instructions directly. No wrapper agent needed.

**Why Main Context Orchestration?**
- Test audit requires 3-stage pipeline (classification → detection → synthesis)
- Sub-agents cannot spawn other sub-agents
- Orchestrator must stay in main context to spawn each stage

**Stages**:
1. Load `test-audit` skill
2. Follow skill instructions to spawn:
   - TestClassifier (Haiku) → `logs/test-classification-{ts}.yaml`
   - MockDetector (Sonnet) → `logs/mock-detection-{ts}.yaml`
   - AuditSynthesizer (Sonnet) → `logs/test-audit-{ts}.yaml`
3. Read `REWRITE_REQUIRED` directive from audit output
4. If true: Orchestrator (Opus) rewrites flagged tests
5. Loop up to 2 times to verify rewrites resolved issues

**Output**: Test audit report, tests rewritten if needed

---

### Phase 3: Test Execution

**Purpose**: Run tests and fix test-related failures

**Stages**:
1. TestRunner (Haiku) - Execute `just test` or equivalent
2. If failures:
   - FailureAnalyzer (Sonnet) - Categorize failures
   - Determine: Is this a test issue or code bug?
   - If test issue: TestFixWriter (Opus) fixes test
   - If code bug: Flag for Phase 4
3. Re-run tests to verify
4. Loop up to 3 times

**Failure Categories**:
| Category | Resolution |
|----------|------------|
| Environment | Fix test setup (ports, deps) |
| Assertion | Update test or fix test logic |
| Timeout | Increase timeout or optimize |
| Flaky | Fix race condition |
| **Code Bug** | Escalate to Phase 4 |

**Output**: Passing tests OR code bugs identified for Phase 4

---

### Phase 4: Fix Validation (Conditional)

**Trigger**: Only runs if Phase 3 detected code bugs (not test issues)

**Agents Required**:
- `bulwark-issue-analyzer` (P1.2) - Root cause analysis
- `bulwark-fix-validator` (P1.3) - Validation against debug report

**Stages**:
1. IssueAnalyzer (bulwark-issue-analyzer, Sonnet)
   - Produces debug report at `logs/debug-reports/{issue-id}.yaml`
   - Includes validation plan (P1/P2/P3 tiered tests)
2. FixWriter (Opus) - Implement fix per root cause
3. TestWriter (Opus) - Add tests per validation plan
4. FixValidator (bulwark-fix-validator, Sonnet)
   - Execute validation plan
   - Assess confidence (high/medium/low)
   - Escalate to manual testing if needed
5. CodeReviewer (Sonnet) - Approve/reject fix
6. Loop if not approved (max 3 iterations)

**Output**: Verified fix with confidence assessment

---

## Orchestrator Execution Flow

```markdown
## Step 1: Determine Entry Point
- Hook-triggered: additionalContext suggests workflow
- Manual: User requests comprehensive review

## Step 2: Phase 1 - Code Review (if available)
IF code-review skill exists:
    Load code-review skill
    Execute Code Review Pipeline stages
    Apply fixes for critical/high issues
ELSE:
    Skip to Phase 2

## Step 3: Phase 2 - Test Audit
Load test-audit skill
Follow Main Context Orchestration instructions:
    - Spawn TestClassifier (Haiku)
    - Read classification, spawn MockDetector (Sonnet)
    - Read violations, spawn AuditSynthesizer (Sonnet)
    - Read REWRITE_REQUIRED directive
IF REWRITE_REQUIRED:
    Rewrite flagged tests (Opus)
    Loop (max 2)

## Step 4: Phase 3 - Test Execution
Spawn TestRunner (Haiku)
IF failures:
    Spawn FailureAnalyzer (Sonnet)
    IF test_issue:
        Fix test (Opus)
        Re-run (loop max 3)
    ELSE:
        Mark CodeBugDetected

## Step 5: Phase 4 - Fix Validation (if needed)
IF CodeBugDetected:
    Spawn IssueAnalyzer (bulwark-issue-analyzer)
    Read debug report
    Implement fix (Opus)
    Write tests (Opus)
    Spawn FixValidator (bulwark-fix-validator)
    Read validation results
    Spawn CodeReviewer (Sonnet)
    IF !approved: Loop (max 3)

## Step 6: Report Completion
Summarize all phases:
- Code review findings (if run)
- Test audit results
- Test execution status
- Fix validation outcome (if run)
```

---

## Dependency Status

| Phase | Dependencies | Status |
|-------|--------------|--------|
| Phase 1 | code-review skill (P4.1) | Not yet built |
| Phase 2 | test-audit skill (P0.8) | **Complete** |
| Phase 3 | Test Execution pipeline template | **Complete** |
| Phase 4 | bulwark-issue-analyzer (P1.2), bulwark-fix-validator (P1.3) | Not yet built |

**Current Capability**: Phases 2 and 3 can run today. Phases 1 and 4 require future work.

---

## Termination Conditions

| Condition | Action |
|-----------|--------|
| All phases complete, no issues | Workflow done |
| Phase 2 loop exceeds max=2 | Report remaining audit issues, continue |
| Phase 3 loop exceeds max=3 | Report unfixable test failures, escalate |
| Phase 4 loop exceeds max=3 | Report unresolved code bug, escalate to manual |
| Manual testing required | Notify user, workflow pauses |

---

## User Communication

At key points, the orchestrator should inform the user:

```markdown
## Code Change Workflow Progress

**Phase 1 (Code Review)**: [Skipped / Completed - N findings]
**Phase 2 (Test Audit)**: [Completed - REWRITE_REQUIRED: yes/no]
**Phase 3 (Test Execution)**: [Completed - N tests passed, M failed]
**Phase 4 (Fix Validation)**: [Not needed / Completed - confidence: high/medium/low]

Overall Status: [Success / Requires Attention]
```

---

## Related Pipelines

| Pipeline | Relationship |
|----------|--------------|
| Code Review | Phase 1 of this workflow |
| Test Audit | Phase 2 of this workflow (Main Context Orchestration) |
| Test Execution & Fix | Phase 3 of this workflow |
| Fix Validation | Phase 4 of this workflow |

---

## Future Enhancements

- **Parallel execution**: Run Code Review and Test Audit in parallel (Phase 1 || Phase 2)
- **Incremental mode**: Only audit/test files related to the change
- **CI integration**: Hook into CI/CD for automated workflow trigger
