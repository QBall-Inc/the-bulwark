# Skill Registry

The Bulwark ships 30 skills. Each one is invoked with `/the-bulwark:{skill-name}` or triggered automatically by hooks and pipelines. Skills are grouped by what they do. Per-skill detail pages live in [`docs/skills/`](../skills/).

## Product & strategy

Skills for ideation, research, and planning. These don't write code. They run multi-agent pipelines that produce structured documents.

| Skill | What it does | Sub-agents |
|-------|-------------|------------|
| [product-ideation](../skills/product-ideation.md) | Evaluates product ideas through a 6-agent pipeline. Produces a BUY/HOLD/SELL recommendation with market analysis, competitive intelligence, and segment targeting. | [market-researcher](../agents/product-ideation-market-researcher.md), [idea-validator](../agents/product-ideation-idea-validator.md), [competitive-analyzer](../agents/product-ideation-competitive-analyzer.md), [segment-analyzer](../agents/product-ideation-segment-analyzer.md), [pattern-documenter](../agents/product-ideation-pattern-documenter.md), [strategist](../agents/product-ideation-strategist.md) |
| [bulwark-research](../skills/bulwark-research.md) | Spawns 5 parallel sub-agents to research different viewpoints on a topic. Merges findings into a synthesis document. | 5 parallel Sonnet agents (dynamically created) |
| [bulwark-brainstorm](../skills/bulwark-brainstorm.md) | Dual-mode brainstorming. `--scoped` runs 5 roles sequentially via Task tool. `--exploratory` runs 4 roles concurrently via Agent Teams with real-time peer debate. | Sequential: 5 role agents. Agent Teams: 4 concurrent agents + Critic. |
| [plan-creation](../skills/plan-creation.md) | Creates implementation plans with a 4-role scrum team. Produces phases, workpackages, tasks, and delivery schedules. Dual-mode (Task tool or Agent Teams). | [PO](../agents/plan-creation-po.md), [Architect](../agents/plan-creation-architect.md), [Eng Lead](../agents/plan-creation-eng-lead.md), [QA/Critic](../agents/plan-creation-qa-critic.md) |
| [plan-to-tasks](../skills/plan-to-tasks.md) | Transforms a `plan-creation` plan into CLEAR-compatible execution structure — `tasks.yaml` workpackage index plus per-WP YAML files. Supports parent/child plan linkage with bidirectional references. | None (single-context pipeline) |

## Code quality

Skills that review, test, and fix code. These are the enforcement layer that runs after you write code.

| Skill | What it does | Sub-agents |
|-------|-------------|------------|
| [code-review](../skills/code-review.md) | Three-phase code review: static tools, LLM judgment across 3-4 aspects (security, type safety, standards), and diagnostic log. | 3-4 Sonnet agents (aspect-specific) |
| [test-audit](../skills/test-audit.md) | Audits test suites for T1-T4 violations using AST analysis, mock detection, and multi-stage synthesis. Triggers automatic rewrites when quality gates fail. | Haiku (classification), Sonnet (mock detection, synthesis) |
| [fix-bug](../skills/fix-bug.md) | 5-stage fix validation pipeline: analyze, implement, write tests, audit tests, validate fix. | [issue-analyzer](../agents/bulwark-issue-analyzer.md), [implementer](../agents/bulwark-implementer.md), [fix-validator](../agents/bulwark-fix-validator.md) |
| [issue-debugging](../skills/issue-debugging.md) | Systematic debugging methodology with root cause analysis, impact mapping, tiered validation plans, and confidence assessment. | [issue-analyzer](../agents/bulwark-issue-analyzer.md), [fix-validator](../agents/bulwark-fix-validator.md) |
| [spec-drift-check](../skills/spec-drift-check.md) | Audits a WP brief, plan doc, or memory entry for drift against current code state. Extracts claims, verifies each, emits PROCEED/STOP verdict. Mandatory Stage 0 (per `SD1` rule) of any new or resumed WP implementation. | None (single-context pipeline) |
| [mock-detection](../skills/mock-detection.md) | Deep mock appropriateness analysis. Determines whether mocks in a test file are legitimate or T1-T4 violations. | Sonnet agent (analysis) |
| [test-classification](../skills/test-classification.md) | Classifies test files by type (unit, integration, E2E) and identifies which files need deeper mock analysis. | Haiku agents (batch classification) |
| [test-fixture-creation](../skills/test-fixture-creation.md) | Creates unbiased test fixtures using a Sonnet agent that can't read the implementation. Fixtures integrate with project infrastructure and hook automation. | Sonnet agent (fixture generation) |
| [bulwark-verify](../skills/bulwark-verify.md) | Generates runnable verification scripts for components by orchestrating assertion-patterns and component-patterns. | Sonnet agent (script generation) |
| [assertion-patterns](../skills/assertion-patterns.md) | Reference for transforming T1-T4 violating tests into real output verification. Loaded by other skills as context. | None (reference skill) |
| [component-patterns](../skills/component-patterns.md) | Per-component-type verification approaches. Loaded by bulwark-verify as context for generating verification scripts. | None (reference skill) |
| [bug-magnet-data](../skills/bug-magnet-data.md) | Curated edge case test data for boundary testing. Provides pre-organized data by type (dates, strings, numbers, Unicode, etc.) for test generation. | None (reference skill) |

## Project setup & tooling

Skills for initializing projects, configuring tooling, and managing sessions.

| Skill | What it does | Sub-agents |
|-------|-------------|------------|
| [init](../skills/init.md) | Guided project initialization. Installs Rules.md, creates CLAUDE.md, offers LSP setup, Justfile scaffolding, and statusline configuration. Auto-detects brownfield projects. | None (orchestrates other skills) |
| [bulwark-scaffold](../skills/bulwark-scaffold.md) | Generates Justfile with build/typecheck/lint recipes, creates logs directory, and optionally configures hooks. | None |
| [setup-lsp](../skills/setup-lsp.md) | Configures Language Server Protocol integration. Detects project languages, offers to install language servers, verifies post-restart initialization. | None |
| [bulwark-statusline](../skills/bulwark-statusline.md) | Configures the Claude Code status line to show token usage and cost in real-time. Supports preset switching and customization. | [statusline-setup](../agents/statusline-setup.md) |
| [session-handoff](../skills/session-handoff.md) | Creates session handoff documents for context transfer between sessions. Ensures proper YAML headers, LF line endings, and complete documentation of progress and decisions. | None |
| [governance-protocol](../skills/governance-protocol.md) | The governance protocol injected at session start via the SessionStart hook. Not invoked directly. | None |

## Meta skills

Skills for building more skills, orchestrating pipelines, and improving existing workflows.

| Skill | What it does | Sub-agents |
|-------|-------------|------------|
| [create-skill](../skills/create-skill.md) | Generates Claude Code skills from requirements. Runs an adaptive interview, classifies complexity, and produces SKILL.md with references and templates. | Sonnet agent (validation) |
| [create-subagent](../skills/create-subagent.md) | Generates single-purpose sub-agents for use via the Task tool. Produces agent definition with diagnostics and permissions setup. | Sonnet agent (validation) |
| [continuous-feedback](../skills/continuous-feedback.md) | Parses past session learnings and memory files to identify improvement targets. Proposes concrete skill/agent modifications with copy-paste ready patches. | Sonnet agents (analysis, proposal generation) |
| [anthropic-validator](../skills/anthropic-validator.md) | Validates Claude Code assets (skills, hooks, agents, plugins) against official Anthropic standards. Fetches latest docs dynamically. | [standards-reviewer](../agents/bulwark-standards-reviewer.md) |
| [pipeline-templates](../skills/pipeline-templates.md) | Pre-defined workflow templates for multi-agent orchestration. Provides code review, fix validation, test audit, new feature, and research pipelines. | None (reference skill) |
| [subagent-prompting](../skills/subagent-prompting.md) | Template for structured sub-agent invocation using 4-part prompting (GOAL/CONSTRAINTS/CONTEXT/OUTPUT) and F# pipeline notation. | None (reference skill) |
| [subagent-output-templating](../skills/subagent-output-templating.md) | Template for structured sub-agent output including YAML log format and task completion reports. | None (reference skill) |

## See also

- [Agent registry](agents.md) — the single-purpose sub-agents these skills spawn
- [Conventions](conventions.md) — the CS/T/V/ID rules skills enforce
- [Guides](../guides/) — workflow walkthroughs that chain these skills together
