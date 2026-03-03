# bulwark-fix-validator

Validates a fix against the debug report produced by `bulwark-issue-analyzer`, executes a tiered test plan, and returns a confidence assessment with a proceed-or-revise recommendation.

## Model

Sonnet.

## Invocation guidance

**Tier 3 — Pipeline-only.** Not recommended for standalone use. The agent reads its validation plan directly from the YAML debug report written by `bulwark-issue-analyzer`. Without that report, it has no test list, no confidence criteria, and no root cause to validate against.

Invoke through the parent skill instead:

```
/the-bulwark:fix-bug path/to/code "description of the bug"
```

The `fix-bug` skill handles sequencing: issue analysis first, implementation second, fix validation last. The agent can also be reached through `issue-debugging` when you want validation without a full fix cycle.

See: [fix-bug](../skills/fix-bug.md), [issue-debugging](../skills/issue-debugging.md).

## What it does

The agent reads the debug report YAML produced by `bulwark-issue-analyzer` and executes the validation plan it contains. Tests run in priority order (P1, then P2, then P3 for high-complexity issues). P1 failures stop the run immediately. P2 and P3 failures are noted and included in the confidence assessment. The agent tries each test execution strategy in sequence: native runner, direct file execution, generated validation script, and finally manual code tracing if nothing else works.

Beyond test results, the agent checks call sites of modified functions, validates each user-visible functionality from the debug report, and runs edge case analysis using `bug-magnet-data` for the data types the fix touches. The output is a structured confidence rating (HIGH, MEDIUM, or LOW) mapped against the criteria in the debug report, along with a recommendation to proceed to code review, revise the fix, or escalate for manual testing.

## Output

| File | Description |
|------|-------------|
| `logs/validations/fix-validation-{issue-id}-{YYYYMMDD-HHMMSS}.yaml` | Full validation report: test results by priority tier, functionality validation status, call site analysis, edge case assessment, confidence level, and recommendation. |
| `tmp/validation-results-{issue-id}.txt` | Human-readable summary of test results and fix analysis. Generated for medium and high complexity issues only. |
| `logs/diagnostics/bulwark-fix-validator-{YYYYMMDD-HHMMSS}.yaml` | Pipeline execution metadata: tests run per tier, test method used, output paths, final confidence level. |
