# plan-creation-po

Product Owner agent for the plan-creation pipeline. Explores the codebase and produces a structured requirements analysis.

## Model

Opus.

## Invocation guidance

Not recommended for standalone use. This agent is Stage 1 of the [plan-creation](../skills/plan-creation.md) pipeline. The orchestrator passes it a structured prompt containing the topic, an optional research synthesis path, and the output file path. Without that context, output is a free-standing requirements document with no downstream consumers.

Direct invocation is possible for one-off requirements analysis, but the result will not feed into architecture, effort estimation, or QA review. Run the parent skill instead if you want a complete implementation plan.

## What it does

Given a topic or problem statement, the agent explores the codebase using Glob, Grep, and Read to discover what already exists, where the integration points are, what constraints apply, and what must not be disrupted. It reads 3-6 relevant files and records why each was selected and what it revealed.

From that codebase context, it produces a structured requirements analysis covering: functional and non-functional requirements, scope definition with explicit deferrals, measurable acceptance criteria, user value with named beneficiaries and magnitude estimates, integration point mapping, and open questions labeled with the responsible downstream role (Architect or Engineering Lead).

## Output

| File | Description |
|------|-------------|
| `logs/plan-creation/{slug}/01-product-owner.md` | Full requirements analysis report (9 sections). Pipeline mode. |
| `logs/plan-creation-po-{YYYYMMDD-HHMMSS}.md` | Same report written to a standalone path when invoked without a pipeline context. |
| `logs/diagnostics/plan-creation-po-{YYYYMMDD-HHMMSS}.yaml` | Execution metadata: files read, searches run, requirements identified, open questions raised, output verdict. |
