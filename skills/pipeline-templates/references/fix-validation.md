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
// Output: Verified fix with passing tests

IssueAnalyzer (root cause analysis)           // Sonnet - analytical
|> FixWriter (implement fix)                  // Opus - write code
|> TestWriter (add/update tests)              // Opus - write tests
|> CodeReviewer (review fix)                  // Sonnet - review
|> (if !approved
    then IssueAnalyzer                        // Loop back
    else Done)
|> LOOP(max=3)                                // Max 3 iterations
```

## Stage Details

### Stage 1: IssueAnalyzer

**Model**: Sonnet (analytical task)

**GOAL**: Understand root cause, not just symptoms.

**CONSTRAINTS**:
- Do NOT modify any files
- Trace full execution path
- Identify all affected areas
- Document hypothesis before conclusion

**CONTEXT**:
- Issue description / bug report
- Error logs / stack traces
- Reproduction steps (if available)

**OUTPUT**: Root cause analysis
```yaml
analysis:
  issue_id: BUG-123
  symptom: "Login fails with 500 error"
  root_cause: "Null pointer when user has no profile"
  affected_files:
    - src/auth/login.ts
    - src/models/user.ts
  complexity: medium  # low | medium | high
  fix_approach: "Add null check before profile access"
```

### Stage 2: FixWriter

**Model**: Opus (code writing required)

**GOAL**: Implement fix that addresses root cause.

**CONSTRAINTS**:
- Only fix the identified issue
- Follow existing code patterns
- Do NOT refactor unrelated code
- Maintain backward compatibility

**CONTEXT**:
- Root cause analysis from Stage 1
- Affected files identified
- Project coding standards

**OUTPUT**: Code changes with explanation
```yaml
fix:
  files_modified:
    - path: src/auth/login.ts
      changes: "Added null check at line 42"
  verification_needed:
    - "Run unit tests for auth module"
    - "Manual test: login with user without profile"
```

### Stage 3: TestWriter

**Model**: Opus (test writing required)

**GOAL**: Add tests that verify the fix and prevent regression.

**CONSTRAINTS**:
- Tests must verify real behavior (T1 rule)
- No mocking the system under test (T2 rule)
- Cover the specific bug scenario
- Cover edge cases identified in analysis

**CONTEXT**:
- Fix applied in Stage 2
- Root cause from Stage 1
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

### Stage 4: CodeReviewer

**Model**: Sonnet (review task)

**GOAL**: Verify fix is correct, complete, and safe.

**CONSTRAINTS**:
- Do NOT modify any files
- Check fix addresses root cause
- Verify tests cover the scenario
- Check for introduced regressions

**CONTEXT**:
- Original issue
- Root cause analysis
- Applied fix
- New tests

**OUTPUT**: Review decision
```yaml
review:
  approved: true | false
  concerns:
    - "Test doesn't cover null profile case"
  recommendations:
    - "Add assertion for profile existence"
```

### Loop Condition

If `approved: false`, loop back to IssueAnalyzer with:
- Original issue context
- Previous fix attempt
- Review feedback

**Max iterations**: 3 (prevent infinite loops)

## Example Invocation

```markdown
## Pipeline: Fix Validation

### Stage 1: IssueAnalyzer
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt with issue details]

### Stage 2: FixWriter
Task: subagent_type=general-purpose, model=opus
Prompt: [4-part prompt, reads Stage 1 analysis]

### Stage 3: TestWriter
Task: subagent_type=general-purpose, model=opus
Prompt: [4-part prompt, reads Stage 2 fix]

### Stage 4: CodeReviewer
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, reviews all stages]

### Loop Check
If not approved and iterations < 3:
  Go to Stage 1 with feedback
```

## Success Criteria

- Root cause identified and documented
- Fix addresses root cause (not just symptom)
- Tests verify the fix with real behavior
- Review approves the fix
- No new issues introduced

## Related Pipelines

- **Code Review**: For reviewing without fixing
- **Test Execution & Fix**: For running tests after fix
