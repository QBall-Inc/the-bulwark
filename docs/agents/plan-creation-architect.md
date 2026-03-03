# plan-creation-architect

Technical Architect agent for the plan-creation pipeline. Analyzes system design, component decomposition, integration points, and technical trade-offs.

## Model

Opus.

## Invocation guidance

Best used through the parent skill. This agent is Stage 2 of the [plan-creation](../skills/plan-creation.md) pipeline. The orchestrator passes it the Product Owner's requirements output, an optional research synthesis path, and the output file path. Without that context, it produces a free-standing architectural analysis with no connection to requirements or downstream effort estimation.

Direct invocation works for standalone architectural analysis on any topic or problem statement. The agent accepts open-ended input and can reason from first principles when no prior pipeline output is available. What's lost is the connection to scoped requirements, acceptance criteria, and the QA/Critic review that follows in the full pipeline. If you want a complete implementation plan, run the parent skill.

**Standalone example:**

```
claude --agent plan-creation-architect "GOAL: Design the architecture for a multi-tenant billing module. CONTEXT: TypeScript monorepo, Postgres, existing auth system."
```

## What it does

Given a topic or problem statement (and the Product Owner's output when running in pipeline mode), the agent uses Glob and Grep to explore the codebase before forming any architectural opinions. It identifies existing patterns, integration points, module boundaries, and technology dependencies rather than inferring them.

From that grounding, it produces a structured architectural analysis covering: high-level design strategy with stated rationale, component decomposition with single responsibilities and boundaries, design pattern selection with fitness justification and anti-patterns flagged, integration contracts for each touchpoint with existing systems, explicit trade-off comparisons for the two or three most consequential design decisions, technology recommendations with alternatives compared, extensibility analysis for the most likely evolution pressures, and a risk register with specific risks and concrete mitigations.

## Output

| File | Description |
|------|-------------|
| `logs/plan-creation/{slug}/02-technical-architect.md` | Full architectural analysis report (8 sections). Pipeline mode. |
| `logs/plan-creation-architect-{YYYYMMDD-HHMMSS}.md` | Same report written to a standalone path when invoked without a pipeline context. |
| `logs/diagnostics/plan-creation-architect-{YYYYMMDD-HHMMSS}.yaml` | Execution metadata: files read, searches run, components identified, trade-offs analyzed, risks identified, output verdict. |
