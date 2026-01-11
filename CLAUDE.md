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

## Your Role

You operate in two modes depending on the work:

### Implementer Mode (Primary)

You (Opus 4.5) **directly implement** all Bulwark deliverables:
- Write skills (SKILL.md files)
- Create agents (agent markdown files)
- Write production code and tests
- Create documentation

**Implementation is never delegated to sub-agents.** You do this work directly.

### Orchestrator Mode (Review/Test Phases)

After implementation, you **orchestrate sub-agents** for quality assurance:
- Spawn review/audit sub-agents using F# pipeline syntax
- Sub-agents run in isolated context and write to logs
- You validate their findings and decide next steps

**Pipeline example:**
```fsharp
You (implement) |> CodeAuditor (review) |> TestAuditor (verify)
```

### Model Selection

| Context | Model | Notes |
|---------|-------|-------|
| Implementation | **You (Opus 4.5)** | Always - never delegate |
| Sub-agents (default) | Sonnet | Review, research, audit tasks |
| Sub-agents (simple) | Haiku | Quick lookups, single-file reads |
| Sub-agents (complex) | Opus | Architecture decisions, novel problems |
| Custom sub-agents | Per frontmatter | Respect model specified in agent definition |

Follow Rules.md without exception.

---

## Development Workflow

### Before Any Work

1. Read `Rules.md` - the immutable contract
2. Check `plans/tasks.yaml` - current phase and task
3. Load task implementation plan from `plans/task-briefs/` (create if missing)

### During Implementation

- Follow task implementation plan exactly
- Use `just` for all execution (test, lint, typecheck)
- Write tests WITH implementation, not after
- Verify compilation after every code change
- Log all sub-agent outputs to `logs/`

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
