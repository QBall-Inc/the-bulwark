---
role: critical-analyst
topic: P5.3 continuous-feedback skill
verdict: modify
verdict_confidence: medium
conditions:
  - Proposer agent quality validated via manual prompt experiment before implementation begins
  - v1 scope reduced to 1 specialization (not 2) plus general, cutting reference file count from 4 to 2
  - Kill criteria monitored during first manual test run
key_challenges:
  - No existing skill demonstrates the Proposer's core capability (generating applicable file-level change proposals from LLM analysis)
  - The problem being solved may be smaller than claimed — MEMORY.md already functions as a curated feedback mechanism
  - 4-agent pipeline for proposal-only output may be over-engineered relative to the value delivered
---

# P5.3 Continuous-Feedback Skill -- Critical Analysis

## Cost-Benefit Assessment

The investment is 1 session (35-50K tokens) to build a skill that automates identifying improvement opportunities in existing skills based on accumulated session learnings. All four prior outputs recommend proceeding. Let me challenge whether the return justifies even this modest cost.

**Quantifying the benefit.** The PM claims manual improvement identification takes 15-30 minutes per improvement. Assume the skill surfaces 5 improvements per invocation and the user runs it monthly. That is 75-150 minutes saved per month if 60% of proposals are accepted. Over 6 months: 7.5-15 hours saved. Against a 1-session build cost (roughly 2-3 hours of focused work) plus ongoing maintenance, this is a positive ROI only if the 60% acceptance rate holds and the skill is actually invoked regularly.

**The hidden cost nobody mentions.** Every skill added to the repository incurs maintenance cost. When session-handoff template changes, the Collector's parsing instructions must update. When a new skill type is added to the project, a new specialization reference file must be authored. When the Proposer's output quality degrades (LLM model updates, prompt drift), someone must debug a 4-agent pipeline. The Dev Lead's estimate of "1 session to build" ignores the ongoing cost of a skill that reads other skills' internals. This is a coupling tax that compounds.

**The comparison baseline is wrong.** All four outputs compare the skill against "fully manual improvement identification." But the actual current workflow is: the user reads MEMORY.md at session start (per SR1), which contains curated defects, architecture decisions, and lessons learned. The user already has a feedback mechanism. The gap is not "no feedback loop" but "feedback loop requires manual application." The skill's marginal value is smaller than the PM's framing suggests.

## Assumption Challenges

> **Highest-Risk Assumption**: A Sonnet-class agent can produce proposals specific enough to be directly actionable (target file + section + concrete content to add/modify) from analyzed session learnings.
>
> **If wrong**: The entire skill's value proposition collapses. It becomes a glorified summary tool that restates what MEMORY.md already contains in a different format. The 60% acceptance rate target is unachievable, and the skill is abandoned after 1-2 uses.
>
> **To validate**: Before building anything, run a manual prompt experiment: give a Sonnet agent 5 collected learning items, one target skill's full content, and the proposed template format. Evaluate whether the output is copy-paste applicable or requires significant human rewriting. 15-20 minutes of effort.

This assumption is the load-bearing wall of the entire proposal. The Dev Lead acknowledges the Proposer is "the hardest agent" and "no existing skill demonstrates this pattern." The Architect's proposed diff-like output format ("before/after content where applicable") has never been produced by any Bulwark sub-agent. The PM's 60% acceptance criterion depends entirely on this capability. Yet no prior output proposes validating this assumption before committing to a full build. That is a planning failure.

**Assumption 2: The Collector's normalized intermediate schema will preserve enough context for downstream quality.** The Architect proposes a compact schema (source, category, content, skill_relevance). But session learnings are often nuanced. "BINDING language prevents LLM re-classification" is meaningful only in the context of the full DEF-P4-005 narrative, the SC1-SC3 response, and the specific files it was applied to. Stripping that to a normalized item with a category tag and a 1-2 sentence content field loses the context that makes the learning actionable. The Proposer cannot generate specific file modifications from a lossy intermediate representation. This is the Collect-Analyze interface problem: compress too much and you destroy signal; compress too little and the Collector adds no value over passing raw files.

**Assumption 3: Per-skill keyword routing is deterministic and sufficient.** The Dev Lead prescribes keyword matching: "mock" routes to test-audit, "security" routes to code-review. But session learnings rarely use clean keywords. "Violation scope variance across runs" is a test-audit concern, but contains none of the trigger words (mock, assertion, AST). "Cascading sed pattern collision" is relevant to the rsync/sync infrastructure, not to any skill specialization. Keyword routing will misroute or miss 30-40% of learnings based on the actual MEMORY.md content I can see. The alternative (LLM classification) reintroduces the variance the routing was supposed to eliminate.

**Assumption 4: Windowed input (last 10 sessions) captures actionable learnings.** The Architect defaults to 10 sessions. But improvement-worthy learnings are sparse and distributed across the full 62-session history. The most actionable findings (DEF-P4-005, DEF-P4-006, TestAudit gap pattern) are from sessions 30-45, well outside a 10-session window. The first invocation would need the full history to surface the backlog; subsequent invocations could window. But the PM's "stale proposal detection" (comparing proposals against current skill state) is the mechanism that makes full-history viable, and nobody has validated that this detection works.

## Gaps in Proposals

**No one addresses the cold-start problem for non-Bulwark projects.** The PM claims external adopter viability with 3 sessions. The Architect says projects need `.claude/skills/` and `sessions/`. But a project with 3 sessions and 2 skills has perhaps 5-10 learning items. Running a 4-agent pipeline (Collector + Analyzer + Proposer + Validate) on 5 learning items is absurd overhead. The pipeline's minimum viable input volume is never defined. Below some threshold, the user is better served by reading their own sessions.

**No one addresses what happens when proposals conflict with each other.** If the Analyzer for code-review suggests adding a CRLF detection pattern and the general Analyzer suggests the same thing for a different skill, the Proposer must deduplicate. If two learning items suggest contradictory improvements to the same file section, the Proposer must resolve the conflict. Neither the Architect nor the Dev Lead addresses conflict resolution in the Act stage.

**The "proposal-only" constraint may undermine adoption.** The user must read the proposal, understand it, navigate to each target file, and manually apply changes. For 5-10 proposals per invocation, this is 30-60 minutes of manual work. The skill saves 15-30 minutes of identification time but creates 30-60 minutes of application time. The net time savings may be negative until auto-apply is implemented in v2. The PM defers auto-apply but does not acknowledge that deferral may tank v1 adoption.

**Maintenance burden of 4 specialization reference files is unaddressed.** Each reference file (specialize-code-review.md, specialize-test-audit.md, etc.) encodes domain expertise about what improvements are possible for each skill type. When skills evolve, these references become stale. The irony: a skill designed to prevent knowledge decay in other skills will itself suffer from knowledge decay in its reference files. No maintenance strategy is proposed.

## Simpler Alternatives

**Alternative 1: A checklist, not a pipeline.** Instead of a 4-agent skill, create a static markdown checklist: "For each session's Learnings section, check: (1) Does any learning imply a new pattern for code-review? (2) Does any learning reveal a test-audit gap? (3) Should MEMORY.md be updated?" This costs zero tokens to maintain, is invoked by reading it, and achieves 80% of the identification value. The user already reads session handoffs; a structured checklist makes that reading more productive. Build time: 30 minutes. Maintenance: near zero.

**Alternative 2: A single-agent "skill improvement advisor."** Skip the pipeline entirely. One Sonnet agent receives: the target skill's current files, the last N session handoffs, and a prompt saying "identify 3-5 specific improvements to this skill based on these session learnings." No intermediate schema, no parallel Analyzers, no specialization references. The agent reads both inputs and produces proposals directly. This eliminates the Collect-Analyze interface problem (assumption 2), the routing problem (assumption 3), and cuts token cost by 60-70%. Build time: 1 hour. If the single agent's output quality is poor, the 4-agent pipeline will not be better — the bottleneck is the LLM's ability to map learnings to skill improvements, not the pipeline architecture.

I prescribe Alternative 2 as the v0 validation experiment. If a single Sonnet agent cannot produce actionable proposals when given full context, adding pipeline stages will not fix the problem. If it can, promote to the full pipeline only if the single-agent approach hits scaling limits (too many sessions, too many skills per invocation).

## Kill Criteria

1. **The manual prompt experiment fails.** If a Sonnet agent given 5 learning items and a target skill's content produces proposals that require more than 20% rewriting to be applicable, kill the 4-agent pipeline. Fall back to Alternative 2 or Alternative 1.
2. **First full-pipeline test produces fewer than 3 actionable proposals from Bulwark's 62 sessions.** If the richest possible input corpus cannot yield 3 concrete improvements, the skill's value proposition is invalid.
3. **Proposal acceptance rate falls below 40% across 3 invocations.** The PM set 60% as success; I set 40% as kill. Below 40%, the skill is destroying trust faster than it creates value.
4. **Token consumption exceeds 60K per invocation.** At that point, the skill consumes an entire session's budget (per SR3), leaving no room for the user to actually apply the proposals in the same session. The skill becomes a session unto itself, which is not the intended usage pattern.

## Verdict

**Modify** (Confidence: medium)

The core idea is sound: accumulated session learnings should inform skill improvements systematically. But the proposed 4-agent pipeline is premature optimization. The highest-risk assumption — that the Proposer agent can generate directly actionable proposals — is unvalidated, and every prior output acknowledges this risk without proposing pre-validation.

Specific modifications:

1. **Run the manual prompt experiment first.** Before writing any SKILL.md, templates, or references, spend 15-20 minutes testing whether a Sonnet agent can produce actionable proposals given learning items + target skill content. This is the cheapest possible validation of the highest-risk assumption. Do this at the start of the implementation session, not as a separate task.

2. **Build a single-agent v0 before the pipeline.** If the prompt experiment succeeds, implement Alternative 2 (single-agent advisor) first. Test it on Bulwark's own skills. If it produces actionable proposals but struggles with scale (too many inputs, too many skill types), then promote to the multi-agent pipeline. If it produces actionable proposals at current scale (62 sessions, 14 skills), the pipeline is unnecessary complexity.

3. **Cut v1 specialization to 1 type plus general.** Build `specialize-test-audit.md` and `specialize-general.md` only. Test-audit has the richest documented improvement history (AST scripts, mock detection, assertion patterns). Code-review specialization can follow in v1.1 after the pattern is validated. This cuts reference file authoring by 50% and reduces the maintenance surface.

4. **Define the minimum viable input threshold.** Do not invoke the pipeline on fewer than 5 session handoffs. Below that, the overhead exceeds the value. Document this in SKILL.md as a Pre-Flight Gate check.

This verdict changes to **proceed (as designed)** if: (a) the manual prompt experiment shows Sonnet producing copy-paste-ready proposals at 60%+ quality, AND (b) the single-agent v0 demonstrably struggles with more than 1 skill type per invocation. It changes to **kill** if the prompt experiment shows proposals requiring >50% rewriting, regardless of pipeline complexity.
