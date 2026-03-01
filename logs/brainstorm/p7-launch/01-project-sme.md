---
role: project-sme
topic: "P7.1 Launch: Plugin Manifest, Initialization, and Distribution"
recommendation: proceed
key_findings:
  - "lib/templates/rules.md is missing CN1/CN2 (Code Navigation) rules — project Rules.md has them but the user-facing template does not"
  - "Three init scripts exist with overlapping concerns but serve different audiences (user init vs Bulwark dev) — only init-rules.sh and init-project-rules.sh are user-facing"
  - "19 agents exist in .claude/agents/ but only 4 are production pipeline agents (bulwark-*); the rest are skill-specific sub-agents that ship correctly via plugin auto-discovery"
  - "hooks.json timeout values use milliseconds (60000=60s, 30000=30s, 5000=5s) — these are correct per Claude Code's JSON schema, not the bug claimed in research"
  - "plugin.json uses directory-path format for agents and skills — confirmed valid by research synthesis (schema accepts string|array)"
---

# P7.1 Launch — Project SME

## Summary

The Bulwark plugin structure is approximately 90% complete. The `plugin.json`, `hooks/hooks.json`, skills directory, and agents directory all exist and follow correct conventions. The primary gap is that `lib/templates/rules.md` (the user-facing template) is missing the CN1/CN2 rules that were added to the project's own `Rules.md` in Session 86. Three init scripts exist but serve different audiences and must not be blindly unified. The init pipeline must copy governance files to the user's `.claude/rules/` directory (copy-on-init), not rely on variable expansion in Markdown.

## Detailed Analysis

### Current Plugin Structure

**What exists and is correct:**

- `.claude-plugin/plugin.json` — Valid manifest with `name`, `description`, `version`, `hooks`, `skills` (directory path), `agents` (directory path). The `commands: []` field is empty but structurally correct.
- `hooks/hooks.json` — Four hook types configured: `PostToolUse` (enforce-quality.sh on Write|Edit), `SubagentStart` (track-pipeline-start.sh), `SubagentStop` (track-pipeline-stop.sh), `SessionStart` (inject-protocol.sh). All use `${CLAUDE_PLUGIN_ROOT}` correctly.
- `skills/` — 28 skills exist at `/mnt/c/projects/the-bulwark/skills/`. All are flat directories with SKILL.md, matching plugin auto-discovery requirements.
- `scripts/hooks/` — 8 hook scripts. All are referenced from hooks.json paths.
- `lib/templates/` — 8 template files including rules.md, claudemd-injection.md, 4 Justfile variants, project-rules-template.md, project-rules-bulwark.md, statusline-default.yaml.

**What is missing or needs attention:**

1. **`lib/templates/rules.md` is stale.** The project's `Rules.md` (199 lines) contains sections CS, T, V, ID, TR, SC, CN, SR. The template `lib/templates/rules.md` contains CS, T, V, ID, TR, SC, SR — missing the entire CN (Code Navigation) section (CN1, CN2). This section was added in Session 86 but never propagated to the template. The init script (`init-rules.sh`) copies from `lib/templates/rules.md`, so users would get rules without CN1/CN2.

2. **No `.claude/rules/` delivery mechanism.** The research synthesis confirmed that `.claude/rules/` is the modern pattern for modular governance and that `@${CLAUDE_PLUGIN_ROOT}` does not expand in Markdown. The current `init-rules.sh` copies to `$TARGET/Rules.md` (project root). This must change to `$TARGET/.claude/rules/rules.md` for the init pipeline.

3. **`plugin.json` location.** It lives at `.claude-plugin/plugin.json`, not at repository root. This is the correct location for Claude Code plugins.

### Existing Init Scripts

Three scripts exist in `/mnt/c/projects/the-bulwark/scripts/`:

| Script | Purpose | Audience | Init Pipeline Role |
|--------|---------|----------|-------------------|
| `init-rules.sh` | Copies `lib/templates/rules.md` to target project root as `Rules.md`. Creates backup if exists. | **User-facing** | MANDATORY step — delivers governance rules. Must be updated to target `.claude/rules/` instead of project root. |
| `init-project-rules.sh` | Appends Binding Contract + Mandatory Rules section to target's CLAUDE.md. Has `--bulwark` flag for Bulwark-specific OR/SA rules vs generic template. Idempotent (checks for existing section). | **User-facing** | MANDATORY step — injects CLAUDE.md governance section. The `--bulwark` flag must NOT be set for external users. |
| `sync-hooks-for-dev.sh` | Transforms `hooks/hooks.json` (CLAUDE_PLUGIN_ROOT) to `.claude/settings.json` (CLAUDE_PROJECT_DIR) for dogfooding. | **Bulwark dev only** | NOT part of init pipeline. This is a development convenience script. Plugin install handles hooks natively via `hooks/hooks.json`. |

**Unification verdict:** Do NOT unify these three scripts. `sync-hooks-for-dev.sh` is a development tool and must stay separate. `init-rules.sh` and `init-project-rules.sh` are both user-facing and should be orchestrated by a new `init.sh` that calls them in sequence, but they remain separate atomic scripts (CS1: Single Responsibility).

### Agent Audit

19 agents exist in `.claude/agents/`. Classification by production readiness:

**Production pipeline agents (4)** — Core Bulwark enforcement:
- `bulwark-implementer.md` — Code-writing agent with quality enforcement
- `bulwark-issue-analyzer.md` — Root cause analysis and debug reports
- `bulwark-fix-validator.md` — Fix verification against debug reports
- `bulwark-standards-reviewer.md` — Standards compliance review

**Skill-specific sub-agents (13)** — Spawned by skills, ship with plugin:
- `plan-creation-po.md`, `plan-creation-architect.md`, `plan-creation-eng-lead.md`, `plan-creation-qa-critic.md` (4 plan-creation pipeline agents)
- `product-ideation-*.md` (5 product-ideation pipeline agents: idea-validator, market-researcher, competitive-analyzer, segment-analyzer, pattern-documenter, strategist)
- `statusline-setup.md` (bulwark-statusline skill agent)
- `markdown-reviewer.md` (general-purpose reviewer)

**Test/dev-only agents (2)** — Must NOT ship:
- `code-analyzer.md` — "Simple test agent...Used for testing pipeline orchestration"
- `file-counter.md` — "Simple test agent...Used for testing pipeline orchestration"

**Action:** Remove `code-analyzer.md` and `file-counter.md` from the agents directory before plugin distribution, or move them to a `tests/fixtures/agents/` location. The `agents: "agents/"` directive in plugin.json auto-discovers everything in that directory — test agents would be exposed to users.

### Integration Points

1. **SessionStart hook -> governance-protocol skill.** `inject-protocol.sh` reads `skills/governance-protocol/SKILL.md` using a relative path from the script (`../../skills/governance-protocol/SKILL.md`). This works because `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin root. No change needed.

2. **PostToolUse hook -> enforce-quality.sh -> suggest-pipeline.sh.** Chained execution. `enforce-quality.sh` looks for `Justfile` in `${CLAUDE_PROJECT_DIR}` (the user's project, not the plugin). This is correct — the Justfile is project-specific. If no Justfile exists, it warns but does not block.

3. **enforce-quality.sh -> `just` command.** The script searches PATH, `~/.local/bin/just`, `/usr/local/bin/just`. If `just` is not installed, it warns but does not block. The `bulwark-scaffold` skill generates a Justfile but does not install `just` itself.

4. **CN1/CN2 conditional inclusion.** If a user opts out of LSP setup, CN1 and CN2 rules should not be injected. This means `init-rules.sh` cannot simply copy a monolithic `rules.md`. Two approaches: (a) split CN rules into a separate file in `.claude/rules/cn-rules.md` that is only copied when LSP is configured, or (b) generate rules.md dynamically with/without the CN section. Approach (a) is cleaner and aligns with the `.claude/rules/` modular pattern.

5. **Justfile installation.** `bulwark-scaffold` already handles Justfile generation with language detection. Init should delegate to `bulwark-scaffold` via a recommended (not mandatory) step, not duplicate its logic. The skill is already user-invocable (`/bulwark-scaffold`).

6. **Cleanup script (AC17).** No cleanup mechanism exists today. `logs/` and `tmp/` grow unbounded. The Justfile has a `clean-logs` recipe that deletes `.yaml` and `.log` files, but it is manual and does not do age-based rotation. AC17 needs a new script (e.g., `scripts/hooks/cleanup-stale.sh`) triggered at SessionStart, with 10-day age threshold for files in `logs/` and `tmp/`.

### Constraints and Must-Not-Disrupt

1. **Project's own Rules.md and CLAUDE.md are NOT plugin output targets.** The init pipeline targets the INSTALLING USER'S project. The project root `Rules.md` (199 lines with Bulwark-specific OR/SA rules in CLAUDE.md) is for Bulwark development only. `lib/templates/rules.md` and `lib/templates/claudemd-injection.md` are the source templates.

2. **`sync-hooks-for-dev.sh` must remain separate.** It is the mechanism for dogfooding hooks locally. It must not be absorbed into init.

3. **`${CLAUDE_PLUGIN_ROOT}` in hooks.json must not change.** This variable is resolved by Claude Code at plugin load time. Converting to `${CLAUDE_PROJECT_DIR}` would break plugin-installed hooks.

4. **Skill dependencies between skills must remain self-contained.** Skills replicate references rather than cross-referencing (per MEMORY.md pattern). Init must not introduce cross-skill dependencies.

5. **The `.claude/settings.json` in the project is for Bulwark dev dogfooding** (contains CLAUDE_PROJECT_DIR hooks + Agent Teams env var). Plugin users get hooks from `hooks/hooks.json` automatically — no settings.json manipulation needed during init.

6. **First-run hook failure (GitHub #10997).** SessionStart hooks silently fail on initial plugin install. Init must account for this: either document that the user needs to restart the session after plugin install, or detect and re-trigger governance injection.

## Files Explored

| File | Relevance |
|------|-----------|
| `.claude-plugin/plugin.json` | Plugin manifest — structure, fields, completeness |
| `hooks/hooks.json` | Hook definitions — timeout values, script paths, variable usage |
| `scripts/init-rules.sh` | User-facing init — copies rules template to target project |
| `scripts/init-project-rules.sh` | User-facing init — injects CLAUDE.md governance section |
| `scripts/sync-hooks-for-dev.sh` | Dev-only script — must not be part of init pipeline |
| `scripts/hooks/enforce-quality.sh` | PostToolUse hook — integration with Justfile and project structure |
| `scripts/hooks/inject-protocol.sh` | SessionStart hook — governance protocol injection mechanism |
| `.claude/settings.json` | Dev dogfooding config — hooks + Agent Teams env var |
| `.claude/agents/*.md` (names+descriptions) | Agent audit — production vs test classification |
| `lib/templates/rules.md` | User-facing rules template — missing CN1/CN2 |
| `lib/templates/claudemd-injection.md` | User-facing CLAUDE.md injection — Binding Contract + Mandatory Rules |
| `lib/templates/project-rules-template.md` | Generic project rules placeholder |
| `lib/templates/justfile-generic.just` | Justfile template — scaffold output |
| `lib/templates/statusline-default.yaml` | Status line config template |
| `skills/bulwark-scaffold/SKILL.md` | Scaffold skill — Justfile generation and language detection |
| `skills/governance-protocol/SKILL.md` | Governance injection content — read by SessionStart hook |
| `skills/setup-lsp/SKILL.md` | LSP setup skill — 9-stage pipeline with restart checkpoint |
| `Rules.md` | Project rules (Bulwark dev) — has CN1/CN2 that template lacks |
| `Justfile` | Project Justfile — clean-logs recipe, sync-hooks recipe |
| `package.json` | Project metadata — version 0.1.0 |
| `artifacts/research/p7-launch/synthesis.md` | Research synthesis — design decisions and confirmed findings |

## Recommendation

**Proceed.** The plugin structure is substantively complete. Five concrete actions are needed:

1. **Sync CN1/CN2 to `lib/templates/rules.md`** — or better, split CN rules into a separate `lib/templates/cn-rules.md` file for conditional inclusion based on LSP opt-in/opt-out.

2. **Create `scripts/init.sh`** — orchestrates `init-rules.sh` (mandatory, targets `.claude/rules/`) and `init-project-rules.sh` (mandatory, targets CLAUDE.md) in sequence. Add optional steps: LSP setup delegation (to `setup-lsp` skill), Justfile generation delegation (to `bulwark-scaffold` skill). Do NOT absorb `sync-hooks-for-dev.sh`.

3. **Remove test agents** — `code-analyzer.md` and `file-counter.md` must be moved out of `.claude/agents/` before distribution.

4. **Create cleanup script** — `scripts/hooks/cleanup-stale.sh` for AC17, triggered at SessionStart, 10-day age-based rotation for `logs/` and `tmp/`, with `.gitkeep` preservation.

5. **Update `init-rules.sh` target path** — change from `$TARGET/Rules.md` to `$TARGET/.claude/rules/rules.md` (and create `.claude/rules/` directory). This aligns with the modular `.claude/rules/` pattern confirmed by research.
