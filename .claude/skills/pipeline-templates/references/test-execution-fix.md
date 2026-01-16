# Test Execution & Fix Pipeline

## Purpose

Run tests, analyze failures, and fix issues iteratively.

## When to Use

- After code changes
- CI failure remediation
- Test suite maintenance
- Pre-merge verification

## Pipeline Definition

```fsharp
// Test Execution & Fix Pipeline
// Trigger: Code changes, CI failures
// Output: Passing tests with fixes applied

TestRunner (execute test suite)                  // Haiku - execution
|> (if failures > 0
    then FailureAnalyzer (analyze failures)      // Sonnet - analysis
    else Done)
|> FixWriter (apply fixes)                       // Opus - write code
|> TestRunner (re-execute)                       // Haiku - verify
|> (if failures > 0 && iterations < max
    then FailureAnalyzer                         // Loop back
    else Done)
|> LOOP(max=3)                                   // Max 3 fix attempts
```

## Stage Details

### Stage 1: TestRunner

**Model**: Haiku (execution task)

**GOAL**: Run tests and capture results.

**CONSTRAINTS**:
- Do NOT modify any files
- Capture full output
- Parse failure details

**CONTEXT**:
- Test command (e.g., `just test`)
- Test scope (all, specific files, etc.)

**OUTPUT**: Test results
```yaml
results:
  command: "just test"
  duration: "45s"
  summary:
    total: 142
    passed: 138
    failed: 4
    skipped: 0
  failures:
    - test: "should start proxy on specified port"
      file: tests/proxy.test.ts
      line: 23
      error: "EADDRINUSE: address already in use"
      stack: |
        Error: listen EADDRINUSE: address already in use :::8096
            at Server.setupListenHandle [as _listen2]
    - test: "should parse config file"
      file: tests/config.test.ts
      line: 45
      error: "Expected 'production' but got 'development'"
      stack: |
        AssertionError: expected 'development' to equal 'production'
```

### Stage 2: FailureAnalyzer

**Model**: Sonnet (analysis task)

**Conditional**: Only run if failures > 0

**GOAL**: Analyze failures to understand root cause.

**CONSTRAINTS**:
- Do NOT modify any files
- Categorize failure types
- Identify common patterns
- Prioritize by fix complexity

**CONTEXT**:
- Test results from Stage 1
- Test file contents
- Related source files

**OUTPUT**: Failure analysis
```yaml
analysis:
  failure_count: 4
  categories:
    environment:
      count: 1
      tests: ["should start proxy on specified port"]
      cause: "Port 8096 in use by another process"
      fix_approach: "Use dynamic port assignment"
    assertion:
      count: 2
      tests: ["should parse config file", "should return correct env"]
      cause: "Test environment not properly set"
      fix_approach: "Set NODE_ENV before test"
    flaky:
      count: 1
      tests: ["should timeout on slow response"]
      cause: "Race condition in timeout handling"
      fix_approach: "Increase timeout or fix race"
  priority_order:
    - category: environment
      reason: "Blocking other tests"
    - category: assertion
      reason: "Quick fix"
    - category: flaky
      reason: "May need investigation"
```

### Stage 3: FixWriter

**Model**: Opus (code writing required)

**GOAL**: Apply fixes for test failures.

**CONSTRAINTS**:
- Fix test issues, not production bugs
- One category at a time
- Verify fix doesn't break other tests

**CONTEXT**:
- Failure analysis from Stage 2
- Test files
- Related source files

**OUTPUT**: Applied fixes
```yaml
fixes:
  applied:
    - file: tests/proxy.test.ts
      change: "Use getAvailablePort() instead of hardcoded 8096"
      tests_affected: ["should start proxy on specified port"]
    - file: tests/config.test.ts
      change: "Added beforeEach to set NODE_ENV"
      tests_affected: ["should parse config file", "should return correct env"]
  deferred:
    - file: tests/timeout.test.ts
      reason: "Flaky test needs deeper investigation"
      recommendation: "Skip for now, create issue"
```

### Stage 4: TestRunner (Re-execution)

**Model**: Haiku (execution task)

**GOAL**: Verify fixes resolved failures.

Same as Stage 1, but with expectation of fewer failures.

### Loop Condition

If failures remain and iterations < 3:
- Loop back to FailureAnalyzer
- Focus on remaining failures
- Avoid re-fixing already fixed issues

**Max iterations**: 3 (prevent infinite loop on unfixable issues)

## Example Invocation

```markdown
## Pipeline: Test Execution & Fix

### Stage 1: TestRunner
Task: subagent_type=Bash, model=haiku
Prompt: Run 'just test' and capture output

### Stage 2: FailureAnalyzer
Condition: failures > 0
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, analyzes failures]

### Stage 3: FixWriter
Task: subagent_type=general-purpose, model=opus
Prompt: [4-part prompt, applies fixes]

### Stage 4: TestRunner (Iteration 1)
Task: subagent_type=Bash, model=haiku
Prompt: Re-run 'just test' to verify fixes

### Loop Check
If failures > 0 and iterations < 3:
  Go to Stage 2 with remaining failures
```

## Success Criteria

- All tests pass
- OR: Remaining failures documented with justification
- Fixes don't introduce new failures
- Max 3 fix iterations

## Failure Categories

| Category | Description | Typical Fix |
|----------|-------------|-------------|
| Environment | Port conflicts, missing deps | Dynamic allocation, setup scripts |
| Assertion | Wrong expected value | Update test or fix bug |
| Timeout | Test too slow or hangs | Increase timeout, optimize |
| Flaky | Intermittent failures | Fix race condition, add retry |
| Setup | beforeEach/afterEach issues | Fix setup/teardown |
| Mock | Mock not matching real | Update mock or use real |

## Iteration Tracking

```yaml
iterations:
  - round: 1
    failures_before: 4
    failures_after: 1
    fixed: ["proxy port", "config env"]
  - round: 2
    failures_before: 1
    failures_after: 0
    fixed: ["timeout handling"]
  - round: 3
    not_needed: true
```

## Related Pipelines

- **Fix Validation**: For fixing source code bugs
- **Test Audit**: For auditing test quality
- **Code Review**: For reviewing fixes
