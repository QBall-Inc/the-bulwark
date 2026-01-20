# Fix Validator Expected Results

Expected pipeline outcomes for fix-validator fixtures. Used by tester to validate full Fix Validation pipeline - NOT passed to agents.

## Usage

These files define what a correct full pipeline run should produce. Testers compare pipeline output against these expectations.

## Fixtures

| Fixture | Bug Type | Tests Present | TestWriter Needed | Expected Confidence |
|---------|----------|---------------|-------------------|---------------------|
| `simple-fix` | Null pointer | Yes (incomplete) | Yes | HIGH |
| `complex-fix` | Race condition | Yes (flaky) | No | HIGH or MEDIUM |
| `no-tests` | Division by zero | No | Yes | HIGH or MEDIUM |

## Pipeline Stages Exercised

### simple-fix
1. **IssueAnalyzer**: Identifies null pointer in `generateWelcome`
2. **FixWriter**: Adds optional chaining + email fallback
3. **TestWriter**: Adds test for login without profile
4. **FixValidator**: Validates all tests pass, confidence HIGH

### complex-fix
1. **IssueAnalyzer**: Identifies missing await in `fetchBatch`
2. **FixWriter**: Adds await before Promise.all
3. **TestWriter**: Skipped (existing tests cover scenario when fix applied)
4. **FixValidator**: Validates tests pass consistently, confidence HIGH/MEDIUM

### no-tests
1. **IssueAnalyzer**: Identifies division by zero in `divide`
2. **FixWriter**: Adds zero check with error return
3. **TestWriter**: Creates test file with division tests
4. **FixValidator**: Validates new tests pass, confidence HIGH/MEDIUM

## Validation Criteria

The tester should verify:

1. **IssueAnalyzer Output**: Debug report exists with correct root cause
2. **Fix Applied**: Code change addresses root cause
3. **Tests**: New test added if TestWriter invoked
4. **FixValidator Output**: Validation report exists with appropriate confidence
5. **No Bias**: Agent found issues without hints in code/comments
