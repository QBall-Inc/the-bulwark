# test-classification

Prompt template for the classification stage in the test-audit pipeline. Classifies test files by type and flags candidates for deep mock analysis.

## Invocation & usage

```
/the-bulwark:test-classification
```

Direct invocation loads the prompt template for use with a Haiku sub-agent. The skill substitutes `{target}` with the path you provide and spawns a Haiku agent to classify the files in that directory.

**Example invocations:**

```
# Loaded automatically during test-audit Scale mode (most common usage)
/the-bulwark:test-audit tests/ --threshold=5

# Direct invocation to classify a specific directory
/the-bulwark:test-classification tests/

# Direct invocation with an explicit path for standalone triage
/the-bulwark:test-classification src/__tests__/
```

### Auto-invocation

test-classification is Stage 1 of the test-audit pipeline in Scale mode only. When the file count in the target directory exceeds the threshold (default: 5), test-audit loads this skill as a prompt template and spawns one or more Haiku sub-agents to classify all test files. Focus mode skips classification entirely and sends all files directly to mock detection.

When auto-triggered, the sub-agent receives AST metadata from Stage 0 (verification line counts, data flow markers) and uses it as ground truth. Files above 20 are batched in groups of 20-25 and classified in parallel.

## Who is it for

- Orchestrators building custom test audit pipelines who need a standalone classification stage.
- Developers who want a fast, cost-efficient triage pass before committing to full mock analysis.
- Teams working with large test suites where running full mock detection on every file is impractical.

## How it works

The skill defines a 4-part prompt (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) for a Haiku sub-agent. The sub-agent classifies every test file found under `{target}` using a two-pass approach: filename pattern first, content scan second.

Filename patterns determine the default category. Files matching `*.integration.*` are classified as integration tests. Files matching `*.e2e.*` are classified as E2E tests. All other test file patterns default to unit. Content is then scanned to validate the filename classification and detect mock indicators (`jest.mock()`, `vi.mock()`, `patch()`).

After classification, the sub-agent applies deep analysis triggers. Integration and E2E files are always flagged, because the absence of explicit mocks does not rule out T3+ violations. Unit files are flagged when they mock core modules (`spawn`, `fs`, `fetch`, `http`), have more than three top-level mocks, or mock the system under test. The sub-agent also counts verification lines per file, excluding comments, imports, and boilerplate. These counts feed the effectiveness calculation in Stage 3 synthesis.

Output is written to `logs/test-classification-{YYYYMMDD-HHMMSS}.yaml`. A diagnostics file at `logs/diagnostics/test-classification-{YYYYMMDD-HHMMSS}.yaml` records the classification decision and confidence level for each file. The mock-detection stage reads both outputs and analyzes only files marked `needs_deep_analysis: true`.
