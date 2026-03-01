---
topic: "P7.1 Launch: Plugin Manifest, Initialization, and Distribution"
phase: brainstorm
mode: exploratory
agents_synthesized: "4"
overall_verdict: modify
verdict_source: critical-analyst
---

# P7.1 Launch — Brainstorm Synthesis

## Consensus Areas

Where all roles agree — foundation for implementation.

| Area | Supporting Roles | Confidence |
|------|-----------------|------------|
| Init pipeline: thin orchestrator + atomic scripts + printed skill delegation | SME, PDL, TA, CA | HIGH |
| Distribution: Self-hosted GitHub marketplace (v1) + npm source (v1) + official Anthropic marketplace submission (v2). Homebrew deferred. | SME, PDL, TA, CA + User (revised) | HIGH |
| Delegate to /bulwark-scaffold and /setup-lsp via printed post-init checklist — do NOT absorb skill logic into init.sh | SME, PDL, TA, CA | HIGH |
| Remove duplicate `standards-reviewer.md` from root `agents/` (byte-identical to `bulwark-standards-reviewer.md`) | PDL (discovered), verified by lead | HIGH |
| Remove test agents from `.claude/agents/` (code-analyzer.md, file-counter.md, test-validator.md) | SME, PDL, CA | HIGH |
| `sync-hooks-for-dev.sh` stays separate — dev-only, NOT part of init pipeline | SME, PDL, TA | HIGH |
| init-rules.sh target path must change: `$TARGET/Rules.md` → `$TARGET/.claude/rules/rules.md` | SME, PDL, TA | HIGH |
| lib/templates/rules.md is stale — missing CN1/CN2 rules | SME, PDL | HIGH |
| AC17 cleanup: include in P7.1, use T-10 day threshold on every SessionStart (no session detection needed) | TA (proposed), PDL (conceded), CA (accepted) | HIGH |
| First-run hook failure (#10997): document restart requirement — no workaround available | SME, PDL, TA, CA | HIGH |
| Monolithic plugin for v1 — ship all skills + production agents, defer modular design | PDL, CA | HIGH |

## Divergence Areas

Where roles disagree — requires decision.

### CN1/CN2 Conditional Inclusion (2v1 — Unconditional wins)

- **Technical Architect**: Split into two files — `rules-core.md` (always) + `rules-cn.md` (LSP opt-in only). Aligns with modular `.claude/rules/` pattern. Governance-reality gap (rules directing use of uninstalled tool) is a real cost.
- **Product & Delivery Lead + Critical Analyst**: Include CN1/CN2 unconditionally in base `rules.md`. Rules are preference-based ("prefer LSP > Grep > Glob") and degrade gracefully without LSP. Conditional inclusion adds 4-6 hours of init.sh complexity for zero governance benefit. A user without LSP reads CN1, has no LSP, uses Grep — no failure occurs.
- **Lead decision**: **Unconditional inclusion.** The CN rules are written as preferences with a fallback hierarchy. They don't mandate LSP — they prefer it. Including them unconditionally:
  - Eliminates init.sh LSP intent prompt before mandatory steps
  - Eliminates maintaining two template files
  - Avoids the "re-run init to get cn-rules.md later" problem if user installs LSP after init
  - CN1 already states "Fall back to Grep only when LSP is unavailable"
  - The cost of a user seeing CN rules without LSP is zero — they'll naturally use Grep/Glob

### Timeout Units (SME vs Research Synthesis)

- **SME**: Claims 60000 is correct (milliseconds per Claude Code's JSON schema).
- **Research Synthesis (5 agents)**: Confirmed timeout is in seconds via official docs + cross-reference with lazyptc-mcp (uses `30`, `10`) and clear-framework (uses `60`, `30`). Bulwark's 60000 = 16.7 hours.
- **Critical Analyst**: Research synthesis already resolved this — 5 agents vs 1 SME reading. Don't treat as open.
- **TA + PDL**: Flag as must-verify before implementation.
- **Lead decision**: **The research synthesis is correct — timeouts are in seconds.** The cross-reference evidence (two independent plugins using single/double-digit values) is stronger than the SME's reading. However, this is trivially verifiable: test a hook with `timeout: 5` vs `timeout: 5000` and observe behavior. **Action: fix to 60/30/5 in P7.1, verify empirically during validation session.**

### Product-Ideation Skill + Agents Distribution

- **Critical Analyst (discovered post-debate)**: 6 product-ideation agents + markdown-reviewer exist in `.claude/agents/` but NOT in root `agents/`. Possible unintentional exclusion.
- **User correction**: The AT flagged the agents but missed the skill — the `product-ideation` skill also exists only in `.claude/skills/`, not in root `skills/`. Both the skill and its 6 agents must be copied to root directories for plugin distribution.
- **Lead decision (user-confirmed)**: Copy `product-ideation` skill to root `skills/` and its 6 agents (`product-ideation-idea-validator`, `product-ideation-market-researcher`, `product-ideation-competitive-analyzer`, `product-ideation-segment-analyzer`, `product-ideation-pattern-documenter`, `product-ideation-strategist`) to root `agents/`. **Drop `markdown-reviewer`** — not needed for plugin distribution. Exclude test agents: code-analyzer.md, file-counter.md, test-validator.md.

### Plugin Directory Convention (User Decision)

- **CA Alternative 3**: Change `plugin.json` agents path to `.claude/agents/` to avoid maintaining two directories.
- **User decision**: This is not a preference question — it's a plugin format constraint. The Claude Code plugin reference defines root `agents/` and `skills/` as the plugin convention. `.claude/` directories are Claude Code internal paths, not plugin distribution paths. **Maintain root `agents/` and `skills/` as the plugin source.** Copy missing assets from `.claude/` to root directories during P7.1.

## Debate Dynamics

The AT peer debate produced several valuable outcomes:

1. **AC17 deferral reversed through debate**: PDL initially recommended deferring AC17 from P7.1 (data-loss risk from session detection). TA challenged: "T-10 day threshold IS the session guard — files under 10 days are never at risk." PDL conceded. This resolved a scope question that would have persisted as an open issue in sequential mode.

2. **agents/ directory error self-corrected**: CA's initial analysis claimed root `agents/` didn't exist (highest-risk finding). PDL challenged with codebase evidence. CA self-corrected within one debate round and pivoted to the real gap: product-ideation agents missing from shipped set. Sequential mode would have propagated the error into synthesis unchallenged.

3. **CN unconditional inclusion emerged from convergence**: PDL initially aligned with TA's split-file approach. CA's challenge ("preference rules degrade gracefully") convinced PDL to switch. This 2v1 convergence would not have occurred in sequential mode where the Critic runs last.

4. **Timeout units debate resolved by evidence weight**: CA's argument (5 research agents vs 1 SME) cut through the "verify first" caution from TA and PDL. In sequential mode, this would remain an open question requiring a separate verification session.

## Critical Analyst Verdict

**Verdict**: MODIFY
**Confidence**: HIGH
**Conditions**:
- CN1/CN2 conditional inclusion is simplified (unconditional — resolved above)
- Init script stays thin (mandatory copy steps + printed delegation)
- Product-ideation skill copied to root `skills/` + its 6 agents copied to root `agents/` (markdown-reviewer dropped)
- Duplicate standards-reviewer.md removed from root `agents/`
- Timeout values corrected to seconds (60/30/5)
- test-validator.md removed alongside code-analyzer.md, file-counter.md
- `init-project-rules.sh` descoped — CLAUDE.md injection redundant with `.claude/rules/` auto-loading (see below)

## Problem Validation

From Critical Analyst: P7.1 is unambiguously worth solving. The plugin is functionally ready — hooks fire, skills exist, agents exist. Without P7.1, Bulwark remains a local dev tool. The investment is commensurate: mostly integration and orchestration of existing components, not new feature development. No kill criteria identified — risks are execution risks, not strategic risks.

## Implementation Outline

### v1 Scope (P7.1 Mandatory)

**Correctness fixes (no design decisions, do first):**
1. Sync CN1/CN2 to `lib/templates/rules.md` (unconditionally — no split file)
2. Remove duplicate `agents/standards-reviewer.md` (keep `bulwark-standards-reviewer.md`)
3. Copy missing assets to root plugin directories:
   - `agents/`: product-ideation-* (6 agents)
   - `skills/`: product-ideation skill
   - Drop: markdown-reviewer (not needed for plugin)
4. Remove test agents from `.claude/agents/`: code-analyzer, file-counter, test-validator
5. Fix timeout values: hooks/hooks.json (60000→60, 30000→30, 5000→5) + .claude/settings.json
6. Descope `init-project-rules.sh` from init pipeline — `lib/templates/claudemd-injection.md` injects Binding Contract + "Read Rules.md" enforcement into CLAUDE.md, but both are redundant with `.claude/rules/rules.md` auto-loading. All rules are in Rules.md; the CLAUDE.md injection adds no governance value. The user's CLAUDE.md should remain minimal (project-specific config only).

**Init pipeline (design work):**
7. Update `init-rules.sh` target: `$TARGET/Rules.md` → `$TARGET/.claude/rules/rules.md`
8. Create `scripts/init.sh` — thin orchestrator:
   - Mandatory: `init-rules.sh` (copies rules.md to `.claude/rules/`)
   - Post-init printed checklist: "Run `/setup-lsp` for LSP support (recommended)", "Run `/bulwark-scaffold` for Justfile generation (recommended)"
9. Create `scripts/hooks/cleanup-stale.sh` (AC17):
   - `find logs/ tmp/ -type f -mtime +10 -not -name '.gitkeep' -delete`
   - Add as second SessionStart hook in hooks.json, timeout: 30
10. Add marketplace metadata to plugin.json (repository, homepage, license, keywords)
11. Document first-run hook failure: user must restart session after plugin install

**Distribution (v1 — P7.1):**
12. GitHub org created: **Q-Ball-Inc** (`github.com/Q-Ball-Inc`)
13. Transfer `the-bulwark` repo to org (GitHub Settings → Transfer) — preserves history, issues, redirects old URLs
14. Create umbrella marketplace repo (`Q-Ball-Inc/claude-plugins`) with `.claude-plugin/marketplace.json`:
    - Marketplace name: **`qball-inc`**
    - Lists the-bulwark with GitHub source (`"source": "github", "repo": "Q-Ball-Inc/the-bulwark"`)
    - npm source as alternative: (`"source": "npm", "package": "@qball-inc/the-bulwark"`)
    - Extensible: Clear Framework and future plugins added to same marketplace
15. Publish to npm: `npm publish` (package.json already exists at repo root)
16. Version bump to `1.0.0` in both plugin.json and package.json
17. Submit to official Anthropic marketplace (non-blocking — review timeline unknown):
    - Via `claude.ai/settings/plugins/submit` or `platform.claude.com/plugins/submit`

**User install experience (v1):**
```
# Self-hosted marketplace (immediate availability)
/plugin marketplace add Q-Ball-Inc/claude-plugins
/plugin install the-bulwark@qball-inc
# Restart Claude Code session (first-run hook fix #10997)
# Run /the-bulwark:init or scripts/init.sh for project governance
```

**Deferred from P7.1:**
- Homebrew tap distribution (macOS convenience, not blocking)
- Statusline delegation in init (cosmetic, low value)
- Automated init tests (manual protocol sufficient for launch)
- Modular plugin design (ship monolithic v1, learn from adoption)
- Version update mechanism ("/bulwark:update" or re-run init)

### Architecture (from Architect)

```
init.sh (thin orchestrator — prompts, calls atomic scripts, prints checklist)
  ├── MANDATORY: init-rules.sh → .claude/rules/rules.md
  └── PRINTED CHECKLIST:
       ├── "Run /setup-lsp for LSP support (recommended)"
       ├── "Run /bulwark-scaffold for Justfile + project tooling (recommended)"
       └── "Restart Claude Code session for hooks to take effect"

hooks/hooks.json:
  SessionStart:
    - inject-protocol.sh (timeout: 5)
    - cleanup-stale.sh (timeout: 30) ← NEW (AC17)
  PostToolUse (Write|Edit):
    - enforce-quality.sh (timeout: 60)
  SubagentStart:
    - track-pipeline-start.sh (timeout: 30)
  SubagentStop:
    - track-pipeline-stop.sh (timeout: 30)
```

Key design pattern: **Scripts handle file system operations. Skills handle AI-guided configuration.** The boundary is firm — init.sh never invokes a skill, and skills never duplicate init.sh's file copy logic.

### Build Plan

**Session 1 — P7.1 Implementation:**
- Steps 1-6: Correctness fixes (~45 min, no design decisions)
- Steps 7-8: init.sh + init-rules.sh update (~2 hours)
- Step 9: cleanup-stale.sh + hooks.json update (~1 hour)
- Steps 10-11: plugin.json metadata + first-run doc (~30 min)

**Session 2 — P7.1 Validation:**
- Test init.sh on a fresh project directory
- Verify governance files land in `.claude/rules/`
- Verify init.sh does NOT touch CLAUDE.md (descoped)
- Verify cleanup-stale.sh preserves files <10 days old
- Verify test agents excluded, product-ideation skill + agents included in root dirs
- Verify timeout correction (empirical test: does a 5-second timeout actually timeout in ~5s?)
- `claude plugin validate .` to verify plugin structure
- `claude --plugin-dir ./` to test locally

**Session 3 — Distribution Setup (can overlap with Session 2):**
- Create GitHub org + transfer/fork repo
- Create umbrella marketplace repo with marketplace.json
- Publish to npm (`npm publish`)
- Version bump to 1.0.0
- Submit to official Anthropic marketplace
- Test end-to-end: `/plugin marketplace add org/claude-plugins` → `/plugin install`

**Estimated: 3 sessions (2 impl/validation + 1 distribution)**

## P7.2 Documentation Scope (Brainstorm Required)

P7.2 is a separate task requiring its own brainstorm. Scope markers from user input:

**Central README.md** (repo root):
- Background and motivation
- Architecture overview
- Advantages / value proposition
- Installation instructions (marketplace + npm + local)
- Skill registry table (hyperlinked to individual docs)
- Agent registry table (hyperlinked to individual docs)

**Individual documentation** (in `docs/skills/` and `docs/agents/`):
- One readme per skill (28 skills)
- One readme per agent (production agents only)
- Consistent template across all docs

**Documentation lives in `docs/`, NOT in plugin directories.** The `skills/`, `agents/`, and `.claude-plugin/` directories contain code only — no readmes. This keeps the plugin payload clean.

**Open questions for P7.2 brainstorm:**
- Template structure for skill/agent docs (sections, format)
- Auto-generation from SKILL.md/agent frontmatter vs manual authoring
- Architecture diagram format (Mermaid? ASCII?)
- `docs/` subdirectory structure vs flat `docs/skills/*.md`
- Whether hooks documentation belongs in `docs/hooks.md` or central README

## Risks and Mitigations

| Risk | Source Role | Severity | Mitigation |
|------|-----------|----------|------------|
| First-run hook failure (#10997) breaks first impression | CA | HIGH | Document restart requirement prominently in README + init.sh output |
| Timeout correction direction wrong (ms vs s) | TA, PDL | MEDIUM | Empirical test during validation session — trivially verifiable |
| init-project-rules.sh + claudemd-injection.md now unused | CA (flagged), User (descoped) | LOW | Descoped — CLAUDE.md injection redundant with .claude/rules/ auto-loading. Keep files for reference but remove from init pipeline. |
| No rollback for partial init failure | CA | LOW | Document manual rollback (.backup files exist). Full rollback mechanism deferred. |
| 198-line Rules.md may be too long for external users without MEMORY.md context | CA | LOW | Already validated at Jefferies (clean environment). Monitor post-launch. |
| Plugin version updates don't propagate to copied governance files | CA | LOW | Thin-copy principle: users own their copy. Document update procedure. |

## Open Questions

Resolved by this brainstorm + user review — no remaining open questions for P7.1 implementation:

1. ~~CN conditional inclusion~~ → Unconditional. Include in base rules.md.
2. ~~AC17 scope~~ → Include in P7.1. T-10 threshold, every SessionStart.
3. ~~agents/ directory~~ → Root agents/ exists. Copy missing product-ideation agents (6). Drop markdown-reviewer.
4. ~~skills/ directory~~ → Copy product-ideation skill to root skills/ (AT missed this gap — user caught it).
5. ~~Timeout units~~ → Seconds. Fix 60000→60, 30000→30, 5000→5. Verify empirically.
6. ~~Init UX~~ → Bash script (init.sh) with printed post-init skill delegation checklist.
7. ~~Monolithic vs modular~~ → Monolithic for v1.
8. ~~Justfile delegation~~ → Print recommendation to run /bulwark-scaffold.
9. ~~Plugin directory convention~~ → Root `agents/` and `skills/` are the plugin convention (not `.claude/`). User decision: this is a format constraint, not a preference.
10. ~~CLAUDE.md injection (claudemd-injection.md)~~ → Descoped. Redundant with `.claude/rules/rules.md` auto-loading. All rules centralized in Rules.md. init-project-rules.sh removed from init pipeline.
