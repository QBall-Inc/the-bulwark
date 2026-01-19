# Test Audit Pipeline

## Purpose

Audit test suite quality, identify mock-heavy tests, and prioritize rewrites.

## When to Use

- Test suite quality assessment
- Identifying tests that mock the system under test
- Prioritizing test improvements
- Ensuring T1-T4 compliance

## Entry Points

| Invocation | Trigger |
|------------|---------|
| `/test-audit [path]` | User slash command |
| Conversation: "audit tests in..." | Natural language |
| PostToolUse hook on `*.test.*` | Automatic after test file changes |

## Pipeline Definition

```fsharp
// Test Audit Pipeline
// Pattern: Main Context Orchestration
// Orchestrator loads skill prompt templates and spawns general-purpose sub-agents

// Entry: /test-audit [path] OR hook-triggered
test-classification (Haiku sub-agent, surface classification + line counting)
|> mock-detection (Sonnet sub-agent, deep analysis + violation scope tracking)
|> test-audit synthesis (Sonnet sub-agent, two-gate REWRITE_REQUIRED directive)
|> (if REWRITE_REQUIRED == true
    then Orchestrator (Opus) rewrites tests
    else Done)
|> LOOP(max=2)  // Limit audit-rewrite cycles to prevent infinite loops
```

## Bias Avoidance

This pipeline separates audit work from implementation to prevent self-review bias:

| Role | Executor | Rationale |
|------|----------|-----------|
| Classification | Haiku sub-agent | Surface pattern matching, triage |
| Detection | Sonnet sub-agent | Deep analysis, mock appropriateness evaluation |
| Synthesis | Sonnet sub-agent | Analysis, two-gate REWRITE_REQUIRED logic |
| Rewrite | Opus (orchestrator) | Implementation strength |

The orchestrator (Opus) does NOT perform audit work - only orchestration and implementation.

## Two-Gate REWRITE_REQUIRED Logic

| Gate | Condition | Trigger |
|------|-----------|---------|
| **Gate 1: Impact** | Any P0 violation (false confidence) | REWRITE_REQUIRED regardless of % |
| **Gate 2: Threshold** | P1 violations AND test effectiveness < 95% | REWRITE_REQUIRED |
| **Advisory** | P2 only OR P1 with effectiveness >= 95% | Recommendations only |

**Test Effectiveness** = (verification_lines - affected_lines) / verification_lines

---

## Stage Details

### Stage 1: TestClassifier

**Skill**: `test-classification` (prompt template)

**Model**: Haiku (pattern matching task)

**Invocation**:
```
Task(subagent_type="general-purpose", model="haiku", prompt=<skill template>)
```

**GOAL**: Categorize all tests by type and quality.

**CONSTRAINTS**:
- Do NOT modify any files
- Classify every test file
- Use consistent categories
- Complete within 30 tool calls

**CONTEXT**:
- Target directory: {from $ARGUMENTS or conversation}
- Test file patterns: `*.test.*`, `*.spec.*`, `test_*`
- Project test framework (Jest, Vitest, etc.)

**OUTPUT**: `logs/test-classification-{YYYYMMDD-HHMMSS}.yaml`
```yaml
metadata:
  agent: test-classification
  timestamp: {ISO-8601}
  target: {directory}
  model: haiku

classification:
  total_files: 25
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
  quality_indicators:
    real_integration:
      - file: tests/proxy.test.ts
        indicators: [spawns-process, checks-port]
    mock_heavy:
      - file: tests/auth.test.ts
        indicators: [mocks-fetch, mocks-fs]

summary: |
  Classified 25 test files: 15 unit, 8 integration, 2 e2e.
  Found 3 real integration tests and 5 mock-heavy tests.
```

---

### Stage 2: MockDetector

**Skill**: `mock-detection` (prompt template)

**Model**: Sonnet (deep analysis, mock appropriateness evaluation)

**Invocation**:
```
Task(subagent_type="general-purpose", model="sonnet", prompt=<skill template + classification>)
```

**GOAL**: Identify T1-T4 violations with violation scope tracking for test effectiveness calculation.

**CONSTRAINTS**:
- Do NOT modify any files
- Only analyze files with `needs_deep_analysis: true` from classification
- Track violation scope (affected line ranges, not just violation lines)
- Use call graph analysis to detect broken integration chains
- Complete within 50 tool calls

**CONTEXT**:
- Test classification from Stage 1 (files to analyze, verification_lines)
- Mock appropriateness rubric (unit vs integration vs e2e)
- T1-T4 rules from Rules.md

**OUTPUT**: `logs/mock-detection-{YYYYMMDD-HHMMSS}.yaml`
```yaml
metadata:
  skill: mock-detection
  timestamp: {ISO-8601}
  classification_source: logs/test-classification-{YYYYMMDD-HHMMSS}.yaml
  model: sonnet
  files_analyzed: 5

violations:
  - file: tests/proxy.test.ts
    line: 15
    violation_scope: [15, 95]  # Lines 15-95 depend on the mock
    affected_lines: 80
    rule: T1
    severity: critical
    priority: P0
    pattern: "jest.spyOn(child_process, 'spawn')"
    reason: "Test mocks spawn, all downstream assertions are ineffective"
    suggested_fix: "Use real spawn. Verify with port check."

  - file: tests/api.integration.ts
    line: 8
    violation_scope: [8, 45]
    affected_lines: 37
    rule: T3
    severity: critical
    priority: P1
    pattern: "jest.mock('node-fetch')"
    reason: "Integration test should use real HTTP"
    suggested_fix: "Use MSW or test server."

file_summaries:
  - file: tests/proxy.test.ts
    verification_lines: 95
    affected_lines: 80
    test_effectiveness: 16%

totals:
  critical: 2
  high: 1
  total_affected_lines: 118

summary: |
  Analyzed 5 files. Found 3 violations affecting 118 lines.
  P0: proxy.test.ts (16% effective). P1: api.integration.ts (33% effective).
```

---

### Stage 3: AuditSynthesizer

**Skill**: `test-audit` (synthesis prompt template)

**Model**: Sonnet (analysis and synthesis)

**Invocation**:
```
Task(subagent_type="general-purpose", model="sonnet", prompt=<synthesis template + classification + violations>)
```

**GOAL**: Compile findings into prioritized rewrite list.

**CONSTRAINTS**:
- Do NOT modify any files
- Prioritize by impact (P0 > P1 > P2 > P3)
- Provide actionable rewrite guidance
- Include REWRITE_REQUIRED directive

**CONTEXT**:
- Classification from Stage 1
- Violations from Stage 2
- T1-T4 rules reference

**OUTPUT**: `logs/test-audit-{YYYYMMDD-HHMMSS}.yaml`
```yaml
metadata:
  agent: test-audit
  timestamp: {ISO-8601}
  sources:
    classification: logs/test-classification-{YYYYMMDD-HHMMSS}.yaml
    violations: logs/mock-detection-{YYYYMMDD-HHMMSS}.yaml
  model: sonnet

audit:
  overview:
    total_tests: 142
    compliant: 98
    violations: 44
    critical: 12
  priority_rewrites:
    - file: tests/proxy.test.ts
      priority: P0  # Critical
      violations: [T1]
      reason: "Core functionality mocked - test provides false confidence"
      effort: medium
      approach: |
        Replace mock with real proxy spawn.
        Use port check to verify proxy started.
        Add timeout for startup wait.
    - file: tests/api.integration.ts
      priority: P1  # High
      violations: [T3]
      reason: "Integration test uses mocks - defeats purpose"
      effort: low
      approach: |
        Remove jest.mock('node-fetch').
        Use test server or real endpoint.
  recommendations:
    - "Establish test harness for proxy testing"
    - "Create shared fixtures for integration tests"
    - "Add pre-commit hook to prevent new T1 violations"

# CRITICAL: Orchestrator directive
directive:
  REWRITE_REQUIRED: true
  priority_files: [tests/proxy.test.ts, tests/api.integration.ts]
  rationale: "2 P0/P1 violations require immediate attention"

summary: |
  Audit complete: 44 violations found, 12 critical.
  REWRITE_REQUIRED: true - 2 files need immediate attention.
  Priority: proxy.test.ts (P0, mocks spawn), api.integration.ts (P1, mocks fetch).
```

---

### Stage 4: Test Rewrite (Orchestrator Work)

**Executor**: Orchestrator (Opus) - NOT a sub-agent

**Conditional**: Only executes if `audit.directive.REWRITE_REQUIRED == true`

**Behavior**:
1. Read `priority_files` from audit report
2. For each file, follow `approach` guidance from audit
3. Implement rewrites directly (not delegated to sub-agent)
4. Follow T1-T4 rules strictly
5. Present summary of changes

**Loop Handling**:
- After rewrite, PostToolUse hook may fire again
- Pipeline limited to `LOOP(max=2)` to prevent infinite cycles
- Second pass serves as verification that rewrites resolved violations

**OUTPUT**: Rewritten test files + summary
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

---

## Example Orchestrator Flow

```markdown
## Orchestrator Execution (Main Context)

### Step 1: Resolve Target
- Parse $ARGUMENTS from /test-audit invocation
- OR extract from conversation context
- OR receive from hook additionalContext

### Step 2: Classification Stage
1. Load `test-classification` skill
2. Construct 4-part prompt using skill template
3. Task(subagent_type="general-purpose", model="haiku", prompt=...)
4. Read output: logs/test-classification-{YYYYMMDD-HHMMSS}.yaml

### Step 3: Detection Stage (Sonnet)
1. Load `mock-detection` skill
2. Construct 4-part prompt + include classification as CONTEXT
3. Task(subagent_type="general-purpose", model="sonnet", prompt=...)
4. Read output: logs/mock-detection-{YYYYMMDD-HHMMSS}.yaml

### Step 4: Synthesis Stage
1. Construct synthesis prompt from test-audit skill
2. Include classification + violations as CONTEXT
3. Task(subagent_type="general-purpose", model="sonnet", prompt=...)
4. Read output: logs/test-audit-{YYYYMMDD-HHMMSS}.yaml

### Step 5: Present Summary
Display audit summary to user before proceeding.

### Step 6: Rewrite (if needed)
IF audit.directive.REWRITE_REQUIRED == true:
    For each file in priority_files:
        Implement rewrite using approach from audit
        Follow T1-T4 rules strictly
ELSE:
    Report: "No rewrites required"
```

---

## Success Criteria

- All tests classified
- T1-T4 violations identified with line numbers
- Priority rewrite list generated with approach guidance
- REWRITE_REQUIRED directive produced
- Critical tests rewritten (if any)
- Loop limited to max 2 cycles

---

## T1-T4 Rules Reference

| Rule | Description | Violation Example |
|------|-------------|-------------------|
| T1 | Never mock system under test | `jest.spyOn(spawn)` when testing spawn |
| T2 | Verify observable output | `expect(fn).toHaveBeenCalled()` only |
| T3 | Integration uses real systems | `jest.mock('fs')` in integration test |
| T4 | Run tests before complete | Not running after writing |

---

## Related Skills

| Skill | Purpose |
|-------|---------|
| `test-classification` | Prompt template for Stage 1 (Haiku) - surface classification + line counting |
| `mock-detection` | Prompt template for Stage 2 (Sonnet) - deep analysis + violation scope |
| `test-audit` | Entry point + orchestration + two-gate synthesis |
| `subagent-prompting` | 4-part prompt structure |
| `subagent-output-templating` | Output format for logs/ |

---

## Related Pipelines

- **Fix Validation**: For fixing issues found in tests
- **Test Execution & Fix**: For running and fixing tests
- **Code Review**: For reviewing test code quality
