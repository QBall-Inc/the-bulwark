---
role: critical-analyst
topic: "P5.13 Plan-Creation Skill — Agent Teams Dual-Mode"
verdict: modify
verdict_confidence: high
conditions:
  - Task tool mode ships as v1; Agent Teams mode deferred until one empirical comparison validates quality improvement
  - Session estimate revised to 2 (Task tool only) + 1 optional (Agent Teams after empirical validation)
  - Role definitions validated via single dry-run before full implementation
key_challenges:
  - Zero evidence that Agent Teams peer debate improves plan quality over Task tool sequential analysis
  - SA2 compliance in Agent Teams mode relies entirely on prompt adherence with no enforcement mechanism
  - 5-role scrum team exceeds research-validated 3-4 agent coordination cap
---

# P5.13 Plan-Creation Skill — Critical Analysis

## Cost-Benefit Assessment

The investment breaks into two distinct components with very different risk profiles.

**Task tool mode**: Low risk, moderate value. The Dev Lead estimates 80% reuse from bulwark-brainstorm. The structural template exists, the SA2 compliance pattern is proven, and the orchestration model is identical to two working skills. One session to build, well-understood cost. The value is real but modest — it replaces an unstructured "Claude, make me a plan" conversation with a 5-role structured process. Whether that structured process produces meaningfully better plans than a single well-prompted conversation is an open question (see Assumption Challenges), but the downside is bounded: one session of work for a skill that at minimum serves as a reusable template.

**Agent Teams mode**: High risk, speculative value. This is the first-ever Agent Teams implementation in Bulwark, building against an experimental API with known failure modes (lead context compaction, task status lag, broken session resumption). The entire justification rests on the assumption that peer debate between LLM agents produces better plans than sequential analysis — an assumption with zero empirical evidence in this codebase. The cost is 1-2 additional sessions of implementation plus ~2x token cost per invocation. The benefit is hypothetical quality improvement that no one has measured.

The cost-benefit math: Task tool mode has a positive expected value. Agent Teams mode has an unknown expected value built on an untested assumption, with guaranteed higher cost. Building both simultaneously — as all four proposals recommend — front-loads the speculative investment before validating the core hypothesis.

All four proposals recommend "proceed with both modes." This unanimous verdict deserves scrutiny. Each proposal acknowledges the risks (experimental API, SA2 compliance, coordination overhead, zero precedent) but then proceeds to recommend building anyway. The SME says the "pre-brainstorm alignment decisions de-risk the key technical unknowns." The PM says deferring Agent Teams "would defer the empirical validation that P5.15 depends on." The Architect says the "primary risk is mitigated by the dual-output contract pattern." The Dev Lead says "risk is bounded because the Task tool mode provides a working fallback."

These are all true statements, but they collectively dodge the real question: **Is building Agent Teams mode the cheapest way to validate whether Agent Teams add value?** The answer is no. A single comparative run — same topic, Task tool mode vs Agent Teams mode, blind quality comparison — would validate the hypothesis in a fraction of the implementation time. Build the comparison harness, not the production feature.

## Assumption Challenges

I cataloged 20 assumptions across the four proposals. Here are the highest-risk ones.

### Assumption 1: Peer debate produces better plans (ALL FOUR PROPOSALS)

Every proposal assumes Agent Teams peer debate will produce higher-quality plans than Task tool sequential analysis. The Architect calls it "the core architectural difference." The PM calls it "qualitatively different from sequential analysis." The SME says it "improves plan quality." The Dev Lead says Agent Teams should produce "richer plans with cross-challenge evidence."

**Evidence for**: The Agyn paper (adversarial investigation for debugging), HEARSAY-II (50 years ago, different substrate), and the intuition that debate catches blind spots.

**Evidence against**: The research synthesis itself rates "peer debate improvement quantification" as LOW confidence. The Contrarian viewpoint in the research calls it "over-hyped for Bulwark's context." There is zero empirical measurement of LLM-to-LLM debate improving plan quality specifically. LLMs responding to each other's messages may produce verbose agreement and mutual reinforcement rather than genuine adversarial challenge. The Architect's key differentiator — QA/Critic participating throughout rather than running last — sounds compelling but rests on the unverified claim that real-time LLM challenge is materially different from after-the-fact LLM review of the same artifacts.

**If wrong**: The entire dual-mode architecture is over-engineering. Agent Teams mode costs ~2x tokens with no quality improvement. The 1-2 sessions spent building Agent Teams mode are wasted. P5.15 (brainstorm exploratory mode) loses its justification.

> **Highest-Risk Assumption**: Agent Teams peer debate produces measurably better plans than Task tool sequential analysis.
> **If wrong**: Dual-mode architecture is pure overhead — ~2x token cost, 1-2 extra implementation sessions, ongoing maintenance of an experimental API integration, all for zero quality gain. P5.15's Agent Teams exploratory mode also loses its rationale.
> **To validate**: Run one plan-creation task through both modes (manual, before building the production skill) and blind-compare output quality. Cost: ~1 hour of manual effort plus token spend for two runs.

### Assumption 2: SA2 compliance via prompt instructions is reliable in Agent Teams mode

All four proposals acknowledge SA2 compliance as a risk but assume it is "manageable" through prompt engineering — instructing each teammate to write to logs/ AND send mailbox summaries. The Architect proposes a post-completion check ("verify all 5 log files exist before synthesis").

**Evidence for**: Task tool mode achieves SA2 compliance through prompt instructions. Bulwark-brainstorm's agents write to logs/ as instructed.

**Evidence against**: Agent Teams teammates operate with their own independent context. They receive peer messages that create social pressure to respond via mailbox rather than logging. There is no orchestrator actively reading their log output mid-execution (unlike Task tool mode, where the orchestrator waits for the log artifact). The "verify log files exist" check catches the violation AFTER the fact — the teammate's analysis is lost if it was only sent via mailbox.

**If wrong**: Findings exist only in ephemeral mailbox files, not in durable logs. SA2 is violated. The synthesis stage has incomplete input. The diagnostic YAML reports a compliance failure.

**Cost to validate**: Run one Agent Teams session with 5 teammates and check whether all 5 log files exist with substantive content (not just stubs).

### Assumption 3: 5 agents work within coordination limits

The research synthesis explicitly states the effective team size "caps at 3-4 agents before coordination overhead dominates." The Architect acknowledges this and argues that reducing to 4 active Agent Teams teammates (PO runs via Task tool) is within bounds. But 4 is at the ceiling, not below it. The Dev Lead identifies role overlap (PO/Delivery Lead, Architect/Eng Lead) as "LOW severity, HIGH probability" — which should raise the question: if roles overlap, do we need all 5?

**Evidence for**: The scrum team roles map to distinct concerns (product scope, architecture, implementation, delivery, quality).

**Evidence against**: The 3-4 cap comes from mob programming research and Agent Teams community experience. 4 active teammates is at the ceiling. More importantly, LLM agents lack the domain expertise that makes human role specialization valuable — a Sonnet instance playing "Delivery Lead" has no scheduling expertise that a Sonnet instance playing "Engineering Lead" lacks. The role differentiation is in the prompt, not in the capability.

**If wrong**: Coordination overhead in Agent Teams mode dominates. Teammates produce overlapping analysis. Token cost exceeds 2x because of message volume. The Critic, already the 5th agent, gets drowned in peer messages.

## Gaps in Proposals

### Gap 1: No definition of "better plan"

All four proposals assume Agent Teams mode produces "better" or "richer" plans, but none defines what "better" means in measurable terms. The PM's success criteria are structural (phases exist, roles contribute, Critic finds a gap) — they measure completeness, not quality. Without a quality metric, the "proving ground" mandate is unfalsifiable. You cannot determine whether Agent Teams "worked" if you have not defined what success looks like beyond structural compliance.

### Gap 2: No consideration of plan-creation frequency

The PM and Architect assert plan-creation is "low-frequency, high-value" to justify higher token costs. But no one has estimated actual frequency. If a user creates one plan per project, the skill runs once. If it runs once, the 5-role structure is untestable in practice — you cannot iterate on role definitions with a sample size of one. The skill may be more valuable as a simpler, faster tool that users run multiple times (iterating on scope) than as a heavyweight 5-agent production.

### Gap 3: CLEAR compatibility is speculative investment

The Architect spent significant design effort on CLEAR-compatible YAML output format, referencing CLEAR's `MasterPlan` type interface and `parseMasterPlanContent()` parser. The SME notes CLEAR is "on hiatus" with "no skills implemented beyond a basic skill-creator and test-writing-discipline." Designing for CLEAR compatibility now is building for a consumer that does not exist and may never exist. The hybrid format (Markdown preamble + YAML body) is fine on its own merits (structured, parseable), but the CLEAR-specific field mapping is premature optimization.

### Gap 4: The PM's reframing is substantive, not semantic

The PM argues Task tool should be "primary" and Agent Teams "enhanced" rather than vice versa. The pre-brainstorm alignment says "Agent Teams as primary mode (Task Tool fallback)." The PM reframes this because "Task tool works for everyone, proven, production-stable" while Agent Teams are "opt-in, experimental, higher cost."

This is not a labeling dispute. It is a resource allocation question. If Agent Teams is "primary," you build and optimize it first. If Task tool is "primary," you ship it and validate Agent Teams later. The PM is correct: Task tool should be primary, and the original "Agent Teams primary" framing should be explicitly revised.

### Gap 5: No rollback plan for Agent Teams mode

The Dev Lead identifies Agent Teams API instability as the highest-severity risk but proposes "document the specific Claude Code version" as mitigation. If Agent Teams changes materially between Claude Code versions, the Agent Teams mode section of SKILL.md becomes dead code. No proposal addresses what happens when: (a) the experimental flag is removed or renamed, (b) the mailbox API changes, or (c) Agent Teams is deprecated entirely. The implicit assumption is that Agent Teams will stabilize and improve. It could also be abandoned.

## Simpler Alternatives

### Alternative 1: Task tool only, with structured debate prompts

Build the 5-role scrum team using Task tool mode only. Simulate the "peer debate" benefit by having the Critic explicitly reference and challenge specific claims from prior agents' log files. This is what bulwark-brainstorm already does with its Critical Analyst role. The quality difference between "Critic reads Architect's log and challenges it" (Task tool) versus "Critic messages Architect in real-time and Architect responds" (Agent Teams) is unproven and possibly negligible for plan creation.

Cost: 1 session. Delivers 95% of the claimed value.

### Alternative 2: 3-role team instead of 5

Collapse to: (1) Product Owner / Scope (combines PO + Delivery Lead), (2) Technical Architect / Implementation (combines Architect + Eng Lead), (3) QA/Critic. Three roles with genuinely distinct lenses. Eliminates the role overlap risk. Stays well within the 3-4 agent coordination cap. Reduces token cost by 40%.

Cost: Same 1 session. Lower ongoing token cost.

### Alternative 3: Defer Agent Teams to P5.15

P5.15 (brainstorm exploratory mode) is explicitly designed for Agent Teams. It is a mode addition to an existing, working skill with established patterns. Building Agent Teams integration there — where the skill infrastructure already exists — is lower risk than building it in a net-new skill. Let P5.15 be the Agent Teams proving ground instead of P5.13.

Cost: Zero additional sessions for P5.13. Agent Teams validation happens at the natural point in the schedule.

## Kill Criteria

Under what conditions should this be abandoned or significantly descoped:

1. **If a comparative test run (same topic, both modes) shows no measurable quality difference between Agent Teams and Task tool output**: Kill Agent Teams mode entirely. Ship Task tool only.

2. **If 3 or more of the 5 scrum team agents produce overlapping analysis in the first test run**: Reduce to 3 roles. The role definitions are not sufficiently differentiated.

3. **If Agent Teams mode fails to produce all 5 SA2-compliant log files in the first test run**: The dual-output prompt contract does not work. Do not iterate on prompt engineering — the enforcement mechanism is too weak. Kill Agent Teams mode.

4. **If Agent Teams experimental flag is removed or API changes before Session 2 begins**: Defer Agent Teams mode indefinitely. Do not chase a moving target.

5. **If the total implementation exceeds 3 sessions**: Stop. The skill is not delivering value proportional to investment. Ship whatever works at Session 3 boundary.

## Verdict

**Modify** (Confidence: high)

Do not build both modes simultaneously. The unanimous "proceed with dual-mode" recommendation from all four proposals rests on an untested assumption (peer debate improves plan quality) and front-loads speculative investment before validation.

**Prescribed approach:**

1. **Session 1**: Build Task tool mode with 5-role scrum team. Ship it. This delivers the core value (structured multi-agent plan creation) with proven infrastructure.

2. **Before Session 2**: Run one comparative test. Same topic through Task tool mode. Then manually run Agent Teams (outside the skill, ad-hoc) with equivalent prompts. Blind-compare output quality. This costs ~1 hour and validates the foundational assumption.

3. **Session 2 (conditional)**: If the comparative test shows Agent Teams produced a measurably better plan, build Agent Teams mode. If not, skip it entirely and reallocate the session to P5.15 or another task.

4. **Adopt the PM's reframing**: Task tool is primary. Agent Teams is enhanced/opt-in. Update the pre-brainstorm alignment language accordingly.

5. **Monitor role overlap**: If the first Task tool test run shows PO/Delivery Lead or Architect/Eng Lead producing redundant analysis, collapse to 3 roles before building Agent Teams mode.

**Conditions under which this verdict would change to "proceed as-is":**
- Empirical evidence (even one comparative run) showing Agent Teams plans are materially better than Task tool plans
- Agent Teams exits experimental status before implementation begins
- A stakeholder requirement mandates Agent Teams integration for P5.13 specifically (not just "proving ground" language)

**Conditions under which this verdict would change to "defer":**
- CLEAR remains on hiatus with no resumption timeline, AND the standalone Essential Skills repo shows no user demand for plan-creation
- Agent Teams experimental flag is removed or renamed before work begins
