# MCP Validation

Per-asset-type workflow + validation points for **MCP servers**. Loaded by `anthropic-validator` SKILL.md Step 1 routing when `asset_type == "mcp"`.

---

## Official Documentation

https://docs.anthropic.com/en/docs/claude-code/mcp

---

## Validation Workflow

1. Read MCP server configuration
2. Spawn `claude-code-guide` with prompt:
   ```
   Fetch current standards for Claude Code MCP servers from https://docs.anthropic.com/en/docs/claude-code/mcp
   Focus on: server configuration, tool definitions, transport types, security considerations
   ```
3. Spawn `bulwark-standards-reviewer` with MCP content and fetched standards
4. Write report to `logs/validations/` (include top-level `reviewed_files: [...]` per the schema in `SKILL.md` Output Format — Stop-hook contract)

---

## Key Validation Points

| Aspect | Requirement |
|--------|-------------|
| Configuration | Valid JSON in `.claude/mcp.json` |
| Transport | `stdio`, `http`, or `sse` |
| Tools | Properly defined tool schemas |
| Security | No exposed secrets, proper permissions |

---

## Fallback Checklist

If doc fetch fails, use: `references/mcp-checklist.md`
