# Agent Registry

Agents are single-purpose sub-agents spawned by skills via the Task tool. You don't invoke them directly. Each agent has a defined model, reads input from a previous pipeline stage, and writes structured output to `logs/`. Per-agent detail pages live in [`docs/agents/`](../agents/).

## Fix validation agents

| Agent | Model | Purpose | Invoked by |
|-------|-------|---------|------------|
| [bulwark-issue-analyzer](../agents/bulwark-issue-analyzer.md) | Sonnet | Root cause analysis, impact mapping, debug report with tiered validation plan | [fix-bug](../skills/fix-bug.md), [issue-debugging](../skills/issue-debugging.md) |
| [bulwark-implementer](../agents/bulwark-implementer.md) | Opus | Implements fixes and features. Runs implementer-quality.sh after every write. | [fix-bug](../skills/fix-bug.md) |
| [bulwark-fix-validator](../agents/bulwark-fix-validator.md) | Sonnet | Executes tiered test plan from the issue analyzer's debug report. Assesses fix confidence. | [fix-bug](../skills/fix-bug.md), [issue-debugging](../skills/issue-debugging.md) |
| [bulwark-standards-reviewer](../agents/bulwark-standards-reviewer.md) | Sonnet | Validates Claude Code assets against official Anthropic standards. Produces severity-rated findings. | [anthropic-validator](../skills/anthropic-validator.md) |

## Plan creation agents

| Agent | Model | Purpose | Invoked by |
|-------|-------|---------|------------|
| [plan-creation-po](../agents/plan-creation-po.md) | Opus | Product Owner. Explores codebase, produces requirements analysis with scope, acceptance criteria, and user value. | [plan-creation](../skills/plan-creation.md) |
| [plan-creation-architect](../agents/plan-creation-architect.md) | Opus | Technical Architect. Analyzes system design, component decomposition, integration points, and technical trade-offs. | [plan-creation](../skills/plan-creation.md) |
| [plan-creation-eng-lead](../agents/plan-creation-eng-lead.md) | Sonnet | Engineering & Delivery Lead. Produces WBS, effort estimates, dependency graphs, milestones, and risk registers. | [plan-creation](../skills/plan-creation.md) |
| [plan-creation-qa-critic](../agents/plan-creation-qa-critic.md) | Sonnet | QA / Critic. Adversarially challenges assumptions, stress-tests estimates, issues APPROVE/MODIFY/REJECT verdict. | [plan-creation](../skills/plan-creation.md) |

## Product ideation agents

| Agent | Model | Purpose | Invoked by |
|-------|-------|---------|------------|
| [product-ideation-market-researcher](../agents/product-ideation-market-researcher.md) | Sonnet | Researches market size, growth trends, key players, regulatory landscape. Produces TAM/SAM/SOM estimates. | [product-ideation](../skills/product-ideation.md) |
| [product-ideation-idea-validator](../agents/product-ideation-idea-validator.md) | Sonnet | Assesses feasibility, timing, uniqueness, problem-solution fit. Produces PASS/CONDITIONAL/FAIL verdict. | [product-ideation](../skills/product-ideation.md) |
| [product-ideation-competitive-analyzer](../agents/product-ideation-competitive-analyzer.md) | Sonnet | Profiles competitors, analyzes positioning and pricing, identifies market gaps using Porter's Five Forces. | [product-ideation](../skills/product-ideation.md) |
| [product-ideation-segment-analyzer](../agents/product-ideation-segment-analyzer.md) | Sonnet | Identifies target user segments, builds personas using Jobs-to-be-Done, estimates willingness to pay. | [product-ideation](../skills/product-ideation.md) |
| [product-ideation-pattern-documenter](../agents/product-ideation-pattern-documenter.md) | Sonnet | Documents success/failure patterns, competitor trajectories, and opportunity gaps from competitive data. | [product-ideation](../skills/product-ideation.md) |
| [product-ideation-strategist](../agents/product-ideation-strategist.md) | Sonnet | Final synthesis. Produces BUY/HOLD/SELL recommendation with confidence level and actionable next steps. | [product-ideation](../skills/product-ideation.md) |

## Utility agents

| Agent | Model | Purpose | Invoked by |
|-------|-------|---------|------------|
| [statusline-setup](../agents/statusline-setup.md) | Haiku | Handles settings.json updates and config file placement for statusline configuration. | [bulwark-statusline](../skills/bulwark-statusline.md) |

## See also

- [Skill registry](skills.md) — the skills that orchestrate these agents
- [How it works](../guides/how-it-works.md) — how pipelines (Layer 3) spawn and chain agents
