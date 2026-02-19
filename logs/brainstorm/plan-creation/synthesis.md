---
topic: "P5.13 Plan-Creation Skill — Agent Teams Dual-Mode"
phase: brainstorm
agents_synthesized: 5
overall_verdict: modify
verdict_source: critical-analyst
---

# P5.13 Plan-Creation Skill — Brainstorm Synthesis

## Consensus Areas

Where all roles agree — foundation for implementation.

| Area | Supporting Roles | Confidence |
|------|-----------------|------------|
| The plan-creation skill should be built | All 5 | HIGH |
| Task tool mode first, using bulwark-brainstorm as structural template (80% reuse) | All 5 | HIGH |
| Output is an implementation plan (phases, workpackages, milestones, dependencies), NOT task briefs | All 5 | HIGH |
| 5 scrum team roles: PO, Architect, Eng Lead, Delivery Lead, QA/Critic | SME, PM, Architect, Dev Lead | HIGH (Critic questions whether 5 is too many) |
| Self-contained skill directory: SKILL.md + references/role-*.md + templates/ | All 5 | HIGH |
| SA2 compliance: artifacts to logs/, mailbox for coordination only | All 5 | HIGH |
| Hybrid plan format: Markdown preamble + YAML body | Architect (primary), SME, PM | HIGH |
| PO runs first via Task tool in both modes (codebase exploration is solo) | Architect, Dev Lead | HIGH |
| Skill must be portable across 3 contexts (CLEAR, standalone, Bulwark) | All 5 | HIGH |
| Diagnostic YAML mandatory | All 5 | HIGH |
| Pre-flight env var detection for Agent Teams (fail fast, not at spawn time) | Architect, Dev Lead, Critic | HIGH |

## Divergence Areas

Where roles disagree — requires decision.

### Divergence 1: Agent Teams — Build Now vs. Validate First

- **SME, Architect, Dev Lead**: Build both modes (Task tool + Agent Teams) in Sessions 1-2. Agent Teams is the proving ground per P5.13's explicit mandate.
- **PM**: Build both, but reframe Agent Teams as "enhanced" not "primary." Task tool is the reliable default.
- **Critic**: Do NOT build Agent Teams mode until a comparative test validates the hypothesis that peer debate improves plan quality. Build Task tool first (Session 1), run a comparative test, then conditionally build Agent Teams (Session 2) only if quality improvement is demonstrated.
- **Decision needed**: Build Agent Teams mode alongside Task tool, or gate it behind empirical validation?

### Divergence 2: 5 Roles vs. 3 Roles

- **SME, PM, Architect, Dev Lead**: 5 roles with sharp boundaries to prevent overlap.
- **Critic**: 5 agents exceeds the research-validated 3-4 coordination cap. Proposes collapsing to 3: (1) PO/Scope, (2) Architect/Implementation, (3) QA/Critic. Eliminates overlap risk, reduces token cost by 40%.
- **Decision needed**: Keep 5 roles or collapse to 3?

### Divergence 3: Agent Teams as "Primary" vs. "Enhanced"

- **Pre-brainstorm alignment**: Agent Teams is "primary mode."
- **PM, Critic**: Task tool should be "primary" (works for everyone, production-stable). Agent Teams should be "enhanced" (opt-in, experimental, higher cost). This is a resource allocation question, not just labeling.
- **Decision needed**: Which framing governs implementation priority?

### Divergence 4: Session Estimate

- **tasks.yaml**: 2 sessions
- **Dev Lead**: 3 sessions (Task tool + Agent Teams + Testing)
- **Critic**: 2 sessions (Task tool only) + 1 conditional (Agent Teams after validation)
- **Decision needed**: How many sessions, and is Agent Teams session conditional?

### Divergence 5: CLEAR Compatibility Urgency

- **Architect**: Design YAML output format compatible with CLEAR's MasterPlan type interface now. Field mapping to `parseMasterPlanContent()`.
- **Critic**: CLEAR is on hiatus with no resumption timeline. Designing for CLEAR compatibility now is premature optimization.
- **Decision needed**: Design for CLEAR compatibility proactively, or keep the hybrid format on its own merits?

## Critical Analyst Verdict

**Verdict**: Modify
**Confidence**: High
**Conditions**: Task tool ships as v1; Agent Teams deferred until one empirical comparison validates quality improvement; role overlap monitored in first test run.

**Highest-Risk Assumption**: Agent Teams peer debate produces measurably better plans than Task tool sequential analysis. Zero empirical evidence exists for this claim in this codebase. The research synthesis rates "peer debate improvement quantification" as LOW confidence.

**Key challenge**: Building both modes simultaneously front-loads speculative investment before validating the core hypothesis. A single comparative run (same topic, both modes, blind quality comparison) would validate the assumption at a fraction of the implementation cost.

## Implementation Outline

### v1 Scope (from PM, modified by Critic)

**MUST HAVE (Session 1):**
- Task tool mode with scrum team pipeline
- Scrum team role definitions in `references/role-*.md`
- Hybrid plan output format (Markdown preamble + YAML body)
- Plan-mode explore-then-commit workflow with approval gate
- Pre-flight with env var detection (for future Agent Teams)
- SA2-compliant log output
- Diagnostic YAML
- Self-contained, portable directory structure

**CONDITIONAL (Session 2, gated on comparative test):**
- Agent Teams mode with delegate-mode lead
- Dual-output contract in teammate prompts (logs + mailbox)
- Agent Teams-specific synthesis path
- Graceful degradation when env var absent

**DEFERRED:**
- Plan management (progress tracking, blocker detection) — CLEAR's responsibility
- Workpackage decomposition — downstream tooling
- Tmux split-pane mode
- Multi-project plan aggregation
- Plan versioning/diffing

### Architecture (from Architect)

Sandwich structure with mode bifurcation at Stage 3:

```
Stage 1: Pre-Flight (SHARED) — parse input, detect mode, AskUserQuestion
Stage 2: Context Gathering (SHARED) — PO explores codebase via Task tool
Stage 3A: Task Tool Mode — [Architect, Eng Lead, Delivery Lead] parallel → QA/Critic last
Stage 3B: Agent Teams Mode — 4 teammates debate via mailbox, QA/Critic active throughout
Stage 4: Synthesis (SHARED, mode-aware input) — plan artifact + approval gate
Stage 5: Diagnostics (SHARED)
```

Key architectural decisions:
- PO always runs via Task tool (solo codebase exploration, no debate benefit)
- QA/Critic participates throughout in Agent Teams mode (not gated last)
- Single plan output template for both modes (enables quality comparison)
- No shared abstraction between modes (premature, not reusable by P5.15)

### Build Plan (from Dev Lead, modified by Critic)

| Session | Scope | Risk |
|---------|-------|------|
| Session 1 | Task tool mode + all scaffolding | Low (80% brainstorm reuse) |
| Between sessions | Comparative test: same topic, Task tool vs ad-hoc Agent Teams | Low cost (~1 hour) |
| Session 2 (conditional) | Agent Teams mode OR reallocate to P5.3/P5.15 | Medium (first-ever AT integration) |
| Session 3 | Manual testing of both modes, anthropic-validator | Low |

## Risks and Mitigations

| Risk | Source Role | Severity | Mitigation |
|------|-----------|----------|------------|
| Agent Teams peer debate shows no quality improvement | Critic | HIGH | Comparative test before building AT mode |
| SA2 compliance in Agent Teams mode via prompt | All | MEDIUM | Dual-output contract + post-completion log file verification |
| 5-role scrum team overlap (PO/Delivery, Architect/Eng) | Dev Lead, Critic | MEDIUM | Sharp role definitions with "DO NOT cover" boundaries; monitor in first test run |
| Agent Teams API instability (experimental) | Dev Lead | HIGH | Task tool fallback; version-lock; keep AT code isolated |
| Lead context compaction orphans teammates | Research synthesis | HIGH | 4 active teammates (within cap); cleanup instructions; verify completion |
| Token cost ~2x in Agent Teams mode | Research synthesis | LOW | Pre-flight warning; accept as cost of peer debate |
| CLEAR compatibility is premature | Critic | LOW | Keep hybrid format on own merits; don't over-invest in CLEAR field mapping |

## Open Questions

Decisions needed from user before proceeding to task brief:

1. **Agent Teams: build now or validate first?** The Critic's comparative-test-first approach adds ~1 hour of manual effort between sessions but prevents up to 2 sessions of potentially wasted work. The counter-argument (from SME, Architect, Dev Lead) is that P5.13 was explicitly designed as the Agent Teams proving ground.

2. **5 roles or 3 roles?** The Critic proposes collapsing to 3 (PO/Scope, Architect/Implementation, QA/Critic). The PM and Dev Lead argue the 5 roles are the product differentiator. The Delivery Lead role (schedule, milestones) is the most distinctive addition over brainstorm's existing 5 roles.

3. **"Primary" vs. "Enhanced" framing?** PM and Critic both argue Task tool should be primary. This affects which mode gets optimized first and which gets the most testing attention.

4. **Session estimate?** 2 (Task tool only + testing) or 3 (both modes + testing) or 2+1 conditional (Task tool + conditional Agent Teams)?

5. **CLEAR compatibility depth?** Design YAML body for CLEAR's MasterPlan interface proactively, or keep the hybrid format on its own merits and let CLEAR build the adapter later?

## Post-Synthesis Decisions

*User input incorporated after synthesis review. Classifications per Critical Evaluation Gate.*

### Decision 1: Build Both Modes Together — User Preference

> **User**: Build both modes (Task tool + Agent Teams) as planned.

**Classification**: Preference — scope/priority decision, no validation needed.

**Impact**: Overrides Critic's "comparative test first" recommendation. P5.13 retains its proving-ground mandate. Session plan: Session 1 (Task tool), Session 2 (Agent Teams), Session 3 (testing). The Critic's kill criteria remain valid — if Agent Teams mode fails SA2 compliance or shows no quality improvement in testing, it can be descoped.

### Decision 2: 4 Roles (Compromise) — User Preference

> **User**: 4 roles — PO, Architect, Eng+Delivery Lead (combined), QA/Critic.

**Classification**: Preference — team structure decision, no validation needed.

**Impact**: Merges the two most overlapping roles (Engineering Lead + Delivery Lead) into a single role that covers implementation sequencing, effort estimation, scheduling, milestones, and dependencies. This addresses the Critic's concern about exceeding the 3-4 agent coordination cap (now 4 agents, within bounds) while preserving the PM's point that distinct roles are the product differentiator. The PO retains its distinct requirements/scope focus, and the Architect retains its design focus.

**Updated role list**:
1. **Product Owner** — Requirements, scope, acceptance criteria, user value
2. **Technical Architect** — System design, component decomposition, integration
3. **Engineering & Delivery Lead** — Implementation sequencing, effort estimation, scheduling, milestones, dependencies, risk
4. **QA / Critic** — Challenge assumptions, identify gaps, kill criteria, adversarial review

### Decision 3: Enhanced/Opt-in Framing — User Preference

> **User**: Task tool is default for everyone. Agent Teams is opt-in enhanced mode.

**Classification**: Preference — aligns with PM + Critic recommendation, no validation needed.

**Impact**: Task tool is the default mode (production-stable, universal). Agent Teams is activated only when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is set AND the user explicitly requests it. This means pre-flight detects the env var but does NOT automatically switch — it offers the option. Updates the pre-brainstorm alignment language from "Agent Teams as primary" to "Agent Teams as enhanced/opt-in."

### Decision 4: Proactive CLEAR Compatibility — User Preference

> **User**: Design YAML body fields to match CLEAR's MasterPlan interface proactively.

**Classification**: Preference — user owns both projects, no validation needed.

**Impact**: Overrides Critic's "premature optimization" concern. The YAML body in the plan output template will use field names compatible with CLEAR's `MasterPlan` type interface (`phases[].id`, `phases[].status`, `milestones[].type`, `milestones[].requires`). This is a low-cost decision (choosing field names) with high future value (no adapter needed when CLEAR resumes). Does NOT create a hard dependency — the skill doesn't import CLEAR types.

## Revised Implementation Summary

Based on all 5 agent outputs + 4 post-synthesis decisions:

| Aspect | Decision |
|--------|----------|
| **Build scope** | Both modes — Task tool (Session 1) + Agent Teams (Session 2) + Testing (Session 3) |
| **Team size** | 4 roles: PO, Architect, Eng+Delivery Lead, QA/Critic |
| **Mode framing** | Task tool = default. Agent Teams = enhanced/opt-in |
| **Plan format** | Hybrid: Markdown preamble + YAML body (CLEAR-compatible field names) |
| **Architecture** | Sandwich: shared Pre-Flight/Synthesis bookend mode-specific Stage 3 |
| **PO execution** | Always via Task tool (codebase exploration is solo, both modes) |
| **QA/Critic in AT mode** | Active participant throughout (not gated last) |
| **SA2 compliance** | Dual-output contract: logs/ for artifacts, mailbox for coordination |
| **Sessions** | 3 (revised from tasks.yaml's 2) |
| **Kill criteria** | Critic's 5 kill criteria remain valid as safety net |

## Incomplete Coverage

All 5 agents completed successfully. No gaps.
