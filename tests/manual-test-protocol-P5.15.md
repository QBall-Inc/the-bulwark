# Manual Test Protocol: P5.15 — Brainstorm Dual-Mode (--scoped / --exploratory)

## Test Strategy

Same topic through both modes for direct comparison. TC1 validates --scoped regression (unchanged behavior). TC2 validates --exploratory with AT peer debate. Side-by-side comparison confirms --exploratory produces qualitatively different (not just reworded) analysis.

## Test Environment

| Test Case | Project | Skill Location | Reason |
|-----------|---------|----------------|--------|
| TC1 (--scoped) | PM-Essentials (`/home/ashay/projects/PM-Essentials`) | `.claude/skills/bulwark-brainstorm/` | Clean environment, no governance hooks, isolates skill behavior |
| TC2 (--exploratory) | PM-Essentials (`/home/ashay/projects/PM-Essentials`) | `.claude/skills/bulwark-brainstorm/` | Same project, same topic — enables direct comparison |

## Test Topic (Same for Both TCs)

```
"Add a plugin marketplace where users can discover, install, rate, and update community-contributed Claude Code plugins with version pinning, dependency resolution, and security review gating"
```

**Why this topic**: Requires real architectural thinking (marketplace backend, plugin registry, dependency graph), has product trade-offs (curation vs open contribution, security vs speed), involves delivery complexity (phased rollout, testing strategy), and is sufficiently open-ended that exploratory debate should surface genuine disagreements.

## Prerequisites

### Both TCs
1. Updated brainstorm skill copied to `/home/ashay/projects/PM-Essentials/.claude/skills/bulwark-brainstorm/` (SKILL.md + 7 references + 4 templates)
2. `.claude/skills/subagent-prompting/` available in PM-Essentials (skill dependency)
3. Fresh Claude Code session for each TC (separate sessions)

### TC2 Only
4. `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set in PM-Essentials `.claude/settings.json` or environment
5. No prior team sessions active (clean state)

---

## TC1: --scoped Mode (Regression)

**Purpose**: Validate that default --scoped mode produces identical behavior to pre-P5.15 brainstorm — 5 sequential agents (SME → 3 parallel → Critic), same output structure.

**Invocation**:
```
/bulwark-brainstorm "Add a plugin marketplace where users can discover, install, rate, and update community-contributed Claude Code plugins with version pinning, dependency resolution, and security review gating"
```

Note: No mode flag — tests default behavior (backward compatibility).

**Validation Checklist**:

| # | Check | Pass/Fail | Notes |
|---|-------|-----------|-------|
| | **Pre-Flight (Stage 1)** | | |
| 1 | Skill loaded from `/bulwark-brainstorm` invocation | PASS | |
| 2 | Mode detection performed — env var checked | PASS | Diagnostics: `env_var_set: true` |
| 3 | Default mode selected as --scoped (even if AT env var is set) | PASS | `user_requested: default`, `effective_mode: scoped` |
| 4 | AskUserQuestion used to clarify scope (or noted as skipped with reason) | PASS | Skipped: "problem statement sufficient" |
| 5 | If --research not provided, user warned | PASS | `research_file: null` in diagnostics |
| 6 | Output directory created: `logs/brainstorm/{slug}/` | PASS | `logs/brainstorm/plugin-marketplace/` |
| 7 | subagent-prompting skill loaded | PASS | Agents follow 4-part template structure |
| | **Project SME (Stage 2)** | | |
| 8 | SME spawned as general-purpose Opus agent | PASS | Diagnostics: `model: opus` |
| 9 | SME explored codebase autonomously (Glob/Grep/Read, no hardcoded paths) | PASS | 10 files explored with relevance notes |
| 10 | SME output written to `logs/brainstorm/{slug}/01-project-sme.md` | PASS | |
| | **Role Analysis (Stage 3A — --scoped)** | | |
| 11 | PM, Architect, Dev Lead spawned in **parallel** (single message, 3 Task tool calls) | PASS | All three show `stage: 3A` in diagnostics |
| 12 | All 3 received SME output in their prompt context | PASS | Each references SME findings/constraints |
| 13 | PM output written to `logs/brainstorm/{slug}/02-product-manager.md` | PASS | |
| 14 | Architect output written to `logs/brainstorm/{slug}/03-technical-architect.md` | PASS | |
| 15 | Dev Lead output written to `logs/brainstorm/{slug}/04-development-lead.md` | PASS | |
| | **Critical Analyst (Stage 4 — --scoped only)** | | |
| 16 | Critical Analyst spawned with ALL 4 prior outputs (SME + PM + Architect + Dev Lead) | PASS | References all 4 by name |
| 17 | Critic output written to `logs/brainstorm/{slug}/05-critical-analyst.md` | PASS | |
| 18 | Critic output includes new **Problem Validation** section (FR5) | PASS | Dedicated `## Problem Validation` section |
| 19 | Critic produced verdict (proceed/modify/defer/kill) | PASS | `defer` (high confidence), updated to `modify` after followup |
| 20 | Critic challenged at least one assumption from a prior role | PASS | Challenged demand, cost reduction, registry ownership, Anthropic competition |
| | **Synthesis (Stage 5)** | | |
| 21 | ALL 5 log files read before synthesis started | PASS | All 5 primary + 2 followup referenced |
| 22 | Synthesis written to `artifacts/brainstorm/{slug}/synthesis.md` | PASS | |
| 23 | Synthesis YAML header includes `mode: scoped` | PASS | |
| 24 | Synthesis has: Consensus Areas, Divergence Areas, Critical Analyst Verdict, Problem Validation, Implementation Outline, Risks and Mitigations, Open Questions | PASS | All sections present |
| 25 | AskUserQuestion used for post-synthesis review | PASS | `post_synthesis_rounds: "2"` |
| 26 | Critical Evaluation Gate applied to user responses (classified as Preference/Technical Claim/Architectural Suggestion) | PASS | `classification: technical-claim`, spawned 2 followup agents |
| | **Diagnostics (Stage 6)** | | |
| 27 | Diagnostic YAML written to `logs/diagnostics/bulwark-brainstorm-{timestamp}.yaml` | PASS | `bulwark-brainstorm-20260225-120000.yaml` |
| 28 | Diagnostic records mode: scoped | PASS | |
| 29 | Diagnostic records all 5 agents with status, model, output_file | PASS | 7 agents recorded (5 primary + 2 followup) |
| 30 | Diagnostic includes mode_detection block (env_var_set, user_requested, effective_mode) | PASS | All 4 fields present |

**TC1 Result**: 30 / 30 PASS

**TC1 Quality Notes**:
- Critical Evaluation Gate standout: Critic's initial `defer` verdict challenged by user with ecosystem evidence. Gate classified as `technical-claim`, spawned 2 targeted followup agents (Architect ecosystem validation + Critic re-evaluation). Verdict evolved defer→modify with full evidence trail.
- Critic quality exceptional: 4 ranked assumptions, 5 kill criteria, 3 simpler alternatives, gaps identified across proposals.
- Followup Architect verified 8/9 specific claims with URLs, metrics, context. Discovered Skills.sh (325K+ installs), 11 web registries, corporate participation.
- Synthesis correctly reframed from "build a marketplace" to "participate + differentiate" based on followup findings.
- Token consumption: ~78% (7 agents across 2 rounds).

---

## TC2: --exploratory Mode (Agent Teams Peer Debate)

**Purpose**: Validate that --exploratory mode spawns SME first via Task tool, then 3 AT teammates in delegate mode with peer debate, producing qualitatively different analysis from TC1.

**Invocation**:
```
/bulwark-brainstorm --exploratory "Add a plugin marketplace where users can discover, install, rate, and update community-contributed Claude Code plugins with version pinning, dependency resolution, and security review gating"
```

**Validation Checklist**:

| # | Check | Pass/Fail | Notes |
|---|-------|-----------|-------|
| | **Pre-Flight (Stage 1)** | | |
| 1 | Skill loaded from `/bulwark-brainstorm --exploratory` invocation | PASS | |
| 2 | Mode detection performed — env var checked (MUST be set) | PASS | Diagnostics: `env_var_set: true` |
| 3 | AT Confirmation Flow executed — token cost warning displayed | PASS | |
| 4 | Model class choice offered (Opus / Sonnet / Switch to --scoped) | PASS | User selected Opus |
| 5 | User's model choice recorded for Stage 3B | PASS | `teammate_model: "opus"` in diagnostics |
| 6 | AskUserQuestion used to clarify scope (or noted as skipped) | PASS | `pre_flight_interview: skipped` |
| 7 | If --research not provided, user warned | PASS | `research_file: null` in diagnostics |
| 8 | Output directory created: `logs/brainstorm/{slug}/` | PASS | `logs/brainstorm/plugin-marketplace/` |
| 9 | subagent-prompting skill loaded | PASS | Agents follow 4-part template structure |
| 10 | `references/at-teammate-prompts.md` loaded for Stage 3B | PASS | AT prompt structure used in teammate spawning |
| | **Project SME (Stage 2 — identical to TC1)** | | |
| 11 | SME spawned as general-purpose Opus agent via Task tool | PASS | Diagnostics: `model: opus`, `stage: 2` |
| 12 | SME explored codebase autonomously | PASS | 13 files explored with relevance notes |
| 13 | SME output written to `logs/brainstorm/{slug}/01-project-sme.md` | PASS | |
| | **Role Analysis (Stage 3B — --exploratory)** | | |
| 14 | Delegate mode entered (lead does NOT perform analysis) | PASS | `delegate_mode: true` in diagnostics |
| 15 | 3 AT teammates spawned: Product & Delivery Lead, Architect, Critical Analyst | PASS | All 3 show `stage: 3B` in diagnostics |
| 16 | Teammates spawned with user's chosen model class | PASS | All Opus per diagnostics |
| 17 | Each teammate prompt includes dual-output contract (SA2) | PASS | All 3 wrote to logs/ AND sent coordination summaries |
| 18 | Each teammate prompt includes peer debate directives | PASS | Post-Debate Update sections in all 3 outputs |
| 19 | Each teammate prompt includes AT mitigation patterns (CC-to-lead, task list, completion signal) | PASS | Evidenced by structured convergence |
| 20 | Product & Delivery Lead output written to `logs/brainstorm/{slug}/02-product-delivery-lead.md` | PASS | |
| 21 | Architect output written to `logs/brainstorm/{slug}/03-technical-architect.md` | PASS | |
| 22 | Critical Analyst output written to `logs/brainstorm/{slug}/04-critical-analyst.md` | PASS | |
| 23 | Observable peer debate — at least one teammate explicitly references and disputes another's position | PASS | 5 peer challenges observed; Product Lead has 2 Post-Debate Updates with explicit concessions to Critic |
| 24 | Critical Analyst includes "Debate Influence" section in log output | PASS | Dedicated section referencing Product Lead and Architect by name |
| 25 | Critical Analyst deferred final verdict until all summaries received | PASS | Upgraded from DEFER to MODIFY after reviewing all peer outputs |
| 26 | "WORK COMPLETE" messages received from all 3 teammates | PASS | All 3 completed successfully per diagnostics |
| | **Stage 4 skipped** | | |
| 27 | Stage 4 (sequential Critic) NOT executed — Critic was AT teammate in Stage 3B | PASS | No Stage 4 agent in diagnostics |
| | **Synthesis (Stage 5)** | | |
| 28 | ALL 4 log files read before synthesis started (not 5 — exploratory has 4) | PASS | `agents_synthesized: "4"` |
| 29 | Synthesis written to `artifacts/brainstorm/{slug}/synthesis.md` | PASS | |
| 30 | Synthesis YAML header includes `mode: exploratory` | PASS | |
| 31 | Synthesis includes **Debate Dynamics** section (--exploratory only) | PASS | Detailed 2-round dynamics with position evolution |
| 32 | Debate Dynamics captures: where teammates disagreed, positions that evolved, unresolved disagreements | PASS | Scope compression (6-9→3-4→2), DEFER→MODIFY evolution, unresolved Anthropic platform risk |
| 33 | AskUserQuestion used for post-synthesis review | PASS | `post_synthesis_rounds: "1"` |
| | **Diagnostics (Stage 6)** | | |
| 34 | Diagnostic YAML written to `logs/diagnostics/bulwark-brainstorm-{timestamp}.yaml` | PASS | `bulwark-brainstorm-20260225-223000.yaml` |
| 35 | Diagnostic records mode: exploratory | PASS | |
| 36 | Diagnostic includes agent_teams block (display_mode, delegate_mode, teammate_count, teammate_model, peer_challenges_observed) | PASS | All 5 AT-specific fields present |
| 37 | Diagnostic includes mode_detection block | PASS | All 4 fields present |

**TC2 Result**: 37 / 37 PASS

**TC2 Quality Notes**:
- Peer debate standout: Product & Delivery Lead compressed scope THREE times through debate (6-9 → 3-4 → 2 sessions), each with explicit concessions documented in "Post-Debate Update" sections.
- Critic evolved from DEFER to conditional MODIFY autonomously through debate — no user intervention needed (contrast with TC1 where user had to challenge the Critic).
- Problem Validation (FR5) worked well — Critic decomposed 6 sub-problems and individually assessed each (5 already solved, 1 genuine gap).
- 15 assumptions cataloged, ranked by P(wrong) x Impact, top 3 stress-tested.
- Token consumption: ~55% (4 agents, 0 followup rounds). More efficient than TC1 (~78%, 7 agents).
- Competitive landscape baked into initial analysis (270K+ SkillsMP, 57K+ skills.sh, 63K claude-plugins.dev) — not bolted on via followup as in TC1.

---

## TC3: Graceful Degradation (Optional — Quick Test)

**Purpose**: Verify that --exploratory without env var falls back to --scoped gracefully.

**Invocation** (with env var UNSET):
```
/bulwark-brainstorm --exploratory "test topic"
```

| # | Check | Pass/Fail | Notes |
|---|-------|-----------|-------|
| 1 | User notified: "Agent Teams requires CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1" | | |
| 2 | Automatic fallback to --scoped mode | | |
| 3 | Diagnostic records fallback_reason | | |

**TC3 Result**: _____ / 3

---

## TC4: Side-by-Side Comparison (Post TC1+TC2)

After both TC1 and TC2 complete on the same topic, compare:

| # | Comparison Point | Observation |
|---|-----------------|-------------|
| 1 | Output structure: TC1 has 5 files, TC2 has 4 | PASS — TC1: 5 primary + 2 followup = 7 files. TC2: 4 files (SME + 3 AT). Structurally different as expected. |
| 2 | TC2 Critic output includes "Debate Influence" section (absent in TC1) | PASS — Dedicated section referencing Product Lead and Architect positions by name, with explicit challenge/concession narrative. |
| 3 | TC2 synthesis includes "Debate Dynamics" section (absent in TC1) | PASS — 2-round dynamics documented: scope compression, position evolution, convergence narrative. |
| 4 | TC2 produces at least one risk or objection NOT present in TC1 | PASS — TC2 Critic decomposed 6 sub-problems individually (5 already solved, 1 genuine gap). TC1 Critic argued against demand generally without this structured decomposition. TC2 also cataloged 15 explicit assumptions with ranked risk scores. |
| 5 | TC2 demonstrates positions that evolved during debate (Post-Debate Updates) | PASS — Product Lead has 2 explicit Post-Debate Update sections showing 3 successive scope compressions (6-9 → 3-4 → 2 sessions). Critic evolved DEFER → conditional MODIFY. Architect position most stable (2-3 sessions throughout). |
| 6 | Token consumption: TC2 within 1.5-2.5x of TC1 | PASS — TC2 ~55% vs TC1 ~78%. TC2 was actually MORE efficient (0.7x), not 1.5-2.5x. AT peer debate resolved disagreements inline rather than requiring followup agents. |

**TC4 Key Finding**: TC2 (exploratory) arrived at the same conclusion as TC1 (scoped) — MODIFY, 2-3 sessions, marketplace adapter layer — but got there autonomously (no user intervention needed) and more efficiently (~55% vs ~78% tokens). The peer debate produced traceable convergence through explicit concessions, while TC1 required user challenge + 2 followup agents to overcome Critic's initial DEFER.

---

## Overall Assessment

| Test Case | Result | Checks |
|-----------|--------|--------|
| TC1 (--scoped regression) | PASS | 30/30 |
| TC2 (--exploratory AT) | PASS | 37/37 |
| TC3 (graceful degradation) | Not tested | /3 |
| TC4 (side-by-side) | PASS | 6/6 |
| **Total** | **PASS** | **73/73 tested** (TC3 not tested — optional, low risk) |

### Verdict

- [x] P5.15 PASS — all TCs pass (PARTIAL on cosmetic items acceptable)
- [ ] P5.15 FAIL — blocking issues found

TC3 (graceful degradation) not tested — optional quick test, low risk. Mode detection logic reuses P5.13's proven pattern.

### Issues Found

None. Both modes produced high-quality, well-structured analysis. No blocking issues.

### Learnings

1. **AT peer debate achieves autonomous convergence**: TC1 needed user intervention to challenge Critic's demand assumption. TC2's peer debate resolved the same disagreement organically through 2 rounds of targeted challenges. This is the primary value proposition of --exploratory mode.
2. **AT is more token-efficient for adversarial topics**: 4 AT agents (~55%) < 5+2 sequential agents (~78%). Peer debate resolves disagreements inline rather than requiring followup cycles.
3. **Post-Debate Updates are the key structural differentiator**: TC2's explicit concession trail (Product Lead's 3 compressions, Critic's verdict upgrade) provides audit-trail quality that sequential mode cannot produce.
4. **Dev Lead role is missed in exploratory mode**: TC1's dedicated Development Lead provided more concrete implementation detail (session-by-session plans, dependency graphs). TC2's combined Product & Delivery Lead prioritized scope/positioning over implementation mechanics. Consider whether --exploratory synthesis should note "implementation detail may be lighter — consider --scoped follow-up for build planning."
