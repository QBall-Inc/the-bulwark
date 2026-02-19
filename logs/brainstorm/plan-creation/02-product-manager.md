---
role: product-manager
topic: "P5.13 Plan-Creation Skill — Agent Teams Dual-Mode"
recommendation: proceed
key_findings:
  - Plan-creation delivers the highest user value in P1 (CLEAR Framework) where it is a core workflow feature, but the skill must ship functional in all 3 distribution contexts from v1 — portability is a product requirement, not a nice-to-have
  - Task tool mode is the v1 launch vehicle — it serves 100% of users immediately, while Agent Teams mode serves a subset gated on an experimental flag and willing to accept ~2x token cost
  - The 5-role scrum team is the product differentiator — without it, the skill is just "ask Claude to make a plan." The adversarial QA/Critic role and the Delivery Lead (missing from brainstorm's roles) are the highest-value additions
  - Scope must be ruthlessly bounded to plan CREATION — any plan management functionality (progress tracking, blocker detection, timeline adjustment) belongs to CLEAR's plan-management skill and must not leak into v1
---

# P5.13 Plan-Creation Skill — Senior Product Manager

## Summary

Plan-creation is a high-value skill with clear demand across all three distribution contexts. The dual-mode architecture (Agent Teams primary, Task tool fallback) is the right design, but the product strategy should prioritize Task tool mode as the launch-quality path while treating Agent Teams mode as a validated secondary path. The skill's competitive moat is the 5-role scrum team producing multi-perspective implementation plans — without that, it's a wrapper around "Claude, make me a plan."

## Detailed Analysis

### User Value Proposition

**P1 — CLEAR Framework (highest priority)**

Plan creation is a core workflow step in CLEAR. The framework's plan-management brief (`/mnt/c/projects/clear-framework/briefs/core/plan-management-feature-brief.md`) defines comprehensive plan infrastructure — master-plan.yaml, dependency DAGs, multi-signal progress tracking — but none of that infrastructure matters without a skill that produces the initial plan artifact. Plan-creation is the upstream dependency for CLEAR's entire plan management capability. When CLEAR resumes from hiatus, this skill unblocks the pipeline.

Measurable value: Without plan-creation, CLEAR users manually write plans. With it, they get a structured, multi-perspective plan produced by 5 specialist roles that catches scope gaps, sequencing errors, and resource conflicts that a single-pass plan misses.

**P2 — Essential Skills Standalone (medium priority)**

For users of the standalone Essential Skills repo (`https://github.com/ashaykubal/essential-agents-skills`), plan-creation is a general-purpose productivity skill. Any project that needs an implementation plan benefits. The value is independent of Bulwark or CLEAR — the skill takes a problem statement and produces a structured plan.

Measurable value: Reduces plan creation from an unstructured conversation to a structured multi-agent process. Users who currently plan by iterating with Claude in a single thread get 5 specialist perspectives instead of one generalist.

**P3 — Bulwark Plugin (lowest priority but strategic)**

For Bulwark, plan-creation is an optional add-on with strategic importance: it is the proving ground for Agent Teams. The direct user value (structured plans) is secondary to the architectural value (validating whether Agent Teams peer debate produces measurably better plans than Task tool sequential analysis).

Measurable value: Empirical comparison data between Agent Teams and Task tool modes. This data informs whether bulwark-brainstorm `--exploratory` (P5.15) should proceed with Agent Teams or pivot.

### Prioritization

Ranked by value-to-effort ratio:

**1. Task tool mode with 5-role scrum team (MUST HAVE)**
- User value: Functional plan-creation skill usable by 100% of users across all 3 contexts, zero dependency on experimental features.
- Who benefits: Every user. This is the baseline product.
- Cost of delay: Blocks CLEAR plan-management skill. Blocks Agent Teams validation. The entire P5.13 value proposition is deferred.
- Effort: MEDIUM — direct template from bulwark-brainstorm exists. Role definitions, output templates, and SKILL.md are net-new but follow established patterns.

**2. 5-role scrum team role definitions (MUST HAVE)**
- User value: The Product Owner catches scope creep and defines acceptance criteria. The Technical Architect decomposes into components. The Engineering Lead sequences work and estimates effort. The Delivery Lead (not present in brainstorm) adds schedule, milestones, and resource allocation — the operational dimension that pure technical planning misses. The QA/Critic is adversarial, challenging assumptions from all four preceding roles.
- Who benefits: Users who currently get single-perspective plans from Claude. The Delivery Lead and QA/Critic add the two perspectives most commonly absent from developer-generated plans.
- Cost of delay: Without defined roles, the skill is indistinguishable from a generic "make a plan" prompt. The roles ARE the product.

**3. CLEAR-compatible output format (MUST HAVE)**
- User value: Plans produced by the skill can be consumed by CLEAR's plan-management infrastructure without manual reformatting.
- Who benefits: P1 (CLEAR) users directly. P2/P3 users indirectly — the structured format (phases, workpackage IDs, milestones, dependency types) is useful even without CLEAR.
- Cost of delay: If the output format is incompatible with CLEAR's master-plan.yaml schema, a format migration is needed later. Design it right now.

**4. Plan-mode explore-then-commit workflow (SHOULD HAVE)**
- User value: Users review the draft plan before the skill finalizes. Prevents wasted tokens on a plan that misses the mark. Aligns with pre-brainstorm alignment decision.
- Who benefits: All users. Plans are high-stakes artifacts — a bad plan wastes entire implementation cycles.
- Cost of delay: Low. Can be added post-v1 if needed, but the AskUserQuestion pattern already exists in bulwark-brainstorm. Include in v1.

**5. Agent Teams mode (SHOULD HAVE, but not launch-blocking)**
- User value: Peer debate between scrum team members. The Technical Architect challenges the Engineering Lead's sequencing. The QA/Critic pushes back on the Product Owner's scope in real-time rather than after-the-fact. This is qualitatively different from sequential analysis.
- Who benefits: Users with `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set, willing to accept ~2x token cost, and working on plans complex enough that peer debate adds value over sequential analysis.
- Cost of delay: MEDIUM. P5.13 is explicitly the Agent Teams proving ground. Deferring Agent Teams mode means deferring the empirical validation that informs P5.15 (brainstorm `--exploratory`). However, the Task tool mode can ship independently.

**6. Token budget warnings and checkpoints (SHOULD HAVE)**
- User value: Prevents surprise token consumption, especially in Agent Teams mode where ~2x cost is expected.
- Who benefits: Cost-conscious users, which is everyone.
- Cost of delay: Users discover the cost empirically. Unpleasant but not catastrophic.

### Scope Boundaries (v1 vs Deferred)

**v1 Scope (ship this)**

| Feature | Justification |
|---------|---------------|
| Task tool mode (5-role sequential/parallel pipeline) | Launch vehicle, 100% user coverage |
| 5 scrum team role definitions in `references/` | Product differentiator |
| CLEAR-compatible output format (phases, workpackage IDs, milestones, dependencies) | Portability requirement — compatible with but not dependent on CLEAR |
| Agent Teams mode with env var gating and graceful degradation | P5.13's explicit proving-ground mandate; pre-flight detection of experimental flag |
| SA2-compliant dual-output in Agent Teams mode (logs/ + mailbox) | Non-negotiable compliance requirement |
| Plan-mode explore-then-commit with user approval gate | Aligns with pre-brainstorm alignment; prevents wasted tokens |
| Diagnostic YAML output | Established pattern from brainstorm/research |
| Self-contained directory structure (SKILL.md + references/ + templates/) | Portability across all 3 contexts |

**Deferred (explicitly NOT in v1)**

| Feature | Why Deferred |
|---------|-------------|
| Plan management (progress tracking, timeline adjustment, blocker detection) | CLEAR's plan-management skill's responsibility. Different skill, different lifecycle. Including it violates single-responsibility and breaks portability for P2/P3. |
| Workpackage decomposition into task briefs | Downstream tooling. Plan-creation produces master plans with workpackage identifiers. Decomposition into `plans/task-briefs/P{X}.{Y}-{name}.md` is a separate workflow step. |
| Tmux split-pane mode | In-process mode is the WSL2-safe default. Tmux adds operational complexity (orphaned sessions, layout disruption per GitHub #23615) with marginal benefit for a short-lived planning session. |
| Migration of existing skills to Agent Teams | Research synthesis is explicit: "No migration needed for current modes." Plan-creation is the one exception because it was designed for Agent Teams from the start. |
| Multi-project plan aggregation | Future enhancement. v1 handles one project at a time. |
| Plan versioning or diffing | Future enhancement once plans are being actively managed by CLEAR. |

### Success Criteria

**Functional success (both modes)**:
1. The skill produces a structured implementation plan with phases, workpackage identifiers, milestones, and dependencies from a user-provided problem statement.
2. All 5 scrum team roles contribute distinct, non-redundant perspectives visible in the log artifacts.
3. The QA/Critic role identifies at least one substantive gap or risk not raised by the other 4 roles (measurable via log inspection).
4. Output format is parseable as CLEAR master-plan input without manual reformatting.
5. Passes `/anthropic-validator` with 0 critical, 0 high findings.

**Task tool mode specific**:
6. SA2 compliance: all agent output in `logs/plan-creation/{slug}/`, no output outside logs.
7. Follows bulwark-brainstorm's established patterns (4-part prompting, diagnostics, error handling with single retry).

**Agent Teams mode specific**:
8. Graceful degradation: when `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is not set, skill automatically falls back to Task tool mode with a user-visible notification.
9. SA2 compliance: artifacts in `logs/`, mailbox used only for coordination summaries.
10. At least one observable instance of peer challenge in mailbox logs (teammate X challenges teammate Y's finding).

**Portability**:
11. Skill runs in a fresh project (no Bulwark, no CLEAR) with no errors — only the problem statement and codebase are required.
12. Rsync to Essential Skills repo succeeds and skill remains functional in standalone context.

### Risk to User Experience

**If Agent Teams mode ships broken**: Users who set the experimental flag and choose Agent Teams mode get orphaned processes, incomplete plans, or SA2 violations (findings scattered across mailbox instead of logs). Mitigation: Pre-flight gate that checks the env var AND warns about experimental status. Graceful degradation is not optional — it is a v1 requirement.

**If output format is wrong**: Plans that don't match CLEAR's master-plan schema require manual reformatting, negating the automation value. Worse, if the format is loosely defined, different runs produce structurally inconsistent plans. Mitigation: Output template with explicit schema in `templates/plan-output.md`. The template enforces structure; the agents fill in content.

**If roles produce redundant output**: The Product Owner and Delivery Lead overlap on scope; the Technical Architect and Engineering Lead overlap on sequencing. Without sharp role boundaries, users get 5 agents saying the same thing in different words — all cost, no value. Mitigation: Role definitions in `references/role-*.md` must include explicit "you are responsible for X, you are NOT responsible for Y" boundaries. The QA/Critic role definition must include specific challenge dimensions (scope realism, sequencing dependencies, estimation accuracy, milestone feasibility).

**If the skill is slow**: 5 agents in Agent Teams mode with ~2x token overhead means a plan could take 10+ minutes and significant token spend. Users expecting a quick plan will abandon. Mitigation: Token budget estimate at pre-flight ("This will consume approximately X tokens in Agent Teams mode, Y tokens in Task tool mode. Proceed?"). Clear expectation-setting.

**If portability breaks**: A skill that works in Bulwark but fails in Essential Skills or CLEAR due to hardcoded paths or missing dependencies erodes trust in the entire skill distribution model. Mitigation: No hardcoded paths. SME/first-mover agent explores codebase autonomously. `subagent-prompting` is the only skill dependency, and it must also be present in target contexts.

## Recommendation

**Proceed.** The plan-creation skill has clear user value across all three distribution contexts, a proven structural template (bulwark-brainstorm), and bounded scope (create plans, not manage them). Ship both modes in v1 — Task tool as the reliable default, Agent Teams as the opt-in primary — because P5.13's explicit mandate is to be the Agent Teams proving ground, and deferring Agent Teams mode would defer the empirical validation that P5.15 depends on.

The one modification I would make to the current framing: stop calling Agent Teams the "primary" mode and Task tool the "fallback." From a product perspective, Task tool is the primary mode (works for everyone, proven, production-stable). Agent Teams is the enhanced mode (opt-in, experimental, higher cost, potentially higher quality). This reframing sets correct user expectations and avoids positioning the reliable path as second-class.
