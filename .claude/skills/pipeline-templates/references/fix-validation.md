# Fix Validation Pipeline

## Purpose

Fix bugs or issues and validate the fix through review and testing.

## When to Use

- Bug fixes
- Issue resolution
- Defect remediation
- Post-review fixes

## Pipeline Definition

```fsharp
// Fix Validation Pipeline
// Trigger: Bug report, issue, or review finding
// Output: Verified fix with passing tests and confidence assessment

IssueAnalyzer (root cause + debug report)     // Sonnet - bulwark-issue-analyzer
|> FixWriter (implement fix)                  // Opus - bulwark-implementer
|> (if !tests_cover_scenario                  // Conditional: only if tests don't already exist
    then TestWriter |> TestAudit              // Opus writes, then audit for T1-T4
    else Skip)
|> FixValidator (validate against debug report) // Sonnet - bulwark-fix-validator
|> CodeReviewer (review fix)                  // Sonnet - review
|> (if !approved
    then IssueAnalyzer                        // Loop back
    else Done)
|> LOOP(max=3)                                // Max 3 iterations
```

**TestWriter Condition**: The orchestrator evaluates whether existing tests cover the bug scenario using the debug report's `validation_plan.tests_to_execute` and `recommendation.new_tests_needed` fields.

### Key Artifacts

| Artifact | Producer | Consumer | Location |
|----------|----------|----------|----------|
| Debug Report | IssueAnalyzer | FixWriter, FixValidator | `logs/debug-reports/{issue-id}.yaml` |
| Validation Results | FixValidator | CodeReviewer | Standard log output |

## Stage Details

### Stage 1: IssueAnalyzer

**Agent**: `bulwark-issue-analyzer` (custom sub-agent)

**Model**: Sonnet (analytical task)

**Skills**: `issue-debugging`

**GOAL**: Understand root cause, map dependencies, produce debug report with validation plan.

**CONSTRAINTS**:
- Do NOT modify any files
- Trace full execution path
- Identify all affected areas (upstream/downstream)
- Document hypothesis before conclusion
- Include tiered validation plan in debug report

**CONTEXT**:
- Issue description / bug report
- Error logs / stack traces
- Reproduction steps (if available)

**OUTPUT**: Debug report at `logs/debug-reports/{issue-id}-{YYYYMMDD-HHMMSS}.yaml`
```yaml
debug_report:
  metadata:
    issue_id: BUG-123
    timestamp: "2026-01-16T10:30:00Z"
    analyzer: bulwark-issue-analyzer

  analysis:
    symptom: "Login fails with 500 error"
    root_cause: "Null pointer when user has no profile"
    complexity: medium  # low | medium | high
    fix_approach: "Add null check before profile access"

  impact_analysis:
    affected_files:
      - src/auth/login.ts
      - src/models/user.ts
    upstream_dependencies:
      - "src/api/auth-routes.ts calls login()"
    downstream_effects:
      - "User dashboard fetches profile on load"
    risk_scope: medium  # isolated | medium | broad

  validation_plan:
    tests_to_execute:
      - path: tests/auth/login.test.ts
        reason: "Direct test of affected function"
        priority: 1  # P1=must, P2=should, P3=nice-to-have
      - path: tests/api/auth-routes.test.ts
        reason: "Integration test for upstream"
        priority: 2
    functionalities_to_validate:
      - "User without profile can login"
      - "Dashboard loads correctly for new users"

  confidence_criteria:
    high:
      - "All P1-P2 tests pass"
      - "No regression in existing tests"
    medium:
      - "P1 tests pass, some P2-P3 skipped"
    low:
      - "Tests cannot reliably validate"
      - "Manual testing required"

  debug_journey:  # Required for medium/high complexity
    hypotheses_tested:
      - hypothesis: "Database connection timeout"
        result: rejected
        evidence: "DB logs show successful queries"
      - hypothesis: "Null profile object"
        result: confirmed
        evidence: "Stack trace points to profile.name access"
```

**Summary**: Include debug report path in summary for orchestrator reference.

### Stage 2: FixWriter

**Agent**: `bulwark-implementer` (custom sub-agent)

**Model**: Opus (code writing with quality enforcement)

**GOAL**: Implement fix that addresses root cause.

**CONSTRAINTS**:
- Only fix the identified issue
- Follow existing code patterns
- Do NOT refactor unrelated code
- Maintain backward compatibility
- Max 3 quality gate retries before escalation

**CONTEXT** (must include for `context: fork`):
- Debug report path: `logs/debug-reports/{issue-id}-{timestamp}.yaml`
- Root cause from Stage 1 analysis
- Affected files from impact analysis
- Fix approach recommendation
- Project coding standards and patterns

**Invocation**:
```
Task: subagent_type=bulwark-implementer
Prompt:
  GOAL: Fix the identified issue based on the debug report.
  CONSTRAINTS: Only fix the identified issue. Write tests for the fix. Max 3 quality gate retries.
  CONTEXT:
    mode: fix
    debug_report_path: logs/debug-reports/{issue-id}-{timestamp}.yaml
    root_cause: {from Stage 1}
    affected_files: {from Stage 1}
    fix_approach: {from Stage 1}
  OUTPUT: Implementation report at logs/implementer-{id}-{timestamp}.yaml
```

**OUTPUT**: Implementation report at `logs/implementer-{id}-{timestamp}.yaml`
```yaml
implementation_report:
  changes:
    files_modified:
      - path: src/auth/login.ts
        changes: "Added null check at line 42"
  tests:
    files_created:
      - path: tests/auth/login-null-profile.test.ts
  quality_gates:
    typecheck: passed
    lint: passed
    retries: 0
  pipeline_suggestions:
    - pipeline: "Code Review"
      target_files: [src/auth/login.ts]
      reason: "Bug fix to authentication module"
```

**SA6 Note**: The implementer returns pipeline suggestions with MANDATORY language in its summary. The orchestrator MUST evaluate each suggestion per SA6.

### Stage 3: TestWriter

**Actor**: Orchestrator (Opus)

**Model**: Opus (test writing required)

**GOAL**: Add tests that verify the fix and prevent regression.

**CONSTRAINTS**:
- Tests must verify real behavior (T1 rule)
- No mocking the system under test (T2 rule)
- Cover the specific bug scenario
- Cover edge cases identified in analysis
- Reference debug report's validation plan for test targets

**CONTEXT**:
- Fix applied in Stage 2
- Debug report from Stage 1
- Existing test patterns

**OUTPUT**: New/updated tests
```yaml
tests:
  new_tests:
    - file: tests/auth/login.test.ts
      name: "handles user without profile gracefully"
      type: integration
  updated_tests: []
```

### Stage 3b: TestAudit (Conditional)

**Trigger**: Runs if **any** test files were created or modified in Stage 2 (FixWriter) OR Stage 3 (TestWriter). This ensures implementer-written tests receive T1-T4 audit even when TestWriter is skipped.

**Model**: Haiku (classification) → Sonnet (detection)

**Skills**: `mock-detection` (lighter weight than full test-audit)

**GOAL**: Verify new/modified tests don't have T1-T4 violations before proceeding to validation.

**CONSTRAINTS**:
- Audit test files touched by FixWriter (Stage 2) and/or TestWriter (Stage 3)
- Block pipeline if T1 violation found (mocking system under test)
- Warn on T2-T4 violations but allow proceed
- Do NOT audit existing tests (only new/modified in this pipeline run)

**CONTEXT**:
- List of test files created/modified by FixWriter and/or TestWriter
- Debug report for understanding what's being tested

**OUTPUT**: Audit result
```yaml
test_audit:
  files_audited:
    - path: tests/auth/login.test.ts
      status: passed | failed
      violations: []

  t1_violations: 0  # Critical - blocks pipeline
  t2_violations: 0  # High - warning only
  t3_violations: 0  # Medium - warning only
  t4_violations: 0  # Low - warning only

  proceed: true | false
  notes: "All generated tests follow T1-T4 rules"
```

**Failure Handling**:
- If T1 violation: Return to TestWriter with feedback, request rewrite
- If T2-T4 violations: Log warning, proceed to FixValidator
- Max 2 audit iterations before escalating to user

### Stage 4: FixValidator

**Agent**: `bulwark-fix-validator` (custom sub-agent)

**Model**: Sonnet (validation task)

**Skills**: `issue-debugging`

**GOAL**: Execute validation plan from debug report, assess fix confidence.

**CONSTRAINTS**:
- Run only tests specified in validation plan (tiered: P1 → P2 → P3)
- Do NOT run full regression suite
- Assess confidence per rubric from debug report
- Escalate to manual testing when required

**CONTEXT**:
- Debug report from IssueAnalyzer (path in Stage 1 summary)
- Fix applied by FixWriter
- Tests written by TestWriter

**OUTPUT**: Validation results with confidence assessment
```yaml
validation_results:
  debug_report_ref: "logs/debug-reports/BUG-123-20260116.yaml"

  tests_executed:
    p1_tests:
      - path: tests/auth/login.test.ts
        status: passed
      - path: tests/auth/profile.test.ts
        status: passed
    p2_tests:
      - path: tests/api/auth-routes.test.ts
        status: passed
    p3_tests:
      - path: tests/e2e/login-flow.test.ts
        status: skipped
        reason: "E2E environment not available"

  functionalities_validated:
    - functionality: "User without profile can login"
      status: validated
      method: "P1 test coverage"
    - functionality: "Dashboard loads correctly for new users"
      status: not_validated
      reason: "Requires manual testing"

  confidence_assessment:
    level: medium
    rationale:
      - "All P1 tests pass"
      - "P2 tests pass"
      - "One functionality requires manual validation"

  escalation:
    manual_testing_required: true
    items:
      - "Dashboard load for new users - UI verification needed"
    message: "Orchestrator should inform user: Manual testing required for dashboard functionality"
```

**Escalation Triggers** (any triggers manual testing):
- Confidence level is `low`
- Risk scope is `broad` AND confidence is not `high`
- Any functionality cannot be validated via automated tests

### Stage 5: CodeReviewer

**Model**: Sonnet (review task)

**GOAL**: Verify fix is correct, complete, and safe. Consider validation results.

**CONSTRAINTS**:
- Do NOT modify any files
- Check fix addresses root cause (from debug report)
- Verify tests cover the scenario
- Check for introduced regressions
- Consider FixValidator confidence assessment

**CONTEXT**:
- Debug report from IssueAnalyzer
- Applied fix from FixWriter
- New tests from TestWriter
- Validation results from FixValidator

**OUTPUT**: Review decision
```yaml
review:
  approved: true | false
  validation_confidence: high | medium | low
  concerns:
    - "Test doesn't cover null profile case"
  recommendations:
    - "Add assertion for profile existence"
  manual_testing_note: "User notified of manual testing requirement"
```

**Approval Criteria**:
- Fix addresses root cause identified in debug report
- Tests verify the specific bug scenario
- No new issues introduced
- Validation confidence is acceptable (high or medium with justification)
- If manual testing required, user has been notified

### Loop Condition

If `approved: false`, loop back to IssueAnalyzer with:
- Original issue context
- Previous fix attempt
- Review feedback
- Previous validation results

**Max iterations**: 3 (prevent infinite loops)

## Example Invocation

```markdown
## Pipeline: Fix Validation

### Stage 1: IssueAnalyzer
Task: subagent_type=bulwark-issue-analyzer, model=sonnet
Prompt: [4-part prompt with issue details]
Output: Debug report at logs/debug-reports/{issue-id}.yaml

### Stage 2: FixWriter
Task: subagent_type=bulwark-implementer
Prompt: [4-part prompt with debug report path, root cause, affected files, fix approach]
Output: Implementation report at logs/implementer-{id}-{timestamp}.yaml

### Stage 3: TestWriter (Orchestrator)
Actor: Orchestrator (Opus) - NOT a sub-agent
Action: Read debug report validation plan, write tests
Output: New/updated tests

### Stage 4: FixValidator
Task: subagent_type=bulwark-fix-validator, model=sonnet
Prompt: [4-part prompt, reads debug report, executes validation plan]
Output: Validation results with confidence assessment

### Stage 5: CodeReviewer
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, reviews all stages including validation results]
Output: Approval decision

### Loop Check
If not approved and iterations < 3:
  Go to Stage 1 with feedback + previous validation results
```

## Success Criteria

- Root cause identified and documented in debug report
- Impact analysis covers upstream/downstream dependencies
- Fix addresses root cause (not just symptom)
- Tests verify the fix with real behavior (T1-T4 rules)
- Validation plan executed (tiered: P1 → P2 → P3)
- Confidence assessment completed
- Manual testing escalated if required
- Review approves the fix
- No new issues introduced

## Related Pipelines

- **Code Review**: For reviewing without fixing
- **Test Execution & Fix**: For running tests after fix
