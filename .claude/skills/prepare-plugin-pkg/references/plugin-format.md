# Plugin Format Reference

Authoritative reference for Claude Code plugin directory structure, plugin.json schema,
and the root vs .claude/ directory convention.

---

## Directory Structure

A Claude Code plugin uses this layout:

```
my-plugin/
  plugin.json              # Plugin manifest (REQUIRED)
  hooks.json               # Hook configuration (if hooks used)
  skills/                  # Skills shipped with the plugin
    my-skill/
      SKILL.md
      references/
      templates/
  agents/                  # Agents shipped with the plugin
    my-agent.md
  scripts/                 # Hook scripts
    on-session-start.sh
  init.sh                  # Install script (optional)
  package.json             # npm distribution manifest (if npm-distributed)
```

### Root vs .claude/ Convention

**Root directories (`skills/`, `agents/`) = distribution directories.**
These are copied to the user's `.claude/` on install and are part of the plugin's
public interface.

**`.claude/` = internal development directory.**
Used during plugin development for locally testing skills and agents. NOT included
in plugin distribution. Do NOT reference `.claude/` paths in plugin.json.

| Directory | Purpose | Ships in plugin? |
|-----------|---------|-----------------|
| `skills/` (root) | Distribution-ready skills | YES |
| `agents/` (root) | Distribution-ready agents | YES |
| `.claude/skills/` | Internal dev copies | NO |
| `.claude/agents/` | Internal dev copies | NO |
| `.claude/rules/` | Auto-loaded rules (post-install target) | NO (init installs these) |

---

## plugin.json Schema

Source: [Plugins reference](https://code.claude.com/docs/en/plugins-reference.md)

```json
{
  "name": "plugin-name",
  "version": "1.2.0",
  "description": "Brief plugin description",
  "author": {
    "name": "Author Name",
    "email": "author@example.com",
    "url": "https://github.com/author"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["keyword1", "keyword2"],
  "commands": ["./custom/commands/special.md"],
  "agents": "./custom/agents/",
  "skills": "./custom/skills/",
  "hooks": "./config/hooks.json",
  "mcpServers": "./mcp-config.json",
  "outputStyles": "./styles/",
  "lspServers": "./.lsp.json"
}
```

### Required Fields

Only `name` is required. All other fields are optional.

| Field | Type | Format | Notes |
|-------|------|--------|-------|
| `name` | string | kebab-case | Must be globally unique for marketplace. Used as skill namespace prefix. |

### Metadata Fields (Optional)

| Field | Type | Notes |
|-------|------|-------|
| `version` | string | semver X.Y.Z. Must match package.json if npm-distributed. |
| `description` | string | Shown in plugin manager |
| `author` | object | `{ name, email, url }` — use object form, not plain string |
| `homepage` | string | Documentation URL |
| `repository` | string | Source code URL |
| `license` | string | e.g. `"MIT"`, `"Apache-2.0"` |
| `keywords` | array | Discovery tags for marketplace search |

### Component Fields (Optional)

| Field | Type | Notes |
|-------|------|-------|
| `skills` | string\|array | Directory path or array of skill directory paths. Supplements default `skills/` auto-discovery. |
| `agents` | string\|array | Directory path or array of agent file paths. Supplements default `agents/` auto-discovery. |
| `hooks` | string\|array\|object | Hook config path(s) or inline config object |
| `commands` | string\|array | Additional command files/directories |
| `mcpServers` | string\|array\|object | MCP config path(s) or inline config |
| `outputStyles` | string\|array | Additional output style files/directories |
| `lspServers` | string\|array\|object | LSP server configs |

### Path Convention

All paths must be relative to the plugin root and start with `./`.

---

## Version Conventions

Use semantic versioning (semver): `MAJOR.MINOR.PATCH`

| Increment | When |
|-----------|------|
| MAJOR | Breaking changes to skill interfaces or hook contracts |
| MINOR | New skills, agents, or features (backwards compatible) |
| PATCH | Bug fixes, documentation, cosmetic changes |

Pre-release labels (`-alpha.1`, `-rc.1`) are valid semver but are rejected by some
marketplace validators. Use only for private or internal distribution.

Version MUST be identical across:
- `plugin.json` → `version`
- `package.json` → `version` (if npm-distributed)
- CHANGELOG top entry (if maintained)

---

## Skill and Agent Path Rules

Paths in `skills` and `agents` fields are relative to the plugin root and must start with `./`.

Both directory paths (string) and individual file arrays are valid:

- Correct: `"./skills/"` (directory — auto-discovers all subdirectories)
- Correct: `["./skills/my-skill/"]` (array of skill directories)
- Correct: `["./agents/my-agent.md"]` (array of agent files)
- Wrong (.claude/ won't distribute): `"./.claude/skills/my-skill/"`
- Wrong (absolute path breaks portability): `"/home/user/my-plugin/skills/"`
- Wrong (missing ./ prefix): `"skills/"` (should be `"./skills/"`)

---

## What Goes in .claude/rules/

After installation, the init script may copy rules or configuration files into the
user's `.claude/rules/` directory. Files placed here are auto-loaded by Claude Code
at session start without any additional configuration.

Common contents:
- Project conventions reference files
- Workflow rule documents
- Binding constraint documents

Do NOT place in `.claude/rules/`:
- SKILL.md files (these go in `.claude/skills/`)
- Agent .md files (these go in `.claude/agents/`)
- Hook scripts (these stay in the plugin's scripts/ directory)
