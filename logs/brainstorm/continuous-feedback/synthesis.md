---
topic: P5.3 continuous-feedback skill
phase: brainstorm
agents_synthesized: 5
overall_verdict: modify
verdict_source: critical-analyst
---

# P5.3 Continuous-Feedback Skill — Brainstorm Synthesis

## Consensus Areas

All 5 roles agree on these foundations:

| Area | Supporting Roles | Confidence |
|------|-----------------|------------|
| The skill addresses a real gap: session learnings are not systematically fed back into skills | SME, PM, Architect, Dev Lead, Critic | HIGH |
| Proposal-only output (no direct file mods) is correct for v1 | SME, PM, Architect, Dev Lead, Critic | HIGH |
| Task tool sub-agents (not Agent Teams) is the right mechanism | SME, PM, Architect, Dev Lead, Critic | HIGH |
| Existing validation infrastructure (anthropic-validator, quality gates) covers the Validate stage | SME, Architect, Dev Lead, Critic | HIGH |
| Follow the bulwark-brainstorm directory layout (SKILL.md + references/ + templates/) | SME, Architect, Dev Lead | HIGH |
| The Proposer agent (Act stage) is the highest-difficulty, highest-risk component | PM, Dev Lead, Critic | HIGH |
| `--since` input windowing is essential for token budget management | Architect, Dev Lead, Critic | HIGH |
| Manual testing is the only viable verification strategy for LLM pipeline skills | Dev Lead, Critic | HIGH |

## Divergence Areas

### 1. Pipeline Complexity: 4-Agent Pipeline vs. Single-Agent v0

- **SME, PM, Architect, Dev Lead**: 4-agent pipeline (Collector → 2-3 Analyzers → Proposer) with orchestrator Validate. All recommend building the full pipeline in 1 session.
- **Critic**: Single-agent v0 first. The 4-agent pipeline is premature optimization. If a single Sonnet agent can't produce actionable proposals with full context, adding pipeline stages won't fix it. Build the pipeline only when the single-agent approach hits scaling limits.
- **Decision needed**: Build full pipeline from the start, or validate with a single-agent prototype first?

### 2. Number of v1 Specializations

- **PM**: 2 specializations in v1 (code-review + test-audit), defer bug-magnet and general to v2
- **Architect, Dev Lead**: 4 reference files (code-review, test-audit, bug-magnet-data, general) — all in v1
- **Critic**: 1 specialization + general only (test-audit, which has richest documented improvement history). Code-review follows in v1.1 after pattern validated.
- **Decision needed**: How many specialization reference files in v1?

### 3. Intermediate Schema Value

- **Architect**: Normalized intermediate format between Collect and Analyze is "the critical abstraction boundary" — schema: {source, category, content, skill_relevance}
- **Critic**: Normalization is lossy. Learning items like "BINDING language prevents LLM re-classification" lose their actionable context when compressed to a category tag and 1-2 sentences. The Proposer needs the full narrative to generate specific proposals.
- **Decision needed**: Compact normalized schema vs. richer intermediate format that preserves context?

### 4. Routing Strategy for Analyzer Selection

- **Dev Lead**: Keyword-based deterministic routing (e.g., "mock" → test-audit, "security" → code-review)
- **Critic**: Keywords miss 30-40% of learnings. "Violation scope variance" is a test-audit concern but contains no trigger keywords. LLM classification reintroduces variance.
- **Decision needed**: How to route learnings to the right Analyzer?

## Critical Analyst Verdict

**Verdict**: Modify
**Confidence**: Medium
**Conditions**:
1. Run a manual prompt experiment at start of implementation session (15-20 min) to validate Proposer capability
2. Build single-agent v0 before full pipeline
3. Cut v1 specialization to 1 type (test-audit) + general
4. Define minimum viable input threshold (5 session handoffs) as Pre-Flight Gate

**Highest-Risk Assumption**: A Sonnet-class agent can produce proposals specific enough to be directly actionable (target file + section + concrete content). No existing Bulwark skill demonstrates this capability.

**Kill Criteria**:
1. Prompt experiment produces proposals requiring >20% rewriting
2. First test yields fewer than 3 actionable proposals from 62 sessions
3. Acceptance rate below 40% across 3 invocations
4. Token consumption exceeds 60K per invocation

## Implementation Outline

### v1 Scope (PM + Critic reconciled)

**In v1:**
- 4-stage pipeline: Collect → Analyze → Act → Validate
- Proposal-only output to `logs/continuous-feedback/{run-slug}/`
- Input: session handoffs + MEMORY.md + custom paths via `--sources`
- Input scoping: `--since <session_number>` (default: last 10 sessions, MEMORY.md always in full)
- Specialization: test-audit + general (per Critic's recommendation — richest history, validates pattern before expanding)
- Minimum input threshold: 5 session handoffs (Pre-Flight Gate)
- Diagnostic YAML output

**Deferred:**
- code-review specialization (v1.1 — after pattern validated)
- bug-magnet-data specialization (v2)
- Auto-apply proposals
- External data source integration
- Scheduled/automated invocation
- Agent memory input (pending P6.9)

### Architecture (Architect + Critic reconciled)

**Pipeline topology:**

```fsharp
// v1 pipeline
PreFlight(args, inputs)                    // Stage 0: Orchestrator
|> Collector(sessions, memory, custom)     // Stage 1: Sonnet, sequential
|> [Analyzer(test-audit), Analyzer(general)]  // Stage 2: Sonnet, parallel (dynamic 1-2)
|> Proposer(all_analyses, target_skills)   // Stage 3: Sonnet, sequential
|> Validate(proposal)                      // Stage 4: Orchestrator, no sub-agent
```

**Directory layout:**
```
skills/continuous-feedback/
  SKILL.md
  references/
    collect-instructions.md          # Parsing rules for session handoffs, MEMORY.md
    specialize-test-audit.md         # Test-audit improvement patterns
    specialize-general.md            # General skill improvement patterns
  templates/
    collect-output.md                # Normalized learning item schema
    proposal-output.md               # Change proposal format
    diagnostic-output.yaml           # Standard diagnostic schema
```

**Key design decisions:**
- Collector as sub-agent (not orchestrator) to avoid 25-40% token consumption on raw file reading
- Dynamic Analyzer count (1-2 based on detected skill types in target project)
- Normalized intermediate format between Collect and Analyze, BUT with richer content field (preserve full learning narrative, not just 1-2 sentences — addressing Critic's lossy schema concern)
- Per-skill routing via Collector's `skill_relevance` field (LLM-classified during collection, not keyword-based — addressing Critic's routing concern)
- No Critical Evaluation Gate (proposal-only output, no interactive synthesis)
- Validate stage is orchestrator-direct (anthropic-validator + quality gates)

### Build Plan (Dev Lead + Critic reconciled)

**Implementation session approach:**

1. **Prompt experiment (15-20 min)**: Before writing SKILL.md, manually test Sonnet's proposal capability. Give it 5 learning items + a target skill's content. Evaluate output quality against the kill criteria.

2. **If experiment passes**: Build the full pipeline in bottom-up order:
   - Step 1: Templates (collect-output.md, proposal-output.md, diagnostic-output.yaml)
   - Step 2: References (collect-instructions.md, specialize-test-audit.md, specialize-general.md)
   - Step 3: SKILL.md (stages, Pre-Flight Gate, error handling, completion checklist)
   - Step 4: Sync to .claude/skills/ + validate with /anthropic-validator

3. **If experiment fails**: Fall back to Alternative 1 (structured checklist) or re-scope the Proposer's output format to be less specific.

**Estimated effort**: 1 session (35-50K tokens), matching the P5.14 precedent.

## Risks and Mitigations

| Risk | Source Role | Severity | Mitigation |
|------|-----------|----------|------------|
| Proposer produces vague, inapplicable proposals | Critic, Dev Lead | HIGH | Prompt experiment before build. Mandatory template fields (target_file, change_type, proposed_content, rationale). Good/bad examples in prompt. |
| Collector token overflow on 62+ session files | Dev Lead, Architect | MEDIUM | `--since` flag defaults to last 10 sessions. Collector reads section headers via Grep, not full files. |
| Normalized intermediate format loses actionable context | Critic | MEDIUM | Richer content field preserving full learning narrative. Collector includes surrounding context, not just extracted sentences. |
| Per-skill routing misses learnings without clean keywords | Critic | MEDIUM | LLM-classified routing in Collector (skill_relevance field) rather than orchestrator keyword matching. |
| Specialization reference files become stale as skills evolve | Critic | LOW | Ironic but addressable: run continuous-feedback on itself. Reference files are short (50-80 lines) and infrequently changing. |
| Stale proposals on re-invocation (already-applied changes re-proposed) | PM | LOW | Proposer receives current skill state. Instruct: "Do not propose changes already present in the current file." |
| Net time savings may be negative in v1 (identification saved, application added) | Critic | LOW | Proposal format designed for easy application (specific file + section + content). Auto-apply deferred to v2 but v1 proposals must be copy-paste-ready. |

## Open Questions

1. **Stale proposal detection**: Should the Proposer compare proposals against current skill state (requiring it to read target files), or should the Collector mark already-addressed learnings during collection?

2. **Run slug format**: Use timestamped slugs (`20260217-143000`) or descriptive slugs (`test-audit-improvement-20260217`)? Timestamped is simpler; descriptive aids browsing.

---

## Post-Synthesis Decisions

Resolved via user Q&A after synthesis. All responses classified as **Preference** (no follow-up validation needed).

### Pipeline Approach: Full Pipeline Directly

**Decision**: Build the full 4-agent pipeline directly. Skip the prompt experiment and single-agent v0.
**Rationale**: User trusts existing multi-stage skill patterns sufficiently. The Critic's v0 approach adds a build/test cycle without guaranteed value — if the pattern works for bulwark-research and bulwark-brainstorm, it can work here.
**Impact**: Removes the prompt experiment step from the build plan. Implementation starts directly with templates.

### Specializations: 2 + General

**Decision**: v1 includes test-audit + code-review + general (3 specialization reference files).
**Rationale**: PM's recommendation. Both skills have rich documented improvement histories and reference file structures. General covers everything else.
**Impact**: 3 reference files instead of 2 (Critic) or 4 (Architect/Dev Lead). `specialize-code-review.md` added to v1.

### Schema Depth: Pass-Through

**Decision**: Collector groups and tags but passes near-raw content. Analyzers handle interpretation.
**Rationale**: Maximum fidelity. The Critic's core concern about lossy intermediate formats is fully addressed. Learning items retain their full narrative context.
**Impact**: Higher token consumption in Analyze stage (Analyzers receive fuller content), but avoids the quality-destroying compression that the Critic identified as the second-highest-risk assumption.

### Test Target: test-audit

**Decision**: First validation run targets the test-audit skill.
**Rationale**: Richest improvement history (AST scripts, mock detection, assertion patterns). Most documented learnings in sessions. If the pipeline works here, it works for simpler skills.

### Rsync Scope: Sync as Examples

**Decision**: Specialization reference files sync to the standalone essential-agents-skills repo as example specializations.
**Rationale**: Users can adapt them for their own skills. The skill is general-purpose; example specializations demonstrate how to extend it.
**Impact**: `sync-essential-skills.sh` includes `references/specialize-*.md` files.

### Updated v1 Scope (Final)

**In v1:**
- Full 4-agent pipeline: Collect → Analyze → Act → Validate (no prompt experiment, no v0)
- Proposal-only output to `logs/continuous-feedback/{run-slug}/`
- Input: session handoffs + MEMORY.md + custom paths via `--sources`
- Input scoping: `--since <session_number>` (default: last 10 sessions, MEMORY.md always in full)
- 3 specializations: test-audit + code-review + general
- Pass-through schema (Collector tags but preserves full content)
- Minimum input threshold: 5 session handoffs (Pre-Flight Gate)
- Diagnostic YAML output
- First test run targets test-audit skill
- Specialization references sync to standalone repo as examples

**Deferred:**
- bug-magnet-data specialization (v2)
- Auto-apply proposals
- External data source integration
- Scheduled/automated invocation
- Agent memory input (pending P6.9)

### Updated Build Plan (Final)

1. **Step 1: Templates** — collect-output.md, proposal-output.md, diagnostic-output.yaml
2. **Step 2: References** — collect-instructions.md, specialize-test-audit.md, specialize-code-review.md, specialize-general.md
3. **Step 3: SKILL.md** — stages, Pre-Flight Gate, error handling, completion checklist, frontmatter
4. **Step 4: Sync and Validate** — copy to .claude/skills/, run /anthropic-validator, rsync to standalone repo

### Updated Directory Layout (Final)

```
skills/continuous-feedback/
  SKILL.md
  references/
    collect-instructions.md          # Parsing rules for session handoffs, MEMORY.md
    specialize-test-audit.md         # Test-audit improvement patterns
    specialize-code-review.md        # Code-review improvement patterns
    specialize-general.md            # General skill improvement patterns
  templates/
    collect-output.md                # Pass-through learning item schema
    proposal-output.md               # Change proposal format
    diagnostic-output.yaml           # Standard diagnostic schema
```
