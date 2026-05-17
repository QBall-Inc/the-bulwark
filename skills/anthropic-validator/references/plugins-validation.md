# Plugins Validation

Per-asset-type workflow + validation points for **plugins**. Loaded by `anthropic-validator` SKILL.md Step 1 routing when `asset_type == "plugin"`.

---

## Official Documentation

https://docs.anthropic.com/en/docs/claude-code/plugins

---

## Validation Workflow

1. Read plugin manifest and structure
2. Spawn `claude-code-guide` with prompt:
   ```
   Fetch current standards for Claude Code plugins from https://code.claude.com/docs/en/plugins
   Focus on: plugin.json manifest schema (required vs optional fields), directory structure, auto-discovery semantics
   ```
3. Spawn `bulwark-standards-reviewer` with plugin content and fetched standards. **Apply the allowlist below before emitting findings — do NOT flag allowlisted patterns as violations.**
4. Write report to `logs/validations/` (include top-level `reviewed_files: [...]` per the schema in `SKILL.md` Output Format — Stop-hook contract)

---

## Key Validation Points

| Aspect | Requirement |
|--------|-------------|
| Manifest | `.claude-plugin/plugin.json` exists and is valid JSON |
| Required fields | `name`, `description` |
| Optional fields | `version`, `author` |
| Structure | Flat directories at root (`skills/`, `agents/`, `hooks/`) |
| Component registration | **Auto-discovery from `skills/` and `agents/` directories is canonical.** plugin.json is NOT required to enumerate skills/agents in arrays. |
| Naming | Plugin name matches directory |

---

## Allowlist (do NOT flag as violations)

The following patterns appear in production Bulwark plugin configurations and are explicitly permitted by the Anthropic plugin spec or are additive-and-harmless. The validator MUST NOT emit findings against these:

| Pattern | Why it's allowed |
|---------|------------------|
| `plugin.json` without `skills:` array | Auto-discovery from `skills/` directory is the documented standard. Per https://code.claude.com/docs/en/plugins: "Skills and commands are automatically discovered when the plugin is installed." |
| `plugin.json` without `agents:` array | Same as above for `agents/` directory. |
| `homepage`, `repository`, `license`, `keywords` in `plugin.json` | Additive npm + marketplace metadata. Anthropic loader ignores them; they enable npm package discovery and plugin-marketplace listing. Do not flag as non-spec. |

If the plugin DOES include `skills:` or `agents:` arrays, validate that array entries match filesystem reality (drift = High). If the arrays are absent, do not synthesize a "missing" finding — absence is the canonical case.

---

## Directory Structure

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # ONLY manifest here
├── agents/                  # At root, NOT in .claude-plugin/
├── skills/                  # At root, NOT in .claude-plugin/
└── hooks/                   # At root, NOT in .claude-plugin/
```

---

## Fallback Checklist

If doc fetch fails, use: `references/plugins-checklist.md`
