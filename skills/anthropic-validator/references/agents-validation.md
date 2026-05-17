# Agents Validation

Per-asset-type workflow + validation points for **agents** (`.claude/agents/*.md` files). Loaded by `anthropic-validator` SKILL.md Step 1 routing when `asset_type == "agent"`.

---

## Official Documentation

https://docs.anthropic.com/en/docs/claude-code/sub-agents

---

## Validation Workflow

1. Read the agent markdown file
2. Spawn `claude-code-guide` with prompt:
   ```
   Fetch current standards for Claude Code custom sub-agents from https://docs.anthropic.com/en/docs/claude-code/sub-agents
   Focus on: agent definition format, frontmatter fields, model selection, tools array, lookup priority
   ```
3. Spawn `bulwark-standards-reviewer` with agent content and fetched standards
4. Write report to `logs/validations/` (include top-level `reviewed_files: [...]` per the schema in `SKILL.md` Output Format — Stop-hook contract)

---

## Key Validation Points

### Anthropic-Official Fields (16 total — Last verified 2026-05-03)

| Field | Type | Requirement | Notes |
|-------|------|-------------|-------|
| `name` | string | **Required** | Lowercase + hyphens; matches filename |
| `description` | string | **Required** | Guides automatic delegation; include "Use proactively after X" hints in description text |
| `tools` | array | Optional | Allowlist of tools the agent may use; supports `Agent(name)` syntax for sub-agent delegation. **Canonical tool field for AGENTS** (NOT `allowed-tools`; that field is for SKILLS) |
| `disallowedTools` | array | Optional | Denylist; applied **before** `tools` resolution. A tool listed in both is removed |
| `model` | string | Optional | `haiku`, `sonnet`, `opus`, full model ID, or `inherit` (default) |
| `permissionMode` | string | Optional | `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`. **Ignored in plugin agents** |
| `skills` | array | Optional | Skills to inject into agent context at startup. Full content loaded (not just available for invocation). **IS Anthropic-official for AGENTS** (vs Bulwark-adopted for SKILLS) |
| `mcpServers` | array/object | Optional | Inline MCP server definitions or references. **NOT supported in plugin agents** |
| `hooks` | object | Optional | Lifecycle hooks (PreToolUse, PostToolUse, Stop). `Stop` auto-converts to `SubagentStop` at runtime. **NOT supported in plugin agents** |
| `maxTurns` | integer | Optional | Maximum agentic turns before stop |
| `memory` | string | Optional | `user`, `project`, or `local` scope for persistent memory across conversations |
| `background` | boolean | Optional | Run as background task (default: false). Ignored in fork mode. Pre-approves required permissions; auto-denies anything not pre-approved |
| `effort` | string | Optional | Override session effort: `low`, `medium`, `high`, `xhigh`, `max` |
| `isolation` | string | Optional | Set to `worktree` for isolated git worktree copy (auto-cleaned if no changes made) |
| `color` | string | Optional | Display color: `red`, `blue`, `green`, `yellow`, `purple`, `orange`, `pink`, `cyan` |
| `initialPrompt` | string | Optional | Auto-submitted first turn when agent runs as main session via `--agent` flag or `agent` setting |

**Sources**: https://docs.anthropic.com/en/docs/claude-code/sub-agents (canonical) / https://code.claude.com/docs/en/sub-agents.

**Important — `tools` vs `allowed-tools`**:
- For **agents** (`.claude/agents/*.md`, `agents/*.md`): the official field is `tools`. Do NOT flag `tools:` in agent frontmatter.
- For **skills** (`SKILL.md`): the official field is `allowed-tools`. `tools:` in SKILL.md is **not** official and should be flagged as `unknown` (HIGH violation).

**Important — Fields that are NOT in the official agent spec**:
- `user-invocable` — NOT supported for agents. Anthropic has no first-class user-vs-internal distinction for agents; scope location controls discoverability. **Flag as HIGH `unknown` field**.
- `proactively` — NOT supported. Use `description` wording ("Use proactively after X") to influence auto-delegation. **Flag as HIGH `unknown` field**.

**Plugin agent restrictions**: `hooks`, `mcpServers`, and `permissionMode` are silently ignored when an agent ships in a plugin. If the agent depends on these, it must live in `.claude/agents/` (project) or `~/.claude/agents/` (user) instead.

### Bulwark-Adopted Fields (informational notes, not violations)

| Field | Notes |
|-------|-------|
| `version` | Semver string. Defaults to `1.0.0` for new agents. |
| `author` | Attribution string. Uniform `"Ashay Kubal @ Qball Inc."` for first-party Bulwark assets. |

See "Bulwark-Adopted Fields Allowlist" section in main SKILL.md for full classification rules.

---

## Agent Lookup Priority

1. CLI flag (`--agent`)
2. `.claude/agents/` (project)
3. `~/.claude/agents/` (user)
4. Plugin `agents/` directory
5. Built-in agents

---

## Version & Deprecation Notes

- **v2.1.63**: `Task(...)` renamed to `Agent(...)`. `Task(...)` references still work as aliases but deprecated. New documentation should use `Agent(...)`.

---

## Fallback Checklist

If doc fetch fails, use: `references/agents-checklist.md`
