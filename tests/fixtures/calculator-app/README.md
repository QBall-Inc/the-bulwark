# Calculator App - Test Fixture

**Purpose**: Test fixture for validating Bulwark skills. Contains INTENTIONAL issues.

## DO NOT FIX THESE ISSUES

This codebase is designed to have problems for testing:

### Bugs
- `divide()`: No division by zero handling
- `multiply()`: Integer overflow not handled
- `incrementAsync()`: Race condition
- `Calculator.getHistory()`: Memory leak (no clear method)

### Security Issues
- `calculate()`: Uses `eval()` - code injection vulnerability
- `evaluateFormula()`: No input sanitization

### Type Issues
- `calculate()`: Uses `any` type
- `parseNumber()`: Unsafe type assertion

### Test Issues (in calculator.test.ts)
- **Real tests**: `add`, `subtract` tests verify actual behavior
- **Mock-heavy tests**: `Calculator class`, `divide`, `multiply` tests mock the system under test
- **Missing tests**: No coverage for security-critical functions

## Usage

```bash
# Install dependencies (optional - for running tests)
npm install

# Run tests
npm test

# Type check
npm run typecheck
```

## For Bulwark Validation

| Skill | What to Test |
|-------|--------------|
| P0.2 subagent-output-templating | Agent output format |
| P0.4 issue-debugging | Fix bugs, verify validation loop |
| P0.6 test-classification | Classify real vs mock-heavy tests |
| P0.7 mock-detection | Detect mock-heavy patterns |
| P0.8 test-audit | Full audit of test suite |
| P4.1 security-heuristics | Find eval() and injection issues |
| P4.2 type-safety | Find any usage and unsafe assertions |
