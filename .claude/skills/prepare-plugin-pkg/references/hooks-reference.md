# Hooks Reference

Authoritative reference for Claude Code hook event types, timeout units, script path
conventions, $CLAUDE_PLUGIN_ROOT usage, and PostToolUse matcher syntax.

---

## CRITICAL: Timeout Values Are in SECONDS

**Timeout values in hooks.json are in SECONDS, not milliseconds.**

This is the most common and most damaging mistake in plugin development.

| Value | Interpretation | Is this what you want? |
|-------|---------------|------------------------|
| `30` | 30 seconds | Yes — typical hook timeout |
| `60` | 60 seconds | Yes — long-running hook |
| `60000` | 16.7 hours | NO — likely meant 60 seconds |
| `30000` | 8.3 hours | NO — likely meant 30 seconds |
| `5000` | 1.4 hours | NO — likely meant 5 seconds |

**Rule of thumb:** If your timeout value is >= 1000, it is almost certainly wrong.

**Acceptable range:** 5-120 seconds. Anything above 120 seconds should be questioned.

---

## Valid Hook Event Types

| Event Type | Fires When | Common Use |
|------------|-----------|------------|
| `SessionStart` | Claude Code session begins | Load project context, run setup checks |
| `PostToolUse` | After any tool call completes | Quality gates, logging, enforcement |
| `SubagentStart` | Sub-agent is spawned | Audit trail, context injection |
| `SubagentStop` | Sub-agent completes | Result logging, quality review |
| `PreCompact` | Before context compaction | Save state, write summaries |

**Note:** `PreToolUse` is not a supported event type. Use `PostToolUse` instead.
Tool-level interception before execution is not available via hooks.

---

## hooks.json Structure

```json
{
  "hooks": [
    {
      "event": "SessionStart",
      "script": "scripts/on-session-start.sh",
      "timeout": 30
    },
    {
      "event": "PostToolUse",
      "matcher": {
        "tool": "Write"
      },
      "script": "scripts/on-write.sh",
      "timeout": 60
    }
  ]
}
```

### Required Fields Per Hook Entry

| Field | Type | Notes |
|-------|------|-------|
| `event` | string | Must be a valid event type (see table above) |
| `script` | string | Path to script, relative to plugin root or using $CLAUDE_PLUGIN_ROOT |

### Optional Fields Per Hook Entry

| Field | Type | Notes |
|-------|------|-------|
| `timeout` | integer | Seconds. Default varies by event type. |
| `matcher` | object | PostToolUse only. Filters which tool calls trigger the hook. |

---

## $CLAUDE_PLUGIN_ROOT

Use `$CLAUDE_PLUGIN_ROOT` in hook scripts to reference files within the plugin
directory. This variable is set by Claude Code to the plugin's installation path.

**Correct — portable across machines:**
```bash
#!/bin/bash
source "$CLAUDE_PLUGIN_ROOT/scripts/lib/common.sh"
```

**Incorrect — hardcoded path (breaks on other users' machines):**
```bash
#!/bin/bash
source "/home/myuser/projects/my-plugin/scripts/lib/common.sh"
```

**Incorrect — relative path (breaks depending on working directory):**
```bash
#!/bin/bash
source "./scripts/lib/common.sh"
```

---

## PostToolUse Matcher Syntax

Matchers filter which tool calls trigger a PostToolUse hook. Without a matcher,
the hook fires on ALL tool calls.

Match by tool name: `{ "tool": "Write" }`
Match multiple tools: `{ "tool": ["Write", "Edit"] }`
No matcher: omit the `matcher` field entirely (hook fires on all tool calls).

**Supported tool names:** Write, Edit, Read, Bash, Glob, Grep, Task, WebFetch, WebSearch.

---

## Script Requirements

Hook scripts must be:
1. **Executable** — `chmod +x scripts/my-hook.sh` (or equivalent)
2. **Portable** — No machine-specific paths; use $CLAUDE_PLUGIN_ROOT
3. **Fast** — Complete within the timeout; long-running scripts block the session
4. **Exit-code aware** — Exit 0 for success; exit 2 to show stderr to Claude (non-blocking)

### Exit Code Behavior

| Exit Code | Effect |
|-----------|--------|
| `0` | Success, Claude continues normally |
| `1` | Error logged, Claude continues (hook failure is non-fatal) |
| `2` | Stderr content shown to Claude (informational, non-blocking — tool already ran) |

**Note:** PostToolUse hooks cannot block tool execution. The tool has already run by
the time PostToolUse fires. Exit code 2 shows a message to Claude but cannot undo
the tool's action.

---

## Hook Execution Environment

Variables available to hook scripts at runtime:

| Variable | Value |
|----------|-------|
| `$CLAUDE_PLUGIN_ROOT` | Absolute path to plugin installation directory |
| `$CLAUDE_PROJECT_DIR` | Absolute path to the user's current project |
| `$CLAUDE_TOOL_NAME` | Name of the tool that fired (PostToolUse only) |
| `$CLAUDE_SESSION_ID` | Unique session identifier |
