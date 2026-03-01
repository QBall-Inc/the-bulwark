# Distribution Checklist Reference

Authoritative reference for distribution requirements across npm and self-hosted marketplace
channels. Covers required fields, version consistency rules, and the first-run restart
requirement that must be documented for all installations.

---

## First-Run Restart Requirement (CRITICAL to Document)

**Claude Code hooks do not activate until the user restarts Claude Code after installation.**

This is a known framework behavior. It is not a bug — it is how hook registration works.
If this is not documented, users will install your plugin and assume it is broken.

**Where to document it:**
1. In your README or install instructions: "After installing, restart Claude Code for hooks to activate."
2. In post-install output from your init script: `echo "Installation complete. Please restart Claude Code to activate hooks."`

Both locations are recommended. At minimum, one is required.

---

## npm Distribution

Use npm when your plugin should be installable via `npm install -g` or surfaced in
the npm registry. Plugins distributed via npm require a `package.json`.

### Required package.json Fields

| Field | Requirement | Notes |
|-------|-------------|-------|
| `name` | Must match plugin.json `name` exactly | Case-sensitive; use same kebab-case |
| `version` | Must match plugin.json `version` exactly | Semver X.Y.Z |
| `description` | Non-empty string | Used in npm search results |
| `files` | Array of directories/files to include | Controls what ships in the package |

### Recommended package.json Fields

| Field | Recommendation | Notes |
|-------|----------------|-------|
| `keywords` | Include `"claude-code"` and `"claude-plugin"` | Improves discoverability |
| `license` | SPDX identifier (e.g., `"MIT"`) | Required for public npm packages |
| `repository` | URL to source repo | Helps users find source and report issues |
| `engines` | `{ "node": ">=18" }` if scripts require Node | Prevents install on incompatible environments |

### package.json `files` Field

The `files` field controls what is included in the npm package. Be explicit — do not
ship internal directories.

**Correct:**
```json
"files": [
  "skills/",
  "agents/",
  "scripts/",
  "hooks.json",
  "plugin.json",
  "init.sh"
]
```

**Incorrect — ships internal directories:**
```json
"files": [
  "."
]
```

**Directories to EXCLUDE from `files`:**
- `.claude/` — internal development directory
- `logs/` — internal audit/debug output
- `tmp/` — temporary working files
- `plans/` — internal planning documents
- `sessions/` — internal session handoffs
- `test/` or `tests/` — test harness (unless your plugin ships test utilities)

---

## Self-Hosted Marketplace

Self-hosted marketplaces allow distribution outside the official Claude Code marketplace.
They require a `marketplace.json` file describing the plugin for the catalog.

### marketplace.json Structure

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "Short description visible in marketplace listing.",
  "author": "Your Name or Org",
  "homepage": "https://github.com/yourorg/my-plugin",
  "install": {
    "type": "npm",
    "package": "my-plugin"
  },
  "tags": ["workflow", "quality", "claude-code"],
  "minClaudeCodeVersion": "1.0.0",
  "screenshots": []
}
```

### Required marketplace.json Fields

| Field | Notes |
|-------|-------|
| `name` | Must match plugin.json `name` |
| `version` | Must match plugin.json `version` |
| `description` | Marketplace listing text; keep under 200 chars |
| `install.type` | Distribution method: `"npm"`, `"git"`, or `"local"` |

---

## Official Marketplace Submission

The Claude Code official marketplace has additional requirements beyond plugin.json:

- Version must NOT have pre-release labels (`-alpha`, `-beta`, `-rc`) for stable listing
- Description must be 10-200 characters
- At least one skill or agent must be included
- All hook script paths must be valid
- Plugin must pass the marketplace validator (separate tooling)

Contact Anthropic for official marketplace submission access.

---

## Version Consistency

Before every release, confirm these three version strings are identical:

| Location | Field | Example |
|----------|-------|---------|
| `plugin.json` | `version` | `"1.2.0"` |
| `package.json` | `version` | `"1.2.0"` |
| CHANGELOG (top entry) | Header | `## [1.2.0] - 2026-03-01` |

A mismatch between any two of these is a CRITICAL distribution error. Users who
install via npm will get the package.json version; the plugin.json they receive must
match, or Claude Code may report a version inconsistency warning.

---

## Pre-Release Checklist Summary

Work through these before tagging a release:

- [ ] plugin.json version updated and valid semver
- [ ] package.json version matches plugin.json (if npm)
- [ ] marketplace.json version matches plugin.json (if self-hosted)
- [ ] CHANGELOG updated with release date
- [ ] All SKILL.md files in `skills/` (not `.claude/skills/`)
- [ ] All agent .md files in `agents/` (not `.claude/agents/`)
- [ ] package.json `files` excludes `.claude/`, `logs/`, `tmp/`
- [ ] First-run restart requirement documented
- [ ] hooks.json timeout values are in seconds (not milliseconds)
- [ ] All hook scripts are executable
