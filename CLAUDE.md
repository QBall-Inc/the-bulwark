# Project: The Bulwark 

You are building The Bulwark, a SDLC workflow enforcement plugin that transforms stochastic AI output into deterministic, engineering-grade artifacts.

## Binding Contract

All work in this project is governed by @Rules.md. Compliance is mandatory and non-negotiable. Failure to follow any rule in Rules.md is a contract violation.

| Commitment | Requirement |
|------------|-------------|
| Rules Adherence | 100% compliance with Rules.md at all times |
| Reporting & Logging | All sub-agent outputs written to logs, all decisions documented |
| Coding Standards | Every implementation follows atomic principles and Anthropic guidelines |
| Testability | All code must be testable with real behavior verification |
| Real-World Testing | No mock-only tests for integration points |
| Verification Before Completion | No fix or feature declared complete without verification |
| Anthropic Compliance | All hooks, agents, skills, and plugins match official Anthropic guidelines |

## Modes of Operation

Throughout the session, you will operate in one of two modes:

- **Implementer Mode:** Primary model directly implements all deliverables
- **Orchestrator Mode:** Primary model orchestrates sub-agents or agent teams for research/review/edit/focused implementations (OR1-OR3, SA1-SA6)

## Project Assets

| Asset | Location | Purpose |
|-------|----------|---------|
| Active Tasks | `plans/active_tasks.yaml` | Current task board — active/pending work with full acceptance criteria |
| Completed Tasks | `plans/tasks_completed.yaml` | Archive of completed phases and tasks |
| Task Briefs | `plans/task-briefs/` | Implementation plans for individual workpackages |
| Master Plan | `plans/the-bulwark-plan.md` | Overall project plan and architecture |
| Sessions | `sessions/` | Session handoff documents for context continuity |
| Skills | `skills/` | Plugin skills (production) |
| Agents | `agents/` | Plugin agents (production) |
| Dev Skills | `.claude/skills/` | Dogfood copies + dev-only skills (humanizer) |
| Dev Agents | `.claude/agents/` | Dev-only agents (markdown-reviewer, test agents) |
| Scripts | `scripts/` | Build, init, hooks, and utility scripts |
| Hooks | `hooks/hooks.json` | Plugin hook definitions |
| Templates | `lib/templates/` | Rules.md, CLAUDE.md, Justfile, statusline templates |

## Session Startup Sequence

- Load @Rules.md
- Read previous session's handoff and process the tasks in scope for this session / this session's priorities
- Grep `plans/active_tasks.yaml` for `current_task` and `status: in_progress` to identify active tasks. **Do NOT read the entire file** — only read the specific task sections relevant to this session's scope.
- If you need the task brief for the active task, read the `implementation_plan` path from the task entry.
- Read the tasklist (TaskList tool)
- Outline the session plan to the user and ask for confirmation to begin

## In-Session Protocol

- The Bulwark governance protocol and Rules.md dictate in-session governance and need to be followed without exception to ensure quality output
- **Always** prioritize **quality**, **accuracy** and **completeness** of the task at hand over speed

## Session End Sequence

- Once the user requests or confirms a session handoff, load the `session-handoff` skill and follow its instructions
- Ensure CRLF characters are removed from the session handoff (Use LF/Unix line endings only)
- Update plan/tasks file with latest status, close out completed tasks from the tasklist
- Commit session changes with appropriate comments

```bash
git add -A
git commit -m "Session {N}: {Brief summary}"
```
- Present a summary of the session to the user, outlining the priorities for the next session
- Confirm closure of the session

```
Session handoff: sessions/session_{N}_{YYYYMMDD}.md
active_tasks.yaml: updated
Git: committed (push status)

Ready to end session.
```

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
