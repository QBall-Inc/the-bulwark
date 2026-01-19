# Test Audit Expected Results

Expected outcomes for test-audit fixture validation.

**IMPORTANT**: This directory is intentionally separate from the test fixtures to prevent confirmation bias during sub-agent analysis.

## Purpose

These files contain expected findings that are used to validate test-audit pipeline output AFTER the audit completes. They should NEVER be passed to sub-agents during analysis.

## Files

| File | Corresponding Fixture |
|------|----------------------|
| `clean.yaml` | `test-audit/clean/calculator.test.ts` |
| `t1-violation.yaml` | `test-audit/t1-violation/proxy.test.ts` |
| `t2-violation.yaml` | `test-audit/t2-violation/db.test.ts` |
| `t3-violation.yaml` | `test-audit/t3-violation/api.integration.ts` |
| `t3plus-violation.yaml` | `test-audit/t3plus-violation/workflow.integration.ts` |
| `mixed-types.yaml` | `test-audit/mixed-types/everything.test.ts` |

## Usage

After running `/test-audit` on a fixture, compare the actual output against these expected results:

```bash
# Compare actual vs expected for t1-violation
diff <(cat logs/mock-detection-*.yaml) tests/fixtures/test-audit-expected/t1-violation.yaml
```

## Note on Approximate Values

Expected results contain approximate values for:
- Line numbers (may shift with formatting)
- Affected lines count
- Test effectiveness percentage

Human validation should focus on:
- Correct violation type detected
- Correct priority assigned
- Reasonable scope estimation
- Correct REWRITE_REQUIRED directive
