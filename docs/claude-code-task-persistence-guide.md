# Deterministic Task Management in Claude Code: A Cross-Session Guide

## Background

Claude Code introduced a built-in task management system that replaced the earlier `TodoWrite`/`TodoRead` tools. This shift, part of Claude Code 2.x releases in late 2025, brought significant improvements to how AI-assisted development sessions can track and persist work across time.

### From ToDos to Tasks

The original ToDo system had limitations:
- Session-scoped by default
- No dependency tracking
- Limited visibility into task state
- No cross-session persistence without workarounds

The new Task system addresses these with:
- **Persistent task lists** via environment variable
- **Dependency management** (blocks/blockedBy)
- **Status workflow** (pending → in_progress → completed)
- **Owner assignment** for multi-agent coordination
- **Cross-session visibility** when configured

---

## The Three-Tier Planning Model

Effective project management with Claude Code works best with a three-tier hierarchy:

```
┌─────────────────────────────────────────────────────────┐
│  TIER 1: Project Plan (Version Controlled)              │
│  plans/tasks.yaml or plans/roadmap.md                   │
│  - Phases, milestones, high-level deliverables          │
│  - Owned by humans, updated at major checkpoints        │
│  - Source of truth for "what are we building"           │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  TIER 2: Task Briefs (Version Controlled)               │
│  plans/task-briefs/feature-xyz.md                       │
│  - Implementation details for each high-level task      │
│  - Acceptance criteria, technical approach              │
│  - Created before implementation begins                 │
└─────────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────┐
│  TIER 3: Session Tasks (Persistent via Task System)     │
│  ~/.claude/tasks/{project-id}/                          │
│  - Granular sub-tasks for current work                  │
│  - Created and managed by Claude during sessions        │
│  - Persists across sessions when configured             │
└─────────────────────────────────────────────────────────┘
```

### Why Three Tiers?

| Tier | Persistence | Owner | Granularity | Purpose |
|------|-------------|-------|-------------|---------|
| Plan | Git | Human | Phases/Features | Strategic direction |
| Brief | Git | Human + AI | Tasks/Stories | Implementation spec |
| Tasks | Claude Task System | AI | Sub-tasks | Execution tracking |

---

## Setting Up Cross-Session Task Persistence

### The Key: CLAUDE_CODE_TASK_LIST_ID

By default, Claude Code creates a unique task list per session (stored with UUID). To share tasks across sessions, set the `CLAUDE_CODE_TASK_LIST_ID` environment variable **before** starting Claude Code.

```bash
# Tasks persist to ~/.claude/tasks/my-project/
CLAUDE_CODE_TASK_LIST_ID=my-project claude
```

### The Challenge: Per-Project Configuration

If you work on multiple projects, you need different task list IDs for each. Setting a global ID means all projects share one task list—not ideal.

### Solution: Project-Aware Launcher Script

Create a launcher script that auto-detects your project:

```bash
#!/bin/bash
# ~/.local/bin/claude-project

detect_project() {
  case "$PWD" in
    */my-webapp*)        echo "my-webapp" ;;
    */data-pipeline*)    echo "data-pipeline" ;;
    */mobile-app*)       echo "mobile-app" ;;
    *)                   echo "" ;;
  esac
}

PROJECT_ID=$(detect_project)

if [[ -n "$PROJECT_ID" ]]; then
  echo "Task list: $PROJECT_ID"
  export CLAUDE_CODE_TASK_LIST_ID="$PROJECT_ID"
else
  echo "No project detected - using session-based tasks"
fi

exec claude "$@"
```

### Installation

```bash
# 1. Save script to PATH
mkdir -p ~/.local/bin
# (save script as ~/.local/bin/claude-project)

# 2. Make executable
chmod +x ~/.local/bin/claude-project

# 3. Fix Windows line endings (CRITICAL for WSL users)
# Files created on Windows have CRLF endings that break bash scripts
sed -i 's/\r$//' ~/.local/bin/claude-project

# 4. Ensure PATH includes ~/.local/bin
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

> **WSL Users**: Step 3 is essential. Without it, you'll see "cannot execute: required file not found" even though the file exists. This happens because bash interprets the shebang as `#!/bin/bash\r` (with carriage return) instead of `#!/bin/bash`.

### Usage

```bash
# Navigate to project directory
cd ~/projects/my-webapp

# Launch with project-aware tasks
claude-project

# Output: "Task list: my-webapp"
# Tasks now persist to ~/.claude/tasks/my-webapp/
```

---

## Working with Tasks

### Creating Tasks

Claude can create tasks during a session:

```
TaskCreate:
  subject: "Implement user authentication"
  description: "Add JWT-based auth with refresh tokens"
  activeForm: "Implementing authentication"
```

### Task Dependencies

Tasks can block each other:

```
Task #1: Set up database schema [pending]
Task #2: Implement API endpoints [pending, blocked by #1]
Task #3: Write integration tests [pending, blocked by #2]
```

### Viewing Tasks

Use `/tasks` in Claude Code to see current task list:

```
#1 [completed] Set up database schema
#2 [in_progress] Implement API endpoints
#3 [pending] Write integration tests [blocked by #2]
```

### Cross-Session Workflow

**Session 1:**
```
You: Let's implement the user module
Claude: [Creates tasks #1, #2, #3]
Claude: [Completes #1, starts #2]
You: I need to stop for today
Claude: Task #2 is in_progress, #3 is pending
```

**Session 2 (next day):**
```bash
cd ~/projects/my-webapp
claude-project
```

```
You: What's the current status?
Claude: [Reads persistent task list]
Claude: Task #2 (API endpoints) is in_progress, #3 (tests) is pending
```

---

## Integration with Project Planning

### Example: tasks.yaml (Tier 1)

```yaml
project: my-webapp
current_phase: P2

phases:
  - id: P1
    name: Foundation
    status: completed

  - id: P2
    name: Core Features
    status: in_progress
    tasks:
      - id: P2.1
        name: User Authentication
        status: in_progress
        brief: plans/task-briefs/P2.1-authentication.md

      - id: P2.2
        name: Dashboard
        status: pending
        brief: plans/task-briefs/P2.2-dashboard.md
```

### Example: Task Brief (Tier 2)

```markdown
# P2.1: User Authentication

## Overview
Implement JWT-based authentication with refresh token rotation.

## Acceptance Criteria
- [ ] Login endpoint returns access + refresh tokens
- [ ] Protected routes validate JWT
- [ ] Refresh endpoint rotates tokens
- [ ] Logout invalidates refresh token

## Technical Approach
1. Add jsonwebtoken and bcrypt dependencies
2. Create auth middleware
3. Implement /auth/login, /auth/refresh, /auth/logout
4. Add token blacklist for logout
```

### Example: Session Tasks (Tier 3)

When working on P2.1, Claude creates granular tasks:

```
#1 [completed] Add auth dependencies to package.json
#2 [completed] Create JWT utility functions
#3 [in_progress] Implement login endpoint
#4 [pending] Implement refresh endpoint [blocked by #3]
#5 [pending] Implement logout endpoint [blocked by #4]
#6 [pending] Add auth middleware [blocked by #3]
#7 [pending] Write auth integration tests [blocked by #5, #6]
```

---

## Best Practices

### 1. Use Blocking Tasks for Coordination

When multiple sessions might access the same task list:

```
#1 [pending] WAIT: Manual testing in progress - do not proceed
#2 [pending] Fix bug in parser [blocked by #1]
#3 [pending] Update documentation [blocked by #1]
```

### 2. Keep Task Descriptions Self-Contained

Tasks may be read in a different session without full context:

```
# Bad
subject: "Fix the bug"

# Good
subject: "Fix null pointer in UserService.getProfile()"
description: "Line 142 throws when user.address is undefined. Add null check."
```

### 3. Update Tier 1 at Session Boundaries

At the end of significant sessions, sync back to version-controlled files:

```yaml
# Update tasks.yaml
- id: P2.1
  status: in_progress  # was: pending
  notes: "Login endpoint complete, refresh in progress"
```

### 4. Clear Completed Tasks Periodically

Task lists can accumulate. Periodically clear completed items or archive them.

---

## Troubleshooting

### Tasks Not Persisting

1. Verify environment variable is set **before** Claude starts:
   ```bash
   echo $CLAUDE_CODE_TASK_LIST_ID  # Should show project name
   ```

2. Check task storage location:
   ```bash
   ls ~/.claude/tasks/
   # Should show your project name, not just UUIDs
   ```

### "Command not found" for claude-project

1. Ensure script is in PATH
2. Ensure script is executable: `chmod +x ~/.local/bin/claude-project`
3. On WSL, fix line endings: `sed -i 's/\r$//' ~/.local/bin/claude-project`

### Tasks Showing in Wrong Project

Check your `detect_project()` patterns. More specific patterns should come first:

```bash
# Order matters - more specific first
*/my-webapp-api*)    echo "my-webapp-api" ;;
*/my-webapp*)        echo "my-webapp" ;;
```

---

## Summary

| Component | Location | Persistence | Purpose |
|-----------|----------|-------------|---------|
| Project Plan | `plans/tasks.yaml` | Git | Strategic roadmap |
| Task Briefs | `plans/task-briefs/` | Git | Implementation specs |
| Session Tasks | `~/.claude/tasks/{id}/` | Claude Task System | Execution tracking |
| Launcher | `~/.local/bin/claude-project` | Local | Auto-detect project |

The combination of version-controlled planning documents and Claude's persistent task system creates a robust workflow for complex, multi-session projects. The key is setting `CLAUDE_CODE_TASK_LIST_ID` before launching Claude Code—and the project-aware launcher script makes this seamless.
