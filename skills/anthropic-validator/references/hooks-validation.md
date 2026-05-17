# Hooks Validation

Per-asset-type workflow + validation points for **hooks** (`hooks.json` files). Loaded by `anthropic-validator` SKILL.md Step 1 routing when `asset_type == "hooks"`.

---

## Official Documentation

https://docs.anthropic.com/en/docs/claude-code/hooks

---

## Validation Workflow

1. Read the hooks configuration file
2. Spawn `claude-code-guide` with prompt:
   ```
   Fetch current standards for Claude Code hooks from https://docs.anthropic.com/en/docs/claude-code/hooks
   Focus on: hook types, matcher patterns, once field, command format, environment variables
   ```
3. Spawn `bulwark-standards-reviewer` with hooks content and fetched standards
4. Write report to `logs/validations/` (include top-level `reviewed_files: [...]` per the schema in `SKILL.md` Output Format — Stop-hook contract)

---

## Key Validation Points

### Supported Hook Events

| Event | Supports `matcher`? | Typical Input | Typical Use Case |
|-------|---------------------|---------------|------------------|
| `PreToolUse` | Yes | tool name + input | Validation, blocking |
| `PostToolUse` | Yes | tool name + input + output | Logging, side effects, quality gates |
| `PermissionRequest` | Yes | tool name + permission scope | Permission-time validation |
| `SubagentStart` | No | subagent type + prompt | Tracking, setup |
| `SubagentStop` | No | subagent type | Finalization, cleanup |
| `Stop` | No | `stop_hook_active` flag | End-of-turn pipeline triggers (P10.1 pattern) |
| `SessionStart` | No | startup metadata | Fires on **all** session boundaries (true session start, post-compact, post-clear). Use `once: true` ONLY when the hook is genuinely one-shot. **Boundary-injection hooks (e.g., governance-protocol banner, rules injection) MUST NOT use `once: true`** — they need to re-fire on every boundary. |
| `SessionEnd` | No | session metadata | End-of-session cleanup |
| `PreCompact` | No | conversation summary | Pre-compaction validation |
| `UserPromptSubmit` | No | user prompt | Prompt-time triggers |
| `Notification` | No | notification payload | Alerts, external logging |

**Last verified**: 2026-04-26 (Session 110, P10.3) against https://docs.anthropic.com/en/docs/claude-code/hooks. Sync this table whenever Anthropic publishes new hook events or deprecates existing ones.

### Other Field Requirements

| Field | Requirement |
|-------|-------------|
| `matcher` | Regex pattern — only valid for `PreToolUse` / `PostToolUse` (and `PermissionRequest` if used). Must NOT be present for matcher-less events. |
| `command` | Shell command to execute |
| `once` | Boolean, **OPTIONAL**. `true` only when the hook should run exactly once per claude process; absence is the default and is correct for any hook that needs to fire on session boundary events (start + post-compact + post-clear). |
| `timeout` | Optional, milliseconds |

---

## Allowlist (do NOT flag as violations)

| Pattern | Why it's allowed |
|---------|------------------|
| SessionStart hook WITHOUT `once: true` | SessionStart without `once: true` fires on every session boundary (true start, post-compact, post-clear). This is the correct pattern for any hook that injects state on every boundary — e.g., governance-protocol banners, rules injection. Bulwark relies on this behavior; **do not flag absence of `once: true` as Medium/High**. |
| `hooks.json` top-level `description` field | Documentation convenience for human readers. Anthropic loader ignores it; harmless. Do not flag as non-spec. |

---

## Environment Variables

| Variable | Available In |
|----------|--------------|
| `$CLAUDE_TOOL_NAME` | PreToolUse, PostToolUse |
| `$CLAUDE_TOOL_INPUT` | PreToolUse, PostToolUse |
| `$CLAUDE_TOOL_OUTPUT` | PostToolUse |
| `$CLAUDE_SUBAGENT_TYPE` | SubagentStart, SubagentStop |
| `$CLAUDE_SUBAGENT_PROMPT` | SubagentStart |
| `$CLAUDE_PROJECT_DIR` | All hook types — project root |
| `$CLAUDE_PLUGIN_ROOT` | All hook types when running from a plugin — plugin root directory |

---

## Fallback Checklist

If doc fetch fails, use: `references/hooks-checklist.md`
