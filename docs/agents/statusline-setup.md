# statusline-setup

Configures the user's Claude Code statusline by updating `settings.json` files. Handles config file placement at either project or user scope while preserving all other settings.

## Model

Haiku.

## Invocation guidance

**Tier 3: Skill-only.** Not user-invocable directly. The agent is launched by the [bulwark-statusline](../skills/bulwark-statusline.md) skill via the `Task` tool, with the chosen statusline script path passed in the prompt context.

**Via parent skill:**

```
/the-bulwark:bulwark-statusline
```

## What it does

The agent reads the target `settings.json` (project-level at `.claude/settings.json` or user-level at `~/.claude/settings.json`, depending on the chosen scope), checks whether a `statusLine` block already exists, and either adds a new block or updates the existing one. All other settings (hooks, plugins, env vars, permissions) are preserved untouched.

If a `statusLine` block already exists, the agent reports the current configuration and defers to the orchestrating skill on whether to overwrite. This avoids surprising users who have hand-tuned their statusline.

## Output

| File | Contents |
|------|----------|
| Target `settings.json` | Updated with new `statusLine` block at top level; all other keys preserved |
| Stdout | Structured report: previous statusline (if any), new statusline applied, settings file path |

## Why a separate agent?

The statusline configuration touches `settings.json` — a file that also holds hooks, MCP server registrations, environment variables, and permission settings. Isolating the edit into a single-purpose sub-agent keeps the surface area for accidental mutations small. The agent has only `Read` and `Edit` tools — it cannot run commands, fetch external resources, or write new files. This is a deliberate blast-radius limit for an asset that controls so much of Claude Code's behavior.
