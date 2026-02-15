# Deep Mode Detection Prompt

Use this template for Stage 2 in **Deep mode only**. In Deep mode, the detection agent self-computes classification metadata (normally provided by Stage 1) using AST output.

## GOAL

Analyze ALL provided test files for T1-T4 violations using mock appropriateness rubric and call graph analysis. For each file, self-compute classification metadata (test type, mock indicators, needs_deep_analysis) before performing detection. Track the full scope of each violation for test effectiveness calculation.

## CONSTRAINTS

- Do NOT modify any files
- Analyze ALL provided files (no classification filtering — this is Deep mode)
- Use AST metadata as ground truth for verification_lines (do not re-estimate)
- Use AST data-flow violations as starting leads for T3+ analysis
- Use AST skip markers as T4 violations (deterministic — no further analysis needed)
- Use call graph analysis to detect T1-T3 violations beyond AST leads
- Track violation scope (all affected lines, not just violation line)
- Provide full context for each violation (line, snippet, reason, fix)
- Complete within 50 tool calls per batch

## CONTEXT

**Mode:** Deep (all files analyzed, no classification stage)

**Files to analyze:** {list of ALL test files}

**AST metadata per file:**
```
{for each file}:
  file: {path}
  verification_lines: {metrics.test_logic_lines from verify-count}
  assertion_lines: {metrics.assertion_lines}
  framework: {metrics.framework_detected}
  skip_markers: {markers from skip-detect, or "none"}
  data_flow_leads: {violations from ast-analyze, or "none"}
```

**Self-classification instructions:**
For each file, determine before analysis:
1. **Test type**: unit / integration / e2e (infer from file name, directory, imports, setup patterns)
2. **Mock indicators**: list jest.mock/vi.mock/sinon calls found
3. **Complexity assessment**: simple (few mocks) / complex (many mocks, deep chains)

**Mock appropriateness rubric:** See mock-detection skill's "Mock Appropriateness Rubric" section

**T1-T4 detection patterns:** See mock-detection skill's "T1-T4 Detection Patterns" section

**Extended stub/fake patterns:** See `skills/mock-detection/references/stub-patterns.md` (loaded via mock-detection dependency)

**False positive prevention:** See `skills/mock-detection/references/false-positive-prevention.md` (loaded via mock-detection dependency) — consult BEFORE flagging borderline patterns

## OUTPUT

Write violations to: `logs/mock-detection-{YYYYMMDD-HHMMSS}.yaml`

Write diagnostics to: `logs/diagnostics/mock-detection-{YYYYMMDD-HHMMSS}.yaml`

Use the same output schema as the mock-detection skill's "Output Schema" section, with one addition — include a `self_classification` block per file:

```yaml
self_classification:
  - file: tests/proxy.test.ts
    test_type: unit
    mock_indicators: ["jest.spyOn(child_process, 'spawn')"]
    needs_deep_analysis: true
    reason: "Mock intercepts core dependency"
```
