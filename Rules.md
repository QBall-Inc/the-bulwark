## Grounding Clause (GC)
Validate all new Claude Code assets (hooks, skills, agents, plugins, commands, MCP servers) using the `/anthropic-validator` skill.

## Coding Standards (CS)

### CS1: Atomic Principles
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

## Testing Rules (T)

### T1: Never Mock the System Under Test

### T2: Verify Observable Output
Tests verify **results**, not that functions were called.

### T3: Integration Tests Use Real Systems
- No mocking at integration boundaries
- Test Harness to validate real system behavior. If not possible to set up test harness, say: "I cannot set up a test harness to validate real system behavior for these tests. Please run these tests manually and confirm."

### T4: Run Tests Before Declaring Complete
Write tests WITH implementation, not after. Run them, check output, verify they catch failures.

## Verification Rules (V)

### V1: Never declare a fix complete without verification
If you cannot verify, say: "I've made changes but cannot verify without running [command]. Please run and confirm."

### V2: Use `just` for all Execution
- `just` for all execution, not npm/npx directly
- If recipe does not exist, create one before execution

### V3: Always Check Logs for Full Output
Before attempting fix, always reference full output of `just` runs from `logs/` instead of summary from stdout.

### V4: Verify Compilation After Changes
After any code edit: `just typecheck && just lint`. Do not proceed if either fails.

## Issue Debugging Rules (ID)

### ID1: Holistic Analysis before Fixing
- Understand the root cause (not just the symptom). Trace the execution path and identify all affected areas.
- Rank issue complexity based on the execution path and affected areas.
  - Low complexity: Self-contained, no affected areas.
  - Medium complexity: One or more affected areas, with one or more integration tests failing.
  - High complexity: More than 5 integration test failures.

### ID2: Fix Validation Loop
A fix is not complete until:
- Root cause documented
- Fix implemented and reviewed
- Tests pass. Tests to be run based on issue complexity:
  - Low complexity: Unit Tests
  - Medium complexity: Integration Tests + E2E Tests of affected areas
  - High complexity: All Tests
- No new issues introduced

### ID3: Document the Journey
Log debugging steps: symptoms, hypotheses tested, root cause, fix applied, verification results. Store in project-defined location.

## Task Rules (TR)

### TR1: Implementation Plan Required
Every task in tasklist should be traceable to an item in an implementation plan in plans/

### TR2: Task Identification and Dependencies
- Unique sequential identifiers for tasks in tasklist (e.g., `T-001: Rewrite Rules.md`)
- Keep IDs persistent across sessions (via `CLAUDE_CODE_TASK_LIST_ID`)
- Add blocking dependencies
- Verify dependency chain: no missing blockers, no circular dependencies, correct execution order

### TR3: Task Descriptions Are Durable
- Include enough context for future sessions to execute without additional lookup
- Completed tasks are dropped; active and pending tasks carry forward

## Orchestrator Rules (OR)

### OR1: Sub-Agent Model Selection
When spawning sub-agents for review/audit/research:

| Complexity | Model | Use Cases |
|------------|-------|-----------|
| Simple | Haiku | Quick lookups, single-file reads |
| Standard | **Sonnet** (default) | Code review, test audit, research |
| Complex | Opus | Architecture review, novel problem analysis, implementation |

### OR2: Custom Agent Model Respect
Custom sub-agents **may** specify their model in frontmatter. The Orchestrator respects this.

### OR3: Pipeline Syntax
Use F# pipe syntax for workflow orchestration. Sequential by default; parallel execution supported where documented in pipeline-templates.

## Sub-Agent Rules (SA)

### SA1: All sub-agent invocations are done by loading the subagent-prompting skill
Load subagent-prompting skill for full usage

### SA2: Sub-agent Output
All sub-agent output MUST be written using the subagent-output-templating skill. Exceptions: 
- **When a custom sub-agent definition specifies output paths and format**: The agent MUST use those exact paths and formats. No additional log files.
- **When no output path is specified in a custom sub-agent**: The agent MUST write output to `logs/{agent-name}-{timestamp}.md` as a fallback.

### SA3: Sub-agents return only summaries to main context (findings, severity, next actions). Full reasoning stays in logs.

### SA4: Pipeline Chaining
Complex workflows use F# pipe syntax for conceptual orchestration. Each agent reads previous agent's log output.

### SA5: Do not use `run_in_background: true` when spawning sub-agents. Foreground sub-agents return summaries (per SA3), full output to logs (per SA2).

### SA6: Presumed Execute
Pipeline suggestions from code-writing sub-agents are **PRESUMED EXECUTE**. 
- **Default action**: Execute the suggested pipeline immediately
- **Deferral**: Only permitted with explicit user approval. Ask the user: "Pipeline X was suggested for [files]. Execute or defer?"
- **Rule Violation**: Silent ignoring, self-rationalizing deferral (e.g., "change is small", "not warranted")

## Skill Compliance Rules (SC)

### SC1: Skill Instructions Are **Binding**, Not Advisory
- Steps marked "MANDATORY" or "REQUIRED" must be executed
- Steps must be executed **IN ORDER** unless explicitly stated otherwise
- Do NOT substitute judgment for skill instructions
- Do NOT skip steps because they seem unnecessary

### SC2: Sub-Agent Spawning Is Mandatory
When a skill specifies sub-agent spawning (e.g., `Task(subagent_type=...)`):
- You **MUST** spawn the sub-agent as instructed
- You **MUST NOT** perform the sub-agent's work yourself
- The sub-agent model selection is intentional (Refer OR1, OR2)

### SC3: Skill Execution Verification
After executing a skill:
- Verify all mandatory steps were completed
- Verify all required outputs were generated
- If any step was skipped, document why and re-attempt

## Code Navigation Rules (CN)

### CN1: Prefer LSP for Semantic Operations
When LSP is available, use it for go-to-definition, find-references, type information, symbol search, and implementation tracing. Fall back to Grep only when LSP is unavailable, returns no results, or the target is a non-code file (docs, config, logs).

### CN2: Search Tool Hierarchy

| Operation | Preference Order |
|-----------|-----------------|
| Code navigation (definitions, references, types) | LSP > Grep > Glob |
| File content search | Grep > Glob |
| File discovery | Glob |

## Session Rules (SR)

### SR1: Session Startup
Follow Startup Protocol From CLAUDE.md

### SR2: Token Checkpoints

| Consumption | Action |
|-------------|--------|
| 50% | Status check - confirm on track |
| 65% | Begin wrap-up, take user guidance |
| 75% | **STOP** - Create handoff, await confirmation |

- Add checkpoints explicitly to the tasklist at the right junctures after estimating tokens (SR3)
- Prompt user to run `/context` at each checkpoint

### SR3: Token Estimation

| Task Type | Tokens | Strategy |
|-----------|--------|----------|
| Atomic skill | 15-25K | Single session |
| Composite skill / Agent | 25-40K | May span sessions |
| Research / Multi-file | 40-60K | Split into sub-tasks |

**If estimated > 50% budget**: Split task before starting.

### SR4: Session End Protocol
- Follow Session Handoff Protocol From CLAUDE.md
- Update plan with the current status
- Commit all session changes to git before ending the session. Ask user whether to push to remote.

**These rules are non-negotiable. Violations waste time and tokens.**
