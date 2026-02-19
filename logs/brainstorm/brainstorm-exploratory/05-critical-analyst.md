---
role: critical-analyst
topic: "P5.15 — Add --exploratory mode to bulwark-brainstorm using Agent Teams peer debate"
verdict: modify
verdict_confidence: medium
conditions:
  - "P5.13 completes with demonstrated peer cross-challenge (agents disputing each other, not converging)"
  - "A pre-implementation AT debate test on a real topic produces at least 2 explicit disagreements between agents"
  - "Retrospective of past 20 sessions identifies >= 3 instances where --exploratory would have prevented wasted work"
key_challenges:
  - "The problem this solves may be too rare to justify the investment — only 1 example cited across 60+ sessions"
  - "No evidence that LLM agents in AT mode will actually debate rather than converge when given the same context"
  - "P5.13 validates AT mechanics but not AT debate dynamics for subjective idea validation"
  - "The PM's 1-session estimate contradicts the Dev Lead's 2-session estimate — a 100% disagreement on effort"
---

# P5.15 — Add --exploratory Mode to bulwark-brainstorm — Critical Analysis

## Cost-Benefit Assessment

The investment is 2 sessions of implementation and testing (Dev Lead estimate; PM's 1-session claim is wishful). Ongoing costs include: 3-location sync maintenance, 6-case manual test protocol, AT API stability monitoring, and the cognitive overhead of a dual-mode skill. The total lifetime cost is approximately 3-4 sessions when you include the inevitable debugging and refinement that all AT-dependent features will require as the experimental API evolves.

The benefit case rests on a single proof point: the Ralph Loops descoping decision (Sessions 61-62). The PM argues that an --exploratory brainstorm "could have surfaced this faster through adversarial debate." This is a counterfactual — it is literally impossible to verify. What we know is that two research sessions accomplished the descoping adequately. The PM does not demonstrate that --exploratory would have been faster, only that it might have been. "Might have been faster" is not a compelling ROI justification for 3-4 sessions of investment.

Quantifying the benefit more honestly: --exploratory prevents wasted implementation sessions on bad ideas. Each prevented session saves 15-60K tokens. If --exploratory is used once per quarter (generous given zero usage in 60+ sessions) and successfully prevents one wasted session, the annual savings are 60-240K tokens. The cost to build is 2 sessions of Opus-class work. The payback period is measured in months, not sessions — marginal at best.

The PM's claim that "the user base is narrow but value per use is high" is accurate but incomplete. Narrow user base AND low frequency of the triggering condition (uncertainty about whether to build something) means total value delivered is small. The brainstorm skill itself has been invoked 6+ times; the --exploratory triggering condition (problem framing is uncertain) would have applied to perhaps 1-2 of those. Building a mode for 15-30% of invocations of an already-niche skill requires honest scrutiny.

## Assumption Challenges

**Highest-Risk Assumption**: The problem --exploratory solves (idea validation under uncertainty) recurs frequently enough to justify the investment.

**If wrong**: The feature is used 1-2 times total across the project lifetime, making it a net-negative investment. Two sessions to build, six test cases to maintain, three-location sync to manage, ongoing AT API stability monitoring — all for a capability exercised less than once per quarter.

**To validate**: Count historical instances where a problem or idea was abandoned after discovering it was not worth pursuing. If fewer than 3 in the past 20 sessions, frequency is insufficient to justify a dedicated mode.

---

**Assumption: AT peer debate will produce genuine cross-challenge.** All four proposals treat this as a given. The PM's kill criterion (#4) acknowledges the risk but treats it as a post-implementation check. The Architect's "selective challenge over full mesh" instruction assumes agents will naturally disagree when prompted to. But LLMs reading the same SME output and the same research documents are more likely to converge than diverge. The MEMORY.md entry on "violation scope variance across runs" shows that LLM judgment varies stochastically, not adversarially. Stochastic variance is not the same as structured disagreement. Three agents may produce slightly different framings of the same conclusion, which looks like "diverse perspectives" but is actually convergence with noise.

The PM's kill criterion ("if first test run shows no observable cross-challenge, kill the mode") is the right instinct but applied at the wrong time. Testing cross-challenge AFTER building the feature means the 2-session investment is already sunk. Test it BEFORE building: run a bare AT debate (no brainstorm skill, just 3 agents with role prompts discussing a real topic) and observe whether genuine disagreement emerges. Cost: 30 minutes. Savings if it fails: 2 sessions.

**Assumption: The Critic is better as an active participant than as a sequential final reviewer.** The Architect calls this "the primary quality advantage Agent Teams provide" and "the architectural differentiator." No evidence supports this claim. The Architect's own analysis identifies the trade-off: "maximum influence, but may anchor early on incomplete information." The Critic reviewing all outputs at the end (--scoped) has maximum information. The Critic participating throughout (--exploratory) has maximum influence but partial information. For idea validation under uncertainty, where the goal is to identify fatal flaws, you want the Critic to have COMPLETE information before rendering judgment. The --scoped Critic design may actually be superior for the --exploratory use case.

The Architect proposes a mitigation: "Do not form a final verdict until all teammates have shared their summaries." This instruction asks the Critic to participate throughout but withhold judgment — functionally recreating the sequential pattern within AT. If the mitigation is necessary, it undermines the premise that active participation is an advantage.

**Assumption: P5.13 de-risks P5.15.** All four proposals treat P5.13 as the proving ground. P5.13 validates AT mechanics (spawning, delegate mode, mailbox, dual-output). It does NOT validate AT debate dynamics for subjective, open-ended idea evaluation. Plan-creation has a concrete deliverable (a plan document) that agents can converge on or disagree about with reference to specific technical constraints. Brainstorming under uncertainty has no concrete anchor — agents are evaluating whether a concept deserves further investment. The debate dynamics in these two scenarios may differ substantially. P5.13 proving that AT works mechanically does not prove that AT produces valuable debate for brainstorming.

**Assumption: 1 implementation session is sufficient (PM) vs. 2 sessions (Dev Lead).** The PM and Dev Lead disagree by 100% on effort. The PM's rationale ("P5.13 de-risks, 80%+ reuse") ignores that the 20% new work includes AT prompt engineering, which the Dev Lead correctly identifies as 40% of Session 1 and the highest-uncertainty component. The Dev Lead's 2-session estimate is more credible because it accounts for AT debugging unknowns (30% of Session 2 budgeted for "fix issues found during testing"). Use the Dev Lead's estimate.

## Gaps in Proposals

**Gap 1: No analysis of whether the brainstorm skill's output CONSUMERS can use --exploratory output differently.** The synthesis feeds into task briefs. Task briefs feed into implementation sessions. If the downstream consumer (the implementer reading the task brief) does not change behavior based on whether the brainstorm was --scoped or --exploratory, the mode distinction is invisible to the workflow. None of the four proposals address what the implementer does differently with debate-driven output versus sequential output. If the answer is "nothing different," the mode is cosmetic.

**Gap 2: No competitive analysis against a simpler workflow.** The PM identifies the workflow gap: "no step for validating whether an idea deserves implementation planning." But `bulwark-research` with a pointed question ("Is X worth building?") followed by `/bulwark-brainstorm --scoped` already approximates this. The research skill gathers facts; the Critic in --scoped mode challenges assumptions; the synthesis produces a verdict. The PM does not explain why this existing two-step workflow is inadequate, only that a single-step --exploratory mode would be "faster." How much faster? One invocation saved? That is not a compelling efficiency gain.

**Gap 3: No consideration of AT API removal risk.** Agent Teams is experimental. The Architect notes the architecture is "hedged" — only Stage 3B is affected. But the hedge has ongoing costs: maintaining dead code if AT is removed, confusing users who discover --exploratory in documentation but cannot use it, and the sync complexity of a mode that may become permanently non-functional. None of the proposals estimate the probability of AT being removed or stabilized within 6 months.

**Gap 4: Naming inconsistency for the combined role.** The PM calls it "Product & Delivery." The Architect calls it "Product & Delivery Lead." The Dev Lead calls it "Product-Implementation Lead." Three names for the same role across three proposals suggests the consolidation concept is not yet crisp enough to implement. If the role's identity is unclear to the proposal authors, it will be unclear in the agent prompt, producing muddled output.

## Simpler Alternatives

**Alternative 1: Enhanced Critic mode for --scoped.** Instead of building a full AT mode, strengthen the Critic's role in --scoped: give the Critic explicit instructions to challenge the problem framing itself, not just the proposed solutions. Add a "problem validation" section to the Critic's template that asks: "Should this problem be solved at all? What evidence suggests this is worth investing in?" This delivers 60% of --exploratory's value (adversarial challenge to the premise) at 10% of the cost (modify one role reference file and one template). Total effort: 1 hour, not 2 sessions.

**Alternative 2: Manual AT debate outside the skill.** When the rare "idea validation under uncertainty" scenario arises, the user spawns an AT team manually with role prompts extracted from the brainstorm skill's references. No skill modification needed. The user gets peer debate when they want it without burdening the skill with a permanent second mode. This is the honest assessment of a feature used once per quarter.

**Alternative 1 is the recommended approach.** It addresses the genuine gap (the Critic does not currently challenge problem framing) without the AT dependency, 2x token cost, experimental API risk, 3-location sync burden, or 6-case test protocol expansion. If Alternative 1 proves insufficient after 3-5 brainstorm sessions, that empirical evidence justifies the full --exploratory investment.

## Kill Criteria

1. **Pre-implementation**: Run a bare AT debate test (3 agents, role prompts, real topic, no brainstorm skill) and observe whether genuine cross-challenge occurs. If agents converge without substantive disagreement across 2 test runs, kill --exploratory. Do not build it hoping prompts will fix a fundamental convergence tendency.

2. **Pre-implementation**: Count historical instances where an idea was abandoned after brainstorming/research proved it unworthy. If fewer than 3 in the past 20 sessions, the triggering frequency is too low to justify a dedicated mode.

3. **Post-P5.13**: If P5.13's AT mode shows no observable peer debate (teammates producing independent analyses without referencing each other's positions), kill --exploratory. P5.13 is the canary.

4. **Post-first-test-run** (PM's criterion, retained): If --exploratory produces no cross-challenge between teammates in its first real brainstorm run, kill the mode immediately.

5. **AT API stability**: If Anthropic announces AT deprecation or makes breaking changes before P5.15 implementation begins, kill --exploratory.

## Verdict

**Modify** (Confidence: medium)

Do not build --exploratory as currently scoped. Instead:

1. **Immediately**: Implement Alternative 1 (enhanced Critic mode) — add problem-framing challenge to the Critic's role reference and template. Cost: 1 hour. No AT dependency.

2. **After P5.13**: Observe P5.13's AT debate dynamics. If genuine cross-challenge occurs in plan-creation, --exploratory becomes more credible for brainstorming.

3. **Before committing to P5.15**: Run the two pre-implementation validation checks (bare AT debate test + historical frequency count). If both pass, proceed with the full --exploratory implementation as the four proposals describe. If either fails, the investment is not justified.

4. **If proceeding**: Use the Dev Lead's 2-session estimate, not the PM's 1-session estimate. Adopt the Architect's sandwich architecture. Settle the combined role name before implementation begins.

This verdict would change to **proceed** if:
- The bare AT debate test produces 3+ explicit disagreements between agents on a single topic
- Historical frequency analysis identifies 3+ instances where --exploratory would have prevented wasted sessions
- P5.13's AT mode demonstrates genuine peer debate, not parallel independent analysis

This verdict would change to **kill** if:
- The bare AT debate test shows convergence across 2 test runs
- P5.13's AT mode fails mechanically or produces no peer interaction
- Anthropic signals AT deprecation or instability
