# Plugins Validation Checklist (Fallback)

This checklist is used when dynamic documentation fetch fails. May be outdated - prefer fetched standards.

**Last Updated**: 2026-04-30 (S112 — corrected false-positive checks for skills/agents arrays + npm-metadata fields per https://code.claude.com/docs/en/plugins)

---

## Plugin Structure

Plugins package skills, agents, and hooks for distribution.

### Required Structure

```
plugin-name/
├── .claude-plugin/
│   └── plugin.json          # Manifest (ONLY file in .claude-plugin/)
├── agents/                  # At root, NOT in .claude-plugin/
│   └── *.md
├── skills/                  # At root, NOT in .claude-plugin/
│   └── skill-name/
│       └── SKILL.md
└── hooks/                   # At root, NOT in .claude-plugin/
    └── hooks.json
```

### Critical Rule

All component directories (`agents/`, `skills/`, `hooks/`) MUST be at plugin root, NOT inside `.claude-plugin/`.

---

## Plugin Manifest

### Location

`.claude-plugin/plugin.json`

### Format

**Required fields**: `name`, `description`. **Optional**: `version`, `author`.

```json
{
  "name": "plugin-name",
  "description": "What this plugin provides",
  "version": "1.0.0",
  "author": { "name": "Your Name" }
}
```

**Auto-discovery is canonical**: Skills are auto-discovered from `skills/` and agents from `agents/`. The manifest does NOT need to enumerate them. If you DO add `skills:` / `agents:` arrays, they must match filesystem reality, but their absence is the standard pattern.

**Additive metadata is permitted**: `homepage`, `repository`, `license`, `keywords` are accepted as npm + marketplace fields. The Anthropic loader ignores them; do not flag as violations.

---

## Critical Rules

- [ ] `.claude-plugin/plugin.json` exists
- [ ] Manifest JSON is valid
- [ ] `name` field present and valid
- [ ] `description` field present
- [ ] Component directories at root (not in .claude-plugin/)

## High Priority

- [ ] `version` follows semver (when present — optional)
- [ ] `description` explains plugin purpose
- [ ] If `skills:` array IS present, every entry matches a real directory under `skills/`
- [ ] If `agents:` array IS present, every entry matches a real file under `agents/`
- [ ] Skills follow flat directory structure (one level)

## Medium Priority

- [ ] README.md documents usage
- [ ] License file present
- [ ] Consistent naming

## Low Priority

- [ ] Example configurations
- [ ] Changelog maintained
- [ ] Contributing guidelines

---

## Skills Directory Structure

### Flat Structure (Required)

```
skills/
├── skill-one/
│   └── SKILL.md
├── skill-two/
│   ├── SKILL.md
│   └── references/
└── skill-three/
    └── SKILL.md
```

### Invalid Structure

```
skills/
├── atomic/              # NO nested categories
│   └── skill-one/
└── composite/           # NO nested categories
    └── skill-two/
```

---

## Common Violations

| Violation | Severity | Remediation |
|-----------|----------|-------------|
| Missing plugin.json | Critical | Create `.claude-plugin/plugin.json` |
| Invalid JSON | Critical | Fix JSON syntax |
| Missing `name` or `description` | Critical | Add the required field |
| Components in .claude-plugin/ | Critical | Move to root level |
| Nested skills structure | High | Flatten to single level |
| `skills:` array entry not on filesystem | High | Remove the dangling entry or add the directory (drift) |
| `agents:` array entry not on filesystem | High | Remove the dangling entry or add the file (drift) |

**NOT violations** (do not emit findings against these — see Allowlist in `plugins-validation.md`):

- `plugin.json` without `skills:` or `agents:` arrays — auto-discovery is canonical.
- `homepage` / `repository` / `license` / `keywords` fields — additive npm/marketplace metadata, not non-spec.

---

## Installation

Plugins can be installed via:

1. Local path: `claude plugins add /path/to/plugin`
2. Git repository: `claude plugins add https://github.com/org/plugin`
3. npm package: `claude plugins add @org/plugin`

---

## Environment Variables

Plugins have access to:

| Variable | Description |
|----------|-------------|
| `$CLAUDE_PLUGIN_ROOT` | Absolute path to plugin directory |
| `$CLAUDE_PROJECT_DIR` | Absolute path to project directory |

Use these in hooks and scripts for portable paths.
