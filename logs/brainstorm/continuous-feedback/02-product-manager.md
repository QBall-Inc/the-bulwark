---
role: product-manager
topic: P5.3 continuous-feedback skill
recommendation: proceed
key_findings:
  - Primary user value is closing the feedback loop between session learnings and skill improvement — currently a fully manual process across 62+ sessions
  - The Collect and Validate stages carry near-zero engineering risk; Analyze is the high-value, high-effort core that must ship in v1 to deliver any meaningful user value
  - Proposal-only output (no direct file modification) is the correct v1 scope boundary — it preserves user trust and sidesteps the hardest validation problems
---

# P5.3 Continuous-Feedback Skill — Product Manager

## Summary

The continuous-feedback skill addresses the most significant operational gap in the Bulwark workflow: accumulated session learnings (62 handoffs, 50+ MEMORY.md entries, dozens of defects and architecture decisions) exist as passive documentation rather than active drivers of skill improvement. Today, converting a session learning into a skill update requires a developer to manually identify the relevant skill, determine what changed, draft the update, and validate it. This skill automates the identification and drafting steps while keeping the developer in control of application. The user value is substantial and the engineering risk is bounded by existing infrastructure.

## Detailed Analysis

### User Value Proposition

**Primary beneficiary:** The Bulwark developer/operator (the user who runs sessions, accumulates learnings, and maintains skills).

**Problem being solved:** Knowledge decay. The project has captured rich operational data — DEF-P4-005 through DEF-P4-007, ENH-P4-003, 15+ architecture decisions, framework observations FW-OBS-001 through FW-OBS-005, and dozens of session-specific learnings. Most of this knowledge is not reflected in the skills it should improve. For example:

- DEF-P4-005 (Claude ignores skill instructions without binding language) led to SC1-SC3 in `Rules.md` but has not been systematically applied to validate whether all existing skills use sufficiently binding language.
- The "violation scope variance across runs" finding (MEMORY.md) directly implies test-audit AST scripts could benefit from tighter scoping rules, but no mechanism exists to surface that connection automatically.
- The "BINDING language prevents LLM re-classification" finding was manually applied to two files but could apply to other skills with classification stages.

**Measurable value:** Time saved per improvement cycle. Currently, identifying an improvement target from session data takes 15-30 minutes of reading and cross-referencing. Drafting a concrete proposal takes another 15-30 minutes. The skill compresses both to a single invocation producing a reviewable proposal document. For a project with 14 skills and growing, this translates to hours saved per improvement pass.

**Secondary value:** Discoverability. The skill surfaces improvement opportunities the developer would not find through manual review. Cross-referencing 62 session handoffs against skill-specific patterns (e.g., which AST detection gaps map to which test-audit sub-skills) is cognitively expensive. Automated analysis makes this tractable.

### Prioritization

Ranked by value-to-effort ratio:

**1. General pattern extraction from session handoffs (highest value/effort ratio)**
- User value: Surfaces improvement targets from any session learning for any skill type. This is the broadest applicable capability.
- Who benefits: Any user with session handoffs and skills to improve.
- Cost of delay: Every session that passes without this capability adds to the unprocessed backlog. With 62 sessions already accumulated, the backlog grows linearly.

**2. Per-skill-type Analyze specialization for code-review and test-audit**
- User value: These two skills have the richest reference material (`references/{section}-patterns.md`, 4 AST scripts + sub-skills) and the most documented improvement opportunities in session history.
- Who benefits: Code review and test audit users get targeted, actionable proposals rather than generic suggestions.
- Cost of delay: Moderate. These skills are stable but not improving from accumulated data.

**3. Proposal document generation (Act stage)**
- User value: Converts analysis findings into a concrete, copy-pasteable change proposal. Without this, the skill produces findings but not actions — halving the value.
- Who benefits: The operator who applies changes.
- Cost of delay: High if shipped without this. Analysis without proposals forces the user to do the hard translation work manually, undermining the core value proposition.

**4. Per-skill-type specialization for bug-magnet-data and general skills**
- User value: Extends coverage to remaining skill types.
- Who benefits: Users of these specific skill types.
- Cost of delay: Low. These skill types have fewer documented improvement patterns and can be added incrementally.

**Recheck — challenging my own prioritization:**

- "If I'm wrong about the user value of general pattern extraction, how does the ranking change?" If the session handoff structure is too heterogeneous for reliable pattern extraction, per-skill-type specialization becomes the only viable path, and the ranking inverts to favor code-review/test-audit specialization first. However, the SME confirms session handoffs use a consistent template (YAML header, Learnings section, Technical Decisions), so this risk is low.

- "What user segment am I underweighting?" External adopters who do not have 62 sessions of history. For them, the skill must deliver value from a small number of sessions (1-5). This means the Analyze stage cannot rely on volume — it must extract value from sparse inputs. General pattern extraction handles this better than per-skill specialization, which validates my ranking.

- "Are my scope boundaries driven by constraints or assumptions?" The proposal-only output (no direct file modification) is driven by an explicit design decision, not an assumption. This is correct — the user explicitly stated this preference, and it aligns with trust requirements for a v1.

### v1 Scope Boundaries

**In v1:**

1. **Collect stage:** Parse session handoffs (`sessions/*.md`), MEMORY.md (both project-level and agent-level), and user-specified custom paths via arguments. Use a single Sonnet Collector agent per the SME recommendation.

2. **Analyze stage:** Two modes:
   - General pattern extraction (always runs): Identify recurring themes, unaddressed defects, architectural decisions not yet reflected in skills.
   - Per-skill-type specialization (runs for code-review and test-audit only): code-review gets security/framework pattern feed analysis; test-audit gets AST script gap analysis and detection pattern review.
   - Use 2-3 parallel Sonnet Analyzer agents as the SME recommends.

3. **Act stage:** A single Sonnet Proposer agent generates a proposal document with:
   - Specific file paths and sections to modify
   - Before/after content where applicable
   - Rationale tied to source learnings
   - Validation steps for each proposed change

4. **Validate stage:** Orchestrator runs anthropic-validator on any proposed skill changes. No sub-agent needed — this is a direct tool invocation.

5. **Input sources:** Session handoffs + MEMORY.md as defaults. Custom paths via `--sources` argument.

**Deferred to v2:**

- Per-skill-type specialization for bug-magnet-data and general skills (add after v1 validation confirms the pattern works)
- Automatic application of proposals (direct file modification)
- External data source integration (e.g., GitHub issues, CVE feeds for code-review patterns)
- Scheduled/automated invocation (currently user-triggered only)
- Agent memory as an input source (add when P6.9 agent persistent memory is implemented)

### Success Criteria

1. **Actionability rate:** At least 60% of generated proposals are accepted by the user (measured over 5 invocations). A proposal is "accepted" if the user applies it, possibly with minor edits.

2. **Source traceability:** Every proposal item cites at least one specific session handoff, MEMORY.md entry, or input source. No unsourced suggestions.

3. **Specificity:** Proposals reference concrete file paths (e.g., `skills/code-review/references/security-patterns.md`, line ranges) rather than abstract recommendations like "improve security coverage."

4. **Validation pass rate:** 100% of proposed skill changes pass anthropic-validator when applied.

5. **Time to value:** A complete Collect-Analyze-Act-Validate cycle completes within a single session's token budget (estimated 40-60K tokens per SR3).

6. **Sparse input viability:** The skill produces at least one actionable proposal from as few as 3 session handoffs (validates external adopter use case).

### Risk to User Experience

**Low-quality proposals erode trust rapidly.** If the skill generates vague, irrelevant, or incorrect proposals, users will stop invoking it after 1-2 tries. The proposal-only output design mitigates the blast radius (bad proposals are discarded, not applied), but repeated low-quality output makes the skill perceived as useless.

**Mitigation:** The per-skill-type specialization in the Analyze stage is the primary quality lever. Generic analysis produces generic proposals. The code-review and test-audit specializations ground the analysis in concrete artifacts (pattern files, AST scripts), which constrains the Proposer to actionable outputs. Ship v1 with these two specializations and validate quality before expanding.

**Over-scoping the Analyze stage risks session budget overruns.** Running 3 parallel Sonnet analyzers plus a Proposer on 62 session handoffs could consume significant tokens. If the skill exceeds a single session's budget, it becomes impractical to use. Mitigate by allowing the user to scope input (e.g., `--sessions last-10` or `--since 2026-02-01`) and by having the Collector produce a condensed summary rather than passing raw session content to Analyzers.

**Stale proposals.** If the user runs the skill, applies some proposals, but does not re-run, subsequent invocations may re-propose already-applied changes. The Collector must detect applied changes (by reading current skill state) to avoid this. Include this in v1 scope — it is essential for repeat usability.

## Recommendation

**Proceed with implementation.** The user value is clear, the engineering risk is bounded by proven infrastructure (multi-stage skill patterns, anthropic-validator, Task tool sub-agents), and the proposal-only output design provides a safe v1 surface. The primary implementation risk is Analyze stage quality, which is mitigated by per-skill-type specialization for the two richest skill types (code-review, test-audit).

Execute the SME's recommended 4-agent pipeline: 1 Collector (Sonnet), 2-3 parallel Analyzers (Sonnet), 1 Proposer (Sonnet). The orchestrator handles Validate directly. Ship v1 with general pattern extraction plus code-review and test-audit specializations. Defer bug-magnet-data and general skill specializations to v2. Add input scoping arguments (`--sources`, `--since`) to manage token budgets. Prioritize source traceability and proposal specificity as the key quality metrics that determine whether the skill earns repeat usage.
