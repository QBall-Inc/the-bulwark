# Issue Analyzer Expected Results

This directory contains expected debug report elements for validating the `bulwark-issue-analyzer` agent output.

## Important

**These files are NEVER passed to the agent.** They exist only for human testers to validate that the agent correctly identified the issues.

## Files

| File | Fixture | Issue Type |
|------|---------|------------|
| `production-bug.yaml` | `issue-analyzer/production-bug/` | Production code bug (null pointer) |
| `test-bug.yaml` | `issue-analyzer/test-bug/` | Test code bug (race condition) |

## Validation Process

1. Run the agent against the fixture directory
2. Compare agent's debug report against expected values
3. Check that root cause is correctly identified
4. Verify agent did NOT modify any files
5. Document results in `tests/logs/issue-analyzer-test-results-YYYYMMDD.yaml`

## No-Bias Pattern

The fixture code in `issue-analyzer/` contains NO comments explaining what's wrong. This ensures:
- Agent detects issues through actual code analysis
- No confirmation bias from reading hints
- Realistic simulation of production debugging
