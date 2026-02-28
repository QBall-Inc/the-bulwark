---
topic: "The Bulwark P7 Launch: Plugin Packaging, Initialization, Rules/CLAUDE.md Preparation, and Distribution"
phase: research
agents_synthesized: 5
targeted_research_agents: 4
last_updated: 2026-02-28 (Session 85 — targeted research incorporated)
confidence_distribution:
  high: 17
  medium: 6
  low: 1
  resolved: 6
---

# P7 Launch Research — Synthesis

## Key Findings (Convergent)

Findings where multiple viewpoints agree — these are high confidence.

| # | Finding | Supporting Viewpoints | Confidence |
|---|---------|----------------------|------------|
| 1 | **GitHub marketplace is the primary distribution channel.** `/plugin marketplace add owner/repo` is the native, lowest-friction path. Homebrew/npm are optional secondary channels, not functional requirements. | Direct Investigation, Practitioner, First Principles, Prior Art | HIGH |
| 2 | **Plugin structure is ~90% complete.** `plugin.json`, `hooks/hooks.json` with `${CLAUDE_PLUGIN_ROOT}`, flat `skills/` directory all exist and are structurally correct. The gap is canonicalization, not architecture. | Direct Investigation, First Principles | HIGH |
| 3 | **Initialization is two distinct problems that must not be conflated.** Problem A: installing the plugin into Claude Code (solved natively by `/plugin install`). Problem B: configuring a project with governance files (requires `init.sh`). | First Principles, Practitioner | HIGH |
| 4 | **Init should follow the thin-copy principle: copy files, audit existing config, exit.** Every scaffolding tool that tried to remain a lifecycle manager failed (CRA deprecated 2025, Yeoman dead by 2018). degit and Husky v7 survived by doing less. | Prior Art, First Principles | HIGH |
| 5 | **The `.claude/rules/` directory pattern is the modern approach for modular governance.** Path-scoped frontmatter allows topic-specific rules files auto-loaded without CLAUDE.md bloat. Monolithic CLAUDE.md is actively discouraged. | Practitioner, Direct Investigation | HIGH |
| 6 | **The dependency chain is: governance file prep → init script design → plugin finalization → marketplace creation → documentation.** These cannot be parallelized; init.sh is a delivery vehicle for the governance files, so content must be decided first. | First Principles, Prior Art | HIGH |
| 7 | **Hooks and skills deliver value immediately after plugin install — zero init required for enforcement.** Governance file delivery (Rules.md) is the only mandatory init step. Everything else (Justfile, CLAUDE.md injection, LSP setup) is progressively valuable. Init pipeline: mandatory (governance files) → recommended (LSP setup via P6.11 `setup-lsp`) → optional (Justfile, project assets). | First Principles, Direct Investigation, Session 85 | HIGH |

## Tensions and Trade-offs

Where viewpoints disagree — present both sides, flag for brainstorm decision.

### Tension 1: ~~Rules.md Slimming vs Compliance Reliability~~ RESOLVED

**User decision (validated in production)**: The optimal slimming formula is: **rule statement + essential nuance where non-obvious. No justifications, no examples, no elaboration.** This aligns with Boris Cherney's guidance ("just write the rules") and was empirically validated:
- P8.1 tested both extremes: too slim broke compliance, full justifications wasted tokens
- User validated the slim-with-nuance approach in production at Jefferies (firm Claude subscription) — works at same quality as current Bulwark Rules.md
- Removed from brainstorm scope — the slimming approach is decided, only the execution remains (which rules get nuance, which don't)

### Tension 2: ~~Dual-Repo Model Sustainability~~ RESOLVED

**User decision**: The standalone repo (`essential-agents-skills`) is a separate, independent project — not part of the Bulwark plugin distribution. The rsync script (`sync-essential-skills.sh`) should be removed from the Bulwark remote and gitignored going forward. The standalone repo's issues (node_modules zombie, sync transform complexity) have no bearing on plugin go-live. This tension is resolved and removed from brainstorm scope.

### Tension 3: ~~Plugin Manifest Format — Array vs Directory Path~~ RESOLVED

**Targeted research confirmed (Session 85)**: Official schema defines `skills` and `agents` as `string|array` — both formats are valid. The directory-path format (`"skills": "skills/"`) is schema-correct. Additionally, `skills/` at plugin root is auto-discovered even without explicit declaration, making the entry redundant but harmless. **No change needed to current plugin.json format.**

### Tension 4: Scope of Launch Artifact

- **View A** (Prior Art / MegaLinter anti-pattern): Bundle everything = adoption friction. The plugin should be minimal core (hooks, essential skills), with extended skill bundles as optional installs.
- **View B** (implicit from current structure): All skills + production agents ship as one plugin. Users get full value immediately.
- **Implication**: Brainstorm should decide: monolithic plugin (simpler to ship, higher context cost) vs modular plugin (lower per-project cost, harder to package). Note: the `skills:` dependency field is empirically validated and not a packaging risk.

## Unique Insights

Findings from a single viewpoint that add important nuance.

| # | Insight | Source Viewpoint | Confidence |
|---|---------|-----------------|------------|
| 1 | **`skills:` dependency field is undocumented but empirically validated** — used by 11 skills, flagged as undocumented (FW-OBS-002). However, extensively tested across multiple skills and sessions with consistent behavior. **Not a launch risk** — accepted as working undocumented feature per user confirmation. | Contrarian (downgraded) | LOW |
| 2 | **node_modules zombie in standalone repo** — separate issue from plugin launch. The standalone repo (`essential-agents-skills`) is an independent project, not part of plugin distribution. Fix independently. | Contrarian | N/A (out of scope) |
| 3 | **`extraKnownMarketplaces` has a confirmed bug (#16870)** — ignored in `managed-settings.json`. Team-wide auto-enrollment requires CLI workaround, not pure config. Also unavailable in headless/CI mode (#13096). | Practitioner | HIGH |
| 4 | **ESLint shareable config is the correct mental model** — frame Rules.md + CLAUDE.md templates as "shareable AI governance config" not "plugin." Matches the lightweight, declarative, no-runtime pattern that achieved massive adoption (eslint-config-airbnb: 3M+ weekly downloads). | Prior Art | HIGH |
| 5 | **OPA timing parallel** — policy-as-code needed a forcing function (Kubernetes RBAC) to go mainstream. AI governance may have its forcing function approaching (enterprise compliance mandates). First-mover advantage is available now. | Prior Art | MEDIUM |
| 6 | **`@${CLAUDE_PLUGIN_ROOT}/...` does NOT work in CLAUDE.md @mentions** — `${CLAUDE_PLUGIN_ROOT}` only expands in JSON configs (hooks.json, .mcp.json), not Markdown. Confirmed by GitHub #9354 (OPEN). **Design fork resolved: copy-on-init is the only viable model.** Rules.md must be copied to `.claude/rules/` during init. The `.claude/rules/` directory auto-loads all `.md` files without @import. | First Principles, Targeted Research | HIGH (verified) |
| 7 | **`once: true` IS a valid hooks.json option** (skills-only, not agents). If `true`, hook runs once per session then is removed. SessionStart fires at lifecycle boundaries (startup, resume, clear, compact). Valid fields: `type`, `command`/`url`/`prompt`, `timeout` (seconds), `statusMessage`, `once` (skills only), `async` (command only). For Bulwark: `once: true` is NOT needed — inject-protocol.sh should re-inject after `/clear` and compaction to maintain governance context. | First Principles, Targeted Research (corrected), Official Docs | HIGH (verified) |
| 8 | **Husky v4→v7 migration is the direct parallel for existing-project init** — dedicated migration/audit tool, not silent overwrite. Bulwark's compatibility-audit (AC7) should produce a human-readable diff, not an automatic merge. | Prior Art | HIGH |
| 9 | **Agents need selective migration from `.claude/agents/` to root `agents/`** — plugin.json declares `"agents": "agents/"` but agents live in `.claude/agents/`. Not all 19 agents are production agents — some are test agents (file-counter, code-analyzer, test-validator) that don't need migration. Audit required to determine which agents ship with plugin. | Direct Investigation, First Principles | HIGH |
| 10 | **No automated tests exist for init scripts** — launch-critical entry points (`init-rules.sh`, `init-project-rules.sh`, `bulwark-scaffold`) rely solely on manual test protocols. The idempotency check (`grep "## Mandatory Rules"`) is fragile. | Contrarian | MEDIUM |
| 11 | **Marketplace plugin SessionStart hooks silently fail on first run** — GitHub #10997. Async marketplace loading race condition. Works on subsequent runs once marketplace is cached. Release notes must document restart requirement after initial install. | Targeted Research | HIGH (verified) |
| 12 | **Timeout units in hooks.json ARE wrong** — official docs and reference plugins (lazyptc-mcp: `30`, `10`; clear-framework: `60`, `30`) confirm timeout is in seconds. Bulwark's `60000`/`30000`/`5000` values = 16.7h/8.3h/1.4h. Must be corrected to `60`/`30`/`5` in both `hooks/hooks.json` (plugin) and `.claude/settings.json` (dev). Default: 600s for command hooks. | Targeted Research, Cross-reference with lazyptc-mcp + clear-framework | HIGH (verified, action required) |
| 13 | **`extraKnownMarketplaces` bug confirmed still OPEN (#16870)** — silently ignored in managed-settings.json. Works in project-level `.claude/settings.json` only. Headless/CI mode #13096 closed NOT_PLANNED. Team distribution: use project-level settings.json + manual install instructions. | Targeted Research | HIGH (verified) |
| 14 | **`.claude/rules/` supports recursive subdirectories and path-scoped frontmatter** — files auto-load with same priority as CLAUDE.md. Supports `paths:` globs for targeting specific directories. User-level equivalent at `~/.claude/rules/`. This is the canonical mechanism for modular governance. | Targeted Research | HIGH (verified) |
| 15 | **LSP setup should be an optional init step** — LSP integration replaces grep/glob searches (~30-60s) with semantic code intelligence (~50ms). High-value enhancement that requires tech stack detection, binary installation, plugin installation, and restart. Task brief at `plans/task-briefs/P6.11-setup-lsp.md`. Init should offer: "Would you like to set up LSP for faster code navigation? (Recommended)". Skill: P6.11 (`setup-lsp`). | Session 85, User | HIGH |
| 16 | **Rules.md needs a Code Navigation (CN) section to enforce LSP preference** — without explicit rules, Claude defaults to training-pattern text search (Grep/Glob) even when LSP is available. Proposed hierarchy: Code navigation: LSP > Grep > Glob. File content search: Grep > Glob. Note: Claude Code's built-in Grep tool already uses ripgrep (rg) internally, so ripgrep is already the default for text search. The CN rules enforce LSP-first for semantic operations. | Session 85, User | HIGH |

## Confidence Map

| Finding | Supporting Viewpoints | Confidence |
|---------|----------------------|------------|
| GitHub marketplace is primary distribution | DI, Practitioner, FP, PA | HIGH |
| Plugin structure ~90% complete | DI, FP | HIGH |
| Init = two separate problems | FP, Practitioner | HIGH |
| Thin-copy principle for scaffolding | PA, FP | HIGH |
| .claude/rules/ is the modern pattern | Practitioner, DI | HIGH |
| Dependency chain: governance → init → plugin → marketplace | FP, PA | HIGH |
| Zero-init value from hooks+skills | FP, DI | HIGH |
| `skills:` dependency is undocumented but validated | Contrarian (downgraded) | LOW |
| node_modules zombie in standalone | Contrarian | N/A (out of scope) |
| agents/ migration needed | DI, FP | HIGH |
| extraKnownMarketplaces bug | Practitioner | HIGH |
| Husky parallel for migration/audit | PA | HIGH |
| Rules slimming vs compliance trade-off | Contrarian vs FP/DI | MEDIUM (tension) |
| Dual-repo sustainability | Contrarian | RESOLVED (out of scope) |
| Plugin manifest format (array vs path) | Contrarian vs DI, Targeted | RESOLVED (both valid) |
| OPA timing / first-mover opportunity | PA | MEDIUM |
| once:true in hooks.json | FP, Targeted, Docs | RESOLVED (exists, skills-only, not needed for Bulwark) |
| No init test automation | Contrarian | MEDIUM |
| @CLAUDE_PLUGIN_ROOT path in @mentions | FP, Targeted | RESOLVED (does not work) |
| Homebrew over-engineering for v1 | Contrarian | LOW |
| First-run hook failure (#10997) | Targeted | HIGH (verified) |
| Timeout units in hooks.json | Targeted, Cross-ref | HIGH (verified, action required) |
| extraKnownMarketplaces still broken | Targeted | HIGH (verified) |
| .claude/rules/ recursive + path-scoped | Targeted | HIGH (verified) |

## Open Questions

What couldn't be resolved — needs user input or further research.

1. ~~**Does `@${CLAUDE_PLUGIN_ROOT}/lib/templates/rules.md` work in CLAUDE.md @mentions?**~~ **RESOLVED (Session 85)**: No. Variable expansion only works in JSON configs. Copy-on-init to `.claude/rules/` is the only viable model.

2. **Monolithic vs modular plugin packaging?** Ship all skills + production agents as one plugin, or create a minimal core + optional extensions? *(For brainstorm)*

3. **Should Rules.md be further slimmed for external users?** Current 198 lines is the result of P8.1 slimming. Further slimming risks compliance degradation per project history. But external users have no MEMORY.md context. *(For brainstorm)*

4. ~~**Is `once: true` needed on SessionStart in `hooks/hooks.json`?**~~ **RESOLVED (Session 85)**: `once: true` is valid (skills-only field), but NOT needed for Bulwark. SessionStart fires at lifecycle boundaries (startup, resume, clear, compact). Bulwark's inject-protocol.sh SHOULD re-fire after `/clear` and compaction to maintain governance context. Using `once: true` would weaken governance.

5. **Should P7.1 include automated init tests?** Contrarian identifies this as a gap. Manual testing has worked for development but launch-critical paths may warrant regression coverage. *(For brainstorm)*

6. ~~**Are hooks.json timeout values in seconds or milliseconds?**~~ **RESOLVED (Session 85)**: Timeout is in seconds (confirmed by docs + lazyptc-mcp + clear-framework cross-reference). Bulwark's values (60000/30000/5000) are wrong — must be corrected to 60/30/5 in both `hooks/hooks.json` and `.claude/settings.json`. *(Action item for P7.1)*

7. **NEW: How to handle first-run hook failure (#10997)?** Marketplace plugin SessionStart hooks silently fail on first install due to async loading race. Document restart requirement in release notes, or find workaround? *(For brainstorm)*

## Implications for Next Steps

### Completed Pre-Brainstorm Work (Session 85)

**Slimmed CLAUDE.md template received** — User provided `tmp/sample-claude.md` (~50 lines). Confirms design: minimal CLAUDE.md with `@Rules.md` import, session startup/end sequences, project assets table, modes of operation. Three pending items (image→table, assets table template, rule ID correction) deferred to P7.1 implementation.

**Targeted research complete** — 4 Sonnet sub-agents resolved 4 open questions:
- `@PLUGIN_ROOT` in Markdown: **Does not work** → copy-on-init model confirmed
- `once: true`: **Does not exist** → SessionStart is inherently once-per-lifecycle, no change needed
- Plugin manifest format: **Both string and array valid** → current format correct
- `extraKnownMarketplaces`: **Still broken (#16870)** → use project-level settings.json + manual install

**New findings from targeted research**:
- First-run hook failure (#10997) — marketplace plugins silently fail SessionStart on initial install
- Timeout units ambiguity — hooks.json values may be wrong (seconds vs milliseconds)
- `.claude/rules/` supports recursive subdirectories and path-scoped frontmatter (`paths:` globs)

### Preparatory Work Still Needed

**Rules.md / CLAUDE.md reversal**: P8.1 moved some rules FROM Rules.md TO CLAUDE.md (OR/SA rules). These need to move BACK to Rules.md as part of centralization (AC9). The goal is Rules.md = single source of all rules, CLAUDE.md = minimal project guide with `@Rules.md` import.

**Hierarchical scoping model (user preference, aligns with best practices)**: Plugin init should create `CLAUDE.md` and `Rules.md` at the appropriate scope — `~/.claude/` for user-level or `.claude/` for project-level. The key architectural principle: these files are **additive and hierarchical**. In a monorepo, a `frontend/` subfolder can have its own `.claude/CLAUDE.md` and `Rules.md` with frontend-specific rules. When Claude is launched from that folder, the subfolder's files load IN ADDITION TO the root-level files — not as replacements. This is the recommended pattern from Boris Cherney (Claude Code creator) and widely adopted as best practice. Implications for init design:
- Init should respect scope (user-level → `~/.claude/`, project-level → `.claude/`)
- Init should document the hierarchical loading model so users know they can add subfolder-scoped rules
- The "compatibility audit" (AC7) should check for existing files at ALL scope levels, not just project root

### For AT Brainstorm (Session 86)

The brainstorm should resolve these decision points (updated with targeted research findings):

1. ~~**Governance file delivery model**~~: **RESOLVED** — copy-on-init to `.claude/rules/`. No @import from plugin path.
2. **CLAUDE.md architecture**: minimal `@Rules.md` import + `.claude/rules/` directory for modular governance
3. **Plugin scope**: monolithic (all components) vs modular (core + extensions)
4. **Distribution priority**: marketplace-only for v1, or multi-channel from day 1
5. **Init UX**: bash script vs slash command (`/bulwark:init`) vs both
6. **Rules.md centralization scope**: which OR/SA rules move back from CLAUDE.md, what gets slimmed, AND new CN (Code Navigation) section added
7. **Agent audit**: which of the 19 agents are production (ship with plugin) vs test-only (exclude)
8. **NEW: First-run failure mitigation**: document restart requirement vs find workaround (#10997)
9. **NEW: Code Navigation rules (CN section)**: enforce LSP-first preference hierarchy. Proposed: CN1 (LSP > Grep > Glob for code), CN2 (Grep > Glob for file content). Without explicit rules, Claude defaults to text search even when LSP is configured.

### Immediate Actions (Before Brainstorm)

1. ~~**Verify plugin manifest format**~~: RESOLVED — both formats valid, current format correct. Note: lazyptc-mcp uses `"./skills/"` (with `./` prefix); Bulwark uses `"skills/"` — both valid.
2. **Audit agents/ directory**: Identify which agents are production vs test-only, confirm whether root `agents/` exists
3. ~~**Check `once: true`**~~: RESOLVED — valid (skills-only), not needed for Bulwark governance
4. **Remove rsync script from remote**: `scripts/sync-essential-skills.sh` should be gitignored — not part of plugin distribution
5. ~~**Fix node_modules zombie**~~: Out of scope (standalone repo issue)
6. ~~**Verify timeout units**~~: RESOLVED — seconds, confirmed by docs + cross-reference. **ACTION REQUIRED**: Fix Bulwark values (60000→60, 30000→30, 5000→5) in both `hooks/hooks.json` and `.claude/settings.json` during P7.1.

### Path Variable Reference (from cross-project analysis)

| Variable | Context | Example |
|----------|---------|---------|
| `${CLAUDE_PLUGIN_ROOT}` | Plugin hooks.json, commands, MCP servers — anything bundled in the plugin | `${CLAUDE_PLUGIN_ROOT}/scripts/hooks/inject-protocol.sh` |
| `${CLAUDE_PROJECT_DIR}` | Dev settings.json — references scripts in the project under development | Current Bulwark dev config |
| Project-relative or `~/` | Init-deployed files in user's project | `.claude/rules/rules.md`, `CLAUDE.md` |

The Bulwark plugin `hooks/hooks.json` already correctly uses `${CLAUDE_PLUGIN_ROOT}`. The dev `.claude/settings.json` correctly uses `${CLAUDE_PROJECT_DIR}`. Init-deployed governance files (CLAUDE.md, Rules.md) go into user's project at `.claude/rules/` or project root — no variable expansion needed (they're static copies).

### Reference: Local Plugin Testing

The `lazyptc-mcp` project at `C:\projects\lazyptc-mcp` has plugin packaging already implemented and can serve as a reference for local plugin testing workflow. Once folder consolidation and hook consolidation are ready, test locally using `claude --plugin-dir ./` before marketplace submission.
