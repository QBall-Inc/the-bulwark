# Test Audit Pipeline

## Purpose

Audit test suite quality, identify mock-heavy tests, and prioritize rewrites.

## When to Use

- Test suite quality assessment
- Identifying tests that mock the system under test
- Prioritizing test improvements
- Ensuring T1-T4 compliance

## Pipeline Definition

```fsharp
// Test Audit Pipeline
// Trigger: Test quality concerns, new codebase assessment
// Output: YAML inventory with rewrite priorities

TestClassifier (categorize all tests)           // Haiku - pattern matching
|> MockDetector (find problematic mocks)        // Haiku - pattern matching
|> AuditSynthesizer (compile findings)          // Sonnet - analysis
|> (if high_priority_rewrites > 0
    then TestRewriter (rewrite worst offenders) // Opus - write tests
    else Done)
```

## Stage Details

### Stage 1: TestClassifier

**Model**: Haiku (pattern matching task)

**GOAL**: Categorize all tests by type and quality.

**CONSTRAINTS**:
- Do NOT modify any files
- Classify every test file
- Use consistent categories

**CONTEXT**:
- Test directory paths
- Project test framework (Jest, Vitest, etc.)

**OUTPUT**: Test classification
```yaml
classification:
  total_files: 25
  total_tests: 142
  categories:
    unit:
      count: 80
      files: [...]
    integration:
      count: 45
      files: [...]
    e2e:
      count: 17
      files: [...]
  indicators:
    real_integration:
      - "Actually spawns processes"
      - "Writes to real filesystem"
      - "Makes real HTTP calls (in integration)"
    mock_heavy:
      - "Mocks child_process.spawn"
      - "Mocks fs module entirely"
      - "jest.spyOn without real call"
```

### Stage 2: MockDetector

**Model**: Haiku (pattern matching task)

**GOAL**: Identify tests that mock the system under test (T1 violation).

**CONSTRAINTS**:
- Do NOT modify any files
- Focus on high-risk mock patterns
- Document specific line numbers

**CONTEXT**:
- Test classification from Stage 1
- T1-T4 rules from Rules.md

**OUTPUT**: Mock detection findings
```yaml
violations:
  t1_violations:  # Mocking system under test
    - file: tests/proxy.test.ts
      line: 15
      pattern: "jest.spyOn(child_process, 'spawn')"
      severity: high
      reason: "Test claims to verify proxy starts but mocks spawn"
  t2_violations:  # Not verifying observable output
    - file: tests/config.test.ts
      line: 42
      pattern: "expect(db.save).toHaveBeenCalled()"
      severity: medium
      reason: "Verifies call, not result"
  t3_violations:  # Mock at integration boundary
    - file: tests/api.integration.ts
      line: 8
      pattern: "jest.mock('node-fetch')"
      severity: high
      reason: "Integration test should use real HTTP"
```

### Stage 3: AuditSynthesizer

**Model**: Sonnet (analysis and synthesis)

**GOAL**: Compile findings into prioritized rewrite list.

**CONSTRAINTS**:
- Do NOT modify any files
- Prioritize by impact and effort
- Provide actionable rewrite guidance

**CONTEXT**:
- Classification from Stage 1
- Violations from Stage 2
- Project testing patterns

**OUTPUT**: Audit report with priorities
```yaml
audit:
  summary:
    total_tests: 142
    compliant: 98
    violations: 44
    critical: 12
  priority_rewrites:
    - file: tests/proxy.test.ts
      priority: P0  # Critical
      reason: "Core functionality mocked"
      effort: medium
      approach: "Start real proxy, verify port"
    - file: tests/api.integration.ts
      priority: P1  # High
      reason: "Integration test uses mocks"
      effort: low
      approach: "Use test server instead of mock"
  recommendations:
    - "Establish test harness for proxy testing"
    - "Create shared fixtures for integration tests"
```

### Stage 4: TestRewriter (Conditional)

**Model**: Opus (test writing required)

**Conditional**: Only run if high-priority rewrites exist.

**GOAL**: Rewrite worst offending tests to use real behavior.

**CONSTRAINTS**:
- Follow T1-T4 rules strictly
- Verify real behavior, not mocks
- Maintain test coverage
- One file at a time

**CONTEXT**:
- Priority rewrites from Stage 3
- Project test patterns
- Available test infrastructure

**OUTPUT**: Rewritten tests
```yaml
rewrites:
  completed:
    - file: tests/proxy.test.ts
      changes: "Replaced mock with real proxy spawn"
      verification: "Run: npm test -- proxy.test.ts"
  remaining:
    - file: tests/api.integration.ts
      reason: "Needs test server setup first"
```

## Example Invocation

```markdown
## Pipeline: Test Audit

### Stage 1: TestClassifier
Task: subagent_type=general-purpose, model=haiku
Prompt: [4-part prompt with test directories]

### Stage 2: MockDetector
Task: subagent_type=general-purpose, model=haiku
Prompt: [4-part prompt, reads Stage 1 output]

### Stage 3: AuditSynthesizer
Task: subagent_type=general-purpose, model=sonnet
Prompt: [4-part prompt, synthesizes findings]

### Stage 4: TestRewriter (Conditional)
Condition: priority_rewrites with P0 severity
Task: subagent_type=general-purpose, model=opus
Prompt: [4-part prompt, rewrites tests]
```

## Success Criteria

- All tests classified
- T1-T4 violations identified
- Priority rewrite list generated
- Critical tests rewritten (if any)

## T1-T4 Rules Reference

| Rule | Description | Violation Example |
|------|-------------|-------------------|
| T1 | Never mock system under test | `jest.spyOn(spawn)` when testing spawn |
| T2 | Verify observable output | `expect(fn).toHaveBeenCalled()` |
| T3 | Integration uses real systems | `jest.mock('fs')` in integration |
| T4 | Run tests before complete | Not running after writing |

## Related Pipelines

- **Fix Validation**: For fixing issues found in tests
- **Test Execution & Fix**: For running and fixing tests
