---
name: subagent-prompting
description: Template for structured sub-agent invocation using 4-part prompting (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) and F# pipeline notation. Use when orchestrating sub-agents or designing multi-agent workflows.
user-invocable: false
---

# Sub-Agent Prompting Template

## Overview

This skill provides a standardized template for invoking sub-agents with deterministic inputs and predictable outputs. Use this when:

- Orchestrating specialist sub-agents (code auditor, test auditor, etc.)
- Designing multi-agent workflows with conditional branching
- Ensuring consistent prompt structure across sub-agent invocations

## 4-Part Template (Required)

Every sub-agent invocation MUST include all four parts. Incomplete prompts lead to unpredictable behavior.

### GOAL (What Success Looks Like)

State the high-level objective, not just the action. Good goals are outcome-focused.

```markdown
## GOAL

[Describe the desired end state, not the process]

Examples:
- GOOD: "Identify all security vulnerabilities that could allow unauthorized data access"
- BAD: "Review the auth file"

- GOOD: "Refactor authentication module for improved maintainability without breaking existing tests"
- BAD: "Refactor the code"
```

### CONSTRAINTS (What You Cannot Do)

Explicit boundaries prevent scope creep and unexpected changes.

```markdown
## CONSTRAINTS

- [Hard limit 1: e.g., "Do NOT modify any files"]
- [Hard limit 2: e.g., "Do NOT add new dependencies"]
- [Hard limit 3: e.g., "Maintain backward API compatibility"]
- [Resource limit: e.g., "Complete within 50 tool calls"]

Examples:
- "Identify issues only - do NOT implement fixes"
- "Read-only analysis - no file modifications"
- "Focus only on files in src/auth/ directory"
```

### CONTEXT (What You Need to Know)

Provide all information required to complete the task. Sub-agents run in isolated context and cannot access parent conversation.

```markdown
## CONTEXT

### Files to Analyze
- `path/to/file1.ts` - [brief description of relevance]
- `path/to/file2.ts` - [brief description of relevance]

### Related Context
- Previous findings: [summary of relevant prior work]
- Architecture notes: [relevant design decisions]
- Known issues: [existing problems to be aware of]

### Standards to Apply
- [Coding standard or guideline reference]
- [Security policy reference if applicable]
```

### OUTPUT (What to Deliver)

Specify concrete deliverables with exact format requirements.

```markdown
## OUTPUT

### Primary Deliverable
Write findings to: `logs/{agent-name}-{timestamp}.md`

### Output Format
[Specify structure: YAML, Markdown sections, etc.]

### Summary Requirements
Return to main thread: [max 200 tokens summary of key findings]

### Diagnostic Output
Write to: `logs/diagnostics/{agent-name}-{timestamp}.yaml`
```

---

## Pipeline Syntax (F# Conceptual Notation)

### Understanding the Notation

F# pipe syntax (`|>`) is a **conceptual notation** for planning and documentation. It is NOT directly executable Claude Code syntax.

```fsharp
// This is documentation, not executable code
Agent1 (task) |> Agent2 (task) |> Agent3 (task)
```

**Purpose**: Visualize workflow dependencies and conditional logic before implementation.

### Mapping to Task() Invocations

Each pipeline stage maps to a sequential `Task()` call from the main thread:

```fsharp
// Conceptual pipeline
CodeAuditor (security) |> CodeAuditor (architecture) |> (if findings > 0 then IssueDebugger else Done)
```

**Actual execution**:

1. Main thread invokes: `Task(description="Security audit", subagent_type="sonnet", prompt="[4-part prompt]")`
2. Main thread reads log output, extracts findings
3. Main thread invokes: `Task(description="Architecture audit", subagent_type="sonnet", prompt="[4-part prompt]")`
4. Main thread reads log output, extracts findings
5. IF `findings.count > 0`: Main thread invokes IssueDebugger
6. ELSE: Pipeline complete

### Pipeline Patterns

**Code Review Pipeline:**
```fsharp
CodeAuditor (security)
|> CodeAuditor (architecture)
|> TestAuditor (coverage)
|> (if findings > 0 then IssueDebugger else Done)
```

**Fix Validation Pipeline:**
```fsharp
IssueDebugger (root cause)
|> Implementer (apply fix)
|> CodeAuditor (verify quality)
|> TestAuditor (verify tests)
|> (if issues > 0 then IssueDebugger else Done)  // Loop until clean
```

**Test Audit Pipeline:**
```fsharp
TestAuditor (classify all)
|> (if mock_heavy > 0 then VerificationScriptCreator else Done)
|> Implementer (rewrite flagged)
|> TestAuditor (re-verify)
```

### Key Constraint

Sub-agents CANNOT spawn other sub-agents. All pipeline orchestration happens from the main thread.

---

## Model Selection Guidance

### Decision Matrix

| Model | Use For | Cost | When to Choose |
|-------|---------|------|----------------|
| **Opus** | Planning, architecture, novel problems | Highest | System design decisions, security audits requiring judgment, complex trade-off analysis |
| **Sonnet** | Development, complex analysis, integration | Medium | Feature implementation, code review, most sub-agent tasks |
| **Haiku** | Operations, pattern matching, lookups | Lowest | Unit tests, classification tasks, quick file searches |

### Model Selection Rules

1. **Opus is ONLY for planning/architecture** - Reserve expensive models for decisions, not execution
2. **Sonnet is the default** - Use for most sub-agent work requiring analysis
3. **Haiku for simple tasks** - Pattern matching, classification, quick lookups

### Anti-Patterns

| Anti-Pattern | Why It's Wrong | Correct Approach |
|--------------|----------------|------------------|
| Using Opus for implementation | Wastes budget on execution | Use Sonnet for implementation |
| Using Haiku for security audits | Misses nuanced vulnerabilities | Use Sonnet or Opus |
| No model specified | Unpredictable behavior | Always specify `subagent_type` |

---

## Diagnostic Output (Required)

When this skill is used to invoke a sub-agent, the sub-agent MUST write diagnostic output.

### Diagnostic File Location

```
logs/diagnostics/{skill-name}-{YYYYMMDD-HHMMSS}.yaml
```

### Diagnostic Format

```yaml
skill: subagent-prompting
timestamp: 2026-01-10T12:30:45Z
diagnostics:
  model_requested: sonnet
  model_actual: sonnet
  context_type: main
  parent_vars_accessible: true
  hooks_fired: []
  execution_time_ms: 1250
  completion_status: success
notes: "Skill invoked successfully"
```

### When to Write Diagnostics

- At the END of skill execution (success or failure)
- Include actual model used (may differ from requested)
- Record execution time for performance tracking

---

## Quick Reference

### Prompt Checklist

```markdown
[ ] GOAL: Outcome-focused objective stated
[ ] CONSTRAINTS: Hard limits explicitly listed
[ ] CONTEXT: All required files and background provided
[ ] OUTPUT: Log path, format, and summary requirements specified
[ ] DIAGNOSTIC: logs/diagnostics/ path included
```

### Task() Invocation Template

```python
Task(
    description="[3-5 word summary]",
    subagent_type="sonnet",  # or "haiku", "opus"
    prompt="""
## GOAL
[Outcome-focused objective]

## CONSTRAINTS
- [Limit 1]
- [Limit 2]

## CONTEXT
[Files, background, standards]

## OUTPUT
Write to: logs/{agent}-{timestamp}.md
Diagnostic: logs/diagnostics/{agent}-{timestamp}.yaml
Summary: [max 200 tokens]
"""
)
```

---

## References

For extended examples and edge cases, see `references/examples.md`.
