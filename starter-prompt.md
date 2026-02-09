# The Bulwark - Starter Prompt

You are building The Bulwark - a development workflow enforcement plugin that transforms stochastic AI output into deterministic, engineering-grade artifacts.

## Your Role

You operate in two modes — Implementer and Orchestrator — as defined in the Project Rules in CLAUDE.md.

Follow Rules.md without exception.

## Session Startup Sequence

Execute these steps in order:

1. **Read** `CLAUDE.md` - Project guide, architecture, binding contract
2. **Read** `Rules.md` - Immutable rules (**MUST follow**)
3. **Check** `plans/tasks.yaml` - Current phase and task status (source of truth)
4. **Check** `sessions/` - Latest session handoff document
5. **Load** task implementation plan from `plans/task-briefs/` (if exists)
6. **If no implementation plan exists** - Create one before implementation

After reading, crystallize:
- Current phase and task ID
- What was accomplished last session
- What needs to be done next
- Any blockers carried forward

### Present to User

Outline in a single-column table and **wait for explicit confirmation**:
- Current phase and task ID
- Sub-tasks from implementation plan
- Token checkpoints (per Rules.md rubric)

Do NOT start work until user confirms.

---

## Token Checkpoints

| Consumption | Action |
|-------------|--------|
| 50% | Status check - confirm on track, discuss blockers |
| 65% | Begin wrap-up - complete current sub-task, no new major work |
| 75% | **STOP** - Await user confirmation before handoff |

At each checkpoint, prompt user: "Please run `/context` and share token consumption."

See Rules.md for token complexity estimation rubric.

---

## Task Tracking

### Planning vs. Session Tracking

| Purpose | Tool | Scope |
|---------|------|-------|
| **Planning** | `plans/tasks.yaml` | Cross-session, version-controlled, source of truth |
| **Session work** | `/tasks` | In-session progress, background task coordination |

### Using /tasks for Execution Tracking

Claude Code's built-in task system complements `tasks.yaml` for tracking execution:

- **TaskCreate** - Break down current task into sub-tasks
- **TaskUpdate** - Mark progress (pending → in_progress → completed)
- **TaskList** - View current tasks

**Persistence:** Set `CLAUDE_CODE_TASK_LIST_ID=the-bulwark` to persist tasks across sessions. This allows multi-session work to maintain sub-task breakdown.

**Relationship with tasks.yaml:**
- `tasks.yaml` defines WHAT to do (phases, tasks, acceptance criteria)
- `/tasks` tracks HOW it's progressing (sub-tasks, completion status)
- At session close: update `tasks.yaml` status; `/tasks` carries forward if work continues

---

## Session Closing Sequence

Before ending any session:

### 1. Session Handoff

Load and follow the `session-handoff` skill to understand the session handoff protocol.

Create handoff at: `sessions/session_{N}_{YYYYMMDD}.md`

### 2. Update tasks.yaml

```yaml
current_phase: P{X}
current_task: P{X}.{Y}

# Update task status
- id: P{X}.{Y}
  status: completed  # or in_progress, blocked
```

### 3. Git Commit

Commit session changes:
```bash
git add -A
git commit -m "Session {N}: {Brief summary}"
```

Ask user: "Push to remote? [Yes / No - I'll push manually]"

### 4. Confirm Closure

```
Session handoff: sessions/session_{N}_{YYYYMMDD}.md
tasks.yaml: updated
Git: committed (push status)

Ready to end session.
```

---

## Quick Reference

| Checkpoint | Action |
|------------|--------|
| Session start | CLAUDE.md → Rules.md → tasks.yaml → handoff → task-brief |
| During work | Use `/tasks` for sub-task tracking |
| 50% tokens | Status check, confirm on track |
| 65% tokens | Wrap-up, no new major work |
| 75% tokens | **STOP**, await user confirmation |
| Session end | Handoff skill → tasks.yaml → git commit → confirm |

---

See `CLAUDE.md` for emergency procedures and binding contract.
