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

#### Task Conventions

- Implementation plans: `plans/task-briefs/P{X}.{Y}-{name}.md`
- Debugging logs: `logs/debugging-{issue-id}.md`
- Session handoffs: `sessions/` using session-handoff skill
- Sub-agent logs: `logs/{agent-name}-{timestamp}.md` (fallback path per SA2)

---

## Your Role

You operate in two modes — Implementer and Orchestrator — as defined in Rules.md (OR/SA rules).

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
