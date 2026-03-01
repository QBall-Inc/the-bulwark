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

### T2: Verify Observable Output

Tests verify **results**, not that functions were called.

### T3: Integration Tests Use Real Systems

- File operations: Write and read real files
- Process operations: Spawn real processes
- No mocking at integration boundaries
- Explore ways to set up test harness to validate real system behavior. If not possible to set up test harness, say: "I cannot set up a test harness to validate real system behavior for these tests. Please run these tests manually and confirm."

### T4: Run Tests Before Declaring Complete

Write tests WITH implementation, not after. Run them, check output, verify they catch failures.

---

## Verification Rules (V)

### V1: No Fix Without Verification

**Never declare a fix complete without verification.**

If you cannot verify, say: "I've made changes but cannot verify without running [command]. Please run and confirm."

### V2: Use `just` for Execution

Use project task runner (`just`) for all execution — not npm/npx directly.

### V3: Check Logs for Full Output

When `just` runs: full output goes to `logs/`, summary to stdout. Read logs before attempting fixes.

### V4: Verify Compilation After Changes

After any code edit: `just typecheck && just lint`. Do not proceed if either fails.

---

## Issue Debugging Rules (ID)

### ID1: Holistic Analysis before Fixing

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

Log debugging steps: symptoms, hypotheses tested, root cause, fix applied, verification results. Store in project-defined location.

---

## Task Rules (TR)

### TR1: Implementation Plan Required

Every task requires an implementation plan before execution. Store plans in a project-defined location.

### TR2: Plan Structure

Plans must include: Functional Requirements, Technical Requirements, Technical Design, Success Criteria, Verification Plan, Future Enhancements

### TR3: Research & Plan Before Implementation

Task → Research → Plan → Review → Implementation → Verification

- After research, review research & proposal with user
- Create plan & review plan with user
- Do NOT begin implementation without a reviewed plan.

### TR4: Task Identification and Dependencies

Every task in the tasklist must include a unique sequential identifier in its subject (e.g., `T-001: Rewrite Rules.md`).

- IDs increment globally across sessions (the tasklist persists via `CLAUDE_CODE_TASK_LIST_ID`)
- All blocking dependencies must be set via `addBlockedBy`/`addBlocks` at creation time
- After inserting new tasks, verify the dependency chain: no missing blockers, no circular dependencies, correct execution order
- New tasks inserted between existing tasks use the next available ID (ordering is by dependencies and list position, not ID sequence)

### TR5: Task Descriptions Are Durable

Task descriptions must be self-contained — include enough context for a future session to understand and execute without additional lookup.

- The tasklist is the primary reference for in-session execution and survives across sessions
- Include: what needs to be done, relevant file paths, and acceptance criteria where applicable
- Completed tasks are dropped; active and pending tasks carry forward

---

## Skill Compliance Rules (SC)

### SC1: Skill Instructions Are Binding

When a skill is loaded, ALL instructions within it are **BINDING**, not advisory:
- Steps marked "MANDATORY" or "REQUIRED" must be executed
- Steps must be executed **IN ORDER** unless explicitly stated otherwise
- Do NOT substitute judgment for skill instructions
- Do NOT skip steps because they seem unnecessary

### SC2: Sub-Agent Spawning Is Mandatory

When a skill specifies sub-agent spawning (e.g., `Task(subagent_type=...)`):
- You **MUST** spawn the sub-agent as instructed
- You **MUST NOT** perform the sub-agent's work yourself
- The sub-agent model selection is intentional (Haiku for simple, Sonnet for standard)

### SC3: Skill Execution Verification

After executing a skill:
- Verify all mandatory steps were completed
- Verify all required outputs were generated
- If any step was skipped, document why and re-attempt

---

## Code Navigation Rules (CN)

### CN1: Prefer LSP for Semantic Operations

When LSP is available, use it for go-to-definition, find-references, type information, symbol search, and implementation tracing. Fall back to Grep only when LSP is unavailable, returns no results, or the target is a non-code file (docs, config, logs).

### CN2: Search Tool Hierarchy

| Operation | Preference Order |
|-----------|-----------------|
| Code navigation (definitions, references, types) | LSP > Grep > Glob |
| File content search | Grep > Glob |
| File discovery | Glob |

Do not use Grep/Glob for operations LSP handles semantically (e.g., finding all callers of a function). LSP respects scope, types, and inheritance; text search does not.

---

## Session Rules (SR)

### SR1: Follow Startup Protocol

Follow session startup protocol defined in project instructions.

### SR2: Token Checkpoints

| Consumption | Action |
|-------------|--------|
| 50% | Status check - confirm on track |
| 65% | Begin wrap-up, take user guidance |
| 75% | **STOP** - Create handoff, await confirmation |

- Add checkpoints explicitly to the Tasklist. Prompt user to run `/context` at each checkpoint
- Do NOT proceed to the next step until user confirms token usage

### SR3: Token Estimation

| Task Type | Tokens | Strategy |
|-----------|--------|----------|
| Atomic skill | 15-25K | Single session |
| Composite skill / Agent | 25-40K | May span sessions |
| Research / Multi-file | 40-60K | Split into sub-tasks |

**If estimated > 50% budget**: Split task before starting.

### SR4: Session Handoff

When the user requests or confirms session end or session handoff, load the session-handoff skill and follow the instructions to begin session handoff. Update `plans/tasks.yaml` with current task status before completing the handoff.

### SR5: Commit Changes

Commit all session changes to git before ending the session. Ask user whether to push to remote.

---

**These rules are non-negotiable. Violations waste time and tokens.**
