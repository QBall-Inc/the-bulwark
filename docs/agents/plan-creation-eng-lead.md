# plan-creation-eng-lead

Engineering and Delivery Lead agent for the plan-creation pipeline. Produces work breakdown structures, effort estimates, dependency graphs, milestones, and risk registers.

## Model

Sonnet.

## Invocation guidance

Not recommended for standalone use. This agent is Stage 3 of the [plan-creation](../skills/plan-creation.md) pipeline. The orchestrator passes it a structured prompt containing the topic, prior-stage log paths (Product Owner and Architect outputs), an optional codebase path, and the output file path. Without that context, it produces a delivery plan with no requirements or architecture grounding.

Direct invocation is possible for standalone delivery planning when you already have a defined scope and architecture. In that case, provide the topic and any available prior-stage documents in the prompt. The result will be a complete delivery plan, but it will not flow into QA review unless you invoke the parent skill.

## What it does

Given a topic and prior-stage context, the agent reads the Product Owner and Architect outputs before producing any estimates. It also explores the codebase with Glob, Grep, and Read to assess actual complexity. Estimates come from codebase evidence, not assumptions.

From that context, it produces a structured delivery plan across eight sections: work breakdown structure, implementation sequencing, effort estimation, dependency graph with critical path, milestones, parallel execution opportunities, risk register with mitigations, and resource considerations. Every workpackage is scoped to a single Claude Code session (200K token window). If a workpackage cannot fit in one session, it is decomposed. Each estimate carries a confidence level (High, Medium, or Low) with a stated rationale.

## Output

| File | Description |
|------|-------------|
| `logs/plan-creation/{slug}/03-eng-delivery-lead.md` | Full delivery plan report (8 sections). Pipeline mode. |
| `logs/plan-creation-eng-lead-{YYYYMMDD-HHMMSS}.md` | Same report written to a standalone path when invoked without a pipeline context. |
| `logs/diagnostics/plan-creation-eng-lead-{YYYYMMDD-HHMMSS}.yaml` | Execution metadata: files read, workpackages defined, phases defined, risks identified, session range, critical path length, output verdict. |
