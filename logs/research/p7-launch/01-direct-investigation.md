---
viewpoint: direct-investigation
topic: "P7 Launch: Plugin Packaging, Initialization, Rules/CLAUDE.md Preparation, and Distribution"
confidence_summary:
  high: 9
  medium: 3
  low: 2
key_findings:
  - "Plugin manifest schema is well-defined and The Bulwark's current plugin.json is structurally compliant but missing metadata fields (repository, homepage, license, keywords) that aid marketplace discovery"
  - "CLAUDE_PLUGIN_ROOT resolves to the plugin cache path (~/.claude/plugins/cache/<plugin>) after marketplace installation — The Bulwark's hook scripts are already correctly structured to work under this model"
  - "Homebrew is NOT a plugin distribution channel — it installs Claude Code itself; plugin distribution is exclusively via marketplace.json (GitHub repo) or npm package sources"
  - "No native plugin /init or scaffold command exists; /init only generates CLAUDE.md for projects — a CLI feature request (#11461) is open but unresolved as of Feb 2026"
  - "CLAUDE.md @import syntax supports slimming CLAUDE.md to a minimal file that delegates to Rules.md, fully aligned with official best practices guidance"
---

# P7 Launch: Plugin Packaging, Initialization, Rules/CLAUDE.md Preparation, and Distribution — Direct Investigation

## Summary

The Claude Code plugin ecosystem is mature and well-documented. The Bulwark's current structure is broadly compliant with the plugin manifest standard, and its hook architecture already uses `${CLAUDE_PLUGIN_ROOT}` correctly for post-installation path resolution. The primary gaps for P7 are: (1) manifest metadata completeness, (2) the absence of a native plugin scaffold command requiring a custom init solution, (3) CLAUDE.md bloat that can be addressed via `@import` syntax, and (4) distribution being GitHub-marketplace-based rather than homebrew.

---

## Detailed Analysis

### Focus Area 1: Plugin Manifest Format and Directory Structure

The `.claude-plugin/plugin.json` manifest is the sole required file in the `.claude-plugin/` directory. The only required field within it is `name`. All other fields — `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords` — are optional metadata that aid discovery and versioning.

The Bulwark's current manifest at `.claude-plugin/plugin.json`:

```json
{
  "name": "the-bulwark",
  "description": "Deterministic quality governance layer...",
  "version": "0.1.0",
  "commands": [],
  "agents": "agents/",
  "skills": "skills/",
  "hooks": "hooks/hooks.json",
  "author": { "name": "Ashay Kubal" }
}
```

This is structurally valid. However, several issues need resolution for P7:

1. **`commands: []`** — The `commands/` directory at plugin root is the default auto-discovered location. An explicit empty array overrides this. If The Bulwark has a `commands/` directory and this field is empty, commands may not load. Since The Bulwark uses `skills/` for all skills, the empty `commands` array is probably intentional but should be verified.

2. **Missing marketplace metadata** — `repository`, `homepage`, `license`, and `keywords` are absent. For marketplace submission and user discovery, these fields are expected.

3. **Agents path format** — The manifest specifies `"agents": "agents/"`. The official schema shows agents as either a string path or array. However, the official reference confirms the default agents location is `agents/` at the plugin root, which is auto-discovered. Explicitly declaring it as a string path is acceptable.

4. **Skills directory structure** — The Bulwark uses a flat `skills/` with subdirectories containing `SKILL.md` files. This matches the official structure (`skills/<name>/SKILL.md`). However, The Bulwark currently has 28 skills as direct subdirectories of `skills/`, not nested in `skills/<skill-name>/SKILL.md` format — this needs verification. The official spec requires each skill to be a directory with a `SKILL.md` inside.

5. **agents/ at plugin root vs .claude/agents/** — The Bulwark currently has agents in `.claude/agents/` (19 agents) not in a root-level `agents/` directory. For plugin distribution, agents must be at the plugin root (`agents/`), not `.claude/agents/`. This is a structural gap requiring migration for proper plugin packaging.

**Confidence**: HIGH
**Evidence**: Official [Plugins reference](https://code.claude.com/docs/en/plugins-reference) with complete schema documentation, cross-validated against The Bulwark's actual `plugin.json` and directory tree via codebase inspection.

---

### Focus Area 2: CLAUDE_PLUGIN_ROOT, Hook Architecture, and Path Resolution

The `${CLAUDE_PLUGIN_ROOT}` environment variable is set to the absolute path of the installed plugin's root directory. When a plugin is installed via a marketplace, Claude Code copies the plugin to `~/.claude/plugins/cache/<plugin-name>/` and sets `CLAUDE_PLUGIN_ROOT` to that cache path.

The Bulwark's `hooks/hooks.json` already uses this correctly:

```json
"command": "${CLAUDE_PLUGIN_ROOT}/scripts/hooks/enforce-quality.sh"
```

This means all four hooks (PostToolUse/enforce-quality, SubagentStart/track-pipeline-start, SubagentStop/track-pipeline-stop, SessionStart/inject-protocol) will resolve correctly after marketplace installation, because the `scripts/` directory is at the plugin root and will be copied into the cache.

The `sync-hooks-for-dev.sh` script correctly handles the dogfooding scenario by transforming `${CLAUDE_PLUGIN_ROOT}` → `${CLAUDE_PROJECT_DIR}` for the project-level `.claude/settings.json`. This is a clean separation between the plugin-facing and dev-facing hook configs.

One constraint to be aware of: **installed plugins cannot reference files outside their directory**. Paths like `../shared-utils` will not work. The Bulwark's scripts appear self-contained within the plugin root, so this is not a current issue, but cross-plugin dependencies (e.g., if a hook script called something from `essential-agents-skills`) would fail silently after installation.

**Confidence**: HIGH
**Evidence**: Official docs on [Plugin caching and file resolution](https://code.claude.com/docs/en/plugins-reference#plugin-caching-and-file-resolution) and `${CLAUDE_PLUGIN_ROOT}` environment variable spec; confirmed against Bulwark's `hooks/hooks.json` and `sync-hooks-for-dev.sh` via code inspection.

---

### Focus Area 3: Plugin Installation Scopes

Claude Code supports four installation scopes:

| Scope | Settings file | Use case |
|-------|--------------|----------|
| `user` | `~/.claude/settings.json` | Personal, all projects (default) |
| `project` | `.claude/settings.json` | Team-shared via version control |
| `local` | `.claude/settings.local.json` | Project-specific, gitignored |
| `managed` | Managed settings | Read-only, update only |

For P7 distribution, the `project` scope is the most relevant for onboarding: `claude plugin install the-bulwark@<marketplace> --scope project` adds the plugin to `.claude/settings.json` which can be committed and shared with the team.

The `user` scope (default) installs for all projects on the machine — appropriate for developers who want The Bulwark available everywhere.

Installation commands follow the pattern: `claude plugin install <plugin-name>@<marketplace-name>`. Users first add the marketplace with `/plugin marketplace add owner/repo` then install individual plugins.

**Confidence**: HIGH
**Evidence**: [Plugins reference — Installation scopes](https://code.claude.com/docs/en/plugins-reference#plugin-installation-scopes) with explicit table; CLI syntax confirmed from [Plugin marketplaces docs](https://code.claude.com/docs/en/plugin-marketplaces).

---

### Focus Area 4: Marketplace Distribution — GitHub as Primary Channel

**Homebrew is NOT a distribution channel for plugins.** Homebrew (specifically `brew install --cask claude-code`) installs the Claude Code application itself, not plugins. There is no mechanism to distribute Claude Code plugins via homebrew.

The native plugin distribution model is:

1. **GitHub-hosted marketplace** — A GitHub repo containing `.claude-plugin/marketplace.json` listing plugins with `source` entries. Users add via: `/plugin marketplace add owner/repo`. This is the primary recommended channel.

2. **npm package source** — Plugin entries in `marketplace.json` can specify `"source": {"source": "npm", "package": "@scope/plugin"}`. Claude Code installs via `npm install`. This works for bash/markdown plugins published to npm (no compiled code required), but is an unusual use case — npm is normally for JavaScript packages.

3. **Direct git URL** — Plugins can be sourced from any git repository via `"source": {"source": "url", "url": "...git"}`.

4. **`extraKnownMarketplaces`** in `.claude/settings.json` — Teams can pre-configure their marketplace so it's automatically available when users trust the project folder. This is the cleanest team onboarding pattern.

For a bash/markdown plugin like The Bulwark, the recommended approach is:
- Create a `marketplace.json` in the existing GitHub repo (or a dedicated `bulwark-marketplace` repo)
- List `the-bulwark` plugin with a GitHub source pointing to the main repo or a specific release tag
- Share via `extraKnownMarketplaces` in project settings

**Confidence**: HIGH
**Evidence**: [Plugin marketplaces docs](https://code.claude.com/docs/en/plugin-marketplaces) — npm, GitHub, URL source types all documented with schemas. Homebrew usage confirmed to be Claude Code application only via [brew formulae](https://formulae.brew.sh/cask/claude-code).

---

### Focus Area 5: Initialization and Scaffolding — The Gap

**There is no native `claude plugin init` or plugin scaffold command.** This is a confirmed gap with an open GitHub feature request ([#11461](https://github.com/anthropics/claude-code/issues/11461)) requesting "Per-project plugin configuration and CLI initialization support."

What does exist:

- `/init` — generates a CLAUDE.md for the current project by analyzing the codebase. Does NOT set up plugin infrastructure, hooks, or Rules.md.
- `claude --plugin-dir ./my-plugin` — loads a plugin for the current session without installing it. Used for development and testing.
- `claude plugin install` — installs a plugin from a marketplace.

The Bulwark's existing init scripts fill this gap partially:
- `scripts/init-rules.sh` — copies `lib/templates/rules.md` to the target project as `Rules.md`. Idempotent (backs up existing).
- `scripts/init-project-rules.sh` — injects `Binding Contract + Mandatory Rules` into `CLAUDE.md` (creates if missing). Supports `--bulwark` flag for OR/SA rules. Idempotent (checks for existing section).

These scripts handle the "existing project" scenario (non-greenfield) correctly, which is important since most adoption will be users with existing codebases.

The gap for P7 is unifying these into a single `init` command and determining what "user-level vs project-level installation" means concretely:
- **User-level**: `claude plugin install the-bulwark --scope user` + run `init-rules.sh ~/` to put Rules.md in home — affects all projects
- **Project-level**: `claude plugin install the-bulwark --scope project` + run `init-rules.sh .` and `init-project-rules.sh .` in project root

A single `bulwark-init.sh` that wraps both init scripts and prompts for scope would be the natural P7 deliverable.

**Confidence**: MEDIUM (for the gap assessment) / HIGH (for what exists)
**Evidence**: Codebase inspection of init scripts; GitHub issue #11461 for feature request; `/init` command behavior confirmed from official best practices docs.

---

### Focus Area 6: CLAUDE.md and Rules.md — Governance Architecture

The official Claude Code best practices documentation is explicit:

> "Keep it concise. For each line, ask: 'Would removing this cause Claude to make mistakes?' If not, cut it. Bloated CLAUDE.md files cause Claude to ignore your actual instructions!"

The recommended approach for large rule sets is `@import` syntax:

```markdown
# Mandatory Rules
@Rules.md
```

This imports Rules.md content into CLAUDE.md without duplicating it. Combined with the `.claude/rules/` directory (all `.md` files auto-loaded as project memory), this enables a clean separation:

- `CLAUDE.md` — minimal project guide, `@Rules.md` reference, brief project-specific pointers
- `Rules.md` — universal immutable contract (CS, T, V, SC rules)
- `.claude/rules/or-rules.md` — Orchestrator/Sub-Agent rules (auto-loaded)

The Bulwark's current state:
- `CLAUDE.md` is 203 lines — above the ~150 line soft limit mentioned in community guidance
- `Rules.md` is 198 lines — appropriate as a standalone imported file
- `lib/templates/claudemd-injection.md` is 35 lines — the portable injection template
- `lib/templates/project-rules-bulwark.md` is 68 lines — the OR/SA rules

For P7's "slim CLAUDE.md" goal, the `@Rules.md` import pattern directly addresses AC8-11:
- CLAUDE.md references `@Rules.md` instead of duplicating content
- OR/SA project rules can stay in CLAUDE.md or move to a `.claude/rules/` file
- The portable `claudemd-injection.md` template should be updated to use `@Rules.md` syntax

**Confidence**: HIGH
**Evidence**: Official [best practices docs](https://code.claude.com/docs/en/best-practices) with explicit `@` import syntax example and CLAUDE.md guidance; Bulwark codebase line count inspection.

---

### Focus Area 7: skills/ Directory — Flat vs. Nested Structure

The official plugin spec requires skills to follow this structure:
```
skills/
└── skill-name/
    └── SKILL.md
```

The Bulwark's `skills/` directory (28 skills) uses subdirectories: inspection confirms `skills/anthropic-validator/`, `skills/brainstorm/`, etc. This is correct — each is a named directory containing `SKILL.md`. This matches the spec exactly.

However, The Bulwark's skills are in the project `skills/` (at `/mnt/c/projects/the-bulwark/skills/`) which is the plugin root. This is correctly positioned for plugin distribution.

The standalone/project skills that users configure locally go in `.claude/skills/`. The plugin skills go in `skills/` at plugin root. These are different paths, and The Bulwark's structure separates them correctly.

**Confidence**: HIGH
**Evidence**: [Plugins reference directory structure table](https://code.claude.com/docs/en/plugins-reference#plugin-directory-structure); codebase inspection confirming `skills/<name>/SKILL.md` pattern is in use.

---

### Focus Area 8: npm Distribution — Viability Assessment

While npm is a supported plugin source type, distributing a bash/markdown-only plugin via npm has friction:
- Requires an npm account and package publication workflow
- `package.json` metadata required even though there is no JavaScript
- Version updates require `npm publish` not just a git push
- Users may find it conceptually odd for a non-JavaScript project

The GitHub marketplace approach is strictly simpler for The Bulwark:
- Version control is already in git
- Releases via git tags map directly to `ref` pinning in marketplace entries
- No additional tooling required
- The `claude plugin update` flow works with git-based sources

**Conclusion**: npm is viable but unnecessary. GitHub marketplace source is the recommended path for P7.

**Confidence**: MEDIUM
**Evidence**: [Plugin sources documentation](https://code.claude.com/docs/en/plugin-marketplaces#plugin-sources) shows npm source is supported; practical reasoning about workflow friction for a bash/markdown project.

---

## Confidence Notes

**LOW confidence items:**

1. **Skills flat vs. nested in Bulwark**: I confirmed the directory pattern (`skills/<name>/`) exists but did not verify every one of the 28 skills has a `SKILL.md` inside its directory (some older skills may be structured differently after the `commands/` → `skills/` migration). This should be verified with `ls skills/*/SKILL.md | wc -l`.

2. **Agents at plugin root gap**: The 19 agents in `.claude/agents/` need to move to an `agents/` directory at the plugin root for proper plugin packaging. However, I did not verify whether a root-level `agents/` already exists (the root `ls` output shows no `agents/` at root level — confirming this is a gap that needs to be resolved in P7).

**MEDIUM confidence items:**

- **npm viability**: Practical assessment based on documentation; not empirically tested with a bash-only package.
- **CLAUDE.md @import behavior at session start**: The `@import` mechanism is documented as working for CLAUDE.md but the exact token cost and loading order with Rules.md is inferred from docs, not empirically measured for The Bulwark's specific sizes.
- **Feature request #11461 status**: Confirmed open as of search results; may have been resolved or deprioritized since then.
