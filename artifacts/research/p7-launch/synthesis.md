---
topic: "The Bulwark P7 Launch: Plugin Packaging, Initialization, Rules/CLAUDE.md Preparation, and Distribution"
phase: research
agents_synthesized: 5
confidence_distribution:
  high: 14
  medium: 8
  low: 4
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
| 7 | **Hooks and skills deliver value immediately after plugin install — zero init required for enforcement.** Governance file delivery (Rules.md) is the only mandatory init step. Everything else (Justfile, CLAUDE.md injection) is progressively valuable. | First Principles, Direct Investigation | HIGH |

## Tensions and Trade-offs

Where viewpoints disagree — present both sides, flag for brainstorm decision.

### Tension 1: Rules.md Slimming vs Compliance Reliability

- **View A** (First Principles, Direct Investigation): CLAUDE.md should be minimal with `@Rules.md` import. Official best practices say "for each line, ask: would removing this cause Claude to make mistakes?" Current ~200-line CLAUDE.md is above the ~150-line soft limit.
- **View B** (Contrarian): Every time instruction weight is reduced, compliance degrades. DEF-P4-005 proved binding language is essential. TC3 Round 1 failed due to instruction positioning. Further slimming risks repeating this with external users who lack project memory context.
- **Implication**: The brainstorm must decide WHERE to slim (project-specific OR/SA rules don't belong in user templates) vs WHAT must remain (binding language, SC1-SC3 enforcement). The delivery mechanism (@import vs copy) affects this — if Rules.md lives in the plugin and auto-updates, users always get the latest version without re-running init.

### Tension 2: ~~Dual-Repo Model Sustainability~~ RESOLVED

**User decision**: The standalone repo (`essential-agents-skills`) is a separate, independent project — not part of the Bulwark plugin distribution. The rsync script (`sync-essential-skills.sh`) should be removed from the Bulwark remote and gitignored going forward. The standalone repo's issues (node_modules zombie, sync transform complexity) have no bearing on plugin go-live. This tension is resolved and removed from brainstorm scope.

### Tension 3: Plugin Manifest Format — Array vs Directory Path

- **View A** (Contrarian): `plugins-checklist.md` expects `"skills": ["name1", "name2"]` (array), but `plugin.json` uses `"skills": "skills/"` (directory path). Never tested against actual plugin loading.
- **View B** (Direct Investigation): Official docs confirm both formats are supported — string path for auto-discovery, array for explicit listing.
- **Implication**: **Must be verified empirically before P7.1 implementation.** Test with `claude --plugin-dir ./` to confirm the directory-path format loads all 28 skills correctly.

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
| 6 | **`@${CLAUDE_PLUGIN_ROOT}/...` path syntax in CLAUDE.md @mentions is unverified** — if it works, Rules.md can live in the plugin and auto-update with plugin updates. If not, Rules.md must be copied to each project during init. This is a critical design fork. | First Principles | LOW (needs testing) |
| 7 | **`once: true` may be missing from SessionStart hook in hooks.json** — current config fires inject-protocol.sh without `once: true`. Plugin-level hooks should include this to prevent repeated governance injection per turn. | First Principles | MEDIUM |
| 8 | **Husky v4→v7 migration is the direct parallel for existing-project init** — dedicated migration/audit tool, not silent overwrite. Bulwark's compatibility-audit (AC7) should produce a human-readable diff, not an automatic merge. | Prior Art | HIGH |
| 9 | **Agents need selective migration from `.claude/agents/` to root `agents/`** — plugin.json declares `"agents": "agents/"` but agents live in `.claude/agents/`. Not all 19 agents are production agents — some are test agents (file-counter, code-analyzer, test-validator) that don't need migration. Audit required to determine which agents ship with plugin. | Direct Investigation, First Principles | HIGH |
| 10 | **No automated tests exist for init scripts** — launch-critical entry points (`init-rules.sh`, `init-project-rules.sh`, `bulwark-scaffold`) rely solely on manual test protocols. The idempotency check (`grep "## Mandatory Rules"`) is fragile. | Contrarian | MEDIUM |

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
| Plugin manifest format (array vs path) | Contrarian vs DI | MEDIUM (needs test) |
| OPA timing / first-mover opportunity | PA | MEDIUM |
| once:true missing from hooks.json | FP | MEDIUM |
| No init test automation | Contrarian | MEDIUM |
| @CLAUDE_PLUGIN_ROOT path in @mentions | FP | LOW (needs test) |
| Homebrew over-engineering for v1 | Contrarian | LOW |

## Open Questions

What couldn't be resolved — needs user input or further research.

1. **Does `@${CLAUDE_PLUGIN_ROOT}/lib/templates/rules.md` work in CLAUDE.md @mentions?** This is the critical design fork for governance file delivery. If yes: Rules.md lives in plugin, auto-updates. If no: must copy to project during init. *Needs empirical test.*

2. **Monolithic vs modular plugin packaging?** Ship all skills + production agents as one plugin, or create a minimal core + optional extensions?

3. **Should Rules.md be further slimmed for external users?** Current 198 lines is the result of P8.1 slimming. Further slimming risks compliance degradation per project history. But external users have no MEMORY.md context.

5. **Is `once: true` needed on SessionStart in `hooks/hooks.json`?** Current dev config (`settings.json`) behavior may differ from installed plugin behavior.

6. **Should P7.1 include automated init tests?** Contrarian identifies this as a gap. Manual testing has worked for development but launch-critical paths may warrant regression coverage.

## Implications for Next Steps

### Pre-Brainstorm Preparatory Work (Start of Session 85)

**Rules.md / CLAUDE.md reversal**: P8.1 moved some rules FROM Rules.md TO CLAUDE.md (OR/SA rules). These need to move BACK to Rules.md as part of centralization (AC9). The goal is Rules.md = single source of all rules, CLAUDE.md = minimal project guide with `@Rules.md` import.

**Slimmed CLAUDE.md template**: Before implementation, ask user for their template of a slimmed-down CLAUDE.md. This template defines the target state for AC10 and informs both init script design and governance file delivery decisions.

### Pre-Brainstorm Targeted Research (Start of Session 85)

Before the AT brainstorm begins, run targeted Task tool sub-agent research to resolve specific open questions. This updates the synthesis with verified answers so the brainstorm operates on facts, not assumptions.

| # | Research Target | Method | Why |
|---|----------------|--------|-----|
| 1 | **`extraKnownMarketplaces` bug status** (#16870) | Web search for current issue status | Determines if team auto-enrollment is viable for launch |
| 2 | **`@${CLAUDE_PLUGIN_ROOT}/...` path in CLAUDE.md @mentions** | Web search + Claude Code docs fetch | Critical design fork for governance file delivery |
| 3 | **`once: true` in plugin hooks.json** | Web search + Claude Code hooks docs | Determines if SessionStart needs configuration change |
| 4 | **Plugin manifest format verification** | Docs fetch for current plugin.json schema | Resolves array vs directory-path question |

Update synthesis with findings before proceeding to brainstorm.

### For AT Brainstorm (Session 85, after targeted research)

The brainstorm should resolve these decision points:

1. **Governance file delivery model**: @import from plugin path vs copy during init (informed by targeted research #2)
2. **CLAUDE.md architecture**: minimal @import + `.claude/rules/` directory vs current injection pattern
3. **Plugin scope**: monolithic (all components) vs modular (core + extensions)
4. **Distribution priority**: marketplace-only for v1, or multi-channel from day 1
5. **Init UX**: bash script vs slash command (`/bulwark:init`) vs both
6. **Rules.md slimming scope**: what stays, what moves, what gets cut
7. **Agent audit**: which of the 19 agents are production (ship with plugin) vs test-only (exclude)

### Immediate Actions (Before Brainstorm)

1. **Verify plugin manifest format**: `claude --plugin-dir ./` test to confirm directory-path format loads skills
2. **Audit agents/ directory**: Identify which agents are production vs test-only, confirm whether root `agents/` exists
3. **Check `once: true`**: Verify SessionStart hook behavior in `hooks/hooks.json` vs dev settings
4. **Remove rsync script from remote**: `scripts/sync-essential-skills.sh` should be gitignored — not part of plugin distribution
5. **Fix node_modules zombie** (standalone repo, separate from plugin): `rm -rf` in essential-agents-skills repo

### Reference: Local Plugin Testing

The `lazyptc-mcp` project at `C:\projects\lazyptc-mcp` has plugin packaging already implemented and can serve as a reference for local plugin testing workflow. Once folder consolidation and hook consolidation are ready, test locally using `claude --plugin-dir ./` before marketplace submission.
