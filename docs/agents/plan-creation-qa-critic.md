# plan-creation-qa-critic

QA / Critic agent for the plan-creation pipeline. Adversarially challenges assumptions, stress-tests estimates, and issues a final APPROVE/MODIFY/REJECT verdict.

## Model

Sonnet.

## Invocation guidance

Not recommended for standalone use. This agent is Stage 4, the final stage, of the [plan-creation](../skills/plan-creation.md) pipeline. The orchestrator passes it the output paths from the Product Owner, Technical Architect, and Engineering Lead agents. Without those prior-stage outputs, the agent cannot identify cross-cutting gaps or escalate underrated risks, which are its primary functions.

Direct invocation is possible for adversarial review of any plan, proposal, or design document. Provide the document inline or as a file path. The agent applies the same critique disciplines but cannot challenge prior-agent assumptions because no prior agents exist in standalone mode.

## What it does

Reads all three prior-stage reports in full before forming any critique. It does not re-derive requirements or repeat architectural analysis. Its job is to find what the other three agents collectively missed: the optimistic assumption that runs unchallenged across all outputs, the estimate that ignores messy integration, the acceptance criterion that cannot be verified, and the failure mode that nobody named.

The critique covers six areas: assumption challenging (with evidence for and against each), gap identification (novel findings only, not restatements of prior-agent findings), estimate stress-testing (identifying the 2-3 workpackages most likely to blow their estimates and why), risk escalation (prior-agent risks that were underrated, plus risks not named at all), testability review (each acceptance criterion assessed for objective verifiability), and kill criteria (the specific conditions under which the project should be abandoned). The agent then issues one of three verdicts. APPROVE means the plan is sound. MODIFY means it is conditionally approvable, with a checklist of required changes. REJECT means there are fundamental gaps that revision cannot fix.

## Output

| File | Description |
|------|-------------|
| `logs/plan-creation/{slug}/04-qa-critic.md` | Full critique report: assumptions challenged, gaps identified, estimate stress test, risk escalations, testability review, kill criteria, and final verdict. Pipeline mode. |
| `logs/plan-creation-qa-critic-{YYYYMMDD-HHMMSS}.md` | Same report at a standalone path when invoked without a pipeline context. |
| `logs/diagnostics/plan-creation-qa-critic-{YYYYMMDD-HHMMSS}.yaml` | Execution metadata: prior outputs read, assumptions challenged, novel gaps found, risks escalated, criteria reviewed, kill criteria defined, verdict. |
