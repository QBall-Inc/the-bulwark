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

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Short description of what the plugin does.",
  "author": "Your Name or Org",
  "homepage": "https://github.com/yourorg/my-plugin",
  "skills": [
    "skills/my-skill/SKILL.md"
  ],
  "agents": [
    "agents/my-agent.md"
  ],
  "hooks": "hooks.json",
  "init": "init.sh",
  "minClaudeCodeVersion": "1.0.0"
}
```

### Required Fields

| Field | Type | Format | Notes |
|-------|------|--------|-------|
| `name` | string | kebab-case | Must be globally unique for marketplace |
| `version` | string | semver X.Y.Z | Must match package.json if npm-distributed |
| `description` | string | single line | Used in marketplace listings; keep under 120 chars |

### Recommended Fields

| Field | Type | Notes |
|-------|------|-------|
| `author` | string | Name or org for attribution |
| `homepage` | string | URL to repo or docs |
| `minClaudeCodeVersion` | string | semver; prevents install on incompatible versions |

### Optional Fields

| Field | Type | Notes |
|-------|------|-------|
| `skills` | array | Paths to SKILL.md files (relative to plugin root) |
| `agents` | array | Paths to agent .md files (relative to plugin root) |
| `hooks` | string | Path to hooks.json |
| `init` | string | Path to init script |

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

Paths in `skills` and `agents` arrays are relative to the plugin root.

- Correct: `"skills/my-skill/SKILL.md"`
- Wrong (.claude/ won't distribute): `".claude/skills/my-skill/SKILL.md"`
- Wrong (absolute path breaks portability): `"/home/user/my-plugin/skills/my-skill/SKILL.md"`

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
