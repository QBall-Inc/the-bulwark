# mock-detection

Deep mock appropriateness analysis for the test-audit pipeline. Detects T1-T4 violations using call graph tracing and violation scope tracking.

## Invocation & usage

```
/the-bulwark:mock-detection
```

This skill is primarily used as an internal pipeline stage. Direct invocation loads it as a prompt template for a Sonnet sub-agent to analyze a specific set of flagged test files.

**Example invocations:**

```
# Loaded automatically during test-audit (most common usage)
/the-bulwark:test-audit

# Direct invocation to analyze flagged files from a prior classification run
/the-bulwark:mock-detection

# Direct invocation with explicit context
/the-bulwark:mock-detection logs/test-classification-20240315-143022.yaml
```

### Auto-invocation

mock-detection is always Stage 2 of the test-audit pipeline, in both Focus and Scale modes. When auto-triggered, it receives the classification YAML path from Stage 1 (test-classification) and analyzes only files marked `needs_deep_analysis: true`. It does not re-classify files. The upstream classification determines which files it sees and provides `verification_lines` counts and `mock_indicators` as starting points for analysis.

## Who is it for

- Teams running test-audit who want to understand why a file was flagged before deciding whether to fix it.
- Developers debugging a specific test file suspected of T3 or T3+ violations.
- Orchestrators building custom test audit pipelines who need a standalone mock analysis stage.

## How it works

The skill constructs a 4-part prompt (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) for a Sonnet sub-agent. The sub-agent reads the classification output, then for each flagged file performs a four-step call graph analysis: identify what the test claims to verify, trace data flow from setup through action to assertion, locate where mocks intercept that flow, and evaluate whether the interception defeats the test's stated purpose.

Violations are classified into four types. T1 (mocking the system under test) and T3+ (broken integration chain) are P0: they produce false confidence because the test always passes regardless of real behavior. T2 (verifying calls without verifying results) and T3 (mocking an integration boundary) are P1: they run real code but don't fully verify outcomes.

For each violation, the sub-agent tracks the full scope, not just the violation line. A `jest.spyOn` on line 15 that affects assertions through line 95 gets a scope of `[15, 95]` and 80 affected lines. This scope feeds the test effectiveness calculation in Stage 3 synthesis.

Mixed-type files (unit tests and integration tests in the same file) are evaluated per describe block. A mock that is safe in a unit section is a T3 violation in an integration section of the same file. When AST metadata is available from prior pipeline stages, it is used as ground truth for section boundaries.

Output is written to `logs/mock-detection-{YYYYMMDD-HHMMSS}.yaml`. A separate diagnostics file at `logs/diagnostics/mock-detection-{YYYYMMDD-HHMMSS}.yaml` records the call graph reasoning for each decision.
