# Research: @mention Syntax in CLAUDE.md and Plugin Root Path Support

**Date**: 2026-02-28
**Task**: Determine whether `@${CLAUDE_PLUGIN_ROOT}/path/to/file.md` works in CLAUDE.md for auto-loading files from a plugin directory
**Context**: P7 launch planning — governance file (Rules.md) delivery model design fork

---

## Summary (Bottom Line Up Front)

**`@${CLAUDE_PLUGIN_ROOT}/path/to/file.md` does NOT work in CLAUDE.md.**

`${CLAUDE_PLUGIN_ROOT}` is not expanded in CLAUDE.md content. It is only expanded in JSON configuration contexts (hooks.json, .mcp.json, plugin.json). Environment variable interpolation is not supported in CLAUDE.md @-import paths at all.

This is a confirmed design constraint, not a temporary bug.

---

## Finding 1: What @mention syntax IS supported in CLAUDE.md

### Official documentation (code.claude.com/docs/en/memory)

CLAUDE.md files support `@path/to/import` syntax for importing other Markdown files. From the official documentation:

```
See @README for project overview and @package.json for available npm commands.

# Additional Instructions
- git workflow @docs/git-instructions.md
```

**Supported path types:**
- Relative paths: `@docs/rules.md` — resolves relative to the file containing the import, NOT the working directory
- Absolute paths: `@/etc/claude-code/standards.md` — full filesystem paths
- Home directory shorthand: `@~/.claude/my-project-instructions.md` — officially documented, but see caveat below

**NOT supported:**
- Environment variable interpolation: `@${SOME_VAR}/file.md` — no variable expansion in @-import paths
- Shell expressions: `@$(some-command)/file.md`
- Glob patterns: `@docs/*.md`

### Tilde path caveat (Bug #17354)

The official docs show `@~/.claude/my-project-instructions.md` as a valid worktree-sharing pattern. However, there is an open bug (#17354, marked as duplicate of #13138) where tilde expansion fails in some contexts, creating a literal `~/` directory instead of expanding to `$HOME`. This bug affects Claude Code's internal file operations; its impact on @-imports specifically is unclear from bug reports, but it represents a reliability risk.

### Recursive imports and depth limit

Imported files can recursively import additional files. Max depth: 5 hops.

### What the approval dialog covers

The first time Claude Code encounters external imports (files outside the project), it shows an approval dialog listing the specific files being imported. This is a one-time per-project decision. If declined, the dialog never resurfaces and imports remain disabled permanently for that project.

---

## Finding 2: Why `${CLAUDE_PLUGIN_ROOT}` Does Not Work in CLAUDE.md

### Where `${CLAUDE_PLUGIN_ROOT}` IS supported

`${CLAUDE_PLUGIN_ROOT}` is an environment variable injected by Claude Code that contains the absolute path to the installed plugin directory. Per the official plugins reference:

> **`${CLAUDE_PLUGIN_ROOT}`**: Contains the absolute path to your plugin directory. Use this in hooks, MCP servers, and scripts to ensure correct paths regardless of installation location.

It is explicitly supported in:
- `hooks/hooks.json` — hook `command` fields
- `.mcp.json` / `mcpServers` — command and args fields
- `plugin.json` — inline hook and MCP configurations

Example from official docs:
```json
{
  "hooks": {
    "PostToolUse": [{
      "hooks": [{
        "type": "command",
        "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-code.sh"
      }]
    }]
  }
}
```

### Where `${CLAUDE_PLUGIN_ROOT}` is NOT supported

Issue #9354 ("Fix ${CLAUDE_PLUGIN_ROOT} in command markdown OR support local project plugin installation") documents that `${CLAUDE_PLUGIN_ROOT}` **only works in JSON configurations** and **fails in command markdown files**. Status: OPEN as of November 2025.

CLAUDE.md is a Markdown file — the same category as command markdown files. There is no documentation or evidence suggesting variable interpolation works in CLAUDE.md @-import paths. The @-import mechanism is a path-based file inclusion system, not a shell-evaluated expression.

### Does the plugin system even have a CLAUDE.md concept?

Reviewing the plugin directory structure reference, there is **no CLAUDE.md in the plugin component list**:

| Component | Default Location |
|-----------|-----------------|
| Manifest | `.claude-plugin/plugin.json` |
| Commands | `commands/` |
| Agents | `agents/` |
| Skills | `skills/` |
| Hooks | `hooks/hooks.json` |
| MCP servers | `.mcp.json` |
| Settings | `settings.json` |

CLAUDE.md is not a plugin component. A plugin cannot ship a CLAUDE.md that auto-loads into user projects. There is no documented mechanism for this.

---

## Finding 3: `.claude/rules/` Directory Pattern

### Official documentation confirms this pattern exists

From code.claude.com/docs/en/memory:

```
your-project/
├── .claude/
│   ├── CLAUDE.md           # Main project instructions
│   └── rules/
│       ├── code-style.md   # Code style guidelines
│       ├── testing.md      # Testing conventions
│       └── security.md     # Security requirements
```

**Key behaviors:**
- All `.md` files in `.claude/rules/` are **automatically loaded** as project memory
- Same priority as `.claude/CLAUDE.md`
- Files are discovered recursively (subdirectories supported)
- Loading is unconditional unless `paths:` frontmatter is used for path-scoped rules

**Path-scoped rules (YAML frontmatter):**
```markdown
---
paths:
  - "src/api/**/*.ts"
---

# API Development Rules
- All API endpoints must include input validation
```

Rules without `paths:` are always loaded. Rules with `paths:` only apply when Claude is working with files matching the patterns.

**Glob support in `paths:`:**
```markdown
---
paths:
  - "src/**/*.{ts,tsx}"
  - "{src,lib}/**/*.ts"
---
```

**Symlinks are supported:**
```bash
# Symlink a shared rules directory
ln -s ~/shared-claude-rules .claude/rules/shared

# Symlink individual rule files
ln -s ~/company-standards/security.md .claude/rules/security.md
```

**User-level rules also exist:**
```
~/.claude/rules/
├── preferences.md
└── workflows.md
```
User-level rules are loaded before project rules. Project rules take higher priority.

**Additional directories via environment variable:**
```bash
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ../shared-config
```
This loads CLAUDE.md, .claude/CLAUDE.md, and .claude/rules/*.md from additional directories.

---

## Finding 4: Referenced Bugs and Issues

| Issue | Status | Relevance |
|-------|--------|-----------|
| [#9354](https://github.com/anthropics/claude-code/issues/9354) — Fix `${CLAUDE_PLUGIN_ROOT}` in command markdown | OPEN (Nov 2025) | Confirms variable is not expanded in markdown contexts |
| [#15124](https://github.com/anthropics/claude-code/issues/15124) — @ file references outside project directory fail | CLOSED NOT PLANNED (Feb 2026) | External absolute paths in @-imports unreliable in v2.0.76 |
| [#4754](https://github.com/anthropics/claude-code/issues/4754) — Relative path from user CLAUDE.md loads from wrong directory | CLOSED NOT PLANNED | Intermittent bug with symlinked config dirs |
| [#17354](https://github.com/anthropics/claude-code/issues/17354) — Tilde creates literal `~/` directory | CLOSED DUPLICATE of #13138 | Tilde expansion unreliable in some contexts |

**Pattern in closed issues**: Issues about file references outside the project directory and variable expansion in markdown contexts are being closed as NOT PLANNED or as duplicates, suggesting these are not priorities for the framework team.

---

## Finding 5: Recommended Governance File Delivery Model

### Option A: Copy-on-init (RECOMMENDED)

During plugin initialization, copy `rules.md` from the plugin directory into the target project:
- Write to `.claude/rules/rules.md` (auto-loaded by the `.claude/rules/` pattern)
- OR inject an @-import into the project's CLAUDE.md pointing to `.claude/rules/rules.md`

**Pros:**
- Fully supported, no framework hacks
- Rules auto-load on every session without user action
- `.claude/rules/` pattern is designed exactly for this use case
- Survives plugin uninstall (intentional — governance rules should persist)

**Cons:**
- Does not auto-update when plugin updates (copy is a snapshot at init time)
- Re-initialization required to get updated rules

**Mitigation for the update gap:**
- Include a `version:` field in the copied rules file
- Initialization script detects stale version and prompts for re-run
- Or: ship an update hook (`PostToolUse` or `SessionStart`) that checks if the project's rules version matches the plugin's rules version and alerts the user

### Option B: Symlink to plugin cache (FRAGILE — NOT RECOMMENDED)

```bash
ln -s ~/.claude/plugins/cache/the-bulwark/lib/templates/rules.md .claude/rules/rules.md
```

- Plugin documentation says `.claude/rules/` supports symlinks
- BUT: plugin cache path is unstable (version-dependent, changes on update)
- AND: the symlink would break on plugin update (cache path changes) — which is exactly when you WANT it to update
- AND: the target path `~/.claude/plugins/cache/` contains version hashes, not a stable install path
- **This approach is fragile and should not be used**

### Option C: CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD (LIMITED — NOT RECOMMENDED for distribution)

```bash
CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1 claude --add-dir ~/.claude/plugins/cache/the-bulwark
```

- Would load rules from the plugin directory without copying
- BUT: requires users to set an environment variable on every invocation
- NOT a viable distribution model for end users
- Only appropriate for power-user or CI configuration

### Option D: User-level ~/.claude/rules/ (VIABLE for user-scoped plugins)

Ship rules to `~/.claude/rules/rules.md` during init. These load for ALL projects automatically.

**Pros:** Auto-loads everywhere, no per-project setup
**Cons:** Governance rules apply globally, cannot be scoped per project; no auto-update on plugin update

---

## Conclusion

**The recommended governance file delivery model is Option A: Copy-on-init.**

1. The Bulwark plugin initialization script copies `lib/templates/rules.md` to `.claude/rules/rules.md` in the target project.
2. The `.claude/rules/` directory pattern auto-loads all `.md` files in that directory — no @-import required.
3. To handle updates: embed a `bulwark_rules_version:` header in the rules file; the init script or a hook checks for version drift and prompts re-init.

**`@${CLAUDE_PLUGIN_ROOT}/lib/templates/rules.md` does not work in CLAUDE.md.** This path is not a supported syntax and the variable is not expanded in markdown contexts.

---

## Sources

- [Manage Claude's memory — Claude Code Docs](https://code.claude.com/docs/en/memory)
- [Create plugins — Claude Code Docs](https://code.claude.com/docs/en/plugins)
- [Plugins reference — Claude Code Docs](https://code.claude.com/docs/en/plugins-reference)
- [Issue #9354: Fix ${CLAUDE_PLUGIN_ROOT} in command markdown OR support local project plugin installation](https://github.com/anthropics/claude-code/issues/9354)
- [Issue #15124: @ file references outside project directory fail in CLAUDE.md](https://github.com/anthropics/claude-code/issues/15124)
- [Issue #4754: Files referenced with relative path from user CLAUDE.md attempt to load from working directory](https://github.com/anthropics/claude-code/issues/4754)
- [Issue #17354: Tilde paths create literal ~ directories](https://github.com/anthropics/claude-code/issues/17354)
- [Referencing Files and Resources in Claude Code — Steve Kinney](https://stevekinney.com/courses/ai-development/referencing-files-in-claude-code)
- [Claude Code settings reference](https://code.claude.com/docs/en/settings)
