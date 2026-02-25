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
| 1 | Skill loaded from `/bulwark-brainstorm` invocation | | |
| 2 | Mode detection performed — env var checked | | |
| 3 | Default mode selected as --scoped (even if AT env var is set) | | |
| 4 | AskUserQuestion used to clarify scope (or noted as skipped with reason) | | |
| 5 | If --research not provided, user warned | | |
| 6 | Output directory created: `logs/brainstorm/{slug}/` | | |
| 7 | subagent-prompting skill loaded | | |
| | **Project SME (Stage 2)** | | |
| 8 | SME spawned as general-purpose Opus agent | | |
| 9 | SME explored codebase autonomously (Glob/Grep/Read, no hardcoded paths) | | |
| 10 | SME output written to `logs/brainstorm/{slug}/01-project-sme.md` | | |
| | **Role Analysis (Stage 3A — --scoped)** | | |
| 11 | PM, Architect, Dev Lead spawned in **parallel** (single message, 3 Task tool calls) | | |
| 12 | All 3 received SME output in their prompt context | | |
| 13 | PM output written to `logs/brainstorm/{slug}/02-product-manager.md` | | |
| 14 | Architect output written to `logs/brainstorm/{slug}/03-technical-architect.md` | | |
| 15 | Dev Lead output written to `logs/brainstorm/{slug}/04-development-lead.md` | | |
| | **Critical Analyst (Stage 4 — --scoped only)** | | |
| 16 | Critical Analyst spawned with ALL 4 prior outputs (SME + PM + Architect + Dev Lead) | | |
| 17 | Critic output written to `logs/brainstorm/{slug}/05-critical-analyst.md` | | |
| 18 | Critic output includes new **Problem Validation** section (FR5) | | |
| 19 | Critic produced verdict (proceed/modify/defer/kill) | | |
| 20 | Critic challenged at least one assumption from a prior role | | |
| | **Synthesis (Stage 5)** | | |
| 21 | ALL 5 log files read before synthesis started | | |
| 22 | Synthesis written to `artifacts/brainstorm/{slug}/synthesis.md` | | |
| 23 | Synthesis YAML header includes `mode: scoped` | | |
| 24 | Synthesis has: Consensus Areas, Divergence Areas, Critical Analyst Verdict, Problem Validation, Implementation Outline, Risks and Mitigations, Open Questions | | |
| 25 | AskUserQuestion used for post-synthesis review | | |
| 26 | Critical Evaluation Gate applied to user responses (classified as Preference/Technical Claim/Architectural Suggestion) | | |
| | **Diagnostics (Stage 6)** | | |
| 27 | Diagnostic YAML written to `logs/diagnostics/bulwark-brainstorm-{timestamp}.yaml` | | |
| 28 | Diagnostic records mode: scoped | | |
| 29 | Diagnostic records all 5 agents with status, model, output_file | | |
| 30 | Diagnostic includes mode_detection block (env_var_set, user_requested, effective_mode) | | |

**TC1 Result**: _____ / 30

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
| 1 | Skill loaded from `/bulwark-brainstorm --exploratory` invocation | | |
| 2 | Mode detection performed — env var checked (MUST be set) | | |
| 3 | AT Confirmation Flow executed — token cost warning displayed | | |
| 4 | Model class choice offered (Opus / Sonnet / Switch to --scoped) | | |
| 5 | User's model choice recorded for Stage 3B | | |
| 6 | AskUserQuestion used to clarify scope (or noted as skipped) | | |
| 7 | If --research not provided, user warned | | |
| 8 | Output directory created: `logs/brainstorm/{slug}/` | | |
| 9 | subagent-prompting skill loaded | | |
| 10 | `references/at-teammate-prompts.md` loaded for Stage 3B | | |
| | **Project SME (Stage 2 — identical to TC1)** | | |
| 11 | SME spawned as general-purpose Opus agent via Task tool | | |
| 12 | SME explored codebase autonomously | | |
| 13 | SME output written to `logs/brainstorm/{slug}/01-project-sme.md` | | |
| | **Role Analysis (Stage 3B — --exploratory)** | | |
| 14 | Delegate mode entered (lead does NOT perform analysis) | | |
| 15 | 3 AT teammates spawned: Product & Delivery Lead, Architect, Critical Analyst | | |
| 16 | Teammates spawned with user's chosen model class | | |
| 17 | Each teammate prompt includes dual-output contract (SA2) | | |
| 18 | Each teammate prompt includes peer debate directives | | |
| 19 | Each teammate prompt includes AT mitigation patterns (CC-to-lead, task list, completion signal) | | |
| 20 | Product & Delivery Lead output written to `logs/brainstorm/{slug}/02-product-delivery-lead.md` | | |
| 21 | Architect output written to `logs/brainstorm/{slug}/03-technical-architect.md` | | |
| 22 | Critical Analyst output written to `logs/brainstorm/{slug}/04-critical-analyst.md` | | |
| 23 | Observable peer debate — at least one teammate explicitly references and disputes another's position | | |
| 24 | Critical Analyst includes "Debate Influence" section in log output | | |
| 25 | Critical Analyst deferred final verdict until all summaries received | | |
| 26 | "WORK COMPLETE" messages received from all 3 teammates | | |
| | **Stage 4 skipped** | | |
| 27 | Stage 4 (sequential Critic) NOT executed — Critic was AT teammate in Stage 3B | | |
| | **Synthesis (Stage 5)** | | |
| 28 | ALL 4 log files read before synthesis started (not 5 — exploratory has 4) | | |
| 29 | Synthesis written to `artifacts/brainstorm/{slug}/synthesis.md` | | |
| 30 | Synthesis YAML header includes `mode: exploratory` | | |
| 31 | Synthesis includes **Debate Dynamics** section (--exploratory only) | | |
| 32 | Debate Dynamics captures: where teammates disagreed, positions that evolved, unresolved disagreements | | |
| 33 | AskUserQuestion used for post-synthesis review | | |
| | **Diagnostics (Stage 6)** | | |
| 34 | Diagnostic YAML written to `logs/diagnostics/bulwark-brainstorm-{timestamp}.yaml` | | |
| 35 | Diagnostic records mode: exploratory | | |
| 36 | Diagnostic includes agent_teams block (display_mode, delegate_mode, teammate_count, teammate_model, peer_challenges_observed) | | |
| 37 | Diagnostic includes mode_detection block | | |

**TC2 Result**: _____ / 37

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
| 1 | Output structure: TC1 has 5 files, TC2 has 4 | |
| 2 | TC2 Critic output includes "Debate Influence" section (absent in TC1) | |
| 3 | TC2 synthesis includes "Debate Dynamics" section (absent in TC1) | |
| 4 | TC2 produces at least one risk or objection NOT present in TC1 | |
| 5 | TC2 demonstrates positions that evolved during debate (Post-Debate Updates) | |
| 6 | Token consumption: TC2 within 1.5-2.5x of TC1 | |

---

## Overall Assessment

| Test Case | Result | Checks |
|-----------|--------|--------|
| TC1 (--scoped regression) | | /30 |
| TC2 (--exploratory AT) | | /37 |
| TC3 (graceful degradation) | | /3 |
| TC4 (side-by-side) | | /6 |
| **Total** | | /76 |

### Verdict

- [ ] P5.15 PASS — all TCs pass (PARTIAL on cosmetic items acceptable)
- [ ] P5.15 FAIL — blocking issues found

### Issues Found

{Document any issues requiring fixes here}

### Learnings

{Document any learnings for MEMORY.md here}
