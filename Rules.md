# The Bulwark - Immutable Rules

These rules form an **immutable contract** for Bulwark development. Follow without exception.

---

## Grounding Clause

Every implementation must:

1. **Match Official Anthropic Guidelines** for hooks, agents, skills, and plugins
2. **Use only documented Claude Code patterns** - no undocumented behaviors

Reference documentation:
- Hooks: https://docs.anthropic.com/en/docs/claude-code/hooks
- Skills: https://docs.anthropic.com/en/docs/claude-code/skills
- Sub-agents: https://docs.anthropic.com/en/docs/claude-code/sub-agents
- Plugins: https://docs.anthropic.com/en/docs/claude-code/plugins

---

## Coding Standards (CS)

### CS1: Atomic Principles

Every function, skill, and agent must be:
- **Single Responsibility**: One purpose only
- **Self-Contained**: Explicit inputs/outputs, minimal dependencies
- **Independently Verifiable**: Can be tested in isolation

### CS2: No Magic

- No implicit behaviors or hidden dependencies
- No undocumented side effects
- All configuration explicit

### CS3: Fail Fast

- Validate inputs at boundaries
- Return errors early, no silent failures
- All errors must be actionable

### CS4: Clean Code

- No unused imports or variables
- No commented-out code blocks
- If something is removed, delete it completely

---

## Testing Rules (T)

### T1: Never Mock the System Under Test

If testing that a proxy starts, **actually start a proxy**.

```typescript
// FORBIDDEN
jest.spyOn(child_process, 'spawn').mockReturnValue(mockProcess);
expect(child_process.spawn).toHaveBeenCalled();

// REQUIRED
const result = await startProxy();
expect(await checkPort(8096)).toBe(true);
```

### T2: Verify Observable Output

Tests verify **results**, not that functions were called.

```typescript
// FORBIDDEN: expect(db.save).toHaveBeenCalled();
// REQUIRED:  expect((await db.find(id)).status).toBe('active');
```

### T3: Integration Tests Use Real Systems

- File operations: Write and read real files
- Process operations: Spawn real processes
- No mocking at integration boundaries
- Explore ways to set up test harness to validate real system behavior. If not possible to set up test harness, say: "I cannot set up a test harness to validate real system behavior for these tests. Please run these tests manually and confirm."

---

### T4: Run Tests Before Declaring Complete

After writing tests: run them, check output, verify they catch failures.

---

## Verification Rules (V)

### V1: No Fix Without Verification

**Never declare a fix complete without verification.**

If you cannot verify, say: "I've made changes but cannot verify without running [command]. Please run and confirm."

### V2: Use `just` for Execution

```bash
just test      # Not: npm test
just lint      # Not: npm run lint
just typecheck # Not: npx tsc
```

### V3: Check Logs for Full Output

When `just` runs: full output goes to `logs/`, summary to stdout. Read logs before attempting fixes.

### V4: Verify Compilation After Changes

After any code edit: `just typecheck && just lint`. Do not proceed if either fails.

---

## Orchestrator Rules (OR)

### OR1: Implementation is Never Delegated

You (Opus 4.5) directly implement all deliverables:
- Skills, agents, production code, tests, documentation

Sub-agents are for **review and audit only**, never implementation.

### OR2: Sub-Agent Model Selection

When spawning sub-agents for review/audit/research:

| Complexity | Model | Use Cases |
|------------|-------|-----------|
| Simple | Haiku | Quick lookups, single-file reads |
| Standard | **Sonnet** (default) | Code review, test audit, research |
| Complex | Opus | Architecture review, novel problem analysis |

**Default to Sonnet** unless task clearly fits Simple or Complex.

### OR3: Custom Sub-Agent Models

Custom sub-agents specify their model in frontmatter. The Orchestrator respects this.

### OR4: Sequential Execution

The Orchestrator executes agents **sequentially** using F# pipe syntax for workflow orchestration:

```fsharp
AgentA |> AgentB |> (if condition then AgentC else Done)
```

Note: True parallel execution requires manual multi-terminal setup. The F# syntax represents logical workflow order, not parallel execution.

---

## Sub-Agent Rules (SA)

### SA1: Structured Prompting

All sub-agent invocations use the 4-part template:
1. **GOAL**: What success looks like
2. **CONSTRAINTS**: What cannot be done
3. **CONTEXT**: What the agent needs to know
4. **OUTPUT**: Expected deliverables and format

### SA2: Output to Logs

Sub-agent output written to `logs/{agent-name}-{timestamp}.md`. Main thread reads logs, not raw output.

### SA3: No Direct Context Pollution

Sub-agent results return as summaries only (findings, severity, next actions). Full reasoning stays in logs.

### SA4: Pipeline Orchestration

Complex workflows use F# pipe syntax. Each agent reads previous agent's log output.

---

## Issue Debugging Rules (ID)

### ID1: Holistic Analysis beofre fixing

- Understand root cause (not just symptom), trace execution path, identify all affected areas.
- Rank issue complexity based on execution path and affected areas
  - Low complexity: Self-contained, no affected areas
  - Medium complexity: At least one affected areas, with one or more integration tests failing
  - High complexity: More than 5 integration test failures

### ID2: Fix Validation Loop

Fixes must be verified. A fix is not complete until:
- Root cause documented
- Fix implemented and reviewed
- Tests pass. Tests to be run based on issue complexity:
  - Low complexity: Unit Tests
  - Medium complexity: Integration Tests + E2E Tests of affected areas
  - High complexity: All Tests
- No new issues introduced

### ID3: Document the Journey

Log debugging steps to `logs/debugging-{issue-id}.md`: symptoms, hypotheses tested, root cause, fix applied, verification results.

---

## Task Rules (TR)

### TR1: Implementation Plan Required

Every task requires an implementation plan before execution.

**Location**: `plans/task-briefs/P{X}.{Y}-{name}.md`

### TR2: Plan Structure

Plans must include: Functional Requirements, Technical Requirements, Technical Design, Success Criteria, Verification Plan, Future Enhancements

### TR3: Research & Plan Before Implementation

```
Task → Research → Plan → Review → Implementation → Verification
```

- After research, review research & proposal with user
- Create plan & review plan with user
- Do NOT begin implementation without a reviewed plan.

---

## Skill Compliance Rules (SC)

### SC1: Skill Instructions Are Binding

When a skill is loaded, ALL instructions within it are **BINDING**, not advisory:
- Steps marked "MANDATORY" or "REQUIRED" must be executed
- Steps must be executed **IN ORDER** unless explicitly stated otherwise
- Do NOT substitute judgment for skill instructions
- Do NOT skip steps because they seem unnecessary

### SC2: Sub-Agent Spawning Is Mandatory

When a skill specifies sub-agent spawning (e.g., `Task(subagent_type=...)`:
- You **MUST** spawn the sub-agent as instructed
- You **MUST NOT** perform the sub-agent's work yourself
- The sub-agent model selection is intentional (Haiku for simple, Sonnet for standard)

### SC3: Skill Execution Verification

After executing a skill:
- Verify all mandatory steps were completed
- Verify all required outputs were generated
- If any step was skipped, document why and re-attempt

---

## Session Rules (SR)

### SR1: Follow Starter Prompt

Every session begins with an initial user prompt, also stored at `starter-prompt.md`.


### SR2: Token Checkpoints

| Consumption | Action |
|-------------|--------|
| 50% | Status check - confirm on track |
| 65% | Begin wrap-up, take user guidance |
| 75% | **STOP** - Create handoff, await confirmation |

- Add checkpoints explicitly to ToDo list. Prompt user to run `/context` at each checkpoint
- Do NOT proceed to the next step until user confirms token usage

### SR3: Token Estimation

| Task Type | Tokens | Strategy |
|-----------|--------|----------|
| Atomic skill | 15-25K | Single session |
| Composite skill / Agent | 25-40K | May span sessions |
| Research / Multi-file | 40-60K | Split into sub-tasks |

**If estimated > 50% budget**: Split task before starting.

### SR4: Session Handoff

Before ending: ensure `/tasks` reflect current state, create handoff in `sessions/` using the session-handoff skill, update `tasks.yaml`, document blockers and next steps.

---

**These rules are non-negotiable. Violations waste time and tokens.**
