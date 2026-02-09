# The Bulwark - Development Guide

You are building The Bulwark, a development workflow enforcement plugin that transforms stochastic AI output into deterministic, engineering-grade artifacts.

For architecture details and deliverables, see `docs/architecture.md`.

---

## Binding Contract

The following commitments are **sacrosanct** and non-negotiable:

| Commitment | Requirement |
|------------|-------------|
| Rules Adherence | 100% compliance with Rules.md at all times |
| Reporting & Logging | All sub-agent outputs written to logs, all decisions documented |
| Coding Standards | Every implementation follows atomic principles and Anthropic guidelines |
| Testability | All code must be testable with real behavior verification |
| Real-World Testing | No mock-only tests for integration points |
| Verification Before Completion | No fix or feature declared complete without verification |
| Anthropic Compliance | All hooks, agents, skills, and plugins match official Anthropic guidelines |

---

## Mandatory Rules

### Read Rules.md

**YOU MUST READ `Rules.md` AT THE START OF EVERY SESSION.**

This is not optional. This is not advisory. This is a binding requirement.

`Rules.md` contains the immutable rules that govern all work in this project, including:
- **SC1-SC3: Skill Compliance Rules** - When a skill is loaded, ALL instructions within it are BINDING. You MUST spawn sub-agents when instructed. You MUST NOT substitute your judgment for skill instructions.
- **T1-T4: Testing Rules** - Real behavior verification, no mock-only tests
- **V1-V4: Verification Rules** - No fix without verification
- **CS1-CS4: Coding Standards** - Atomic principles, no magic, fail fast, clean code

**Failure to read and follow Rules.md is a contract violation.**

If you find yourself thinking "I can handle this directly without following the skill instructions" - STOP. That thought pattern is explicitly prohibited by SC1-SC2 in Rules.md.

### Project Rules (Bulwark-Specific)

These extend Rules.md for this project.

#### Modes of Operation

- **Implementer Mode**: Primary model directly implements all deliverables (OR1)
- **Orchestrator Mode**: Primary model orchestrates sub-agents for review/audit (OR2-OR4, SA1-SA6)

#### Orchestrator Rules (OR)

OR1: Implementation work is always performed by an Opus-class model — either the primary model directly or a dedicated Opus sub-agent (e.g., bulwark-implementer). Non-Opus sub-agents are for review, audit, and research only.

OR2: Sub-Agent Model Selection

When spawning sub-agents for review/audit/research:

| Complexity | Model | Use Cases |
|------------|-------|-----------|
| Simple | Haiku | Quick lookups, single-file reads |
| Standard | **Sonnet** (default) | Code review, test audit, research |
| Complex | Opus | Architecture review, novel problem analysis |

Default to Sonnet unless task clearly fits Simple or Complex.

OR3: Custom sub-agents specify their model in frontmatter. The Orchestrator respects this.

OR4: Use F# pipe syntax for workflow orchestration. Sequential by default; parallel execution supported where documented in pipeline-templates.

#### Sub-Agent Rules (SA)

SA1: All sub-agent invocations use the 4-part template:
1. **GOAL**: What success looks like
2. **CONSTRAINTS**: What cannot be done
3. **CONTEXT**: What the agent needs to know
4. **OUTPUT**: Expected deliverables and format

SA2: All sub-agent output MUST be written to the `logs/` directory. Main thread reads logs, not raw output.

- **When an agent definition specifies output paths and format**: The agent MUST use those exact paths and formats. No additional log files. For example, if the agent specifies `logs/debug-reports/{id}-{timestamp}.yaml`, that is the ONLY output file (plus any diagnostics path also specified). Do NOT also write a generic `.md` file.
- **When no output path is specified**: The agent MUST write output to `logs/{agent-name}-{timestamp}.md` as a fallback.

This is a closed loop: every sub-agent MUST produce a log artifact, and MUST produce exactly the artifacts specified - no more, no fewer.

SA3: Sub-agent results return as summaries only (findings, severity, next actions). Full reasoning stays in logs.

SA4: Complex workflows use F# pipe syntax. Each agent reads previous agent's log output.

SA5: Do not use `run_in_background: true` when spawning sub-agents. Retrieving background agent output via `TaskOutput` or `TaskStop` dumps the full transcript into parent context, causing token spikes. Foreground sub-agents return only their summary (per SA3) while full output goes to logs (per SA2).

SA6: Pipeline suggestions from code-writing sub-agents are **PRESUMED EXECUTE**. The orchestrator MUST run the suggested pipeline unless the user explicitly approves deferral. Orchestrator self-deferral is a rule violation.

- **Default action**: Execute the suggested pipeline immediately
- **Deferral**: Only permitted with explicit user approval. Ask the user: "Pipeline X was suggested for [files]. Execute or defer?"
- **Silent ignoring**: Rule violation
- **Self-rationalizing deferral** (e.g., "change is small", "not warranted"): Rule violation

#### Task Conventions

- Implementation plans: `plans/task-briefs/P{X}.{Y}-{name}.md`
- Debugging logs: `logs/debugging-{issue-id}.md`
- Session handoffs: `sessions/` using session-handoff skill
- Sub-agent logs: `logs/{agent-name}-{timestamp}.md` (fallback path per SA2)

#### Grounding Clause

Validate all new Claude Code assets (hooks, skills, agents, plugins, commands, MCP servers) using the `/anthropic-validator` skill.

---

## Your Role

You operate in two modes — Implementer and Orchestrator — as defined in the Project Rules above.

---

## Development Workflow

### Before Any Work

1. Read `Rules.md` - the immutable contract
2. Check `plans/tasks.yaml` - current phase and task
3. Load task implementation plan from `plans/task-briefs/` (create if missing)

### Before Declaring Complete

- [ ] Typecheck passes (`just typecheck`)
- [ ] Lint passes (`just lint`)
- [ ] Tests pass (`just test`)
- [ ] Tests verify real behavior (not mocks)
- [ ] Matches Anthropic guidelines
- [ ] Changes verified, not just implemented

---

## Common Commands

```bash
just typecheck    # Type checking
just lint         # Linting
just test         # Run tests
```

---

## Emergency Procedures

### Context Running Low Unexpectedly

```
Context budget critical. Immediate handoff required.

Creating minimal handoff with:
- Current state
- Files touched
- Next steps
```

### Blocked by External Dependency

```
Blocked: [description of blocker]

Cannot proceed without: [what's needed]

Options:
1. [Alternative approach if any]
2. Park task, move to next
3. Await resolution

Recommend: [your recommendation]
```

### Rule Violation Detected

```
Rule violation detected: [rule ID]

Violation: [what happened]
Correction: [what should happen]

Reverting and re-attempting with correct approach.
```

---

## Quick References

| Document | Purpose |
|----------|---------|
| `Rules.md` | Immutable contract - **READ BEFORE ANY WORK** |
| `starter-prompt.md` | Session startup, checkpoints, closing sequences |
| `docs/architecture.md` | What we're building (agents, skills, pipelines) |
| `plans/tasks.yaml` | Current phase and task status |
| `plans/task-briefs/` | Implementation plans per task |
| `plans/references.md` | External resources and patterns |
| `sessions/` | Latest session handoff for context |

---

**CRITICAL**: Before any work, read `Rules.md`. The contract is non-negotiable.
